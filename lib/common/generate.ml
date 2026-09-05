open! Core
open! Hardcaml
open! Uart_of_hardcaml

let uart_circuit () =
  let scope = Scope.create ~flatten_design:false () in
  let module Circ = Circuit.With_interface (Uart_test_top.I) (Uart_test_top.O) in
  Circ.create_exn ~name:"uart_test_top" (Uart_test_top.create scope)
;;

let () =
  let filename, circ, notice =
    match Array.to_list (Sys.get_argv ()) with
    | [ _ ] | [ _; "uart" ] -> "uart_test_top.v", uart_circuit (), ""
    | [ _; "cme" ] ->
      ( "cme_mdp3_feed_parser.v"
      , Cme_of_hardcaml.Cme_feed_parser.circuit ()
      , "// Phase 0 INACTIVE SKELETON: accepts no payloads or controls; emits no events.\n"
      )
    | _ -> failwith "usage: generate.exe [uart|cme]"
  in
  let hier = Rtl.create Verilog [ circ ] in
  let rtl = Rtl.full_hierarchy hier in
  Out_channel.write_all filename ~data:(notice ^ Rope.to_string rtl);
  Stdio.printf "Generated %s\n" filename
;;
