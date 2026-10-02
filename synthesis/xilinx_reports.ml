(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "xilinx_reports.ml" *)
(* Explicit device reporting; without -run only Verilog/XDC/Tcl are generated. FIFO
   capacities are fixed here and printed with every invocation. The subcommands below
   select a *design*; the device is chosen separately by the required [-profile] flag,
   which supplies part and clock as a pair -- see [Report_support.Profile]. *)

open! Core
open! Async
open Cme_of_hardcaml
open Cme_report_support.Report_support
module Stream = Stream_test_support.Stream_fixture.Pass_through
module Ingress_command = Reports.Command.With_interface (Ingress_fifo.I) (Ingress_fifo.O)
module Event_command = Reports.Command.With_interface (Event_fifo.I) (Event_fifo.O)
module Aligner_command = Reports.Command.With_interface (Byte_aligner.I) (Byte_aligner.O)
module Stream_command = Reports.Command.With_interface (Stream.I) (Stream.O)
module Decoder_command = Reports.Command.With_interface (Mbp_decoder.I) (Mbp_decoder.O)

module Parser_command =
  Reports.Command.With_interface (Cme_feed_parser.I) (Cme_feed_parser.O)

(* Out-of-context synthesis leaves any path touching a top-level port unconstrained,
   because [hardcaml_xilinx_reports] emits only [create_clock] into its generated XDC and
   offers no hook for [set_input_delay]/[set_output_delay]. Registering every port is the
   library's intended substitute, so the aligner's combinational cones -- notably the
   [byte_count] priority encoder -- are measured between real flops. *)
module Aligner_i_with_clock = struct
  include Byte_aligner.I

  let get_clock (i : _ t) = i.clock_i
  let set_clock (i : _ t) ~clock = { i with clock_i = clock }
end

module Aligner_registered =
  Reports.Wrap_with_registers.Make_sequential (Aligner_i_with_clock) (Byte_aligner.O)

module Aligner_registered_command =
  Reports.Command.With_interface (Byte_aligner.I) (Byte_aligner.O)

(* Printed with every result, so it must track the configuration the design is actually
   built with rather than a literal that silently goes stale. *)
let depths =
  sprintf
    "ingress depth=%d; event depth=%d"
    Cme_config.default.ingress_fifo_depth
    Cme_config.default.event_fifo_depth
;;

let () =
  Command_unix.run
    (Command.group
       ~summary:
         (sprintf
            "CME device reports: ingress depth %d, event depth %d; template-46 MBP \
             parser. Every subcommand requires -profile production (xcu50-fsvh2104-2-e \
             at 156.25 MHz) or -profile validation (xc7a100tcsg324-1 at 25 MHz)"
            Cme_config.default.ingress_fifo_depth
            Cme_config.default.event_fifo_depth)
       [ ( "ingress-fifo"
         , report_command ~name:"cme_ingress_fifo" (fun flags ->
             printf "Target: ingress-fifo; %s (where applicable)\n" depths;
             Ingress_command.run
               ~primitive_groups:[]
               ~name:"cme_ingress_fifo"
               ~flags
               (fun scope i ->
                  Ingress_fifo.create ~depth:Cme_config.default.ingress_fifo_depth scope i))
         )
       ; ( "event-fifo"
         , report_command ~name:"cme_event_fifo" (fun flags ->
             printf "Target: event-fifo; %s (where applicable)\n" depths;
             Event_command.run
               ~primitive_groups:[]
               ~name:"cme_event_fifo"
               ~flags
               (fun scope i ->
                  Event_fifo.create ~depth:Cme_config.default.event_fifo_depth scope i)) )
       ; ( "byte-aligner"
         , report_command ~name:"cme_byte_aligner" (fun flags ->
             printf "Target: byte-aligner; %s (where applicable)\n" depths;
             Aligner_command.run
               ~primitive_groups:[]
               ~name:"cme_byte_aligner"
               ~flags
               Byte_aligner.create) )
       ; ( "byte-aligner-registered"
         , report_command ~name:"cme_byte_aligner_registered" (fun flags ->
             printf
               "Target: byte-aligner-registered; max_consume=8; all top-level ports \
                registered\n";
             Aligner_registered_command.run
               ~primitive_groups:[]
               ~name:"cme_byte_aligner_registered"
               ~flags
               (Aligner_registered.create (fun scope i ->
                  Byte_aligner.hierarchical scope i))) )
       ; ( "stream-foundation"
         , report_command ~name:"cme_stream_fixture" (fun flags ->
             printf "Target: stream-foundation; %s (where applicable)\n" depths;
             Stream_command.run
               ~primitive_groups:[]
               ~name:"cme_stream_fixture"
               ~flags
               (fun scope i ->
                  Stream.create ~depth:Cme_config.default.ingress_fifo_depth scope i)) )
       ; ( "mbp-decoder"
         , report_command ~name:"cme_mbp_decoder" (fun flags ->
             printf "Target: mbp-decoder; template=46; schema=1/13\n";
             Decoder_command.run
               ~primitive_groups:[]
               ~name:"cme_mbp_decoder"
               ~flags
               Mbp_decoder.create) )
       ; ( "cme-feed-parser"
         , report_command ~name:"cme_feed_parser" (fun flags ->
             printf "Target: cme-feed-parser; %s (where applicable)\n" depths;
             Parser_command.run
               ~primitive_groups:[]
               ~name:"cme_feed_parser"
               ~flags
               (fun scope i -> Cme_feed_parser.create ~config:Cme_config.default scope i))
         )
       ])
;;
