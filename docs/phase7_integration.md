# Phase 7 — Arty integration

The board harness, observability, sender, and automated MII/UART simulation are
implemented, and the CME datapath is covered cycle-accurately by `dune runtest`.
**Physical acceptance passed on 2026-09-09 UTC.** The complete native harness was
synthesized and implemented for the Arty A7-100T, met the build's setup and hold timing
gate with the DP83848J receive constraints, was programmed onto the board, and passed all
seven physical Ethernet/UART cases in `board_acceptance.py`.

The acceptance sequence has since been extended with seven MTU-scale cases (deep MBP
groups, many-message datagrams, a full final beat, and a heavy gap/duplicate pair). Their
expected counters are confirmed by the XML oracle, by the sender model and by Cyclesim,
but they have **not** yet been run on hardware.

## Composition and provenance

The harness is one native Hardcaml hierarchy. The installed `hardcaml_networking` package
provides the Arty pin interface, board helpers and `Udp.Udp_rx_64_mac_top`; the CME top calls
that module directly alongside the feed parser and validation sink. RTL generation needs no
sibling checkout, external Verilog blackbox, vendored file, or concatenation step.

```text
cme_feed_parser_validation_harness_arty
  |                                 validation/board/cme_feed_parser_validation_harness_arty.ml
  |- udp_rx_64_mac_top              hardcaml_networking.Udp
  |- cme_mdp3_feed_parser           lib/cme/cme_feed_parser.ml
  |- cme_validation_sink            validation/board/cme_validation_sink.ml
  `- board scaffolding              validation/board/board_scaffolding.ml
