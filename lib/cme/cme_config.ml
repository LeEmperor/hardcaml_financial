(* Module: "cme_config.ml" *)
(* Elaboration-time storage parameters for the portable core. Phase 0 validates these
   parameters but does not instantiate storage yet.
*)

type t =
  { ingress_fifo_depth : int
  ; event_fifo_depth : int
  }

let default = { ingress_fifo_depth = 64; event_fifo_depth = 16 }

let validate t =
  if t.ingress_fifo_depth < 1 then invalid_arg "ingress_fifo_depth must be positive";
  if t.event_fifo_depth < 1 then invalid_arg "event_fifo_depth must be positive"
;;
