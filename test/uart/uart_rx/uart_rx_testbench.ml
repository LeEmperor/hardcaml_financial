(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "uart_rx_testbench.ml" *)

(* Testbench Support: Uart_rx

   Shared DUT fixture, drivers, observations, and simulation scenarios used by the unit,
   Quickcheck, and expect test suites.

   The oracle is a software UART transmitter, not a cycle model - the mirror image of what
   [uart_tx_testbench] does with [Uart_receiver]. [Uart_transmitter.frame] turns a byte
   into the ten symbols a real transmitter would put on the line, the driver walks that
   line past the DUT one cycle at a time, and the headline property is the round trip: a
   random byte onto the wire, the same byte out of [d_out]. That is indifferent to how the
   receiver chooses to time itself, which is the point - the block is tick-driven, so the
   only thing a cycle-level model would pin down is the tick schedule the test itself
   chose.

   Symbols are intervals, and the tick's phase inside one is the whole story. The block
   re-phases in START: it waits there for the first tick after the start edge, and every
   sample after that is one symbol period later. So a tick at cycle [tick_phase] of the
   start-bit interval puts every subsequent sample at that same offset into its own
   symbol, and the frame decodes correctly for any [tick_phase] in [1, cycles_per_symbol).
   Zero is excluded and is not an off-by-one: at cycle zero of the start bit the falling
   edge and the tick land together, START has not been entered yet, and the receiver
   spends the frame one symbol behind. [run_byte] defaults to the mid-bit phase, which is
   where a real receiver would sample.

   Sampling. [before_edge]. [d_out_valid] is an [Always.Variable.wire] driven off the
   current state - it is high for the whole of the STOP window rather than as a pulse - so
   the value during a cycle is what that cycle's state selects. [d_out] is the shift
   register, so at [before_edge] it holds everything shifted in on prior cycles, which is
   the complete byte by the time STOP is reached. [after_edge] would report the state the
   block is moving to and shift the frame by one.

   Tags: [{ "ACTIVE" ; "TEST" ; "TESTBENCH" ; "COMMON_ITEMS" }]
*)

open! Core
open! Hardcaml
open! Uart_of_hardcaml
open! Hardcaml_step_testbench
open! Hardcaml_verif
module Dut = Uart_rx

(* Start bit, eight data bits, stop bit. *)
let symbols_per_frame = 10
let data_bits_per_frame = 8

(* The software transmitter: 8-N-1, least significant data bit first, line idling at mark.
   This is the stimulus, so it is written out rather than derived from anything the DUT
   does. *)
module Uart_transmitter = struct
  let idle_line = true

  let frame byte =
    (false :: List.init data_bits_per_frame ~f:(fun index -> (byte lsr index) land 1 = 1))
    @ [ true ]
  ;;
end

(* One driven cycle, as the DUT presented it. *)
module Observation = struct
  type t =
    { d_out_valid : bool
    ; d_out : int
    }
  [@@deriving sexp, equal, compare]
end

(* What the receiver produced over a whole run: the byte it announced, and how long it
   announced it for. Deliberately total - a run with no valid window at all comes back as
   [None] rather than raising, so a failing property prints what the block actually did
   instead of a backtrace. *)
module Reception = struct
  type t =
    { byte : int option
    ; valid_cycles : int
    ; num_windows : int (* separate runs of [d_out_valid]; a clean frame has exactly 1 *)
    }
  [@@deriving sexp, equal, compare]

  let of_observations observations =
    let byte =
      List.find_map observations ~f:(fun (observation : Observation.t) ->
        if observation.d_out_valid then Some observation.d_out else None)
    in
    let valid_cycles =
      List.count observations ~f:(fun (observation : Observation.t) ->
        observation.d_out_valid)
    in
    let num_windows =
      List.fold
        observations
        ~init:(0, false)
        ~f:(fun (count, was_valid) (observation : Observation.t) ->
          ( (if observation.d_out_valid && not was_valid then count + 1 else count)
          , observation.d_out_valid ))
      |> fst
    in
    { byte; valid_cycles; num_windows }
  ;;
end

