# Hardcaml Module Structuring Style

## 1. Purpose

This guide defines how to lay out the *body* of a synthesizable Hardcaml module: which
sequential idiom to reach for, how to order the regions of a `create` function, and how to
name the nets inside it. It is the companion to the
[Formatting guide](formatting_guide.md), which covers file headers, external port suffixes,
interface comments, and formatter settings. Where that guide governs a module's surface,
this one governs its interior.

Like the formatting guide, these rules are project-neutral and can be copied to another
Hardcaml repository. Repository-specific settings belong in
[Project conventions](hardcaml_project_conventions.md); the timing rationale behind the
naming rules is in [Timing notes](timing_notes.md).

Apply this guide to new modules and to modules being deliberately migrated. Do not
restructure a module as a side effect of an unrelated change.

## 2. Evidence base

These conventions are extracted from Jane Street's own Hardcaml sources rather than
invented. A survey of the shipped circuit library and the core repository:

| Repository | `.ml` files | touch `Always` | use `wire` + `<--` | use `reg_fb` |
| --- | --- | --- | --- | --- |
| `hardcaml_circuits` | 90 | 2 | 12 | 5 |
| `hardcaml/src` | 73 | 11 | 9 | 2 |

The two canonical exemplars, both handshake blocks whose state feeds back into the
handshake that updates it:

- `hardcaml_circuits/src/stack.ml:43-60` — named `wire`s for the Q nets, `_next` bindings
  for the D cones, drives grouped together.
- `hardcaml_circuits/src/datapath_register.ml:25-43` — a skid buffer, plus a locally
  shadowed `reg` that binds the register spec once.

## 3. Choosing a sequential idiom

Pick by the shape of the feedback, not by preference:

| Situation | Idiom |
| --- | --- |
| State read by logic that computes its own next value (handshakes, admission control, anything whose `ready`/`valid` depends on the state) | `wire` for Q, `<-- reg spec next` to drive |
| Self-contained counter or accumulator, whose next value depends only on itself and local enables | `Signal.reg_fb spec ~enable ~width ~f` |
| A genuine state machine with many variables updated under shared conditions | `Always.State_machine` with `Always.Variable.reg` |

`reg_fb` removes the *self-hold* reference, not a forward reference: it binds the current
value as a lambda parameter, so `~f:(fun x -> x +:. 1)` needs no wire. It does not help
when the feedback path runs through intermediate signals that other registers also read,
because those cannot be buried inside one register's closure. Representative `reg_fb` uses
are all counter-shaped: `cordic.ml:98`, `counter_div_mod.ml:47`, `rac.ml:91`,
`clk_div.ml:52`.

Do not treat a `wire` as a workaround. Before adding one, trace the cycle: if the flop's
Q reaches its own D through combinational logic, the wire is structural and should be
commented as such. If the only reference is the hold leg of its own mux, prefer `reg_fb`
or a per-register enable and drop the wire.

## 4. Region order inside `create`

Lay out the body in this order, with a comment banner separating the regions in any
module large enough that they are not obvious at a glance:

1. **Preamble** — `Reg_spec.create`, local module aliases, `active`.
2. **State hangers** — every `wire` that carries a register's Q net, declared together,
   in the same order as the register file in region 5.
3. **Combinational** — decode, handshake, and transfer conditions.
4. **Next state** — one `let <name>_next = ...` per register.
5. **Register file** — one line per flop, driving each hanger.
6. **Outputs** — the `O.t` record.

Regions 2 and 5 are the two halves of the same declaration; keeping their orders identical
makes it verifiable at a glance that every hanger is driven. Small modules may interleave
a `_next` with its drive, as `stack.ml` does, when the state is not entangled with a
shared handshake.

## 5. The register file

Bind the register spec and shared enable exactly once, then drive each hanger on its own
line:

```ocaml
let reg d = Signal.reg spec ~enable:active d in

initialized   <-- reg initialized_next;
expected      <-- reg expected_next;
channel_valid <-- reg channel_valid_next;
dropping      <-- reg dropping_next;
```

A register added later cannot then pick up a different clock, clear, or pause behaviour by
accident. `datapath_register.ml:26` uses the same shadow to attach RTL attributes
uniformly. Registers needing a different spec — a different `~clear_to`, a second clock
domain — are written out in full and commented with the reason.

### The shadow inverts qualification

Naming the helper `reg` deliberately shadows `Signal.reg`, which `open Signal` has already
brought into scope. This keeps the drive lines short and makes them read as the register
file they are, but it breaks a habit worth naming explicitly: **below the shadow,
qualifying the name changes which function is called.**

```ocaml
let reg d = Signal.reg spec ~enable:active d in

initialized <-- reg initialized_next;         (* the shadow: next value only *)
initialized <-- Signal.reg initialized_next;  (* the library function, missing its spec *)
```

Above the shadow, `reg` and `Signal.reg` are the same function. Below it they are not.
Adding the module prefix is normally an explicitness-only edit with no change in meaning;
here it silently selects a different function, and the second line above fails with
`This expression has type t but an expression was expected of type Reg_spec.t`.

