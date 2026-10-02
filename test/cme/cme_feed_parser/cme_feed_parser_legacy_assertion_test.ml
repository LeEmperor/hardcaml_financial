(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "cme_feed_parser_legacy_assertion_test.ml" *)
(* The original Cyclesim sketch for the feed parser, superseded by the suite alongside it.

   Kept in a bare (executable) stanza: [dune build] compiles it so it keeps type-checking
   against the RTL rather than silently rotting, and [dune runtest] never invokes it. The
   body is commented out because the ports it names ([clear], [msg_valid], [msg_data])
   never existed on [Cme_feed_parser] - it was written against an interface that was still
   being decided. It is left as written; the live coverage is in
   [cme_feed_parser_expect_tests.ml].

   Tags: [{ "DEPRECATED" ; "ASSERTION_TEST" }]
*)

open! Core
open! Hardcaml
open! Signal

(* Simulation using Cyclesim *)
(* module Sim = Cyclesim.With_interface (Cme_feed_parser.I) (Cme_feed_parser.O) *)
(**)
(* let () = *)
(* let sim = Sim.create Cme_feed_parser.create in *)
(* let i = Cyclesim.inputs sim in *)
(* let o = Cyclesim.outputs sim in *)
(**)
(* (* Reset *) *)
(* i.clear := vdd; *)
(* Cyclesim.cycle sim; *)
(* i.clear := gnd; *)
(**)
(* (* Apply a payload *) *)
(* i.valid := vdd; *)
(* i.data := of_int ~width:64 0xDEADBEEF; *)
(* Cyclesim.cycle sim; *)
(**)
(* let msg_valid = Bits.to_bool !(o.msg_valid) in *)
(* let msg_data = Bits.to_int !(o.msg_data) in *)
(*   Printf.printf "msg_valid=%b msg_data=0x%X\n" msg_valid msg_data; *)
(* assert msg_valid; *)
(* assert (msg_data = 0xDEADBEEF); *)
(*   print_endline "PASS" *)
