(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "cme_feed_parser_unit_quickcheck_tests.ml" *)
(* Phase 5 deterministic conformance against the XML oracle, with seeded schedules. *)

open! Core
open Cme_feed_parser_testbench
open F

let updates events =
  List.filter_map events ~f:(function
    | G.Mbp_update u -> Some u
    | _ -> None)
;;

let verify payloads = ignore (run payloads : Observation.t)

let%test_unit "all supported update action and entry type combinations" =
  let entries =
    List.concat_map [ 0; 1; 2; 3; 4; 5 ] ~f:(fun action ->
      List.map [ '0'; '1'; 'E'; 'F'; 'J'; 'w'; 'x' ] ~f:(fun entry_type ->
        { default_entry with action; entry_type }))
  in
  let result = run [ packet 1L [ message ~match_event_indicator:0xff entries ] ] in
  [%test_result: int] (List.length result.events) ~expect:43
;;

let%test_unit "signed minima, maxima, all nulls, and asymmetric 64-bit context" =
  let nulls =
    { default_entry with
      price = Int64.max_value
    ; size = 0x7fff_ffffL
    ; orders = 0x7fff_ffffL
    ; tradeable = 0x7fff_ffffL
    }
  in
  let low =
    { default_entry with
      price = Int64.min_value
    ; size = -0x8000_0000L
    ; security_id = -0x8000_0000L
    ; rpt_seq = 0xffff_ffffL
    ; orders = -0x8000_0000L
    ; tradeable = -0x8000_0000L
    ; level = 255
    }
  in
  let high =
    { default_entry with
      price = Int64.(max_value - 1L)
    ; size = 0x7fff_fffeL
    ; security_id = 0x7fff_ffffL
    ; orders = 0x7fff_fffeL
    ; tradeable = 0x7fff_fffeL
    }
  in
  verify
    [ packet
        ~sending_time:0x8877_6655_4433_2211L
        0xffff_ffffL
        [ message
            ~transact_time:0x9876_5432_10fe_dcbaL
            ~match_event_indicator:0x80
            [ nulls; low; high ]
        ]
    ]
;;

let%test_unit "zero entries, empty packets, and explicit end-of-event" =
  verify
    [ packet 1L []
    ; packet
        2L
        [ message []
        ; message ~match_event_indicator:0x80 []
        ; message [ default_entry ]
        ; message ~match_event_indicator:0x80 [ default_entry ]
        ]
    ]
;;

let%test_unit "every message alignment and appended root, entry and MBO padding" =
  let payloads =
    List.init 8 ~f:(fun pad ->
      packet
        (Int64.of_int (pad + 1))
        [ message ~template:99 ~root_block:(11 + pad) []
        ; message
            ~root_block:(11 + pad)
            ~entry_block:(32 + pad)
            ~order_block:(24 + pad)
            ~order_count:3
            ~match_event_indicator:0x80
            [ default_entry; { default_entry with rpt_seq = 8L } ]
        ; message ~match_event_indicator:0x80 []
        ])
  in
  ignore (Small.run payloads : Observation.t)
;;

let%test_unit "versions gate optional fields and enum additions; future schema warns and \
               decodes"
  =
  verify
    (List.init 7 ~f:(fun index ->
       let version = 8 + index in
       packet
         (Int64.of_int (index + 1))
         [ message ~version ~root_block:19 ~entry_block:40 [ default_entry ]
         ; message ~version [ { default_entry with entry_type = 'w' } ]
         ; message ~version [ { default_entry with entry_type = 'x' } ]
         ; message ~match_event_indicator:0x80 []
         ]))
;;

let%test_unit "schema rejection and invalid enums preserve later messages" =
  let bad =
    [ message ~schema:2 [ default_entry ]
    ; message ~root_block:8 [ default_entry ]
    ; message ~entry_block:31 [ default_entry ]
    ; message ~order_block:23 ~order_count:1 [ default_entry ]
    ; message [ default_entry; { default_entry with action = 6 }; default_entry ]
    ; message [ { default_entry with entry_type = '?' } ]
    ; raw_message ~declared_size:10 ""
    ]
  in
  verify
    (List.mapi bad ~f:(fun index bad ->
       packet
         (Int64.of_int (index + 1))
         [ bad; message ~match_event_indicator:0x80 [ default_entry ] ]))
;;

let resize_message m length =
  let m = String.prefix m length |> Bytes.of_string in
  set_le m 0 2 (Int64.of_int length);
  Bytes.to_string m
;;