Three rules keep that safe:

- **Name the shadow after the function it replaces.** A differently named helper
  (`state_reg`, `drive`) avoids the trap but makes the call sites read as project-specific
  machinery rather than as a register.
- **Give the shadow a different arity or argument type from the original**, so a mistaken
  qualification is a type error rather than a silent behaviour change. Dropping `spec`
  achieves this; a shadow that merely defaulted an optional argument would typecheck and
  fail silently.
- **Comment the shadow at its definition**, stating what is captured and what arity
  remains. The definition is the only place a reader can learn that bare `reg` is local.

## 6. Naming

Every net that a timing report or waveform might name must carry a `--` name. An unnamed
design reports paths as `signal_reg_51_reg[6] -> signal_reg_48_reg[0]`; a named one reads
as `collected -> skip_left`. See [Timing notes](timing_notes.md) for the case where this
changed a diagnosis rather than merely improving readability.

- **Q nets** take the name of the state they hold: `expected`, `channel_valid`.
- **D cones** take that name plus `_next`: `expected_next`. This is the convention across
  `stack.ml`, `datapath_register.ml`, and `vec.ml`.
- **Intermediate combinational nodes** are named too, not just flops — decode terms,
  handshake terms, and transfer conditions all appear in failing paths.
- Direction suffixes stay on ports only, per the
  [Formatting guide](formatting_guide.md#5-internal-signal-names).

Naming is either a bare `--` or `let ( -- ) = Scope.naming scope in`, which prefixes names
with the hierarchy path. Choose one per repository and apply it uniformly: bare names are
sufficient when RTL is emitted hierarchically, since each module has its own namespace;
scope naming is required when the design is flattened, or names from different modules
will collide and be silently uniquified.

### The `--` precedence trap

`--` begins with `-`, placing it at OCaml's `+`/`-` precedence level, above every operator
beginning with `&`, `|`, `<`, `>` or `=`. So:

```ocaml
let ready = active &: ~:control &: (dropping |: taking) -- "ready" in    (* wrong *)
let ready = (active &: ~:control &: (dropping |: taking)) -- "ready" in  (* right *)
```

The first names only the parenthesised sub-expression and leaves the predicate anonymous.
It is silent — the design is correct, only the report lies. Function application binds
tighter than `--`, so `msb delta -- "late"` and `mux2 a b c -- "n"` need no extra parens.

## 7. Worked example

`lib/cme/single_feed_sequencer.ml` is the reference implementation of this layout: six
state flops whose Q nets are all read by the handshake logic that computes their next
values, so all six hangers are structural.

```ocaml
let create (_scope : Scope.t) (i : _ I.t) =
  let spec = Reg_spec.create ~clock:i.clock_i ~clear:i.reset_i () in
  let module T = Cme_types in
  let active = (i.en_i &: ~:(i.reset_i)) -- "active" in

  (* State hangers ... the feedback is structural: every one of these is read by the
     handshake logic that computes its own next value, so the cycle is real and closes
     through the flop. *)
  let initialized   = wire 1  -- "initialized"   in
  let expected      = wire 32 -- "expected"      in
  (* ... *)

  (* ---- combinational ---- *)
  let control_ready = (active &: idle &: i.quiescent_i) -- "control_ready" in
  let admit = (input_transfer &: start &: ~:dropping) -- "admit" in
  (* ... *)

  (* ---- next state ---- *)
  let initialized_next =
    mux2 session_reset gnd (mux2 (resync |: admit) vdd initialized)
    -- "initialized_next"
  in
  (* ... *)

  (* ---- register file ---- *)
  let reg d = Signal.reg spec ~enable:active d in
  initialized <-- reg initialized_next;
  expected    <-- reg expected_next;
  (* ... *)
```

## 8. Migration checklist

When bringing an existing module to this style:

1. Confirm each `wire` is structural by tracing its cycle; convert self-hold-only
   registers to `reg_fb` or a per-register enable.
2. Reorder the hanger declarations to match the drive order.
3. Lift each anonymous D expression into a named `_next` binding.
4. Hoist the register spec and shared enable into a local `reg`, commented with what it
   captures and the arity it leaves — see the shadowing note in section 5.
5. Name the intermediate combinational nodes, watching the precedence trap.
6. Drop redundant `Signal.` prefixes where `open Signal` already covers the name.
7. Restructure only — transcribe every expression verbatim, preserving operand order and
   mux priority — then rely on the module's existing suites to confirm equivalence.

## 9. Known deviations in this repository

Not yet migrated; each is a candidate for a future pass:

- `lib/cme/packet_header.ml` hand-prefixes internal names (`"packet_header_active"`)
  rather than relying on module hierarchy or `Scope.naming`.
- `lib/cme/mbp_decoder.ml` uses `Always.Variable.reg` with a local `variable name width`
  helper. This is correct for its size — it is a large state machine — but its bare
  naming convention differs from `packet_header.ml`'s prefixes.
- No module currently uses `Scope.naming`; the repository has not chosen between the two
  naming schemes described in section 6.
