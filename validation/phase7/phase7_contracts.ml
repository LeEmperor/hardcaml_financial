(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "phase7_contracts.ml" *)
(* Verify the external Verilog event ABI and Python sender fixtures with the XML oracle.

   Two sequences are checked, because the sender transmits two different ones. The MII
   vector set ends with the two error frames, which advance the sequencer; the board run
   omits them -- a NIC always emits a valid FCS -- and continues into the MTU-scale cases
   instead. Each sequence therefore gets its own golden decoder, so the expected counters
   are checked in the sequence context the board actually sees. *)

open! Core
open! Hardcaml
module T = Cme_of_hardcaml.Cme_types
module G = Cme_schema.Golden_decoder

type case =
  { name : string
  ; (* Reaches the parser. Traffic on a filtered destination port never does, so the
       oracle must not advance its sequencer for it either. *)
    selected : bool
  ; (* Payload is a whole number of 8-byte beats, so the final beat is full. Every case
       but one ends on a partial tail: a packet header is 12 bytes and an unpadded message
       is a multiple of 8, so only root padding can reach a full beat. *)
    full_beat : bool
  ; (* Running (updates, end_of_event, diagnostics, sequence_gaps, duplicates). *)
    expected : int * int * int * int * int
  }

let case ?(selected = true) ?(full_beat = false) name expected =
  { name; selected; full_beat; expected }
;;

(* The MII vector set, in the order write_vectors emits it. *)
let mii_vector_cases =
  [ case "single_partial_tail" (1, 1, 0, 0, 0)
  ; case "multiple_messages" (4, 3, 0, 0, 0)
  ; case "sequence_gap" (5, 4, 1, 1, 0)
  ; case "duplicate" (5, 4, 2, 1, 1)
  ; case "after_duplicate" (6, 5, 2, 1, 1)
  ; case "filtered_port" ~selected:false (6, 5, 2, 1, 1)
  ; case "after_filtered" (7, 6, 2, 1, 1)
  ; case "late_bad_fcs" (8, 7, 2, 1, 1)
  ; case "bad_ip_checksum" (9, 8, 2, 1, 1)
  ]
;;

(* What board_acceptance.run_cases() transmits: the base sequence without the error
   frames, then the MTU-scale cases. *)
let board_run_cases =
  [ case "single_partial_tail" (1, 1, 0, 0, 0)
  ; case "multiple_messages" (4, 3, 0, 0, 0)
  ; case "sequence_gap" (5, 4, 1, 1, 0)
  ; case "duplicate" (5, 4, 2, 1, 1)
  ; case "after_duplicate" (6, 5, 2, 1, 1)
  ; case "filtered_port" ~selected:false (6, 5, 2, 1, 1)
  ; case "after_filtered" (7, 6, 2, 1, 1)
  ; case "mtu_deep_group" (51, 7, 2, 1, 1)
  ; case "mtu_many_messages" (73, 29, 2, 1, 1)
  ; case "mtu_single_event" (105, 30, 2, 1, 1)
  ; case "mtu_full_final_beat" ~full_beat:true (149, 31, 2, 1, 1)
  ; case "mtu_sequence_gap" (193, 32, 3, 2, 1)
  ; case "mtu_duplicate" (193, 32, 4, 2, 2)
  ; case "mtu_after_duplicate" (237, 33, 4, 2, 2)
  ]
;;

let check_sequence ~directory ~schema_file ~label cases =
  let golden = G.create ~schema_file in
  let updates, ends, diagnostics, gaps, duplicates = ref 0, ref 0, ref 0, ref 0, ref 0 in
  List.iter cases ~f:(fun { name; selected; full_beat; expected } ->
    let payload = In_channel.read_all (Filename.concat directory (name ^ ".bin")) in
    [%test_result: bool] ~message:name (String.length payload % 8 = 0) ~expect:full_beat;
    if selected
    then
      List.iter (G.decode_payload golden payload) ~f:(function
        | G.Mbp_update update ->
          incr updates;
          assert (Int64.equal update.security_id 1234L);
          assert (Option.equal Int64.equal update.price_mantissa (Some (-123L)));
          assert (Int64.equal update.packet.ingress_timestamp 0L)
        | G.End_of_event _ -> incr ends
        | G.Diagnostic diagnostic ->
          incr diagnostics;
          (match diagnostic.code with
           | G.Diagnostic_code.Sequence_gap -> incr gaps
           | G.Diagnostic_code.Duplicate_or_late -> incr duplicates
           | _ -> failwith "unexpected fixture diagnostic"));
    let actual = !updates, !ends, !diagnostics, !gaps, !duplicates in
    [%test_eq: int * int * int * int * int] ~message:name actual expected);
  printf "PASS %s: %d payloads against XML oracle\n" label (List.length cases)
;;

let () =
  let directory, schema_file =
    match Array.to_list (Sys.get_argv ()) with
    | [ _; directory; schema_file ] -> directory, schema_file
    | _ -> failwith "usage: phase7_contracts.exe VECTOR_DIR SCHEMA_XML"
  in
  assert (T.Event.width = 677);
  assert (T.Event_kind.mbp_update = 0);
  assert (T.Event_kind.end_of_event = 1);
  assert (T.Event_kind.diagnostic = 2);
  assert (T.Diagnostic_code.sequence_gap = 1);
  assert (T.Diagnostic_code.duplicate_or_late = 2);
  let empty = T.Event.map T.Event.port_widths ~f:Bits.zero in
  let encoded =
    T.Event.Of_bits.pack { empty with kind = Bits.ones 2; diagnostic_code = Bits.ones 8 }
  in
  assert (Bits.to_int_trunc (Bits.select encoded ~high:1 ~low:0) = 3);
  assert (Bits.to_int_trunc (Bits.select encoded ~high:627 ~low:620) = 255);
  check_sequence ~directory ~schema_file ~label:"MII vector sequence" mii_vector_cases;
  check_sequence ~directory ~schema_file ~label:"board run sequence" board_run_cases;
  print_endline "PASS Phase 7 event ABI and both sender sequences against XML oracle"
;;
