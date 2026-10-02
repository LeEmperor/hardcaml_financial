(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "uart_loopback_validation_harness.ml" *)
(* Board-level echo harness for the UART pair on the Arty A7-100T.

   This is the bring-up top: it lives outside [lib/] on purpose, because [lib/] holds the
   reusable blocks and this directory holds the scaffolding that drives them on real
   silicon. It reuses [Arty_board_top.I] / [Arty_board_top.O] - the canonical pin contract
   in [lib/common] - as its port interface and supplies its own [create].

   Structure --------- clk100mhz domain, all of it: Board_scaffolding.eth_ref_clk ->
   eth_ref_clk (25 MHz to the PHY XI pin) Board_scaffolding.phy_hard_reset -> eth_rstn
   (PHY held down ~0.66 ms after power-on) Board_scaffolding.heartbeat -> led0_r toggle
   (0.5 Hz, eye-visible) Second_pulse ~clk_freq:868 -> baud tick, 100 MHz / 868 = 115_207
   baud Uart_rx -> byte latch -> Uart_tx -> uart_rxd_out

   The echo path is one register and one edge detector. [Uart_rx.d_out_valid] is a level
   held for the whole STOP window, so a rising-edge detector on it gives a single-cycle
   "byte arrived" pulse; that pulse latches the byte and arms [Uart_tx.d_in_valid] for
   exactly one cycle, which is all [Uart_tx] needs to leave IDLE. The latch is what holds
   [d_in] steady for the rest of the frame - [Uart_tx] reads [d_in] combinationally
   through PAYLOAD rather than shifting a captured copy - and the next byte cannot arrive
   before this one has been sent, so one register is enough.

   One phase caveat, and it is the receiver's rather than this harness's: [Uart_rx]
   samples on the same baud tick the transmitter runs on, not on a 16x oversampling clock,
   so its sampling point sits wherever the start-bit edge happened to fall relative to the
   tick. That is fine for a bring-up echo at 115200 and is the first thing to fix if this
   ever has to hold a line at speed.

   Controls: btn[0] = active-high reset (raw async button, synchronized into the clock
   domain), sw[0] = enable. Send a byte at the USB-UART and it comes back.

   LED map: led[3:0] lower nibble of the last received byte led0_r heartbeat toggle led1_g
   phy_ready led2_b d_out_valid (a frame is in its stop window)
*)

open! Core
open! Hardcaml
open! Uart_of_hardcaml
open! Signal

(* Reuse the canonical board pin contract as the harness port interface. *)
module I = Arty_board_top.I
module O = Arty_board_top.O

let create (scope : Scope.t) (i : _ I.t) : _ O.t =
  let rst = Signal.bit i.I.btn ~pos:0 -- "rst" in
  (* btn[0]: raw async reset button *)
  let en = Signal.bit i.I.sw ~pos:0 -- "en" in
  (* sw[0]: active-high enable *)
  let sys_rst =
    Board_scaffolding.reset_sync ~clock:i.I.clk100mhz ~async_rst:rst -- "sys_rst"
  in
  let spec100 = Reg_spec.create ~clock:i.I.clk100mhz ~clear:sys_rst () in
  (* Board plumbing: PHY reference clock, PHY hard reset, heartbeat. *)
  let ref_clk =
    Board_scaffolding.eth_ref_clk ~scope ~clk100mhz:i.I.clk100mhz ~sys_rst ~en:vdd
  in
  let phy = Board_scaffolding.phy_hard_reset ~spec100 ~sys_rst in
  let hb =
    Board_scaffolding.heartbeat ~scope ~clk100mhz:i.I.clk100mhz ~sys_rst ~spec100
  in
  (* 100 MHz / 868 = 115_207 baud, within 0.01% of 115200. Both ends of the loop run off
     this one tick; see the phase note in the header. *)
  let baud =
    Second_pulse.create
      ~clk_freq:868
      scope
      { Second_pulse.I.clk = i.I.clk100mhz; rst = sys_rst }
  in
  let rx =
    Uart_rx.create
      scope
      { Uart_rx.I.clock = i.I.clk100mhz
      ; reset = sys_rst
      ; en
      ; tick = baud.pulse
      ; uart_rx_d = i.I.uart_txd_in
      }
  in
  (* [d_out_valid] is a level over the whole stop window; the edge is the arrival. *)
  let byte_arrived =
    Helper_circuits.rising_edge_detector spec100 rx.d_out_valid -- "byte_arrived"
  in
  let echo_byte = Signal.reg spec100 ~enable:byte_arrived rx.d_out -- "echo_byte" in
  let tx =
    Uart_tx.create
      scope
      { Uart_tx.I.clk = i.I.clk100mhz
      ; rst = sys_rst
      ; en
      ; tick = baud.pulse
      ; d_in = echo_byte
      ; d_in_valid = byte_arrived
      }
  in
  { O.led = select echo_byte ~high:3 ~low:0
  ; led0_r = hb.toggle
  ; led0_g = gnd
  ; led0_b = gnd
  ; led1_r = gnd
  ; led1_g = phy.ready
  ; led1_b = gnd
  ; led2_r = gnd
  ; led2_g = gnd
  ; led2_b = rx.d_out_valid
  ; led3_r = gnd
  ; led3_g = gnd
  ; led3_b = gnd
  ; uart_rxd_out = tx.uart_tx
  ; eth_mdc = gnd
  ; eth_rstn = Signal.msb phy.cnt
  ; eth_ref_clk = ref_clk.dst_clk
  ; eth_tx_en = gnd
  ; eth_txd = zero 4
  }
;;