```

`Arty_board_top`, `Clk_div` and `Second_pulse` come from `hardcaml_networking`;
`board_scaffolding.ml` supplies the matching plumbing layer (per-domain reset
synchronizers, the 25 MHz PHY reference divider, PHY hard-reset sequencing, and the
heartbeat).

The target is **Arty A7-100T, `xc7a100tcsg324-1`, parser clock 25 MHz**. This is
functional integration. Phase 6's continuous-wide-stream tests and the U50 production
profile establish separate throughput and timing evidence.

### Why 25 MHz

The parser shares `eth_tx_clk` with the UDP application stream, so the design contains
**no parser clock-domain crossing** — the only crossing is the async receive FIFO already
inside the networking stack. A faster parser clock would require an MMCM and a new
crossing whose failures would present as parser bugs, and would buy no functional
coverage: MII at 100 Mb/s occupies roughly 6% of the parser's capacity at 25 MHz, so the
link is the limit. `docs/retargeting.md` records ~23 ns of routed slack for the
parser out-of-context at this clock, which is headroom, not a reason to spend it.

## Selection and observability

Only destination UDP port **31337** reaches the parser. Other ports drain at full rate
without changing parser sequence state; selection is latched on the accepted first wide
beat and retained through the packet. The sender crafts unicast Ethernet frames for MAC
`02:00:00:00:00:01`, IPv4 `192.168.1.1`, directly on the selected host interface, so ARP
replies from this receive-only harness are unnecessary. Use a direct host-to-Arty cable
and quiet unrelated traffic on that interface during capture; the commands are in the
[host setup runbook](../validation/README.md). The wrapper selects a port;
it does not authenticate source IP/MAC and does not validate UDP checksums.

`btn[0]` resets. `sw[0]` enables reception; the PHY reference clock and the UART remain
active when it is low, so pausing ingress freezes the counters without truncating a
status record. `sw[3:1]` selects one of eight counters, whose low nibble is shown on
`led[3:0]`. RGB indicators show heartbeat (`led0_r`), updates seen (`led0_g`), PHY reset
released (`led1_g`), UDP busy (`led1_b`), network errors seen (`led2_r`), IPv4 checksum
status (`led2_g`), and parser diagnostics seen (`led3_r`).

The USB UART uses **115200 baud, 8 data bits, no parity, one stop bit**. A snapshot starts
after 25,000,000 idle cycles, approximately once per second plus record transmission time.
Every 36-byte record contains ASCII `CME7` followed by these little-endian 32-bit unsigned
counters:

| Index / switch value | Counter | Increment condition |
| --- | --- | --- |
| 0 | packets | Selected first wide beat accepted by the parser, including duplicates |
| 1 | updates | Accepted MBP-update event |
| 2 | end_of_event | Accepted end-of-event marker |
| 3 | diagnostics | Accepted parser diagnostic event |
| 4 | crc_errors | Late network bad-FCS verdict |
| 5 | ip_errors | Network frame completion with false IPv4 checksum status |
| 6 | sequence_gaps | Parser sequence-gap diagnostic |
| 7 | duplicates | Parser duplicate-or-late diagnostic |

Counters wrap modulo 2^32 and reset together. Snapshot values remain fixed during
serialization, including when new events arrive. The host requires two consecutive
matching snapshots for each case and preserves raw UART bytes and a JSON report.

An end-of-event marker requires bit 7 (`LastMsgOfEvent`) of MatchEventIndicator. Both the
board sender and the simulation stimulus set it; a payload without it produces the update
and no marker, which is correct parser behaviour rather than a counting fault.

**Late CRC alignment:** `Udp_ipv4_rx` registers `crc_error_o` on `frame_done_o`, so the
sink delays its CRC sampling by one enabled cycle; sampling both together would charge the
previous frame's verdict to this one. IPv4 checksum status is already aligned to frame
completion. Network error counters cover the network status channel, including
filtered-port traffic, and never become parser diagnostics. All parsed events remain
**provisional** on this permissive receive path, including events from a frame later found
to have bad FCS or a bad IP checksum.

## Verification

Four layers, all currently green.

**1. `dune runtest` — the CME datapath, cycle-accurate.** Everything from the recovered
UDP payload to the UART pin is ordinary Hardcaml, so it is reachable from Cyclesim:

- `test/cme/validation_sink/` drives synthetic events past a software counter model
  checked every cycle, and decodes the UART pin with an independent receiver that never
  looks inside the DUT. Record atomicity is checked by requiring every decoded counter
  tuple to be one the counters held simultaneously, with a non-vacuity count of the
  records transmitted while the live counters were still moving.
- `test/cme/validation_core/` covers destination-port selection, parser composition and
  counter wiring, including the central claim that filtered traffic can neither be counted
  nor perturb sequence state — checked by running an identical selected stream with and
  without filtered packets interleaved and requiring identical counters.

The former hand-written `cme_validation_sink.sv` had none of this: it was outside every
OCaml suite, and its event ABI was the literal slice `event_data[627:620]`. The Hardcaml
sink reads the same field through `Event.Of_signal.unpack`, so a field added to
`Cme_types.Event` can no longer silently shift the diagnostic code out from under the
counters.

**2. `validation/phase7/check.sh` — the native board top, in Icarus.** MII nibbles pass
through the real generated async receive FIFO, width adapter, parser, counters and UART
pin, with independent RX and application clocks at 25 MHz and a phase offset. The
`cme_feed_parser_validation_harness_arty_sim` generator target calls the same
top-level `create` function as the bitstream build and changes only the UART timing
parameters.

**3. `phase7_contracts.ml`** — the event ABI and both sender sequences against the XML
oracle, run as part of `dune runtest`: the nine MII vector fixtures, and separately the
fourteen board-run payloads, each with its own golden decoder so the counters are checked
in the sequence context that sender actually transmits.

```sh
./validation/phase7/check.sh
```

Requirements are the existing OCaml switch with `hardcaml_networking` installed, Python 3,
and Icarus Verilog. Artifacts are `_build/phase7/simulation.txt`, `rtl.sha256`,
`networking_package.txt`, `cases.json`, and the generated payload fixtures.
The recorded native-top run passed all nine cases and decoded nineteen complete atomic
UART records. It also checked enable freeze and reset overriding disabled enable entirely
through the board UART and LED outputs.

**4. Physical Arty A7 run.** Vivado synthesis and implementation completed for
`xc7a100tcsg324-1`; the worst setup and hold path checks in `build.tcl` passed, allowing
the bitstream to be written and programmed. The host then sent the seven physical cases
through `enx207bd25880ef` and decoded counter snapshots from `/dev/ttyUSB1`. The capture
started at `2026-09-09T00:09:15Z`; every case recorded two consecutive snapshots equal to
the expected counters and the run ended with `6, 7, 6, 2, 0, 0, 1, 1`.

The seven MTU-scale cases were added to the sequence afterwards and ran on the same
programmed board later the same night. Both fourteen-case captures passed with the same
final counters, `13, 237, 33, 4, 0, 0, 2, 2`: `_build/phase7/board-capture.json` started
at `2026-09-09T00:51:37Z` and `_build/phase7/acceptance.json` at `2026-09-09T01:29:57Z`.
The second is a plain repeat after a board reset, so the sequence is reproducible rather
than a single observation.

The known networking EtherType/receive-metadata clock-domain-crossing concern did not
affect this board run. IPv4/UDP traffic reached the parser, the other-destination-port
case left all parser counters unchanged, and the following selected packet was processed
with the expected counters. This is direct evidence for the exercised traffic and clock
conditions; it is not a general CDC proof for every phase relationship or frame type.

| Case | Sequence | Packets | Updates | End markers | Diagnostics | CRC / IP errors | Gaps / duplicates |
| --- | ---: | ---: | ---: | ---: | ---: | --- | --- |
| Single message, partial tail | 100 | 1 | 1 | 1 | 0 | 0 / 0 | 0 / 0 |
| Two messages, 1 + 2 entries | 101 | 2 | 4 | 3 | 0 | 0 / 0 | 0 / 0 |
| Sequence gap | 103 | 3 | 5 | 4 | 1 | 0 / 0 | 1 / 0 |
| Duplicate | 103 | 4 | 5 | 4 | 2 | 0 / 0 | 1 / 1 |
| After duplicate | 104 | 5 | 6 | 5 | 2 | 0 / 0 | 1 / 1 |
| Other destination port | 900 | 5 | 6 | 5 | 2 | 0 / 0 | 1 / 1 |
| After filtered packet | 105 | 6 | 7 | 6 | 2 | 0 / 0 | 1 / 1 |
| Late bad FCS, simulation | 106 | 7 | 8 | 7 | 2 | 1 / 0 | 1 / 1 |
| Bad IPv4 checksum, simulation | 107 | 8 | 9 | 8 | 2 | 1 / 1 | 1 / 1 |

All entries use security ID 1234 and price mantissa -123. The independent XML-driven
oracle verifies the sender's payloads and expected parser counts. All payloads end on
partial wide beats. Counter matching establishes the selected functional cases; it is not
full field-by-field UART event capture.

## Build and run on the board

`check.sh` writes **`cme_feed_parser_validation_harness_arty.v`**. This one generated file
contains the complete networking, parser, sink and board hierarchy and elaborates on its
own with `cme_feed_parser_validation_harness_arty` as the synthesis top.

With Vivado installed and licensed:

```sh
vivado -mode batch -source validation/phase7/build.tcl -tclargs _build/phase7/vivado
```

The Tcl builds `cme_feed_parser_validation_harness_arty` on `xc7a100tcsg324-1` against
this repository's own `validation/constraints/cme_arty.xdc`, saves routed timing,
utilization, CDC, clock-interaction and DRC reports, and writes a bitstream only when the
reported worst setup and hold paths pass.

The XDC models the DP83848J 100 Mb/s MII receive interface from the incoming 25 MHz
`eth_rx_clk`: T2.5.2 supplies a 10 ns minimum and 30 ns maximum clock-to-output delay for
`eth_rxd[*]`, `eth_rx_dv`, and `eth_rxerr`. These are PHY-pin values. Arty PCB
data-versus-clock trace skew has not been characterized or included, so routed timing is
still first-order interface evidence. The completed implementation passed setup and hold
timing with this model. No numerical WNS/WHS values are stored in the board-capture JSON;
retain the Vivado reports when numerical margin is needed. The parser-only Arty reports
in `retargeting.md` do not cover this composed board harness.

This validation profile assumes the link negotiates **100BASE-TX**. At 10 Mb/s the PHY
drives 2.5 MHz MII clocks, which needs a separate timing constraint set; the current UART
divisor also relies on the 25 MHz application clock. Confirm a 100 Mb/s link on the host
and jack indicators before running the cases.

Program `_build/phase7/vivado/cme_feed_parser_validation_harness_arty.bit` using Vivado
Hardware Manager. Connect the board's Ethernet jack directly to host interface
`enx207bd25880ef` and its USB UART to the host. Set `sw[0]` high, press/release `btn[0]`,
and wait for PHY release and a 100 Mb/s link. Then run, substituting the actual serial
device:

```sh
sudo python3 validation/phase7/board_acceptance.py run \
  --serial /dev/ttyUSB1 \
  --output _build/phase7/board-capture.json
