# Phase 6 pickup — place and route, because RTL has run out

> **Superseded on device framing; see [retargeting.md](retargeting.md).** Every
> number below is `xc7a100tcsg324-1` at 156.25 MHz — the validation part held to
> the production clock, which is not an operating point this project targets. The
> same tree meets 156.25 MHz on the deployment part `xcu50-fsvh2104-2-e` with
> **WNS +0.340 ns and zero failing endpoints**, so "RTL has run out" was true for
> a reason other than the one assumed here: the RTL was fine and the part was
> wrong. The place-and-route intent below is still the right next step — run it on
> the U50. The Tcl pattern, the verification list, and the `report_design_analysis`
> / `report_high_fanout_nets` guidance are all part-independent and still apply.

Working tree: branch `bpurtell/cme`, worktree `/home/wayne/devel/jane/cme`.
Continue from the current tree **including untracked files** — `lib/cme/mbp_decoder.ml`,
`test/cme/mbp_decoder/mbp_decoder_invariant_tests.ml`, `docs/phase5_decoding.md`,
`docs/phase6_notes.md`, `docs/timing_notes.md`, `docs/phase6_verification.md` and the
Phase 5/6 test sources are required and uncommitted. Do not reset to HEAD or drop
untracked files.

## Read first

- `docs/phase6_notes.md` — **start here**, specifically "Measured effect of D3" and
  "What is left after D3". It records what D3 turned out to be, which is not what
  the since-deleted `phase7_pickup.md` predicted.
- `docs/timing_notes.md` — how operators map to LUTs, the two rules D3 added (never put
  a late signal opposite a multiply in an adder; never gate a wide datum with a late
  condition), and the `--` precedence trap.
- `docs/hardcaml_reports.md` — the reporting command and its evidence limits.
- `docs/cme_mdp3_10g_parser_plan.md` — authority for acceptance (lines 616–621).

## Where things stand

Everything except device timing is green: functional conformance, the enforcing 14-case
`@performance-check`, formatting, the flattened structural audit, and all ten RTL smoke
targets. D1, A1, A2 and D3 are applied and measured.

| | Baseline | After D1 | After A1+A2 | After D3 |
| --- | ---: | ---: | ---: | ---: |
| Worst setup slack | −16.428 ns | −15.324 ns | −15.031 ns | **−10.577 ns** |
| Total setup violation | −76,133 ns | −68,716 ns | −36,391 ns | **−34,183 ns** |
| Setup failing endpoints | 7,177 | 7,226 | 7,451 | 7,409 |
| Data path delay | 22.178 ns | 21.074 ns | 21.391 ns | 16.691 ns |
| — logic | 7.136 ns | 5.507 ns | 9.687 ns | **5.097 ns** |
| — estimated route | 15.042 ns | 15.567 ns | 11.704 ns | 11.594 ns |
| Logic levels | 33 | 29 | 25 | 23 |
| DSP48E1 on the path | 0 | 0 | 2 | **0** |
| Slice LUTs | 8,014 | 8,027 | 8,848 | 8,979 |
| Flip-flops | 7,609 | 7,659 | 6,943 | 6,946 |
| Block RAM tiles | 11.5 | 11.5 | 23.5 | 23.5 |
| DSP48E1 | 9 | 9 | 9 | 8 |

Worst hold slack +0.191 ns, 0 failing endpoints. Reports for the last column are in
`/tmp/cme-d3-paths-final/` (disposable; the durable copy is in `phase6_notes.md`).

**Two things changed in kind with D3.** The worst path no longer contains a hard macro —
no DSP48E1, no block RAM, just LUTs and five CARRY4s — so nothing on it is delay you
cannot move. And its logic delay is 5.097 ns against a 6.400 ns period, so **69% of the
16.691 ns is an unplaced routing estimate on a design at 14% LUT utilisation with no
placement pressure**. `timing_notes.md` already records what that estimate is worth: on
the standalone aligner, 77% of the path was net delay, replication recovered 61% of the
gap, and the remainder was distance rather than depth. There is no reason to expect the
full parser's estimate to be more honest than that one was.

