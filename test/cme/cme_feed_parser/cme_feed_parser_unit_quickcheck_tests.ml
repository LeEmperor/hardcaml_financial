(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "cme_feed_parser_unit_quickcheck_tests.ml" *)

(* Unit and Quickcheck Suite: Cme_feed_parser

   The block is a skeleton, so these are contract properties rather than behavior
   properties: the outputs do not depend on the inputs, and the block is combinational.
   Both are things the current RTL says and a datapath will have to stop saying. The
   Quickcheck property is the one worth keeping past that point in some form - "for every
   beat, [slave_ready] is high" becomes "for every beat the block can accept,
   [slave_ready] is high", which is the real backpressure claim.

   Tags: [{ "ACTIVE" ; "TEST" ; "UNIT_TEST" ; "QUICKCHECK" }]
*)

open! Core
open! Cme_feed_parser_testbench

let%test_unit "the block never backpressures, whatever arrives" =
  Quickcheck.test
    (Hardcaml_verif.Generators.byte_list ~min_length:1 ~max_length:8 ())
    ~seed:(`Deterministic "cme_feed_parser ready")
    ~trials:16
    ~sexp_of:[%sexp_of: int list]
    ~f:(fun beats ->
      let stimuli = List.map beats ~f:Stimulus.beat in
      let observations = Testbench.run_stimuli stimuli in
      List.iter observations ~f:(fun (observation : Observation.t) ->
        [%test_result: bool] observation.slave_ready ~expect:true))
;;

let%test_unit "no beat produces output while the datapath is unwritten" =
  Quickcheck.test
    (Hardcaml_verif.Generators.byte_list ~min_length:1 ~max_length:8 ())
    ~seed:(`Deterministic "cme_feed_parser data_out")
    ~trials:16
    ~sexp_of:[%sexp_of: int list]
    ~f:(fun beats ->
      let stimuli = List.map beats ~f:Stimulus.beat in
      let observations = Testbench.run_stimuli stimuli in
      List.iter observations ~f:(fun (observation : Observation.t) ->
        [%test_result: int] observation.data_out ~expect:0))
;;

(* A purely combinational block has no choice about which side of the edge to sample, and
   this is where that gets asserted rather than assumed. It fails the day a register is
   added, which is the point. *)
let%test_unit "the block is combinational: both sides of the edge agree" =
  List.iter
    [ Stimulus.idle; Stimulus.beat 0xDEAD_BEEF; Stimulus.clear ]
    ~f:(fun stimulus ->
      let { Edges.before_edge; after_edge } = Testbench.run_beat stimulus in
      [%test_result: Observation.t] after_edge ~expect:before_edge)
;;
