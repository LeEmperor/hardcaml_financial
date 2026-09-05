(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "byte_aligner.ml" *)
(* Two stored beats expose a low-byte-first peek window. An accepted consume retires 0..8
   bytes; filling a free slot may extend the window without consuming anything. A
   following packet can occupy slot 1 but is never visible in the current window.
*)

open! Hardcaml
open Signal

module I = struct
  type 'a t =
    { (* Application clock; synchronous reset overrides enable. *)
      clock_i : 'a
    ; reset_i : 'a
    ; en_i : 'a
    ; (* Ingress_beat fields; timestamp is meaningful on first only. *)
      data_i : 'a [@bits 64]
    ; keep_i : 'a [@bits 8]
    ; first_i : 'a
    ; last_i : 'a
    ; ingress_timestamp_i : 'a [@bits 64]
    ; valid_i : 'a
    ; (* A command transfers on consume_valid_i && consume_ready_o. *)
      consume_valid_i : 'a
    ; consume_count_i : 'a [@bits 4]
    }
  [@@deriving hardcaml]
end

module O = struct
  type 'a t =
    { ready_o : 'a
    ; (* Peek interface, not a ready/valid output beat. Available bytes can grow during a
         stall; already available bytes and their context remain stable. *)
      valid_o : 'a
    ; data_o : 'a [@bits 128]
    ; available_o : 'a [@bits 5]
    ; boundary_o : 'a
    ; first_o : 'a
    ; ingress_timestamp_o : 'a [@bits 64]
    ; packet_byte_offset_o : 'a [@bits 16]
    ; consume_ready_o : 'a
    }
  [@@deriving hardcaml]
end

let byte_count keep =
  (* Legal masks are nonzero contiguous low lanes; the testbench checks that contract. *)
  List.init 8 (fun n -> mux2 (bit keep ~pos:n) (of_int_trunc ~width:4 (n + 1)) (zero 4))
  |> List.fold_left (fun count next -> mux2 (next <>:. 0) next count) (zero 4)
;;

let mask_data data keep =
  List.init 8 (fun n ->
    mux2 (bit keep ~pos:n) (select data ~high:((n * 8) + 7) ~low:(n * 8)) (zero 8))
  |> concat_lsb
;;

let create (_scope : Scope.t) (i : _ I.t) =
  let spec = Reg_spec.create ~clock:i.clock_i ~clear:i.reset_i () in
  let active = i.en_i &: ~:(i.reset_i) in
  let module B = Cme_types.Ingress_beat in
  let input =
    B.Of_signal.pack
      { beat =
          { data = mask_data i.data_i i.keep_i
          ; keep = i.keep_i
          ; first = i.first_i
          ; last = i.last_i
          }
      ; ingress_timestamp = mux2 i.first_i i.ingress_timestamp_i (zero 64)
      }
  in
  let slot_width = width input in
  let slot0, slot1 = wire slot_width, wire slot_width in
  let count = wire 2 in
  let offset = wire 3 in
  let head, tail = B.Of_signal.unpack slot0, B.Of_signal.unpack slot1 in
  let occupied = count <>:. 0 in
  let join_tail = count ==:. 2 &: ~:(head.beat.last) in
  let remaining =
    uresize (byte_count head.beat.keep) ~width:5 -: uresize offset ~width:5
  in
  let available =
    mux2
      occupied
      (remaining +: mux2 join_tail (uresize (byte_count tail.beat.keep) ~width:5) (zero 5))
      (zero 5)
  in
  let boundary = occupied &: (head.beat.last |: (join_tail &: tail.beat.last)) in
  let valid = active &: occupied in
  let requested = uresize i.consume_count_i ~width:5 in
  let consume_ready = valid &: (requested <=:. 8) &: (requested <=: available) in
  let consume = consume_ready &: i.consume_valid_i &: (requested <>:. 0) in
  let pop_head = consume &: (requested >=: remaining) in
  let pop_tail = pop_head &: join_tail &: (requested ==: available) in
  let pops = mux2 pop_tail (of_int_trunc ~width:2 2) (uresize pop_head ~width:2) in
  let retained = count -: pops in
  let ready = active &: (retained <:. 2) in
  let push = ready &: i.valid_i in
  count <-- reg spec ~enable:active (retained +: uresize push ~width:2);
  let next_head = mux2 pop_head slot1 slot0 in
  slot0 <-- reg spec ~enable:active (mux2 (push &: (retained ==:. 0)) input next_head);
  slot1 <-- reg spec ~enable:active (mux2 (push &: (retained ==:. 1)) input slot1);
  let next_offset =
    mux2
      pop_tail
      (zero 3)
      (mux2
         pop_head
         (uresize (requested -: remaining) ~width:3)
         (offset +: uresize requested ~width:3))
  in
  offset <-- reg spec ~enable:consume next_offset;
  let packet_end = consume &: boundary &: (requested ==: available) in
  let packet_offset =
    reg_fb spec ~enable:consume ~width:16 ~f:(fun q ->
      mux2 packet_end (zero 16) (q +: uresize requested ~width:16))
  in
  let first = occupied &: head.beat.first &: (offset ==:. 0) in
  let timestamp = reg spec ~enable:(consume &: first) head.ingress_timestamp in
  let window = concat_msb [ mux2 join_tail tail.beat.data (zero 64); head.beat.data ] in
  let aligned = mux offset (List.init 8 (fun n -> srl window ~by:(n * 8))) in
  { O.ready_o = ready
  ; valid_o = valid
  ; data_o = mux2 occupied aligned (zero 128)
  ; available_o = available
  ; boundary_o = boundary
  ; first_o = first
  ; ingress_timestamp_o = mux2 first head.ingress_timestamp timestamp
  ; packet_byte_offset_o = packet_offset
  ; consume_ready_o = consume_ready
  }
;;

let hierarchical ?instance scope i =
  let module H = Hierarchy.In_scope (I) (O) in
  H.hierarchical ?instance ~name:"cme_byte_aligner" ~scope create i
;;
