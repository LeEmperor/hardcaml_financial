(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "packet_header.ml" *)
(* Collect the twelve-byte technical header using the two-beat aligner. Output is the
   ordered pre-sequence packet stream; idle includes buffered bytes. *)

open! Hardcaml
open Signal

module I = struct
  type 'a t =
    { (* Application domain; synchronous reset overrides the shared enable pause. *)
      clock_i : 'a
    ; reset_i : 'a
    ; en_i : 'a
    ; (* Framed low-byte-first UDP payload; timestamp is sampled on first only. *)
      data_i : 'a [@bits 64]
    ; keep_i : 'a [@bits 8]
    ; first_i : 'a
    ; last_i : 'a
    ; ingress_timestamp_i : 'a [@bits 64]
    ; valid_i : 'a
    ; (* Consumer of the packed pre-sequence packet stream. *)
      ready_i : 'a
    }
  [@@deriving hardcaml]
end

module O = struct
  type 'a t =
    { ready_o : 'a
    ; valid_o : 'a
    ; (* Cme_types.Packet_item packed in declaration order. *)
      item_o : 'a [@bits Cme_types.packet_item_width]
    ; idle_o : 'a
    }
  [@@deriving hardcaml]
end

let create scope (i : _ I.t) =
  let module T = Cme_types in
  let spec = Reg_spec.create ~clock:i.clock_i ~clear:i.reset_i () in
  let active = i.en_i &: ~:(i.reset_i) in
  (* 0: first eight header bytes; 1: remaining four; 2: body; 3: header-only marker; 4:
     short-header diagnostic. *)
  let state = wire 3 in
  let consume_count, consume_valid = wire 4, wire 1 in
  let a =
    Byte_aligner.hierarchical
      scope
      { clock_i = i.clock_i
      ; reset_i = i.reset_i
      ; en_i = i.en_i
      ; data_i = i.data_i
      ; keep_i = i.keep_i
      ; first_i = i.first_i
      ; last_i = i.last_i
      ; ingress_timestamp_i = i.ingress_timestamp_i
      ; valid_i = i.valid_i
      ; consume_count_i = consume_count
      ; consume_valid_i = consume_valid
      }
  in
  let collecting = state <:. 2 in
  let required =
    mux2 (state ==:. 0) (of_int_trunc ~width:5 8) (of_int_trunc ~width:5 4)
  in
  let enough = a.available_o >=: required in
  let collect = collecting &: a.valid_o &: (enough |: a.boundary_o) in
  (* Eight bytes ending the packet are still a short twelve-byte header. Do not enter the
     second collector after consuming that boundary. *)
  let short =
    collect &: (~:enough |: (state ==:. 0 &: a.boundary_o &: (a.available_o ==:. 8)))
  in
  let body_count = mux2 (a.available_o >=:. 8) (of_int_trunc ~width:5 8) a.available_o in
  let body_last = a.boundary_o &: (a.available_o <=:. 8) in
  let body_valid = state ==:. 2 &: a.valid_o &: (a.available_o >=:. 8 |: a.boundary_o) in
  let valid = active &: (body_valid |: (state ==:. 3) |: (state ==:. 4)) in
  let transfer = valid &: i.ready_i in
  consume_valid <-- (collect |: (body_valid &: i.ready_i));
  consume_count
  <-- uresize (mux2 collecting (mux2 enough required a.available_o) body_count) ~width:4;
  state
  <-- reg
        spec
        ~enable:active
        (mux2
           collect
           (mux2
              short
              (of_int_trunc ~width:3 4)
              (mux2
                 (state ==:. 0)
                 (of_int_trunc ~width:3 1)
                 (mux2
                    (a.boundary_o &: (a.available_o ==:. 4))
                    (of_int_trunc ~width:3 3)
                    (of_int_trunc ~width:3 2))))
           (mux2 (transfer &: (state <>:. 2 |: body_last)) (zero 3) state));
  let first_half =
    reg spec ~enable:(collect &: (state ==:. 0)) (select a.data_o ~high:63 ~low:0)
  in
  let second_half =
    reg spec ~enable:(collect &: (state ==:. 1)) (select a.data_o ~high:31 ~low:0)
  in
  let timestamp = reg spec ~enable:(collect &: (state ==:. 0)) a.ingress_timestamp_o in
  let missing_offset =
    reg spec ~enable:short (a.packet_byte_offset_o +: uresize a.available_o ~width:16)
  in
  let started =
    reg_fb spec ~enable:active ~width:1 ~f:(fun q ->
      mux2 collecting gnd (mux2 (transfer &: body_valid) vdd q))
  in
  let context : _ T.Packet_context.t =
    { ingress_timestamp = timestamp
    ; source_id = gnd
    ; packet_seq = select first_half ~high:31 ~low:0
    ; sending_time = concat_msb [ second_half; select first_half ~high:63 ~low:32 ]
    ; packet_header_present = vdd
    ; channel_valid = gnd
    }
  in
  let empty = T.Packet_item.Of_signal.zero () in
  let keep =
    mux
      (uresize body_count ~width:4)
      (List.init 9 (fun n -> of_int_trunc ~width:8 ((1 lsl n) - 1)))
  in
  let body =
    { empty with
      kind = mux2 started (of_int_trunc ~width:2 T.Packet_item_kind.body) (zero 2)
    ; context =
        T.Packet_context.Of_signal.mux2
          started
          (T.Packet_context.Of_signal.zero ())
          context
    ; beat =
        { data = Byte_aligner.mask_data (select a.data_o ~high:63 ~low:0) keep
        ; keep
        ; first = ~:started
        ; last = body_last
        }
    }
  in
  let marker = { empty with context; body_empty = vdd } in
  let diagnostic =
    { (T.Event.Of_signal.zero ()) with
      kind = of_int_trunc ~width:2 T.Event_kind.diagnostic
    ; packet = { (T.Packet_context.Of_signal.zero ()) with ingress_timestamp = timestamp }
    ; diagnostic_code = of_int_trunc ~width:8 T.Diagnostic_code.truncated_packet_header
    ; diagnostic_byte_offset = missing_offset
    }
  in
  let error =
    { empty with kind = of_int_trunc ~width:2 T.Packet_item_kind.diagnostic; diagnostic }
  in
  { O.ready_o = a.ready_o
  ; valid_o = valid
  ; item_o =
      T.Packet_item.Of_signal.pack
        (T.Packet_item.Of_signal.mux2
           (state ==:. 4)
           error
           (T.Packet_item.Of_signal.mux2 (state ==:. 3) marker body))
  ; idle_o = state ==:. 0 &: (a.available_o ==:. 0)
  }
;;

let hierarchical ?instance scope i =
  let module H = Hierarchy.In_scope (I) (O) in
  H.hierarchical ?instance ~name:"cme_packet_header" ~scope create i
;;
