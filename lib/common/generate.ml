(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "generate.ml" *)
(* RTL generators, one subcommand per emittable artifact. Pick a target on the command
   line instead of comment-toggling this file:

   {v
     dune exec lib/common/generate.exe -- uart-test-top
     dune exec lib/common/generate.exe -- cme-feed-parser
     dune exec lib/common/generate.exe -- uart-frame-parser
     dune exec lib/common/generate.exe -- uart-loopback-validation
   v}

   Run the executable with [-help] for the current list. Output paths are resolved against
   the repo root rather than the working directory, so the RTL lands somewhere stable no
   matter where the binary ran.
*)

open! Core
open! Hardcaml
open! Cme_of_hardcaml
open! Uart_of_hardcaml
open! Signal
module Circ_uart_test_top = Circuit.With_interface (Uart_test_top.I) (Uart_test_top.O)
module Circ_cme = Circuit.With_interface (Cme_feed_parser.I) (Cme_feed_parser.O)

module Circ_uart_frame_parser =
  Circuit.With_interface (Uart_frame_parser.I) (Uart_frame_parser.O)

module Circ_uart_loopback_validation =
  Circuit.With_interface
    (Uart_loopback_validation_harness.I)
    (Uart_loopback_validation_harness.O)

(* Emit [circ] as hierarchical Verilog at [path]. [path] is resolved against the repo
   root: DUNE_SOURCEROOT is set by [dune exec] so the RTL always lands at a stable
   location rather than wherever the binary happened to run. *)
let emit ~scope ~path circ =
  let rtl =
    Rtl.full_hierarchy
      (Rtl.create ~database:(Scope.circuit_database scope) Verilog [ circ ])
  in
  let root = Option.value (Sys.getenv "DUNE_SOURCEROOT") ~default:"." in
  let out = Filename.concat root path in
  Out_channel.write_all out ~data:(Rope.to_string rtl);
  Stdio.printf "wrote %s\n" out
;;

(* Each target builds its circuit under a fresh scope, then emits. *)
let target ~summary ~build =
  Command.basic
    ~summary
    (Command.Param.return (fun () ->
       let scope = Scope.create ~flatten_design:false () in
       build scope))
;;

let uart_test_top_cmd =
  target ~summary:"board UART bring-up top -> uart_test_top.v" ~build:(fun scope ->
    emit
      ~scope
      ~path:"uart_test_top.v"
      (Circ_uart_test_top.create_exn ~name:"uart_test_top" (Uart_test_top.create scope)))
;;

let cme_feed_parser_cmd =
  target
    ~summary:"CME MDP 3.0 unpacker -> hardcaml_cme_feed_parser.v"
    ~build:(fun scope ->
      emit
        ~scope
        ~path:"hardcaml_cme_feed_parser.v"
        (Circ_cme.create_exn ~name:"cme_feed_parser" (Cme_feed_parser.create scope)))
;;

let uart_frame_parser_cmd =
  target
    ~summary:"UART framing layer -> hardcaml_uart_frame_parser.v"
    ~build:(fun scope ->
      emit
        ~scope
        ~path:"hardcaml_uart_frame_parser.v"
        (Circ_uart_frame_parser.create_exn
           ~name:"uart_frame_parser"
           (Uart_frame_parser.create scope)))
;;

let uart_loopback_validation_cmd =
  target
    ~summary:
      "board UART echo harness, RX->TX bridge -> \
       validation/uart_loopback_validation_harness.v"
    ~build:(fun scope ->
      emit
        ~scope
        ~path:"validation/uart_loopback_validation_harness.v"
        (Circ_uart_loopback_validation.create_exn
           ~name:"uart_loopback_validation_harness"
           (Uart_loopback_validation_harness.create scope)))
;;

let () =
  Command_unix.run
    (Command.group
       ~summary:"Hardcaml RTL generators (pick a target)"
       [ "uart-test-top", uart_test_top_cmd
       ; "cme-feed-parser", cme_feed_parser_cmd
       ; "uart-frame-parser", uart_frame_parser_cmd
       ; "uart-loopback-validation", uart_loopback_validation_cmd
       ])
;;
