(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "validation_core_heavy_traffic_tests.ml" *)
(* Heavy board traffic across the composed board datapath: port selection, the feed
   parser, and the counter sink.

   The rest of the board suite establishes that the composition is wired correctly using
   one-entry, one-message packets. Everything here is about what the board has never
   actually been shown -- deep MBP groups, MTU-sized datagrams, sustained back-to-back
   bursts, full final beats, and the diagnostic codes beyond gap and duplicate. The
   randomized system stress in test/cme/cme_feed_parser covers the parser in isolation;
   these cases exist because the counters, the port filter and the network status channel
   sit outside that DUT and are what the phase 7 board run actually reads back.

   Counts are pinned by expect tests rather than restated here, so a change in what the
   parser emits per entry shows up as a diff instead of as a rewritten assertion. *)

open! Core
open Validation_core_testbench

(* Sequence numbers are consecutive for every scenario that must stay diagnostic-free. *)
let consecutive ~from count =
  List.init count ~f:(fun index -> Int64.of_int (from + index))
;;

let%expect_test "one message carrying an MTU-filling MBP group" =
  let result = run ~max_cycles:20_000 [ selected (near_mtu 1L) ] in
  print_s [%sexp (mtu_entries : int)];
  print_s [%sexp (result : Observation.t)];
  [%expect
    {|
    44
    ((packets 1) (updates 44) (end_of_event 1) (diagnostics 0) (crc_errors 0)
     (ip_errors 0) (sequence_gaps 0) (duplicates 0) (filtered_beats 0)
     (filtered_while_parser_busy 0) (beats 182) (full_tail_beats 0))
    |}]
;;

let%expect_test "the same MTU budget spent on many small messages" =
  let result = run ~max_cycles:20_000 [ selected (near_mtu_many_messages 1L) ] in
  print_s [%sexp (mtu_messages : int)];
  print_s [%sexp (result : Observation.t)];
  [%expect
    {|
    22
    ((packets 1) (updates 22) (end_of_event 1) (diagnostics 0) (crc_errors 0)
     (ip_errors 0) (sequence_gaps 0) (duplicates 0) (filtered_beats 0)
     (filtered_while_parser_busy 0) (beats 178) (full_tail_beats 0))
    |}]
;;

(* A multi-message event closes once, on the message carrying LastMsgOfEvent, rather than
   once per message. This is the shape a real incremental refresh arrives in. *)
let%expect_test "a multi-message event closes exactly once" =
  let result =
    run ~max_cycles:20_000 [ selected (heavy ~messages:8 ~entries:4 ~last_only:true 1L) ]
  in
  print_s [%sexp (result : Observation.t)];
  [%expect
    {|
    ((packets 1) (updates 32) (end_of_event 1) (diagnostics 0) (crc_errors 0)
     (ip_errors 0) (sequence_gaps 0) (duplicates 0) (filtered_beats 0)
     (filtered_while_parser_busy 0) (beats 162) (full_tail_beats 0))
    |}]
;;

let%expect_test "a sustained back-to-back burst of MTU-sized packets" =
  let result =
    run
      ~stalls:false
      ~max_cycles:60_000
      (List.map (consecutive ~from:1 12) ~f:(fun sequence -> selected (near_mtu sequence)))
  in
  print_s [%sexp (result : Observation.t)];
  [%expect
    {|
    ((packets 12) (updates 528) (end_of_event 12) (diagnostics 0) (crc_errors 0)
     (ip_errors 0) (sequence_gaps 0) (duplicates 0) (filtered_beats 0)
     (filtered_while_parser_busy 0) (beats 2184) (full_tail_beats 0))
    |}]
;;

(* Offering every beat with no idle cycle is the only way the ingress FIFO and the
   parser's backpressure are ever loaded. The datapath must still retire a packet in time
   comparable to its beat count; a pathological stall would show as a large cycle count
   against an unchanged beat count. *)
let%test_unit "a saturated burst retires close to its beat count" =
  let result =
    run
      ~stalls:false
      ~max_cycles:60_000
      (List.map (consecutive ~from:1 12) ~f:(fun sequence -> selected (near_mtu sequence)))
  in
  [%test_result: int] result.packets ~expect:12;
  [%test_result: int] result.diagnostics ~expect:0;
  let working = result.cycles - drain_cycles in
  if working > 2 * result.beats
  then
    raise_s
      [%message
        "saturated burst stalled far beyond its beat count"
          (working : int)
          ~beats:(result.beats : int)]
;;

