# Phase 6 notes — the ready chain and how to break it

Working notes on the −16.428 ns full-parser setup failure recorded in the
[Phase 6 verification record](phase6_verification.md). This is the reasoning
behind the chosen fix, including the options that were rejected and why, and the
measurements of what each step actually did; it is not an acceptance
requirement. See [timing_notes.md](timing_notes.md) for how
operators map to LUTs and for the separate `byte_aligner` closure, and
[hardcaml_reports.md](hardcaml_reports.md) for the report flow.

> **Device framing superseded; see [retargeting.md](retargeting.md).** Every slack
> figure in this document is `xc7a100tcsg324-1` at 156.25 MHz — the *validation*
> part held to the *production* clock, a pairing the plan never asked for. The
> same tree meets 156.25 MHz on the deployment part `xcu50-fsvh2104-2-e` with
> **WNS +0.340 ns and zero failing endpoints**. The measurements, deltas, source
> hashes and reasoning below remain the durable Artix-7 record and are unchanged;
> what changes is what they mean. Two conclusions in particular are revised there:
> the baseline would have failed on the U50 too (so this work was necessary), but
> it was priced against a 16.4 ns deficit when the real one was ~1.7 ns, and on the
> deployment part **D3 is what closed the design** while A1+A2 contributed almost
> nothing to *worst* slack. The rejection of skid buffers below is also void on
> both its grounds; see retargeting.

