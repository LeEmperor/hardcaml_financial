open! Core
open! Hardcaml
open! Uart_of_hardcaml

let () =
  Stdio.print_endline "============ Begin Generate =============== ";
  let scope = Scope.create ~flatten_design:false () in
  let module Circ = Circuit.With_interface (Uart_test_top.I) (Uart_test_top.O) in
  let circ = Circ.create_exn ~name:"uart_test_top" (Uart_test_top.create scope) in
  let hier = Rtl.create Verilog [circ] in
  let rtl = Rtl.full_hierarchy hier in
  Out_channel.write_all "uart_test_top.v" ~data:(Rope.to_string rtl);
;;

