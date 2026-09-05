# FeedParser_of_Hardcaml

Portable Hardcaml CME MDP 3.0 feed parser, starting at a framed 64-bit UDP payload
stream. The current implementation is the **Phase 0 inactive skeleton**: it
accepts no payloads or sequencer controls and emits no events.

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

Next is Phase 1: stream fixtures, bounded FIFOs, and the two-beat byte aligner.
Production schema pinning and the independent decoder belong to Phase 4, which
can proceed alongside the streaming work.
