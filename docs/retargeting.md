# Retargeting — the parser closes 156.25 MHz on the deployment part

Working notes on a target error and what it cost. Phases 0–6 measured every
device number on `xc7a100tcsg324-1`, the Arty A7-100T's Artix-7 at speed grade
−1, constrained to the *production* clock of 156.25 MHz. That combination is not
in the plan and does not describe any intended operating point. The deployment
part is an Alveo U50 — `xcu50-fsvh2104-2-e`, Virtex UltraScale+ HBM at speed
grade −2.

Status as of 2026-09-07: **the current tree meets 156.25 MHz on
`xcu50-fsvh2104-2-e` placed and routed, WNS +0.327 ns, zero failing endpoints,
zero SLR crossings.** The validation profile is also closed: `xc7a100tcsg324-1`
at 25 MHz routes at WNS +16.750 ns. Both are recorded under
[the routed results](#the-routed-results); everything functional is green.

This document supersedes `phase7_pickup.md` (deleted) and the device framing in
[phase8_pickup.md](phase8_pickup.md). It does not supersede the *measurements* in
[phase6_notes.md](phase6_notes.md), which remain the durable Artix-7 record.

## The routed results

Both profiles, full parser, `-full-design-hierarchy true`, through
`-place -route`. Reports are in `reports/production/cme_feed_parser/` and
`reports/validation/cme_feed_parser/`.

| | `production` xcu50-fsvh2104-2-e @ 156.25 MHz | `validation` xc7a100tcsg324-1 @ 25 MHz |
| --- | ---: | ---: |
| Period | 6.400 ns | 40.000 ns |
| WNS post-synthesis | +0.340 ns | +22.213 ns |
| WNS post-place | +0.553 ns | +16.318 ns |
| **WNS post-route** | **+0.327 ns** | **+16.750 ns** |
| Worst hold, routed | +0.042 ns | +0.096 ns |
| Failing endpoints | 0 at every stage | 0 at every stage |
| LUTs, routed | 8,727 (1.00%) | 8,383 (13.22%) |
| Flip-flops | 6,003 (0.34%) | 6,001 (4.73%) |
| Block RAM tiles | 11.5 (0.86%) | 11.5 (8.52%) |
| DSPs | 8 x DSP48E2 (0.13%) | 8 x DSP48E1 (3.33%) |

Vivado reports `All user specified timing constraints are met` at all six stages.

**The placer kept the whole design in one SLR unaided.** The routed SLR
connectivity matrix is zero in both directions -- 0 of 23,040 available
`SLR1 <-> SLR0` crossings used. The concern in item 2 below was reasonable but
did not materialise, and no pblock is needed.

The routed worst path moved off the decoder's `collected` counter and onto the
aligner's occupancy signal:

```text
cme_mbp_decoder/cme_byte_aligner/occupied_slot_count_reg[1]_rep/C
  -> cme_mbp_decoder/state_reg[0]/D
  6.055 ns: logic 3.077 ns (50.8%), route 2.978 ns (49.2%), 20 levels
  (CARRY8=2 DSP_*=5 LUT2=2 LUT4=2 LUT5=1 LUT6=7)
```

Two things worth reading off that. The out-of-context post-synthesis estimate put
71% of the delay in routing; routed, it is 49%, so the estimate was pessimistic
rather than optimistic -- which is why place *gained* slack instead of losing it.
And the critical path now terminates in the A1 `occupied_slot_count` cone, so the
re-pricing in item 3 below has a concrete target.

### These are the first numbers from the current tree

The `+0.340 ns` post-synthesis figure in the next section was measured at 22:26
from a netlist where the iterator's output FIFO still carried
`RAM_STYLE="block"`; the `distributed` attribute reached the source at 23:14-23:18.
The two netlists differ -- 8,480 vs 8,661 LUTs, 6,949 vs 6,003 flip-flops -- and
post-synthesis WNS landing on +0.340 ns in both is a coincidence, not a
reproduction. Read the table above as the record and the one below as history.

## The measurement

Same harness, same flow, same clock constraint as every recorded Artix-7 number —
`synth_design -mode out_of_context` + `opt_design`, retiming enabled,
`-full-design-hierarchy true`. Only `-part` differs, and nothing else in the tree
changed between the two columns.

```sh
cd /tmp && <build>/default/synthesis/xilinx_reports.exe cme-feed-parser \
  -dir /tmp/cme-u50-reports \
  -part xcu50-fsvh2104-2-e -clock clock_i:156.25 \
  -full-design-hierarchy true -jobs 1 \
  -path-to-vivado <vivado>/bin/vivado -run
```

> `-part` and `-clock` no longer exist. They were replaced by the single
> `-profile production` / `-profile validation` flag described under
> [the standing rule](#standing-rule); the invocation above is kept verbatim
> because it is what produced the numbers in this table.

| Post-synthesis | `xc7a100tcsg324-1` −1 | `xcu50-fsvh2104-2-e` −2 |
| --- | ---: | ---: |
| Worst setup slack | −10.577 ns | **+0.340 ns** |
| Total setup violation | −34,183 ns | **0.000 ns** |
| Setup failing endpoints | 7,409 | **0** of 14,124 |
| Worst hold slack | +0.191 ns | +0.058 ns, 0 failing |
| Data path delay | 16.691 ns | 6.041 ns |
| — logic | 5.097 ns (31%) | 1.729 ns (29%) |
| — estimated route | 11.594 ns (69%) | 4.312 ns (71%) |
| Logic levels | 23 | 25 |
| LUTs | 8,979 (14.2%) | 8,480 (**0.97%**) |
| Flip-flops | 6,946 | 6,949 (0.40%) |
| Block RAM tiles | 23.5 (17.4%) | 23.5 (**1.75%**) |
| DSP | 8 × DSP48E1 | 8 × DSP48E2 (0.13%) |

Vivado's own verdict on the U50 run: `All user specified timing constraints are
met.`

The worst path is the same cone in both, launching from the decoder's `collected`
counter:

```text
Artix-7   cme_mbp_decoder/collected_reg[6]/C   -> cme_mbp_decoder/skip_left_reg[0]/D
UltraScale+ cme_mbp_decoder/collected_reg[12]/C -> cme_mbp_decoder/event_bits_reg[673]/D
  25 levels (CARRY8=6 LUT2=1 LUT3=1 LUT4=3 LUT5=4 LUT6=10)
```

Reports are in `/tmp/cme-u50-reports/`, which will not survive a reboot. The
tables here are the durable copy.

### The RTL was already portable

The generated `cme_feed_parser.v` instantiates **zero** device primitives — no
`RAMB*`, no `DSP48*`, no `CARRY4`, no `FDRE`. Everything is inferred. The
retarget is one command-line flag and required no source change whatsoever.

A secondary benefit: `hardcaml_xilinx_reports`' `Primitive_group` taxonomy is
documented as UltraScale (ug974), which is why every target in
`synthesis/xilinx_reports.ml` passes `~primitive_groups:[]` and falls back to
parsing the standard utilization report. On the deployment part those queries
would populate correctly. See [hardcaml_reports.md](hardcaml_reports.md).

## What the plan actually said

The target error is a drift in measurement, not a mistake in the plan. From
[cme_mdp3_10g_parser_plan.md](cme_mdp3_10g_parser_plan.md):

> The production target clock is 156.25 MHz. The same synchronous RTL may run at
> the Arty's 25 MHz `eth_tx_clk` for functional testing; no CDC is inserted
> between the UDP shim and parser because both application interfaces use that
> clock.

> Device-specific place-and-route timing closure is deferred until selection of
> the 10GbE board shell.

> On Arty, send synthetic MDP payloads inside UDP datagrams and verify packet,
> update, diagnostic, and late-network-error counters. Treat this as **functional
> acceptance only**; do not derive a 10G throughput claim from the MII test.

Two arithmetic consequences of holding the Arty to 156.25 MHz:

**Phase 7 never needed any of the timing work.** At −16.428 ns on a 6.400 ns
period the pre-D1 baseline ran at roughly 43.8 MHz — already 1.75× the 25 MHz
application clock Phase 7 specifies. The current tree at −10.577 ns is roughly
58.9 MHz. Four rounds of RTL surgery moved the Arty from *meets Phase 7 with 75%
margin* to *meets Phase 7 with 135% margin*.

**The Arty cannot exercise the properties the timing work defends.**
`hardcaml_networking` is 4-bit MII at 25 MHz, i.e. 100 Mb/s. A 64-bit parser at
25 MHz has 1.6 Gb/s of payload capacity, so the link fills roughly 6% of the
available beats. The zero-stall and full-rate invariants that A1, A2 and the
third aligner slot exist to preserve are unobservable on that board by
construction.

**The tell was in the reports the whole time.** The standalone `byte_aligner` —
800 LUTs, seven logic levels, the smallest real module in the design — measured
−0.080 ns post-route wrapped and −0.481 ns standalone on that part at that clock
(recorded in [hardcaml_reports.md](hardcaml_reports.md)). When the simplest leaf
sits at the device's edge, a 9,000-LUT design at 23 levels is not going to close
there no matter how it is written. That reading was available before D1 started.

## What the campaign actually bought

This is the part that does *not* support a simple "wasted effort" reading.
Measuring the same design on both parts gives a scale factor for this design's
mix of logic and interconnect:

```text
logic  5.097 / 1.729 = 2.95x
route 11.594 / 4.312 = 2.69x
total 16.691 / 6.041 = 2.76x
```

Applying the split ratios to each recorded revision's logic and route split
projects the Artix-7 progression onto the deployment part:

| Revision | A7 data path | A7 WNS | Projected U50 data path | Projected U50 WNS |
| --- | ---: | ---: | ---: | ---: |
| Baseline | 22.178 ns | −16.428 ns | ~8.02 ns | **~−1.68 ns** |
| After D1 | 21.074 ns | −15.324 ns | ~7.66 ns | ~−1.32 ns |
| After A1+A2 | 21.391 ns | −15.031 ns | ~7.64 ns | ~−1.30 ns |
| After D3 | 16.691 ns | −10.577 ns | 6.041 ns | **+0.340 ns** (measured) |

These are projections from one measured scale factor, not measurements. Only the
last row is real. Read them as ordering and magnitude, not as slack figures.

Three things follow, and the middle one is uncomfortable:

1. **The baseline would have failed on the U50 too**, by something like 1.7 ns.
   The timing work was necessary. The goal was right.
2. **It was priced against a 16.4 ns deficit when the real deficit was ~1.7 ns.**
   That is roughly a 10× inflation, and it is what justified compensations a
   1.7 ns problem would never have paid for.
3. **D3 is what closed the design.** On the projection it is worth ~1.6 ns of the
   ~2.0 ns recovered; D1 is worth ~0.36 ns; A1+A2 is worth ~0.02 ns of *worst*
   slack. A1+A2's real contribution was population-level — it halved total setup
   violation by removing a long path shared by thousands of endpoints — which
   matters for routability at place-and-route but is not what closed the worst
   path.

## Change-by-change

| Change | What it is | Verdict |
| --- | --- | --- |
| **D1** | Register header-derived expressions in the decoder on the edge that latches the header | **Keep.** +50 flops, −1.6 ns logic, no latency, no semantic change, device-independent. |
| **D3a** | Rewrite `position + consume_count + bytes <= body_size` as `consume_count <= room - bytes` so the late signal meets the product at a comparator, never at an adder | **Keep.** DSP48E2 has the same post-adder fusion as DSP48E1, so the trap is live on the deployment part. |
| **D3b** | Write `skip_left <-- bytes` unconditionally and gate only the state transition | **Keep.** Same reason — DSP `OPMODE` folding is not Artix-specific. |
| **A1** | Non-greedy aligner `ready` reading `occupied_slot_count` directly, plus a third slot | **Re-price.** The rule is right; the compensation is what needs re-measuring. |
| **A2** | Non-greedy `Elastic_fifo` admission plus depth compensation (ingress 64→65, iterator output FIFO 2→3) | **Two separable problems; see below.** |

D1 and D3 are keepers on their own merits and would have been correct against any
target. They also brought `test/cme/mbp_decoder/mbp_decoder_invariant_tests.ml`
and the `--` naming pass, both of which are independently valuable — the naming
pass is what corrected D3's diagnosis.

### The third aligner slot is not optional and not spare

It is neither headroom nor burst absorption. With two slots and a non-greedy
`ready`, occupancy oscillates 1 → 2 → 1, and in every `count == 1` cycle the
window holds only the head, so `available <= 8`. That starves `packet_header`'s
twelve-byte collect and both `max_consume:15` consumers, and the stage would
admit a beat every other cycle and fail the zero-stall half of the gate.

So A1 and `slot2` stand or fall together; evaluating the slot on its own merits
is not an available option. What *is* worth noting is that adding it invalidated
the standalone aligner closure claim — it widens `next_head` to a three-way mux
and adds 142 flops — and nobody re-measured. See
[timing_notes.md](timing_notes.md), which has been corrected.

### The two things worth calling damage — both corrected

Corrected 2026-09-07. The diagnosis below is kept because it is the reason the
fixes look the way they do.

**1. Twelve block RAM tiles bought by accident.** The iterator's output FIFO going
depth 2 → 3 pushed its `reg [1078:0]` backing array from `[0:0]` to `[0:1]`,
crossing Vivado's block-memory inference threshold. Block RAM more than doubled,
11.5 → 23.5 tiles, to hold two 1,079-bit `Message_item`s. This is a side effect of
a depth change, not a timing decision anybody made.

*Fixed.* `Elastic_fifo.create` now takes `?ram_attributes`, passed straight to
`Fifo.create` (whose own default remains block RAM), and the iterator's output
FIFO passes `Rtl_attribute.Vivado.Ram_style.distributed`. The generated
`cme_sbe_message_iterator.v` carries `(* RAM_STYLE="distributed" *)` on that array,
and `cme_mdp3_feed_parser.v` now holds exactly one distributed and two block
arrays. **The tile count itself is not yet re-measured** — that needs a Vivado run
on the cluster, so 23.5 → ~11.5 remains a projection until item 4 below is closed.

*Why this is a timing change and not only an area one.* The read is asynchronous
out of the array — `assign memory = signal_multiport_mem[signal_reg_5]` — through
a write-before-read bypass mux and into a register, and that shape is identical
under either style. What changes is physical. At `block`, a 1,079-bit
`Message_item` is far wider than a BRAM port, so one logical word is split across
roughly twelve hard macros in BRAM columns and all 1,079 bits must be gathered
back to a single consumer. At `distributed` the two entries sit in SLICEM LUTRAM
in the general fabric, placeable beside the logic that reads them. With 71% of the
measured 6.041 ns an unplaced routing estimate, and with the SLR risk in item 2 of
[what is actually left](#what-is-actually-left), taking twelve hard macros out of
a 6.400 ns path is the part worth having. The roughly 1,079 LUTs it costs are the
price, and at 0.97% utilisation they are not a constraint on anything.

That is reasoning, not a measurement, and it can go the other way: LUTRAM's
asynchronous read is LUT delay in the general fabric, so if the placer was already
finding a good BRAM placement the swap could be neutral or slightly worse in logic
delay. The thing to read off the next cluster run is therefore **WNS against
`RAM_STYLE`**, not the tile count on its own.

The two arrays left on block RAM are deliberate: ingress at 138 × 64 is a
legitimate BRAM, and event at 677 × 15 is a judgement call nobody has measured.
The new argument makes either one a one-line change if the placed report says so.

**2. `Elastic_fifo` lost a capability, and the tests assert its absence.** Under
non-greedy admission a depth-1 elastic FIFO has no full-rate pass-through at all:
push and pop in the same cycle need a slot that is already free. That is a
degradation of a *reusable primitive*, and the suites were rewritten to encode it
as the specification:

```ocaml
(* ingress_fifo_unit_quickcheck_tests.ml *)
if depth > 1 then assert (result.simultaneous > 0)
else assert (result.simultaneous = 0)      (* asserting the ABSENCE *)
```

plus the continuous-traffic cases moving from depth 1 to depth 2 in three files.
This is self-locking: reverting A2 now means reverting tests that read as spec.

*Fixed.* Admission is now a configuration. `Elastic_fifo.create` takes
`?greedy_admission` alongside the existing `?fallthrough`, defaulting to `false`,
and `Event_fifo` / `Ingress_fifo` thread it through. Greedy restores the original
`~:full |: pop` readiness — the pre-A2 expression, recovered from `57a7be3` rather
than redesigned — so full-rate replacement is available at every depth including 1,
at the cost of input readiness being combinationally transparent to the downstream
ready. **No parser call site changes**, so every instance keeps non-greedy
admission and the +0.340 ns above is untouched by inspection.

The suites now cover both modes instead of asserting an absence: the readiness
model in `stream_scenarios.ml` and `event_fifo_testbench.ml` takes the configured
mode, and each suite gained greedy cases at depth 1 — including continuous-traffic
depth 1, which is exactly the capability the old assertion said was gone. The
depth-1 non-greedy `simultaneous = 0` assertion survives, but it now reads as one
half of a configuration matrix rather than as the specification.

## The eight-cycle bound is self-imposed and over-tight

The gate in `test/cme/cme_feed_parser/phase6_performance.ml` enforces
`latency_max <= 8`, which at 156.25 MHz is **51.2 ns** from accepting the final
byte an entry requires to asserting `event_valid_o`. Eight of the fourteen cases
measure exactly 8, so the gate currently has **zero** forward-latency headroom,
and that is the single constraint that ruled out skid buffers throughout Phase 6.

Nothing external requires 51.2 ns. For calibration, AlgoLogic markets its Alveo
CME feed handler as *"receives MDP3.0 market data, rapidly processes, updates,
and transfers Best Bid Offer (BBO) data in less than 100 nanoseconds"*. Treat
that as a marketing figure with unstated measurement conditions, but as an
order-of-magnitude reference it is useful, and it is roughly **twice** our
internal budget.

It is also not the same measurement. Their 100 ns is wire-to-wire for a whole
feed handler — MAC, UDP, parse, and book update. Ours is parser-internal, one
stage of that. Budgeting a comparable envelope:

| Stage | Rough cost |
| --- | ---: |
| 10G MAC RX, cut-through | ~15–25 ns |
| IP/UDP strip and payload packing | ~2–3 cycles, 13–19 ns |
| **Parser (this design)** | **remainder, ~55–70 ns ≈ 9–11 cycles** |
| Book update / BBO | not in scope for v1 |

So the defensible relaxation is roughly **8 → 10 or 11 cycles**, not 8 → 15.
That is one to three full register slices, since a skid buffer registers both
directions and costs exactly one cycle of forward latency each.

### What that unlocks

[phase6_notes.md](phase6_notes.md) rejected Option B, skid buffers, on two
grounds. **Both are now void:**

1. *"Four boundaries is +4 cycles against a gate with at most one to spare."*
   Void if the gate moves to 10–11.
2. *"Cutting a 33-level path once leaves roughly 16 levels (≈11 ns), still short
   of 6.400 ns."* That is Artix-7 arithmetic. On the U50 the entire 25-level path
   is 6.041 ns; half of it is ~3 ns. Void on the correct part.

This matters because a skid buffer breaks the ready chain *properly* — without a
third aligner slot, without changing `Elastic_fifo`'s contract, and without the
twelve block RAM tiles. The pivot available here is to **spend latency headroom
instead of area and primitive-contract changes**, which is a straight
improvement on the A1/A2 trade.

### But not yet

The design currently meets timing. Do not spend the latency budget to fix a
problem that is closed. The right role for that headroom now is as the
**contingency fund for place-and-route**: +0.340 ns is about 5% of the period,
and an SLR crossing or a bad placement will consume it instantly. If P&R opens a
gap, one skid buffer at the worst boundary is a cheaper and cleaner answer than
another round of arithmetic rewriting — and unlike the A-class changes it can be
reverted without touching a primitive's contract.

Relaxing the gate is a plan change and should be recorded as one in
[cme_mdp3_10g_parser_plan.md](cme_mdp3_10g_parser_plan.md), with the budget table
above as its justification, before any skid buffer is written.

## What is actually left

1. ~~**Place and route the full parser on `xcu50-fsvh2104-2-e`.**~~ **Done:
   +0.327 ns routed, 0 failing.** No hand-rolled Tcl was needed -- `-place -route`
   on the harness covers it, so the recipe in
   [phase8_pickup.md](phase8_pickup.md) is redundant.
2. ~~**Watch the SLR.**~~ **Done: zero crossings, no floorplan required.** The
   placer kept all 8,727 LUTs inside one SLR without being asked, so the pblock
   argument in [timing_notes.md](timing_notes.md) never has to be settled.
3. **Re-baseline the A-class changes on the U50 before reverting them.** The
   projection says A1+A2 bought ~0.02 ns of worst slack but halved total
   violation. Whether the third slot, the ingress depth bump and the
   `Elastic_fifo` contract change are still worth their cost is answerable by
   synthesising the reverted tree on the correct part. Reverting on the
   projection alone would repeat exactly the error this document is about:
   changing RTL against an unmeasured target.
4. ~~**Fix the block RAM side effect** -- `~ram_attributes` on the iterator output
   FIFO.~~ **Done and verified, and the WNS question is answered: LUTRAM cost
   nothing.** 23.5 -> 11.5 tiles on both parts, with 376 LUTs picking up the
   distributed array. On the deployment part the pre-attribute netlist synthesised
   at +0.340 ns and the post-attribute netlist synthesises at +0.340 ns and routes
   at +0.327 ns, so getting twelve hard macros off the 6.400 ns path was free in
   logic delay rather than paid for. The worst path does not touch either array.
5. ~~**Establish the Arty validation profile.**~~ **Done: +16.750 ns routed at
   25 MHz**, 0 failing. That leaves a 23.25 ns data path, so the parser would run
   at roughly 60 MHz on the Arty -- 2.4x what Phase 7 asks of it. The profile is
   now a flag rather than a convention; see the standing rule.

## Standing rule

Every recorded device number must name its part *and* its clock, and the two
profiles are:

| `-profile` | Part | Clock | What it establishes |
| --- | --- | --- | --- |
| `production` | `xcu50-fsvh2104-2-e` | 156.25 MHz | 10G timing. The only profile that can. |
| `validation` | `xc7a100tcsg324-1` | 25 MHz | Phase 7 board acceptance. Establishes nothing about throughput. |

A number without both is not evidence. Constraining the validation part to the
production clock measures a device nobody deploys at a frequency it will never
run, and this project spent four revisions doing it.

**The rule is now enforced by the tool rather than by this document.**
`Report_support.Profile` in `synthesis/report_support.ml` holds the table above,
and `report_command` passes empty parameters for the library's `-part` and
`-clock` flags before overwriting both fields from `-profile`. Those two flags
are therefore absent from `xilinx_reports.exe -help`, and the selected part and
clock are printed at the head of every invocation and again beside every report
summary, so a pasted number carries its own provenance.

Deliberately, there is no override. The pair coming apart is the entire failure
this guards against, and an escape hatch is that failure with an extra step. A
third operating point should be a third constructor in `Profile.t`, named and
justified, not a flag.
