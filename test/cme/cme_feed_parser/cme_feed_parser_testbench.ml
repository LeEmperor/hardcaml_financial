(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "cme_feed_parser_testbench.ml" *)
(* Integrated Step fixture: compare every event bit with the independent XML oracle.
   Transfers are sampled before the edge; completion requires the idle control fence. *)

open! Core
open! Hardcaml
open! Cme_of_hardcaml
module G = Cme_schema.Golden_decoder
module F = Schema_test_support.Schema_fixture
module T = Cme_types
module Stream = Stream_test_support.Stream_fixture

let int width = Bits.of_int_trunc ~width
let int64 width = Bits.of_int64_trunc ~width
let bool = Bits.of_bool

let packet_bits (p : G.packet_context) : Bits.t T.Packet_context.t =
  { ingress_timestamp = int64 64 p.ingress_timestamp
  ; source_id = int 1 p.source_id
  ; packet_seq = int64 32 p.packet_seq
  ; sending_time = int64 64 p.sending_time
  ; packet_header_present = bool p.packet_header_present
  ; channel_valid = bool p.channel_valid
  }
;;

let message_bits (m : G.message_context) : Bits.t T.Message_context.t =
  { msg_size = int 16 m.msg_size
  ; block_length = int 16 m.block_length
  ; template_id = int 16 m.template_id
  ; schema_id = int 16 m.schema_id
  ; schema_version = int 16 m.schema_version
  ; message_header_present = bool m.message_header_present
  ; transaction_time = int64 64 m.transaction_time
  ; transaction_time_present = bool m.transaction_time_present
  ; packet_byte_offset = int 16 m.packet_byte_offset
  }
;;

let code = function
  | G.Diagnostic_code.Sequence_gap -> 1
  | Duplicate_or_late -> 2
  | Truncated_packet_header -> 3
  | Invalid_message_size -> 4
  | Message_beyond_packet -> 5
  | Unsupported_template -> 6
  | Schema_incompatibility -> 7
  | Invalid_enum -> 8
;;

let event_bits event =
  let blank = T.Event.Of_bits.zero () in
  let optional width value = int64 width (Option.value value ~default:0L) in
  let e =
    match event with
    | G.Mbp_update u ->
      { blank with
        packet = packet_bits u.packet
      ; message = message_bits u.message
      ; entry_index = int 16 u.entry_index
      ; entry_count = int 16 u.entry_count
      ; security_id = int64 32 u.security_id
      ; rpt_seq = int64 32 u.rpt_seq
      ; price_mantissa = optional 64 u.price_mantissa
      ; price_is_null = bool (Option.is_none u.price_mantissa)
      ; entry_size = optional 32 u.entry_size
      ; entry_size_is_null = bool (Option.is_none u.entry_size)
      ; number_of_orders = optional 32 u.number_of_orders
      ; number_of_orders_is_null = bool (Option.is_none u.number_of_orders)
      ; price_level = int 8 u.price_level
      ; update_action = int 8 u.update_action
      ; entry_type = int 8 u.entry_type
      ; tradeable_size = optional 32 u.tradeable_size
      ; tradeable_size_is_null = bool (Option.is_none u.tradeable_size)
      ; match_event_indicator = int 8 u.match_event_indicator
      ; message_last = bool u.message_last
      }
    | End_of_event e ->
      { blank with
        kind = int 2 1
      ; packet = packet_bits e.packet
      ; message = message_bits e.message
      ; match_event_indicator = int 8 e.match_event_indicator
      }
    | Diagnostic d ->
      { blank with
        kind = int 2 2
      ; packet = packet_bits d.packet
      ; message = Option.value_map d.message ~default:blank.message ~f:message_bits
      ; diagnostic_code = int 8 (code d.code)
      ; expected_seq = optional 32 d.expected_seq
      ; expected_seq_present = bool (Option.is_some d.expected_seq)
      ; diagnostic_byte_offset = int 16 d.byte_offset
      }
  in
  T.Event.Of_bits.pack e
;;

