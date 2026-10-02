(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "uart_rx_unit_quickcheck_tests.ml" *)

(* Unit and Quickcheck Suite: Uart_rx

   The headline property is the round trip - a byte onto the wire, the same byte out of
   [d_out] - swept across tick spacings and tick phases. Everything else here is a
   statement the round trip cannot make on its own: that nothing is announced when nothing
   was sent, that two frames back to back are two receptions rather than one, and that the
   two ways of stopping the block mid-frame (the enable and the clear) both drop the frame
   rather than announce a corrupted one.

   Tags: [{ "ACTIVE" ; "TEST" ; "UNIT_TEST" ; "QUICKCHECK" }]
*)

open! Core
open! Uart_rx_testbench

let%test_unit "0x55 round trips at the default spacing" =
  let reception = Testbench.receive 0x55 in
  [%test_result: int option] reception.byte ~expect:(Some 0x55)
;;

let%test_unit "0xAA round trips - the complement, so a stuck bit shows up as one or the \
               other"
  =
  let reception = Testbench.receive 0xAA in
  [%test_result: int option] reception.byte ~expect:(Some 0xAA)
;;

let%test_unit "0x00 and 0xFF round trip - the all-low byte is the one a receiver that \
               mistook the start bit for data would lose"
  =
  List.iter [ 0x00; 0xFF ] ~f:(fun byte ->
    let reception = Testbench.receive byte in
    [%test_result: int option] reception.byte ~expect:(Some byte))
;;

(* The bit order is the claim most worth pinning separately: a receiver that shifted the
   other way passes on 0x00, 0xFF and every palindrome, and fails only here. *)
let%test_unit "0x01 and 0x80 are not interchangeable" =
  List.iter [ 0x01; 0x80 ] ~f:(fun byte ->
    let reception = Testbench.receive byte in
    [%test_result: int option] reception.byte ~expect:(Some byte))
;;

let%test_unit "every byte round trips at the default spacing" =
  Quickcheck.test
    Hardcaml_verif.Generators.byte
    ~seed:(`Deterministic "uart_rx round trip")
    ~trials:24
    ~sexp_of:[%sexp_of: int]
    ~f:(fun byte ->
      let reception = Testbench.receive byte in
      [%test_result: int option] reception.byte ~expect:(Some byte))
;;

(* The block advances on [tick], so the same frame at a different tick spacing is the same
   frame. A receiver that had picked up a dependency on the clock rate instead would pass
   at one spacing and fail at the others. *)
let%test_unit "the round trip is independent of the tick spacing" =
  let generator =
    let open Quickcheck.Generator.Let_syntax in
    let%bind byte = Hardcaml_verif.Generators.byte in
    let%map cycles_per_symbol = Int.gen_incl 2 6 in
    byte, cycles_per_symbol
  in
  Quickcheck.test
    generator
    ~seed:(`Deterministic "uart_rx tick spacing")
    ~trials:24
    ~sexp_of:[%sexp_of: int * int]
    ~f:(fun (byte, cycles_per_symbol) ->
      let reception = Testbench.receive ~cycles_per_symbol byte in
      [%test_result: int option] reception.byte ~expect:(Some byte))
;;

(* Every phase inside the start-bit interval except cycle zero, where the tick coincides
   with the falling edge and START has not been entered yet. See the testbench header. *)
let%test_unit "the round trip holds at every tick phase from 1 to cycles_per_symbol - 1" =
  let generator =
    let open Quickcheck.Generator.Let_syntax in
    let%bind byte = Hardcaml_verif.Generators.byte in
    let%bind cycles_per_symbol = Int.gen_incl 2 6 in
    let%map tick_phase = Int.gen_incl 1 (cycles_per_symbol - 1) in
    byte, cycles_per_symbol, tick_phase
  in
  Quickcheck.test
    generator
    ~seed:(`Deterministic "uart_rx tick phase")
    ~trials:32
    ~sexp_of:[%sexp_of: int * int * int]
    ~f:(fun (byte, cycles_per_symbol, tick_phase) ->
      let reception = Testbench.receive ~cycles_per_symbol ~tick_phase byte in
      [%test_result: int option] reception.byte ~expect:(Some byte))
;;

let%test_unit "one frame is announced exactly once" =
  Quickcheck.test
    Hardcaml_verif.Generators.byte
    ~seed:(`Deterministic "uart_rx single window")
    ~trials:16
    ~sexp_of:[%sexp_of: int]
    ~f:(fun byte ->
      let reception = Testbench.receive byte in
      [%test_result: int] reception.num_windows ~expect:1)
;;

let%test_unit "an idle line announces nothing" =
  let reception = Reception.of_observations (Testbench.run_idle ~num_symbols:12 ()) in
  [%test_result: int option] reception.byte ~expect:None;
  [%test_result: int] reception.valid_cycles ~expect:0
;;

let%test_unit "two frames back to back are two receptions" =
  let generator =
    let open Quickcheck.Generator.Let_syntax in
    let%bind first = Hardcaml_verif.Generators.byte in
    let%map second = Hardcaml_verif.Generators.byte in
    first, second
  in
  Quickcheck.test
    generator
    ~seed:(`Deterministic "uart_rx back to back")
    ~trials:16
    ~sexp_of:[%sexp_of: int * int]
    ~f:(fun (first, second) ->
      let reception_a, reception_b = Testbench.run_two_bytes first second in
      [%test_result: int option] reception_a.byte ~expect:(Some first);
      [%test_result: int option] reception_b.byte ~expect:(Some second))
;;

(* Both of these are "the frame is dropped", not "a corrupted byte is announced". That
   distinction is the whole value of the pair: a receiver that announced whatever the
   shift register happened to hold would pass a test that only checked the byte was wrong. *)
let%test_unit "a frame arriving with the enable low is dropped, not deferred" =
  let reception = Reception.of_observations (Testbench.run_byte_disabled 0x55) in
  [%test_result: int option] reception.byte ~expect:None
;;

let%test_unit "a clear partway through a frame drops it" =
  List.iter [ 2; 4; 6 ] ~f:(fun num_symbols_before_clear ->
    let reception =
      Reception.of_observations
        (Testbench.run_byte_cleared_midframe ~num_symbols_before_clear 0x55)
    in
    [%test_result: int option] reception.byte ~expect:None)
;;
