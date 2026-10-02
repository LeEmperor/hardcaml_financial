(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "sbe_message_iterator.ml" *)
(* Generic ten-byte SBE prefix collection and size-bounded body delivery. The two-beat
   window never joins packets. Template admission is an elaboration-time list; no schema
   offsets or production template choices belong here.

   This is the bread and the butter of the system in terms of dispatching;
*)

open! Hardcaml
open Signal

module I = struct
  type 'a t =
    { (* Application domain; synchronous reset overrides enable. *)
      clock_i : 'a
    ; reset_i : 'a
    ; en_i : 'a
    ; (* Canonical post-sequence packet items. *)
      item_i : 'a [@bits Cme_types.packet_item_width]
    ; valid_i : 'a
    ; (* Ordered message consumer, including terminal truncation diagnostics. *)
      ready_i : 'a
    }
  [@@deriving hardcaml]
end

module O = struct
  type 'a t =
    { ready_o : 'a
    ; valid_o : 'a
    ; item_o : 'a [@bits Cme_types.message_item_width]
    ; idle_o : 'a
    }
  [@@deriving hardcaml]
end

module State = struct
  type t =
    | Idle
    | Prefix_first (* collecting the first eight prefix bytes *)
    | Prefix_tail (* collecting the final two after a split *)
    | Body (* streaming the size-bounded message body *)
    | Empty_body (* the message was exactly its ten-byte prefix *)
    | Skip (* discarding the body of an unsupported template *)
    | Drain (* discarding the remainder of an untrustworthy packet *)
    | Error (* holding a diagnostic at the output *)
  [@@deriving sexp_of, compare ~localize, enumerate]
end

(* [Error] has to hand control back somewhere once its diagnostic is taken. Only these
   four targets are ever reachable, so the restore is an exhaustive match rather than a
   raw state code smuggled through a register. *)
module Resume = struct
  module Cases = struct
    type t =
      | Idle
      | Prefix_first
      | Skip
      | Drain
    [@@deriving sexp_of, compare ~localize, enumerate]
  end

  include Hardcaml.Enum.Make_binary (Cases)
end

(* Control state sharing the [active] enable. Bundled so it is registered, named and
   updated in one place each, rather than as separate wires carrying next-value muxes. *)
module Regs = struct
  type 'a t =
    { input_done : 'a (* the packet's final input beat has been taken *)
    ; remaining : 'a [@bits 16] (* body bytes still owed for the current message *)
    ; started : 'a (* the current message has already emitted a body beat *)
    ; second_error : 'a (* the held diagnostic is the truncation follow-up *)
    }
  [@@deriving hardcaml]
end