```

`--iface` defaults to `enx207bd25880ef`; pass it explicitly to override that interface.
Prepare that interface first — unmanage it, disable IPv6 and flush its address per
[validation/README.md](../validation/README.md). Background host traffic reaches the
network counters ahead of the port filter, so it can break both the all-zero baseline
check and the expected tuple below.

Raw Ethernet sending requires `CAP_NET_RAW` (the example uses `sudo`). The UART baseline
must be all zeros; a nonzero baseline fails with a request to reset the board. The sender
waits for two expected snapshots after each datagram. A healthy run prints fourteen `PASS`
lines and finishes with counters `13, 237, 33, 4, 0, 0, 2, 2`. JSON output includes per-case
observations, pass/fail, UTC time, interface, serial path, the installed networking-package
record, and hashes of the integrated board RTL, parser RTL, constraints and schema. A
`.uart.bin` file retains the captured bytes.

The ordinary NIC adds FCS itself, so the host acceptance sequence excludes the
simulation-only bad-FCS case. Do not append the simulation FCS to NIC-transmitted Ethernet
frames. To regenerate fixtures without sending anything:

```sh
python3 validation/phase7/board_acceptance.py vectors _build/phase7
```

The MTU-scale cases are in the board run and in the payload fixtures, but deliberately not
in `mii_vectors.txt`: iverilog is the elaboration and compile gate, and functional coverage
of heavy traffic lives in Cyclesim, in
`test/cme/validation_core/validation_core_heavy_traffic_tests.ml`. That suite mirrors this
acceptance sequence packet for packet, so it fails before anyone reaches for hardware.

### Exploratory traffic

`board_acceptance.py run` is the fixed pass/fail acceptance: it asserts absolute counter
tuples, so it requires a freshly reset board. For anything else — soak runs, one-off
shapes, malformed messages — use the flexible sender, which compares before/after deltas
against its own model rather than absolute tuples:

```sh
sudo python3 validation/phase7/feed_traffic.py --iface enx207bd25880ef --serial /dev/ttyUSB1 \
  --count 2000 --shape mtu-deep,mtu-wide --last-only \
  --inject bad-size@20,beyond-packet@30 --bad-ip-after 40 --output _build/soak.json
