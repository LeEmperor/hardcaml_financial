(*
  Module: Uart_frame_parser

  Given no ethernet, need some basic way to frame ethernet transfers in an ethernet-like way.


  Assume this module is receiving in the information from a fifo that contains the uart beats.
*)

open! Core
open! Hardcaml
open! Signal
open! Hardcaml_circuits

let () =
  Stdio.print_endline "=== Imported UART Frame Parser ==="
;;

module I = struct
  type 'a t =
    { 
      clock   : 'a;
      reset   : 'a;

      uart_byte : 'a [@bits 8]
    }
  [@@deriving hardcaml]
end

module O = struct
  type 'a t =
    {
      bruh : 'a;
    }
  [@@deriving hardcaml]
end

module I_Wires = struct
  type 'a t =
    {
      bruh1 : 'a;
    }
  [@@deriving hardcaml]
end

module I_Regs = struct
  type 'a t =
    {
      bruh2 : 'a;
    }
  [@@deriving hardcaml]
end

module States = struct
  type t = 
    | Wait_frame
    | Length_hi
    | Length_lo
    | Payload
  [@@deriving sexp_of, compare ~localize, enumerate]

  let width = Int.ceil_log2 (List.length all)

  let to_signal t =
    List.findi_exn all ~f:(fun _ v -> compare v t = 0)
    |> fst
    |> Signal.of_int_trunc ~width
  ;;
end

let create scope i : _ O.t =
  (* let _scope = Scope.subscope  *)

  let reset = i.I.reset in
  let clock = i.I.clock in
  let rising_edge = Reg_spec.create ~clock ~clear:reset ()  in


  (* roughly follows a state machine of 
  1. Wait_frame
    wait until data is available in the fifo

   *)




  { O.
    bruh = zero 1;
  }


