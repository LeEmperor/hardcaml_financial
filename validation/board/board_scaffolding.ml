(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "board_scaffolding.ml" *)
(* Domain-agnostic Arty A7-100T board plumbing for the CME validation top: per-domain
   reset synchronizers, the 25 MHz PHY reference clock, PHY hard-reset sequencing, the
   heartbeat LED, and a level synchronizer.

   Ported from hardcaml_networking's validation/board_scaffolding.ml so that no CME board
   code lives in that repository. [Arty_board_top], [Clk_div] and [Second_pulse] are no
   longer copied into lib/common/ - they come from the hardcaml_networking opam package,
   which is their single source of truth.

   These are plain helper functions, NOT a Hardcaml sub-module: they build signals
   directly into the caller's circuit, so the caller keeps control over signal-creation
   order and the emitted RTL is identical to hand-inlined plumbing. *)

open! Core
open! Hardcaml
open! Signal
open! Hardcaml_networking
open! Common

(* Per-domain reset synchronizer. btn[0] is a raw asynchronous input, so drop it through a
   2-FF chain in the target clock domain: async-assert, sync-deassert. *)
let reset_sync ~clock ~async_rst =
  let spec = Reg_spec.create ~clock ~reset:async_rst () in
  let ff0 = Signal.reg spec ~reset_to:(Bits.one 1) Signal.gnd in
  Signal.reg spec ~reset_to:(Bits.one 1) ff0
;;

(* 25 MHz reference clock to the PHY XI pin. The jitter is ugly but irrelevant at MII
   speeds. Drive eth_ref_clk from [.dst_clk]. [divisor] is passed explicitly rather than
   left to [Clk_div]'s default so the 100 -> 25 MHz relationship is stated at the call
   site, and so this board's refclk does not move if that default ever changes upstream. *)
let eth_ref_clk ~scope ~clk100mhz ~sys_rst ~en =
  Clk_div.create ~divisor:4 scope { Clk_div.I.src_clk = clk100mhz; rst = sys_rst; en }
;;

module Phy_reset = struct
  type t =
    { cnt : Signal.t (* 17-bit saturating counter; MSB stuck at 1 once released *)
    ; ready : Signal.t (* = MSB(cnt): PHY is out of its ~0.66 ms hard reset *)
    }
end

(* PHY hard reset: hold eth_rstn low ~0.66 ms after power-on, then release and hold high.
   Drive eth_rstn from [msb cnt]; use [ready] as the "PHY up" status level. *)
let phy_hard_reset ~spec100 ~sys_rst =
  let cnt =
    Signal.reg_fb spec100 ~enable:vdd ~width:17 ~f:(fun q ->
      mux2 sys_rst (zero 17) (mux2 (msb q) q (q +:. 1)))
    -- "phy_rst_cnt"
  in
  { Phy_reset.cnt; ready = Signal.msb cnt -- "dbg_phy_ready" }
;;

module Heartbeat = struct
  type t =
    { toggle : Signal.t (* 0.5 Hz square wave for an eye-visible LED blink *)
    ; keep : Signal.t (* Second_pulse debug OR-reduction, forward for anti-prune *)
    }
end

(* 1 Hz heartbeat pulse toggled into a 0.5 Hz square wave. *)
let heartbeat ~scope ~clk100mhz ~sys_rst ~spec100 =
  let hb = Second_pulse.create scope { Second_pulse.I.clk = clk100mhz; rst = sys_rst } in
  let toggle =
    Signal.reg_fb spec100 ~enable:hb.pulse ~width:1 ~f:(fun q -> ~:q)
    -- "heartbeat_toggle"
  in
  { Heartbeat.toggle; keep = hb.keep }
;;

(* Plain 2-FF level synchronizer into [spec]'s domain. *)
let sync2 ~spec x = Signal.reg spec (Signal.reg spec x)
