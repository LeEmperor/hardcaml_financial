(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "mbp_decoder.ml" *)
(* Template-46 decoder with schema-sized collectors and runtime padding/group skips. Owns
   one message until completion; terminal iterator diagnostics abort collection and are
   emitted by Event_orderer after all previously completed decoder events. *)

open! Hardcaml
open Signal
open Always
module D = Generated_mbp_descriptor
module T = Cme_types

module I = struct
  type 'a t =
    { clock_i : 'a
    ; reset_i : 'a
    ; en_i : 'a
    ; (* Ordered message items, including a terminal abort diagnostic. *)
      item_i : 'a [@bits T.message_item_width]
    ; valid_i : 'a
    ; event_ready_i : 'a
    ; done_ready_i : 'a
    }
  [@@deriving hardcaml]
end

module O = struct
  type 'a t =
    { ready_o : 'a
    ; event_o : 'a [@bits T.Event.width]
    ; event_valid_o : 'a
    ; done_o : 'a
    ; idle_o : 'a
    }
  [@@deriving hardcaml]
end

let field data offset bytes =
  select data ~low:(8 * offset) ~high:((8 * (offset + bytes)) - 1)
;;

let create scope (i : _ I.t) =
  let active = i.en_i &: ~:(i.reset_i) in
  let spec = Reg_spec.create ~clock:i.clock_i ~clear:i.reset_i () in
  (* Timing reports name flops, and an unnamed design reports as [signal_reg_51_reg[6]].
     Every state register carries its source name so a path can be read directly; see the
     naming rule in docs/timing_notes.md. *)
  let variable name width =
    let v = Variable.reg spec ~enable:active ~width in
    ignore (v.value -- name : Signal.t);
    v
  in
  (* idle, check, root, root_done, root_padding, mbp_dimensions, mbp_check, entry,
     entry_emit, entry_padding, order_dimensions, order_check, orders, tail, end_event,
     drain, done *)
  let state = variable "state" 5 in
  let at n = state.value ==:. n in
  let go n = state <-- of_int_trunc ~width:5 n in
  let position = variable "position" 16 in
  let collected = variable "collected" 16 in
  let skip_left = variable "skip_left" 24 in
  let input_done = variable "input_done" 1 in
  let aborted = variable "aborted" 1 in
  let packet_bits =
    variable
      "packet_bits"
      (List.fold_left ( + ) 0 (T.Packet_context.to_list T.Packet_context.port_widths))
  in
  let message_bits =
    variable
      "message_bits"
      (List.fold_left ( + ) 0 (T.Message_context.to_list T.Message_context.port_widths))
  in
  let transaction = variable "transaction" 64 in
  let transaction_present = variable "transaction_present" 1 in
  let indicator = variable "indicator" 8 in
  let entry_block = variable "entry_block" 16 in
  let entry_count = variable "entry_count" 16 in
  let entry_index = variable "entry_index" 16 in
  let dimension_position = variable "dimension_position" 16 in
  let entry_position = variable "entry_position" 16 in
  let event_bits = variable "event_bits" T.Event.width in
  let event_pending = variable "event_pending" 1 in
  let event_space = ~:(event_pending.value) |: i.event_ready_i in
  let input = T.Message_item.Of_signal.unpack i.item_i in
  let diagnostic = input.kind ==:. T.Message_item_kind.diagnostic in
  let retiring = at 16 &: event_space &: i.done_ready_i in
  let accepting_start = at 0 |: retiring in
  let accept = accepting_start |: (~:(at 16) &: ~:(input_done.value)) in
  let consume_count, consume_valid = wire 4, wire 1 in
  let a =
    Byte_aligner.hierarchical
      ~max_consume:15
      scope
      { clock_i = i.clock_i
      ; reset_i = i.reset_i
      ; en_i = i.en_i
      ; data_i = input.beat.data
      ; keep_i = input.beat.keep
      ; first_i = input.beat.first
      ; last_i = input.beat.last
      ; ingress_timestamp_i = zero 64
      ; valid_i = i.valid_i &: accept &: ~:diagnostic &: ~:(input.body_empty)
      ; consume_count_i = consume_count
      ; consume_valid_i = consume_valid
      }
  in
  let abort_ready = wire 1 in
  let ready =
    active &: accept &: mux2 diagnostic abort_ready (input.body_empty |: a.ready_o)
  in
  let transfer = ready &: i.valid_i in
  let start = transfer &: accepting_start in
  let abort = transfer &: diagnostic in
  (* Arithmetic that depends only on the message header, evaluated in the cycle that
     latches it rather than in every cycle that reads it. These mirror the [message_bits]
     write under [start] below, so each becomes valid on exactly the same edge as [header]
     and adds no latency; they are meaningless before the first header is latched and are
     only read from state 1 onwards. Keeping the adders and variable-width comparators
     here takes them out of the [consume_count] cone, which launches the parser's worst
     setup path. Any change to the [message_bits] assignment must be mirrored here. *)
  let header_derived e = reg spec ~enable:(active &: start) e in
  let hdr_root_plus_dimensions =
    header_derived (input.message.block_length +:. D.Mbp_dimension.encoded_size)
    -- "hdr_root_plus_dimensions"
  in
  let hdr_body_size = header_derived (input.message.msg_size -:. 10) -- "hdr_body_size" in
  let hdr_root_extension =
    header_derived (input.message.block_length -:. D.root_block_length)
    -- "hdr_root_extension"
  in
  let hdr_dimensions_fit =
    header_derived
      (input.message.msg_size
       >=: input.message.block_length +:. (10 + D.Mbp_dimension.encoded_size))
    -- "hdr_dimensions_fit"
  in
  let hdr_root_within_head =
    header_derived (input.message.block_length <=:. D.root_block_length + 1)
    -- "hdr_root_within_head"
  in
  let hdr_root_within_window =
    header_derived (input.message.block_length <=:. D.root_block_length + 9)
    -- "hdr_root_within_window"
  in
  let hdr_root_over_body =
    header_derived (input.message.block_length >: input.message.msg_size -:. 10)
    -- "hdr_root_over_body"
  in
  let packet = T.Packet_context.Of_signal.unpack packet_bits.value in
  let header = T.Message_context.Of_signal.unpack message_bits.value in
  let message =
    { header with
      transaction_time = transaction.value
    ; transaction_time_present = transaction_present.value
    }
  in
  let base = { (T.Event.Of_signal.zero ()) with packet; message } in
  let absolute = header.packet_byte_offset +:. 10 in
  let emit event =
    [ event_bits <-- T.Event.Of_signal.pack event; event_pending <-- vdd ]
  in
  let fail code offset =
    emit
      { base with
        kind = of_int_trunc ~width:2 T.Event_kind.diagnostic
      ; diagnostic_code = of_int_trunc ~width:8 code
      ; diagnostic_byte_offset = offset
      }
    @ [ go 15 ]
  in
  let schema offset = fail T.Diagnostic_code.schema_incompatibility offset in
  let collecting = at 2 |: at 5 |: at 7 |: at 10 in
  (* The ordinary root and MBP dimensions fit together in the two-beat window. Collect
     them in one command; extended roots retain the generic padded path. *)
  let combined_root =
    at 2
    &: (collected.value
        ==:. 0
        &: hdr_root_within_head
        |: (collected.value ==:. 8 &: hdr_root_within_window))
    &: hdr_dimensions_fit
  in
  (* Version 9 ends at MDEntryType. TradeableSize is absent until version 10; its reserved
     bytes must not delay that version's completed update. *)
  let target =
    mux2
      (at 2)
      (mux2
         combined_root
         hdr_root_plus_dimensions
         (of_int_trunc ~width:16 D.root_block_length))
      (mux2
         (at 5)
         (of_int_trunc ~width:16 D.Mbp_dimension.encoded_size)
         (mux2
            (at 7)
            (mux2
               (header.schema_version <:. D.Tradeable_size.since_version)
               (of_int_trunc ~width:16 (D.Entry_type.offset + D.Entry_type.byte_width))
               (of_int_trunc ~width:16 D.mbp_group_block_length))
            (of_int_trunc ~width:16 D.Order_dimension.encoded_size)))
  in
  let required = target -: collected.value in
  let tail_remaining = entry_block.value -: collected.value in
  let tail_available =
    mux2 (a.available_o <:. 15) a.available_o (of_int_trunc ~width:5 15)
  in
  let tail_count =
    mux2
      (tail_remaining <: uresize tail_available ~width:16)
      (uresize tail_remaining ~width:5)
      tail_available
  in
  let count =
    mux2
      (at 7)
      tail_count
      (mux2
         (combined_root |: (required <:. 8))
         (uresize required ~width:5)
         (of_int_trunc ~width:5 8))
  in
  (* Emit a completed entry on its final collection edge. Reserve event storage before
     consuming that chunk, so backpressure and terminal aborts retain ownership. *)
  let collect =
    active
    &: collecting
    &: a.valid_o
    &: (a.available_o >=: count)
    &: (count <>:. 0)
    &: (~:(at 7) |: (uresize count ~width:16 <: required) |: event_space)
  in
  (* A completed entry can occupy the collector while the event register is stalled. Also
     finish an entry whose remaining bytes are already in the aligner. Hold the terminal
     abort upstream until that update (or enum diagnostic) is in event storage. *)
  Signal.(
    abort_ready
    <-- ~:(at 8 |: (at 7 &: a.valid_o &: (uresize a.available_o ~width:16 >=: required))));
  let skipping = at 4 |: at 9 |: at 12 in
  (* Use the space after a short padding tail for the next fixed chunk. This avoids a
     padding-only cycle on each extended entry while keeping the window at 128 bits. *)
  let next_is_order = entry_index.value +:. 1 ==: entry_count.value in
  (* Fuse the last root padding with MBP dimensions, including zero padding left. Only
     prefetch inside MsgSize; the ordinary path retains malformed-tail errors. *)
  let prefetch_root =
    active
    &: at 4
    &: (skip_left.value <=:. 12)
    &: a.valid_o
    &: (uresize a.available_o ~width:24
        >=: skip_left.value +:. D.Mbp_dimension.encoded_size)
    &: (uresize position.value ~width:24
        +: skip_left.value
        +:. D.Mbp_dimension.encoded_size
        <=: uresize (header.msg_size -:. 10) ~width:24)
  in
  let prefetch_next =
    active
    &: at 9
    &: (skip_left.value >:. 0)
    &: a.valid_o
    &: mux2
         next_is_order
         (skip_left.value
          <=:. 7
          &: (uresize a.available_o ~width:24 >=: skip_left.value +:. 8))
         (skip_left.value <:. 15 &: (uresize a.available_o ~width:24 >: skip_left.value))
  in
  let prefetched_data =
    mux
      (uresize skip_left.value ~width:4)
      (List.init 16 (fun byte -> srl a.data_o ~by:(byte * 8)))
  in
  let available_skip =
    mux2 (a.available_o <:. 15) a.available_o (of_int_trunc ~width:5 15)
  in
  let skip_count =
    mux2
      prefetch_root
      (uresize (skip_left.value +:. D.Mbp_dimension.encoded_size) ~width:5)
      (mux2
         prefetch_next
         (mux2 next_is_order (uresize (skip_left.value +:. 8) ~width:5) available_skip)
         (mux2
            (skip_left.value <: uresize available_skip ~width:24)
            (uresize skip_left.value ~width:5)
            available_skip))
  in
  let skip =
    active
    &: skipping
    &: (skip_left.value <>:. 0 |: prefetch_root)
    &: a.valid_o
    &: (a.available_o >=: skip_count)
  in
  let draining = at 13 |: at 15 in
  let drain_count = mux2 (a.available_o <:. 8) a.available_o (of_int_trunc ~width:5 8) in
  let drain = active &: draining &: a.valid_o in
  Signal.(
    consume_count
    <-- uresize (mux2 collecting count (mux2 skipping skip_count drain_count)) ~width:4);
  Signal.(consume_valid <-- (collect |: skip |: drain));
  let consumed = collect |: skip |: drain in
  (* Fixed eight-byte chunk registers: only the 128-bit aligner shifts dynamically. *)
  let collector ?(forward = false) size state_number =
    List.init
      ((size + 7) / 8)
      (fun chunk ->
        let bytes = min 8 (size - (chunk * 8)) in
        let prefetch =
          if chunk <> 0
          then gnd
          else if state_number = 5
          then prefetch_root
          else if state_number = 7
          then prefetch_next &: ~:next_is_order
          else if state_number = 10
          then prefetch_next &: next_is_order
          else gnd
        in
        let take =
          collect &: at state_number &: (collected.value ==:. chunk * 8) |: prefetch
        in
        let next = field (mux2 prefetch prefetched_data a.data_o) 0 bytes in
        let stored = reg spec ~enable:take next in
        if forward then mux2 take next stored else stored)
    |> concat_lsb
  in
  let root = collector ~forward:true D.root_block_length 2 in
  let ordinary_dimensions = collector D.Mbp_dimension.encoded_size 5 in
  let combined_dimension_data =
    let offset = uresize (header.block_length -: collected.value) ~width:4 in
    field
      (mux offset (List.init 16 (fun byte -> srl a.data_o ~by:(byte * 8))))
      0
      D.Mbp_dimension.encoded_size
  in
  let combined_dimensions =
    reg spec ~enable:(collect &: combined_root) combined_dimension_data
  in
  let used_combined_root = reg spec ~enable:(collect &: at 2) combined_root in
  let dimensions = mux2 used_combined_root combined_dimensions ordinary_dimensions in
  (* Byte enables allow a short padding tail and the beginning of the next entry to share
     one consume. The storage remains exactly one schema-sized entry; each mux selects an
     eight-bit lane from the same 128-bit window. *)
  let prefetched_count = uresize skip_count ~width:24 -: skip_left.value in
  let entry =
    List.init D.mbp_group_block_length (fun byte ->
      let take =
        collect
        &: at 7
        &: (collected.value <=:. byte)
        &: (collected.value +: uresize count ~width:16 >:. byte)
      in
      let prefetch =
        if byte < 15
        then prefetch_next &: ~:next_is_order &: (prefetched_count >:. byte)
        else gnd
      in
      let offset = uresize (of_int_trunc ~width:16 byte -: collected.value) ~width:4 in
      let lane = mux offset (List.init 16 (fun n -> field a.data_o n 1)) in
      let prefetched_lane = if byte < 15 then field prefetched_data byte 1 else zero 8 in
      let next = mux2 prefetch prefetched_lane lane in
      let enable = take |: prefetch in
      let stored = reg spec ~enable next in
      mux2 enable next stored)
    |> concat_lsb
  in
  let order_dimensions = collector D.Order_dimension.encoded_size 10 in
  let block =
    field
      dimensions
      D.Mbp_dimension.block_length_offset
      D.Mbp_dimension.block_length_byte_width
  in
  let count_entries =
    uresize
      (field dimensions D.Mbp_dimension.count_offset D.Mbp_dimension.count_byte_width)
      ~width:16
  in
  let order_block =
    field
      order_dimensions
      D.Order_dimension.block_length_offset
      D.Order_dimension.block_length_byte_width
  in
  let order_count =
    field
      order_dimensions
      D.Order_dimension.count_offset
      D.Order_dimension.count_byte_width
  in
  let entries_bytes = uresize (block *: count_entries) ~width:24 in
  let orders_bytes = uresize (order_block *: order_count) ~width:24 in
  let body_size = hdr_body_size in
  (* Body space left at the current position, as a 25-bit two's complement value: while
     draining, [position] runs past the body, and the sign bit carries that instead of
     wrapping. Both operands are registers, so this sits off the late cone. *)
  let room = uresize body_size ~width:25 -: uresize position.value ~width:25 -- "room" in
  (* [--] binds tighter than [&:], so the name needs the parentheses or it lands on the
     comparison alone and the timing report points at half the predicate. *)
  let fits site bytes =
    (~:(msb room) &: (uresize bytes ~width:25 <=: room)) -- ("fits_" ^ site)
  in
  (* The same bound one consume later. [consume_count] is the late signal on this module's
     worst setup path -- [collected] -> [required] -> [count] -> [consume_count] -- so the
     bound is written as [consume_count <= body_size - position - bytes] rather than
     [position + consume_count + bytes <= body_size]. Both are the same value, but the
     first evaluates every wide operation from early operands and leaves the late signal
     facing one comparison; the second fed a 16-bit add whose sum entered the group-size
     multiplier's DSP48E1 and came back out through that same DSP's opmode, putting 4.3 ns
     of unavoidable DSP delay behind [collected]. The rewrite does not reproduce the
     16-bit wrap of [next_position], which needs [position >= 65521] and is unreachable
     inside a message body. *)
  let fits_after_consume site bytes =
    let headroom = room -: uresize bytes ~width:25 -- ("headroom_" ^ site) in
    (~:(msb headroom) &: (uresize consume_count ~width:25 <=: headroom))
    -- ("fits_after_consume_" ^ site)
  in
  let combined_block =
    field
      combined_dimension_data
      D.Mbp_dimension.block_length_offset
      D.Mbp_dimension.block_length_byte_width
  in
  let combined_count =
    uresize
      (field
         combined_dimension_data
         D.Mbp_dimension.count_offset
         D.Mbp_dimension.count_byte_width)
      ~width:16
  in
  let combined_entries_bytes = uresize (combined_block *: combined_count) ~width:24 in
  let next_position = position.value +: uresize consume_count ~width:16 in
  let combined_fits = fits_after_consume "combined" combined_entries_bytes in
  let final_order_dimension =
    at 10
    &: collect
    &: event_space
    &: input_done.value
    &: (a.available_o ==: count)
    &: (field
          a.data_o
          D.Order_dimension.block_length_offset
          D.Order_dimension.block_length_byte_width
        >=:. D.order_group_block_length)
    &: (field a.data_o D.Order_dimension.count_offset D.Order_dimension.count_byte_width
        ==:. 0)
  in
  (* A valid nonempty MBO group can enter its skip on the dimension collection edge.
     Invalid dimensions keep the registered diagnostic path. *)
  let valid_orders site data =
    let block =
      field
        data
        D.Order_dimension.block_length_offset
        D.Order_dimension.block_length_byte_width
    in
    let count =
      field data D.Order_dimension.count_offset D.Order_dimension.count_byte_width
    in
    let bytes = uresize (block *: count) ~width:24 -- ("order_bytes_" ^ site) in
    ( block
      >=:. D.order_group_block_length
      &: (count <>:. 0)
      &: fits_after_consume site bytes
    , bytes )
  in
  let optional offset bytes since null =
    let raw = field entry offset bytes in
    let is_null =
      header.schema_version
      <:. since
      |:
      match null with
      | None -> gnd
      | Some value -> raw ==: of_int64_trunc ~width:(bytes * 8) (Int64.of_string value)
    in
    mux2 is_null (zero (bytes * 8)) raw, is_null
  in
  let price, price_null =
    optional
      D.Price_mantissa.offset
      D.Price_mantissa.byte_width
      D.Price_mantissa.since_version
      D.Price_mantissa.null_value
  in
  let size, size_null =
    optional
      D.Entry_size.offset
      D.Entry_size.byte_width
      D.Entry_size.since_version
      D.Entry_size.null_value
  in
  let orders, orders_null =
    optional
      D.Number_of_orders.offset
      D.Number_of_orders.byte_width
      D.Number_of_orders.since_version
      D.Number_of_orders.null_value
  in
  let tradeable, tradeable_null =
    optional
      D.Tradeable_size.offset
      D.Tradeable_size.byte_width
      D.Tradeable_size.since_version
      D.Tradeable_size.null_value
  in
  let action = field entry D.Update_action.offset D.Update_action.byte_width in
  let entry_type = field entry D.Entry_type.offset D.Entry_type.byte_width in
  let enum_valid value values =
    List.fold_left
      ( |: )
      gnd
      (List.map
         (fun (candidate, version) ->
           value ==:. candidate &: (header.schema_version >=:. version))
         values)
  in
  let action_valid = enum_valid action D.Update_action.valid_values_since_version in
  let type_valid = enum_valid entry_type D.Entry_type.valid_values_since_version in
  let update =
    { base with
      kind = of_int_trunc ~width:2 T.Event_kind.mbp_update
    ; entry_index = entry_index.value
    ; entry_count = entry_count.value
    ; security_id = field entry D.Security_id.offset D.Security_id.byte_width
    ; rpt_seq = field entry D.Rpt_seq.offset D.Rpt_seq.byte_width
    ; price_mantissa = price
    ; price_is_null = price_null
    ; entry_size = size
    ; entry_size_is_null = size_null
    ; number_of_orders = orders
    ; number_of_orders_is_null = orders_null
    ; price_level = field entry D.Price_level.offset D.Price_level.byte_width
    ; update_action = action
    ; entry_type
    ; tradeable_size = tradeable
    ; tradeable_size_is_null = tradeable_null
    ; match_event_indicator = indicator.value
    ; message_last = entry_index.value +:. 1 ==: entry_count.value
    }
  in
  let begin_collect n = [ collected <-- zero 16; go n ] in
  let finish_message =
    [ when_
        (bit indicator.value ~pos:7 &: ~:(aborted.value))
        (emit
           { base with
             kind = of_int_trunc ~width:2 T.Event_kind.end_of_event
           ; match_event_indicator = indicator.value
           })
    ; go 16
    ]
  in
  let finish_entry next_position =
    if_
      (~:action_valid |: ~:type_valid)
      (fail
         T.Diagnostic_code.invalid_enum
         (absolute
          +: entry_position.value
          +: mux2
               action_valid
               (of_int_trunc ~width:16 D.Entry_type.offset)
               (of_int_trunc ~width:16 D.Update_action.offset)))
      (emit update
       @ [ if_
             (entry_block.value ==: collected.value +: uresize consume_count ~width:16)
             [ entry_index <-- entry_index.value +:. 1
             ; entry_position <-- next_position
             ; if_
                 (entry_index.value +:. 1 ==: entry_count.value)
                 (begin_collect 10)
                 (begin_collect 7)
             ]
             [ skip_left
               <-- uresize
                     (entry_block.value
                      -: collected.value
                      -: uresize consume_count ~width:16)
                     ~width:24
             ; go 9
             ]
         ])
  in
  compile
    [ when_ (event_pending.value &: i.event_ready_i) [ event_pending <-- gnd ]
    ; when_
        transfer
        [ input_done <-- (diagnostic |: input.body_empty |: input.beat.last) ]
    ; when_ consumed [ position <-- position.value +: uresize consume_count ~width:16 ]
    ; when_
        collect
        [ collected <-- collected.value +: uresize count ~width:16
        ; when_ (~:(at 7) &: (required <=:. 8)) [ state <-- state.value +:. 1 ]
        ]
    ; when_
        skip
        [ skip_left
          <-- mux2
                (prefetch_next |: prefetch_root)
                (zero 24)
                (skip_left.value -: uresize skip_count ~width:24)
        ]
    ; switch
        state.value
        [ of_int_trunc ~width:5 0, []
        ; ( of_int_trunc ~width:5 1
          , [ when_
                event_space
                [ if_
                    (header.schema_id <>:. D.schema_id)
                    (schema (header.packet_byte_offset +:. 6))
                    [ if_
                        (header.schema_version <:. D.template_since_version)
                        (schema (header.packet_byte_offset +:. 8))
                        [ if_
                            (header.block_length
                             <:. D.root_block_length
                             |: hdr_root_over_body)
                            (schema (header.packet_byte_offset +:. 2))
                            (begin_collect 2
                             @ [ when_
                                   (header.schema_version >:. D.schema_version)
                                   (emit
                                      { base with
                                        kind =
                                          of_int_trunc ~width:2 T.Event_kind.diagnostic
                                      ; diagnostic_code =
                                          of_int_trunc
                                            ~width:8
                                            T.Diagnostic_code.schema_incompatibility
                                      ; diagnostic_byte_offset =
                                          header.packet_byte_offset +:. 8
                                      })
                               ])
                        ]
                    ]
                ]
            ] )
        ; ( of_int_trunc ~width:5 2
          , [ when_
                (collect &: ~:combined_root &: (required <=:. 8))
                [ transaction
                  <-- field root D.Transact_time.offset D.Transact_time.byte_width
                ; transaction_present <-- vdd
                ; indicator
                  <-- field
                        root
                        D.Match_event_indicator.offset
                        D.Match_event_indicator.byte_width
                ; skip_left <-- uresize hdr_root_extension ~width:24
                ; go 4
                ]
            ; when_
                (collect &: combined_root)
                [ transaction
                  <-- mux2
                        (collected.value ==:. 0)
                        (field a.data_o D.Transact_time.offset D.Transact_time.byte_width)
                        (field root D.Transact_time.offset D.Transact_time.byte_width)
                ; transaction_present <-- vdd
                ; indicator
                  <-- mux2
                        (collected.value ==:. 0)
                        (field
                           a.data_o
                           D.Match_event_indicator.offset
                           D.Match_event_indicator.byte_width)
                        (field
                           a.data_o
                           (D.Match_event_indicator.offset - 8)
                           D.Match_event_indicator.byte_width)
                ; dimension_position <-- header.block_length
                ; if_
                    (combined_block >=:. D.mbp_group_block_length &: combined_fits)
                    [ entry_block <-- combined_block
                    ; entry_count <-- combined_count
                    ; entry_index <-- zero 16
                    ; entry_position <-- next_position
                    ; if_ (combined_count ==:. 0) (begin_collect 10) (begin_collect 7)
                    ]
                    [ go 6 ]
                ]
            ] )
        ; ( of_int_trunc ~width:5 3
          , [ transaction <-- field root D.Transact_time.offset D.Transact_time.byte_width
            ; transaction_present <-- vdd
            ; indicator
              <-- field
                    root
                    D.Match_event_indicator.offset
                    D.Match_event_indicator.byte_width
            ; skip_left <-- uresize hdr_root_extension ~width:24
            ; go 4
            ] )
        ; ( of_int_trunc ~width:5 4
          , [ if_
                prefetch_root
                (let block =
                   field
                     prefetched_data
                     D.Mbp_dimension.block_length_offset
                     D.Mbp_dimension.block_length_byte_width
                 in
                 let count =
                   uresize
                     (field
                        prefetched_data
                        D.Mbp_dimension.count_offset
                        D.Mbp_dimension.count_byte_width)
                     ~width:16
                 in
                 let bytes =
                   uresize (block *: count) ~width:24 -- "prefetch_root_bytes"
                 in
                 [ dimension_position
                   <-- position.value +: uresize skip_left.value ~width:16
                 ; if_
                     (block
                      >=:. D.mbp_group_block_length
                      &: fits_after_consume "prefetch_root" bytes)
                     [ entry_block <-- block
                     ; entry_count <-- count
                     ; entry_index <-- zero 16
                     ; entry_position <-- next_position
                     ; if_ (count ==:. 0) (begin_collect 10) (begin_collect 7)
                     ]
                     [ go 6 ]
                 ])
                [ when_
                    (skip_left.value ==:. 0 &: event_space)
                    [ if_
                        (fits
                           "dimensions"
                           (of_int_trunc ~width:24 D.Mbp_dimension.encoded_size))
                        ([ dimension_position <-- position.value ] @ begin_collect 5)
                        (schema (absolute +: position.value))
                    ]
                ]
            ] )
        ; ( of_int_trunc ~width:5 6
          , [ when_
                event_space
                [ if_
                    (block
                     <:. D.mbp_group_block_length
                     |: ~:(fits "entries" entries_bytes))
                    (schema (absolute +: dimension_position.value))
                    [ entry_block <-- block
                    ; entry_count <-- count_entries
                    ; entry_index <-- zero 16
                    ; entry_position <-- position.value
                    ; if_ (count_entries ==:. 0) (begin_collect 10) (begin_collect 7)
                    ]
                ]
            ] )
        ; ( of_int_trunc ~width:5 7
          , [ when_
                (collect &: (uresize count ~width:16 >=: required))
                [ finish_entry (position.value +: uresize consume_count ~width:16) ]
            ] )
        ; of_int_trunc ~width:5 8, [ when_ event_space [ finish_entry position.value ] ]
        ; ( of_int_trunc ~width:5 9
          , [ if_
                prefetch_next
                [ entry_index <-- entry_index.value +:. 1
                ; entry_position <-- position.value +: uresize skip_left.value ~width:16
                ; collected
                  <-- mux2
                        next_is_order
                        (of_int_trunc ~width:16 8)
                        (uresize prefetched_count ~width:16)
                ; if_
                    next_is_order
                    [ if_
                        (event_space
                         &: input_done.value
                         &: (a.available_o ==: skip_count)
                         &: (field
                               prefetched_data
                               D.Order_dimension.block_length_offset
                               D.Order_dimension.block_length_byte_width
                             >=:. D.order_group_block_length)
                         &: (field
                               prefetched_data
                               D.Order_dimension.count_offset
                               D.Order_dimension.count_byte_width
                             ==:. 0))
                        finish_message
                        (let valid, bytes =
                           valid_orders "prefetched_orders" prefetched_data
                         in
                         (* The group size is written unconditionally: [valid] is the late
                            signal here, and gating the data with it puts the skip-length
                            multiply behind the bound check that reads the same product,
                            which is how two DSP48E1s ended up in series. The value is
                            dead when the group is invalid - state 11 overwrites
                            [skip_left] before any reader, exactly as the zero it used to
                            keep did. *)
                         [ skip_left <-- bytes; if_ valid [ go 12 ] [ go 11 ] ])
                    ]
                    [ go 7 ]
                ]
                [ when_
                    (skip_left.value
                     ==:. 0
                     |: (skip &: (skip_left.value ==: uresize skip_count ~width:24)))
                    [ entry_index <-- entry_index.value +:. 1
                    ; entry_position <-- mux2 skip next_position position.value
                    ; if_
                        (entry_index.value +:. 1 ==: entry_count.value)
                        (begin_collect 10)
                        (begin_collect 7)
                    ]
                ]
            ] )
        ; ( of_int_trunc ~width:5 10
          , let valid, bytes = valid_orders "live_orders" a.data_o in
            [ when_ collect [ skip_left <-- bytes; when_ valid [ go 12 ] ]
            ; when_ final_order_dimension finish_message
            ] )
        ; ( of_int_trunc ~width:5 11
          , [ when_
                event_space
                [ if_
                    (order_block
                     <:. D.order_group_block_length
                     |: ~:(fits "orders" orders_bytes))
                    (schema
                       (absolute +: position.value -:. D.Order_dimension.encoded_size))
                    [ if_
                        (orders_bytes ==:. 0 &: input_done.value &: (a.available_o ==:. 0))
                        finish_message
                        [ skip_left <-- orders_bytes; go 12 ]
                    ]
                ]
            ] )
        ; ( of_int_trunc ~width:5 12
          , [ when_
                (skip_left.value
                 ==:. 0
                 |: (skip &: (skip_left.value ==: uresize skip_count ~width:24)))
                [ if_
                    (input_done.value
                     &: (mux2 skip (a.available_o -: skip_count) a.available_o ==:. 0)
                     &: event_space)
                    finish_message
                    [ go 13 ]
                ]
            ] )
        ; ( of_int_trunc ~width:5 13
          , [ when_
                (input_done.value &: (a.available_o ==:. 0) &: event_space)
                finish_message
            ] )
        ; of_int_trunc ~width:5 14, [ when_ event_space finish_message ]
        ; ( of_int_trunc ~width:5 15
          , [ when_ (input_done.value &: (a.available_o ==:. 0)) [ go 16 ] ] )
        ; of_int_trunc ~width:5 16, [ when_ retiring [ go 0 ] ]
        ]
    ; when_
        start
        [ packet_bits <-- T.Packet_context.Of_signal.pack input.packet
        ; message_bits <-- T.Message_context.Of_signal.pack input.message
        ; transaction <-- zero 64
        ; transaction_present <-- gnd
        ; indicator <-- zero 8
        ; position <-- zero 16
        ; aborted <-- gnd
        ; if_
            (input.message.schema_id
             ==:. D.schema_id
             &: (input.message.schema_version >=:. D.template_since_version)
             &: (input.message.schema_version <=:. D.schema_version)
             &: (input.message.block_length >=:. D.root_block_length)
             &: (input.message.msg_size >=:. 10)
             &: (input.message.block_length <=: input.message.msg_size -:. 10))
            (begin_collect 2)
            [ go 1 ]
        ]
      (* A trustworthy MsgSize that ends inside a collector is a schema error. A physical
         packet truncation arrives as an abort; its diagnostic belongs to the iterator. *)
    ; when_
        (collecting
         &: input_done.value
         &: ~:(aborted.value)
         &: (a.available_o
             <: count
             |: (at 7 &: (uresize a.available_o ~width:16 <: required)))
         &: event_space)
        (schema
           (absolute
            +: mux2 (at 10) (position.value -: collected.value) dimension_position.value))
    ; when_ abort [ aborted <-- vdd; go 15 ]
    ];
  (* Named nets, not just flops: a timing path through this module is a chain of
     comparators, adders and two multiplies, and reading it from [signal_add_29] is
     guesswork. See the naming rule in docs/timing_notes.md. *)
  List.iter
    (fun (name, signal) -> ignore (signal -- name : Signal.t))
    [ "available", a.available_o
    ; "consume_valid", consume_valid
    ; "consume_count", consume_count
    ; "start", start
    ; "retiring", retiring
    ; "ready", ready
    ; "transfer", transfer
    ; "abort", abort
    ; "event_space", event_space
    ; "collecting", collecting
    ; "skipping", skipping
    ; "draining", draining
    ; "combined_root", combined_root
    ; "target", target
    ; "required", required
    ; "tail_remaining", tail_remaining
    ; "tail_available", tail_available
    ; "tail_count", tail_count
    ; "count", count
    ; "collect", collect
    ; "skip", skip
    ; "drain", drain
    ; "next_is_order", next_is_order
    ; "prefetch_root", prefetch_root
    ; "prefetch_next", prefetch_next
    ; "prefetched_data", prefetched_data
    ; "prefetched_count", prefetched_count
    ; "available_skip", available_skip
    ; "skip_count", skip_count
    ; "drain_count", drain_count
    ; "root", root
    ; "ordinary_dimensions", ordinary_dimensions
    ; "combined_dimension_data", combined_dimension_data
    ; "combined_dimensions", combined_dimensions
    ; "used_combined_root", used_combined_root
    ; "dimensions", dimensions
    ; "entry", entry
    ; "order_dimensions", order_dimensions
    ; "block", block
    ; "count_entries", count_entries
    ; "order_block", order_block
    ; "order_count", order_count
    ; "combined_block", combined_block
    ; "combined_count", combined_count
    ; "entries_bytes", entries_bytes
    ; "orders_bytes", orders_bytes
    ; "combined_entries_bytes", combined_entries_bytes
    ; "combined_fits", combined_fits
    ; "next_position", next_position
    ; "room", room
    ; "final_order_dimension", final_order_dimension
    ];
  { O.ready_o = ready
  ; event_o = event_bits.value
  ; event_valid_o = active &: event_pending.value
  ; done_o = active &: at 16 &: event_space
  ; idle_o = at 0 &: ~:(event_pending.value) &: (a.available_o ==:. 0)
  }
;;

let hierarchical ?instance scope i =
  let module H = Hierarchy.In_scope (I) (O) in
  H.hierarchical ?instance ~name:"cme_mbp_decoder" ~scope create i
;;
