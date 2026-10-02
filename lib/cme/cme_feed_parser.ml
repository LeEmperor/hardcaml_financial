(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "cme_feed_parser.ml" *)
(* Portable CME MDP 3.0 parser: framed UDP payloads to ordered normalized MBP events. *)

open! Hardcaml

module I = struct
  type 'a t =
    { (* Application domain; active-high synchronous reset overrides enable. *)
      clock_i : 'a
    ; reset_i : 'a
    ; en_i : 'a
    ; (* Trusted UDP payload; lane 0 is the earliest byte. *)
      data_i : 'a [@bits 64]
    ; keep_i : 'a [@bits 8]
    ; valid_i : 'a
    ; first_i : 'a
    ; last_i : 'a
    ; ingress_timestamp_i : 'a [@bits 64]
    ; (* Idle-only sequencer controls; session reset wins over resync. *)
      session_reset_i : 'a
    ; resync_valid_i : 'a
    ; resync_next_seq_i : 'a [@bits 32]
    ; (* Ordered normalized-event consumer, in the same clock domain. *)
      event_ready_i : 'a
    }
  [@@deriving hardcaml]
end

module O = struct
  type 'a t =
    { ready_o : 'a
    ; control_ready_o : 'a
    ; event_valid_o : 'a
    ; event_o : 'a [@bits Cme_types.Event.width]
    }
  [@@deriving hardcaml]
end

let create ?(config = Cme_config.default) (scope : Scope.t) (i : Signal.t I.t)
  : Signal.t O.t
  =
  Cme_config.validate config;
  let open Signal in
  let order_ready, downstream_idle = wire 1, wire 1 in
  let decoder_ready, decoder_valid, decoder_done = wire 1, wire 1, wire 1 in
  let decoder_event = wire Cme_types.Event.width in
  let fifo_ready = wire 1 in
  let messages =
    Message_pipeline.hierarchical
      ~config
      ~supported_templates:[ Generated_mbp_descriptor.template_id ]
      scope
      { clock_i = i.clock_i
      ; reset_i = i.reset_i
      ; en_i = i.en_i
      ; data_i = i.data_i
      ; keep_i = i.keep_i
      ; valid_i = i.valid_i
      ; first_i = i.first_i
      ; last_i = i.last_i
      ; ingress_timestamp_i = i.ingress_timestamp_i
      ; session_reset_i = i.session_reset_i
      ; resync_valid_i = i.resync_valid_i
      ; resync_next_seq_i = i.resync_next_seq_i
      ; ready_i = order_ready
      ; downstream_idle_i = downstream_idle
      }
  in
  let order =
    Event_orderer.hierarchical
      scope
      { clock_i = i.clock_i
      ; reset_i = i.reset_i
      ; en_i = i.en_i
      ; item_i = messages.item_o
      ; valid_i = messages.valid_o
      ; decoder_ready_i = decoder_ready
      ; decoder_event_i = decoder_event
      ; decoder_event_valid_i = decoder_valid
      ; decoder_done_i = decoder_done
      ; event_ready_i = fifo_ready
      }
  in
  let decoder =
    Mbp_decoder.hierarchical
      scope
      { clock_i = i.clock_i
      ; reset_i = i.reset_i
      ; en_i = i.en_i
      ; item_i = order.decoder_item_o
      ; valid_i = order.decoder_valid_o
      ; event_ready_i = order.decoder_event_ready_o
      ; done_ready_i = order.decoder_done_ready_o
      }
  in
  let events =
    Event_fifo.hierarchical
      ~depth:config.event_fifo_depth
      ~fallthrough:true
      scope
      { clock_i = i.clock_i
      ; reset_i = i.reset_i
      ; en_i = i.en_i
      ; event_i = order.event_o
      ; event_valid_i = order.event_valid_o
      ; event_ready_i = i.event_ready_i
      }
  in
  order_ready <-- order.ready_o;
  decoder_ready <-- decoder.ready_o;
  decoder_valid <-- decoder.event_valid_o;
  decoder_event <-- decoder.event_o;
  decoder_done <-- decoder.done_o;
  fifo_ready <-- events.event_ready_o;
  downstream_idle <-- (order.idle_o &: decoder.idle_o &: ~:(events.event_valid_o));
  { O.ready_o = messages.ready_o
  ; control_ready_o = messages.control_ready_o
  ; event_valid_o = events.event_valid_o
  ; event_o = events.event_o
  }
;;

let hierarchical ?(config = Cme_config.default) ?instance scope i =
  let module H = Hierarchy.In_scope (I) (O) in
  H.hierarchical ?instance ~name:"cme_mdp3_feed_parser" ~scope (create ~config) i
;;

let circuit ?(config = Cme_config.default) () =
  let scope = Scope.create ~flatten_design:true () in
  let module C = Circuit.With_interface (I) (O) in
  C.create_exn ~name:"cme_mdp3_feed_parser" (create ~config scope)
;;