## The intent

**Place and route the full parser, once.** This is item 3 on every version of this list
since Phase 6 opened, and it is now the only item that can produce new information.

The harness (`synthesis/xilinx_reports.exe ... -run`) emits Verilog, XDC and Tcl and runs
`synth_design -mode out_of_context` + `opt_design` — a hand-rolled run would execute the
*identical* `synth_design`. What it does not emit is `place_design`, `phys_opt_design`
and `route_design`, and those are the whole point here. Roll the Tcl by hand against the
harness-generated `cme_feed_parser.v` / `.xdc`; the pattern that produced the readable
path reports for D3 is in this session's scratch and is four lines long:

```tcl
create_project -in_memory -part xc7a100tcsg324-1
read_verilog [file join $root cme_feed_parser.v]
read_xdc     [file join $root cme_feed_parser.xdc]
set_property top cme_feed_parser [current_fileset]
auto_detect_xpm
set_param synth.elaboration.rodinMoreOptions "rt::set_parameter synRetiming true"
synth_design -top cme_feed_parser -mode out_of_context
opt_design
place_design
phys_opt_design
route_design
report_timing -setup -max_paths 12 -nworst 1 -path_type full -input_pins -file ...
report_timing_summary -file ...
report_utilization -file ...
```

Expect it to take considerably longer than the ~4 minutes a synth-only run takes. Read
`report_design_analysis` and `report_high_fanout_nets -timing -load_types` alongside the
timing report; `timing_notes.md` records that `FANOUT` is a `report_design_analysis`
column and **not** a net property, and that `get_nets -filter {FANOUT > 100}` silently
matches nothing while `phys_opt_design -force_replication_on_nets` then hard-errors on
the empty list.

**What the answer changes.** If placed routing lands near the logic delay, the design is
close and the remaining work is fanout replication and possibly floorplanning — note that
`timing_notes.md` rejected pblocks on portability grounds for the standalone aligner, and
that argument is weaker for a whole-design floorplan but has not been revisited. If
placed routing stays near 11 ns, the path is genuinely long and the next RTL lever is the
one named at the end of `phase6_notes.md`: the `collected -> combined_root -> required ->
count` cone, ten levels of muxes and comparators between the collected counter and the
consume decision, most of it a function of registers and in principle evaluable on the
edge that writes them. That is D1's trick against a much larger mirror and it should not
be attempted on an unplaced estimate.

## Constraints that still bind

Both acceptance criteria from the plan are unchanged and the 14-case gate enforces them.
Eight of the fourteen cases measure `latency_max = 8` — **zero** forward-latency headroom
— and `input_stalls` must stay 0 on all fourteen. A pipeline stage in the forward path is
still ruled out under the gate as written; a register whose value becomes valid on the
same edge as its source is not. **Do not reach for skid buffers** without changing the
gate first — that is a plan change, not an implementation choice.

