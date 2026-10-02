# Timing notes

How Hardcaml operators map to FPGA logic, and the record of the `byte_aligner`
timing work. Working notes rather than an acceptance requirement; see
[hardcaml_reports.md](hardcaml_reports.md) for the report flow and
[retargeting.md](retargeting.md) for the parts and clocks of record.

> **Read [retargeting.md](retargeting.md) first.** Every measurement in this
> document was taken on `xc7a100tcsg324-1` at 156.25 MHz — the *validation* part
> held to the *production* clock, which is not an operating point this project
> targets. The full parser meets 156.25 MHz on the deployment part
> (`xcu50-fsvh2104-2-e`, WNS +0.340 ns). The operator-to-LUT material below is
> device-independent and still correct; the slack figures are Artix-7 numbers and
> should not be read as closure evidence for anything.

Status as of 2026-09-07: **the standalone `byte_aligner` closure claim is
withdrawn.** An earlier revision of this document said the aligner "meets
6.400 ns on `xc7a100tcsg324-1`". That was contradicted by this project's own
recorded post-route figures — −0.080 ns wrapped and −0.481 ns standalone, in
[hardcaml_reports.md](hardcaml_reports.md#recorded-aligner-result) — and it was
measured with **two** slots, before Phase 6 added a third. It has not been
re-measured since. Do not repeat the claim; the number that matters is the
full-parser one on the deployment part.

## How operators map to LUTs

A `&:` in Hardcaml creates one node in a `Signal.t` DAG. It is not a gate and it
is not a logic level. Synthesis discards that structure almost immediately:

1. Elaborate to generic gates.
2. Optimize into an AIG, structurally hash, rewrite. Operator nesting is
   destroyed here - `(a &: b) &: c` and `a &: (b &: c)` become the same graph.
3. Technology map. This is cut-based: for each AIG node the mapper enumerates
   K-feasible cuts (subgraphs with at most K distinct boundary inputs) and picks
   a cover minimizing depth, then area. On 7-series K=6, because a LUT6 is a
   64-bit truth table implementing *any* Boolean function of 6 inputs.

The rule that follows:

> LUT levels are set by the number of distinct signals in the logic cone, not by
> the number of operators.

```
a &: b &: c &: d &: e &: f            5 ops, 6 inputs  -> 1 LUT,  1 level
(a &: b) |: (c &: d) |: ~:(e &: f)    5 ops, 6 inputs  -> 1 LUT,  1 level
a &: b &: ... &: t                   19 ops, 20 inputs -> 4 LUTs, 2 levels
```

Depth for a wide reduction is `ceil(log6 N)`; 36 inputs is still 2 levels.
Xilinx also has escapes past 6 inputs costing far less than a full LUT delay:
`MUXF7`/`MUXF8` combine adjacent LUTs into 7/8-input functions, `LUT6_2` gives
two 5-input functions sharing inputs, and `CARRY4` handles adders and
comparators far faster than a LUT tree.

Consequences for how we write these modules:

- Do not restructure `&:`/`|:` chains for timing. It does nothing. Write them
  for readability. This was confirmed empirically below.
- Do watch encoders, popcounts, variable-vs-variable comparators, subtractors,
  and how many sit in series between two registers.
- Constant comparisons (`<=:. 2`, `==:. 0`, `<>:. 0`) fold into a single LUT and
  are near-free. Variable comparisons (`requested <=: available`) are not. These
  two forms sit adjacent in `consume_ready` and look symmetric in the source;
  they are not.
- `mux2` on a wide vector costs area, not depth - it is bit-parallel, one level
  per bit regardless of width. The arrival time of the *select* is what matters.
- Name signals with `--`. Timing reports name flops, and an unnamed design
  reports as `signal_reg_4_reg[54]`, which is unreadable. See below.
- **Never put a late signal on one side of an adder whose other side is a
  multiply.** Vivado fuses `a * b + c` into a single DSP48E1 using its post-adder,
  so `c` enters at the `C` port and pays the whole DSP delay - about 2 ns on this
  part, which no placement recovers. Rearranging the same comparison so the late
  signal meets the product at a *comparator* instead costs nothing and removes
  the DSP from its cone. This is what D3 did in
  [phase6_notes.md](phase6_notes.md); it took 4.3 ns of DSP delay off the
  decoder's worst path.
- **Do not gate a wide datum with a late condition when only control needs
  gating.** In the Always DSL a conditional assignment becomes a mux on the
  register's *data*, and Vivado will fold a mux on a DSP output into that DSP's
  `OPMODE` - which means the mux select arrives at a DSP pin and pays DSP delay
  again. If the datum does not actually depend on the condition, write it
  unconditionally and gate only the state transition.

## What moved the aligner's timing

Measured on `xc7a100tcsg324-1` at 6.400 ns (156.25 MHz) through the pin-reduction
harness in `validation/`, with **two** slots. Both caveats matter: the part and
clock are the wrong pairing (see [retargeting.md](retargeting.md)), and Phase 6
has since added a third slot, widening `next_head` to a three-way mux and adding
142 flops.

| Stage | WNS | Levels | Logic | Net |
| --- | --- | --- | --- | --- |
| Baseline | -0.31 ns | 7 | 1.52 ns | 5.07 ns |
| After `phys_opt_design` replication | -0.12 ns | 7 | 1.39 ns | 4.86-5.18 ns |
| After registering the slot byte counts | -0.08 ns wrapped, -0.48 ns standalone | 6 | - | - |

The last row is the corrected figure from
[hardcaml_reports.md](hardcaml_reports.md#recorded-aligner-result); an earlier
revision of this table recorded it as "passes", which the post-route runs do not
support. Registering the slot byte counts is still the change that mattered — it
removed the priority encoders from the head of every failing path and made the
design smaller — but it did not close 156.25 MHz on that part, and the two-slot
result no longer describes the module as built.

Two findings drove this, and neither was logic depth.

**Routing dominated, not logic.** At baseline, 77% of the path was net delay.
The tell was a path with *fanout 11* still carrying 4.86 ns of routing - about
0.6 ns per hop. Fanout replication fixed the load component and got 61% of the
gap; what remained was distance, not depth.

**The critical path launched from a single bit.** With `--` naming applied, all
ten worst paths launched from `slot1_reg[66]`, which is `tail.beat.keep[2]`:

```
tail.keep --> byte_count --> tail_available --> stored_available --> available
          --> consume_ready --> consume --> pop_head --> pop_tail --> retained
          --> next_slot0 --> slot0.D
```

`byte_count` sat at the head of every failing path, so everything downstream
waited on it.

### The fix: registered slot byte counts

`byte_count` is a **priority encoder**, not a popcount - it returns the index of
the highest set bit plus one, which equals the byte count only because the input
contract guarantees contiguous low lanes. (Earlier drafts of this document called
it a popcount; that was wrong.)

It was being evaluated from the *registered* slot, i.e. in the cycle that reads
the slot. `slot0_bytes` / `slot1_bytes` now hold the count in registers updated
by muxes mirroring `next_slot0` / `next_slot1`, so it is evaluated in the cycle
that *writes* the beat, where there is slack.

This adds **no latency** - `<slot>_bytes` becomes valid on exactly the same edge
as `<slot>` - and it made the design *smaller*:

| | before | after |
| --- | --- | --- |
| Depth, cells (yosys) | 15 | 12 |
| Depth, LUT delays (yosys) | 9 | 8 |
| FDRE | 361 | 353 |
| Estimated LCs | 909 | 797 |

Adding 8 flops removed 16: with `remaining`, `tail_available` and the
`placed_tail` mux select all reading the counts, nothing reads `slot0.keep` or
`slot1.keep` any more, so both 8-bit keep fields go dead along with both priority
encoders. **The raw keep masks are no longer available in the slots** - anything
downstream needing them must reconstruct from the count.

The correctness risk is the mirror silently diverging, which is invisible at the
port boundary until a specific beat pattern hits.
`test/cme/byte_aligner/byte_aligner_invariant_tests.ml` asserts
`<slot>_bytes = byte_count <slot>.keep` every cycle over seeded random traffic,
with the model written from the spec rather than reusing the RTL function. It was
mutation-tested (flipping `retained ==:. 1` to `==:. 0` in the slot1 mirror is
caught at cycle 2). **Any change to `next_slot0` / `next_slot1` / `next_slot2`
must be mirrored in the count muxes.**

Phase 6 added the third slot and its `slot2_bytes` mirror for the non-greedy
`ready` rule; see [phase6_notes.md](phase6_notes.md). The window is still two
beats - slot2 is storage behind it - so the mirror argument is unchanged in kind,
only wider. The invariant suite covers all three slots, and it now also checks
structurally that no combinational path runs from `consume_count_i` /
`consume_valid_i` to `ready_o`, which is the one property that would pass every
behavioural test and fail only in static timing analysis.

`mbp_decoder.ml` got the same treatment in D3 and it changed the diagnosis, not
just the readability: every state register and every named net in it now carries
its source name, and the worst path that read as `signal_reg_51_reg[6] ->
signal_reg_48_reg[0]` reads as `collected -> skip_left`, with the cells between
them named after the expressions that built them. The conclusion drawn from the
unreadable version - that the decoder's `block *: count` products were the
problem - was wrong. They were standing still; `consume_count` was being routed
through them. One Vivado run bought that.

### What was not the problem

The `&:` cascades. `active`, `valid`, `consume`, `pop_head`, `ready` and `push` -
six named boolean expressions - accounted for roughly 3 LUTs on a 7-level path.
`active = en_i &: ~:(reset_i)` does not survive as logic at all; it is absorbed
into the CE/reset pins of the flops it feeds.

## Method notes

### The `--` operator binds tighter than `&:`

`--` starts with `-`, so it sits at OCaml's `+`/`-` precedence level, above every
operator starting with `&`, `|`, `<`, `>` or `=`. That makes

```ocaml
~:(msb headroom) &: (consume_count <=: headroom) -- "fits"     (* wrong *)
(~:(msb headroom) &: (consume_count <=: headroom)) -- "fits"   (* right *)
```

two different things: the first names the comparison alone and leaves the whole
predicate anonymous, so the timing report points at half of what you meant. It
is silent - the design is correct, only the report lies. `-:` and `--` *are* the
same precedence and left-associative, so `a -: b -- "name"` does name the
subtraction; the trap is specifically the mixed-precedence cases. The decoder's
invariant suite caught this by looking the named node up and comparing it to a
model, which is a good reason for an invariant suite to read named nodes rather
than ports.

### The harness

`byte_aligner` has 146 input and 218 output bits, unplaceable on any real
package. `validation/synth_harness.sv` reduces this to four ports so a normal
in-context synth/place/route runs. Two rules make it give honest numbers:

- **The stimulus and capture stages must be registers, not wires.** Fanning one
  pin combinationally to every DUT input makes all inputs the same net;
  `opt_design` propagates the equivalence inward and the module collapses.
  Measured: the naive combinational version synthesizes to **4 cells** (the DUT
  is annihilated) against 920 LCs for the registered version.
- **The DUT instance must be `DONT_TOUCH`.** The scramble register must *not* be,
  or `phys_opt_design` cannot replicate it to relieve fanout.

The harness reproduces standalone depth exactly (15 cells / 9 LUT delays either
way, pre-fix), so DUT-internal paths in its reports are the module's own.

`validation/byte_aligner_ooc.xdc` runs the DUT as top out of context. That is a
post-synth smoke test only - nothing is placed, so interconnect delay is
estimated. Logic levels and cell counts from it are real; WNS is not.

### yosys as a pre-check

Useful without a Vivado license, and the flow is in git history:

```sh
yosys -Q -p "read_verilog cme_byte_aligner.v; \
             synth_xilinx -top cme_byte_aligner -flatten; write_json netlist.json"
```

Calibration against Vivado on this module: yosys+ABC reported 15 cells / 9 LUT
delays where Vivado found 7 levels. Treat it as pessimistic and directional -
good for comparing two revisions of the same module, not for absolute Fmax.

### Vivado gotchas hit here

- `CLOCK_DEDICATED_ROUTE ANY` is rejected; legal values are `TRUE`, `FALSE`,
  `BACKBONE`, `SAME_CMT_COLUMN`, `ANY_CMT_COLUMN`, `SAME_CMT_ROW`,
  `ANY_CMT_REGION`. It is not needed at all when the placer picks the clock pin.
- `FANOUT` is a `report_design_analysis` column, **not** a net property. Filter
  on `FLAT_PIN_COUNT` instead (which counts the driver, so fanout is
  `FLAT_PIN_COUNT - 1`). `get_nets -filter {FANOUT > 100}` silently matches
  nothing, and `phys_opt_design -force_replication_on_nets` then hard-errors on
  the empty list rather than skipping. Prefer the built-in
  `report_high_fanout_nets -timing -load_types`.
- Tcl has no `&&` command separator; use newlines.
- Clear stale incremental-synthesis checkpoints
  (`set_property incremental_checkpoint {} [get_runs synth_1]`) - this project
  had one pointing at an unrelated design in `hardcaml_networking`.

### Deliberately not used

**Pblocks.** A pblock would likely have closed the routing gap by confining the
909-LC design, which occupied ~1.4% of the device and had no placement pressure.
It was rejected on portability grounds: `CLOCKREGION_X0Y1` is a coordinate on one
die, and the grid differs between families. The RTL fix travels to any target;
a pblock would have to be re-derived for each. Tool-side replication is an
acceptable middle ground since no source or constraint file records it.

> **This argument is much weaker for the deployment part.** It was made for a
> reusable leaf module against an undecided target. `xcu50-fsvh2104-2-e` is a
> fixed card with multiple SLRs, and a floorplan that confines a 9,000-LUT design
> to one SLR is ordinary practice rather than a portability sin — an SLR crossing
> costs more than the full parser's entire +0.340 ns margin. Revisit this when the
> placed-and-routed run happens; see [retargeting.md](retargeting.md).
