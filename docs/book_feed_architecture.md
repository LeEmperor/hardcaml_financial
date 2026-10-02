# Downstream architecture: book building, strategy, and order egress

**Nothing in this document is implemented.** It is a design sketch for the
stages that would consume `Cme_feed_parser`'s event stream, written to record
the reasoning while the parser's output contract is still cheap to change. The
[main plan](cme_mdp3_10g_parser_plan.md) remains the authority for parser scope
and acceptance; this document has no acceptance criteria and gates nothing.

Its purpose is to answer one question: given a 677-bit normalized event, what
should exist between it and an order on the wire, and what does that imply
about the event contract itself.

## Pipeline shape

```
Cme_feed_parser              ── implemented
  │  Event (677 b), ready/valid, one entry per beat
  ▼
instrument filter            ── security_id -> internal slot, or drop
  │  Book_delta (~130 b)
  ├──────────────────────────────────────────────┐
  ▼                                              ▼
book builder                                trigger compare
  │  per-instrument level arrays               (pre-armed, 1 cycle)
  ▼                                              │
market state publisher                           │
  │  Bbo / depth, valid only on end_of_event     │
  ▼                                              │
strategy  ◄───────────────────────────────────────┘
  │  order intent
  ▼
pre-trade risk               ── mandatory, not bypassable
  │
  ▼
order encoder (iLink 3)  ──►  TCP egress
```

The left column is the correctness path; the short diagonal is the latency
path. Both are described below.

## Stage 1: instrument filter

