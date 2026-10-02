(* University of Florida *)
(* Author: Bohdan Purtell *)
(* Module: "report_support.ml" *)
(* Adapted from hardcaml_networking/synthesis/xilinx_reports.ml at
   4109a4a6540e3c328e431cfa58a6e7526fa9733f. Standard reports and freshness checks prevent
   an upstream Vivado failure from appearing to be successful evidence. *)

open! Core
open! Async
module Reports = Hardcaml_xilinx_reports

(* The part and the clock are one indivisible choice, so they are named together here and
   the underlying [-part] / [-clock] flags are removed. Phases 0-6 recorded every device
   number against [-part xc7a100tcsg324-1 -clock clock_i:156.25]: the validation part held
   to the production clock, a combination that describes no operating point anybody
   intends. See docs/retargeting.md. *)
module Profile = struct
  type t =
    | Production
    | Validation

  (* Every interface in the design names its clock [clock_i]. *)
  let clock_port_name = "clock_i"

  let name = function
    | Production -> "production"
    | Validation -> "validation"
  ;;

  let part_name = function
    | Production -> "xcu50-fsvh2104-2-e"
    | Validation -> "xc7a100tcsg324-1"
  ;;

  let frequency_mhz = function
    | Production -> 156.25
    | Validation -> 25.
  ;;

  let period_ns t = 1000. /. frequency_mhz t

  let establishes = function
    | Production -> "establishes 10G timing closure; the only profile that can"
    | Validation ->
      "establishes Arty A7-100T board acceptance only; says nothing about throughput"
  ;;

  let clock t =
    Reports.Clock.create_mhz ~name:clock_port_name ~frequency_mhz:(frequency_mhz t) ()
  ;;

  let all = [ Production; Validation ]
  let arg_type = Command.Arg_type.of_alist_exn (List.map all ~f:(fun t -> name t, t))

  let param =
    Command.Param.flag
      "-profile"
      (Command.Param.required arg_type)
      ~doc:"production|validation device profile; selects part and clock together"
  ;;

  (* The standing rule in docs/retargeting.md is that a device number naming only one of
     its part and its clock is not evidence. Printing both beside every summary is what
     enforces it. *)
  let describe t =
    sprintf
      "Profile: %s; part %s; clock %s at %g MHz (%.3f ns period); %s"
      (name t)
      (part_name t)
      clock_port_name
      (frequency_mhz t)
      (period_ns t)
      (establishes t)
  ;;
end

type report_artifacts =
  { compact : string
  ; utilization : string
  ; timing : string
  }

let report_artifacts ~(flags : Reports.Command.Command_flags.t) ~name =
  let stage =
    match flags.place, flags.route with
    | true, true -> "post_route"
    | true, false -> "post_place"
    | false, (false | true) -> "post_synth"
  in
  let directory = Filename.concat flags.output_path name in
  { compact = Filename.concat directory (stage ^ "_report.txt")
  ; utilization = Filename.concat directory (stage ^ "_" ^ name ^ ".utilization")
  ; timing = Filename.concat directory (stage ^ "_" ^ name ^ ".timing")
  }
;;

let read_required_report path =
  let contents =
    try In_channel.read_all path with
    | Sys_error error ->
      raise_s [%message "Vivado did not produce an expected report" (path : string) error]
  in
  if String.is_empty contents
  then raise_s [%message "Vivado produced an empty report" (path : string)];
  contents
;;

let normalize_resource_name name =
  let name = String.strip name in
  Option.value (String.chop_suffix name ~suffix:"*") ~default:name
;;

let utilization_rows contents =
  let wanted =
    String.Set.of_list
      [ (* Series-7 names the first two rows "Slice ..."; UltraScale+ names them "CLB
           ...". Both are listed because a row that is absent from this set is dropped
           from the summary without any diagnostic. *)
        "Slice LUTs"
      ; "CLB LUTs"
      ; "LUT as Logic"
      ; "LUT as Memory"
      ; "LUT as Distributed RAM"
      ; "LUT as Shift Register"
      ; "Slice Registers"
      ; "CLB Registers"
      ; "Register as Flip Flop"
      ; "CARRY4"
      ; "CARRY8"
      ; "F7 Muxes"
      ; "F8 Muxes"
      ; "F9 Muxes"
      ; "Block RAM Tile"
      ; "DSPs"
      ]
  in
  let seen = String.Hash_set.create () in
  String.split_lines contents
  |> List.filter_map ~f:(fun line ->
    match String.split line ~on:'|' with
    | _left :: name :: used :: _fixed :: _prohibited :: available :: utilization :: _ ->
      let name = normalize_resource_name name in
      if Set.mem wanted name && not (Hash_set.mem seen name)
      then (
        Hash_set.add seen name;
        Some (name, String.strip used, String.strip available, String.strip utilization))
      else None
    | _ -> None)
