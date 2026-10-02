(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "phase6_performance.ml" *)
(* Always-ready system performance evidence through the same Step fixture and XML
   scoreboard as conformance. --check enforces, rather than blesses, the plan's bounds. *)

open! Core
open Cme_feed_parser_testbench
open F

type probe =
  { packet_index : int
  ; message_offset : int
  ; entry_index : int
  ; required_byte : int
  }

let traffic
  ?(version = 13)
  ?(root_extension = 0)
  ?(entry_extension = 0)
  ?(order_count = 0)
  ?(order_block = 24)
  ~packets
  ~messages
  ~entries
  ~padding
  ()
  =
  let probes = ref [] in
  let payloads =
    List.init packets ~f:(fun packet_index ->
      let offset = ref 12 in
      let bodies =
        List.init messages ~f:(fun message_index ->
          let root_block =
            11 + root_extension + if padding then message_index mod 8 else 0
          in
          let entry_block =
            32 + entry_extension + if padding then (message_index + 3) mod 8 else 0
          in
          let body =
            message
              ~version
              ~order_count
              ~order_block
              ~root_block
              ~entry_block
              ~match_event_indicator:0x80
              (List.init entries ~f:(fun index ->
                 { default_entry with rpt_seq = Int64.of_int index }))
          in
          body)
      in
      List.iteri bodies ~f:(fun message_index body ->
        let root_block =
          11 + root_extension + if padding then message_index mod 8 else 0
        in
        let entry_block =
          32 + entry_extension + if padding then (message_index + 3) mod 8 else 0
        in
        List.iter (List.init entries ~f:Fn.id) ~f:(fun entry_index ->
          probes
          := { packet_index
             ; message_offset = !offset
             ; entry_index
               (* Template 46: the last semantic byte is 26 in version 9 and 30 in
                  versions 10–13. Reserved bytes and extensions never move the origin. *)
             ; required_byte =
                 (!offset
                  + 10
                  + root_block
                  + 3
                  + (entry_index * entry_block)
                  + if version >= 10 then 30 else 26)
             }
             :: !probes);
        offset := !offset + String.length body);
      packet (Int64.of_int (packet_index + 1)) bodies)
  in
  payloads, List.rev !probes
;;

let measure name payloads probes =
  let trace =
    String.equal name "padded-alignments"
    && Array.exists (Sys.get_argv ()) ~f:(String.equal "--trace")
  in
  let result = run ~stalls:false ~trace payloads in
  let accepts = Hashtbl.Poly.create () in
  List.iter result.accepted_beats ~f:(fun beat ->
    for byte = beat.first_byte to beat.first_byte + beat.byte_count - 1 do
      Hashtbl.set accepts ~key:(beat.packet_index, byte) ~data:beat.cycle
    done);
  let events = Hashtbl.Poly.create () in
  List.iter2_exn result.events result.event_cycles ~f:(fun event cycle ->
    match event with
    | G.Mbp_update update ->
      let packet_index = Int64.to_int_exn update.packet.packet_seq - 1 in
      Hashtbl.add_exn
        events
        ~key:(packet_index, update.message.packet_byte_offset, update.entry_index)
        ~data:cycle
    | _ -> ());
  assert (Hashtbl.length events = List.length probes);
  let latencies =
    List.map probes ~f:(fun probe ->
      let accepted = Hashtbl.find_exn accepts (probe.packet_index, probe.required_byte) in
      let emitted =
        Hashtbl.find_exn
          events
          (probe.packet_index, probe.message_offset, probe.entry_index)
      in
      if String.equal name "padded-alignments"
         && probe.packet_index < 2
         && Array.exists (Sys.get_argv ()) ~f:(String.equal "--detail")
      then
        printf
          "packet=%d message_offset=%d entry=%d accepted=%d emitted=%d latency=%d\n"
          probe.packet_index
          probe.message_offset
          probe.entry_index
          accepted
          emitted
          (emitted - accepted);
      assert (emitted >= accepted);
      emitted - accepted)
  in
  let minimum = List.min_elt latencies ~compare:Int.compare |> Option.value ~default:0 in
  let maximum = List.max_elt latencies ~compare:Int.compare |> Option.value ~default:0 in
  let over_bound = List.count latencies ~f:(fun cycles -> cycles > 8) in
  let beats = List.length result.accepted_beats in
  let span =
    (List.last_exn result.accepted_beats).cycle
    - (List.hd_exn result.accepted_beats).cycle
    + 1
  in
  assert (span = beats + result.input_stalls);
  printf
    "%s: packets=%d beats=%d events=%d input_stalls=%d offered_span=%d cycles=%d \
     latency_min=%d latency_max=%d over_8=%d/%d\n\
     %!"
    name
    (List.length payloads)
    beats
    (List.length result.events)
    result.input_stalls
    span
    result.cycles
    minimum
    maximum
    over_bound
    (List.length probes);
  result.input_stalls = 0 && over_bound = 0
;;

let () =
  let cases =
    [ "single-entry", 1, 1, 1, false
    ; "dense-entries", 16, 1, 255, false
    ; "small-packets", 128, 1, 1, false
    ; "zero-entry-packets", 128, 1, 0, false
    ; "many-messages", 16, 16, 1, false
    ; "padded-alignments", 16, 8, 3, true
    ; "padded-sustained", 128, 8, 3, true
    ; "zero-entry-many-messages", 128, 16, 0, false
    ]
  in
  let ordinary =
    List.map cases ~f:(fun (name, packets, messages, entries, padding) ->
      let payloads, probes = traffic ~packets ~messages ~entries ~padding () in
      measure name payloads probes)
  in
  let extended =
    List.map
      [ "mbo-groups", 13, 0, 0, 3, 24
      ; "large-extensions", 13, 32, 64, 2, 40
      ; "version-9", 9, 0, 0, 0, 24
      ; "version-10", 10, 0, 0, 0, 24
      ; "version-11", 11, 0, 0, 0, 24
      ; "version-12", 12, 0, 0, 0, 24
      ]
      ~f:
        (fun
          (name, version, root_extension, entry_extension, order_count, order_block) ->
        let payloads, probes =
          traffic
            ~version
            ~root_extension
            ~entry_extension
            ~order_count
            ~order_block
            ~packets:128
            ~messages:8
            ~entries:3
            ~padding:true
            ()
        in
        measure name payloads probes)
  in
  let passed = List.for_all (ordinary @ extended) ~f:Fn.id in
  printf
    "Performance acceptance: %s (one beat/cycle; entry latency <= 8 cycles; clock target \
     156.25 MHz, simulation only)\n\
     %!"
    (if passed then "PASS" else "FAIL");
  if Array.exists (Sys.get_argv ()) ~f:(String.equal "--check") && not passed
  then
    failwith
      "Phase 6 performance acceptance failed; see measured stalls and latency above"
;;