[@@@ocamlformat "disable"]
let create
    ~supported_templates
    scope (i : _ I.t)
  =

  List.iter
    (fun id -> if id < 0 || id > 65535 then invalid_arg "template ID must fit uint16")
    supported_templates;

  (* spec *)
  let spec = Reg_spec.create ~clock:i.clock_i ~clear:i.reset_i () in

  (* local aliasing *)
  let module T = Cme_types in

  (* spot derives *)
  let active = i.en_i &: ~:(i.reset_i) in

  (* hanger wires*)
  let output_ready = Signal.wire 1 in

  let input = T.Packet_item.Of_signal.unpack i.item_i in

  (* [sm.current] is the state register's q and [sm.is] hands back plain combinational
     signals, so the state is readable here even though the transitions are only compiled
     once the aligner outputs exist. The same holds for [r.<field>.value]. *)
  let sm = Always.State_machine.create (module State) spec ~enable:active in
  let _ : Signal.t = sm.current -- "phase6_iterator_state" in
  let r = Regs.Of_always.reg spec ~enable:active in
  Regs.Of_always.apply_names ~prefix:"phase6_iterator_" r;

  (* ppx rise up *)
  let idle              = sm.is State.Idle in
  let prefix_first      = sm.is State.Prefix_first in
  let prefix_tail       = sm.is State.Prefix_tail in
  let body_state        = sm.is State.Body in
  let empty_body_state  = sm.is State.Empty_body in
  let skip_state        = sm.is State.Skip in
  let draining          = sm.is State.Drain in
  let error_state       = sm.is State.Error in

  (*
    data flow example:

    in idle state, we're looking to start and crunch off 10B from the message header
        each of these are 2B
      -> MsgSize,
      -> BlockLength,
      -> TemplateID, <-- important
      -> SchemaID,
      -> Version



      prefix_first => collect 10B
      prefix_tail  => collect final 2B after a split
        we're walking multiple messages, so the assumptions on offset are not nice clean 2 or 8
        after the first header item anymore -> thus we need a spare state for grabbing remaining header
        introduces extra latency here but thit is necessary
    *)

  let collecting = prefix_first |: prefix_tail in
  let input_done = r.input_done.value in
  let remaining = r.remaining.value in
  let started = r.started.value in
  let second_error = r.second_error.value in
  let consume_count, consume_valid = wire 4, wire 1 in

  (* is the incoming packet adherent to the markers that the feed sequencer would've handed it?  *)
  let is_start = input.kind ==:. T.Packet_item_kind.start in
  let is_diagnostic = input.kind ==:. T.Packet_item_kind.diagnostic in

  let empty_packet = is_start &: input.body_empty in
  let retiring_packet = wire 1 in

  (* huh *)
  let early_start = retiring_packet &: is_start &: ~:(input.body_empty) in

  let accept_bytes =
    idle &: is_start &: ~:(input.body_empty) |: early_start |: (~:idle &: ~:input_done)
  in

  (* byte aligner instance;
     downstream modules have no concept of "beats" in terms of arriving data, only a byte window
     they are exposed; this is somewhat necessary in light of the "consume" paradigm being used
     on top of the fact that most of the things here make use of an offset of 4 because of the
     header offsets
   *)

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
      ; valid_i = i.valid_i &: accept_bytes
      ; consume_count_i = consume_count
      ; consume_valid_i = consume_valid
      }
  in

  (* bruh *)
  let ready =
    active
    &: mux2
         (* are we idle or starting early? *)
         (idle |: early_start)

         (* yes - pass the output ready and aligner readys through, assuming we're not a diagnostic packet *)
         (mux2
            is_diagnostic
            output_ready
            (empty_packet |: a.ready_o)
         )

        (* !input_done AND a.ready_o represents the backpressure push through *)
         (~:input_done &: a.ready_o)
  in

  let input_transfer = i.valid_i &: ready in
  let start =
    input_transfer &: (idle |: early_start) &: is_start &: ~:(input.body_empty)
  in

  let packet =
    T.Packet_context.Of_signal.unpack
      (reg spec ~enable:start (T.Packet_context.Of_signal.pack input.context))
  in

  let count =
    mux2
      (remaining <:. 8)
      (uresize remaining ~width:5)
      (of_int_trunc ~width:5 8)
  in

  let prefetch_full, prefetch_head = wire 1, wire 1 in
  let prefetched = prefetch_full |: prefetch_head in
  let shifted_prefix =
    mux
      (uresize count ~width:3)
      (List.init 8
         (fun byte ->
            srl a.data_o ~by:(byte * 8)
         )
      )
  in

  let prefix_data =
    mux2
      prefetched
      shifted_prefix
      a.data_o
  in

  let prefix_span = mux2 prefetch_full (count +:. 10) (zero 5) in
  (* Offset seven leaves only nine bytes in two stored beats. Retire eight before
     collecting the final two; every other alignment fits the complete prefix. *)
  let split_prefix =
    prefix_first &: (select a.packet_byte_offset_o ~high:2 ~low:0 ==:. 7)
  in
  let required =
    mux2
      prefix_tail
      (of_int_trunc ~width:5 2)
      (mux2 split_prefix (of_int_trunc ~width:5 8) (of_int_trunc ~width:5 10))
  in
  let collect = collecting &: a.valid_o &: (a.available_o >=: required |: a.boundary_o) in
  let short_prefix =
    collect
    &: (a.available_o
        <: required
        |: (split_prefix &: a.boundary_o &: (a.available_o ==:. 8)))
  in
  let prefix_head =
    reg
      spec
      ~enable:(collect &: split_prefix |: prefetch_head)
      (select prefix_data ~high:63 ~low:0)
  in
  let header_head = mux2 prefix_tail prefix_head (select prefix_data ~high:63 ~low:0) in
  let current_offset =
    a.packet_byte_offset_o +:. 12 +: mux2 prefetched (uresize count ~width:16) (zero 16)
  in
  let offset = reg spec ~enable:(collect &: prefix_first |: prefetched) current_offset in
  let message_offset = mux2 (prefix_first |: prefetched) current_offset offset in

  (* contents packed struct map *)
  (* glorified parallele slicer, only latches into the relevant pipeline reg when necessary *)
  let parsed : _ T.Message_context.t =
    { msg_size        = select header_head ~high:15 ~low:0
    ; block_length    = select header_head ~high:31 ~low:16
    ; template_id     = select header_head ~high:47 ~low:32
    ; schema_id       = select header_head ~high:63 ~low:48
    ; schema_version  =
        mux2
          prefix_tail
          (select a.data_o ~high:15 ~low:0)
          (select prefix_data ~high:79 ~low:64)
    ; message_header_present = vdd
    ; transaction_time = zero 64
    ; transaction_time_present = gnd
    ; packet_byte_offset = message_offset
    }
  in

  let prefix_complete = collect &: ~:split_prefix &: ~:short_prefix |: prefetch_full in
  let message =
    T.Message_context.Of_signal.unpack
      (reg spec ~enable:prefix_complete (T.Message_context.Of_signal.pack parsed))
  in
  let supported =
    List.fold_left
      ( |: )
      gnd
      (List.map (fun id -> parsed.template_id ==:. id) supported_templates)
  in
  let invalid_size = prefix_complete &: (parsed.msg_size <:. 10) in
  let unsupported = prefix_complete &: ~:invalid_size &: ~:supported in
  let consumed_prefix_span = mux2 prefetch_full prefix_span required in
  let prefix_ends_packet = a.boundary_o &: (a.available_o ==: consumed_prefix_span) in
  let available_count =
    mux2 (a.available_o <:. 8) a.available_o (of_int_trunc ~width:5 8)
  in
  (* A known short body is diagnosed before exposing its first beat. Once started, already
     completed chunks remain provisional; the diagnostic aborts the collector. *)
  let short_body =
    body_state
    |: skip_state
    &: a.valid_o
    &: a.boundary_o
    &: (uresize a.available_o ~width:16 <: remaining)
  in
  let body_valid = body_state &: a.valid_o &: ~:short_body &: (a.available_o >=: count) in
  let skip = skip_state &: a.valid_o &: ~:short_body &: (a.available_o >=: count) in
  let body_transfer = body_valid &: output_ready in
  let advance = body_transfer |: skip in
  let end_message = remaining <=:. 8 in
  let end_packet = a.boundary_o &: (a.available_o ==: count) in
  retiring_packet <-- (advance &: end_message &: end_packet);
  (* A short final body beat can retire together with the next message's prefix. Parse ten
     bytes when they fit, otherwise save eight and finish on the next cycle. The last body
     item still carries the old registered message context. *)
  prefetch_full
  <-- (advance
       &: end_message
       &: ~:end_packet
       &: (count <=:. 5)
       &: (a.available_o >=: count +:. 10));
  prefetch_head
  <-- (advance
       &: end_message
       &: ~:end_packet
       &: ~:prefetch_full
       &: (count <=:. 7)
       &: (a.available_o >=: count +:. 8)
       &: ~:(a.boundary_o &: (a.available_o ==: count +:. 8)));
  let drain = draining &: a.valid_o in
  let drain_end = a.boundary_o &: (a.available_o <=:. 8) in
  let missing_offset = a.packet_byte_offset_o +: uresize a.available_o ~width:16 +:. 12 in
  let prefix_missing_body =
    prefix_complete &: ~:invalid_size &: prefix_ends_packet &: (parsed.msg_size >:. 10)
  in
  let failure =
    short_prefix |: invalid_size |: unsupported |: short_body |: prefix_missing_body
  in
  let diagnostic_code =
    mux2
      short_prefix
      (of_int_trunc ~width:8 T.Diagnostic_code.message_beyond_packet)
      (mux2
         invalid_size
         (of_int_trunc ~width:8 T.Diagnostic_code.invalid_message_size)
         (mux2
            unsupported
            (of_int_trunc ~width:8 T.Diagnostic_code.unsupported_template)
            (of_int_trunc ~width:8 T.Diagnostic_code.message_beyond_packet)))
  in
  let diagnostic_message =
    T.Message_context.Of_signal.mux2
      short_prefix
      { (T.Message_context.Of_signal.zero ()) with packet_byte_offset = message_offset }
      (T.Message_context.Of_signal.mux2 prefix_complete parsed message)
  in
  let diagnostic_offset =
    mux2
      invalid_size
      message_offset
      (mux2 unsupported (message_offset +:. 4) missing_offset)
  in
  let diagnostic =
    T.Event.Of_signal.pack
      { (T.Event.Of_signal.zero ()) with
        kind = of_int_trunc ~width:2 T.Event_kind.diagnostic
      ; packet
      ; message = diagnostic_message
      ; diagnostic_code
      ; diagnostic_byte_offset = diagnostic_offset
      }
  in
  let error = reg spec ~enable:failure diagnostic in
  (* Unsupported at the exact prefix boundary needs a second truncation diagnostic. *)
  let pending_truncation =
    reg spec ~enable:failure (unsupported &: prefix_missing_body)
  in
  let resume =
    let to_ (target : Resume.Cases.t) = Resume.Of_signal.of_enum target in
    let mux2 = Resume.Of_signal.mux2 in
    Resume.Of_signal.reg
      ~enable:failure
      spec
      (mux2
         short_body
         (to_ Drain)
         (mux2
            (short_prefix |: invalid_size)
            (mux2
               (a.boundary_o &: (a.available_o <=: consumed_prefix_span))
               (to_ Idle)
               (to_ Drain))
            (mux2
               prefix_ends_packet
               (to_ Idle)
               (mux2 (parsed.msg_size ==:. 10) (to_ Prefix_first) (to_ Skip)))))
  in
  let error_transfer = active &: error_state &: output_ready in

  (* Transition fragments shared between arms. *)
  let after_prefix =
    Always.[ if_ (parsed.msg_size ==:. 10)
               [ sm.set_next State.Empty_body ]
               [ sm.set_next State.Body ] ]
  in
  let continuation =
    Always.[ if_ prefetch_full after_prefix
             @@ elif prefetch_head [ sm.set_next State.Prefix_tail ]
             @@ elif end_packet [ sm.set_next State.Idle ]
             [ sm.set_next State.Prefix_first ] ]
  in
  (* [Prefix_first] and [Prefix_tail] differ only in [required]/[split_prefix], which are
     already folded into [collect]; likewise [Body] and [Skip] differ only in whether the
     beat reaches the output. Each pair therefore shares one transition arm. *)
  let collecting_arm =
    Always.[ if_ failure [ sm.set_next State.Error ]
             @@ elif collect
                  [ if_ split_prefix [ sm.set_next State.Prefix_tail ] after_prefix ]
                  [] ]
  in
  (* [start] outranks [advance &: end_message] here: both fire on an early start, and the
     next packet's prefix has to win over retiring to [Idle]. *)
  let streaming_arm =
    Always.[ if_ failure [ sm.set_next State.Error ]
             @@ elif start [ sm.set_next State.Prefix_first ]
             @@ elif (advance &: end_message) continuation
             [] ]
  in
  Always.(compile
    [ (* Sticky from the packet's final input beat; [start] reloads it for the next. *)
      r.input_done <-- (input_done |: (input_transfer &: input.beat.last))
    ; when_ (idle |: start) [ r.input_done <-- (start &: input.beat.last) ]
    ; when_ advance [ r.remaining <-- remaining -: uresize count ~width:16 ]
    ; when_ prefix_complete [ r.remaining <-- parsed.msg_size -:. 10 ]
    ; when_ body_transfer [ r.started <-- vdd ]
    ; when_ (collecting |: prefetched) [ r.started <-- gnd ]
    ; when_ error_transfer [ r.second_error <-- (pending_truncation &: ~:second_error) ]
    ; when_ failure [ r.second_error <-- gnd ]

    ; sm.switch
        [ State.Idle,         [ when_ start [ sm.set_next State.Prefix_first ] ]
        ; State.Prefix_first, collecting_arm
        ; State.Prefix_tail,  collecting_arm
        ; State.Body,         streaming_arm
        ; State.Skip,         streaming_arm
        ; State.Empty_body,
          [ when_ output_ready
              [ if_ (input_done &: (a.available_o ==:. 0))
                  [ sm.set_next State.Idle ]
                  [ sm.set_next State.Prefix_first ] ] ]
        ; State.Drain,        [ when_ (drain &: drain_end) [ sm.set_next State.Idle ] ]
        ; State.Error,
          [ when_ error_transfer
              [ if_ (pending_truncation &: ~:second_error)
                  [ sm.set_next State.Error ]
                  [ Resume.Of_always.match_ resume
                      [ Resume.Cases.Idle, [ sm.set_next State.Idle ]
                      ; Prefix_first,      [ sm.set_next State.Prefix_first ]
                      ; Skip,              [ sm.set_next State.Skip ]
                      ; Drain,             [ sm.set_next State.Drain ]
                      ] ] ] ]
        ]
    ]);
  consume_valid <-- (collect |: advance |: drain);
  consume_count
  <-- uresize
        (mux2
           prefetched
           (count
            +: mux2 prefetch_full (of_int_trunc ~width:5 10) (of_int_trunc ~width:5 8))
           (mux2
              collecting
              (mux2 (a.available_o <: required) a.available_o required)
              (mux2 draining available_count count)))
        ~width:4;
  List.iter
    (fun (name, signal) -> ignore (signal -- ("phase6_iterator_" ^ name)))
    [ "offset", a.packet_byte_offset_o
    ; "available", a.available_o
    ; "consume", consume_valid
    ; "count", consume_count
    ; "body", body_transfer
    ; "ready", output_ready
    ; "prefix", prefix_complete
    ];
  let blank = T.Message_item.Of_signal.zero () in
  let keep =
    mux
      (uresize count ~width:4)
      (List.init 9 (fun n -> of_int_trunc ~width:8 ((1 lsl n) - 1)))
  in
  let body =
    { blank with
      kind = mux2 started (of_int_trunc ~width:2 T.Message_item_kind.body) (zero 2)
    ; packet =
        T.Packet_context.Of_signal.mux2
          started
          (T.Packet_context.Of_signal.zero ())
          packet
    ; message =
        T.Message_context.Of_signal.mux2
          started
          (T.Message_context.Of_signal.zero ())
          message
    ; beat =
        { data = Byte_aligner.mask_data (select a.data_o ~high:63 ~low:0) keep
        ; keep
        ; first = ~:started
        ; last = end_message
        }
    }
  in
  let empty = { blank with packet; message; body_empty = vdd } in
  let saved_error = T.Event.Of_signal.unpack error in
  let saved_error =
    { saved_error with
      diagnostic_code =
        mux2
          second_error
          (of_int_trunc ~width:8 T.Diagnostic_code.message_beyond_packet)
          saved_error.diagnostic_code
    ; diagnostic_byte_offset =
        mux2
          second_error
          (saved_error.message.packet_byte_offset +:. 10)
          saved_error.diagnostic_byte_offset
    }
  in
  let diagnostic_item =
    { blank with
      kind = of_int_trunc ~width:2 T.Message_item_kind.diagnostic
    ; diagnostic = T.Event.Of_signal.mux2 idle input.diagnostic saved_error
    }
  in
  let output_valid =
    active
    &: (idle
        &: i.valid_i
        &: is_diagnostic
        |: body_valid
        |: empty_body_state
        |: error_state)
  in
  let output_item =
    T.Message_item.Of_signal.pack
      (T.Message_item.Of_signal.mux2
         (idle |: error_state)
         diagnostic_item
         (T.Message_item.Of_signal.mux2 empty_body_state empty body))
  in
  (* Two effective items absorb the decoder's final-dimension/next-start handoff; a single
     slot propagates those short pauses into an accumulating padded-packet backlog. Three
     slots are needed to keep two effective, because non-greedy admission cannot refill
     the last slot in the cycle it drains. See docs/phase6_notes.md.

     Depth 3 leaves the backing array two Message_items deep, which is past Vivado's
     block-memory inference threshold: at this width that is twelve BRAM tiles to hold two
     entries. Force distributed RAM instead, so the depth is bought in LUTRAM sized to the
     two entries actually stored. See docs/retargeting.md. *)
  let output =
    Elastic_fifo.create
      ~depth:3
      ~ram_attributes:[ Rtl_attribute.Vivado.Ram_style.distributed ]
      scope
      ~clock:i.clock_i
      ~reset:i.reset_i
      ~en:i.en_i
      ~data:output_item
      ~valid:output_valid
      ~ready:i.ready_i
  in
  output_ready <-- output.ready;
  { O.ready_o = ready
  ; valid_o = output.valid
  ; item_o = output.data
  ; idle_o = idle &: (a.available_o ==:. 0) &: ~:(output.valid)
  }
[@@@ocamlformat "enable"]

let hierarchical ~supported_templates ?instance scope i =
  let module H = Hierarchy.In_scope (I) (O) in
  H.hierarchical
    ?instance
    ~name:"cme_sbe_message_iterator"
    ~scope
    (create ~supported_templates)
    i
;;
