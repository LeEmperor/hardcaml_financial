(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "validation_core_testbench.ml" *)
(* Board integration from the recovered UDP payload to the UART pin: destination-port
   selection, the feed parser, and the counter sink.

   Packets are tagged with the UDP port the network stack would report. The scenario
   interleaves selected and filtered traffic so the central board claim -- that unrelated
   host chatter on the validation link cannot perturb parser sequence state -- is
   exercised rather than assumed. Sequence numbers are assigned only to selected packets,
   so if a filtered packet ever reached the parser the very next selected packet would
   raise a sequence-gap diagnostic and the expected counters would not match.

   Each packet also carries the physical-frame verdict the MAC would report for the frame
   that delivered it. [Udp_rx_64_mac_top] is cut-through: a frame whose FCS or IPv4 header
   checksum is wrong has already been streamed to the application by the time the verdict
   arrives, so a bad frame both parses and raises a network error. That is the board
   behaviour the phase 7 acceptance cases [late_bad_fcs] and [bad_ip_checksum] pin down,
   and driving the status channel here is the only way to reproduce them in Cyclesim. *)

open! Core
open! Hardcaml
open Hardcaml_verif
module F = Schema_test_support.Schema_fixture
module Stream = Stream_test_support.Stream_fixture
module Core_dut = Cme_board_validation.Cme_validation_core

let dest_port = 31337
let counter_count = 8

(* Largest UDP payload that fits an untagged 1500-byte Ethernet MTU: 1500 - 20 (IPv4) - 8
   (UDP). The board sender in validation/phase7 is bound by the same limit. *)
let max_udp_payload = 1472

module Packet = struct
  (* [port] is the destination port the network stack reports for the packet's first beat.
     [crc_error] and [checksum_ok] are the MAC's verdicts for the delivering frame, raised
     after the payload has already been streamed. *)
  type t =
    { port : int
    ; payload : string
    ; crc_error : bool
    ; checksum_ok : bool
    }
end

module Observation = struct
  type t =
    { packets : int
    ; updates : int
    ; end_of_event : int
    ; diagnostics : int
    ; crc_errors : int
    ; ip_errors : int
    ; sequence_gaps : int
    ; duplicates : int
    ; filtered_beats : int
    ; (* Cycles a filtered packet was accepted while the parser was refusing input. *)
      filtered_while_parser_busy : int
    ; (* Stimulus shape, reported so a heavy scenario cannot silently shrink. *)
      beats : int
    ; (* Packets whose final beat is full, i.e. keep = 0xff rather than a partial tail. *)
      full_tail_beats : int
    ; (* Cycles the scenario needed, including the fixed drain window. Throughput
         evidence: it moves with backpressure, so a stalling datapath shows up here. It is
         kept out of the printed form deliberately -- a latency change would otherwise
         rewrite every counter trace in the suite. Assert on it directly instead. *)
      cycles : int [@sexp_drop_if fun _ -> true]
    }
  [@@deriving sexp_of, compare, equal]

  (* Counters alone. The remaining fields are schedule- or stimulus-dependent, so two runs
     of the same traffic under different stall schedules are only comparable through this. *)
  let counters_only t =
    { t with
      filtered_beats = 0
    ; filtered_while_parser_busy = 0
    ; beats = 0
    ; full_tail_beats = 0
    ; cycles = 0
    }
  ;;
end

let unpack bits =
  List.init counter_count ~f:(fun k ->
    Bits.to_int_trunc (Bits.select bits ~high:((32 * k) + 31) ~low:(32 * k)))
;;

(* Cycles with no accepted beat that end the run once the stimulus is exhausted. Long
   enough for the parser to retire a packet and for the sink to absorb the final frame
   verdict. *)
let drain_cycles = 400