Status as of 2026-09-07: **D1, A1, A2 and D3 applied and measured. The ready
chain is gone — the worst path no longer leaves `cme_mbp_decoder` — and the two
chained DSP48E1 multiplies that replaced it are gone too. Worst setup slack is
−10.577 ns, down from −16.428 ns at baseline, and for the first time the worst
path's **logic** delay (5.097 ns) is inside the 6.400 ns period with 69% of what
remains being an unplaced routing estimate. D2 is obsolete. What is left is a
placed-and-routed run; see [what is left](#what-is-left-after-d3).**

## The budget

Two acceptance criteria constrain any fix, both from the
[main plan](cme_mdp3_10g_parser_plan.md):

- Accept one 64-bit beat every cycle for back-to-back legal packets **without
  internally generated stalls**.
- Assert the update **no later than eight cycles** after accepting the final
  byte required for that entry.

`test/cme/cme_feed_parser/phase6_performance.ml` enforces both over 14 traffic
cases. Nine of them already measure a maximum entry latency of 8, so the
forward-latency headroom is **one cycle for the cases at 7 and zero for
padded, MBO, large-extension, and versions 9–12**. The stall budget is zero
everywhere. Any fix that adds a forward pipeline stage has to fit in that.

## What the failing path actually is

Every `ready` in the design is *greedy*: it depends on the current cycle's
consume/pop decision rather than on registered state alone. Two places produce
this, and both are deliberate full-rate optimisations:

```ocaml
(* byte_aligner.ml *)
retained = occupied_slot_count -: pops      (* pops <- consume <- consume_count_i *)
ready    = active &: (retained <:. 2)

(* elastic_fifo.ml *)
pop         = active &: ~:empty &: ready
input_ready = active &: (~:full |: pop)
```

The dependency only *activates* when the stage is full — the aligner at
`occupied_slot_count == 2`, the FIFO at `full` — which is why it never showed
up functionally. Static timing analysis does not care: the path is physically
present in every cycle.

Chained across the parser, that is the reported worst path: 33 logic levels,
22.178 ns (7.136 ns logic, 15.042 ns estimated route), launching from the
decoder's packed block-length field and ending at the ingress BRAM read
address.

```
decoder block_length (signal_reg_49[20])
  -> consume_count arithmetic         CARRY4 adders/subtractors/comparators
  -> decoder aligner        consume -> retained -> ready
  -> iterator output FIFO   pop -> input_ready -> output_ready
  -> iterator aligner       ready
  -> single_feed_sequencer  ready (pass-through)
  -> packet_header          consume_valid <- collect |: (body_valid &: ready_i)
  -> packet_header aligner  ready
  -> ingress elastic FIFO   pop -> RAMB36E1 ADDRARDADDR
```

Five greedy hops in series. The rule that follows:

> No `ready` may depend on the current cycle's consume/pop decision.

The rule binds *this design*, not the primitives it is built from. `Elastic_fifo`
now takes `?greedy_admission` and keeps the old greedy readiness available for
reusers with a short ready chain; every instance in the parser takes the
non-greedy default, so nothing below changes. See
[retargeting.md](retargeting.md).

Note what this is *not*. It is not logic-depth bloat of the kind
[timing_notes.md](timing_notes.md) warns against chasing, and it is not the
`byte_aligner` failing: that module closes 6.400 ns standalone through the
`validation/` harness. What fails is the composition of three aligners and two
FIFOs whose ready signals are all combinationally transparent.

## Options considered

| | Forward latency | Stall risk | Cuts the chain |
| --- | --- | --- | --- |
| A. Non-greedy ready plus one extra slot | none | manageable | yes, all five hops |
| B. Skid buffers (full register slice) | +1 cycle per boundary | none | yes |
| C. Credit-based flow control | none | same as A | yes |
| D. Shorten the head and tail | none | none | no, shortens segments |

### B is not possible here

A full register slice registers both directions, so each one costs a cycle of
forward latency. Four boundaries is +4 cycles against a gate with at most one
to spare, and even a single slice fails twice over: it pushes the nine cases
already at 8 to 9, and cutting a 33-level path once leaves roughly 16 levels
(≈11 ns), still short of 6.400 ns. The cuts that would work are exactly the
cuts the latency gate forbids. Skid buffers only become available if the
eight-cycle requirement is renegotiated, which is a plan change, not an
implementation choice.

> **Both grounds are void; see
> [retargeting.md](retargeting.md#the-eight-cycle-bound-is-self-imposed-and-over-tight).**
> The depth ground was Artix-7 arithmetic — on `xcu50-fsvh2104-2-e` the entire
> 25-level worst path is 6.041 ns, so half of it is ~3 ns. The latency ground
> stands only against the gate as written: eight cycles is 51.2 ns of
> parser-internal latency, tighter than anything external requires, and a
> defensible relaxation to 10–11 cycles buys one to three slices. Renegotiating
> the gate is still a plan change, and still the right way to do it — but it is
> now a plan change worth making, and a skid buffer would break the ready chain
> without the third aligner slot, the `Elastic_fifo` contract change, or the
> twelve block RAM tiles that option A cost.

### C is A with more machinery

Per-stage credit counters remove the combinational coupling completely, but at
a credit-return latency of one cycle they degenerate to precisely A's "carry one
more slot". The extra counter state buys nothing at this round-trip. Worth
revisiting only if a future boundary crosses more than one cycle.

### A is possible, and is the intended fix

Registering `ready` is not the same as registering the datapath. `ready` gates
admission of new beats; the forward path (`available` -> `consume` -> `collect`
-> event) is untouched, so there is no added latency by construction.

**A1, aligner — applied.** `ready = active &: (occupied_slot_count <:. 3)`,
reading the register directly and dropping `-: pops`. This puts the whole
`consume_count -> consume -> retained` cone on the input side of the count flop
and makes `ready_o` a fresh launch point.

The third slot is not optional and is not about burst absorption. With two
slots and a non-greedy ready the occupancy oscillates 1 -> 2 -> 1; in every
`count == 1` cycle the window holds only the head, so `available <= 8` and
neither `packet_header`'s twelve-byte collect (`available >= 12`) nor either
`max_consume:15` consumer can fire. The stage would accept a beat every other
cycle and fail the zero-stall half of the gate. At three slots with
`count <:. 3` the steady state parks at two occupied, the head-plus-tail window
stays full, and full rate is preserved. Cost is one packed `Ingress_beat`
(138 bits) plus the 4-bit count mirror per instance, about 430 flops across the
three aligners against 7,609 today.

**A2, elastic FIFO — applied.** `input_ready = active &: ~:full`, dropping
`|: pop`. This costs one slot of effective depth, so the ingress FIFO goes
64 -> 65 and the iterator's output FIFO goes **2 -> 3**. That second one matters:
the 2-deep output FIFO is what removed the accumulating padded-packet backlog in
this phase, and letting its effective depth fall back to 1 would reintroduce the
bug.

A1 and A2 are one rule and landed together. Doing either alone leaves a greedy
hop in the middle of the chain and most of the path intact.

The consequence worth stating plainly, because several test models encode it: a
depth-1 elastic FIFO now has **no full-rate pass-through at all**. Push and pop
in the same cycle need a slot that is already free, so a one-deep FIFO admits on
alternate cycles, and sustained rate anywhere is carried by `depth - 1` slots.
Nothing in the parser runs a depth-1 stage, but the transport suites did test
one, and those cases now assert the absence rather than the presence of
same-cycle replacement.

### D is free and orthogonal

**D1, head — applied.** The path launches from `block_length` inside the packed
`message_bits` register and reaches `consume_count` through live arithmetic:
an adder and a variable-width comparator in `combined_root`, a second adder into
`target`, then the `target -: collected` subtractor, then comparators into
`count` and `collect`. Everything in that cone that depends on the message
header *alone* is now evaluated in the cycle that latches the header:

| Registered value | Replaces |
| --- | --- |
| `hdr_dimensions_fit` | `msg_size >=: block_length +:. (10 + dimension size)` |
| `hdr_root_plus_dimensions` | `block_length +:. dimension size` in `target` |
| `hdr_root_within_head` / `hdr_root_within_window` | the two `combined_root` constant compares |
| `hdr_body_size` | `msg_size -:. 10` |
| `hdr_root_over_body` | `block_length >: body_size` |
| `hdr_root_extension` | `block_length -:. root_block_length`, both sites |

This is the same shape as the registered slot byte counts in
[timing_notes.md](timing_notes.md): move arithmetic into the cycle that *writes*
the field, where there is slack, rather than the cycle that reads it. The
registers are enabled by `active &: start`, mirroring the `message_bits <-- pack
input.message` assignment, so each becomes valid on exactly the same edge as
`header` and adds no latency.

The correctness risk is the same too — a mirror that silently diverges. Unlike
the aligner's, these are not equal to their spec function on every cycle: after
reset `message_bits` clears to zero while the mirrors clear to zero
independently, so `hdr_root_within_head` reads false where
`block_length <= root_block_length + 1` reads true. That state is unreachable
because the values are only read from state 1 onward and every path into state 1
passes through the `start` write. Any invariant test must therefore assert
equality **conditioned on the decoder not being idle**, not every cycle.

**D2, tail — not yet attempted.** Give the ingress FIFO a prefetch output stage
so `ADDRARDADDR` is driven by a registered "output stage has room" rather than
by the global ready. This removes the RAMB36E1 setup (−0.566 ns) and the last
LUT hops from the chain.

## Measured effect of D1

Applied to `lib/cme/mbp_decoder.ml`. `@all`, `@runtest`, `@fmt`, and
`@rtl-check` all pass. `@performance-check` passes all 14 cases with numbers
identical to the record in [phase6_verification.md](phase6_verification.md) —
same latency minima and maxima, zero input stalls, same cycle counts —
confirming the change is latency- and throughput-neutral.

Device result: see the table below, produced by the same command and flow as
the baseline so the delta is directly comparable.

Same command, part, clock, hierarchy profile, and Vivado build as the baseline,
so the delta is directly comparable. Reports are under
`/tmp/cme-d1-reports/cme_feed_parser/`; the OCaml summary is
`/tmp/cme-d1-synthesis.log`. Generated paths are disposable, so the numbers are
preserved here.

| Post-synthesis timing | Baseline | After D1 | Delta |
| --- | ---: | ---: | ---: |
| Worst setup slack | −16.428 ns | **−15.324 ns** | +1.104 ns |
| Data path delay | 22.178 ns | 21.074 ns | −1.104 ns |
| — logic | 7.136 ns | **5.507 ns** | −1.629 ns |
| — estimated route | 15.042 ns | 15.567 ns | +0.525 ns |
| Logic levels | 33 | 29 | −4 |
| CARRY4 on the path | 9 | **4** | −5 |
| Total setup violation | −76,133.227 ns | −68,716.225 ns | −9.7% |
| Setup failing endpoints | 7,177 | 7,226 | +49 |
| Worst hold slack | +0.252 ns | +0.252 ns | unchanged, 0 failing |

| Post-synthesis resource | Baseline | After D1 |
| --- | ---: | ---: |
| Slice LUTs | 8,014 | 8,027 |
| Flip-flops | 7,609 | 7,659 |
| Block RAM tiles | 11.5 | 11.5 |
| DSP48E1 | 9 | 9 |

Reading this:

- **The targeted arithmetic went where it was supposed to.** Five of the nine
  CARRY4s left the path and logic delay dropped 23%. Fifty flops bought it, which
  is the seven registered values.
- **Logic delay is now inside the period for the first time** (5.507 ns against
  6.400 ns). Before D1 the path could not have closed at any routing quality.
  It can now, in principle; what remains is chain traversal.
- **The ready chain is untouched, as expected.** The worst path still ends at the
  ingress BRAM read address and still traverses all three aligners:
  `cme_mbp_decoder` -> `cme_mbp_decoder/cme_byte_aligner` ->
  `cme_sbe_message_iterator/cme_byte_aligner` ->
  `cme_packet_header/cme_byte_aligner` -> `cme_ingress_fifo`. The launch register
  moved from `signal_reg_49_reg[20]` to `signal_reg_51_reg[6]`, i.e. D1 removed
  the specific cone that made block-length the worst launch point, and the next
  register in the same structure took its place. That is the signature of a
  problem whose remaining cost is the chain, not any one expression in it.
- **Failing endpoints rose slightly while worst slack and total violation both
  improved.** That is redistribution across a large failing population, not a
  regression; total violation, the better aggregate here, improved 9.7%.
- **Routing "worsened" by 0.525 ns and should be ignored.** This is an unplaced
  estimate on a design with no placement pressure; run-to-run variation of that
  size carries no information.

D1 therefore does roughly a tenth of the work and confirms the diagnosis: the
gap is the five-hop combinational ready chain, and A1/A2 are what address it.

Source identity for this measurement:

```text
mbp_decoder.ml       3b832c1a30459d1743821c7516c31a99913804861428ef4d531bb1b385f9199d
full-parser Verilog  78695518957ec9cf809b78517b35e74b61ec291b287d3210830ecbf128381e70
```

## Measured effect of A1 + A2

Applied to `lib/cme/byte_aligner.ml` and `lib/cme/elastic_fifo.ml`, with the
depth increases in `lib/cme/cme_config.ml` (65) and
`lib/cme/sbe_message_iterator.ml` (3). `@all`, `@runtest`, `@fmt` and
`@rtl-check` pass. `@performance-check` passes all 14 cases with numbers
**byte-for-byte identical** to the D1 run and to the record in
[phase6_verification.md](phase6_verification.md): same accepted beats, same
event counts, `input_stalls=0` everywhere, same `latency_min`/`latency_max`,
same total cycles. Registering `ready` costs nothing in the forward direction,
as predicted.

Same command, part, clock, hierarchy profile and Vivado build as D1, so the
delta is directly comparable. Reports are under
`/tmp/cme-a1-reports/cme_feed_parser/`.

| Post-synthesis timing | After D1 | After A1+A2 | Delta |
| --- | ---: | ---: | ---: |
| Worst setup slack | −15.324 ns | **−15.031 ns** | +0.293 ns |
| **Total setup violation** | −68,716.225 ns | **−36,391.204 ns** | **−47.0%** |
| Setup failing endpoints | 7,226 | 7,451 | +225 |
| Data path delay | 21.074 ns | 21.391 ns | +0.317 ns |
| — logic | 5.507 ns | 9.687 ns | +4.180 ns |
| — estimated route | 15.567 ns | 11.704 ns | −3.863 ns |
| Logic levels | 29 | 25 | −4 |
| CARRY4 on the path | 4 | 9 | +5 |
| DSP48E1 on the path | 0 | **2** | +2 |
| Worst hold slack | +0.252 ns | +0.191 ns | 0 failing either way |

| Post-synthesis resource | After D1 | After A1+A2 |
| --- | ---: | ---: |
| Slice LUTs | 8,027 | 8,848 |
| Flip-flops | 7,659 | 6,943 |
| Block RAM tiles | 11.5 | 23.5 |
| DSP48E1 | 9 | 9 |

The block RAM and flip-flop movement is not what it looks like; it is isolated
[below](#a-side-effect-block-ram-doubled-and-it-is-not-the-ingress-depth).

### The chain is gone

This is the result the change was for, and it is not the worst-slack column.
The launch register is unchanged — `cme_mbp_decoder/signal_reg_51_reg[6]`, the
same one D1 left behind — but the **capture** register moved from

```text
cme_message_pipeline/cme_packet_pipeline/cme_ingress_fifo/
  signal_multiport_mem_reg_0/ADDRARDADDR[10]
```

to

```text
cme_mbp_decoder/signal_reg_48_reg[0]
```

The worst path no longer leaves `cme_mbp_decoder`. It does not touch the
iterator's aligner, the packet-header aligner, the sequencer, or the ingress
FIFO. Five module boundaries and two FIFOs came off the path, exactly as the
rule predicted, and the population-level number agrees: total setup violation
halved while worst slack barely moved, which is the signature of removing a long
path shared by thousands of endpoints rather than shortening one path.

Estimated route delay fell 3.863 ns for the same reason — the path is now local
to one module — and that is the one routing figure in these notes worth reading,
because it is a change in what the path *is* rather than run-to-run noise on the
same path.

### What replaced it, and why worst slack barely moved

The new worst path is a decoder-internal multiply chain:

```text
signal_reg_51_reg[6]  (header-derived register)
  -> LUT4/LUT6, CARRY4 adders (signal_add_75)
  -> DSP48E1 signal_add_29        1.999 ns
  -> LUT4 + 3x CARRY4 partial products (signal_mulu_2)
  -> DSP48E1 signal_mulu_2        2.326 ns
  -> 3x LUT6
  -> signal_reg_48_reg[0]
```

Two DSP48E1s in series account for 4.325 ns of the 9.687 ns logic delay. These
are the `block *: count` products in `mbp_decoder.ml` (lines 386, 387, 406, 438
and 691) — group size times entry count, evaluated live in the cycle that reads
them. **Logic delay alone is now 9.687 ns against a 6.400 ns period**, so unlike
after D1 this path could not close at any routing quality.

That is a different problem from the one these notes are about. It is a
D-class problem, not an A-class one: an unpipelined arithmetic cone inside one
module, addressable by the same trick D1 used — `block` and `count` are both
derived from headers, so the product can be computed on the edge that latches
them instead of the edge that reads them.

### What was left after A1 + A2

1. **D3, the decoder multiplies.** *(Done — see [below](#measured-effect-of-d3),
   though not the way it was framed here.)*
2. **D2 is obsolete.** It was going to give the ingress FIFO a prefetch output
   stage so `ADDRARDADDR` stopped being driven by the global ready. The ingress
   FIFO is no longer on the worst path at all; there is nothing left there to
   shorten.
3. **A placed-and-routed run** before claiming closure. Still outstanding, and
   still the only way to calibrate the routing estimate.
4. **The standalone `byte_aligner` closure is now stale.** The
   [timing_notes.md](timing_notes.md) claim that the aligner meets 6.400 ns
   through the `validation/` harness was measured with two slots. The third slot
   widens `next_head` to a three-way mux and adds 142 flops; the module should
   be re-measured through that harness before the claim is repeated.
5. **The iterator output FIFO's RAM style**, which is where the twelve extra
   block RAM tiles went. Characterised below; not applied.

Source identity for this measurement:

```text
byte_aligner.ml        ca5d1f5b6809f7f54de6f4dba74883eb0ddb100fce22b9b190d8f7c08f3f2b38
elastic_fifo.ml        922ea29b3bb3feb67c1290c1a0131386fe73451e55bd3e8629b4df6618cd86a1
cme_config.ml          e48a2312457bd93326b290baa1f12c8b536929e994aa881cee41ce0ea379302a
sbe_message_iterator.ml 6e7a09857556bbfc5aa6b4cdabc457b2ac7d3b8a9912a43911ae9b1d86758c01
mbp_decoder.ml         3b832c1a30459d1743821c7516c31a99913804861428ef4d531bb1b385f9199d
full-parser Verilog    0dbc9a2fcdb43358fd0b472dd3523d1d86c13b12e26fc791d7c94e7de4370a20
```

### A side effect: block RAM doubled, and it is not the ingress depth

Block RAM tiles went 11.5 -> 23.5 (RAMB36E1 11 -> 23) and flip-flops fell 716
even though A1 *adds* roughly 430. The obvious suspect is the ingress FIFO
going 64 -> 65, since `Elastic_fifo` builds
`Fifo.create ~showahead:true ~capacity:(depth - 1)` and that moves the RAM from
63 to 64 words, across a power of two. **It is not that.** A control run with
A1 and A2 applied but ingress left at 64 was synthesised through the identical
flow (`/tmp/cme-a1b-reports/`):

| | After D1 | A1+A2, ingress 65 | A1+A2, ingress 64 |
| --- | ---: | ---: | ---: |
| Slice LUTs | 8,027 | 8,848 | 8,828 |
| Flip-flops | 7,659 | 6,943 | 6,943 |
| Block RAM tiles | 11.5 | 23.5 | 23.5 |
| Worst setup slack | −15.324 ns | −15.031 ns | −15.031 ns |
| Total setup violation | −68,716 ns | −36,391 ns | −36,403 ns |

The extra ingress beat costs about twenty LUTs and nothing else. The block RAM
is the **iterator's output FIFO**. Its backing array in the generated Verilog is

```verilog
reg [1078:0] signal_multiport_mem[0:0];   // after D1: depth 2 -> capacity 1
reg [1078:0] signal_multiport_mem[0:1];   // after A2: depth 3 -> capacity 2
```

A `Message_item` is 1,079 bits. At one word Vivado keeps that array in
flip-flops; at two it infers block memory, and a 2 x 1079 array costs twelve
tiles because tile granularity, not capacity, sets the price. The same
arithmetic explains the flip-flop drop: about 1,079 flops left for the BRAM,
about 430 arrived with `slot2`.

This is a poor trade — twelve tiles to hold two message items — and the remedy
is one argument, not a redesign: `Fifo.create` accepts RAM attributes, so the
shallow, very wide instances can be pinned to `Ram_style.registers` (restoring
exactly the D1 implementation at a cost of roughly 2,100 flops, 1.7% of the
device) or `Ram_style.distributed`. It is deliberately **not** applied here.
Choosing a RAM style is a design decision with its own timing consequences and
deserves its own measurement rather than being absorbed silently into a timing
change; utilisation at 23.5 of 135 tiles (17.4%) is not pressing.

## Measured effect of D3

D3 was supposed to be D1's trick applied to the five `block *: count` products:
register them on the edge that writes their operands. **It could not be, and the
diagnosis behind it was wrong.** Working the products through one at a time:

| Site | Product | Operands at the moment they are read | Registerable? |
| --- | --- | --- | --- |
| `entries_bytes` | `block *: count_entries` | `dimensions`, already registered | no |
| `orders_bytes` | `order_block *: order_count` | `order_dimensions`, already registered | no |
| `combined_entries_bytes` | `combined_block *: combined_count` | live window slice | no |
| `valid_orders` (×2) | `block *: count` | live window / `prefetched_data` | no |
| state 4 prefetch | `block *: count` | `prefetched_data` | no |

The three live sites decide on the edge the dimension bytes arrive, which is the
whole point of them; there is no earlier edge to move to. The two registered
sites look like candidates until you check when they are read: `dimensions` is
written on exactly the edge that enters state 6, and `order_dimensions` on the
edge that enters state 11, so a register fed from them would be valid one cycle
*after* the decision needs it. Computing them instead on the write edge means
reading `a.data_o` rather than a flop, which lengthens the very cone D1
shortened. Every one of the five genuinely needs the live form.

### Naming the decoder first, which is what changed the diagnosis

`mbp_decoder.ml` carried seven `--` names, all D1's. Every state register and
every named net in it now carries its source name, which cost one Vivado run and
replaced this:

```text
Source:      cme_mbp_decoder/signal_reg_51_reg[6]/C
Destination: cme_mbp_decoder/signal_reg_48_reg[0]/D
```

with this:

```text
Source:      cme_mbp_decoder/collected_reg[6]/C
Destination: cme_mbp_decoder/skip_left_reg[0]/D
```

and turned a 25-cell path listing into a readable one. It is the same lesson the
aligner taught in [timing_notes.md](timing_notes.md), and it immediately showed
that the products were **not** the problem:

```text
collected -> combined_root -> target -> required -> count -> consume_count
          -> next_position          16-bit CARRY4 add
          -> DSP48E1 (next_position + bytes)          1.999 ns   <- C port
          -> comparison against body_size             CARRY4
          -> DSP48E1 (the same product again)         2.326 ns   <- OPMODE
          -> skip_left
```

Both DSP crossings are **`consume_count` passing through a multiply it has no
arithmetic business in**. The bound being evaluated is
`position + consume_count + bytes <= body_size`. Written that way, the sum
`next_position + bytes` is an adder with a product on one side, and Vivado folds
that adder into the multiplier's DSP48E1 post-adder — so the late signal enters
the DSP at its `C` port and pays the full 1.999 ns. Then the `valid` result of
that comparison gated the *data* of `skip_left <-- bytes`, and Vivado folded
*that* mux into a second DSP's `OPMODE`, for another 2.326 ns. The products were
sitting still the whole time; the consume decision was being routed through them.

### The two changes

**D3a — write the bound so the late signal meets the product at a comparator,
never at an adder.** `room = body_size - position` is a 25-bit two's complement
value computed from two registers, off the late cone; `headroom = room - bytes`
subtracts the product from it, still off the late cone; and the bound becomes

```ocaml
let fits_after_consume site bytes =
  let headroom = room -: uresize bytes ~width:25 -- ("headroom_" ^ site) in
  (~:(msb headroom) &: (uresize consume_count ~width:25 <=: headroom))
  -- ("fits_after_consume_" ^ site)
```

`consume_count` is four bits, so what it faces is one comparison against an
already-settled value. The at-current-position form (`fits`) collapses the same
way to `bytes <= room`, taking a 24-bit adder out of the state 6 and state 11
paths as well. The sign bit carries the case the old form could not: `position`
runs past the body while draining, and 25 bits hold every intermediate exactly,
so no operation wraps.

This is not the same value as before in one corner. The old form built
`next_position` with a 16-bit add that wraps; the new one does not reproduce that
wrap. Reaching it needs `position >= 65521` inside a message body, which is
unreachable, and the invariant suite asserts that reachability claim every cycle
rather than leaving it in a comment.

**D3b — never gate a wide datum with the late signal when only control needs
gating.** `skip_left <-- bytes` was written under `if_ valid`, and `valid` is the
result of the bound above. The group size does not depend on whether the group
is valid, so the write is now unconditional and only the state transition is
gated. When the group is invalid the stored value is dead: state 11 overwrites
`skip_left` before any reader, exactly as the zero it used to keep did. Entry
into every state that reads `skip_left` (4, 9, 12) is preceded by a write to it
on every path, which is what makes this safe.

### Result

Same command, part, clock, hierarchy profile and Vivado build as A1+A2. The
baseline column is a re-synthesis of the A1+A2 tree with the names added and
nothing else changed, so the delta is naming-neutral; it reproduces A1+A2's
worst slack exactly (−15.031 ns) and its total violation to 8 ps.

| Post-synthesis timing | A1+A2 (named) | After D3 | Delta |
| --- | ---: | ---: | ---: |
| Worst setup slack | −15.031 ns | **−10.577 ns** | +4.454 ns |
| Data path delay | 21.391 ns | 16.691 ns | −4.700 ns |
| — logic | 9.687 ns | **5.097 ns** | −4.590 ns |
| — estimated route | 11.704 ns | 11.594 ns | −0.110 ns |
| Logic levels | 25 | 23 | −2 |
| **DSP48E1 on the path** | **2** | **0** | −2 |
| CARRY4 on the path | 9 | 5 | −4 |
| Total setup violation | −36,382.902 ns | −34,183.047 ns | −6.0% |
| Setup failing endpoints | 7,451 | 7,409 | −42 |
| Worst hold slack | +0.191 ns | +0.191 ns | unchanged, 0 failing |

| Post-synthesis resource | A1+A2 (named) | After D3 |
| --- | ---: | ---: |
| Slice LUTs | 8,848 | 8,979 |
| Flip-flops | 6,943 | 6,946 |
| Block RAM tiles | 23.5 | 23.5 |
| DSP48E1 | 9 | 8 |

`@all`, `@runtest`, `@fmt` and `@rtl-check` pass. `@performance-check` passes all
14 cases with numbers byte-for-byte identical to the D1 and A1+A2 runs and to the
record in [phase6_verification.md](phase6_verification.md): `input_stalls=0`
everywhere, the same `latency_min`/`latency_max`, the same cycle counts. The
rewrite is a pure algebraic and control-gating change with no state added, so
that is what it should do.

Reading this:

- **The DSPs are off the path, and that was the whole 4.3 ns of unavoidable
  delay.** Logic delay fell 47%, and at 5.097 ns against a 6.400 ns period the
  worst path can close in principle for the first time since these notes began.
  That was true after D1 too and stopped being true after A1+A2; it is true again
  now and this time nothing on the path is a hard macro.
- **The 131 extra LUTs are the price**, plus three flops. The 25-bit subtract per
  site replaces a 24-bit add per site, and one DSP came back as fabric — total
  DSP48E1 use fell 9 → 8 because the fused multiply-subtract no longer needs a
  separate multiplier for the same product.
- **Total violation improved 6.0% while failing endpoints fell 42.** Smaller than
  A1+A2's 47%, and expected: this shortened one cone rather than removing a long
  path shared by thousands of endpoints.
- **Routing is now 69% of the path and is the whole remaining story.** It is an
  unplaced estimate on a design at 14% LUT utilisation with no placement
  pressure, so it is neither trustworthy as a magnitude nor addressable from RTL.
  That is precisely the condition under which
  [timing_notes.md](timing_notes.md) says to stop editing RTL and go place the
  design.

### What is left after D3

The worst path is now a control chain with no wide arithmetic in it at all:

```text
collected -> combined_root -> required -> count/collect
          -> collected + count (the state-advance test)
          -> entry_index / next_is_order
          -> skip_left write enable
23 levels, logic 5.097 ns (31%), estimated route 11.594 ns (69%)
```

1. **A placed-and-routed run.** This is now the binding item, not one of several.
   Logic fits the period; 69% of the failing delay is an estimate that only
   placement can replace with a number. Everything below waits on it.
2. **The standalone `byte_aligner` closure is still stale** — measured with two
   slots, and A1 added a third.
3. **The iterator output FIFO's RAM style**, still twelve block RAM tiles for two
   message items. Unchanged by D3.
4. If placement leaves a real gap, the next RTL lever is the `collected` ->
   `count` cone itself: ten levels of muxes and comparators between the collected
   counter and the consume decision, most of which is a function of registers and
   could in principle be evaluated on the edge that writes them. That is D1's
   trick again, applied to a much larger mirror, and it should not be attempted
   on an unplaced estimate.

Source identity for this measurement:

```text
mbp_decoder.ml       0259564126ddb7603485ac8d425af0353f0bb243e868a987d4357421a7c9e426
full-parser Verilog  47b518e732069ce666bedaa3ca1041f71e4a17b16597aa5ad60d814ac6445d97
```

## Re-synthesis: what the harness does

`xilinx_reports.exe ... -run` is a real Vivado invocation. It emits the
Verilog, XDC, and Tcl, then runs Vivado on that script. The generated Tcl is:

```tcl
create_project -in_memory -part xc7a100tcsg324-1
set_param synth.elaboration.rodinMoreOptions "rt::set_parameter synRetiming true"
synth_design -top cme_feed_parser -mode out_of_context
opt_design
report_utilization / report_timing_summary
```

So a hand-rolled Vivado run would execute the *identical* `synth_design`; there
is no difference in the synthesis itself. The only thing hand-rolling buys is
stages the harness does not emit — `place_design` and `route_design`. Use the
harness for comparing revisions, which is what these notes do. A one-off placed
and routed run is worth doing separately to calibrate the 15.042 ns routing
estimate, which is currently unplaced and neither trustworthy as a magnitude nor
addressable from RTL.

## Sequencing

1. **D1** first, alone, and measure. It is small, it is the proven trick on this
   codebase, and the delta tells you how much of the 33 levels is decoder
   arithmetic versus the ready chain — which calibrates how aggressive A needs
   to be. *(Done.)*
2. **A1 and A2** together, with the depth increases. *(Done.)*
3. ~~**D2** if the remaining segment through the ingress FIFO still
   dominates.~~ *(Obsolete: the ingress FIFO is off the worst path.)*
4. ~~**D3**, the decoder's `block *: count` products, which is what the worst
   path is now.~~ *(Done, but the products were not the problem: what crossed
   them was `consume_count`. See [Measured effect of D3](#measured-effect-of-d3).)*
5. A placed-and-routed run before claiming closure, and a re-measurement of the
   standalone `byte_aligner` closure with three slots. **This is now the whole
   remaining list**, and (5) is where the evidence stops being RTL-addressable.

## Verification, as landed

The hooks that were extended rather than merely re-run:

- `test/cme/mbp_decoder/mbp_decoder_invariant_tests.ml` — new with D3. The
  decoder had no invariant suite; an algebraic rewrite of a bound check is
  exactly the kind of change that stays right on ordinary traffic and fails on a
  boundary, so every `fits_*` and `fits_after_consume_*` node is asserted against
  a model of the bound written from the plan's statement of it, in unbounded
  integers, on every cycle of padded, MBO, large-extension, zero-entry, dense,
  truncated-MsgSize and version-9-to-13 traffic. `room` is checked against
  `body_size - position` as a signed value on every cycle too, and the
  16-bit-wrap reachability claim that makes the rewrite equivalent to the form it
  replaced is asserted rather than left in a comment.

  The suite reads its nodes between `cycle_before_clock_edge` and
  `cycle_at_clock_edge`. Reading after a whole `Cyclesim.cycle` mixes post-edge
  registers with pre-edge combinational nodes — the after-edge pass only
  refreshes what the outputs need — and the invariant is about one instant.

  It carries two **structural** checks, because the timing property is the one
  thing every behavioural test in the repository would pass: no `headroom_*` cone
  may contain `consume_count`, and, generally, no adder or subtractor anywhere in
  the decoder may have both `consume_count` and a multiply in its combinational
  cone. Both walk the graph with `Deps_for_loop_checking` and both carry negative
  controls. Mutation-tested: dropping the sign check and an off-by-one in `room`
  are caught by the behavioural invariant at the first message; restoring the
  `next_position + bytes` adder form is caught **only** by the structural checks,
  which is the case they exist for.

- `test/cme/byte_aligner/byte_aligner_invariant_tests.ml` — the slot-byte-count
  mirror now covers `slot2_bytes` as well, since `timing_notes.md` warns that
  any change to `next_slot0` / `next_slot1` (now `next_slot2` too) must be
  mirrored in the count muxes. The suite also gained a **structural** check:
  no combinational path may run from `consume_count_i` / `consume_valid_i` to
  `ready_o`, walked over the signal graph with
  `Signal_graph.Deps_for_loop_checking`, which cuts at registers. This is the
  one property that would pass every behavioural test in the repository and fail
  only in static timing analysis, so it is worth asserting directly. It carries
  a negative control — `consume_ready_o` *must* be reachable from the same
  inputs — so an empty cone means the traversal works, not that it found
  nothing. `event_fifo_unit_quickcheck_tests.ml` asserts the same shape for
  `event_ready_o` against `event_ready_i` at depths 1, 3 and 16.
- The aligner Step model now tags each accepted byte with the beat that carried
  it and clips the expected window to the two leading resident beats. Without
  that it would expect the third slot to be visible.
- `event_fifo_testbench.ml` and `stream_scenarios.ml` model readiness as
  `occupancy < depth` with no `|| (valid && ready)` term, and count
  `blocked_at_full` — cycles where the FIFO was full, draining, and being
  offered an entry, which is exactly where greedy and non-greedy differ. That
  counter is asserted non-zero so the readiness equality cannot pass vacuously.
- The depth-1 cases now assert the **absence** of same-cycle replacement, and
  the continuous zero-stall cases moved from depth 1 to depth 2, because a
  one-deep elastic FIFO no longer has full-rate pass-through.
- The 14-case performance table was the real check, and it did not move.
