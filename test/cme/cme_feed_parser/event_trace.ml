(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "event_trace.ml" *)
(* Readable normalized-event history. Every event below is what the RTL actually emitted,
   checked bit-for-bit against the independent XML oracle as it was recorded, and grouped
   by the packet that produced it. This is evidence for a reader, not a gate: the
   enforcing bounds live in @performance-check and the differential suites. *)

open! Core
open Cme_feed_parser_testbench
open F

(* Presentation only; the decoder validates these against the schema's enums. *)
let action_name = function
  | 0 -> "New"
  | 1 -> "Change"
  | 2 -> "Delete"
  | 3 -> "DeleteThru"
  | 4 -> "DeleteFrom"
  | 5 -> "Overlay"
  | n -> sprintf "action:%d" n
;;

let entry_type_name value =
  match Char.of_int_exn value with
  | '0' -> "Bid"
  | '1' -> "Offer"
  | '2' -> "Trade"
  | 'E' -> "ImpliedBid"
  | 'F' -> "ImpliedOffer"
  | 'J' -> "BookReset"
  | 'x' -> "MarketBestBid"
  | 'w' -> "MarketBestOffer"
  | c -> sprintf "type:%c" c
;;

let diagnostic_name = function
  | G.Diagnostic_code.Sequence_gap -> "sequence_gap"
  | Duplicate_or_late -> "duplicate_or_late"
  | Truncated_packet_header -> "truncated_packet_header"
  | Invalid_message_size -> "invalid_message_size"
  | Message_beyond_packet -> "message_beyond_packet"
  | Unsupported_template -> "unsupported_template"
  | Schema_incompatibility -> "schema_incompatibility"
  | Invalid_enum -> "invalid_enum"
;;

(* Schema exponent is a constant -9. Rendered as exact fixed point; the data path carries
   the mantissa and never sees a float. *)
let fixed9 mantissa =
  let negative = Int64.is_negative mantissa in
  let magnitude = Int64.abs mantissa in
  let billion = 1_000_000_000L in
  sprintf
    "%s%Ld.%09Ld"
    (if negative then "-" else "")
    Int64.(magnitude / billion)
    Int64.(rem magnitude billion)
;;

let optional f = Option.value_map ~default:"null" ~f

(* Packets are fed in order, so consecutive events sharing a sequence number and an
   ingress timestamp came from the same packet. The timestamp separates a duplicate packet
   from the original it repeats. *)
let group_events events cycles =
  let key (event : G.event) =
    let p =
      match event with
      | G.Mbp_update u -> u.packet
      | End_of_event e -> e.packet
      | Diagnostic d -> d.packet
    in
    p.packet_seq, p.ingress_timestamp
  in
  List.zip_exn events cycles
  |> List.group ~break:(fun (a, _) (b, _) ->
    not ([%equal: int64 * int64] (key a) (key b)))
;;

(* Accept window per fed packet, so a group header can show input and output side by side.
   Only joined when every fed packet produced at least one event. *)
let accept_windows (beats : Observation.accepted_beat list) =
  List.group beats ~break:(fun a b -> a.packet_index <> b.packet_index)
  |> List.map ~f:(fun beats -> (List.hd_exn beats).cycle, (List.last_exn beats).cycle)
;;

let print_event cycle previous event =
  let delta =
    match previous with
    | None -> "     "
    | Some p -> sprintf "%+5d" (cycle - p)
  in
  match (event : G.event) with
  | G.Mbp_update u ->
    printf
      "  cyc %6d %s  update         sec=%-10Ld rpt=%-8Ld lvl=%-3d %-10s %-15s px=%-22s \
       size=%-8s ord=%-6s entry %d/%d%s\n"
      cycle
      delta
      u.security_id
      u.rpt_seq
      u.price_level
      (action_name u.update_action)
      (entry_type_name u.entry_type)
      (optional fixed9 u.price_mantissa)
      (optional Int64.to_string u.entry_size)
      (optional Int64.to_string u.number_of_orders)
      u.entry_index
      u.entry_count
      (if u.message_last then "  [last of message]" else "")
  | End_of_event e ->
    printf
      "  cyc %6d %s  end-of-event   mei=0x%02x  transact=%Ld  (book consistent; publish \
       here)\n"
      cycle
      delta
      e.match_event_indicator
      e.message.transaction_time
  | Diagnostic d ->
    printf
      "  cyc %6d %s  DIAGNOSTIC     %-24s offset=%-5d%s\n"
      cycle
      delta
      (diagnostic_name d.code)
      d.byte_offset
      (Option.value_map d.expected_seq ~default:"" ~f:(sprintf " expected_seq=%Ld"))
;;

let print_trace name (result : Observation.t) ~packets =
  let groups = group_events result.events result.event_cycles in
  let windows = accept_windows result.accepted_beats in
  let joinable = List.length groups = packets && List.length windows = packets in
  let updates =
    List.count result.events ~f:(function
      | G.Mbp_update _ -> true
      | _ -> false)
  and ends =
    List.count result.events ~f:(function
      | End_of_event _ -> true
      | _ -> false)
  and diagnostics =
    List.count result.events ~f:(function
      | Diagnostic _ -> true
      | _ -> false)
  in
  printf "\n════ %s ════\n" name;
  printf
    "%d packets in, %d beats accepted, %d events out (%d update, %d end-of-event, %d \
     diagnostic); %d cycles, %d input stalls\n"
    packets
    (List.length result.accepted_beats)
    (List.length result.events)
    updates
    ends
    diagnostics
    result.cycles
    result.input_stalls;
  let previous = ref None in
  List.iteri groups ~f:(fun index group ->
    let event, _ = List.hd_exn group in
    let p =
      match event with
      | G.Mbp_update u -> u.packet
      | End_of_event e -> e.packet
      | Diagnostic d -> d.packet
    in
    let window =
      if joinable
      then (
        let first, last = List.nth_exn windows index in
        sprintf "  in=cyc %d..%d" first last)
      else ""
    in
    printf
      "\npacket seq=%-8Ld ingress=%-20Ld sending=%-10Ld sequencing=%s%s\n"
      p.packet_seq
      p.ingress_timestamp
      p.sending_time
      (if p.channel_valid then "ok" else "BROKEN (sticky until reset/resync)")
      window;
    List.iter group ~f:(fun (event, cycle) ->
      print_event cycle !previous event;
      previous := Some cycle))
;;

let scenarios () =
  let entry ?(level = 1) ?(action = 0) ?(entry_type = '0') ?(rpt_seq = 1L) price size =
    { default_entry with
      price
    ; size
    ; level
    ; action
    ; entry_type
    ; rpt_seq
    ; security_id = 31415L
    }
  in
  [ ( "steady-book"
    , "Ordinary in-sequence traffic: two-sided depth updates across four packets."
    , [ packet
          100L
          [ message
              ~match_event_indicator:0x80
              [ entry ~level:1 ~action:0 ~entry_type:'0' ~rpt_seq:1L 4_512_250_000_000L 7L
              ; entry ~level:1 ~action:0 ~entry_type:'1' ~rpt_seq:2L 4_512_500_000_000L 4L
              ]
          ]
      ; packet
          101L
          [ message
              ~match_event_indicator:0x80
              [ entry
                  ~level:2
                  ~action:0
                  ~entry_type:'0'
                  ~rpt_seq:3L
                  4_512_000_000_000L
                  12L
              ; entry ~level:1 ~action:1 ~entry_type:'1' ~rpt_seq:4L 4_512_500_000_000L 9L
              ]
          ]
      ; packet
          102L
          [ message
              ~match_event_indicator:0x80
              [ entry ~level:1 ~action:2 ~entry_type:'0' ~rpt_seq:5L 4_512_250_000_000L 0L
              ; entry ~level:1 ~action:5 ~entry_type:'x' ~rpt_seq:6L 4_512_750_000_000L 1L
              ]
          ]
      ; packet
          103L
          [ message
              ~match_event_indicator:0x80
              [ entry ~level:3 ~action:4 ~entry_type:'1' ~rpt_seq:7L 4_513_000_000_000L 5L
              ]
          ]
      ]
    , [] )
  ; ( "multi-message-packet"
    , "Three messages in one datagram, including a zero-entry message that is only a \
       match-event boundary."
    , [ packet
          200L
          [ message [ entry ~level:1 ~action:0 ~rpt_seq:10L 900_000_000_000L 3L ]
          ; message []
          ; message
              ~match_event_indicator:0x80
              [ entry ~level:1 ~action:1 ~entry_type:'1' ~rpt_seq:11L 901_000_000_000L 8L
              ; entry ~level:2 ~action:0 ~entry_type:'1' ~rpt_seq:12L 902_000_000_000L 6L
              ; entry ~level:3 ~action:0 ~entry_type:'1' ~rpt_seq:13L 903_000_000_000L 2L
              ]
          ]
      ]
    , [] )
  ; ( "gap-duplicate-recovery"
    , "A dropped packet and a repeat of one already seen. Note that channel_valid stays \
       false for every later packet: only a session reset or an explicit resync clears \
       it, so a book builder knows its state is untrustworthy until it recovers."
    , [ packet 300L [ message ~match_event_indicator:0x80 [ default_entry ] ]
      ; packet 302L [ message ~match_event_indicator:0x80 [ default_entry ] ]
      ; packet 302L [ message ~match_event_indicator:0x80 [ default_entry ] ]
      ; packet 303L [ message ~match_event_indicator:0x80 [ default_entry ] ]
      ]
    , [] )
  ; ( "session-reset-and-resync"
    , "Out-of-band control: a session reset, then an explicit resynchronization to a \
       known sequence."
    , [ packet 400L [ message ~match_event_indicator:0x80 [ default_entry ] ]
      ; packet 900L [ message ~match_event_indicator:0x80 [ default_entry ] ]
      ; packet 901L [ message ~match_event_indicator:0x80 [ default_entry ] ]
      ]
    , [ { after_packets = 1; session_reset = true; resync = None }
      ; { after_packets = 2; session_reset = false; resync = Some 901L }
      ] )
  ; ( "malformed-and-recovery"
    , "Unsupported template, incompatible schema, and a declared size that runs past the \
       datagram; alignment is regained for the next good packet."
    , [ packet 500L [ message ~template:32 [] ]
      ; packet 501L [ message ~schema:2 [] ]
      ; packet 502L [ raw_message ~declared_size:400 "\000\000\000\000" ]
      ; packet 503L [ message ~match_event_indicator:0x80 [ default_entry ] ]
      ]
    , [] )
  ]
;;

let rec find_schema directory depth =
  let candidate = Filename.concat directory "docs/templates.xml" in
  if Sys_unix.file_exists_exn candidate
  then Some candidate
  else if depth = 0
  then None
  else find_schema (Filename.concat directory Filename.parent_dir_name) (depth - 1)
;;

let usage () =
  printf
    "usage: event_trace.exe [--pcap FILE] [--limit N] [--sexp]\n\n\
    \  --pcap FILE  replay UDP payloads from a classic-PCAP capture instead of the\n\
    \               synthetic scenarios, using the capture's own timestamps\n\
    \  --limit N    replay at most N payloads from the capture (default 32)\n\
    \  --sexp       also dump the full machine-readable observation per scenario\n";
  exit 1
;;

let () =
  let arguments = Array.to_list (Sys.get_argv ()) |> List.tl_exn in
  let sexp = List.mem arguments "--sexp" ~equal:String.equal in
  let value flag =
    List.findi arguments ~f:(fun _ a -> String.equal a flag)
    |> Option.map ~f:(fun (index, _) ->
      match List.nth arguments (index + 1) with
      | Some v -> v
      | None -> usage ())
  in
  let capture = value "--pcap" in
  let limit = value "--limit" |> Option.value_map ~default:32 ~f:Int.of_string in
  if List.exists arguments ~f:(fun a ->
       String.is_prefix a ~prefix:"--"
       && not (List.mem [ "--pcap"; "--limit"; "--sexp" ] a ~equal:String.equal))
  then usage ();
  let schema_file =
    match find_schema Filename.current_dir_name 8 with
    | Some path -> path
    | None ->
      failwith
        "cannot locate docs/templates.xml; run from inside the repository or through the \
         @event-trace alias"
  in
  printf
    "CME MDP 3.0 feed parser — normalized event trace\n\
     schema: %s\n\
     Every event was compared bit-for-bit with the independent XML oracle as it was \
     emitted.\n\
     Cycles are simulation cycles with the sink always ready; per-entry latency bounds \
     are enforced by @performance-check.\n"
    schema_file;
  let show name description payloads controls timestamp =
    printf "\n%s\n" description;
    let result =
      run ~stalls:false ~check_model:true ~schema_file ~timestamp ~controls payloads
    in
    print_trace name result ~packets:(List.length payloads);
    if sexp then printf "\n%s\n" (Sexp.to_string_hum [%sexp (result : Observation.t)])
  in
  match capture with
  | None ->
    List.iter (scenarios ()) ~f:(fun (name, description, payloads, controls) ->
      show name description payloads controls (fun index ->
        let ordinal = Int64.of_int (index + 1) in
        Int64.((0x0000_1000_0000_0000L * ordinal) + 0x2a2aL)))
  | Some file ->
    let payloads =
      Cme_schema.Pcap_payloads.load file
      |> List.filter ~f:(fun p -> not (String.is_empty p.bytes))
      |> fun all -> List.take all limit
    in
    if List.is_empty payloads
    then failwith (sprintf "%s contained no non-empty IPv4/UDP payloads" file);
    let timestamps =
      List.map payloads ~f:(fun p -> p.ingress_timestamp) |> Array.of_list
    in
    show
      "pcap-replay"
      (sprintf
         "Replay of %d UDP payload(s) from %s, with the capture's own ingress timestamps."
         (List.length payloads)
         file)
      (List.map payloads ~f:(fun p -> p.bytes))
      []
      (fun index -> timestamps.(index))
;;
