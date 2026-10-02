(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "mbp_decoder_invariant_tests.ml" *)
(* The decoder's group-size bound checks must never diverge from the bound they stand for.

   Every "does this group fit in the message body" test used to read
   [position + consume_count + bytes <= body_size] directly, which put the late consume
   decision into a 24-bit add whose other operand was a group-size multiply. Vivado fuses
   that add into the multiplier's DSP48E1, so [collected] reached [skip_left] through two
   DSPs in series - 4.3 ns of logic on a 6.4 ns period, uncloseable at any routing
   quality. The checks are now written as [consume_count <= body_size - position - bytes],
   with the wide arithmetic evaluated from registers and the window, and the late signal
   facing a single comparison.

   That is an algebraic rewrite, and an algebraic rewrite is exactly the kind of change
   that stays correct on ordinary traffic and fails on a boundary: an off-by-one in
   [room], a missing sign check, a width that wraps where the original did not. This suite
   asserts each rewritten predicate against a model of the bound written from the spec, in
   unbounded integers, on every cycle of realistic traffic - padded roots and entries, MBO
   groups, and schema versions 9 through 13.

   The second invariant is structural: no [headroom_*] cone may contain [consume_count].
   Restoring the [next_position + bytes] form would pass every behavioural test here and
   fail only in static timing analysis, so it is checked on the signal graph directly,
   with the general rule - no adder or subtractor may mix the consume decision with a
   multiply - checked alongside it.

   Tags: [{ "ACTIVE" ; "TEST" ; "INVARIANT" ; "MBP_DECODER" }]
*)

open! Core
open! Hardcaml
open Cme_of_hardcaml
module F = Schema_test_support.Schema_fixture
module T = Cme_types
module Stream = Stream_test_support.Stream_fixture
module Sim = Cyclesim.With_interface (Mbp_decoder.I) (Mbp_decoder.O)

(* [site, bytes] pairs. [fits_<site>] is the bound at the current position;
   [fits_after_consume_<site>] is the bound one consume later and also has a
   [headroom_<site>]. *)