> The gate itself is now under review. Eight cycles at 156.25 MHz is 51.2 ns of
> parser-internal latency, which
> [retargeting.md](retargeting.md#the-eight-cycle-bound-is-self-imposed-and-over-tight)
> argues is tighter than anything external requires; a defensible relaxation is
> 10–11 cycles, which buys one to three register slices. Both grounds on which
> `phase6_notes.md` rejected skid buffers are void — the latency ground if the gate
> moves, and the "cutting the path once still leaves ~11 ns" ground on the correct
> part, where the whole path is 6.041 ns. This does not change what to do next:
> the design meets timing, so the latency budget is contingency for
> place-and-route, not something to spend now.

## Verification

The suites that guard the timing work, all currently passing:

- `test/cme/byte_aligner/byte_aligner_invariant_tests.ml` — the slot-byte-count mirrors,
  plus the structural rule that `ready_o` has no combinational path from
  `consume_count_i` / `consume_valid_i`.
- `test/cme/event_fifo/event_fifo_unit_quickcheck_tests.ml` — the same shape for
  `event_ready_o` against `event_ready_i` at depths 1, 3 and 16.
- `test/cme/mbp_decoder/mbp_decoder_invariant_tests.ml` — new with D3. Every `fits_*` and
  `fits_after_consume_*` node against a model of the bound written from the plan, on
  every cycle of ten traffic shapes; `room` against `body_size - position` as a signed
  value; and two structural checks — no `headroom_*` cone may contain `consume_count`,
  and no adder anywhere in the decoder may have both `consume_count` and a multiply in
  its cone. Mutation-tested; the second structural check is the only thing that catches a
  reversion to the `next_position + bytes` form.

The 14-case performance table is the real check. Baseline to beat, all 14 cases:
`input_stalls=0`, `latency_max` 7 or 8, `over_8=0/N`. It has been byte-for-byte identical
across D1, A1+A2 and D3; keep it that way.

```sh
source ./env.sh
./scripts/with-switch.sh dune build --build-dir /tmp/cme-d4-build --display quiet @all @runtest @fmt @rtl-check
./scripts/with-switch.sh dune build --build-dir /tmp/cme-d4-build --display quiet @performance-check
```

Synthesis-only re-run, for revision-to-revision deltas:

```sh
cd /tmp && /tmp/cme-d4-build/default/synthesis/xilinx_reports.exe cme-feed-parser \
  -dir /tmp/cme-d4-reports \
  -part xc7a100tcsg324-1 -clock clock_i:156.25 \
  -full-design-hierarchy true -jobs 1 \
  -path-to-vivado /home/wayne/tools/xilinx/vivado25_install/2025.2.1/Vivado/bin/vivado \
  -run
```

Drop `-run` to emit the Verilog only; that is the cheap way to confirm an edit is
RTL-neutral by hashing `cme_feed_parser.v`. The revision measured above is
`47b518e732069ce666bedaa3ca1041f71e4a17b16597aa5ad60d814ac6445d97`, from
`mbp_decoder.ml` at
`0259564126ddb7603485ac8d425af0353f0bb243e868a987d4357421a7c9e426`, and the tree as it
stands reproduces both. Note that the harness's own report only prints worst setup and
hold slack; the readable path listing comes from a separate `report_timing` run against
the same generated sources.

## Secondary open items

1. **The standalone `byte_aligner` closure is stale.** `timing_notes.md` claims the
   aligner meets 6.400 ns through the `validation/` harness; that was measured with two
   slots. A1 adds a third, widens `next_head` to a three-way mux, and adds 142 flops. The
   claim should be re-measured before it is repeated. A placed run of the whole parser
   partly subsumes this, but the harness measures the module in isolation and is cheap.
2. **Block RAM is 23.5 tiles and twelve of them hold two `Message_item`s.** The iterator's
   output FIFO went depth 2 → 3 with A2, its backing array went `[0:0]` → `[0:1]`, and
   Vivado infers block memory at two words. The remedy is one `Fifo.create` RAM-attribute
   argument (`Ram_style.registers` restores the pre-A2 implementation for about 2,100
   flops, 1.7% of the device; `distributed` is the other option). Deliberately not
   applied — a RAM-style choice has its own timing consequences and deserves its own
   measurement. Utilisation at 17.4% is not pressing, but a placed run is the right time
   to find out whether those tiles are hurting placement.
3. **`sbe_message_iterator.ml` still carries no `--` names.** The decoder's naming pass
   is what corrected D3's diagnosis; if a placed run puts the worst path back in the
   iterator, name it before analysing it.

Note the `/tmp` report directories referenced in the docs won't survive a reboot — the
tables and hashes in `phase6_notes.md` are the durable copy.
