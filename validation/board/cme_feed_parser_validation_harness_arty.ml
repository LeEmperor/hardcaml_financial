(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "cme_feed_parser_validation_harness_arty.ml" *)
(* Native Arty A7-100T receive harness for the CME MDP 3.0 feed parser:

   MII PHY -> Ethernet MAC -> IPv4 -> UDP -> destination-port selection -> CME feed parser
   -> diagnostic counters -> USB UART

   This file owns every functional instance in the board datapath. The MAC/UDP stack is
   instantiated directly from the installed [hardcaml_networking] library, so emitting
   this circuit produces one self-contained RTL hierarchy. No external Verilog blackbox,
   vendored network RTL, or post-generation concatenation is required.

   Controls: btn[0] resets, sw[0] enables reception, sw[3:1] selects which counter's low
   nibble reaches led[3:0]. The PHY reference clock and UART keep running while sw[0] is
   low, so pausing ingress freezes the counters without truncating a status record.

   Clocking: the parser runs in the PHY's 25 MHz tx-clock domain, shared with the UDP
   application stream. The RX-to-application crossing is the asynchronous FIFO inside
   [Udp.Udp_rx_64_mac_top]. *)

open! Core
open! Hardcaml
open! Signal
open! Hardcaml_networking
open! Common
module I = Arty_board_top.I
module O = Arty_board_top.O

let default_dest_port = 31337

let create
  ?(dest_port = default_dest_port)
  ?uart_divisor
  ?snapshot_cycles
  (scope : Scope.t)
  (i : _ I.t)
  : _ O.t
  =
  let rst = bit i.btn ~pos:0 in
  let sys_rst = Board_scaffolding.reset_sync ~clock:i.clk100mhz ~async_rst:rst in
  let rx_rst = Board_scaffolding.reset_sync ~clock:i.eth_rx_clk ~async_rst:rst in
  let tx_rst = Board_scaffolding.reset_sync ~clock:i.eth_tx_clk ~async_rst:rst in
  let spec100 = Reg_spec.create ~clock:i.clk100mhz ~clear:sys_rst () in
  let spec_tx = Reg_spec.create ~clock:i.eth_tx_clk ~clear:tx_rst () in
  let en = Board_scaffolding.sync2 ~spec:spec_tx (bit i.sw ~pos:0) in
  let display = Board_scaffolding.sync2 ~spec:spec_tx (select i.sw ~high:3 ~low:1) in
  (* The PHY reference clock is unconditional: gating it on [en] would drop the link every
     time reception is paused. *)
  let ref_clk =
    Board_scaffolding.eth_ref_clk ~scope ~clk100mhz:i.clk100mhz ~sys_rst ~en:vdd
  in
  let phy = Board_scaffolding.phy_hard_reset ~spec100 ~sys_rst in
  let heartbeat =
    Board_scaffolding.heartbeat ~scope ~clk100mhz:i.clk100mhz ~sys_rst ~spec100
  in
  let ready = wire 1 in
  let network =
    Udp.Udp_rx_64_mac_top.hierarchical
      ~instance:"network"
      scope
      { Udp.Udp_rx_64_mac_top.I.rx_clock_i = i.eth_rx_clk
      ; rx_reset_i = rx_rst
      ; rx_dv_i = i.eth_rx_dv
      ; rx_er_i = i.eth_rxerr
      ; rx_data_i = i.eth_rxd
      ; tx_clock_i = i.eth_tx_clk
      ; tx_reset_i = tx_rst
      ; en_i = en
      ; app_tready_i = ready
      }
  in
  (* Select the destination port on the first accepted wide beat and retain the choice for
     the rest of that packet. Filtered traffic drains without touching parser sequence
     state. *)
  let active = en &: ~:tx_rst in
  let selected = wire 1 in
  let select_packet =
    mux2 network.app_tfirst_o (network.dst_port_o ==:. dest_port) selected
    -- "select_packet"
  in
  let accepted = active &: network.app_tvalid_o &: ready in
  selected <-- Signal.reg spec_tx ~enable:(accepted &: network.app_tfirst_o) select_packet;
  let parser =
    Cme_of_hardcaml.Cme_feed_parser.hierarchical
      ~instance:"feed_parser"
      scope
      { clock_i = i.eth_tx_clk
      ; reset_i = tx_rst
      ; en_i = en
      ; data_i = network.app_tdata_o
      ; keep_i = network.app_tkeep_o
      ; valid_i = network.app_tvalid_o &: select_packet
      ; first_i = network.app_tfirst_o
      ; last_i = network.app_tlast_o
      ; ingress_timestamp_i = zero 64
      ; session_reset_i = gnd
      ; resync_valid_i = gnd
      ; resync_next_seq_i = zero 32
      ; event_ready_i = vdd
      }
  in
  ready <-- (active &: (~:select_packet |: parser.ready_o));
  let sink =
    Cme_validation_sink.hierarchical
      ?uart_divisor
      ?snapshot_cycles
      ~instance:"diagnostic_sink"
      scope
      { clock_i = i.eth_tx_clk
      ; reset_i = tx_rst
      ; en_i = en
      ; packet_accepted_i = accepted &: network.app_tfirst_o &: select_packet
      ; event_valid_i = parser.event_valid_o
      ; event_i = parser.event_o
      ; rx_frame_done_i = network.rx_frame_done_o
      ; crc_error_i = network.crc_error_o
      ; checksum_ok_i = network.checksum_ok_o
      ; display_i = display
      }
  in
  { O.led = sink.led_o
  ; led0_r = heartbeat.toggle
  ; led0_g = sink.update_seen_o
  ; led0_b = gnd
  ; led1_r = gnd
  ; led1_g = phy.ready
  ; led1_b = network.udp_busy_o
  ; led2_r = sink.network_error_seen_o
  ; led2_g = network.checksum_ok_o
  ; led2_b = gnd
  ; led3_r = sink.diagnostic_seen_o
  ; led3_g = gnd
  ; led3_b = gnd
  ; uart_rxd_out = sink.uart_o
  ; eth_mdc = gnd
  ; eth_rstn = msb phy.cnt
  ; (* Receive-only harness: the MII transmit pins are parked. *)
    eth_ref_clk = ref_clk.dst_clk
  ; eth_tx_en = gnd
  ; eth_txd = zero 4
  }
;;
