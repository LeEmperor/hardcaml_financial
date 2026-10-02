# Phase 6 pickup — historical checkpoint

> Resumed on 2026-09-07. The padded-layout failure described below is fixed,
> and the expanded 14-case performance gate passes. See the
> [Phase 6 verification record](phase6_verification.md) for current results and
> continuation instructions. The commands, expected failure, and device limits
> below describe the earlier checkpoint.

Checkpoint: 2026-09-07. Continue from the current working tree, including its
untracked source files. This is a handoff at the user's request, not Phase 6
completion. The [main plan](cme_mdp3_10g_parser_plan.md) remains the authority;
[Phase 5](phase5_decoding.md) describes the underlying decoder and event contract.

## Status and first commands

Functional conformance and RTL structural checks pass. Five measured traffic
cases meet the cycle-level performance criteria. The padded-layout case fails:
351 of 384 entry events exceed eight cycles, with a maximum of 23 cycles. There
is no fresh full-parser device timing or mapped resource result for this
checkpoint. Phase 6.2 and the device-reporting portion of 6.3 remain open.

Run from the repository root, using the existing opam switch wrapper:

```sh
./scripts/with-switch.sh dune build --build-dir /tmp/cme-phase6-build --display quiet @all @runtest @fmt @rtl-check
./scripts/with-switch.sh dune build --build-dir /tmp/cme-phase6-build @performance-report
./scripts/with-switch.sh dune build --build-dir /tmp/cme-phase6-build @performance-check
```

The last command is **expected to fail** until the padded-layout deficit is
fixed. `@performance-report` prints the same measurements and failure status
but exits successfully; it is an inspection command, not an acceptance gate.
Keep the thresholds intact. Performance acceptance is separate from ordinary
`@runtest`, so a passing functional suite does not imply Phase 6 completion.

For per-entry timing of the first two padded packets:

```sh
cd test/cme/cme_feed_parser
/tmp/cme-phase6-build/default/test/cme/cme_feed_parser/phase6_performance.exe --detail
```

The executable needs that working directory for the XML fixture's relative
path. The Dune aliases arrange their own dependencies and working directory.
Run Dune commands sequentially. A separate `/tmp/cme-phase6-build` was used
to avoid contention with ongoing work in `_build`; it is disposable and must
not be assumed to exist on another machine.

## Retained implementation

The portable parser's ports and 677-bit event ABI are unchanged. The default
configuration still uses 64 ingress FIFO beats and 16 output events.

- `lib/cme/byte_aligner.ml`: configurable consumption of up to 15 bytes from
  the existing two-beat, 128-bit window. The ordinary constructor retains the
  eight-byte limit. Pipeline instances opt into 15. Concurrent work added
  named signals and registered slot byte counts; these changes are preserved
  and included in the checkpoint tests.
- `lib/cme/packet_header.ml`: consume the twelve-byte technical header in one
  command when available.
- `lib/cme/sbe_message_iterator.ml`: collect a ten-byte SBE prefix together
  when it fits; retain the eight-plus-two fallback at offset seven. A final
  short body beat can prefetch the following prefix. Packet/message retirement
  overlaps the next admission where ordering permits.
- `lib/cme/mbp_decoder.ml`: combine compatible root/dimension collection,
  collect entries into schema-sized byte registers, emit a completed entry on
  its final collection cycle, and use padding consumption to prefetch the next
  entry or MBO dimensions. Exceptional schema, abort, and backpressure paths
  retain their diagnostic ordering.
- `lib/cme/event_orderer.ml`: permit previous-message retirement and
  next-message admission together.
- `lib/cme/elastic_fifo.ml` and `event_fifo.ml`: optional empty-queue
  fallthrough, enabled for the integrated output FIFO. Standalone defaults are
  unchanged; depth-one and stalled bypass behavior have regression coverage.

Message body beats remain eight bytes except at the final beat of a message.
Do not silently introduce short non-final beats: the aligner's storage layout
and decoder collectors rely on this convention.

## Functional evidence and test locations

`test/cme/cme_feed_parser/cme_feed_parser_testbench.ml` is now a shared test
support library. Its typed observation records accepted ingress byte ranges,
their cycles, and transferred event cycles alongside the existing exact XML
oracle scoreboard. Performance and stress tests use this same Step fixture.
Reset clears timing observations along with cancelled work.

`test/cme/cme_feed_parser/phase6_stress_tests.ml` adds these reproducible
properties to ordinary `@runtest`:

