(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "generators.ml" *)
(* Quickcheck generators for the value types the suites randomize over.

   Every suite was rolling its own [Int.gen_incl 0x00 0xFF]; these are the shared ones.
   Lengths default to small ranges because each generated element costs simulated clock
   cycles - pass the optional bounds explicitly when a suite wants a wider sweep.

   Tags: [{ "ACTIVE" ; "TEST" ; "QUICKCHECK" ; "COMMON_ITEMS" }]
*)

open! Core

let byte : int Quickcheck.Generator.t = Int.gen_incl 0x00 0xFF

[@@@ocamlformat "disable"]

let byte_list
  ?(min_length = 1)
  ?(max_length = 16) ()
  : int list Quickcheck.Generator.t =

  let open Quickcheck.Generator.Let_syntax in
  let%bind length = Int.gen_incl min_length max_length in
  List.gen_with_length length byte
;;
[@@@ocamlformat "enable"]

let payload_length ?(min_length = 0) ?(max_length = 64) () : int Quickcheck.Generator.t =
  Int.gen_incl min_length max_length
;;

(* Cycle spacings for a tick-driven block. One is the degenerate case - a tick every
   cycle, so the block advances at the clock rate - and is the one a [tick] that is really
   being treated as a clock enable will fail on. *)
let tick_spacing ?(min_spacing = 1) ?(max_spacing = 6) () : int Quickcheck.Generator.t =
  Int.gen_incl min_spacing max_spacing
;;
