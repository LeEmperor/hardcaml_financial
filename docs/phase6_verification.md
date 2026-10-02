# Phase 6 verification — cycle-level acceptance passes; Artix-7 device timing fails

> **The device timing failure recorded here is against the wrong part.** All of it
> is `xc7a100tcsg324-1` at 156.25 MHz, the validation part held to the production
> clock. On the deployment part `xcu50-fsvh2104-2-e` the current tree **meets**
> 156.25 MHz post-synthesis at WNS +0.340 ns with zero failing endpoints. See
> [retargeting.md](retargeting.md). The cycle-level and structural evidence in
> this document is device-independent and unaffected.

> The device evidence below measures the tree **before** the D1, A1, A2 and D3
> changes. Since then worst setup slack has improved to −10.577 ns, total setup
> violation has fallen 55% (−76,133 ns to −34,183 ns), the worst path no longer
> leaves `cme_mbp_decoder` — the cross-module ready chain that dominated this
> record is gone — and it no longer crosses a DSP48E1. Its logic delay, 5.097 ns,
> is inside the 6.400 ns period; 69% of the remaining violation is an unplaced
> routing estimate. Resource use moved with it: 8,979 LUTs, 6,946 FFs, 23.5 BRAM,
> 8 DSP. The default ingress depth is now 65. See the
> [Phase 6 notes](phase6_notes.md) for the analysis, the measured deltas, and
> what is left. The tables here are left as the record they were generated as,
> hashes included.
>
> The cycle-level evidence below still holds exactly: `@performance-check`
> reports the same 14 rows, byte for byte, after all four changes.

Updated 2026-09-07 from the [pickup checkpoint](phase6_pickup.md). The
[main plan](cme_mdp3_10g_parser_plan.md) remains the authority for acceptance.

The enforcing performance gate now passes all 14 cases. Functional conformance,
formatting, the flattened structural audit, and all ten RTL smoke targets pass.
Fresh full-parser synthesis/resource and timing evidence is also recorded.
The Artix-7 post-synthesis estimate fails the 156.25 MHz target with −16.428 ns
worst setup slack (−10.577 ns as of the changes noted above). Physical 10G
timing remains open; the passing cycle-level gate does not establish the
operating frequency.

## Reproduction

Run from the repository root with the existing opam switch wrapper. Run Dune
commands sequentially; the build directory is disposable.

```sh
./scripts/with-switch.sh dune build --build-dir /tmp/cme-phase6-build --display quiet @all @runtest @fmt @rtl-check
./scripts/with-switch.sh dune build --build-dir /tmp/cme-phase6-build --display quiet @performance-check
```

Both commands must exit successfully. `@performance-report` prints the same
measurements without enforcing the bounds. Ordinary `@runtest` remains separate
from performance acceptance; the eight-cycle threshold has not changed.

For a cycle trace of the first two padded packets, including iterator and
decoder state, available bytes, consume commands, and handoffs:

```sh
cd test/cme/cme_feed_parser
/tmp/cme-phase6-build/default/test/cme/cme_feed_parser/phase6_performance.exe --trace --detail --check
```

`--trace` samples internal nodes after combinational evaluation and before the
clock edge for cycles 0–309 of the padded-alignment case. `--detail` prints entry
accept/transfer cycles for its first two packets. Both use the same Step fixture
and exact XML oracle scoreboard as the other performance measurements.

## Isolated failures and changes

The original 16-packet padded stream reproduced exactly: zero input stalls,
7–23-cycle entry latency, and 351/384 entries above eight cycles. Extending it
to 128 packets exhausted buffering: 65 input stalls, 7–71-cycle latency, and
3,039/3,072 entries above the bound.

The trace identified two iterator output stalls per padded packet, at cycles
43 and 80 of the first packet, while the decoder finished the prior message's
MBO dimensions. The next packet's first prefix completed at cycle 152 rather
than 151, accumulating one cycle per packet. Increasing the iterator's internal
output FIFO from one item to two absorbs those brief handoffs. The original
16-packet case and its 128-packet extension then both passed without changing
the prefix or body beat contract. The final trace has no iterator output
backpressure during the first packet; packet 1's first entry is accepted at
cycle 153 and transferred at 160 (seven cycles), matching packet 0's latency.

Broader coverage exposed three additional problems, now fixed in
`lib/cme/mbp_decoder.ml`:

- Version 9 collected the bytes reserved for TradeableSize, which only becomes
  semantic in version 10. Its entry completion threshold now ends at MDEntryType
  (byte 26); reserved bytes still retire through the runtime padding path.
- Nonempty MBO groups spent extra cycles checking dimensions and retiring the
  skip. Valid dimensions now enter the skip on their collection edge, and a
  final skip can finish the message on the same edge when event storage permits.
  Invalid dimensions retain the registered diagnostic path and byte offsets.
- Large root extensions incurred separate root retirement and MBP dimension
  handoffs. The final root collection now records transaction metadata directly,
  and final root padding can consume and validate MBP dimensions together when
  they fit within the existing 128-bit window and MsgSize.