| Property | Deterministic seed | Trials × packets |
| --- | --- | --- |
| Schema-valid differential streams | `phase6-valid-packets` | 48 × 64 = 3,072 |
| Faults, reset, resync, session reset | `phase6-faults-controls` | 32 × 32 = 1,024 |
| Deep physical truncation and recovery | `phase6-cut-through-truncations` | 16 × 32 = 512 |

The valid generator covers versions 9–13, zero/multiple entries, compatible
root/entry extensions, MBO groups, signed values, nulls, and randomized sink
backpressure/source gaps. Seed-list and integer shrinking re-encode dependent
lengths/counts, preserving framing for the valid property; shrinking is capped
at 100 attempts. Fault streams include sequence wrap, gaps, duplicate/late
packets, unsupported/incompatible messages, invalid enums/dimensions/sizes,
and early truncation. Reset intentionally cancels in-flight work, so the table
counts generated packets, not a claim that all survive reset and emit events.

Deep truncations use an explicit cut-through scoreboard: compare the exact
already-emitted update prefix against the complete-message XML oracle, then
check the truncation diagnostic and following recovery packet. This property
sets `check_model:false` only to replace whole-payload equality with those
explicit assertions; it does not leave events unverified.

Named regression in
`test/cme/message_pipeline/message_pipeline_unit_quickcheck_tests.ml`:
`phase6 regression: a prefix at offset seven spans three input beats`.
This guards the deadlock exposed when a ten-byte prefix cannot fit in the
remaining portion of two stored beats. It runs with and without stalls.
Aligner coverage includes the 15-byte limit and slot-byte-count invariants;
FIFO coverage includes optional fallthrough at depths 1, 3, and 16.

The checkpoint passes the full functional suite, not just these new properties.
No sanitized real-capture replay was added; the plan does not require it when
unavailable.

## Measured performance and remaining failure

`test/cme/cme_feed_parser/phase6_performance.ml` drives uninterrupted input with
an always-ready event sink and compares all emitted events with the XML oracle.
Entry latency is measured from external acceptance of the beat containing the
last required semantic byte to external transfer of its update. For template
46/version 13 that byte is entry byte 30 (zero-based); reserved byte 31 and
runtime extension padding must not shift the latency origin. Every update is
matched by packet sequence, message offset, and entry index. The test also
checks that the ingress acceptance span equals beats plus input stalls.

| Traffic | Packets | Beats | Events | Input stalls | Entry latency (cycles) | Entries over 8 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Single entry | 1 | 10 | 2 | 0 | 7 | 0 / 1 |
| Dense entries (255/message) | 16 | 16,416 | 4,096 | 0 | 7 | 0 / 4,080 |
| Small packets | 128 | 1,280 | 256 | 0 | 7 | 0 / 128 |
| Zero-entry packets | 128 | 768 | 128 | 0 | N/A | 0 / 0 |
| Many messages (16/packet) | 16 | 2,080 | 512 | 0 | 7 | 0 / 256 |
| Padded alignments | 16 | 2,304 | 512 | 0 | 7–23 | 351 / 384 |

The failing case has eight messages per packet and three entries per message.
For zero-based message index `m`, root block length is `11 + m mod 8` and entry
block length is `32 + (m + 3) mod 8`. MBO count is zero; the end-of-event bit is
set. Root/entry lengths therefore exercise differing prefix and body alignments.

The backlog grows roughly one cycle per repeated packet. For example, in
packet 0 the first entry is accepted at cycle 9 and emitted at 16 (latency 7);
at message offset 737, entries are accepted at 100/104/108 and emitted at
108/112/116 (latency 8). In packet 1 the first entry is accepted at 153 and
emitted at 161 (latency 8); offset 737 entries are accepted at 244/248/252 and
emitted at 253/257/261 (latency 9). `--detail` exposes these measurements.
Do not interpret zero stalls in this finite run as proof of sustained rate:
buffering can absorb the developing deficit.

Suggested next investigation:

1. Reproduce the table before changing RTL. Extend the padded stream long
   enough to exceed ingress buffering and quantify the steady-state deficit.
2. Reduce the legal root/entry/message alignment combination and trace internal
   prefix/body transfers, decoder states, and message retirement. Fractional
   body/prefix packing and handoff overhead are suspects, not established causes.
3. Fix the isolated deficit while retaining complete event/model equality and
   the existing truncation/reset/stall tests. Technical-header fusion and
   packet-retirement overlap alone did not remove it.
