# hardcaml_financial

FPGA market-data hardware written in Hardcaml. The goal is a feed parser — take a wire
format in, unpack the messages, and build internal state from them — starting with the CME's
SBE-encoded MDP 3.0. Right now what exists is the front end that gets bytes into the chip: a
UART transceiver, an Arty A7-100T board contract, and the bring-up harness that echoes a
byte back at you so you know the link works.

Written in [Hardcaml](https://github.com/janestreet/hardcaml) as a learning project. Any
suggestions or contributions welcome.

Targeted at the Arty A7-100T (`xc7a100tcsg324-1`).

---
<br>

# Repository Layout

```
lib/
  common/   helper circuits, Arty board pin contract, clock divider, RTL generator entry point
  uart/     UART transmitter and receiver, plus a board bring-up top
  cme/      the feed parser itself — CME MDP 3.0 unpacker, UART framing layer (both skeletons)
test/       verification suites, mirroring the lib/ layout
validation/ board-level harness (Arty scaffolding, XDC constraints, host-side Python)
synthesis/  out-of-context Vivado resource and timing reports
scripts/    switch wrapper, RTL generation with a provenance manifest, release assembly
tools/      thin wrappers over the dune commands
```

Three longer-form notes live alongside the code:

- `HardcamlDocs.md` — Hardcaml usage notes (Cyclesim, Evsim, the Always DSL, and so on).
- `docs/formatting_guide.md` — source formatting and signal-naming conventions.
- `test/test_architecture.md` — how the verification suites are structured, written from a
  UVM background. Read this before adding a test.

## What is real and what is a skeleton

Worth being blunt about, because the directory layout does not distinguish them:

| Block | State |
| --- | --- |
| `Uart_tx`, `Uart_rx` | working, and verified by a round-trip suite each |
| `Clk_div`, `Second_pulse`, `Helper_circuits` | working, parameterized, verified |
| `Arty_board_top` | a pin contract, not logic — the `create` is a stub of safe defaults |
| `Uart_loopback_validation_harness` | working; echoes a byte, runs on the board |
| `Uart_frame_parser` | ports and state enumeration settled, datapath not written |
| `Cme_feed_parser` | ports settled, outputs tied off, datapath not written |

The two skeletons have suites anyway. That is not coverage of anything yet — it is the diff
that will make the first real datapath reviewable, and it means the ports cannot drift
without something noticing.

<br>

---

# Installation Pre-Requisites

## Automatic
```./bootstrap.sh --install-deps``` verifies you have an [OxCaml](https://oxcaml.org/get-oxcaml/)
[opam](https://opam.ocaml.org/) switch, installs the project's package dependencies into it,
and writes `env.sh`.

It does **not** create the switch for you — if the switch is missing, bootstrap stops and
prints the `opam switch create` line to run. Create it once (see Manual below), then rerun
bootstrap.

WARNING: The dependency install may take up to 30 minutes!

<br>

## Manual
This is the recommended way of installing, as any breaking objects won't damage the state of
the repo.

#### OxCaml
OxCaml install:

```opam switch create 5.2.0+ox 5.2.0+ox --repos ox=git+https://github.com/oxcaml/opam-repository.git,default```

The scripts in `./scripts` and `./tools` default to a switch named `5.2.0+ox`. If you name
yours something else, export `OPAM_SWITCH=<your-switch-name>` (or edit the generated
`env.sh`) so the wrappers can find it.

You will also want the following libraries for [OCaml](https://ocaml.org/):

1. ```dune```
2. ```core```
3. ```hardcaml```
4. ```hardcaml_xilinx_reports```
5. ```ppx_hardcaml```
6. ```ppx_jane```
7. ```hardcaml_circuits```
8. ```hardcaml_waveterm```
9. ```hardcaml_step_testbench```
10. ```ppx_expect```
11. ```base_quickcheck```
12. ```alcotest```
13. ```ocamlformat```
14. ```ppx_js_style```
15. ```ocaml-lsp-server``` (for editor integration)

Use ```opam install --switch=5.2.0+ox -y dune core hardcaml hardcaml_xilinx_reports ppx_hardcaml ppx_jane hardcaml_circuits hardcaml_waveterm hardcaml_step_testbench ppx_expect base_quickcheck alcotest ocamlformat ppx_js_style ocaml-lsp-server``` to install the dependency
set manually,

```OR``` let the bootstrap ```--install-deps``` flag handle it for you. You can also opt to
install the main OxCaml switch yourself, and then let the dependencies afterwards get handled
by ```./bootstrap.sh```.

<br>

#### Ubuntu/Debian (tested on 22.04/24.04)
```sudo apt install opam build-essential pkg-config```

#### macOS
```brew install opam```

#### Windows
```lmao```

<br>

---

# Setup

Run ```./bootstrap.sh```, followed by ```source ./env.sh``` to select the OxCaml opam switch
for the current shell. `env.sh` is written *by* bootstrap and is not checked in, so run
bootstrap first.

The project builds entirely with [dune](https://dune.build/). All commands go through
`./scripts/with-switch.sh` so they run on the `5.2.0+ox` switch:

```sh
./scripts/with-switch.sh dune build      # build everything
./scripts/with-switch.sh dune runtest    # run all suites
./scripts/with-switch.sh dune fmt        # format
./scripts/with-switch.sh dune build @lint # Jane Street style checks
```

`dune runtest` covers the inline expect and Quickcheck suites under
`test/<domain>/<block>/`. The legacy assertion harnesses in those directories are compiled
by `dune build` and deliberately never run — see `test/test_architecture.md`.

`@lint` is a separate alias on purpose: `ppx_js_style` is a style checker, not a PPX the
build needs, so it does not run during every compile. Check its **exit code**, not its
output — piping it into `tail` reports `tail`'s status, which is how a red lint alias gets
recorded as green.

Generated VCD files can be opened with `./tools/open_wave.sh <vcd-file>`.

<br>

---

# Generating RTL

`lib/common/generate.exe` emits Verilog, one subcommand per target, so there is no
comment-toggling of the generator source:

```sh
./scripts/with-switch.sh dune exec lib/common/generate.exe -- uart-test-top
./scripts/with-switch.sh dune exec lib/common/generate.exe -- uart-loopback-validation
```

| target | what it emits |
| --- | --- |
| `uart-test-top` | board UART bring-up top |
| `cme-feed-parser` | CME MDP 3.0 unpacker |
| `uart-frame-parser` | UART framing layer |
| `uart-loopback-validation` | board UART echo harness, RX→TX bridge |

Run `dune exec lib/common/generate.exe -- -help` for the current list. Output paths are
resolved against the repo root, so the RTL lands in a stable place no matter where the
binary ran.

To emit every target at once, plus a `MANIFEST.txt` recording the commit and toolchain that
produced them, use `./scripts/generate_rtl.py` (`--list` shows the targets). It verifies each
output was actually refreshed by the run, which is what stops a target that errored out from
leaving last run's `.v` on disk looking current.

Synthesis estimates and resource reports use a separate executable; see
[`synthesis/README.md`](synthesis/README.md).

<br>

---

# Generating Release Candidates

`./scripts/make-release.sh --version v0.1 --require-clean` regenerates the RTL, stages the
release bundles into `release-group/`, checksums and verifies them, and writes the zips to
upload. `--require-clean` refuses to run against uncommitted changes so the manifest names a
published commit.

It does not invoke Vivado: the bitstream and board reports are copied from an existing
project run, so re-run implementation first if the RTL changed. See
[`release-group/README.md`](release-group/README.md) for the bundle layout and the full
release procedure — including what is not yet there to ship.

<br>

---

# Board Validation

`validation/` holds everything needed to run a design on the Arty rather than in a
simulator: the shared board scaffolding, the UART echo harness, the XDC, and a host-side
companion that classifies what comes back rather than just asserting it did. See
[`validation/README.md`](validation/README.md), which doubles as the release runbook.

<br>

---

## Emacs

The repository is a Git-backed Emacs project, so `project.el` and Projectile detect it
without an extra marker file. The checked-in `.dir-locals.el` sets two-space, space-only
OCaml indentation and configures these project commands:

- configure: `./bootstrap.sh`
- compile: `./scripts/with-switch.sh dune build`
- test: `./scripts/with-switch.sh dune runtest`

Run `M-x project-compile` (or Projectile's compile/test commands) from any project buffer.
Eglot users can format the current buffer with `M-x eglot-format-buffer`. Start Emacs from a
shell in which the project switch is selected when using Merlin or Eglot, so `ocamllsp` and
`ocamlformat` come from the OxCaml switch:

```sh
source ./env.sh
opam exec --switch="$OPAM_SWITCH" -- emacs .
```

OCamlFormat uses its Jane Street profile from `.ocamlformat`; `dune fmt` is the
authoritative formatter. `ppx_jane` supplies Jane Street syntax extensions and derivers,
while `ppx_js_style` is a separate style checker. The latter runs only via the Dune `@lint`
alias (or `./tools/dune_lint.sh`), rather than changing normal PPX expansion during every
build.
