(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "helper_tb_functions.ml" *)
(* Serial-line stimulus helpers for [Cyclesim]-style testbenches: put a byte on a UART
   line, 8-N-1, least significant data bit first.

   These take the simulator's [cycle] as a callback and a [Bits.t ref] for the line, which
   is the shape the standalone testbench executables use. The four-file suites under
   [test/<domain>/<dut>/] do not use this module - they drive through
   [Hardcaml_step_testbench] and build their stimulus from the DUT's own [I] record. Reach
   for [hardcaml_verif] first; this is here for the harnesses that predate it and for
   quick one-off scripts.

   [cycles_per_symbol] is how many clock cycles one bit lasts, i.e. the tick spacing the
   DUT is being driven at - not a baud rate. A real 115200-baud line at 100 MHz would be
   868, which no simulation wants to sit through.

   Tags: [{ "ACTIVE" ; "TEST" ; "TESTBENCH" ; "COMMON_ITEMS" }]
*)

open! Core
open! Hardcaml

let ( <-- ) (r : Bits.t ref) i = r := Bits.of_int_trunc ~width:(Bits.width !r) i

(* Hold [value] on the line for one whole symbol. The DUT samples on its own tick, so the
   line has to be steady for the interval rather than pulsed at the sample point. *)
let send_bit ~cycle ~(line : Bits.t ref) ~cycles_per_symbol value =
  line <-- if value then 1 else 0;
  for _ = 1 to cycles_per_symbol do
    cycle ()
  done
;;

(* One 8-N-1 frame: a space start bit, eight data bits least significant first, a mark
   stop bit. *)
let send_byte ~cycle ~line ~cycles_per_symbol byte =
  send_bit ~cycle ~line ~cycles_per_symbol false;
  for index = 0 to 7 do
    send_bit ~cycle ~line ~cycles_per_symbol ((byte lsr index) land 1 = 1)
  done;
  send_bit ~cycle ~line ~cycles_per_symbol true
;;

let send_bytes ~cycle ~line ~cycles_per_symbol name bytes =
  printf "\nsending %s: %d bytes" name (List.length bytes);
  List.iter bytes ~f:(fun byte -> send_byte ~cycle ~line ~cycles_per_symbol byte)
;;

(* Line at mark, which is what it must sit at between frames. *)
let idle ~cycle ~line ~num_cycles =
  line <-- 1;
  for _ = 1 to num_cycles do
    cycle ()
  done
;;