let%test_unit "dimension arithmetic rejects oversized products and accepts maximum entry \
               count"
  =
  let mutate m offset width value =
    let bytes = Bytes.of_string m in
    set_le bytes offset width value;
    Bytes.to_string bytes
  in
  let m = message [ default_entry ] in
  let bad =
    [ mutate m 2 2 65535L
    ; mutate (mutate m 21 2 65535L) 23 1 255L
    ; mutate (mutate m 56 2 65535L) 63 1 255L
    ; mutate m 21 2 0L
    ; mutate m 56 2 0L
    ]
  in
  verify
    (List.mapi bad ~f:(fun index bad ->
       packet (Int64.of_int (index + 1)) [ bad; message [] ]));
  let entries =
    List.init 255 ~f:(fun index -> { default_entry with rpt_seq = Int64.of_int index })
  in
  let result = Small.run [ packet 1L [ message ~match_event_indicator:0x80 entries ] ] in
  [%test_result: int] (List.length result.events) ~expect:256
;;

let%test_unit "compatible message tails are skipped before the next prefix" =
  let original = message ~match_event_indicator:0x80 [ default_entry ] in
  verify
    (List.init 8 ~f:(fun pad ->
       let bytes = Bytes.of_string (original ^ String.make (pad + 1) '\xa5') in
       set_le bytes 0 2 (Int64.of_int (Bytes.length bytes));
       packet
         (Int64.of_int (pad + 1))
         [ Bytes.to_string bytes; message ~match_event_indicator:0x80 [] ]))
;;

let%test_unit "trustworthy message bounds reject short dimensions and groups" =
  let m =
    message ~order_count:2 ~match_event_indicator:0x80 [ default_entry; default_entry ]
  in
  let lengths =
    [ 10
    ; 11
    ; 17
    ; 20
    ; 21
    ; 22
    ; 23
    ; 24
    ; 25
    ; 55
    ; 56
    ; 87
    ; 88
    ; 89
    ; 90
    ; 94
    ; 95
    ; 96
    ; 97
    ; 110
    ; 140
    ; 143
    ]
  in
  verify
    (List.mapi lengths ~f:(fun index length ->
       packet
         (Int64.of_int (index + 1))
         [ resize_message m length; message ~match_event_indicator:0x80 [] ]))
;;

let%test_unit "sequence gaps, duplicate drops, wrap and packet header diagnostics" =
  let m = message ~match_event_indicator:0x80 [ default_entry ] in
  verify
    [ packet 0xffff_fffeL [ m ]
    ; packet 0xffff_ffffL [ m ]
    ; packet 0L [ m ]
    ; packet 2L [ m ]
    ; packet 2L [ m ]
    ; packet 1L [ m ]
    ; packet 3L [ m ]
    ];
  List.iter
    (List.init 11 ~f:(fun n -> n + 1))
    ~f:(fun n -> verify [ String.make n '\x5a'; packet 1L [ m ] ])
;;

let%test_unit "structural diagnostics stay ordered with schema errors and updates" =
  verify
    [ packet
        1L
        [ message ~template:99 []
        ; message ~schema:2 []
        ; message [ default_entry ]
        ; "short"
        ]
    ; packet 2L [ raw_message ~declared_size:9 "bad"; message [ default_entry ] ]
    ; packet 3L [ raw_message ~declared_size:100 "short" ]
    ; packet 4L [ message [ default_entry ] ]
    ]
;;

let%test_unit "short packet headers retain current channel validity without advancing \
               sequence"
  =
  let m = message ~match_event_indicator:0x80 [ default_entry ] in
  verify
    [ packet 1L [ m ]; "bad"; packet 2L [ m ]; packet 4L [ m ]; "short"; packet 5L [ m ] ]
;;

let%test_unit "event FIFO saturation propagates backpressure with depth one" =
  let payloads =
    List.init 20 ~f:(fun n ->
      packet
        (Int64.of_int (n + 1))
        [ message ~match_event_indicator:0x80 (List.init 5 ~f:(fun _ -> default_entry)) ])
  in
  let result = Tiny.run ~sink_block_until:500 payloads in
  assert (result.input_stalls > 0 && result.output_stalls > 0);
  [%test_result: int] (List.length result.events) ~expect:120
;;

