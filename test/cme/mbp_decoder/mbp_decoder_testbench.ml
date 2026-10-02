(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "mbp_decoder_testbench.ml" *)
(* Exercise an abort behind a completed collector and stalled event register. *)

open! Core
open! Hardcaml
open Cme_of_hardcaml
module F = Schema_test_support.Schema_fixture
module T = Cme_types
module Stream = Stream_test_support.Stream_fixture

module Dut = struct
  include Mbp_decoder

  let name = "mbp_decoder"
end

module Fixture = Hardcaml_verif.Sim_fixture.Make (Dut)
module Step = Fixture.Step

module Observation = struct
  type t =
    { indices : int list
    ; abort_cycle : int
    ; done_cycle : int
    ; idle : bool
    }
  [@@deriving sexp, equal, compare]
end

let run ?(release_at = 200) () =
  let int width = Bits.of_int_trunc ~width in
  let m = F.message ~match_event_indicator:0x80 [ F.default_entry; F.default_entry ] in
  let body = String.drop_prefix m 10 |> fun s -> String.prefix s 80 in
  let source =
    Stream.packet body
    |> List.mapi ~f:(fun index beat ->
      T.Message_item.Of_bits.pack
        { (T.Message_item.Of_bits.zero ()) with
          kind = int 2 (if index = 0 then 0 else 1)
        ; message =
            (if index <> 0
             then T.Message_context.Of_bits.zero ()
             else
               { (T.Message_context.Of_bits.zero ()) with
                 msg_size = int 16 (String.length m)
               ; block_length = int 16 11
               ; template_id = int 16 46
               ; schema_id = int 16 1
               ; schema_version = int 16 13
               ; message_header_present = Bits.vdd
               })
        ; beat =
            { data = beat.data
            ; keep = int 8 beat.keep
            ; first = Bits.of_bool beat.first
            ; last = Bits.gnd
            }
        })
  in
  let abort =
    T.Message_item.Of_bits.pack
      { (T.Message_item.Of_bits.zero ()) with
        kind = int 2 T.Message_item_kind.diagnostic
      }
  in
  let testbench (handler : Step.Handler.t @ local) _ =
    let todo = ref source
    and body_done_at = ref None
    and aborted = ref false in
    let indices = ref []
    and abort_cycle = ref (-1)
    and done_cycle = ref (-1) in
    let held = ref None
    and idle = ref false
    and cycle = ref 0 in
    while (not !idle) && !cycle < release_at + 300 do
      let reset = !cycle = 0 in
      let send_abort =
        (not !aborted) && Option.exists !body_done_at ~f:(fun at -> !cycle >= at + 50)
      in
      let item = if send_abort then Some abort else List.hd !todo in
      let ready = !cycle >= release_at in
      let done_ready = !cycle >= release_at + 30 in
      let edge =
        Step.cycle
          handler
          { clock_i = Bits.gnd
          ; reset_i = Bits.of_bool reset
          ; en_i = Bits.vdd
          ; item_i = Option.value item ~default:(Bits.zero T.message_item_width)
          ; valid_i = Bits.of_bool ((not reset) && Option.is_some item)
          ; event_ready_i = Bits.of_bool ready
          ; done_ready_i = Bits.of_bool done_ready
          }
      in
      let o = Step.O_data.before_edge edge in
      Option.iter !held ~f:(fun old ->
        assert (Bits.equal old o.event_o && Bits.to_bool o.event_valid_o));
      if Bits.to_bool o.event_valid_o
      then (
        held := if ready then None else Some o.event_o;
        if ready
        then (
          let e = T.Event.Of_bits.unpack o.event_o in
          assert (Bits.to_int_trunc e.kind = T.Event_kind.mbp_update);
          assert (Int64.equal (Bits.to_int64_trunc e.price_mantissa) (-123L));
          indices := Bits.to_int_trunc e.entry_index :: !indices));
      if (not reset) && Option.is_some item && Bits.to_bool o.ready_o
      then
        if send_abort
        then (
          aborted := true;
          abort_cycle := !cycle)
        else (
          todo := List.tl_exn !todo;
          if List.is_empty !todo then body_done_at := Some !cycle);
      if Bits.to_bool o.done_o && done_ready then done_cycle := !cycle;
      idle := !done_cycle >= 0 && Bits.to_bool (Step.O_data.after_edge edge).idle_o;
      incr cycle
    done;
    assert !idle;
    { Observation.indices = List.rev !indices
    ; abort_cycle = !abort_cycle
    ; done_cycle = !done_cycle
    ; idle = !idle
    }
  in
  Fixture.run_with_timeout ~timeout:(release_at + 305) ~testbench
;;
