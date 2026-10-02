(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "mbp_decoder_expect_tests.ml" *)
(* Reviewed completion trace for the stalled collector regression. *)

open! Core
open Mbp_decoder_testbench

let%expect_test "completed updates retire before abort completion" =
  let o = run () in
  print_s [%sexp (o.indices : int list), (o.abort_cycle >= 200 : bool), (o.idle : bool)];
  [%expect {| ((0 1) true true) |}]
;;