(* Heavy traffic must be counted identically however the source and the enable are
   scheduled: a deep group spans many beats, so a stall inside one is the interesting case
   rather than a stall between packets. *)
let%test_unit "heavy counters do not depend on the stall schedule" =
  let stream =
    [ selected (near_mtu 1L)
    ; filtered (near_mtu_many_messages 900L)
    ; selected (heavy ~messages:6 ~entries:5 ~last_only:true 2L)
    ; selected (near_mtu_many_messages 3L)
    ]
  in
  let reference =
    Observation.counters_only (run ~stalls:false ~max_cycles:60_000 stream)
  in
  List.iter [ 1; 2; 3; 5; 8 ] ~f:(fun seed ->
    [%test_result: Observation.t]
      (Observation.counters_only (run ~seed ~max_cycles:60_000 stream))
      ~expect:reference)
;;

(* Every other fixture in the repository ends on a partial beat, because a packet header
   is 12 bytes and a default message is a whole number of beats. Padding the root block is
   what makes keep = 0xff on the final beat reachable at all. *)
let%expect_test "a payload that ends on a full beat" =
  let result = run [ selected (aligned 1L); selected (aligned ~entries:9 2L) ] in
  print_s [%sexp (result : Observation.t)];
  [%expect
    {|
    ((packets 2) (updates 10) (end_of_event 2) (diagnostics 0) (crc_errors 0)
     (ip_errors 0) (sequence_gaps 0) (duplicates 0) (filtered_beats 0)
     (filtered_while_parser_busy 0) (beats 52) (full_tail_beats 2))
    |}]
;;

let%test_unit "a full final beat is counted like a partial one" =
  let full = run [ selected (aligned ~entries:4 1L) ] in
  let partial = run [ selected (heavy ~entries:4 1L) ] in
  (* Non-vacuity: the two stimuli really do differ in tail shape. *)
  [%test_pred: int] (fun n -> n > 0) full.full_tail_beats;
  [%test_result: int] partial.full_tail_beats ~expect:0;
  [%test_result: Observation.t]
    (Observation.counters_only full)
    ~expect:(Observation.counters_only partial)
;;

(* The board has only ever seen sequence_gap and duplicate_or_late. These are the
   remaining codes the sink lumps into [diagnostics], reported alongside good traffic so a
   diagnostic that swallowed the rest of a packet would change the update count. *)
let%expect_test "parser diagnostics beyond gap and duplicate" =
  let result =
    run
      ~max_cycles:20_000
      [ selected (heavy ~entries:4 1L)
      ; selected (unsupported_template ~entries:4 2L)
      ; selected (invalid_message_size 3L)
      ; selected (message_beyond_packet 4L)
      ; selected (heavy ~entries:4 5L)
      ]
  in
  print_s [%sexp (result : Observation.t)];
  [%expect
    {|
    ((packets 5) (updates 12) (end_of_event 3) (diagnostics 3) (crc_errors 0)
     (ip_errors 0) (sequence_gaps 0) (duplicates 0) (filtered_beats 0)
     (filtered_while_parser_busy 0) (beats 78) (full_tail_beats 0))
    |}]
;;

let%test_unit "a malformed message does not perturb sequence state" =
  let result =
    run
      ~max_cycles:20_000
      [ selected (heavy ~entries:2 1L)
      ; selected (invalid_message_size 2L)
      ; selected (message_beyond_packet 3L)
      ; selected (unsupported_template ~entries:2 4L)
      ; selected (heavy ~entries:2 5L)
      ]
  in
  [%test_result: int] result.packets ~expect:5;
  [%test_result: int] result.sequence_gaps ~expect:0;
  [%test_result: int] result.duplicates ~expect:0;
  [%test_pred: int] (fun n -> n > 0) result.diagnostics
;;

let%test_unit "a multi-packet sequence jump is a single gap" =
  let result = run [ selected (simple 1L); selected (simple 100_000L) ] in
  [%test_result: int] result.packets ~expect:2;
  [%test_result: int] result.sequence_gaps ~expect:1;
  [%test_result: int] result.duplicates ~expect:0;
  [%test_result: int] result.updates ~expect:2
;;

(* Reproduces the phase 7 acceptance cases [late_bad_fcs] and [bad_ip_checksum]: the MAC
   is cut-through, so a frame that fails its FCS or IPv4 header checksum has already been
   parsed by the time the verdict is raised. Both the update and the network error must be
   counted. *)
