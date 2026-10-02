(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "uart_test_top.ml" *)
(* Board-level bring-up design for the UART RX/TX paths, wired to the Arty pin contract in
   [Arty_board_top]. Drives a fixed byte out of the USB-UART at a [Second_pulse]-derived
   baud tick and blinks a heartbeat, so the board can be confirmed alive before anything
   heavier is attached to it.
*)

open! Core
open! Hardcaml
open! Signal
open! Hardcaml_circuits
module I = Arty_board_top.I
module O = Arty_board_top.O

let create scope i : _ O.t =
  (* aliases *)
  let _scope = Scope.sub_scope scope "uart_top" in
  let clock100 = i.I.clk100mhz in
  let rst = Signal.bit i.I.btn ~pos:0 in
  let en = Signal.bit i.I.sw ~pos:0 in
  let rising_edge = Reg_spec.create ~clock:clock100 ~clear:rst () in
  (* fifo stuff *)

  (* hierarchical instantiations *)
  let heartbeat_inst = Second_pulse.create scope { Second_pulse.I.clk = clock100; rst } in
  let baud_inst =
    Second_pulse.create scope ~clk_freq:868 { Second_pulse.I.clk = clock100; rst }
  in
  (* potentially unused *)
  (* let uart_data_sequence : Signal.t = *)
  (* Signal.reg_fb ~enable:baud_inst.pulse rising_edge ~width:4 *)
  (* ~f:(fun f -> mux2 rst (zero 1) (f +:. 1)) *)
  (* in *)
  let uart_inst =
    Uart_tx.create
      scope
      { Uart_tx.I.clk = clock100
      ; rst
      ; en
      ; tick = baud_inst.pulse
      ; d_in = of_int_trunc ~width:8 0x55
      ; d_in_valid = vdd
      }
  in
  { O.led = zero 4
  ; led0_r = heartbeat_inst.pulse
  ; led0_g = gnd
  ; led0_b = gnd
  ; led1_r = gnd
  ; led1_g = gnd
  ; led1_b = gnd
  ; led2_r = gnd
  ; led2_g = gnd
  ; led2_b = gnd
  ; led3_r = gnd
  ; led3_g = gnd
  ; led3_b = gnd
  ; uart_rxd_out = uart_inst.uart_tx
  ; (* actually the tx pin lmao *)
    (* uart_txd_in = vdd; *)
    eth_mdc = gnd
  ; eth_rstn = vdd
  ; eth_ref_clk = gnd
  ; eth_tx_en = gnd
  ; eth_txd = zero 4
  }
;;
