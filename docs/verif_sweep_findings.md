# Verif Sweep — findings log

Things the verification sweep turned up that outlive the phase that found them. Two kinds:

- **RTL findings** — behavior in `lib/` that the suites pinned down. The sweep's job is
  coverage, not fixes, so the default is to record rather than change; each entry says what
  the current suites do about it and what a fix would have to reckon with. An entry that is
  later fixed stays here, marked **resolved**, with what changed and why.
- **Process findings** — tooling and workflow facts that cost time once and should not cost
  it twice. The durable rules from these are folded into `test/test_architecture.md`'s
  "Settled Conventions"; this file keeps the incident and the reasoning.

Append per phase. Nothing here is a TODO list — resolve or delete an entry deliberately.

The numbering is inherited from `hardcaml_networking`, where these blocks and their suites
were first written. It is kept rather than renumbered so a `See findings RTL-6` comment
means the same thing in both repositories. Entries that were specific to the Ethernet MAC
(RTL-1, RTL-2, PROC-3) are not reproduced here — nothing in this repository has the code
they describe.

---

## Phase 2 — the common blocks and the UART

### RTL-3. `Clk_div` had no divisor — the ratio was hardcoded at four — **resolved**

**Where:** `lib/common/clk_div.ml`.

**What:** the whole module used to be

```ocaml
let cnt = reg_fb spec ~enable:i.en ~width:2 ~f:(fun x -> x +:. 1) -- "cnt" in
{ O.dst_clk = msb cnt }
```

The `~width:2` was a literal, so the division ratio was fixed at four and there was no
port, optional argument or functor parameter that changed it. A property that swept the
output period across divisor values had nothing to sweep.

**Resolution:** `create` takes `?(divisor = 4)` and computes the counter width from it. The
ratio must be a power of two and at least two, checked at elaboration time by
`counter_width` so a bad ratio fails where it is written rather than as a width error from
inside Hardcaml. Two is the floor because a divisor of one asks for a zero-width register —
the same trap RTL-4 describes.

**What the suite does:** two axes. The ratio, as a `Make_testbench` functor instantiated at
2, 4, 8, 16 and 32; and the enable schedule — arbitrary interleavings of run, hold and
clear — against a fold over the same schedule. The schedule is the sharper of the two: a
free-running period measurement cannot distinguish a counter that occasionally drops or
double-counts an enable, and the schedule property can, because the model tracks the count
rather than the phase.

**What the parameterization does not change.** The module's header comment disclaims
correctness above ~150 MHz and points at `hardcaml_xilinx` for real clocking primitives.
This is a counter MSB, not a clock resource, and an argument that makes it look like a
general clocking primitive is exactly the use that comment warns against. The header says
so explicitly for that reason.

### RTL-4. `Second_pulse` did not elaborate at `clk_freq = 1` — **resolved**

**Where:** `lib/common/second_pulse.ml`.

**What:** the counter width was computed as `Int.ceil_log2 clk_freq`, which is `0` for
`clk_freq = 1`, and Hardcaml rejects a zero-width register:

```
("Width of signals must be >= 0" (width 0))
```

Verified directly rather than inferred — elaborated at 1, 2 and 3; 1 raised, 2 and 3 were
fine. The failure was loud, but the message never mentions `clk_freq` and sends the reader
into `Reg_spec`.

**Resolution:** `counter_width` is `Int.max 1 (Int.ceil_log2 clk_freq)`, with `clk_freq < 1`
refused by name. A `clk_freq` of one is legal and degenerate rather than an error — a clock
whose period is a second makes every cycle a second, and the pulse is high on every one —
so the floor widens the counter instead of refusing the ratio. One extra bit costs nothing
and the terminal compare against `clk_freq - 1` is still exact.

**What the suite does:** instantiates at 3, 4, 5, 8, 10 and 16 — both powers of two, where
the terminal count coincides with the counter's natural wrap, and non-powers, where it does
not. That pairing is what would catch a counter that rolled on the wrap instead of on the
compare; a suite that only ran at powers of two could not.

### RTL-5. `Uart_tx` carried four pieces of dead weight — **resolved**

**Where:** `lib/uart/uart_tx.ml`. None of these was a bug; all four were things a reader had
to rule out before trusting the module.