module Testbench = struct
  module Fixture = Sim_fixture.Make (struct
      include Dut

      let name = "Uart_rx"
    end)

  module Sim = Fixture.Sim
  module Step = Fixture.Step

  let bit = Bits_conv.bit

  let inputs ~reset ~en ~tick ~uart_rx_d =
    { Step.input_hold with
      reset = bit reset
    ; en = bit en
    ; tick = bit tick
    ; uart_rx_d = bit uart_rx_d
    }
  ;;

  let snapshot (output : Bits.t Dut.O.t) =
    { Observation.d_out_valid = Bits.to_bool output.d_out_valid
    ; d_out = Bits.to_int_trunc output.d_out
    }
  ;;

  (* Clear applied with the enable low and the line at mark, so the block starts from idle
     rather than from a spurious start edge. *)
  let reset ?(num_cycles = 2) (handler : Step.Handler.t @ local) =
    Step.delay
      ~num_cycles
      handler
      (inputs ~reset:true ~en:false ~tick:false ~uart_rx_d:Uart_transmitter.idle_line)
  ;;

  let drive (handler : Step.Handler.t @ local) ~en ~tick ~uart_rx_d =
    Step.cycle handler (inputs ~reset:false ~en ~tick ~uart_rx_d)
    |> Step.O_data.before_edge
    |> snapshot
  ;;

  (* One symbol interval: [cycles_per_symbol] cycles holding [line], with [tick] high on
     exactly one of them. Holding the line for the whole interval rather than pulsing it
     is what makes the tick's phase meaningful. *)
  let drive_symbol
    (handler : Step.Handler.t @ local)
    ~cycles_per_symbol
    ~tick_phase
    ~en
    ~line
    =
    let rec loop (handler : Step.Handler.t @ local) index =
      if index = cycles_per_symbol
      then []
      else (
        let observation = drive handler ~en ~tick:(index = tick_phase) ~uart_rx_d:line in
        observation :: loop handler (index + 1))
    in
    loop handler 0
  ;;

  let drive_symbols
    (handler : Step.Handler.t @ local)
    ~cycles_per_symbol
    ~tick_phase
    ~en
    ~lines
    =
    let rec loop (handler : Step.Handler.t @ local) = function
      | [] -> []
      | line :: remaining ->
        let observations =
          drive_symbol handler ~cycles_per_symbol ~tick_phase ~en ~line
        in
        observations @ loop handler remaining
    in
    loop handler lines
  ;;

  let drive_idle
    (handler : Step.Handler.t @ local)
    ~cycles_per_symbol
    ~tick_phase
    ~num_symbols
    =
    drive_symbols
      handler
      ~cycles_per_symbol
      ~tick_phase
      ~en:true
      ~lines:(List.init num_symbols ~f:(fun _ -> Uart_transmitter.idle_line))
  ;;

  let create_simulator = Fixture.create_simulator
  let run_with_timeout = Fixture.run_with_timeout
  let default_tick_phase ~cycles_per_symbol = Int.max 1 (cycles_per_symbol / 2)
  let timeout_for ~cycles_per_symbol ~num_symbols = 8 + (num_symbols * cycles_per_symbol)

  (* Send one byte and report every driven cycle: leading idle, the ten symbols, trailing
     idle. The trailing idle is what makes the STOP window visible - [d_out_valid] stays
     high until the tick that ends it. *)
  let run_byte
    ?(cycles_per_symbol = 4)
    ?tick_phase
    ?(num_leading = 1)
    ?(num_trailing = 2)
    byte
    =
    let tick_phase =
      Option.value tick_phase ~default:(default_tick_phase ~cycles_per_symbol)
    in
    let testbench (handler : Step.Handler.t @ local) _initial_outputs =
      reset handler;
      let leading =
        drive_idle handler ~cycles_per_symbol ~tick_phase ~num_symbols:num_leading
      in
      let frame =
        drive_symbols
          handler
          ~cycles_per_symbol
          ~tick_phase
          ~en:true
          ~lines:(Uart_transmitter.frame byte)
      in
      let trailing =
        drive_idle handler ~cycles_per_symbol ~tick_phase ~num_symbols:num_trailing
      in
      leading @ frame @ trailing
    in
    run_with_timeout
      ~timeout:
        (timeout_for
           ~cycles_per_symbol
           ~num_symbols:(num_leading + symbols_per_frame + num_trailing))
      ~testbench
  ;;

  let receive ?cycles_per_symbol ?tick_phase byte =
    Reception.of_observations (run_byte ?cycles_per_symbol ?tick_phase byte)
  ;;

  (* Two frames back to back with a single idle symbol between them, which is the tightest
     spacing 8-N-1 allows. Splits the observations at the second start edge so each frame
     can be decoded on its own. *)
  let run_two_bytes ?(cycles_per_symbol = 4) ?tick_phase first second =
    let tick_phase =
      Option.value tick_phase ~default:(default_tick_phase ~cycles_per_symbol)
    in
    let testbench (handler : Step.Handler.t @ local) _initial_outputs =
      reset handler;
      let leading = drive_idle handler ~cycles_per_symbol ~tick_phase ~num_symbols:1 in
      let frame_a =
        drive_symbols
          handler
          ~cycles_per_symbol
          ~tick_phase
          ~en:true
          ~lines:(Uart_transmitter.frame first)
      in
      let gap = drive_idle handler ~cycles_per_symbol ~tick_phase ~num_symbols:1 in
      let frame_b =
        drive_symbols
          handler
          ~cycles_per_symbol
          ~tick_phase
          ~en:true
          ~lines:(Uart_transmitter.frame second)
      in
      let trailing = drive_idle handler ~cycles_per_symbol ~tick_phase ~num_symbols:2 in
      ( Reception.of_observations (leading @ frame_a)
      , Reception.of_observations (gap @ frame_b @ trailing) )
    in
    run_with_timeout
      ~timeout:
        (timeout_for ~cycles_per_symbol ~num_symbols:(2 + (2 * symbols_per_frame) + 2))
      ~testbench
  ;;

  (* The line held at mark for a stretch: nothing should ever be announced. *)
  let run_idle ?(cycles_per_symbol = 4) ~num_symbols () =
    let tick_phase = default_tick_phase ~cycles_per_symbol in
    let testbench (handler : Step.Handler.t @ local) _initial_outputs =
      reset handler;
      drive_idle handler ~cycles_per_symbol ~tick_phase ~num_symbols
    in
    run_with_timeout ~timeout:(timeout_for ~cycles_per_symbol ~num_symbols) ~testbench
  ;;

  (* The enable held low for the whole frame. The start edge is lost rather than deferred,
     and the reason is worth stating: the FSM is gated by [en], but the edge detector's
     history register is not, so by the time the enable returns the detector has already
     taken the low line as its history and there is no edge left to find. *)
  let run_byte_disabled ?(cycles_per_symbol = 4) byte =
    let tick_phase = default_tick_phase ~cycles_per_symbol in
    let testbench (handler : Step.Handler.t @ local) _initial_outputs =
      reset handler;
      let leading = drive_idle handler ~cycles_per_symbol ~tick_phase ~num_symbols:1 in
      let frame =
        drive_symbols
          handler
          ~cycles_per_symbol
          ~tick_phase
          ~en:false
          ~lines:(Uart_transmitter.frame byte)
      in
      let trailing = drive_idle handler ~cycles_per_symbol ~tick_phase ~num_symbols:3 in
      leading @ frame @ trailing
    in
    run_with_timeout
      ~timeout:(timeout_for ~cycles_per_symbol ~num_symbols:(1 + symbols_per_frame + 3))
      ~testbench
  ;;

  (* A clear asserted partway through a frame. The synchronous clear takes effect on the
     cycle after it is applied, so the frame is abandoned and nothing is announced. *)
  let run_byte_cleared_midframe ?(cycles_per_symbol = 4) ~num_symbols_before_clear byte =
    let tick_phase = default_tick_phase ~cycles_per_symbol in
    let testbench (handler : Step.Handler.t @ local) _initial_outputs =
      reset handler;
      let leading = drive_idle handler ~cycles_per_symbol ~tick_phase ~num_symbols:1 in
      let lines = Uart_transmitter.frame byte in
      let before =
        drive_symbols
          handler
          ~cycles_per_symbol
          ~tick_phase
          ~en:true
          ~lines:(List.take lines num_symbols_before_clear)
      in
      reset ~num_cycles:1 handler;
      let after =
        drive_symbols
          handler
          ~cycles_per_symbol
          ~tick_phase
          ~en:true
          ~lines:(List.drop lines num_symbols_before_clear)
      in
      let trailing = drive_idle handler ~cycles_per_symbol ~tick_phase ~num_symbols:2 in
      leading @ before @ after @ trailing
    in
    run_with_timeout
      ~timeout:(timeout_for ~cycles_per_symbol ~num_symbols:(1 + symbols_per_frame + 3))
      ~testbench
  ;;
end

(* Golden rendering: one character per driven cycle. ['V'] marks a cycle inside the STOP
   window, so the row shows where in the frame the byte is announced and for how long. *)
let valid_trace observations =
  String.of_list
    (List.map observations ~f:(fun (observation : Observation.t) ->
       if observation.d_out_valid then 'V' else '.'))
;;
