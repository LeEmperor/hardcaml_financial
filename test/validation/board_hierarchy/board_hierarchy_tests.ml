(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "board_hierarchy_tests.ml" *)

(* Board-hierarchy regression for the validation harnesses.

   Two things are pinned here, and the second is the one that costs a board bring-up when
   it breaks. First, the shape of the emitted hierarchy: which sub-circuits are recorded
   in the scope's database and which the board top instantiates. Second, the Arty pin
   contract - every port the XDC binds to by name, at the width it binds at - which must
   match [Arty_board_top] exactly and must be identical whether the design was elaborated
   hierarchically for RTL or flat for [Cyclesim].

   As it stands the harness has no hierarchy boundaries at all: [Uart_rx], [Uart_tx],
   [Second_pulse] and [Clk_div] are plain [create scope] calls rather than
   [Hierarchy.In_scope] instantiations, so they inline into the top and the database comes
   back empty. That is the current state rather than a goal, and it is asserted rather
   than assumed: the day a block is given a real hierarchy boundary these goldens go red
   and say so, which is the only cheap way to notice that the emitted RTL just changed
   shape.

   Tags: [{ "ACTIVE" ; "TEST" ; "EXPECT_TEST" ; "HIERARCHY" }]
*)

open! Core
open! Hardcaml
module Board_circuit = Circuit.With_interface (Arty_board_top.I) (Arty_board_top.O)

type design =
  { top : Circuit.t
  ; database : Circuit_database.t
  }

let build ~flatten_design ~name create =
  let scope = Scope.create ~flatten_design () in
  let top = Board_circuit.create_exn ~name (create scope) in
  { top; database = Scope.circuit_database scope }
;;

let sorted_circuit_names database =
  Circuit_database.get_circuits database
  |> List.map ~f:Circuit.name
  |> List.sort ~compare:String.compare
;;

let sorted_ports get_ports circuit =
  get_ports circuit
  |> List.map ~f:(fun signal -> List.hd_exn (Signal.names signal), Signal.width signal)
  |> List.sort ~compare:[%compare: string * int]
;;

let sorted_instantiations circuit =
  Circuit.instantiations circuit
  |> List.map ~f:(fun instantiation -> instantiation.instantiation.circuit_name)
  |> List.sort ~compare:String.compare
;;

let board_ports ports = List.sort ports ~compare:[%compare: string * int]

let board_input_ports =
  board_ports (Arty_board_top.I.to_list Arty_board_top.I.port_names_and_widths)
;;

let board_output_ports =
  board_ports (Arty_board_top.O.to_list Arty_board_top.O.port_names_and_widths)
;;

let harness_name = "uart_loopback_validation_harness"
let create = Uart_loopback_validation_harness.create

let%test_unit "the harness keeps the Arty pin contract the XDC binds to" =
  let hierarchical = build ~flatten_design:false ~name:harness_name create in
  let flat = build ~flatten_design:true ~name:harness_name create in
  [%test_result: (string * int) list]
    ~message:harness_name
    (sorted_ports Circuit.outputs hierarchical.top)
    ~expect:board_output_ports;
  (* Inputs are a subset: a port nothing in the design reads is optimized away, so the
     claim is containment rather than equality. *)
  List.iter (sorted_ports Circuit.inputs hierarchical.top) ~f:(fun port ->
    assert (List.mem board_input_ports port ~equal:[%compare.equal: string * int]));
  (* Flattening for [Cyclesim] must not change the boundary. *)
  [%test_result: (string * int) list]
    ~message:harness_name
    (sorted_ports Circuit.inputs hierarchical.top)
    ~expect:(sorted_ports Circuit.inputs flat.top);
  [%test_result: (string * int) list]
    ~message:harness_name
    (sorted_ports Circuit.outputs hierarchical.top)
    ~expect:(sorted_ports Circuit.outputs flat.top)
;;

let%test_unit "no instantiation is left unresolved" =
  let hierarchical = build ~flatten_design:false ~name:harness_name create in
  let unresolved =
    Hierarchy.fold
      hierarchical.top
      hierarchical.database
      ~init:[]
      ~f:(fun unresolved circuit inst ->
        match circuit, inst with
        | None, Some inst -> inst.circuit_name :: unresolved
        | _ -> unresolved)
  in
  [%test_result: string list] ~message:harness_name unresolved ~expect:[]
;;

let%expect_test "the emitted hierarchy: recorded circuits and top-level instantiations" =
  let hierarchical = build ~flatten_design:false ~name:harness_name create in
  print_s
    [%message
      ""
        ~recorded:(sorted_circuit_names hierarchical.database : string list)
        ~instantiated:(sorted_instantiations hierarchical.top : string list)];
  [%expect {| ((recorded ()) (instantiated ())) |}]
;;

let%expect_test "the board output pin contract" =
  print_s [%sexp (board_output_ports : (string * int) list)];
  [%expect
    {|
    ((eth_mdc 1) (eth_ref_clk 1) (eth_rstn 1) (eth_tx_en 1) (eth_txd 4) (led 4)
     (led0_b 1) (led0_g 1) (led0_r 1) (led1_b 1) (led1_g 1) (led1_r 1) (led2_b 1)
     (led2_g 1) (led2_r 1) (led3_b 1) (led3_g 1) (led3_r 1) (uart_rxd_out 1))
    |}]
;;