- **`frame` was computed and never used.** `let frame = concat_msb [ zero 1; byte; one 1 ]`
  built the complete ten-bit frame — start bit, payload, stop bit — and nothing read it. The
  transmitter drives the line from `mux data_place_counter.value (bits_lsb byte)` instead.
  It read like the remains of a shift-register implementation that was replaced by a mux.
  The two would not agree about bit order without care, which is why the suite asserts the
  wire order directly (`0x01` and `0x80`, one bit each at opposite ends) rather than only
  that the byte round-trips.
- **`DONE` was unreachable.** The state was enumerated and no transition targeted it; `STOP`
  goes to `IDLE`. It had no arm in the output `switch` either, so it would have fallen
  through to the `tx_d <--. 1` default and driven mark — harmless if reached, but it could
  not be.
- **The sub-scope was discarded.** `let _scope = Scope.sub_scope scope "uart_tx" in` bound to
  a name that starts with an underscore and was never used, so the module's internals were
  not hierarchically named in waveforms.
- **`keep` was tied to zero.** The convention is to OR-reduce a module's internal debug
  signals into `keep` so synthesis does not prune them; returning `zero 1` retains nothing.

**Resolution:** all four removed or wired up. `keep` now OR-reduces the bit counter and the
FSM state. Read what that means before using it as a status line: it goes high on the first
frame and stays high, because the bit counter rests at seven rather than returning to zero.
What is worth freezing is that it depends on the internals at all — a tie-off retains
nothing — and the suite freezes exactly that.

### RTL-6. A clear cancels an in-flight delayed edge in `Helper_circuits`

**Where:** `lib/common/helper_circuits.ml`, `rising_edge_delayed` / `falling_edge_delayed`.

**What:** these are `delay_by spec ~n_cycles (edge_detector spec x)`, and the delay chain
carries the same `spec` — so the same clear. If a clear arrives on the cycle an edge is
detected, the edge is combinationally present that cycle but the register that would carry
it is cleared on the same edge, and it never emerges. Visible in the expect-test golden as
an entirely empty `falling_delayed` row: the clear cycle drives `x` low, `falling` is high
during it, and the delayed copy never appears.

The two directions then part ways, because the clear has also zeroed the history register:

- A rise whose input stays high is re-detected on the cycle after the clear, so the detector
  emits a two-cycle pulse and the delayed copy arrives exactly once, one cycle late.
  Deferred, not lost.
- A fall is gone. A low input against a zeroed history is not an edge, so there is no second
  detection and no delayed pulse at all.

**This is correct**, not a defect — a clear is supposed to flush the pipeline — but it is the
kind of thing that gets rediscovered as a bug. The available workaround, building the delay
chain on a clear-free spec, is worse: it would hand the consumer a delayed edge for a
transition its own reset caused, describing a frame that no longer exists. Callers that need
the edge across a reset have to hold it themselves.

**The consumer in this repository** is `Uart_rx`'s start-bit detect — a falling detector, so
a clear coincident with the start bit swallows the frame. That is the behavior the `uart_rx`
suite's "a clear partway through a frame drops it" property pins down, and dropping the frame
rather than announcing a corrupted byte is the right answer.

Related and separate: sampled at `before_edge`, a synchronous clear's effect appears on the
cycle *after* the clear, not during it — the registers still hold their old contents while
the clear is being applied. The suite asserts both halves of that explicitly, because an
assertion written the obvious way ("nothing survives from the clear onward") is off by one
and fails.

### RTL-7. `Uart_rx` samples on the baud tick, not on an oversampling clock

**Where:** `lib/uart/uart_rx.ml`.

**What:** the receiver takes the first tick after the start edge as its phase reference and
samples every tick thereafter. With the transmitter and receiver driven from the same
`Second_pulse` tick — which is what `uart_loopback_validation_harness` does — the sampling
point sits wherever the start-bit edge happened to fall relative to that tick, rather than at
mid-bit. A conventional receiver runs a 16x oversampling clock and re-centres.

**Why it works anyway, and where it stops working.** The phase is arbitrary but *stable*: it
is fixed for the whole frame, so as long as it lands inside the symbol it lands inside every
symbol. It fails when accumulated drift between the two clocks moves the sample point across
a bit boundary within one frame — ten symbols of drift — which a shared clock on one board
cannot produce and two independent crystals eventually can.

**What the suite does:** sweeps `tick_phase` across every value in `[1, cycles_per_symbol)`
and asserts the round trip at each. Phase zero is excluded and is not an off-by-one: there
the falling edge and the tick land on the same cycle, `START` has not been entered yet, and
the receiver spends the frame one symbol behind. That exclusion is the documented shape of
the block, not a gap in the sweep.