```

`bad-size` and `beyond-packet` replace a message body with a short raw message, so they
fit any shape. `unsupported` instead prefixes a further message, and the `mtu-*` shapes are
by construction the largest that fit a datagram, so pairing the two overflows the MTU and
the run is refused before anything is sent. Give it a shape with room to grow — say
`--shape 8x4` — in a separate run.

Two soak runs are recorded. `_build/soak.json` offered 2000 MTU-sized datagrams
(2 953 148 bytes) alternating deep and wide in 0.23 s, and `_build/soak_injections.json`
offered 20 000 datagrams at `8x4` (26 677 500 bytes) in 2.16 s with `unsupported`,
`bad-size` and `beyond-packet` injections and one corrupted IPv4 checksum. Both reported an
observed counter delta identical to the prediction. The offered rate of roughly 99–102 Mb/s
saturates the 100BASE-TX link, so it bounds the Arty adapter rather than the parser.

`--dump` writes the frames to disk instead, needing neither privileges nor a board. A bad
Ethernet FCS cannot be provoked this way: the NIC generates the real one, so `crc_errors`
is reachable only from the MII vectors and the Cyclesim suite.

**Sequencer session state.** The counters are deltas and need no reset, but the parser's
expected sequence number is session state and the 36-byte UART record does not carry it —
it is a magic word and eight counters. The board therefore cannot be asked where its
sequencer is. `feed_traffic.py` remembers it in `_build/phase7/sender_state.json`, keyed by
interface and destination port, so repeated runs continue rather than replaying an
already-consumed range. An all-zero UART baseline means the board was reset and the record
is discarded. If the board carries traffic this script did not send, the position is
genuinely unknowable and the run refuses, asking for a board reset or an explicit
`--assume-next-sequence N`.

Passing `--sequence` explicitly still forces whatever you ask for — a replay of an old
range, or a jump forward — and the prediction accounts for it, so
`--sequence <old start>` correctly predicts a run of duplicates rather than a clean pass.

## Acceptance status

- **7.1 complete:** one native Hardcaml harness instantiates networking, parser and sink;
  its self-contained RTL hierarchy elaborates and the installed networking package is
  recorded.
- **7.2 complete:** port selection, eight counters, LEDs, atomic UART snapshots, separate
  late-network status, and automated host comparison implemented — now in Hardcaml and
  covered by `dune runtest`.
- **7.3 complete:** all selected cases pass full MII RTL simulation, and all fourteen
  physical board cases — the seven base cases and the seven MTU-scale cases added
  afterwards — passed through the programmed Arty Ethernet and UART interfaces, in two
  separate captures. Sustained traffic from the flexible sender matched its predicted
  counter deltas across repeated runs on the same board.
- **7.4 complete:** the setup, sender command, expected observations, and captured result
  are recorded. Vivado synthesis/implementation passed the setup and hold gate and the
  programmed bitstream produced the expected final counters. The capture is
  `_build/phase7/board-capture.json`, with raw UART data in the adjacent `.uart.bin` file.

Phase 7 functional board acceptance is complete. Arty PCB receive-clock/data skew remains
absent from the first-order PHY timing model, and the passing EtherType cases bound the
observed CDC result to this test rather than establishing a general structural CDC proof.