;;

let print_utilization_summary ~path contents =
  printf "\nVivado utilization summary (%s)\n" path;
  printf "  %-28s %10s %10s %10s\n" "RESOURCE" "USED" "AVAILABLE" "UTIL%";
  List.iter (utilization_rows contents) ~f:(fun (name, used, available, utilization) ->
    printf "  %-28s %10s %10s %10s\n" name used available utilization)
;;

let print_timing_summary ~path contents =
  let summary_lines =
    String.split_lines contents
    |> List.map ~f:String.strip
    |> List.filter ~f:(fun line ->
      String.is_prefix line ~prefix:"Setup :"
      || String.is_prefix line ~prefix:"Hold  :"
      || String.is_prefix line ~prefix:"PW    :")
  in
  printf "\nVivado timing summary (%s)\n" path;
  List.iter summary_lines ~f:(printf "  %s\n")
;;

let print_artifact_paths ({ compact; utilization; timing } : report_artifacts) =
  printf "\nReport artifacts\n";
  printf "  compact:     %s\n" compact;
  printf "  utilization: %s\n" utilization;
  printf "  timing:      %s\n" timing
;;

let artifact_paths ({ compact; utilization; timing } : report_artifacts) =
  [ compact; utilization; timing ]
;;

let modification_time path =
  if Sys_unix.file_exists_exn path then Some (Core_unix.stat path).st_mtime else None
;;

let require_refreshed_artifacts artifacts previous_modification_times =
  List.iter2_exn
    (artifact_paths artifacts)
    previous_modification_times
    ~f:(fun path previous_modification_time ->
      match previous_modification_time, modification_time path with
      | None, Some _ -> ()
      | Some previous, Some current when Float.(current > previous) -> ()
      | None, None -> () (* [read_required_report] below provides the clearer error. *)
      | Some _, None -> ()
      | Some previous, Some current ->
        raise_s
          [%message
            "Vivado did not refresh an expected report"
              (path : string)
              (previous : float)
              (current : float)])
;;

let print_reports ~profile ~full_report artifacts previous_modification_times =
  let compact = read_required_report artifacts.compact in
  let utilization = read_required_report artifacts.utilization in
  let timing = read_required_report artifacts.timing in
  require_refreshed_artifacts artifacts previous_modification_times;
  ignore compact;
  printf "\n%s\n" (Profile.describe profile);
  print_utilization_summary ~path:artifacts.utilization utilization;
  print_timing_summary ~path:artifacts.timing timing;
  print_artifact_paths artifacts;
  if full_report
  then (
    printf
      "\n===== FULL UTILIZATION REPORT: %s =====\n%s\n"
      artifacts.utilization
      utilization;
    printf "\n===== FULL TIMING REPORT: %s =====\n%s\n" artifacts.timing timing)
;;

let report_command ~name run =
  Command.async
    ~summary:("Synthesis reports for " ^ name)
    (let open Command.Let_syntax in
     let%map_open () = return ()
     and profile = Profile.param
     (* [-part] and [-clock] are replaced by [-profile], not supplemented by it: a
        deliberate loss of expressiveness, since the pair drifting apart is the failure
        this guards against. Restoring an override means restoring the drift. *)
     and flags =
       Reports.Command.Command_flags.flags ~part_name:(return "") ~clocks:(return []) ()
     and full_report =
       flag
         "-full-report"
         no_arg
         ~doc:" print the complete Vivado utilization and timing reports"
     in
     fun () ->
       (* Standard Vivado reports are always required; see [primitive_groups]. *)
       let flags =
         { flags with
           reports = true
         ; part_name = Profile.part_name profile
         ; clocks = [ Profile.clock profile ]
         }
       in
       printf "%s\n" (Profile.describe profile);
       let artifacts = report_artifacts ~flags ~name in
       let previous_modification_times =
         List.map (artifact_paths artifacts) ~f:modification_time
       in
       let open Deferred.Let_syntax in
       let%map () = run flags in
       Out_channel.flush Out_channel.stdout;
       if flags.run
       then print_reports ~profile ~full_report artifacts previous_modification_times
       else (
         printf "Generated report project in %s\n" (Filename.dirname artifacts.compact);
         printf "Add -run to invoke Vivado and print the report summary.\n"))
;;
