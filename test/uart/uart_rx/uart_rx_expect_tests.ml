(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "uart_rx_expect_tests.ml" *)

(* Expect Test Suite: Uart_rx

   Golden traces of where in a frame the byte is announced, as one character per driven
   cycle. The thing to read off a row is an alignment: [d_out_valid] should be low for the
   leading idle and the ten symbol intervals of the frame, then high across the STOP
   window and down again at the tick that ends it. A list of booleans would carry the same
   information and none of the shape.

   One sexp golden is kept as well, over the typed [Reception.t], so the record the
   properties compare against stays visible in the goldens rather than only in the
   testbench.

   Tags: [{ "ACTIVE" ; "TEST" ; "EXPECT_TEST" }]
*)

open! Core
open! Uart_rx_testbench

let print_trace observations = print_endline (valid_trace observations)

let print_reception observations =
  print_s [%sexp (Reception.of_observations observations : Reception.t)]
;;

let%expect_test "0x55 at the default four-cycle spacing" =
  print_trace (Testbench.run_byte 0x55);
  [%expect {| .......................................VVVV......... |}]
;;

let%expect_test "the typed reception for the same run" =
  print_reception (Testbench.run_byte 0x55);
  [%expect {| ((byte (85)) (valid_cycles 4) (num_windows 1)) |}]
;;

let%expect_test "the stop window widens with the tick spacing, and nothing else moves" =
  List.iter [ 2; 4; 6 ] ~f:(fun cycles_per_symbol ->
    printf "%d: " cycles_per_symbol;
    print_trace (Testbench.run_byte ~cycles_per_symbol 0x55));
  [%expect
    {|
    2: ....................VV....
    4: .......................................VVVV.........
    6: ..........................................................VVVVVV..............
    |}]
;;

let%expect_test "an idle line never announces" =
  print_trace (Testbench.run_idle ~num_symbols:6 ());
  [%expect {| ........................ |}]
;;

let%expect_test "two frames back to back are two separate windows" =
  let reception_a, reception_b = Testbench.run_two_bytes 0x41 0x42 in
  print_s [%sexp (reception_a : Reception.t)];
  print_s [%sexp (reception_b : Reception.t)];
  [%expect
    {|
    ((byte (65)) (valid_cycles 4) (num_windows 1))
    ((byte (66)) (valid_cycles 4) (num_windows 1))
    |}]
;;

(* The enable gates the FSM but not the edge detector's history register, so a start edge
   that arrives while the block is disabled is gone rather than pending. Frozen here
   because it is the kind of thing a later "just gate the whole block" change would break
   silently in the other direction. *)
let%expect_test "a frame arriving with the enable low leaves no trace" =
  print_trace (Testbench.run_byte_disabled 0x55);
  [%expect {| ........................................................ |}]
;;

let%expect_test "a clear partway through a frame abandons it" =
  print_trace (Testbench.run_byte_cleared_midframe ~num_symbols_before_clear:4 0x55);
  [%expect {| .................................................... |}]
;;