let%expect_test "network frame verdicts on heavy traffic" =
  let result =
    run
      ~max_cycles:20_000
      [ selected (heavy ~entries:3 1L)
      ; bad_fcs (selected (heavy ~entries:3 2L))
      ; bad_ip (selected (heavy ~entries:3 3L))
      ; bad_fcs (filtered (heavy ~entries:3 900L))
      ; selected (heavy ~entries:3 4L)
      ]
  in
  print_s [%sexp (result : Observation.t)];
  [%expect
    {|
    ((packets 4) (updates 12) (end_of_event 4) (diagnostics 0) (crc_errors 2)
     (ip_errors 1) (sequence_gaps 0) (duplicates 0) (filtered_beats 18)
     (filtered_while_parser_busy 18) (beats 90) (full_tail_beats 0))
    |}]
;;

(* Frame verdicts belong to the physical layer, ahead of the destination-port filter, so a
   bad frame on an unrelated port is still a network error and still cannot reach the
   parser's sequence state. *)
let%test_unit "a bad frame on a filtered port is a network error only" =
  let result =
    run
      [ selected (simple 1L)
      ; bad_fcs (filtered (simple 900L))
      ; bad_ip (filtered (simple 901L))
      ; selected (simple 2L)
      ]
  in
  [%test_result: int] result.packets ~expect:2;
  [%test_result: int] result.crc_errors ~expect:1;
  [%test_result: int] result.ip_errors ~expect:1;
  [%test_result: int] result.sequence_gaps ~expect:0;
  [%test_result: int] result.duplicates ~expect:0;
  [%test_result: int] result.diagnostics ~expect:0
;;

(* An exact mirror of what validation/phase7/board_acceptance.py run_cases() transmits:
   the seven base cases followed by the seven MTU-scale ones, same sequence numbers, same
   shapes, same order. The board run checks these counters over a real PHY and a real MAC;
   this checks the same expectations against the DUT before anyone reaches for hardware.

   The Python side states its expectations as absolute counter tuples, and they are
   independently confirmed by the golden XML decoder in phase7_contracts.ml and by the
   sender model in feed_traffic.py. This is the third, and the only one that runs the
   actual RTL. *)
let board_acceptance_sequence =
  [ selected (shaped [ 1 ] 100L)
  ; selected (shaped [ 1; 2 ] 101L)
  ; selected (shaped [ 1 ] 103L)
  ; selected (shaped [ 1 ] 103L)
  ; selected (shaped [ 1 ] 104L)
  ; filtered (shaped [ 1 ] 900L)
  ; selected (shaped [ 1 ] 105L)
  ; selected (shaped [ mtu_entries ] 106L)
  ; selected (shaped (List.init mtu_messages ~f:(fun _ -> 1)) 107L)
  ; selected (shaped ~last_only:true (List.init 8 ~f:(fun _ -> 4)) 108L)
  ; selected (shaped ~root_block:full_tail_root_block [ mtu_aligned_entries ] 109L)
  ; selected (shaped [ mtu_entries ] 111L)
  ; selected (shaped [ mtu_entries ] 111L)
  ; selected (shaped [ mtu_entries ] 112L)
  ]
;;

let%expect_test "the phase 7 board acceptance sequence" =
  let result = run ~max_cycles:60_000 board_acceptance_sequence in
  print_s [%sexp (result : Observation.t)];
  [%expect
    {|
    ((packets 13) (updates 237) (end_of_event 33) (diagnostics 4) (crc_errors 0)
     (ip_errors 0) (sequence_gaps 2) (duplicates 2) (filtered_beats 10)
     (filtered_while_parser_busy 10) (beats 1332) (full_tail_beats 1))
    |}]
;;

(* The final tuple board_acceptance.py expects to read back over the UART, restated here
   so a divergence between the two files fails rather than drifts. *)
let%test_unit "the board acceptance sequence ends on the counters the board run expects" =
  let result = run ~max_cycles:60_000 board_acceptance_sequence in
  [%test_result: int] result.packets ~expect:13;
  [%test_result: int] result.updates ~expect:237;
  [%test_result: int] result.end_of_event ~expect:33;
  [%test_result: int] result.diagnostics ~expect:4;
  [%test_result: int] result.crc_errors ~expect:0;
  [%test_result: int] result.ip_errors ~expect:0;
  [%test_result: int] result.sequence_gaps ~expect:2;
  [%test_result: int] result.duplicates ~expect:2;
  (* Non-vacuity: one case really is padded to a whole number of beats. *)
  [%test_result: int] result.full_tail_beats ~expect:1
;;
