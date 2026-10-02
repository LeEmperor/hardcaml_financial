(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "cme_feed_parser_testbench.ml" *)

(* Testbench Support: Cme_feed_parser

   Shared DUT fixture, drivers, observations, and simulation scenarios used by the unit,
   Quickcheck, and expect test suites.

   The DUT is a skeleton: the ports are settled and the datapath is not, so what this
   suite pins down is the contract as it stands rather than any unpacking behavior.
   [data_out] is tied to zero and [slave_ready] to one, and both of those are claims -
   "the block never backpressures" and "nothing has been unpacked yet" - that a datapath
   landing here will have to break deliberately rather than by accident. When it does,
   these goldens are the diff that says so.

   Sampling. Both sides. The block is purely combinational today, so [before_edge] and
   [after_edge] agree, and [run_beat] returns both rather than picking one: a registered
   stage cannot be added here without a test noticing.

   Tags: [{ "ACTIVE" ; "TEST" ; "TESTBENCH" ; "COMMON_ITEMS" }]
*)

open! Core
open! Hardcaml
open! Cme_of_hardcaml
open! Hardcaml_step_testbench
open! Hardcaml_verif
module Dut = Cme_feed_parser

(* One beat's worth of stimulus. [data] is the 64-byte ingress word, given as an integer
   because the suite only ever drives values that fit one - a wider pattern would need a
   [Bits.t] and would not be more informative against a tie-off. *)
module Stimulus = struct
  type t =
    { rst : bool
    ; valid : bool
    ; data : int
    }
  [@@deriving sexp, equal, compare]

  let idle = { rst = false; valid = false; data = 0 }
  let beat data = { rst = false; valid = true; data }
  let clear = { rst = true; valid = false; data = 0 }
end

module Observation = struct
  type t =
    { stimulus : Stimulus.t
    ; data_out : int
    ; slave_ready : bool
    }
  [@@deriving sexp, equal, compare]
end

(* [data_out] is 512 bits wide, so it is rendered rather than printed as an integer: a
   wide value in decimal is not reviewable, and the tie-off is more legible as a width
   plus a hex digest than as a number. *)
module Compact_observation = struct
  type t =
    { data_out : string
    ; slave_ready : bool
    }
  [@@deriving sexp, equal, compare]

  let of_observation ({ data_out; slave_ready; _ } : Observation.t) =
    { data_out = sprintf "0x%x" data_out; slave_ready }
  ;;
end

module Edges = struct
  type t =
    { before_edge : Observation.t
    ; after_edge : Observation.t
    }
  [@@deriving sexp, equal, compare]
end

module Testbench = struct
  module Fixture = Sim_fixture.Make (struct
      include Dut

      let name = "Cme_feed_parser"
    end)

  module Sim = Fixture.Sim
  module Step = Fixture.Step

  let bit = Bits_conv.bit

  let inputs ({ rst; valid; data } : Stimulus.t) =
    { Step.input_hold with
      rst = bit rst
    ; valid = bit valid
    ; data = Bits.of_int_trunc ~width:512 data
    }
  ;;

  let snapshot stimulus (output : Bits.t Dut.O.t) =
    { Observation.stimulus
    ; data_out = Bits.to_int_trunc output.data_out
    ; slave_ready = Bits.to_bool output.slave_ready
    }
  ;;

  let reset ?(num_cycles = 2) (handler : Step.Handler.t @ local) =
    Step.delay ~num_cycles handler (inputs Stimulus.clear)
  ;;

  let create_simulator = Fixture.create_simulator
  let run_with_timeout = Fixture.run_with_timeout

  let run_stimuli stimuli =
    let testbench (handler : Step.Handler.t @ local) _initial_outputs =
      let rec loop (handler : Step.Handler.t @ local) = function
        | [] -> []
        | stimulus :: remaining ->
          let observation =
            Step.cycle handler (inputs stimulus)
            |> Step.O_data.after_edge
            |> snapshot stimulus
          in
          observation :: loop handler remaining
      in
      reset handler;
      loop handler stimuli
    in
    run_with_timeout ~timeout:(8 + List.length stimuli) ~testbench
  ;;

  (* Both sides of one beat's edge, so the block's combinational-ness is asserted rather
     than assumed. *)
  let run_beat stimulus =
    let testbench (handler : Step.Handler.t @ local) _initial_outputs =
      reset handler;
      let outputs = Step.cycle handler (inputs stimulus) in
      { Edges.before_edge = snapshot stimulus (Step.O_data.before_edge outputs)
      ; after_edge = snapshot stimulus (Step.O_data.after_edge outputs)
      }
    in
    run_with_timeout ~timeout:12 ~testbench
  ;;
end
