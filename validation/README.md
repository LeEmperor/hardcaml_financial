# Board validation

Everything needed to run a design on the Arty A7-100T rather than in a simulator. This is
the runbook: it is copied into the release bundle as `RUNBOOK.md`, so it has to stand on
its own for someone who has the bitstream and none of the source.

`validation/` lives outside `lib/` on purpose. `lib/` holds the reusable blocks; this
directory holds the scaffolding that drives them on real silicon, which is throwaway by
design and should never be something a block depends on.

## Contents

| File | What it is |
| --- | --- |
| `board_scaffolding.ml` | shared Arty plumbing: per-domain reset synchronizers, the 25 MHz PHY reference clock, PHY hard-reset sequencing, the heartbeat LED, the RX-drain pulse, and CDC helpers |
| `uart_loopback_validation_harness.ml` | the bring-up top: a UART echo, RX to TX |
| `constraints/unified_tx_rx.xdc` | pin constraints, named to line up with `Arty_board_top`'s I/O fields exactly |
| `constraints/arty_master_DO_NOT_EDIT.xdc` | Digilent's untouched vendor master, for reference |
| `uart_app.py` | host-side companion: sends a payload and classifies what comes back |
| `test_uart_app_echo.py` | offline check of that classifier — no board, no serial port |

`board_scaffolding` is deliberately a set of plain helper functions rather than a Hardcaml
sub-module: they build signals directly into the caller's circuit, with no I/O record and
no hierarchy boundary, so the caller keeps control of signal-creation order and the emitted
RTL is identical to hand-inlined plumbing.

## Building the bitstream

Emit the harness RTL:

```sh
./scripts/with-switch.sh dune exec lib/common/generate.exe -- uart-loopback-validation
```

That writes `validation/uart_loopback_validation_harness.v`. Add it and
`constraints/unified_tx_rx.xdc` to a Vivado project targeting `xc7a100tcsg324-1`, set the
harness as the top, and run implementation.

The XDC constrains every pin in `Arty_board_top`, including the ones this harness does not
use. That is intentional: the pin contract is the stable thing and the harness is not.
`test/validation/board_hierarchy/` asserts that the emitted top still has exactly the port
names and widths the XDC binds to, so a rename in `Arty_board_top` fails a test rather than
failing in Vivado.

## Running it

Controls:

- `btn[0]` — active-high reset. It is a raw asynchronous button, synchronized into the
  clock domain by `Board_scaffolding.reset_sync`.
- `sw[0]` — enable. The UART blocks do nothing with it low.

LEDs:

| LED | Meaning |
| --- | --- |
| `led[3:0]` | lower nibble of the last received byte |
| `led0_r` | heartbeat, a 0.5 Hz toggle — if this is dark, the design is not running |
| `led1_g` | `phy_ready`: the PHY is out of its ~0.66 ms hard reset |
| `led2_b` | `d_out_valid`: a frame is in its stop window |

Then, from the host:

```sh
python3 validation/uart_app.py --echo --port /dev/ttyUSB1
python3 validation/uart_app.py --echo --count 256 --pattern alternate
```

Needs `pyserial`. On Linux the Arty's USB-UART is normally `/dev/ttyUSB1` — `ttyUSB0` is
the JTAG channel — and on macOS a `/dev/tty.usbserial-*`.

Exit code 0 means every byte came back, on time and intact. Anything else prints a tally
and the index of the first fault.

## Why the tally has five entries

A byte that comes back late, a byte that comes back wrong, a byte that comes back twice,
and a byte that does not come back are four different bugs, and collapsing them into
"failed" is how a marginal baud rate gets recorded as a framing problem. `uart_app.py`
classifies each sent byte as one of `on-time`, `late`, `corrupt`, `duplicate` or `lost`,
and reports where the first fault was as well as how many there were.

Read the patterns the same way. `--pattern ones` sends `0xFF`, which on the wire is
indistinguishable from an idle line except for the start bit — so a receiver that announces
a byte without ever having seen a start bit passes every other pattern and fails that one.
`--pattern zeros` is the mirror: an all-space frame, which is what a receiver that mistook
the start bit for data loses. `counter` is the only pattern that can tell a dropped byte
from a duplicated neighbour.

The classifier is pure and separate from the serial port, which is what lets
`test_uart_app_echo.py` check all five outcomes with no hardware and no root:

```sh
python3 validation/test_uart_app_echo.py
```

Run that after touching the classifier. It is fast and it is the only part of the host side
that anything checks automatically.

## The phase caveat

`Uart_rx` samples on the same baud tick the transmitter runs on, not on a 16x oversampling
clock, so its sampling point sits wherever the start-bit edge happened to fall relative to
the tick rather than at mid-bit. The phase is arbitrary but stable — fixed for the whole
frame — so it works fine for a bring-up echo at 115200 on one board with one clock. It is
the first thing to fix if this ever has to hold a line at speed, or talk to a device with
its own crystal. See finding RTL-7 in `docs/verif_sweep_findings.md`.

## When it does not work

Work down this list; each step rules out everything above it.

1. **`led0_r` dark.** The design is not running. Check the bitstream loaded, and that
   `btn[0]` is not held.
2. **Heartbeat fine, nothing echoes.** Check `sw[0]` is up — with the enable low the
   receiver's FSM does not advance, and a start edge arriving during that window is *lost*
   rather than deferred, because the edge detector's history register is not gated by the
   enable. That is asserted by the `uart_rx` suite, so it is behavior rather than a
   suspicion.
3. **Echoes, but garbage.** Baud mismatch. The harness derives its tick from
   `Second_pulse ~clk_freq:868`, which is 100 MHz / 868 = 115_207 baud. If you changed
   either number, change the host's `--baud` to match.
4. **Echoes intact but the tally says `late`.** The link is working and slow. Raise
   `--timeout`, or `--gap` the sends apart, before believing there is a framing bug.
5. **Right port?** `ttyUSB0` is JTAG. Talking to it looks exactly like a dead design.