let observe bits =
  let e = T.Event.Of_bits.unpack bits in
  let b = Bits.to_bool
  and n = Bits.to_int_trunc
  and wide = Bits.to_int64_trunc in
  let signed v = Bits.sresize v ~width:64 |> wide in
  let packet : G.packet_context =
    { ingress_timestamp = wide e.packet.ingress_timestamp
    ; source_id = n e.packet.source_id
    ; packet_seq = wide e.packet.packet_seq
    ; sending_time = wide e.packet.sending_time
    ; packet_header_present = b e.packet.packet_header_present
    ; channel_valid = b e.packet.channel_valid
    }
  in
  let m = e.message in
  let message : G.message_context =
    { msg_size = n m.msg_size
    ; block_length = n m.block_length
    ; template_id = n m.template_id
    ; schema_id = n m.schema_id
    ; schema_version = n m.schema_version
    ; message_header_present = b m.message_header_present
    ; transaction_time = wide m.transaction_time
    ; transaction_time_present = b m.transaction_time_present
    ; packet_byte_offset = n m.packet_byte_offset
    }
  in
  let optional value null = if b null then None else Some (signed value) in
  let event =
    match n e.kind with
    | 0 ->
      G.Mbp_update
        { packet
        ; message
        ; entry_index = n e.entry_index
        ; entry_count = n e.entry_count
        ; security_id = signed e.security_id
        ; rpt_seq = wide e.rpt_seq
        ; price_mantissa = optional e.price_mantissa e.price_is_null
        ; price_exponent = -9
        ; entry_size = optional e.entry_size e.entry_size_is_null
        ; number_of_orders = optional e.number_of_orders e.number_of_orders_is_null
        ; price_level = n e.price_level
        ; update_action = n e.update_action
        ; entry_type = n e.entry_type
        ; tradeable_size = optional e.tradeable_size e.tradeable_size_is_null
        ; match_event_indicator = n e.match_event_indicator
        ; message_last = b e.message_last
        }
    | 1 ->
      End_of_event { packet; message; match_event_indicator = n e.match_event_indicator }
    | 2 ->
      let code =
        match n e.diagnostic_code with
        | 1 -> G.Diagnostic_code.Sequence_gap
        | 2 -> Duplicate_or_late
        | 3 -> Truncated_packet_header
        | 4 -> Invalid_message_size
        | 5 -> Message_beyond_packet
        | 6 -> Unsupported_template
        | 7 -> Schema_incompatibility
        | 8 -> Invalid_enum
        | _ -> failwith "unexpected diagnostic code"
      in
      let message =
        if Bits.equal
             (T.Message_context.Of_bits.pack m)
             (T.Message_context.Of_bits.pack (T.Message_context.Of_bits.zero ()))
        then None
        else Some message
      in
      Diagnostic
        { packet
        ; message
        ; code
        ; expected_seq =
            (if b e.expected_seq_present then Some (wide e.expected_seq) else None)
        ; byte_offset = n e.diagnostic_byte_offset
        }
    | _ -> failwith "reserved event kind"
  in
  if not (Bits.equal bits (event_bits event))
  then failwith "nonzero unused fields or noncanonical null payload";
  event
;;

type control =
  { after_packets : int
  ; session_reset : bool
  ; resync : int64 option
  }
[@@deriving sexp]

module Observation = struct
  type accepted_beat =
    { cycle : int
    ; packet_index : int
    ; first_byte : int
    ; byte_count : int
    }
  [@@deriving sexp]

  type t =
    { events : G.event list
    ; event_cycles : int list
    ; accepted_beats : accepted_beat list
    ; input_stalls : int
    ; output_stalls : int
    ; controls : int
    ; cycles : int
    ; cancelled_work : bool
    }
  [@@deriving sexp]
end

module Make (Config : sig
    val config : Cme_config.t
  end) =
