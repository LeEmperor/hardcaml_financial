open! Core
open! Hardcaml

let () =
  let circuit = Cme_feed_parser.circuit () in
  Rtl.print Verilog circuit