CME publishes hundreds of thousands of instruments. Book state for all of them
does not fit and is not wanted. The filter maps `security_id` (32 bits, the
exchange's identifier) to a small internal slot index, and drops every event
that does not match.

This belongs immediately after the parser, before any storage, so that BRAM
bandwidth is spent only on subscribed instruments. A CAM or a small hash over a
subscription table of tens to low hundreds of entries is sufficient; the table
is written at configuration time, not in the data path.

The filter is also the natural place to narrow the event. See
[Cross-feed normalization](#cross-feed-normalization) for the target struct.

Diagnostic events (`Event_kind.diagnostic`) carry no `security_id` and must be
routed past the filter to the control/monitoring path rather than dropped.

## Stage 2: book builder

MDP 3.0 is a market-by-price feed: the exchange has already aggregated and
sorted. `price_level` is a one-based depth index, not a price to be searched
for. A book update is therefore an array write plus a shift, not a sorted
insert, and needs no comparators over stored prices.

For a depth of N per side, state per instrument is 2N entries of
`(price_mantissa, entry_size, number_of_orders)`. The six `MDUpdateAction`
values map directly:

| Action | Value | Effect at `price_level` = L |
| --- | --- | --- |
| New | 0 | shift L..N down one, write L |
| Change | 1 | overwrite L in place |
| Delete | 2 | shift L+1..N up one, clear N |
| DeleteThru | 3 | clear 1..L, shift remainder up |
| DeleteFrom | 4 | clear L..N |
| Overlay | 5 | overwrite L in place, no shift |

`DeleteThru` and `DeleteFrom` are the range operations and are the usual source
of silent book drift when they are treated as ordinary deletes. `MDEntryType`
`'J'` (BookReset) clears the instrument entirely.

`entry_type` also separates four distinct books that must not be merged:
outright bid/offer (`'0'`/`'1'`), implied bid/offer (`'E'`/`'F'`), and, since
schema version 12, MarketBestBid/MarketBestOffer (`'x'`/`'w'`). Whether implied
liquidity is merged into the tradeable book is a strategy decision, so the
builder should keep them addressable separately.

Prices are fixed-point with the schema's constant exponent `-9`
(`price_exponent` in the generated descriptor). Never convert to floating point
in the data path; carry the mantissa, or convert once to integer ticks at the
filter.

### Per-instrument integrity

The parser's `Single_feed_sequencer` detects gaps at the *packet* level and
emits `sequence_gap` or `duplicate_or_late` diagnostics. That is necessary but
not sufficient: `rpt_seq` is a separate per-instrument sequence, and the book
builder should track it per slot.

On an `rpt_seq` discontinuity, or on any packet-level gap diagnostic, the
affected books must be marked invalid and must stop publishing. A book that
missed a delete is worse than no book, because it will show liquidity that is
not there and invite the strategy to trade into it.

Recovery requires the MDP 3.0 snapshot channel, which this repository does not
parse. Snapshot messages use different templates, so recovery needs either a
second parser instance with a different admission list or an extension of the
existing one. Until that exists, an invalidated instrument can only be
recovered by an operator resync (`resync_valid_i`), which is a session-level
action, not a per-instrument one. This is the largest functional gap between
the current tree and a system that could trade.

## Stage 3: market state and the atomicity fence

The builder's output is not "the book". It is a compact, stable view:
`{instrument, bid_px, bid_qty, ask_px, ask_qty, valid, seq}`, plus additional
levels for strategies that need depth.

The word that matters is *stable*. A single CME match event — one aggressive
order sweeping several levels — arrives as multiple entries across multiple
messages and possibly multiple packets. Between the first and last entry the
book is torn: levels deleted but not yet backfilled, a crossed or zero-width
spread that never existed at the exchange.

`Event_kind.end_of_event` is the fence. The parser emits it when bit 7 of
`match_event_indicator` is set, after the message completes. The rule for
everything downstream of the builder is:

> Apply deltas continuously; sample the book only on `end_of_event`.

`entry_index`, `entry_count`, and `message_last` give within-message position
for the same reason, one level finer. A publisher that ignores the fence will
periodically show phantom arbitrage, and a strategy that acts on it will
trade against a state the exchange was never in.

The one admissible exception is the trigger path below, and only for monotone
conditions.

## Stage 4: strategy, fast path and slow path

The reason to build this in fabric is not that parsing is slow. It is that
detect, decide, and emit can be collapsed into single-digit cycles by moving
the deciding *before* the event arrives.

**Slow path.** The strategy reads the published market state after
`end_of_event`, runs whatever model it runs, and produces order intent. Latency
here is tens of cycles and that is acceptable, because its job is not to react
but to prepare.

**Fast path.** What the slow path prepares is an armed trigger: a threshold, a
side, and a fully encoded, already risk-checked order sitting in a register.
When an event arrives, the fast path is one comparator against `price_mantissa`
and a register enable. It runs in parallel with the book update, not after it.
Once the book catches up, the slow path re-arms.

Two constraints on the fast path:

- It may fire on a single entry only when the condition is monotone under a
  torn book — "best bid fell below X" cannot be undone by later entries in the
  same event, whereas anything involving both sides or the spread can. Spread
  conditions wait for the fence.
- For a market maker the fastest useful reaction is usually *cancel*, not
  trade. Pulling a resting quote ahead of adverse flow is frequently worth more
  than any aggressive fill, and it is the same mechanism: a pre-encoded cancel,
  armed against a threshold.

Note that market data never gates the book. The book is a passive mirror of
exchange state and applies every event unconditionally. What is conditional is
only the outbound order.

## Stage 5: pre-trade risk

Position, order size, and price-collar checks before any order leaves the
device. This is a regulatory requirement (SEC Rule 15c3-5 and exchange-side
equivalents), not an optimization, and it cannot be bypassed by the fast path.

The fast path satisfies it the same way it satisfies encoding: the pre-built
order is risk-checked at arm time, and the trigger only arms if it passed.
Position updates from fills must disarm or re-evaluate outstanding triggers,
which makes the fill-return path part of the latency budget too.

## Stage 6: order encoding and egress

CME order entry is iLink 3 over TCP — a different protocol from the market data
feed, with its own session layer, sequence numbers, and heartbeats. In a
fast-path design the message body is pre-encoded and only a few fields are
patched at fire time.

TCP is stateful and awkward in fabric. The common arrangements are a hardware
TCP offload engine holding an established session, or a hybrid where software
owns the session and the fabric injects pre-formed segments. Either way the
session layer is a substantial subsystem, comparable in size to the parser.

## Cross-feed normalization

There is no industry-standard normalized market data event; every firm defines
its own. The structural reason generality is expensive is visible in the
contrast with NASDAQ ITCH:

| | CME MDP 3.0 | NASDAQ ITCH |
| --- | --- | --- |
| Model | market by price | market by order |
| Identity | `security_id` + `price_level` | order reference number |
| Book state | N levels per side | hash of live order refs |
| Aggregation | done by the exchange | done by the consumer |

ITCH has no `price_level` and this repository's `Event.t` has no order
reference, so the current event cannot carry ITCH and an ITCH parser cannot
emit this `Event.t`. An ITCH book builder needs an order-ref hash with hundreds
of thousands of live entries — a different and much more expensive design than
the level arrays above.

What is shared is narrower than a whole event. The workable construction is a
common core that the book builder consumes, with each feed parser keeping its
own transport-shaped event and a thin adapter projecting down:

```ocaml
module Book_delta = struct
  type 'a t =
    { instrument : 'a [@bits 16]  (* internal slot, post-filter *)
    ; side : 'a
    ; action : 'a [@bits 3]
    ; level : 'a [@bits 8]        (* MBP fills this; MBO aggregates first *)
    ; price : 'a [@bits 64]       (* one house exponent across all feeds *)
    ; qty : 'a [@bits 32]
    ; event_last : 'a             (* the atomicity fence *)
    ; valid : 'a
    }
  [@@deriving hardcaml]
end
```

For an MBO feed the order-ref aggregation stage sits before the adapter, which
is exactly where market-by-order becomes market-by-price.

Price normalization is the detail that is routinely underestimated. CME uses a
constant exponent of `-9` here; other feeds use different fixed scales, and
some vary per instrument. Choose one house representation, convert in the
adapter, and keep per-feed scaling out of the strategy permanently.

## Implications for the current event contract

Two observations follow from the above and are worth settling before the ABI
is depended on by anything.

**The event is wide because it is diagnostic.** Of 677 bits, 325 are
`Packet_context` plus `Message_context`: `packet_seq`, `sending_time`,
`template_id`, `schema_id`, `schema_version`, `block_length`,
`packet_byte_offset`. That metadata is replicated onto every entry of every
message. It is what lets conformance tests compare bit-for-bit against the
golden decoder and point at the exact byte that produced any event, which is
real value and worth keeping at the parser boundary. None of it reaches a book
builder, and none of it exists in another feed. The narrowing belongs in the
filter, not in the parser.

**Output FIFO depth is currently unvalidated against a real consumer.** The
default is 16 events (`Cme_config.default`). Phase 6 measured 128 packets
against a stalling sink exhausting buffering, with entry latency stretching
from 7 to 71 cycles. A book builder that stalls — on a BRAM port conflict, or
mid-shift on a range delete — applies backpressure through `event_ready_i` in
exactly that way. The depth should be resized against a real consumer's stall
profile rather than left at a placeholder.

## Open questions

- Depth N per instrument, and how many instruments, which together fix the
  storage budget and decide registers versus BRAM.
- Whether implied liquidity is merged into the tradeable book, and whether
  `'x'`/`'w'` MarketBest entries are consumed at all.
- Whether snapshot recovery is a second parser instance or an extension of the
  admission list in the existing one.
- Whether the fill-return path is in fabric or in software, which determines
  whether position-based risk can gate the fast path at wire speed.