struct
  module Dut = struct
    include Cme_feed_parser

    let create scope i = create ~config:Config.config scope i
    let name = "cme_feed_parser"
  end

  module Fixture = Hardcaml_verif.Sim_fixture.Make (Dut)
  module Step = Fixture.Step

  let run
    ?(seed = 1)
    ?(stalls = true)
    ?(sink_block_until = 0)
    ?(beat_gap = 0)
    ?(controls = [])
    ?reset_at
    ?(check_model = true)
    ?(trace = false)
    ?(schema_file = F.schema_file)
    ?(timestamp = fun index -> Int64.(0xfedc_ba98_7654_3210L + of_int index))
    payloads
    =
    let random = Random.State.make [| seed; 0x504835 |] in
    let chance n = stalls && Random.State.int random n = 0 in
    let source =
      List.concat_mapi payloads ~f:(fun index payload ->
        let timestamp = timestamp index in
        Stream.packet ~timestamp:(int64 64 timestamp) payload
        |> List.map ~f:(fun beat -> payload, timestamp, beat))
    in
    let testbench (handler : Step.Handler.t @ local) _ =
      let oracle = G.create ~schema_file in
      let todo = ref source
      and pending = ref None
      and next_offer = ref 0 in
      let requests = ref controls
      and packets = ref 0
      and accepted_controls = ref 0 in
      let expected = Queue.create ()
      and events = ref [] in
      let event_cycles = ref []
      and accepted_beats = ref []
      and packet_byte = ref 0 in
      let held = ref None
      and cycle = ref 0
      and finished = ref false in
      let input_stalls = ref 0
      and output_stalls = ref 0
      and cancelled_work = ref false in
      let input_monitor = Stream.Monitor.create () in
      while (not !finished) && !cycle < 200000 do
        let reset = !cycle = 0 || Option.equal Int.equal reset_at (Some !cycle) in
        let enabled = (not reset) && not (chance 19) in
        if reset
        then (
          if !cycle > 0 then cancelled_work := not (Queue.is_empty expected);
          todo := source;
          pending := None;
          next_offer := 0;
          requests := controls;
          packets := 0;
          accepted_controls := 0;
          Queue.clear expected;
          events := [];
          event_cycles := [];
          accepted_beats := [];
          packet_byte := 0;
          held := None;
          G.session_reset oracle);
        if (not reset)
           && !cycle >= !next_offer
           && Option.is_none !pending
           && (not (List.is_empty !todo))
           && not (chance 4)
        then pending := Some (List.hd_exn !todo);
        let payload, timestamp, beat =
          Option.value !pending ~default:("x", 0L, List.hd_exn (Stream.packet "x"))
        in
        let request =
          List.hd !requests |> Option.filter ~f:(fun c -> !packets >= c.after_packets)
        in
        let sink_ready = !cycle >= sink_block_until && not (chance 3) in
        let edge =
          Step.cycle
            handler
            { clock_i = Bits.gnd
            ; reset_i = bool reset
            ; en_i = bool enabled
            ; data_i = beat.data
            ; keep_i = int 8 beat.keep
            ; valid_i = bool (Option.is_some !pending)
            ; first_i = bool beat.first
            ; last_i = bool beat.last
            ; ingress_timestamp_i =
                (if beat.first then beat.timestamp else int64 64 (Int64.of_int !cycle))
            ; session_reset_i = bool (Option.exists request ~f:(fun c -> c.session_reset))
            ; resync_valid_i =
                bool (Option.exists request ~f:(fun c -> Option.is_some c.resync))
            ; resync_next_seq_i =
                int64
                  32
                  (Option.bind request ~f:(fun c -> c.resync) |> Option.value ~default:0L)
            ; event_ready_i = bool sink_ready
            }
        in
        let o = Step.O_data.before_edge edge in
        let ready = Bits.to_bool o.ready_o
        and valid = Bits.to_bool o.event_valid_o
        and control_ready = Bits.to_bool o.control_ready_o in
        Stream.Monitor.observe
          input_monitor
          ~reset
          ~active:enabled
          ~valid:(Option.is_some !pending)
          ~ready
          beat;
        if not enabled then assert ((not ready) && (not valid) && not control_ready);
        if not reset
        then
          Option.iter !held ~f:(fun old ->
            assert (Bits.equal old o.event_o);
            if enabled then assert valid);
        if valid
        then (
          held := if sink_ready then None else Some o.event_o;
          if not sink_ready then incr output_stalls);
        Option.iter request ~f:(fun c ->
          if control_ready
          then (
            assert (Queue.is_empty expected);
            assert (not ready);
            if c.session_reset
            then G.session_reset oracle
            else G.resync oracle ~next_seq:(Option.value_exn c.resync);
            requests := List.tl_exn !requests;
            incr accepted_controls));
        if Option.is_some !pending
        then
          if ready
          then (
            let byte_count = Int.popcount beat.keep in
            accepted_beats
            := { Observation.cycle = !cycle
               ; packet_index = !packets
               ; first_byte = !packet_byte
               ; byte_count
               }
               :: !accepted_beats;
            packet_byte := if beat.last then 0 else !packet_byte + byte_count;
            if beat.first && check_model
            then
              List.iter
                (G.decode_payload ~ingress_timestamp:timestamp oracle payload)
                ~f:(Queue.enqueue expected);
            if beat.last then incr packets;
            todo := List.tl_exn !todo;
            pending := None;
            next_offer := !cycle + beat_gap + 1)
          else if enabled
          then incr input_stalls;
        if valid && sink_ready
        then (
          let actual = observe o.event_o in
          if check_model
          then (
            let expected_event = Queue.dequeue_exn expected in
            if not (Bits.equal o.event_o (event_bits expected_event))
            then
              raise_s
                [%message
                  "normalized event mismatch"
                    (!cycle : int)
                    (actual : G.event)
                    (expected_event : G.event)]);
          events := actual :: !events;
          event_cycles := !cycle :: !event_cycles);
        finished
        := !cycle > 0
           && Option.value_map reset_at ~default:true ~f:(fun at -> !cycle > at)
           && List.is_empty !todo
           && Option.is_none !pending
           && List.is_empty !requests
           && control_ready;
        incr cycle
      done;
      if not !finished
      then
        raise_s
          [%message
            "parser failed to drain"
              (!cycle : int)
              (List.length !events : int)
              (Queue.length expected : int)];
      assert (Queue.is_empty expected);
      { Observation.events = List.rev !events
      ; event_cycles = List.rev !event_cycles
      ; accepted_beats = List.rev !accepted_beats
      ; input_stalls = !input_stalls
      ; output_stalls = !output_stalls
      ; controls = !accepted_controls
      ; cycles = !cycle
      ; cancelled_work = !cancelled_work
      }
    in
    if not trace
    then Fixture.run_with_timeout ~timeout:200005 ~testbench
    else (
      let scope =
        Scope.create ~flatten_design:true ~auto_label_hierarchical_ports:true ()
      in
      let config =
        { Cyclesim.Config.default with
          is_internal_port =
            Some
              (fun s ->
                List.exists (Signal.names s) ~f:(String.is_prefix ~prefix:"phase6_"))
        }
      in
      let simulator = Fixture.Sim.create ~config (Dut.create scope) in
      let nodes =
        List.concat_map (Cyclesim.traced simulator).internal_signals ~f:(fun s ->
          List.filter_map s.mangled_names ~f:(fun name ->
            if String.is_prefix name ~prefix:"phase6_"
            then Some (name, Option.value_exn (Cyclesim.lookup_node_or_reg simulator s))
            else None))
      in
      let cycle = ref 0 in
      let simulator =
        Cyclesim.Private.modify
          simulator
          [ ( After
            , Before_clock_edge
            , fun () ->
                if !cycle < 310
                then (
                  printf "trace cycle=%d" !cycle;
                  List.iter nodes ~f:(fun (name, node) ->
                    printf " %s=%d" name (Bits.to_int_trunc (Cyclesim.Node.to_bits node)));
                  printf "\n");
                incr cycle )
          ]
      in
      Option.value_exn (Step.run_with_timeout ~timeout:200005 () ~simulator ~testbench))
  ;;
end

module Default = Make (struct
    let config = Cme_config.default
  end)

module Small = Make (struct
    let config = { Cme_config.ingress_fifo_depth = 3; event_fifo_depth = 3 }
  end)

module Tiny = Make (struct
    let config = { Cme_config.ingress_fifo_depth = 1; event_fifo_depth = 1 }
  end)

let run = Default.run