The portable ports, 677-bit normalized event ABI, and default 16-event output
FIFO remain unchanged. The default ingress depth was 64 when these tables were
generated and is now 65; see the note at the top of this file. Body beats are still eight
bytes except at a message's final beat. No partial non-final beat experiment or
packet-wide collector was introduced. Named internal trace signals were added
to the iterator and decoder; tracing is opt-in in the testbench.

## Measured performance

All cases use uninterrupted offered input and an always-ready sink. Every
emitted event is compared against the XML oracle. Latency starts at external
acceptance of the beat containing the last semantic entry byte: byte 26 for
version 9, byte 30 for versions 10–13. Runtime extension and reserved padding
never shift that origin. Every update is matched by packet sequence, message
offset, and entry index. The acceptance-span assertion also checks that offered
span equals accepted beats plus source stalls.

| Traffic | Packets | Beats | Events | Input stalls | Entry latency | Entries over 8 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Single entry | 1 | 10 | 2 | 0 | 7 | 0/1 |
| Dense entries (255/message) | 16 | 16,416 | 4,096 | 0 | 7 | 0/4,080 |
| Small packets | 128 | 1,280 | 256 | 0 | 7 | 0/128 |
| Zero-entry packets | 128 | 768 | 128 | 0 | N/A | 0/0 |
| Many messages (16/packet) | 16 | 2,080 | 512 | 0 | 7 | 0/256 |
| Padded alignments | 16 | 2,304 | 512 | 0 | 7–8 | 0/384 |
| Padded sustained | 128 | 18,432 | 4,096 | 0 | 7–8 | 0/3,072 |
| Zero-entry many messages | 128 | 8,448 | 2,048 | 0 | N/A | 0/0 |
| MBO groups | 128 | 27,648 | 4,096 | 0 | 7–8 | 0/3,072 |
| Large extensions | 128 | 57,344 | 4,096 | 0 | 7–8 | 0/3,072 |
| Version 9 | 128 | 18,432 | 4,096 | 0 | 7–8 | 0/3,072 |
| Version 10 | 128 | 18,432 | 4,096 | 0 | 7–8 | 0/3,072 |
| Version 11 | 128 | 18,432 | 4,096 | 0 | 7–8 | 0/3,072 |
| Version 12 | 128 | 18,432 | 4,096 | 0 | 7–8 | 0/3,072 |

Padded cases have eight messages per packet and three entries per message.
For zero-based message index `m`, root length is `11 + m mod 8`, and entry
length is `32 + (m + 3) mod 8`. The MBO case adds three 24-byte orders per
message. Large extensions add 32 bytes to each root and 64 bytes to each entry,
with two 40-byte orders per message. The version-specific cases use the padded
layout with zero orders. Other cases use version 13. All messages set the
end-of-event bit. These finite deterministic cases cover the stated traffic
classes, not every possible legal length/count combination.

## Functional and structural checks

The seeded differential properties remain in ordinary `@runtest`:

| Property | Seed | Trials × packets |
| --- | --- | --- |
| Schema-valid differential streams | `phase6-valid-packets` | 48 × 64 = 3,072 |
| Faults, reset, resync, session reset | `phase6-faults-controls` | 32 × 32 = 1,024 |
| Deep physical truncation and recovery | `phase6-cut-through-truncations` | 16 × 32 = 512 |

The deep truncation generator now covers versions 9–13, root lengths 11–74,
and entry lengths 32–127, exercising the new extended-root path. Its explicit
cut-through scoreboard checks every emitted update against the complete XML
oracle prefix, then the truncation diagnostic and recovery packet. Seed-list
shrinking re-encodes dependent sizes/counts; shrinking remains capped at 100
attempts. Reset can cancel generated work, so packet totals are generation
counts rather than claims that every packet emits an event.

Two named regressions cover extended root/MBO handoffs with randomized stalls
and reset (seeds 17, 83, 211), and malformed extended MBP/MBO dimensions with
exact diagnostic offsets, both with and without stalls. Existing stall, abort,
reset, offset-seven prefix, FIFO, and aligner invariant suites also pass.
No real-capture replay is available or required for this checkpoint.

The flattened full parser has no remaining instantiations, passes Hardcaml's
combinational loop detector, and passes the bounded mux-width inventory.
Negative controls still reject feedback and a 512-bit mux. The graph contains
145 register nodes and 10,406 register bits, excluding memory arrays; these are
pre-synthesis counts. Intentional normalized-record muxes remain explicitly
allowed; dynamic byte-window muxes stay at or below 128 bits.

The inventory is generated at
`/tmp/cme-phase6-build/default/test/cme/rtl_checks/phase6_structure.txt`.
All ten Yosys hierarchy/Icarus elaboration targets pass. These smoke tools do
not replace the structural audit or establish device timing.

## Device evidence

