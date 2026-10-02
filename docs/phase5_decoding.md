# Phase 5: MBP decoding and normalized events

Implemented 2026-09-07. The portable `Cme_feed_parser` now consumes framed 64-bit
UDP payloads and emits the 677-bit normalized event ABI pinned in
[Phase 4](phase4_schema.md).
It decodes `MDIncrementalRefreshBook46`, using Production schema ID 1/version 13.
The public ports, default ingress capacity of 64 beats, and default output
capacity of 16 events are unchanged.

## Implementation and ownership

`lib/cme/mbp_decoder.ml` consumes the ordered `Message_item` interface from
[Phase 3](phase3_messages.md). The public top composes `Message_pipeline`,
`Event_orderer`, `Mbp_decoder`, and `Event_fifo` through real hierarchical child
instances. Decoder ownership, event ordering, and queued output events participate
in the existing sequencer control fence. Reset cancels all work; enable pause
preserves it and suppresses handshakes.

Template dispatch uses the iterator's existing admission list, set to template
46 by the public top. This fulfills the reserved `Template_dispatcher` role
without adding a separate module or buffering stage for a single decoder.

The decoder uses the shared two-beat aligner and fixed chunk registers sized to
the generated schema: an 11-byte root, 3-byte MBP dimensions, 32-byte entry, and
8-byte MBO dimensions. It consumes up to eight bytes per collection or skip cycle.
There is no packet-sized collector or packet-wide shifter. Runtime root and entry
block lengths determine padding skips; runtime MBO block length and count
determine the order-group skip. Products and message-bound checks use 24-bit
arithmetic so oversized dimensions cannot wrap into an apparently valid body.
Compatible remaining message tails are consumed before completion.

Each valid MBP entry produces one update with packet/message context, zero-based
entry index, count, and `message_last`. Bit 7 of `MatchEventIndicator` produces
one end-of-event after successful message completion, including a zero-entry
message. Root transaction time is propagated once collected. Prices and other
signed values retain their raw two's-complement bits; nullable values normalize
to zero plus the corresponding null flag. Price exponent remains the schema's
constant `-9`.

## Schema and error behavior

- Incompatible schema IDs, versions before template introduction, undersized
  blocks, or group dimensions exceeding `MsgSize` produce schema diagnostics.
  The decoder drains the bounded message so subsequent messages can proceed.
- Versions through the pin follow field and enum `sinceVersion` metadata.
  `TradeableSize` is absent/null in version 9; entry types `w` and `x` are admitted
  starting at version 12. The generator now emits enum value/version pairs as
  well as the existing raw enum-value list.
- Newer versions with a compatible root produce a schema diagnostic at the
  version field before decoding known fields. Later group checks still reject
  undersized or out-of-bounds layouts. Appended fields and message tails are
  skipped. This implements the warning required by the main plan; the Phase 4
  oracle previously omitted it.
- Invalid update actions or entry types retain earlier updates, emit one enum
  diagnostic at the invalid field, and suppress remaining updates and end-of-event
  for that message.
- Physical packet truncation is diagnosed by the iterator. Its abort cancels an
  incomplete collector, preserves completed updates, and suppresses end-of-event.
  An entry fully collected while event storage is stalled remains owned until it
  can be emitted; the decoder holds the abort upstream during that interval.
  The orderer emits the terminal diagnostic after decoder completion.

The software oracle still reads the pinned XML independently of the generated
hardware descriptors. Besides the newer-version warning, its group-error
diagnostics now retain transaction time already decoded from the root, and short
packet-header diagnostics retain the current channel-valid state. Complete
messages are compared bit-for-bit against the oracle. A whole-payload oracle
cannot predict cycle-dependent cut-through progress on a physically truncated
packet: those cases instead require an exact prefix of the full-message oracle's
updates, followed by the oracle's truncation diagnostic, with no end-of-event.

## Verification

`test/cme/cme_feed_parser/` replaces the active Phase 0 inactivity tests with a
Step/Cyclesim integration suite. Structural ABI and hierarchy checks remain;
the historical Phase 0 assertion executable remains compile-only. The shared
schema fixture is now a separate test-support library, keeping byte encoding
independent of hardware extraction constants.

The integration suite covers all 42 supported action/type combinations, signed
limits and nulls, asymmetric 64-bit metadata, zero/multiple entries and messages,
all message alignments, runtime padding and MBO skips, message tails, versions
8–14, invalid enums and schemas, short dimensions/groups, maximum entry count,
oversized dimension products, sequencing and wraparound, control fencing,
reset cancellation, enable pauses, byte-source-like bubbles, and FIFO depths
1, 3, and the defaults. A deterministic 20-trial Quickcheck property varies
traffic and stall schedules using seed `phase5-decoder-schedules`.

A physical-truncation sweep cuts a padded six-entry message at every UDP byte
position after the packet header, with continuous and stalled schedules, then
checks recovery. The separate `test/cme/mbp_decoder/` Step suite exercises a
completed entry blocked behind a stalled event register when an abort arrives,
and delayed completion acknowledgment. Its ten schedule trials use seed
`phase5-completed-collector-abort`. Both suites have compact reviewed expect traces.

The full build, functional suites, formatter check, and all ten RTL targets passed:

```sh
./scripts/with-switch.sh dune build @all @runtest @fmt @rtl-check
./scripts/with-switch.sh dune exec --no-build lib/common/generate.exe -- cme
```

The RTL alias includes ten targets, adding `cme_mbp_decoder` and exercising the
active public parser hierarchy. Generated artifacts are under
`_build/default/test/cme/rtl_checks/`; Yosys logs are beside each Verilog target.
The public generator also retains real child hierarchy in
`cme_mdp3_feed_parser.v`. The reporting command offers `mbp-decoder` and the
active `cme-feed-parser` targets.

The automatic-build `dune exec` launch stalled in this environment; after the
successful full build, `dune exec --no-build` and direct execution of the built
generator both completed. A report-project smoke run also completed:

```sh
_build/default/synthesis/xilinx_reports.exe cme-feed-parser \
  -dir _build/xilinx-reports/phase5-parser -part xc7a100tcsg324-1 \
  -clock clock_i:156.25 -hierarchy -full-design-hierarchy true -jobs 1
```

The top project is
`_build/xilinx-reports/phase5-parser/cme_feed_parser/`, with child projects beside
it. Verilog, Tcl, and an XDC containing a 6.400 ns clock were generated; Vivado
was not invoked, so this is project-generation evidence only.

## Performance boundary

This phase establishes decode behavior, ordering, bounded storage, and safe
backpressure. Collection, validation, event emission, and message transitions
occupy separate cycles. It does **not** establish uninterrupted 64-bit acceptance,
the eight-cycle entry-to-event latency bound, or 156.25 MHz device timing.
Those remain Phase 6 acceptance work. Yosys hierarchy resolution and Icarus
elaboration are smoke checks; they do not establish functional RTL simulation,
combinational-loop freedom, or physical timing closure. Arty integration and
board acceptance remain Phase 7.
