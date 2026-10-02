(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "phase6_stress_tests.ml" *)
(* Reproducible system differential stress. Shrinking seed lists regenerates encoded
   messages and all dependent sizes/counts, preserving valid wire framing. *)

open! Core
open Cme_feed_parser_testbench
open F

let choose random values = values.(Random.State.int random (Array.length values))

let wide random =
  Int64.bit_or
    (Int64.shift_left (Int64.of_int (Random.State.bits random)) 34)
    (Int64.bit_or
       (Int64.shift_left (Int64.of_int (Random.State.bits random)) 4)
       (Int64.of_int (Random.State.int random 16)))
;;

let signed32 random = Int64.(shift_right (shift_left (wide random) 32) 32)

let nullable random generate null =
  if Random.State.int random 5 = 0 then null else generate random
;;

let valid_message random =
  let version = 9 + Random.State.int random 5 in
  let entries =
    List.init (Random.State.int random 9) ~f:(fun _ ->
      { price = nullable random wide Int64.max_value
      ; size = nullable random signed32 0x7fff_ffffL
      ; security_id = signed32 random
      ; rpt_seq = Int64.bit_and (wide random) 0xffff_ffffL
      ; orders = nullable random signed32 0x7fff_ffffL
      ; level = Random.State.int random 256
      ; action = Random.State.int random 6
      ; entry_type =
          choose
            random
            (if version < 12
             then [| '0'; '1'; 'E'; 'F'; 'J' |]
             else [| '0'; '1'; 'E'; 'F'; 'J'; 'w'; 'x' |])
      ; tradeable = nullable random signed32 0x7fff_ffffL
      })
  in
  message
    ~version
    ~root_block:(11 + Random.State.int random 9)
    ~entry_block:(32 + Random.State.int random 9)
    ~order_block:(24 + Random.State.int random 9)
    ~order_count:(Random.State.int random 4)
    ~transact_time:(wide random)
    ~match_event_indicator:(Random.State.int random 256)
    entries
;;

let replace bytes offset width value =
  let bytes = Bytes.of_string bytes in
  set_le bytes offset width value;
  Bytes.to_string bytes
;;

let payloads ?(faults = false) seeds =
  let sequence = ref 0xffff_fffeL in
  List.map seeds ~f:(fun seed ->
    let random = Random.State.make [| seed; 0x504836 |] in
    let delta = if faults then choose random [| 0L; 1L; 1L; 1L; 2L; -1L |] else 1L in
    sequence := Int64.bit_and Int64.(!sequence + delta) 0xffff_ffffL;
    let good =
      List.init (1 + Random.State.int random 4) ~f:(fun _ -> valid_message random)
    in
    let messages, cut =
      if not faults
      then good, None
      else (
        let bad, cut =
          match Random.State.int random 10 with
          | 0 -> [ message ~template:65535 [] ], None
          | 1 -> [ message ~schema:2 [ default_entry ] ], None
          | 2 -> [ message ~version:14 [ default_entry ] ], None
          | 3 -> [ message [ { default_entry with action = 255 } ] ], None
          | 4 -> [ replace (message [ default_entry ]) 21 2 31L ], None
          | 5 -> [ raw_message ~declared_size:(Random.State.int random 10) "bad" ], None
          | 6 -> [], Some (1 + Random.State.int random 11)
          | 7 -> [], Some (13 + Random.State.int random 9)
          (* Before a complete first entry: the whole-payload oracle is exact. Deep
             cut-through truncations have a separate prefix-aware property below. *)
          | 8 -> [], Some (23 + Random.State.int random 10)
          | _ -> [], None
        in
        bad @ good, cut)
    in
    let bytes = packet ~sending_time:(wide random) !sequence messages in
    Option.value_map cut ~default:bytes ~f:(String.prefix bytes))
;;

let property ~seed ~trials ~packets f =
  Quickcheck.test
    ~trials
    ~seed:(`Deterministic seed)
    ~sexp_of:[%sexp_of: int list]
    ~shrinker:(List.quickcheck_shrinker Int.quickcheck_shrinker)
    ~shrink_attempts:(`Limit 100)
    (Quickcheck.Generator.list_with_length packets Int.quickcheck_generator)
    ~f
;;

let%test_unit "3072 schema-valid packets match the independent XML oracle under stalls" =
  property ~seed:"phase6-valid-packets" ~trials:48 ~packets:64 (fun seeds ->
    let result =
      Small.run ~seed:(List.hd seeds |> Option.value ~default:0) (payloads seeds)
    in
    assert (List.length result.accepted_beats >= List.length seeds))
;;