The fresh reporting command completed successfully on 2026-09-07. Vivado
2025.2.1 (build 6403652), target `xc7a100tcsg324-1`, full design hierarchy,
6.400 ns `clock_i` constraint, retiming enabled, synthesis plus `opt_design`,
no placement or routing. The generated Verilog contains all 11 module
definitions. This is one inclusive full-parser project; child table rows have
no separate estimates because `-hierarchy` was not requested.

```sh
cd /tmp
/tmp/cme-phase6-build/default/synthesis/xilinx_reports.exe cme-feed-parser \
  -dir /tmp/cme-phase6-final-reports-approved \
  -part xc7a100tcsg324-1 -clock clock_i:156.25 \
  -full-design-hierarchy true -jobs 1 \
  -path-to-vivado /home/wayne/tools/xilinx/vivado25_install/2025.2.1/Vivado/bin/vivado \
  -run
```

The first sandboxed attempt failed before synthesis while writing
`/home/wayne/.Xilinx/Vivado/tclapp/manifest.tcl`. The retry received sandbox
approval for Vivado's cache writes and completed. The reporting wrapper
validated all three fresh, nonempty report artifacts; its successful exit
establishes report generation, not timing acceptance.

| Post-synthesis resource | Used | Available |
| --- | ---: | ---: |
| Slice LUTs | 8,014 | 63,400 |
| Flip-flops | 7,609 | 126,800 |
| Block RAM tiles | 11.5 (11 RAMB36 + 1 RAMB18) | 135 |
| DSP48E1 | 9 | 240 |
| Latches | 0 | — |

| Post-synthesis timing | Result |
| --- | ---: |
| Worst setup slack | **−16.428 ns** |
| Setup failing endpoints | 7,177 / 14,392 |
| Total setup violation | −76,133.227 ns |
| Worst hold slack | +0.252 ns |
| Hold failing endpoints | 0 |
| Worst pulse-width slack | +2.700 ns |

The reported worst setup path launches from decoder message-context register
`cme_mbp_decoder/signal_reg_49_reg[20]/C` (the packed block-length field) and
ends at ingress BRAM read address
`cme_message_pipeline/cme_packet_pipeline/cme_ingress_fifo/signal_multiport_mem_reg_0/ADDRARDADDR[10]`.
It traverses decoder collection/skip control and the upstream aligner/ready
chain: 33 logic levels and 22.178 ns estimated data delay, split into 7.136 ns
logic and 15.042 ns estimated routing. This identifies a concrete cross-stage
control-path investigation; it is not a placed/routed path or a measured Fmax.

`check_timing` reports zero unconstrained internal endpoints and no loops, but
176 inputs and 680 outputs lack I/O delays. The generated XDC declares only
the clock. These out-of-context estimates do not constrain a board interface,
and there is no placement, routing, or 10GbE shell timing result. Device-specific
place-and-route closure remains deferred under the main plan.

Source identity: working tree based on
`988d009eb7c8b87ca8ddd188cec0e3c2b2345be1`, including its untracked Phase 5/6
sources and the changes described above. SHA-256:

```text
reporting executable  48cbf95a523c962143abe91b6876962d3fc93a1cbb7ba1e678fda458d3b9002a
full-parser Verilog   9c496d771e3a2d88508dedfd0d8cd714b0df4bee2261e9555a7a78f5b75becec
mbp_decoder.ml        8a6b05616f8a5bb1d77a8c7f4bf31e8295199cc24dc039a7c82605fdb6a0dc95
sbe_message_iterator  8ec3ff4c46f253c76a7ec3e3a797a27f34e3c80d016af29f0d4ab689ad8a6305
```

Fresh artifacts are under
`/tmp/cme-phase6-final-reports-approved/cme_feed_parser/`:

- `cme_feed_parser.v`, `cme_feed_parser.xdc`, `cme_feed_parser.tcl`;
- `post_synth_report.txt`;
- `post_synth_cme_feed_parser.utilization`;
- `post_synth_cme_feed_parser.timing`.

The OCaml summary is `/tmp/cme-phase6-synthesis-approved.log`. The final
performance/transfer trace is `/tmp/cme-phase6-final-trace.txt`. These generated
paths are disposable; the tables and hashes above preserve the evidence summary.
See [reporting conventions](hardcaml_reports.md) for reproducibility and limits.

## Next work

Phase 6's conformance, performance, structural checks, and available device
reporting are now recorded. The outstanding production constraint is the
failed 156.25 MHz device timing estimate. Start its investigation with the
measured decoder-to-ingress control path, preserving the unchanged eight-cycle
performance gate and all recovery/backpressure checks when introducing pipeline
boundaries. Phase 7's Arty integration is a separate functional milestone and
cannot establish 10G timing closure.

## Working tree

Continue from the current tree, including untracked Phase 5/6 source files.
The pre-existing aligner, synthesis, schema, and decoder work is preserved.
No commit was created. Do not reset to HEAD or discard the untracked decoder,
stress/performance tests, or documentation.
