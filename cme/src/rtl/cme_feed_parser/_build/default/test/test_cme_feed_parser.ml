open Hardcaml
open Hardcaml.Signal

(* Simulation using Cyclesim *)
module Sim = Cyclesim.With_interface (Cme_feed_parser.I) (Cme_feed_parser.O)

let () =
  let sim = Sim.create Cme_feed_parser.create in
  let i   = Cyclesim.inputs  sim in
  let o   = Cyclesim.outputs sim in

  (* Reset *)
  i.clear := vdd;
  Cyclesim.cycle sim;
  i.clear := gnd;

  (* Apply a payload *)
  i.valid := vdd;
  i.data  := of_int ~width:64 0xDEADBEEF;
  Cyclesim.cycle sim;

  let msg_valid = Bits.to_bool !(o.msg_valid) in
  let msg_data  = Bits.to_int  !(o.msg_data)  in
  Printf.printf "msg_valid=%b msg_data=0x%X\n" msg_valid msg_data;
  assert msg_valid;
  assert (msg_data = 0xDEADBEEF);
  print_endline "PASS"