**Not fixed here** — a 16x sampler is a real change to the block and wants a real reason.
Recorded so the next person to push the baud rate up knows which end to look at.

### PROC-1. `[@@ocamlformat "disable"]` is an error, and it fails `@lint` unnoticed

**What:** this ocamlformat (Jane Street fork) rejects the item-level attribute outright,
wherever it is attached and however it is indented:

```
Error: Invalid ocamlformat attribute. Ocamlformat can only be disabled at toplevel
(e.g [@@@ocamlformat "disable"])
```

It is an **error**, not a warning, and it fails `dune build @lint`.

**Why it goes unnoticed:** `dune build` and `dune runtest` are both clean with it present —
only the lint alias fails, and its output is a wall of progress lines that buries the error
blocks.

**What to write instead:** the floating pair, which preserves hand alignment and passes lint:

```ocaml
[@@@ocamlformat "disable"]

let create
  ?(preamble_length     = 7)
  ...
;;
[@@@ocamlformat "enable"]
```

Both forms work inside a `struct`, indented to the enclosing level. Every `disable` needs a
matching `enable` — an unclosed one silently exempts the rest of the file from formatting.

**How to not repeat it:** check the *exit code*, not the output. `dune build @lint` piped
into `tail` reports `tail`'s status, which is how "green" gets recorded. Run it bare, or
capture `$?` before the pipe.

### PROC-2. An empty `(**)` makes ocamlformat skip the whole file

**What:** ocamlformat reports

```
ocamlformat: ignoring "<file>" (misplaced documentation comments - warning 50)
```

and formats nothing in that file. `@fmt` then stays red no matter how many times it is
promoted, which reads like a formatter bug rather than a source problem.

`(**)` is an empty *doc* comment (`(**` … `*)`), and the compiler cannot attach it to
anything in the AST. Write `(* *)`, or say something in it.

### PROC-4. `after_edge` is degenerate for a combinational-off-input block

**What:** `Helper_circuits`' edge detectors are `~:x_d &: x` — combinational in the current
input and the registered previous one. At `after_edge` the register has already taken this
cycle's input, so `x_d = x` and *both detectors read zero unconditionally*, whatever the
input did. A suite that sampled `after_edge` out of habit would observe an all-false column
and could still pass a carelessly written test.

The rule generalizes: sample `after_edge` when the observable is a register, `before_edge`
when it is combinational in the current input — and when it is the latter, `after_edge` is
not merely the wrong choice, it is *information-free*. The `helper_circuits` suite asserts
the degeneracy directly rather than leaving it as a comment, so the reasoning cannot decay.

`Uart_tx` is the same shape for a different reason: `uart_tx` is an `Always.Variable.wire`
driven off the current state, so `after_edge` reports the *next* symbol and shifts the whole
frame by one. `Uart_rx`'s `d_out_valid` is the same, which is why its suite samples
`before_edge` too.

### PROC-5. A `Signal.t`-function module needs a wrapper DUT, and `delay_by 0` needs a wire

**What:** `helper_circuits.ml` exports plain `Signal.t -> Signal.t` functions over a
`Reg_spec.t`, not an `I` / `O` / `create` triple, so there is nothing for
`Sim_fixture.Make` to instantiate. The suite defines a wrapper `module Dut` inside its own
testbench — one input bit, one output per helper — and instantiates every helper against a
shared spec. Instantiating them together rather than one wrapper per function is what makes
`rising_edge_delayed` checkable *against* `rising_edge_detector` in a single simulation,
which is the whole content of its definition.

One mechanical trap: `delay_by spec ~n_cycles:0 x` returns `x` itself, and a circuit output
cannot be an input port directly. Wrap it — `wireof (Helper_circuits.delay_by spec
~n_cycles:0 i.x)` — or the wrapper will not elaborate. Worth an output of its own: it is the
base case of the recursion and the only place the identity is checkable.

### PROC-6. A module that prints at initialisation corrupts the first expect test

**What:** several `lib/` modules opened with

```ocaml
let () = Stdio.print_endline "=== Imported UART TX ==="
```

which runs when the module is linked, not when anything calls it. In an inline-test runner
that is before the first `let%expect_test` captures, so the banner lands in whichever test
happens to run first and the golden records it — a golden that then changes whenever the
link order does.

**Fix applied:** all of them removed. If a module needs to announce itself during a
bring-up run, do it from the executable's `main`, where the output belongs to a program
rather than to a link.
