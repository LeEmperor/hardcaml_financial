open Hardcaml

let () =
  let circuit : Circuit.t = Cme_feed_parser.circuit () in
  Rtl.print Verilog circuit;

