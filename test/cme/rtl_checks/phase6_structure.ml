(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "phase6_structure.ml" *)
(* Flattened graph loop check and explicit mux-width inventory. Wide normalized records
   are intentional; dynamic byte alignment must remain within the two-beat window. *)

open! Core
open! Hardcaml
open Cme_of_hardcaml
module T = Cme_types

let record_widths =
  [ T.Event.width
  ; T.packet_item_width
  ; T.message_item_width
  ; List.sum (module Int) (T.Ingress_beat.to_list T.Ingress_beat.port_widths) ~f:Fn.id
  ; List.sum (module Int) (T.Packet_context.to_list T.Packet_context.port_widths) ~f:Fn.id
  ; List.sum
      (module Int)
      (T.Message_context.to_list T.Message_context.port_widths)
      ~f:Fn.id
  ]
;;

let check_mux signal =
  let width = Signal.width signal in
  if width > 128 && not (List.mem record_widths width ~equal:Int.equal)
  then raise_s [%message "unreviewed wide mux" (width : int) (signal : Signal.t)]
;;

let () =
  let circuit = Cme_feed_parser.circuit () in
  assert (List.is_empty (Circuit.instantiations circuit));
  let graph = Circuit.signal_graph circuit in
  Signal_graph.detect_combinational_loops graph |> Or_error.ok_exn;
  let muxes = Hashtbl.Poly.create () in
  let registers = ref 0
  and register_bits = ref 0 in
  Signal_graph.iter graph ~f:(fun signal ->
    let choices =
      match signal with
      | Mux { cases; _ } -> Some (List.length cases)
      | Cases { cases; _ } -> Some (List.length cases + 1)
      | Reg _ ->
        incr registers;
        register_bits := !register_bits + Signal.width signal;
        None
      | _ -> None
    in
    Option.iter choices ~f:(fun choices ->
      check_mux signal;
      Hashtbl.update
        muxes
        (Signal.width signal, choices)
        ~f:(fun count -> Option.value count ~default:0 + 1)));
  printf "Flattened parser: no instantiations; combinational loop check PASS\n";
  printf
    "Hardcaml register nodes=%d register bits=%d (before synthesis; excludes memory \
     arrays)\n"
    !registers
    !register_bits;
  printf "Mux inventory (output bits, choices, nodes):\n";
  Hashtbl.to_alist muxes
  |> List.sort ~compare:(fun (a, _) (b, _) -> [%compare: int * int] a b)
  |> List.iter ~f:(fun ((width, choices), count) ->
    printf "%d %d %d\n" width choices count);
  (* Negative controls prevent an accidentally disabled check from passing silently. *)
  let loop = Signal.wire 1 in
  Signal.(loop <-- ~:loop);
  assert (
    Or_error.is_error
      (Signal_graph.detect_combinational_loops (Signal_graph.create [ loop ])));
  let wide =
    Signal.mux
      (Signal.input "offset" 3)
      (List.init 8 ~f:(fun n -> Signal.input (sprintf "packet%d" n) 512))
  in
  assert (
    try
      check_mux wide;
      false
    with
    | _ -> true);
  printf "Negative controls: feedback loop and 512-bit packet mux rejected\n"
;;
