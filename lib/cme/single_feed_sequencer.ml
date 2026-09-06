(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "single_feed_sequencer.ml" *)
(* Single-feed admission with ordered diagnostics. Controls must be fenced by the
   composition boundary; quiescent_i includes downstream pending work. *)

open! Hardcaml
open Signal

module I = struct
  type 'a t =
    { (* Application domain; synchronous reset overrides the shared enable pause. *)
      clock_i : 'a
    ; reset_i : 'a
    ; en_i : 'a
    ; (* Ordered pre-sequence Packet_item stream from header extraction. *)
      item_i : 'a [@bits Cme_types.packet_item_width]
    ; valid_i : 'a
    ; (* Consumer of the packed canonical packet stream. *)
      ready_i : 'a
    ; (* No buffered upstream or downstream work; requests are not latched while busy. *)
      quiescent_i : 'a
    ; session_reset_i : 'a
    ; resync_valid_i : 'a
    ; resync_next_seq_i : 'a [@bits 32]
    }
  [@@deriving hardcaml]
end

module O = struct
  type 'a t =
    { ready_o : 'a
    ; valid_o : 'a
    ; (* Cme_types.Packet_item packed in declaration order. *)
      item_o : 'a [@bits Cme_types.packet_item_width]
    ; control_ready_o : 'a
    ; idle_o : 'a
    }
  [@@deriving hardcaml]
end

let create (_scope : Scope.t) (i : _ I.t) =
  let module T = Cme_types in
  let spec = Reg_spec.create ~clock:i.clock_i ~clear:i.reset_i () in
  let active = i.en_i &: ~:(i.reset_i) in
  let item = T.Packet_item.Of_signal.unpack i.item_i in
  let initialized, channel_valid, expected = wire 1, wire 1, wire 32 in
  let dropping, gap_sent, open_packet = wire 1, wire 1, wire 1 in
  let idle = ~:(dropping |: gap_sent |: open_packet) in
  let control_ready = active &: idle &: i.quiescent_i in
  let session_reset = control_ready &: i.session_reset_i in
  let resync = control_ready &: ~:(i.session_reset_i) &: i.resync_valid_i in
  let control = session_reset |: resync in
  let start = item.kind ==:. T.Packet_item_kind.start in
  let diagnostic = item.kind ==:. T.Packet_item_kind.diagnostic in
  let last = item.beat.last |: (start &: item.body_empty) in
  let delta = item.context.packet_seq -: expected in
  let late = msb delta in
  let fault = start &: initialized &: (delta <>:. 0) &: ~:gap_sent in
  let emit_fault = fault &: ~:dropping in
  let valid = active &: i.valid_i &: ~:dropping &: ~:control in
  let ready = active &: ~:control &: (dropping |: (i.ready_i &: ~:emit_fault)) in
  let input_transfer = i.valid_i &: ready in
  let fault_transfer = valid &: i.ready_i &: emit_fault in
  let admit = input_transfer &: start &: ~:dropping in
  initialized
  <-- reg
        spec
        ~enable:active
        (mux2 session_reset gnd (mux2 (resync |: admit) vdd initialized));
  expected
  <-- reg
        spec
        ~enable:active
        (mux2
           session_reset
           (zero 32)
           (mux2
              resync
              i.resync_next_seq_i
              (mux2 admit (item.context.packet_seq +:. 1) expected)));
  channel_valid
  <-- reg
        spec
        ~enable:active
        (mux2
           session_reset
           gnd
           (mux2
              resync
              vdd
              (mux2
                 (fault_transfer &: ~:late)
                 gnd
                 (mux2 (admit &: ~:initialized) vdd channel_valid))));
  dropping
  <-- reg
        spec
        ~enable:active
        (mux2 (fault_transfer &: late) vdd (mux2 (input_transfer &: last) gnd dropping));
  gap_sent
  <-- reg
        spec
        ~enable:active
        (mux2 (fault_transfer &: ~:late) vdd (mux2 admit gnd gap_sent));
  open_packet
  <-- reg spec ~enable:active (mux2 (input_transfer &: ~:diagnostic) ~:last open_packet);
  let admitted_context =
    { item.context with channel_valid = mux2 initialized channel_valid vdd }
  in
  let passed =
    { item with
      context = T.Packet_context.Of_signal.mux2 start admitted_context item.context
    ; diagnostic =
        T.Event.Of_signal.mux2
          diagnostic
          { item.diagnostic with packet = { item.diagnostic.packet with channel_valid } }
          item.diagnostic
    }
  in
  let event =
    { (T.Event.Of_signal.zero ()) with
      kind = of_int_trunc ~width:2 T.Event_kind.diagnostic
    ; packet = { item.context with channel_valid = mux2 late channel_valid gnd }
    ; diagnostic_code =
        mux2
          late
          (of_int_trunc ~width:8 T.Diagnostic_code.duplicate_or_late)
          (of_int_trunc ~width:8 T.Diagnostic_code.sequence_gap)
    ; expected_seq = expected
    ; expected_seq_present = vdd
    }
  in
  let fault_item =
    { (T.Packet_item.Of_signal.zero ()) with
      kind = of_int_trunc ~width:2 T.Packet_item_kind.diagnostic
    ; diagnostic = event
    }
  in
  { O.ready_o = ready
  ; valid_o = valid
  ; item_o =
      T.Packet_item.Of_signal.pack
        (T.Packet_item.Of_signal.mux2 emit_fault fault_item passed)
  ; control_ready_o = control_ready
  ; idle_o = idle
  }
;;

let hierarchical ?instance scope i =
  let module H = Hierarchy.In_scope (I) (O) in
  H.hierarchical ?instance ~name:"cme_single_feed_sequencer" ~scope create i
;;
