(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "mbp_decoder_unit_quickcheck_tests.ml" *)
(* Completed entries survive a terminal abort while the event register is stalled. *)

open! Core
open Mbp_decoder_testbench

let verify release_at =
  let o = run ~release_at () in
  [%test_result: int list] o.indices ~expect:[ 0; 1 ];
  assert (o.abort_cycle >= release_at);
  assert (o.done_cycle >= release_at + 30 && o.idle)
;;

let%test_unit "abort waits for the completed second entry and completion acknowledgment" =
  verify 200
;;

let%test_unit "completed collector survives varying downstream stall durations" =
  Quickcheck.test
    ~trials:10
    ~seed:(`Deterministic "phase5-completed-collector-abort")
    ~sexp_of:[%sexp_of: int]
    ~shrinker:Int.quickcheck_shrinker
    (Int.gen_incl 150 250)
    ~f:verify
;;