let plain_sites = [ "dimensions", `Const 3; "entries", `Node "entries_bytes" ]
let plain_sites = plain_sites @ [ "orders", `Node "orders_bytes" ]

let consume_sites =
  [ "combined", "combined_entries_bytes"
  ; "prefetch_root", "prefetch_root_bytes"
  ; "prefetched_orders", "order_bytes_prefetched_orders"
  ; "live_orders", "order_bytes_live_orders"
  ]
;;

let traced =
  [ "position"; "consume_count"; "hdr_body_size"; "room"; "state" ]
  @ List.map plain_sites ~f:(fun (site, _) -> "fits_" ^ site)
  @ List.filter_map plain_sites ~f:(fun (_, bytes) ->
    match bytes with
    | `Const _ -> None
    | `Node name -> Some name)
  @ List.concat_map consume_sites ~f:(fun (site, bytes) ->
    [ "fits_after_consume_" ^ site; "headroom_" ^ site; bytes ])
;;

let create_sim () =
  let scope = Scope.create ~flatten_design:true () in
  let config =
    { Cyclesim.Config.default with
      is_internal_port =
        Some
          (fun s ->
            List.exists (Signal.names s) ~f:(fun n ->
              List.mem traced n ~equal:String.equal))
    }
  in
  Sim.create ~config (Mbp_decoder.create scope)
;;

let node sim name =
  match Cyclesim.lookup_node_or_reg_by_name sim name with
  | Some n -> n
  | None ->
    raise_s
      [%message
        "internal signal is not traced; a -- name was dropped or an expression was \
         rewritten away"
          (name : string)]
;;

let value sim name = Bits.to_int_trunc (Cyclesim.Node.to_bits (node sim name))
let flag sim name = value sim name = 1

(* Independent model of the bound, in unbounded integers, from the plan's statement of it:
   a group of [bytes] bytes starting [consumed] bytes after [position] fits when it ends
   at or before the end of the message body. Deliberately not the RTL's form. *)
let fits_model ~position ~body_size ~consumed ~bytes =
  position + consumed + bytes <= body_size
;;

let check_cycle ~case ~cycle sim =
  let position = value sim "position" in
  let body_size = value sim "hdr_body_size" in
  let consume_count = value sim "consume_count" in
  let fail site ~bytes ~consumed ~expected ~got =
    raise_s
      [%message
        "group-size bound diverged from the body-size limit it stands for"
          (case : string)
          (cycle : int)
          (site : string)
          (position : int)
          (body_size : int)
          (consumed : int)
          (bytes : int)
          (expected : bool)
          (got : bool)]
  in
  (* [room] is the only signed value here: [position] runs past the body while draining. *)
  let room = value sim "room" in
  let room = if room land (1 lsl 24) <> 0 then room - (1 lsl 25) else room in
  if room <> body_size - position
  then
    raise_s
      [%message
        "room is not the signed body space at the current position"
          (case : string)
          (cycle : int)
          (room : int)
          (position : int)
          (body_size : int)];
  List.iter plain_sites ~f:(fun (site, bytes) ->
    let bytes =
      match bytes with
      | `Const n -> n
      | `Node name -> value sim name
    in
    let expected = fits_model ~position ~body_size ~consumed:0 ~bytes in
    let got = flag sim ("fits_" ^ site) in
    if Bool.( <> ) expected got then fail site ~bytes ~consumed:0 ~expected ~got);
  List.iter consume_sites ~f:(fun (site, bytes_name) ->
    let bytes = value sim bytes_name in
    let expected = fits_model ~position ~body_size ~consumed:consume_count ~bytes in
    let got = flag sim ("fits_after_consume_" ^ site) in
    if Bool.( <> ) expected got
    then fail site ~bytes ~consumed:consume_count ~expected ~got);
  (* The rewrite drops the 16-bit wrap of the old [next_position]. That is only sound
     while the sum stays inside 16 bits, so assert the reachability claim rather than
     asserting it in a comment. *)
  if position + consume_count > 0xffff
  then
    raise_s
      [%message
        "position + consume_count left 16 bits; the rewritten bound no longer matches \
         the form it replaced"
          (case : string)
          (cycle : int)
          (position : int)
          (consume_count : int)]
;;

(* One message as the iterator would hand it over: context on the first beat, body bytes
   after the ten-byte SBE prefix, [last] on the final beat. *)
let items_of_message text =
  let int width = Bits.of_int_trunc ~width in
  let body = String.drop_prefix text 10 in
  Stream.packet body
  |> List.mapi ~f:(fun index beat ->
    T.Message_item.Of_bits.pack
      { (T.Message_item.Of_bits.zero ()) with
        kind =
          int
            2
            (if index = 0 then T.Message_item_kind.start else T.Message_item_kind.body)
      ; message =
          (if index <> 0
           then T.Message_context.Of_bits.zero ()
           else
             { (T.Message_context.Of_bits.zero ()) with
               msg_size = int 16 (String.length text)
             ; block_length = int 16 (Char.to_int text.[2] + (Char.to_int text.[3] * 256))
             ; template_id = int 16 46
             ; schema_id = int 16 1
             ; schema_version =
                 int 16 (Char.to_int text.[8] + (Char.to_int text.[9] * 256))
             ; message_header_present = Bits.vdd
             })
      ; beat =
          { data = beat.data
          ; keep = int 8 beat.keep
          ; first = Bits.of_bool beat.first
          ; last = Bits.of_bool beat.last
          }
      })
;;

(* The cycle is split so that the invariant is read at one instant: after
   [cycle_before_clock_edge] every combinational node is settled against the register
   values still standing, which is the pairing the invariant is about. Reading after a
   whole [Cyclesim.cycle] mixes post-edge registers with pre-edge combinational nodes,
   because the after-edge pass only refreshes what the outputs need. *)
let run_case ~case messages =
  let sim = create_sim () in
  let i = Cyclesim.inputs sim in
  let o = Cyclesim.outputs ~clock_edge:Before sim in
  i.reset_i := Bits.vdd;
  i.en_i := Bits.vdd;
  i.event_ready_i := Bits.vdd;
  i.done_ready_i := Bits.vdd;
  Cyclesim.cycle sim;
  i.reset_i := Bits.gnd;
  let todo = ref (List.concat_map messages ~f:items_of_message) in
  let cycle = ref 0 in
  let idle_streak = ref 0 in
  while (not (List.is_empty !todo)) || !idle_streak < 8 do
    (match !todo with
     | [] ->
       i.valid_i := Bits.gnd;
       i.item_i := Bits.zero T.message_item_width
     | item :: _ ->
       i.valid_i := Bits.vdd;
       i.item_i := item);
    Cyclesim.cycle_check sim;
    Cyclesim.cycle_before_clock_edge sim;
    check_cycle ~case ~cycle:!cycle sim;
    let accepted = Bits.to_bool !(o.ready_o) in
    Cyclesim.cycle_at_clock_edge sim;
    Cyclesim.cycle_after_clock_edge sim;
    (match !todo with
     | _ :: rest when accepted -> todo := rest
     | _ -> ());
    if List.is_empty !todo then incr idle_streak;
    incr cycle;
    if !cycle > 200_000 then failwith "decoder invariant trace did not drain"
  done
;;

let entries n =
  List.init n ~f:(fun index -> { F.default_entry with rpt_seq = Int64.of_int index })
;;

let cases =
  [ ( "ordinary"
    , List.init 8 ~f:(fun _ -> F.message ~match_event_indicator:0x80 (entries 3)) )
  ; ( "padded"
    , List.init 8 ~f:(fun index ->
        F.message
          ~root_block:(11 + (index mod 8))
          ~entry_block:(32 + ((index + 3) mod 8))
          ~match_event_indicator:0x80
          (entries 3)) )
  ; ( "mbo-groups"
    , List.init 8 ~f:(fun index ->
        F.message
          ~root_block:(11 + (index mod 8))
          ~entry_block:(32 + ((index + 3) mod 8))
          ~order_count:3
          ~order_block:24
          ~match_event_indicator:0x80
          (entries 3)) )
  ; ( "large-extensions"
    , List.init 8 ~f:(fun index ->
        F.message
          ~root_block:(43 + (index mod 8))
          ~entry_block:(96 + ((index + 3) mod 8))
          ~order_count:2
          ~order_block:40
          ~match_event_indicator:0x80
          (entries 3)) )
  ; "zero-entry", List.init 8 ~f:(fun _ -> F.message ~match_event_indicator:0x80 [])
  ; "dense-entries", [ F.message ~match_event_indicator:0x80 (entries 255) ]
  ]
  @ List.map [ 9; 10; 11; 12; 13 ] ~f:(fun version ->
    ( Printf.sprintf "version-%d" version
    , List.init 8 ~f:(fun index ->
        F.message
          ~version
          ~root_block:(11 + (index mod 8))
          ~entry_block:(32 + ((index + 3) mod 8))
          ~match_event_indicator:0x80
          (entries 3)) ))
;;

let%test_unit "group-size bounds equal the body-size limit on every cycle" =
  List.iter cases ~f:(fun (case, messages) -> run_case ~case messages)
;;

(* Malformed dimensions are where the bound decides, so they get their own pass: a group
   whose declared size runs off the end of the body must be rejected, and the rewritten
   comparison is the thing that rejects it. *)
let%test_unit "group-size bounds hold when declared sizes overrun the body" =
  let truncated =
    List.init 24 ~f:(fun index ->
      let text = F.message ~match_event_indicator:0x80 (entries 3) in
      (* Shrink the declared MsgSize so the entry group no longer fits. *)
      let size = String.length text - (index * 3) in
      let size = Int.max 13 size in
      String.init (String.length text) ~f:(fun n ->
        match n with
        | 0 -> Char.of_int_exn (size land 0xff)
        | 1 -> Char.of_int_exn ((size lsr 8) land 0xff)
        | _ -> text.[n]))
  in
  run_case ~case:"truncated-msgsize" truncated
;;

module Deps = Signal_graph.Deps_for_loop_checking

let decoder_circuit () =
  let module C = Circuit.With_interface (Mbp_decoder.I) (Mbp_decoder.O) in
  C.create_exn
    ~name:"cme_mbp_decoder"
    (Mbp_decoder.create (Scope.create ~flatten_design:true ()))
;;

let named signal name = List.mem (Signal.names signal) name ~equal:String.equal
let is_consume_count signal = named signal "consume_count"

let is_multiply signal =
  match (signal : Signal.t) with
  | Op2 { op = Mulu; _ } | Op2 { op = Muls; _ } -> true
  | _ -> false
;;

let is_add_or_sub signal =
  match (signal : Signal.t) with
  | Op2 { op = Add; _ } | Op2 { op = Sub; _ } -> true
  | _ -> false
;;

(* Memoized combinational cone summary. Deps_for_loop_checking cuts at registers, so this
   is the logic between two flops and the recursion terminates. *)
let cone_summary circuit =
  let table = Hashtbl.create (module Signal.Type.Uid) in
  let rec go signal =
    let uid = Signal.uid signal in
    match Hashtbl.find table uid with
    | Some v -> v
    | None ->
      let self = is_consume_count signal, is_multiply signal in
      Hashtbl.set table ~key:uid ~data:self;
      let has_consume, has_multiply =
        List.fold (Deps.to_list signal) ~init:self ~f:(fun (c, m) dep ->
          let dc, dm = go dep in
          c || dc, m || dm)
      in
      Hashtbl.set table ~key:uid ~data:(has_consume, has_multiply);
      has_consume, has_multiply
  in
  Signal_graph.iter (Circuit.signal_graph circuit) ~f:(fun s ->
    ignore (go s : bool * bool));
  fun signal -> go signal
;;

let%test_unit "the consume decision never meets a multiply in an adder" =
  let circuit = decoder_circuit () in
  let summary = cone_summary circuit in
  let offenders = ref [] in
  let saw_consume_adder = ref false
  and saw_multiply_adder = ref false in
  Signal_graph.iter (Circuit.signal_graph circuit) ~f:(fun signal ->
    if is_add_or_sub signal
    then (
      let has_consume, has_multiply = summary signal in
      if has_consume then saw_consume_adder := true;
      if has_multiply then saw_multiply_adder := true;
      if has_consume && has_multiply then offenders := signal :: !offenders));
  if not (List.is_empty !offenders)
  then
    raise_s
      [%message
        "an adder mixes the consume decision with a group-size multiply; the sum folds \
         into the multiplier's DSP and puts it in series with consume_count"
          ~offenders:(!offenders : Signal.t list)];
  (* Negative controls: both halves of the forbidden combination exist on their own, so an
     empty offender list means the traversal works rather than that it found nothing. *)
  assert !saw_consume_adder;
  assert !saw_multiply_adder
;;

let%test_unit "no headroom cone contains the consume decision" =
  let circuit = decoder_circuit () in
  let find name =
    let found = ref None in
    Signal_graph.iter (Circuit.signal_graph circuit) ~f:(fun s ->
      if named s name then found := Some s);
    match !found with
    | Some s -> s
    | None -> raise_s [%message "named signal is gone from the decoder" (name : string)]
  in
  let reaches_consume signal =
    not
      (List.is_empty
         (Signal_graph.filter
            ~deps:(module Deps)
            (Signal_graph.create [ signal ])
            ~f:is_consume_count))
  in
  List.iter consume_sites ~f:(fun (site, _) ->
    if reaches_consume (find ("headroom_" ^ site))
    then
      raise_s
        [%message
          "headroom depends on this cycle's consume decision; the wide arithmetic must \
           be evaluated from registers and the aligner window alone"
            (site : string)];
    (* Negative control: the predicate built on that headroom does read consume_count. *)
    assert (reaches_consume (find ("fits_after_consume_" ^ site))))
;;
