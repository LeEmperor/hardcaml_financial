(*
  this is an MDP 3.0 Unpacker
*)

open Hardcaml

module Cme_feed_parser = struct
  (* input port *)
  module I = struct
    type 'a t =
      { 
        clk   : 'a;
        rst   : 'a;

        (* behave like an AXIS *)
        valid : 'a;
        data  : 'a [@bytes 64];
      }
    [@@deriving hardcaml]
  end

  (* output port*)
  module O = struct
    type 'a t =
      {
        data : 'a [@bits 512];
        slave_ready : 'a;
      }
    [@@deriving hardcaml]
  end

  (** Combinational/RTL implementation *)
  let create (i : _ I.t) : _ O.t =




    (* resulting thingy *)
    { 
      O.data = Signal.vdd;
      O.slave_ready     = Signal.vdd;
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


