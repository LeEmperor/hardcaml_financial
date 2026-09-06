# FeedParser_of_Hardcaml

Portable Hardcaml CME MDP 3.0 feed parser, starting at a framed 64-bit UDP payload
stream. The public parser top is still an **inactive skeleton**: it accepts no
payloads or sequencer controls and emits no events. The streaming foundation and
Phase 2 canonical packet pipeline and Phase 3 message iteration are implemented
and tested separately.

The [delivery plan](docs/cme_mdp3_10g_parser_plan.md) describes the phases and
acceptance criteria. The [Phase 0 contracts](docs/phase0_contracts.md) define the
module hierarchy, reset/enable behavior, control priority, internal streams, and
provisional event layout. Follow the
[project conventions](docs/hardcaml_project_conventions.md) for source changes.

Use the existing `5.2.0+ox` opam switch (override with `OPAM_SWITCH`):

```sh
./bootstrap.sh
./scripts/with-switch.sh dune build
./scripts/with-switch.sh dune runtest
./scripts/with-switch.sh dune build @fmt
./scripts/with-switch.sh dune exec lib/common/generate.exe -- cme
```

`./bootstrap.sh --install-deps` installs the project dependencies if needed.
`./tools/dune_fmt.sh` applies the pinned formatter. The CME generator writes
`cme_mdp3_feed_parser.v`; use `-- uart` (or no argument) for the existing UART
target. Generated Verilog is ignored by Git.

Phase 1's bounded FIFOs, two-beat byte aligner, and pass-through fixture are
implemented separately from the inactive parser top. The
[Phase 0–1 verification record](docs/phase01_verification.md) maps their active
Step/Cyclesim unit, Quickcheck, and expect suites.

[Phase 2 packet extraction and sequencing](docs/phase2_packets.md) now provides
`Packet_pipeline`: a tested canonical packet stream with header removal, sequence
admission, ordered diagnostics, duplicate draining, and fenced reset/resync
controls.

[Phase 3 message iteration and recovery](docs/phase3_messages.md) adds
`Sbe_message_iterator`, the composed `Message_pipeline`, and `Event_orderer`.
They expose bounded message bodies, recover at trustworthy message or packet
boundaries, and serialize diagnostics with downstream decoder events. Template
admission is configurable without selecting a production schema. The public
event-producing top remains inactive pending decoder integration.

Optional backend checks and device project generation:

```sh
./scripts/with-switch.sh dune build @rtl-check
./scripts/with-switch.sh dune exec synthesis/xilinx_reports.exe -- stream-foundation \
  -dir _build/xilinx-reports/dry-run -part xc7a100tcsg324-1 \
  -clock clock_i:156.25 -hierarchy -full-design-hierarchy true -jobs 1
```

Yosys checks hierarchy and Icarus checks elaboration. The reporting command
invokes Vivado only with `-run`; see [reporting](docs/hardcaml_reports.md) for
profiles and evidence limits.

[Phase 4 schema tooling and reference decoding](docs/phase4_schema.md) pins CME
Production schema ID 1/version 13, generates template-46 extraction descriptors
during the Dune build, and supplies an independent XML-driven golden decoder with
synthetic and classic-PCAP fixtures. Phase 5 remains responsible for the RTL MBP
decoder and public event-producing composition.
