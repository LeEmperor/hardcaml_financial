(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "elastic_fifo.ml" *)
(* Packed ready/valid storage with exact positive capacity and full-rate replacement. The
   showahead register counts toward capacity. Reset overrides the shared enable.
*)

open! Hardcaml
open Signal

type t =
  { data : Signal.t
  ; valid : Signal.t
  ; ready : Signal.t
  }

let create ~depth scope ~clock ~reset ~en ~data ~valid ~ready =
  if depth < 1 then invalid_arg "FIFO depth must be positive";
  let active = en &: ~:reset in
  let pop = wire 1 in
  let push = wire 1 in
  let spec = Reg_spec.create ~clock ~clear:reset () in
  let output, empty, full =
    if depth = 1
    then (
      let occupied = reg_fb spec ~width:1 ~f:(fun q -> mux2 push vdd (mux2 pop gnd q)) in
      reg spec ~enable:push data, ~:occupied, occupied)
    else (
      let fifo =
        Fifo.create
          ~scope
          ~showahead:true
          ~overflow_check:false
          ~underflow_check:false
          ()
          ~capacity:(depth - 1)
          ~clock
          ~clear:reset
          ~wr:push
          ~d:data
          ~rd:pop
      in
      fifo.q, fifo.empty, fifo.full)
  in
  let output_valid = active &: ~:empty in
  pop <-- (output_valid &: ready);
  let input_ready = active &: (~:full |: pop) in
  push <-- (valid &: input_ready);
  { data = output; valid = output_valid; ready = input_ready }
;;