let run
  ?(seed = 1)
  ?(stalls = true)
  ?(uart_divisor = 4)
  ?(snapshot_cycles = 4000)
  ?(max_cycles = 60_000)
  (packets : Packet.t list)
  =
  let module Dut = struct
    module I = Core_dut.I
    module O = Core_dut.O

    let name = "cme_validation_core"
    let create scope i = Core_dut.create ~dest_port ~uart_divisor ~snapshot_cycles scope i
  end
  in
  let module Fixture = Sim_fixture.Make (Dut) in
  let module Step = Fixture.Step in
  let random = Random.State.make [| seed; 0x424f41 |] in
  let chance n = stalls && Random.State.int random n = 0 in
  let source =
    List.concat_map packets ~f:(fun (packet : Packet.t) ->
      Stream.packet packet.payload |> List.map ~f:(fun beat -> packet, beat))
  in
  let beats = List.length source in
  let full_tail_beats =
    List.count source ~f:(fun (_, (beat : Stream.beat)) -> beat.last && beat.keep = 0xff)
  in
  let testbench (handler : Step.Handler.t @ local) _ =
    let todo = ref source in
    let filtered_beats = ref 0 in
    let filtered_while_parser_busy = ref 0 in
    let counters = ref (List.init counter_count ~f:(fun _ -> 0)) in
    let cycle = ref 0 in
    let idle_after = ref 0 in
    (* Frame verdicts owed to frames whose payload has already been handed over. *)
    let verdicts = Queue.create () in
    (* Mirrors the sink's [crc_pending] register: the CRC verdict is only meaningful on
       the enabled cycle after the one that pulsed frame_done. *)
    let crc_armed = ref false in
    while
      (not (List.is_empty !todo && !idle_after > drain_cycles)) && !cycle < max_cycles
    do
      let reset = !cycle = 0 in
      let enabled = (not reset) && not (chance 23) in
      let offer = (not (List.is_empty !todo)) && not (chance 5) in
      let packet, beat =
        match !todo with
        | (p, b) :: _ -> p, b
        | [] ->
          ( { Packet.port = dest_port
            ; payload = "x"
            ; crc_error = false
            ; checksum_ok = true
            }
          , List.hd_exn (Stream.packet "x") )
      in
      let frame_done = enabled && not (Queue.is_empty verdicts) in
      let crc_verdict, checksum_ok =
        if frame_done then Queue.dequeue_exn verdicts else false, true
      in
      let edge =
        Step.cycle
          handler
          { clock_i = Bits.gnd
          ; reset_i = Bits.of_bool reset
          ; en_i = Bits.of_bool enabled
          ; data_i = beat.data
          ; keep_i = Bits.of_int_trunc ~width:8 beat.keep
          ; valid_i = Bits.of_bool offer
          ; first_i = Bits.of_bool (offer && beat.first)
          ; last_i = Bits.of_bool (offer && beat.last)
          ; dst_port_i = Bits.of_int_trunc ~width:16 packet.port
          ; rx_frame_done_i = Bits.of_bool frame_done
          ; crc_error_i = Bits.of_bool !crc_armed
          ; checksum_ok_i = Bits.of_bool checksum_ok
          ; display_i = Bits.zero 3
          }
      in
      let before = Step.O_data.before_edge edge in
      let after = Step.O_data.after_edge edge in
      let ready = Bits.to_bool before.ready_o in
      if offer && ready
      then (
        todo := List.tl_exn !todo;
        (* The MAC reports its verdict once the whole frame has passed, so the pulse is
           owed from the cycle the payload's final beat is taken. *)
        if beat.last then Queue.enqueue verdicts (packet.crc_error, packet.checksum_ok);
        if packet.port <> dest_port then incr filtered_beats;
        idle_after := 0)
      else incr idle_after;
      (* Filtered traffic must never inherit the parser's backpressure. A filtered beat
         accepted in a cycle where a selected beat would have been refused is the only
         evidence that the two paths are genuinely decoupled. *)
      if offer && packet.port <> dest_port && ready && enabled && not reset
      then incr filtered_while_parser_busy;
      if reset then crc_armed := false else if enabled then crc_armed := crc_verdict;
      counters := unpack after.counters_o;
      incr cycle
    done;
    if not (List.is_empty !todo) then failwith "core testbench failed to drain";
    match !counters with
    | [ packets; updates; ends; diagnostics; crc; ip; gaps; duplicates ] ->
      { Observation.packets
      ; updates
      ; end_of_event = ends
      ; diagnostics
      ; crc_errors = crc
      ; ip_errors = ip
      ; sequence_gaps = gaps
      ; duplicates
      ; filtered_beats = !filtered_beats
      ; filtered_while_parser_busy = !filtered_while_parser_busy
      ; beats
      ; full_tail_beats
      ; cycles = !cycle
      }
    | _ -> failwith "counter unpacking"
  in
  Fixture.run_with_timeout ~timeout:(max_cycles + 10) ~testbench
;;

let selected payload =
  { Packet.port = dest_port; payload; crc_error = false; checksum_ok = true }
;;

let filtered ?(port = dest_port + 1) payload =
  { Packet.port; payload; crc_error = false; checksum_ok = true }
;;

(* The delivering frame fails FCS. Cut-through means the payload still reached the parser,
   so the packet parses and the network error is counted alongside it. *)
let bad_fcs (packet : Packet.t) = { packet with crc_error = true }
let bad_ip (packet : Packet.t) = { packet with checksum_ok = false }

(* MatchEventIndicator bit 7 is LastMsgOfEvent: without it the parser emits the update but
   no end-of-event marker. The board sender in validation/phase7/board_acceptance.py sets
   it, so the simulation stimulus sets it too and the two agree on expected counters. *)
let last_msg_of_event = 0x80

let simple ?(match_event_indicator = last_msg_of_event) sequence =
  F.packet sequence [ F.message ~match_event_indicator [ F.default_entry ] ]
;;

(* ------------------------------------------------------------------------------------
   Heavy stimulus.

   Every builder below emits wire-valid template 46 traffic unless its name says
   otherwise. Sizes are written in terms of the encoding rather than as literals so a
   schema change moves them instead of silently invalidating a "near MTU" claim.
   ------------------------------------------------------------------------------------ *)

(* 10-byte SBE header + 11-byte root block + 3-byte MBP dimension + 8-byte order
   dimension, with no entries and no order-ID group. *)
let message_overhead = 32
let entry_bytes = 32

(* 4-byte sequence number + 8-byte sending time. *)
let packet_header_bytes = 12
let repeated_entries count = List.init count ~f:(fun _ -> F.default_entry)

(* Reserved root padding that lands the payload on a whole number of 8-byte beats. A
   packet header is 12 bytes and an unpadded message is a multiple of 8, so this is the
   only route to a full final beat. Matches ALIGNED_ROOT_BLOCK in board_acceptance.py. *)
let full_tail_root_block = 11 + 4

(* One message per entry count, the direct counterpart of [pack_messages] in
   validation/phase7/board_acceptance.py. With [last_only] the LastMsgOfEvent bit is set
   on the final message alone, which is how a real event spanning several messages is
   flagged; otherwise every message closes its own event. *)
let shaped ?(last_only = false) ?(root_block = 11) counts sequence =
  let count = List.length counts in
  F.packet
    sequence
    (List.mapi counts ~f:(fun index entries ->
       let match_event_indicator =
         if last_only && index < count - 1 then 0 else last_msg_of_event
       in
       F.message ~match_event_indicator ~root_block (repeated_entries entries)))
;;

(* [messages] messages of [entries] MBP entries each. *)
let heavy ?(messages = 1) ?(entries = 1) ?(last_only = false) sequence =
  shaped ~last_only (List.init messages ~f:(fun _ -> entries)) sequence
;;

(* One message with as many entries as an MTU-sized datagram can carry. *)
let mtu_entries = (max_udp_payload - packet_header_bytes - message_overhead) / entry_bytes

let near_mtu ?(last_only = false) sequence =
  heavy ~messages:1 ~entries:mtu_entries ~last_only sequence
;;

(* The same byte budget spent on many small messages instead of one deep group. *)
let mtu_messages =
  (max_udp_payload - packet_header_bytes) / (message_overhead + entry_bytes)
;;

let near_mtu_many_messages ?(last_only = true) sequence =
  heavy ~messages:mtu_messages ~entries:1 ~last_only sequence
;;

(* The deepest group that fits once root padding has taken its bytes out of the entry
   budget: MTU-sized and ending on a full beat at once. *)
let mtu_aligned_entries =
  (max_udp_payload - packet_header_bytes - message_overhead - (full_tail_root_block - 11))
  / entry_bytes
;;

(* A payload whose length is a multiple of eight, so its final beat carries keep = 0xff
   instead of the partial tail every other fixture produces. *)
let aligned ?(entries = 1) sequence =
  let payload = shaped ~root_block:full_tail_root_block [ entries ] sequence in
  if String.length payload % 8 <> 0
  then
    raise_s
      [%message
        "aligned fixture is not a whole number of beats" (String.length payload : int)];
  payload
;;

(* Error-path stimulus. Each raises one parser diagnostic without disturbing sequencing,
   so surrounding traffic must still be counted normally. *)
let unsupported_template ?(entries = 1) sequence =
  F.packet
    sequence
    [ F.message ~template:99 []
    ; F.message ~match_event_indicator:last_msg_of_event (repeated_entries entries)
    ]
;;

(* A declared message size below the 10-byte SBE header cannot describe any message. *)
let invalid_message_size sequence =
  F.packet sequence [ F.raw_message ~declared_size:9 "bad" ]
;;

(* A message whose declared size runs past the end of the datagram. *)
let message_beyond_packet sequence =
  F.packet sequence [ F.raw_message ~declared_size:1000 "short" ]
;;