let%test_unit "1024 fault-mixed packets with reset, resync and session-reset controls" =
  property ~seed:"phase6-faults-controls" ~trials:32 ~packets:32 (fun seeds ->
    let length = List.length seeds in
    let controls =
      [ { after_packets = length / 4; session_reset = false; resync = Some 0xffff_ffffL }
      ; { after_packets = length / 2; session_reset = true; resync = Some 42L }
      ; { after_packets = length * 3 / 4; session_reset = false; resync = Some 0L }
      ]
    in
    let seed = List.hd seeds |> Option.value ~default:0 in
    let reset_at = 20 + (seed land 127) in
    let result = Small.run ~seed ~controls ~reset_at (payloads ~faults:true seeds) in
    [%test_result: int] result.controls ~expect:3)
;;

let%test_unit "512 deep randomized truncations retain only an exact update prefix" =
  property ~seed:"phase6-cut-through-truncations" ~trials:16 ~packets:32 (fun seeds ->
    let cases =
      List.mapi seeds ~f:(fun index seed ->
        let random = Random.State.make [| seed; 0x435554 |] in
        let msg =
          message
            ~version:(9 + Random.State.int random 5)
            ~root_block:(11 + Random.State.int random 64)
            ~entry_block:(32 + Random.State.int random 96)
            ~order_count:2
            ~match_event_indicator:0x80
            (List.init
               (2 + Random.State.int random 12)
               ~f:(fun entry ->
                 { default_entry with rpt_seq = Int64.of_int entry; price = wide random }))
        in
        let full = packet (Int64.of_int (index + 1)) [ msg ] in
        let cut = 34 + Random.State.int random (String.length full - 34) in
        String.prefix full cut, full)
    in
    let recovery =
      packet (Int64.of_int (List.length cases + 1)) [ message [ default_entry ] ]
    in
    let result =
      Small.run
        ~seed:(List.hd seeds |> Option.value ~default:0)
        ~check_model:false
        (List.map cases ~f:fst @ [ recovery ])
    in
    let actual = Queue.of_list result.events in
    List.iteri cases ~f:(fun index (truncated, full) ->
      let ingress_timestamp = Int64.(0xfedc_ba98_7654_3210L + of_int index) in
      let expected =
        G.decode_payload ~ingress_timestamp (G.create ~schema_file) full
        |> List.filter ~f:(function
          | G.Mbp_update _ -> true
          | _ -> false)
        |> Queue.of_list
      in
      while
        Option.exists (Queue.peek actual) ~f:(function
          | G.Mbp_update _ -> true
          | _ -> false)
      do
        [%test_result: Sexp.t]
          ([%sexp_of: G.event] (Queue.dequeue_exn actual))
          ~expect:([%sexp_of: G.event] (Queue.dequeue_exn expected))
      done;
      let diagnostic =
        G.decode_payload ~ingress_timestamp (G.create ~schema_file) truncated
        |> List.last_exn
      in
      [%test_result: Sexp.t]
        ([%sexp_of: G.event] (Queue.dequeue_exn actual))
        ~expect:([%sexp_of: G.event] diagnostic));
    let ingress_timestamp = Int64.(0xfedc_ba98_7654_3210L + of_int (List.length cases)) in
    [%test_result: Sexp.t]
      ([%sexp_of: G.event list] (Queue.to_list actual))
      ~expect:
        ([%sexp_of: G.event list]
           (G.decode_payload ~ingress_timestamp (G.create ~schema_file) recovery)))
;;

let%test_unit "phase6 regression: extended root and MBO handoffs under stalls and reset" =
  let messages =
    List.init 40 ~f:(fun index ->
      message
        ~version:(9 + (index mod 5))
        ~root_block:(43 + (index mod 8))
        ~entry_block:(96 + (index mod 8))
        ~order_block:(40 + (index mod 8))
        ~order_count:(index mod 4)
        ~match_event_indicator:0x80
        (List.init (index mod 4) ~f:(fun entry ->
           { default_entry with rpt_seq = Int64.of_int entry })))
  in
  let payloads =
    List.init 8 ~f:(fun index -> packet (Int64.of_int (index + 1)) messages)
  in
  List.iter [ 17; 83; 211 ] ~f:(fun seed ->
    ignore (Small.run ~seed ~reset_at:137 payloads : Observation.t))
;;

let%test_unit "phase6 regression: extended dimension errors keep diagnostic offsets" =
  let root = 47
  and entry = 99 in
  let good =
    message ~root_block:root ~entry_block:entry ~order_count:2 [ default_entry ]
  in
  let mbp_offset = 10 + root in
  let order_offset = mbp_offset + 3 + entry in
  let short = String.prefix good (mbp_offset + 2) in
  let bad =
    [ replace good mbp_offset 2 31L
    ; replace good (mbp_offset + 2) 1 255L
    ; replace good order_offset 2 23L
    ; replace good (order_offset + 7) 1 255L
    ; replace short 0 2 (Int64.of_int (String.length short))
    ]
  in
  let payloads =
    List.mapi bad ~f:(fun index bad -> packet (Int64.of_int (index + 1)) [ bad; good ])
  in
  List.iter [ false; true ] ~f:(fun stalls ->
    ignore (Small.run ~stalls payloads : Observation.t))
;;
