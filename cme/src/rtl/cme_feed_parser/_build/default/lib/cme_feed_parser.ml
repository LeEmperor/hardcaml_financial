open Hardcaml

module Cme_feed_parser = struct
  (** Input ports *)
  module I = struct
    type 'a t =
      { clock : 'a
      ; clear : 'a
      ; valid : 'a
      ; data  : 'a [@bits 64]
      }
    [@@deriving hardcaml]
  end

  (** Output ports *)
  module O = struct
    type 'a t =
      { ready        : 'a
      ; msg_valid    : 'a
      ; msg_data     : 'a [@bits 64]
      }
    [@@deriving hardcaml]
  end

  (** Combinational/RTL implementation *)
  let create (i : _ I.t) : _ O.t =
    { 
      O.ready     = Signal.vdd ;
      msg_valid   = i.valid ;
      msg_data    = i.data
    }

end

(** Build a [Circuit.t] from the implementation above *)
let circuit () : Circuit.t =
  let module C = Circuit.With_interface (Cme_feed_parser.I) (Cme_feed_parser.O) in
  C.create_exn ~name:"cme_feed_parser" Cme_feed_parser.create

  (*create_exn is a function that takes in 
    1. a labelled name 
    2. a function that follows the signature:
        Signal.t I.t -> Signal.t O.t
    and returns:
      Circuit.t
  *)


