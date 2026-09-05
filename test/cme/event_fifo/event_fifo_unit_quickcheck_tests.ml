(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "event_fifo_unit_quickcheck_tests.ml" *)
(* Complete event-word scoreboard, capacities including non-powers of two. *)

open! Core
open Event_fifo_testbench

let assert_coverage (result : Observation.t) =
  assert (result.full > 0 && result.simultaneous > 0 && result.outputs > 1000)
;;

let%test_unit "depths 1, 2, 3 and 16: capacity, ordering, pause, reset and drain" =
  List.iter [ 1; 2; 3; 16 ] ~f:(fun depth -> assert_coverage (run depth))
;;

let%test_unit "reproducible event patterns and traffic schedules" =
  Quickcheck.test
    ~trials:6
    ~seed:(`Deterministic "event-fifo-schedules")
    ~sexp_of:[%sexp_of: int]
    ~shrinker:Int.quickcheck_shrinker
    (Int.gen_incl 1 100000)
    ~f:(fun seed -> assert_coverage (run ~seed 3))
;;

let%test_unit "literal before/after-edge replacement, pause and reset" =
  let observations = run_literal () in
  let find phase = List.find_exn observations ~f:(fun o -> String.equal o.phase phase) in
  let stalled = find "stall" in
  assert (stalled.before.valid && not stalled.before.ready);
  [%test_result: int] stalled.before.low_byte ~expect:0x81;
  assert stalled.before.high_bit;
  let paused = find "pause" in
  assert ((not paused.before.valid) && not paused.before.ready);
  [%test_result: int] paused.after.low_byte ~expect:0x81;
  let replaced = find "replace" in
  assert (replaced.before.ready && replaced.before.valid);
  [%test_result: int] replaced.before.low_byte ~expect:0x81;
  [%test_result: int] replaced.after.low_byte ~expect:0x32;
  assert replaced.after.high_bit;
  assert (not (find "drain").after.valid);
  assert (not (find "reset_disabled").after.valid);
  assert (not (find "resume_empty").before.valid)
;;
