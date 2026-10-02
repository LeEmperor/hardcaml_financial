# Test Architecture

Given I come from a more traditional aspect of verification (UVM!), many of these test
things will be related as their UVM counterparts.

Vocabulary:
    "Test Scenario" = "Test"

---

# Settled Conventions

Everything below this heading is decided and in force. Source formatting and signal naming
live in `docs/formatting_guide.md`; this section covers only what that guide does not. The
rules here are the durable half of what the verification sweep found; the incidents behind
them, and the RTL behavior the suites pinned down without changing, are logged in
`docs/verif_sweep_findings.md`.

## The four-file suite layout

For DUT `foo` in domain `<d>`, `test/<d>/foo/` holds:

| File | Role |
| --- | --- |
| `foo_testbench.ml` | `module Dut = Foo`, the `Observation` / `Compact_observation` types, `inputs ~...`, `reset`, drivers, scenarios, `run_*` entry points |
| `foo_unit_quickcheck_tests.ml` | `let%test_unit` examples + `Quickcheck.test` properties, ``~seed:(`Deterministic ...)``, a shrinker where the input type has one |
| `foo_expect_tests.ml` | `let%expect_test` golden traces via `print_s [%sexp (obs : ...)]` |
| `foo_legacy_assertion_test.ml` | the superseded harness, if one existed |
| `dune` | one `(library ... (inline_tests ...))` over the first three modules, plus a separate `(executable)` for the legacy module |

The testbench is the only file that touches `Step` or `Bits`. The other two consume its
typed observations, which is what keeps a scenario shared between a property test and a
golden trace instead of written twice.

The suites in this repository are:

| Suite | DUT | Legacy harness |
| --- | --- | --- |
| `test/common/clk_div/` | `Clk_div` | yes |
| `test/common/second_pulse/` | `Second_pulse` | yes |
| `test/common/helper_circuits/` | the `Signal.t` helpers, via a wrapper DUT | no |
| `test/uart/uart_tx/` | `Uart_tx` | yes |
| `test/uart/uart_rx/` | `Uart_rx` | no |
| `test/cme/cme_feed_parser/` | `Cme_feed_parser` | yes (never ran) |
| `test/common/hierarchy_manifest/` | Hardcaml's hierarchy database itself | n/a |
| `test/validation/board_hierarchy/` | the board harness's pin contract | n/a |

## `-source-tree-root .` is mandatory in every `(inline_tests)` stanza

```
(inline_tests
 (flags
  (:standard -source-tree-root .)))
```

ppx_expect v0.18~preview drops the directory from a test file's path when registering the
test, then rebuilds the path at exit from the bare filename plus `-source-tree-root`,
yielding `_build/default/<basename>` — which does not exist. The trailing flag wins over
the one dune passes (`%{workspace_root}`), and `.` points it at the runner's cwd, where
dune has copied the sources. Copy the explanatory comment along with the flag. Drop both if
a later ppx_expect fixes the path handling.

## Legacy harnesses are compiled, never run

A superseded `printf`/`exit 1` harness becomes `foo_legacy_assertion_test.ml` in the DUT's
directory under a bare `(executable)` stanza. `dune build` compiles it, so it keeps
type-checking against the RTL instead of silently rotting; `dune runtest` never invokes it,
so its output spam and `exit 1` stay out of CI. It carries the
`Tags: [{ "DEPRECATED" ; "ASSERTION_TEST" }]` marker in its header.

A legacy file that is in *no* stanza is not relegated, it is dead — it does not compile at
all and will drift from the RTL unnoticed.

## `hardcaml_verif` — the shared verification library

`test/common/verif/` → library `hardcaml_verif`. Reach for it before writing a helper.

| Module | Contents |
| --- | --- |
| `bits_conv.ml` | `bit : bool -> Bits.t`, `to_bool`, `to_int`, `of_int ~width` |
| `sim_fixture.ml` | `Make (Dut : S)` → `Sim`, `Step`, `create_simulator`, `run_with_timeout ~timeout ~testbench` |
| `generators.ml` | `byte`, `byte_list`, `payload_length`, `tick_spacing` as `Quickcheck.Generator.t` |

A helper that only one suite wants belongs in that suite's testbench. `uart_tx`'s software
receiver and `uart_rx`'s software transmitter both stay where they are, because each is the
*oracle* for one block rather than a shared utility — and they are deliberately not shared
with each other, since a round trip through both would only prove they agree.

`Sim_fixture` deliberately re-exports `Step` rather than wrapping it — suites keep calling
`Step.cycle` / `Step.delay` / `Step.O_data` directly. That is also the seam where an
EventSim backend slots in later as a parallel functor over the same `S`.

## OxCaml: arity is part of the arrow type

Not a style rule — a compile error you will otherwise spend an afternoon on. OxCaml encodes
function arity in the arrow, so `a -> b -> c` (arity two) and `a -> (b -> c)` (arity one,
returning a closure) are *different types*. A function that takes a `Handler.t @ local` and
whose arity is inferred as one lets the local handler escape its region, and every call site
is rejected with:

```
Error: This function or one of its parameters escape their region
       when it is partially applied.
```

pointing at the caller's lambda, not at the real cause. This bites any helper that forwards
a step-testbench `~testbench` argument across a module or functor boundary, because the
inference there has no reason to pick arity two. The fix is to write the parameter's type
out explicitly and unparenthesized — see `run_with_timeout` in `sim_fixture.ml`:

```ocaml
let run_with_timeout
  ~timeout
  ~(testbench : Step.Handler.t @ local -> Step.O_data.t -> 'a)
  =
```

Same reasoning applies to any future `Sim_fixture`-like wrapper around `Step.spawn` or
`Step.wait_for`.

### The other half: a closure over the handler cannot both capture and allocate

`List.map`ing a drive function over a list of stimuli looks like the obvious way to write a
driver, and it does not compile when the closure returns a record:

```
Error: The value "handler" is "local" to the parent region
       but is expected to be "global"
       ... which is expected to be "global" because it is an allocation
```

A closure that captures the local handler must itself be local; a closure that allocates its
result must be global. Wanting both is the error. `List.iter` with a unit-returning body is
fine — no allocation — which is why `List.iter ... ~f:(fun byte -> ignore (drive_byte
handler byte : _))` compiles next to a `List.map` that does not.

The fix is the one every testbench here uses: write the traversal as an explicit `let rec
loop (handler : Step.Handler.t @ local) = function`, whose recursive call is a tail call in
the handler's own region. For a fixed short sequence, a run of `let` bindings works too, and
has the side benefit of pinning evaluation order — OCaml does not fix the order of a list
literal's elements, which matters when each element advances the simulation.

## Which side of the clock edge a suite samples

`Step.cycle` hands back both, and the choice is not stylistic — it decides what the
observation *means*.

- **`after_edge`** is the state the DUT settled into as a result of this cycle's inputs.
  Sample it when the thing under test is a register or a state the block just entered:
  `clk_div` (the divided clock is combinational off the counter register), `second_pulse`.
- **`before_edge`** is what the block was driving *during* the cycle. Sample it when the
  outputs are instructions to a combinational consumer, or are themselves driven off the
  current state. `uart_tx` is the case — `uart_tx` is an `Always.Variable.wire` off
  `sm.current`, Moore with no register between the state and the pin — and `uart_rx`'s
  `d_out_valid` is the same shape.

A suite that samples `before_edge` usually needs `after_edge` as well — not as an
observation but as the next state, so the driver can choose the following cycle's stimulus.
A fixed script silently stops testing anything the moment the FSM's timing changes.

A purely combinational DUT has no such choice — both sides agree. `cme_feed_parser` asserts
exactly that rather than assuming it, so a registered stage cannot be added there without a
test noticing.

A block that is combinational in the *current input* and a registered copy of it is the
third case, and there `after_edge` is not merely the wrong choice — it is information-free.
`Helper_circuits`' edge detectors are `~:x_d &: x`; at `after_edge` the register has already
taken this cycle's input, so `x_d = x` and both detectors read zero whatever the input did.
A suite sampling there sees an all-false column and can still pass a carelessly written
test. `helper_circuits` asserts the degeneracy outright.

One more, for `before_edge` specifically: a synchronous clear's effect appears on the cycle
*after* the clear, not during it — while the clear is being applied the registers still hold
their old contents. The obvious assertion ("nothing survives from the clear onward") is off
by one.

## Goldens for one-bit-per-cycle behavior are waveform rows, not sexps

A sexp list of records is the right golden when the observation is structured. When it is
one bit per cycle, it is not: the reviewable claim about a clock divider, a heartbeat pulse,
an edge detector or a UART line is an *alignment* — which cycle the pulse lands on, how far
the delayed copy trails, where in a frame the byte is announced — and stacked character rows
show that where a list of booleans does not. `clk_div` and `second_pulse` print a single
row; `helper_circuits` prints one labelled row per output with the input row on top;
`uart_rx` prints one character per cycle with `V` marking the stop window. Keep one sexp
golden per suite anyway, over a short scenario, so the typed record itself stays visible.

## Wide values print in hex, in a `Compact_observation`

A 32-bit accumulator rendered as `3736805603` is not reviewable against a standard that
quotes `0xDEBB20E3`, and a 512-bit ingress word in decimal is not reviewable against
anything. Suites whose observations carry wide values keep the typed `Observation.t` in
`int` — that is what `[%test_result]` compares — and give `Compact_observation.t` `string`
fields formatted with `sprintf`, which is what the goldens print. The same record is where
boolean control lines collapse into an `active_outputs : string list`.
`cme_feed_parser` is the example here.

## Hardcaml `mux` saturates on an out-of-range select

It returns the *last* element, not a wrap and not an error. A software model of a mux must
clamp its index the same way (`List.nth_exn values (Int.min index (length - 1))`) or it will
disagree with the RTL on every out-of-range combination.

## A DUT with an optional `create` argument cannot be `include`d

`Sim_fixture.S` wants `val create : Scope.t -> Signal.t I.t -> Signal.t O.t`, and OxCaml
will not erase an optional argument to match it. `Clk_div.create` takes `?divisor`, so its
fixture spells the signature out:

```ocaml
module Fixture = Sim_fixture.Make (struct
    module I = Dut.I
    module O = Dut.O

    let create scope inputs = Dut.create ~divisor:Config.divisor scope inputs
    let name = "Clk_div"
  end)
```

Wrapping that in a `Make_testbench (Config : sig val divisor : int end)` functor lets one
suite instantiate the same DUT at several parameter values. That is not a workaround, it is
the point: a parameter with only one instantiation is a constant with extra steps.

`second_pulse` uses the same shape — its `?clk_freq` defaults to 100 MHz, one pulse every
hundred million cycles, which no simulation reaches — and adds the trick worth copying: the
`Observation` and summary types are declared **outside** the functor, so every instantiation
produces the same type and one list of runner records can carry all six. A property then
runs across the whole set instead of being written out per parameter value.

Choose the parameter values so they disagree about something. `second_pulse` runs at 3, 4,
5, 8, 10 and 16: at a power of two the terminal count coincides with the counter's natural
wrap, and a counter that rolled on the wrap rather than on the compare would pass every
power-of-two instance. Watch for the same trap in any block whose defaults are palindromic —
a byte pattern like `0x55` is symmetric under the bit reversal a wrong-way shift register
performs, so it cannot catch one. `uart_rx` tests `0x01` and `0x80` for exactly that reason.

## A module of plain `Signal.t` functions needs a wrapper DUT

`lib/common/helper_circuits.ml` exports `Signal.t -> Signal.t` functions over a
`Reg_spec.t`, not an `I` / `O` / `create` triple, so there is nothing for
`Sim_fixture.Make` to instantiate. Define a wrapper `module Dut` inside the suite's own
testbench, with one input per argument and one output per function, and instantiate every
function against a shared spec.

Instantiate them *together*, not one wrapper per function. `rising_edge_delayed` is by
definition `delay_by n (rising_edge_detector x)`, and that definition is only checkable if
both are visible in the same simulation — which is the difference between testing the
composition and re-implementing it in the model.

Mechanical trap: a circuit output cannot be an input port directly, and `delay_by spec
~n_cycles:0 x` returns `x` itself. Wrap it in `wireof` or the DUT will not elaborate. Give
it an output anyway — it is the recursion's base case and the only place the identity is
checkable.

## Prefer a protocol-level oracle to a cycle-level one

Where the DUT speaks a protocol, model the *other end*, not the timing. `uart_tx`'s oracle
is `Uart_receiver.decode`, which reconstructs a byte from the symbols the fixture sampled
exactly as a real receiver would; `uart_rx`'s is `Uart_transmitter.frame`, which puts the
ten symbols a real transmitter would send onto the line. The headline property in both cases
is a round trip and is indifferent to how the block chooses to time itself. Running it
across tick spacings and enable stalls is what turns "it emitted the right waveform once"
into "it is tick-driven".

Two supporting habits from those suites:

- **A symbol is an interval, not a sample.** `uart_tx`'s fixture records the line on every
  cycle between two ticks and rejects a symbol whose line moved mid-interval; `uart_rx`'s
  driver *holds* the line for the whole interval rather than pulsing it at the sample point,
  which is what makes the tick's phase inside the interval a meaningful axis to sweep. A
  single mid-bit sample would accept a transmitter that glitched between ticks.
- **Keep the model total.** An unexpected symbol count, an unstable symbol, or a frame that
  was never announced comes back *in the record* rather than raising, so a failing property
  prints what the line actually did instead of a backtrace from inside the model.

## Expect tests: promote, then read

Write `[%expect {| |}]` empty, run `dune runtest`, then `dune promote` — **and then read the
promoted output against the RTL's intended behavior before committing.** A golden freezes
current behavior; blind promotion enshrines a bug as the specification. Where a legacy
assertion harness asserted a specific value, cross-check the new golden against that
assertion before relegating the legacy file.

For a timing golden, "read it" means do the arithmetic. `uart_rx`'s stop window is at cycle
39 of a 52-cycle run because the start edge lands at cycle 4, the tick at cycle 6 enters
PAYLOAD, eight samples follow four cycles apart, and the eighth is at cycle 38. If you
cannot say where a golden's edges came from, you have not read it.

Keep goldens short. A 400-line trace is not a reviewable diff — put the long scenarios in
`let%test_unit` cases and leave one or two representative frames in the expect file.

## Formatting and verification

Per the formatting guide's section 9, and in this order:

```sh
./scripts/with-switch.sh dune build @fmt     # scope to a dir: @<dir>/fmt --auto-promote
./scripts/with-switch.sh dune build @lint
./scripts/with-switch.sh dune build          # must be clean, legacy executables included
./scripts/with-switch.sh dune runtest        # must be green with no expect diffs
```

Parts of `lib/` are not formatter-clean at baseline, so a bare `dune build @fmt` reports a
wall of pre-existing diffs. Promote per directory (`dune build @test/uart/uart_rx/fmt
--auto-promote`) rather than running `dune fmt` across the repo, or a suite's diff will
arrive buried in unrelated reflows.

### Disabling the formatter: use the floating pair, never the item attribute

This ocamlformat rejects `[@@ocamlformat "disable"]` outright, wherever it is attached:

```
Error: Invalid ocamlformat attribute. Ocamlformat can only be disabled at toplevel
(e.g [@@@ocamlformat "disable"])
```

It is an **error**, not a warning, and it fails `dune build @lint`. Bracket the hand-aligned
run instead:

```ocaml
[@@@ocamlformat "disable"]

let create
  ?(preamble_length     = 7)
  ...
;;
[@@@ocamlformat "enable"]
```

Both forms work inside a `struct`, indented to the enclosing level. Close every `disable`
with an `enable`: an unclosed one silently exempts the rest of the file.

### An empty `(**)` makes ocamlformat refuse the whole file

`ocamlformat: ignoring "<file>" (misplaced documentation comments - warning 50)` — the file
is skipped entirely and `@fmt` stays red no matter how many times it is promoted. `(**)` is
an empty *doc* comment the compiler cannot attach to anything. Write `(* *)`, or say
something.

### Modules must not print at initialisation

`let () = Stdio.print_endline "=== Imported X ==="` at the top level of a `lib/` module runs
at link time, before the first `let%expect_test` captures, and lands in whichever test runs
first. See finding PROC-6.

## Deferred, on purpose

- **Alcotest.** The "longer more thought out tests → proper suites" idea below is on hold
  pending confirmation that Alcotest is the right vehicle rather than plain `let%test_unit`
  suites. The `alcotest` dep stays in place, untouched. If the answer is yes the retro-fit
  is purely additive: a fourth file `foo_integration_tests.ml` per integration dir, reusing
  the same `foo_testbench.ml`.
- **EventSim.** `hardcaml_event_driven_sim` and
  `Hardcaml_step_testbench.Functional.Event_driven_sim` are both installed in the switch,
  and the portable-equivalence idea below still stands, but no EventSim suites are written
  yet. `Sim_fixture` is shaped to accept a second backend when they are.
- **`_i` / `_o` port rename.** The formatting guide's section 3 requires it; no current
  `lib/` module complies. Testbenches bind to the port names that exist today. A later
  rename sweep of `lib/` would touch the `inputs ~...` and `snapshot` functions of every
  suite.
- **A real CME datapath.** `cme_feed_parser`'s suite pins a tie-off. That is worth having —
  it is the diff that will make the first real datapath reviewable — but it is not coverage
  of anything yet.

---

# Test Scenario - Agnostic, Backend-neutral

# Driver
Needs (2) interfaces, will drive things into the Cyclesim model AND the Eventsim model

Perhaps some other entity of some sort that sends things out to the driver?
    should we have different drivers for cyclesim vs eventsim?
    or one singular driver that speaks different languages
    same for the monitors -> should each simulator have it's own implemented monitor? or should a singular monitor "speak" 2 different languages?

the drivers accept normalized items, and the monitors take wire activity and re-emit TLM items
    the scoreboard then takes in (3) data streams:
        1. DUT via Cyclesim
        2. DUT via Eventsim
        3. Reference model

# Observations
Monitor items? is this a janestreet vocabulary? or can i use a uvm-like name for this?
Monitor should produce this normalized type based on the wire activity out of either simulation backend

```
type observation =
{
    payload : int list
    ; metadata      : metadata option
    ; crc_error     : bool
    ; port_match    : bool
}
```

# Scoreboard
```
[%test_result: ...]
```

# Test Classifications
Alcotest
    longer more thought out tests -> to be composed of proper suites
Inline Test
Expect Test
