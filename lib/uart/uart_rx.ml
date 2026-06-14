(*
  Module: Uart_rx

  RX side of the UART transceiver.
*)

open! Core
open! Hardcaml
open! Signal
open! Always

let () =
  Stdio.print_endline "=== Imported UART RX ==="

module I = struct
  type 'a t = {
    clock     : 'a;
    reset     : 'a;
    en        : 'a;
    tick      : 'a;
    uart_rx_d : 'a;
  } [@@deriving hardcaml]
end

module O = struct
  type 'a t = {
    keep        : 'a;
    d_out       : 'a [@bits 8];
    d_out_valid : 'a;
  } [@@deriving hardcaml]
end

module States = struct
  type t =
    | IDLE    (* line idles high; wait for start bit *)
    | START   (* start bit detected; sync to baud tick *)
    | PAYLOAD (* shift in 8 data bits, LSB first *)
    | STOP    (* stop bit window; d_out_valid held high *)
    | DONE
    [@@deriving sexp_of, compare ~localize, enumerate]
end

let create scope (i : _ I.t) : _ O.t =

  let _scope       = Scope.sub_scope scope "uart_rx" in

  let clock        = i.I.clock in
  let reset        = i.I.reset in
  let en           = i.I.en in
  let rising_edge  = Reg_spec.create ~clock ~clear:reset () in

  let sm                 = Always.State_machine.create (module States) ~enable:en rising_edge in
  let data_place_counter = Always.Variable.reg  ~enable:vdd ~width:3 rising_edge in
  let rx_byte            = Always.Variable.reg  ~enable:vdd ~width:8 rising_edge in
  let d_out_valid_w      = Always.Variable.wire ~default:(Signal.zero 1) () in

  (* Falling edge on uart_rx_d signals the start bit. *)
  let start_bit = Helper_circuits.falling_edge_detector rising_edge i.I.uart_rx_d in

  Always.(
    compile [
      d_out_valid_w <--. 0;

      sm.switch ~default:[] [
        IDLE, [
          when_ start_bit [
            sm.set_next START;
          ];
        ];

        START, [
          (* Wait for the next baud tick so that subsequent ticks land
             at roughly the same phase as the transmitter's bit boundaries. *)
          when_ i.I.tick [
            data_place_counter <--. 0;
            sm.set_next PAYLOAD;
          ];
        ];

        PAYLOAD, [
          when_ i.I.tick [
            (* Shift right: new bit enters at the MSB.  After 8 ticks:
               rx_byte = {b7, b6, ..., b0}, b0 = first received = LSB. *)
            rx_byte <-- concat_msb [i.I.uart_rx_d; drop_bottom rx_byte.value ~width:1];
            if_ (data_place_counter.value ==: of_int_trunc ~width:3 7) [
              sm.set_next STOP;
            ] [
              data_place_counter <-- data_place_counter.value +:. 1;
            ];
          ];
        ];

        STOP, [
          d_out_valid_w <--. 1;
          when_ i.I.tick [
            sm.set_next IDLE;
          ];
        ];
      ];
    ]
  );

  ignore (rx_byte.value            -- "rx_byte");
  ignore (data_place_counter.value -- "bit_ctr");

  {
    d_out       = rx_byte.value;
    d_out_valid = d_out_valid_w.value;
    keep        = reduce ~f:(|:) (bits_lsb rx_byte.value @ bits_lsb data_place_counter.value @ [d_out_valid_w.value]);
  }