4. Broaden continuous-traffic cases to zero-entry multi-message packets, MBO
   groups, larger compatible extensions, and supported version combinations.
   The six current cases are useful evidence, not exhaustive legal coverage.

One experiment was removed before this checkpoint: emitting a partial
non-final first-body fragment together with prefix consumption, compacting
short aligner heads against their tails, and gating combined decoder reads.
That change regressed many-message traffic to 45 stalls / 74-cycle maximum
latency and padded traffic to 208 stalls / 89-cycle maximum latency. It is not
present in the tested design. Revisit fragments only with an explicit internal
beat contract and corresponding collector redesign.

## RTL and device evidence limits

`test/cme/rtl_checks/phase6_structure.ml`, run by `@runtest`, flattens the full
parser, asserts no remaining instantiations, and calls Hardcaml's combinational
loop detector. It inventories mux widths/choices and rejects widths above 128
unless they match explicitly allowed normalized record widths. Negative
controls verify rejection of a feedback loop and a 512-bit mux.

The checkpoint graph reports 134 register nodes and 8,236 register bits,
excluding memory arrays. These are pre-synthesis graph counts, not mapped
FPGA area. The inventory includes 128-bit window muxes and intentional
677-bit event muxes. The record-width exception is a bounded structural audit;
it does not prove that every mux of an allowed width is desirable. Review the
inventory when changing collectors or event routing.

Generated inventory:
`/tmp/cme-phase6-build/default/test/cme/rtl_checks/phase6_structure.txt`.
The separate `@rtl-check` passes all ten Yosys hierarchy/Icarus elaboration
targets. Those smoke tools do not establish timing or replace the loop audit.

The final combined `@all @runtest @fmt @rtl-check` command above exited 0;
`git diff --check` also passed. A fresh full-hierarchy reporting project was
generated successfully from the checkpoint executable with this command:

```sh
/tmp/cme-phase6-build/default/synthesis/xilinx_reports.exe cme-feed-parser \
  -dir /tmp/cme-phase6-reports \
  -part xc7a100tcsg324-1 -clock clock_i:156.25 \
  -full-design-hierarchy true -jobs 1 \
  -path-to-vivado /home/wayne/tools/xilinx/vivado25_install/2025.2.1/Vivado/bin/vivado
```

Artifacts are `/tmp/cme-phase6-reports/cme_feed_parser/cme_feed_parser.v`,
`.xdc`, and `.tcl`. The Verilog contains 11 module definitions and the XDC
constrains `clock_i` to 6.400 ns. This invocation omitted `-run`: it establishes
fresh project generation only, with no synthesis, placement, or routing result.

Vivado is installed outside `PATH` at
`/home/wayne/tools/xilinx/vivado25_install/2025.2.1/Vivado/bin/vivado`.
The observed version is 2025.2.1 (SW Build 6403652). An earlier full-parser run
targeted `xc7a100tcsg324-1`, `clock_i:156.25`, with
`-full-design-hierarchy true -jobs 1`. It failed attempting to write
`/home/wayne/.Xilinx/Vivado/tclapp/manifest.tcl` under the filesystem sandbox;
the wrapper then rejected missing `post_synth_report.txt`. This was not a
successful synthesis run, and its earlier generated RTL is not evidence for
the final checkpoint.

Use the OCaml reporting command documented in
[hardcaml_reports.md](hardcaml_reports.md) to collect fresh full-parser reports
when the tool's cache writes can be supported. Record executable revision,
part, constraint, hierarchy profile, report stage, and fresh artifact paths.
Concurrent aligner/device investigations in that document and
`timing_notes.md` are separate evidence; they do not close full-parser timing.
The 156.25 MHz value in the performance output is the target clock, not a
measured frequency or a claim of physical 10G closure.

## Working-tree handoff

This work overlaps existing Phase 5 edits and concurrent aligner/synthesis
investigation. Preserve the current tree; do not reset to HEAD or drop
untracked files. In particular, `lib/cme/mbp_decoder.ml`, the Phase 6 test
sources, and `docs/phase5_decoding.md` are required source/documentation even
if still untracked. No checkpoint commit was created by this handoff.

Keep Phase 6 open until the enforcing performance alias passes with broader
legal traffic coverage and the remaining device evidence is explicitly
recorded. The first useful pickup task is the padded-layout reproduction and
transfer trace above, not another general decoder rewrite.
