(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "cme_feed_parser_expect_tests.ml" *)

(* Expect Test Suite: Cme_feed_parser

   Golden traces of the port contract as it stands. There is no behavior to freeze yet, so
   what these goldens are for is the diff: the first commit that gives the block a
   datapath will turn every row here red, and reading that diff is how the new behavior
   gets reviewed against the old contract.

   Tags: [{ "ACTIVE" ; "TEST" ; "EXPECT_TEST" }]
*)

open! Core
open! Cme_feed_parser_testbench

let print_compact observations =
  List.iter observations ~f:(fun observation ->
    print_s
      [%sexp (Compact_observation.of_observation observation : Compact_observation.t)])
;;

let%expect_test "a short burst of beats" =
  print_compact
    (Testbench.run_stimuli
       [ Stimulus.idle; Stimulus.beat 0x55; Stimulus.beat 0xAA; Stimulus.idle ]);
  [%expect
    {|
    ((data_out 0x0) (slave_ready true))
    ((data_out 0x0) (slave_ready true))
    ((data_out 0x0) (slave_ready true))
    ((data_out 0x0) (slave_ready true))
    |}]
;;

let%expect_test "a clear changes nothing, because nothing is held" =
  print_compact (Testbench.run_stimuli [ Stimulus.beat 0xFF; Stimulus.clear ]);
  [%expect
    {|
    ((data_out 0x0) (slave_ready true))
    ((data_out 0x0) (slave_ready true))
    |}]
;;

let%expect_test "both sides of one beat's edge" =
  print_s [%sexp (Testbench.run_beat (Stimulus.beat 0xDEAD_BEEF) : Edges.t)];
  [%expect
    {|
    ((before_edge
      ((stimulus ((rst false) (valid true) (data 3735928559))) (data_out 0)
       (slave_ready true)))
     (after_edge
      ((stimulus ((rst false) (valid true) (data 3735928559))) (data_out 0)
       (slave_ready true))))
    |}]
;;
