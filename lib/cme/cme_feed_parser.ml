(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "cme_feed_parser.ml" *)
(* CME MDP 3.0 unpacker.

   Skeleton: the AXI-Stream-shaped ports are settled, the datapath is not. The block
   accepts a 64-byte beat per cycle and is meant to emit one unpacked SBE message per
   beat; [slave_ready] is tied high until there is a datapath to backpressure for.

   The module follows the repository's [I] / [O] / [create scope] shape rather than
   nesting a second module of the same name inside the file, so [Cme_feed_parser.I] is the
   interface and [Circuit.With_interface] can be applied to it directly.
*)

open! Core
open! Hardcaml
open! Signal

module I = struct
  type 'a t =
    { clk : 'a
    ; rst : 'a
    ; (* AXI-Stream-shaped ingress: one 64-byte beat per cycle. *)
      valid : 'a
    ; data : 'a [@bits 512]
    }
  [@@deriving hardcaml]
end

module O = struct
  type 'a t =
    { data_out : 'a [@bits 512]
    ; slave_ready : 'a
    }
  [@@deriving hardcaml]
end

let create (_scope : Scope.t) (_i : _ I.t) : _ O.t =
  { O.data_out = Signal.zero 512; slave_ready = Signal.vdd }
;;