let%test_unit "session reset and resync wait for queued events; reset priority" =
  let payloads =
    List.map [ 10L; 12L; 100L; 7L ] ~f:(fun seq ->
      packet seq [ message ~match_event_indicator:0x80 [ default_entry ] ])
  in
  let controls =
    [ { after_packets = 2; session_reset = false; resync = Some 100L }
    ; { after_packets = 3; session_reset = true; resync = Some 999L }
    ]
  in
  let result = Small.run ~controls ~sink_block_until:300 payloads in
  [%test_result: int] result.controls ~expect:2
;;

let%test_unit "synchronous reset while disabled cancels queued work and restarts" =
  let result =
    Small.run
      ~reset_at:150
      ~sink_block_until:300
      [ packet
          1L
          [ message ~match_event_indicator:0x80 (List.init 10 ~f:(fun _ -> default_entry))
          ]
      ]
  in
  assert result.cancelled_work;
  [%test_result: int] (List.length result.events) ~expect:11
;;

let%test_unit "byte-source-like bubbles preserve all events" =
  ignore
    (Tiny.run
       ~beat_gap:8
       [ packet
           1L
           [ message ~match_event_indicator:0x80 [ default_entry; default_entry ] ]
       ]
     : Observation.t)
;;

let%test_unit "every physical truncation preserves an ordered update prefix and recovers" =
  let message_bytes =
    message
      ~root_block:15
      ~entry_block:35
      ~order_count:2
      ~match_event_indicator:0x80
      (List.init 6 ~f:(fun index -> { default_entry with rpt_seq = Int64.of_int index }))
  in
  let full_length = 12 + String.length message_bytes in
  let cases =
    List.init (full_length - 13) ~f:(fun index ->
      let seq = Int64.of_int (index + 1) in
      let complete = packet seq [ message_bytes ] in
      String.prefix complete (index + 13), complete)
  in
  let recovery =
    packet
      (Int64.of_int (List.length cases + 1))
      [ message ~match_event_indicator:0x80 [ default_entry ] ]
  in
  let payloads = List.map cases ~f:fst @ [ recovery ] in
  List.iter [ false; true ] ~f:(fun stalls ->
    let result = Small.run ~stalls ~check_model:false payloads in
    let actual = Queue.of_list result.events in
    let completed = ref 0 in
    List.iteri cases ~f:(fun index (truncated, complete) ->
      let ingress_timestamp = Int64.(0xfedc_ba98_7654_3210L + of_int index) in
      let expected =
        G.decode_payload ~ingress_timestamp (G.create ~schema_file) complete |> updates
      in
      let emitted = ref [] in
      while
        Option.exists (Queue.peek actual) ~f:(function
          | G.Mbp_update _ -> true
          | _ -> false)
      do
        match Queue.dequeue_exn actual with
        | G.Mbp_update u ->
          emitted := u :: !emitted;
          incr completed
        | _ -> assert false
      done;
      let emitted = List.rev !emitted in
      [%test_result: Sexp.t]
        ([%sexp_of: G.update list] emitted)
        ~expect:([%sexp_of: G.update list] (List.take expected (List.length emitted)));
      let expected_diagnostic =
        G.decode_payload ~ingress_timestamp (G.create ~schema_file) truncated
        |> List.last_exn
      in
      [%test_result: Sexp.t]
        ([%sexp_of: G.event] (Queue.dequeue_exn actual))
        ~expect:([%sexp_of: G.event] expected_diagnostic));
    assert (!completed > 0);
    let ingress_timestamp = Int64.(0xfedc_ba98_7654_3210L + of_int (List.length cases)) in
    [%test_result: Sexp.t]
      ([%sexp_of: G.event list] (Queue.to_list actual))
      ~expect:
        ([%sexp_of: G.event list]
           (G.decode_payload ~ingress_timestamp (G.create ~schema_file) recovery)))
;;

let%test_unit "deterministic randomized schedules preserve conformance" =
  Quickcheck.test
    ~trials:20
    ~seed:(`Deterministic "phase5-decoder-schedules")
    ~sexp_of:[%sexp_of: int]
    ~shrinker:Int.quickcheck_shrinker
    Int.quickcheck_generator
    ~f:(fun seed ->
      ignore
        (Small.run
           ~seed
           [ packet
               1L
               [ message [ default_entry ]; message ~match_event_indicator:0x80 [] ]
           ; packet
               3L
               [ message
                   ~version:14
                   ~entry_block:37
                   ~order_count:2
                   [ default_entry; default_entry ]
               ]
           ; packet 3L [ message [ default_entry ] ]
           ; packet 4L [ message ~match_event_indicator:0x80 [ default_entry ] ]
           ]
         : Observation.t))
;;
