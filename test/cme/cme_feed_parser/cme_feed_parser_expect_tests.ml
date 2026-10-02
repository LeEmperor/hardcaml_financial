(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "cme_feed_parser_expect_tests.ml" *)
(* Compact integrated event ordering trace, using the differential Step fixture. *)

open! Core
open Cme_feed_parser_testbench
open F

let%expect_test "updates, gap, duplicate, and zero-entry end-of-event" =
  let result =
    run
      [ packet
          10L
          [ message ~match_event_indicator:0x80 [ default_entry; default_entry ] ]
      ; packet 12L [ message ~match_event_indicator:0x80 [] ]
      ; packet 12L [ message [ default_entry ] ]
      ; packet 13L [ message ~schema:2 []; message ~match_event_indicator:0x80 [] ]
      ]
  in
  List.iter result.events ~f:(function
    | G.Mbp_update u ->
      printf
        "update seq=%Ld entry=%d/%d price=%Ld last=%b valid=%b\n"
        u.packet.packet_seq
        u.entry_index
        u.entry_count
        (Option.value_exn u.price_mantissa)
        u.message_last
        u.packet.channel_valid
    | End_of_event e ->
      printf "end seq=%Ld valid=%b\n" e.packet.packet_seq e.packet.channel_valid
    | Diagnostic d ->
      printf
        "diagnostic seq=%Ld code=%d offset=%d valid=%b\n"
        d.packet.packet_seq
        (code d.code)
        d.byte_offset
        d.packet.channel_valid);
  [%expect
    {|
    update seq=10 entry=0/2 price=-123 last=false valid=true
    update seq=10 entry=1/2 price=-123 last=true valid=true
    end seq=10 valid=true
    diagnostic seq=12 code=1 offset=0 valid=false
    end seq=12 valid=false
    diagnostic seq=12 code=2 offset=0 valid=false
    diagnostic seq=13 code=7 offset=18 valid=false
    end seq=13 valid=false
    |}]
;;
