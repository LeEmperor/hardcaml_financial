#!/usr/bin/env python3
# University of Florida
# Author: Bohdan Purtell
# Module: "feed_traffic.py"
# Flexible CME MDP 3.0 test-frame sender for the Phase 7 Arty board harness.
#
# The sibling script, board_acceptance.py, sends one fixed sequence and pass/fails it
# against absolute counter tuples: it certifies a bitstream, and you do not choose its
# traffic. This one is the other way round -- you describe the traffic (sequence numbers,
# packet shapes, destination port, repeats, deliberate gap/duplicate injection, malformed
# messages, corrupted IPv4 checksums) and the model here derives the counter deltas it
# should produce. Nothing in it is a regression baseline; it is for soak runs, one-off
# shapes and debugging. It can send on a raw socket, or just write frames to disk (no
# CAP_NET_RAW needed).
#
# Packet construction is imported from board_acceptance.py so the SBE encoding stays
# single-sourced and stays covered by the XML oracle in phase7_contracts.ml.
#
# Functional verification of the parser itself lives in Hardcaml/Cyclesim, under
# test/cme/ -- board-level heavy traffic in
# test/cme/validation_core/validation_core_heavy_traffic_tests.ml. This script is
# the hardware-facing counterpart: it puts the same traffic shapes on a real
# wire and checks the counters the board reports back.
import argparse
import dataclasses
import json
import time
from pathlib import Path

from board_acceptance import (ALIGNED_ROOT_BLOCK, COUNTERS, MAX_UDP_PAYLOAD,
                              MTU_ALIGNED_ENTRIES, MTU_ENTRIES, MTU_MESSAGES, PORT,
                              ROOT_BLOCK, Case, UartReader, ethernet, message, mii_frame,
                              pack_messages, raw_message)

# Malformed-message injections, each named by the parser diagnostic it provokes.
# 'unsupported' is prepended to an otherwise normal packet: the iterator skips the message
# by its declared size, so the rest of the packet still parses. The other two replace the
# body outright, because a size that cannot be trusted ends the packet.
INJECTIONS = ('unsupported', 'bad-size', 'beyond-packet')

DEFAULT_SEQUENCE = 100
# Where the harness sequencer was left. The 36-byte UART record is a magic word and eight
# counters -- it carries no expected-sequence field -- so the board cannot be asked where
# its sequencer is. It is tracked here instead, keyed by interface and destination port.
DEFAULT_STATE = Path(__file__).resolve().parents[2] / '_build/phase7/sender_state.json'


@dataclasses.dataclass(frozen=True)
class Shape:
    """How one packet's messages are laid out."""
    messages: int
    entries: int
    root_block: int = ROOT_BLOCK

    @property
    def name(self):
        pad = '' if self.root_block == ROOT_BLOCK else f'+{self.root_block - ROOT_BLOCK}'
        return f'{self.messages}x{self.entries}{pad}'


NAMED_SHAPES = {
    # One message with the deepest MBP group a datagram can carry.
    'mtu-deep': Shape(1, MTU_ENTRIES),
    # The same byte budget spent on as many single-entry messages as it holds.
    'mtu-wide': Shape(MTU_MESSAGES, 1),
    # Payload length is a whole number of 8-byte beats, so the final beat is full.
    'aligned': Shape(1, 1, ALIGNED_ROOT_BLOCK),
    # Both at once: an MTU-sized datagram that also ends on a full beat.
    'mtu-aligned': Shape(1, MTU_ALIGNED_ENTRIES, ALIGNED_ROOT_BLOCK),
}


def shape(text):
    if text in NAMED_SHAPES:
        return NAMED_SHAPES[text]
    try:
        messages, entries = text.lower().split('x')
        result = Shape(int(messages), int(entries))
    except ValueError:
        raise argparse.ArgumentTypeError(
            f'expected MESSAGESxENTRIES or one of {", ".join(NAMED_SHAPES)}: {text!r}')
    if result.messages < 1 or result.entries < 1:
        raise argparse.ArgumentTypeError('messages and entries must both be at least 1')
    return result


def shapes(text):
    return [shape(part) for part in text.split(',') if part]


def body(shape, last_only, inject):
    """Encode one packet's messages, and predict what the parser will report for them."""
    if inject == 'bad-size':
        # A declared size below the 10-byte SBE header cannot describe any message.
        return raw_message(9, b'bad'), dict(updates=0, end_of_event=0, diagnostics=1)
    if inject == 'beyond-packet':
        # A declared size that runs off the end of the datagram.
        return raw_message(1000, b'short'), dict(updates=0, end_of_event=0, diagnostics=1)
    messages = pack_messages((shape.entries,) * shape.messages, last_only,
                             shape.root_block)
    prefix = message(0, 123, template=99) if inject == 'unsupported' else b''
    return prefix + messages, dict(
        updates=shape.messages * shape.entries,
        end_of_event=1 if last_only else shape.messages,
        diagnostics=1 if inject == 'unsupported' else 0)


class Model:
    """Predicts harness counters. Mirrors the single-feed sequencer rules the
    Phase 7 cases exercise: sequence advances one per accepted packet; a forward
    jump raises a gap and still parses; a stale sequence raises a duplicate and
    drops the payload. A corrupted IPv4 header checksum is a physical-layer
    verdict, so it is counted for every frame put on the wire, filtered and
    duplicate ones included. A bad Ethernet FCS is deliberately absent: a NIC
    generates the real FCS, so this sender cannot provoke crc_errors at all --
    only the MII vectors and the Cyclesim board suite can.

    [next_sequence] seeds the sequencer where the board's already is. A board
    that has never seen a packet expects nothing and accepts whatever arrives
    first, which is None; a board mid-session expects a specific value, and
    seeding it is what lets this model predict the gaps and duplicates that
    resending an earlier range provokes. Getting this wrong is the difference
    between predicting a clean run and predicting 2000 duplicates.
    Predictions are a convenience, not the acceptance oracle."""

    def __init__(self, next_sequence=None):
        self.counts = dict.fromkeys(COUNTERS, 0)
        self.next_sequence = next_sequence

    def observe(self, case, contribution):
        if case.bad_ip:
            self.counts['ip_errors'] += 1
        if case.port != PORT:
            return  # filtered before the parser; only network status can move
        self.counts['packets'] += 1
        duplicate = self.next_sequence is not None and case.sequence < self.next_sequence
        gap = self.next_sequence is not None and case.sequence > self.next_sequence
        if gap:
            self.counts['diagnostics'] += 1
            self.counts['sequence_gaps'] += 1
        if duplicate:
            self.counts['diagnostics'] += 1
            self.counts['duplicates'] += 1
            return
        for name in ('updates', 'end_of_event', 'diagnostics'):
            self.counts[name] += contribution[name]
        self.next_sequence = case.sequence + 1

    @property
    def expected(self):
        return tuple(self.counts[name] for name in COUNTERS)


def plan(args, start):
    """Expand the command line into the ordered list of packets to transmit, each paired
    with the counter contribution the model predicts for its messages."""
    sequence = start
    packets = []

    def build(name, sequence, index):
        inject = args.inject.get(index, '')
        chosen = args.shape[index % len(args.shape)]
        encoded, contribution = body(chosen, args.last_only, inject)
        case = Case(name, sequence, (), (), port=args.port,
                    bad_ip=index in args.bad_ip_after, body=encoded)
        try:
            case.payload
        except ValueError:
            raise SystemExit(
                f'{name}: shape {chosen.name} needs '
                f'{len(encoded) + 12} payload bytes, over the '
                f'{MAX_UDP_PAYLOAD}-byte MTU limit')
        return case, contribution

    for index in range(args.count):
        packets.append(build(f'packet_{index}', sequence, index))
        if index in args.duplicate_after:
            # Resent verbatim, so it carries the same shape and the same verdicts.
            packets.append(build(f'duplicate_{index}', sequence, index))
        sequence += 1
        if index in args.gap_after:
            sequence += args.gap_size
    return packets


def load_state(path):
    try:
        return json.loads(path.read_text())
    except (OSError, ValueError):
        return {}


def save_state(path, state):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(state, indent=2, sort_keys=True) + '\n')


def resolve_sequencer(args, baseline, stored):
    """Decide where the board's sequencer is, and where this run should start.

    Returns (known_next, start, note). [known_next] seeds the model: None means the board
    has never accepted a packet, so the first one this run sends is accepted whatever its
    sequence. Anything else is a value the board will compare against, and the model turns
    the comparison into the gaps and duplicates it predicts."""
    if args.assume_next_sequence is not None:
        known = args.assume_next_sequence
        return known, args.sequence if args.sequence is not None else known, \
            f'sequencer assumed to be at {known} (--assume-next-sequence)'
    if baseline is None:
        # No UART, so nothing to predict against; --dump only cares about the bytes.
        start = args.sequence if args.sequence is not None else DEFAULT_SEQUENCE
        return None, start, 'no --serial: sequencer state unknown and unused'
    if baseline == (0,) * len(COUNTERS):
        start = args.sequence if args.sequence is not None else DEFAULT_SEQUENCE
        return None, start, 'board is freshly reset; sequencer expects nothing yet'
    if stored is None:
        raise SystemExit(
            'The board has already accepted traffic, and its sequencer position is not\n'
            'readable over the UART, so the counter deltas cannot be predicted.\n'
            'Do one of:\n'
            '  - reset the board (press and release btn[0]) and run again;\n'
            '  - pass --assume-next-sequence N if you know what it expects next;\n'
            f'  - or delete {args.state} if its record is stale.')
    known = stored['next_sequence']
    start = args.sequence if args.sequence is not None else known
    if tuple(stored['counters']) != baseline:
        note = ('WARNING: the counters moved since this script last ran, so something '
                'else sent traffic and the sequencer may have advanced past '
                f'{known}. The prediction below may be wrong.')
    else:
        note = f'continuing the previous run; sequencer expects {known}'
    return known, start, note


def snapshot(reader, timeout, settle):
    """Return a counter record that is stable across two consecutive snapshots."""
    deadline = time.monotonic() + timeout
    previous = reader.record(deadline)
    while time.monotonic() < deadline:
        current = reader.record(deadline)
        if current == previous:
            return current
        previous = current
    raise TimeoutError('UART counters never settled; traffic may still be arriving')


def describe(packets):
    return [dict(name=case.name, sequence=case.sequence, port=case.port,
                 payload_bytes=len(case.payload), frame_bytes=len(ethernet(case)),
                 bad_ip=case.bad_ip, predicted=contribution)
            for case, contribution in packets]


def run(args):
    key = f'{args.iface or "none"}:{args.port}'
    state = {} if args.forget_state else load_state(args.state)

    # The UART baseline decides where the sequencer is, so it has to be read before the
    # traffic is planned rather than after.
    reader = baseline = None
    if args.serial is not None:
        reader = UartReader(args.serial)
        baseline = snapshot(reader, args.timeout, args.settle)
        print(f'UART before: {dict(zip(COUNTERS, baseline))}')
    try:
        known_next, start, note = resolve_sequencer(args, baseline, state.get(key))
    except SystemExit:
        if reader is not None:
            import os
            os.close(reader.fd)
        raise
    print(note)

    packets = plan(args, start)
    model = Model(known_next)
    for case, contribution in packets:
        model.observe(case, contribution)
    offered_bytes = sum(len(ethernet(case)) for case, _ in packets)
    report = dict(interface=args.iface, serial=args.serial, port=args.port,
                  shapes=[s.name for s in args.shape], last_only=args.last_only,
                  sequencer_note=note, sequencer_expected=known_next,
                  first_sequence=start, next_sequence=model.next_sequence,
                  offered_frames=len(packets), offered_bytes=offered_bytes,
                  packets=describe(packets),
                  predicted_delta=dict(zip(COUNTERS, model.expected)))
    if baseline is not None:
        report['before'] = dict(zip(COUNTERS, baseline))

    if args.dump is not None:
        args.dump.mkdir(parents=True, exist_ok=True)
        for case, _ in packets:
            (args.dump / f'{case.name}.eth.bin').write_bytes(ethernet(case))
            (args.dump / f'{case.name}.mii.bin').write_bytes(mii_frame(case))
        print(f'Wrote {2 * len(packets)} frame files to {args.dump}')

    try:
        if args.iface is not None:
            # The NIC generates the real Ethernet FCS: never append the simulation one.
            import socket
            with socket.socket(socket.AF_PACKET, socket.SOCK_RAW, socket.htons(0x0800)) as tx:
                tx.bind((args.iface, 0))
                started = time.monotonic()
                for case, _ in packets:
                    tx.send(ethernet(case))
                    if args.verbose:
                        print(f'sent {case.name}: seq={case.sequence} port={case.port} '
                              f'{len(case.payload)} payload bytes', flush=True)
                    if args.interval:
                        time.sleep(args.interval)
                elapsed = time.monotonic() - started
            report['send_seconds'] = elapsed
            if elapsed > 0:
                # Offered rate at the sender. The link is 100 Mbps, so a figure at or above
                # that means the host, not the board, set the pace.
                report['offered_pps'] = len(packets) / elapsed
                report['offered_mbps'] = offered_bytes * 8 / elapsed / 1e6
                print(f'offered {len(packets)} frames / {offered_bytes} bytes in '
                      f'{elapsed:.3f}s = {report["offered_pps"]:.0f} pps, '
                      f'{report["offered_mbps"]:.1f} Mbps')

        if reader is not None:
            after = snapshot(reader, args.timeout + args.settle, args.settle)
            delta = tuple(b - a for a, b in zip(baseline, after))
            report['after'] = dict(zip(COUNTERS, after))
            report['observed_delta'] = dict(zip(COUNTERS, delta))
            report['matched'] = delta == model.expected
            # Remember where the sequencer now is, and what the counters read, so the next
            # run can predict against them instead of assuming a fresh board.
            if args.iface is not None:
                state[key] = dict(next_sequence=model.next_sequence, counters=list(after))
                save_state(args.state, state)
            print(f'UART after:  {dict(zip(COUNTERS, after))}')
            for name, observed, predicted in zip(COUNTERS, delta, model.expected):
                flag = ' ' if observed == predicted else '<-- differs'
                print(f'  {name:<13} observed {observed:>6}  predicted {predicted:>6} {flag}')
            print('MATCH' if report['matched'] else 'MISMATCH')
    finally:
        if reader is not None:
            import os
            os.close(reader.fd)
            if args.raw_uart is not None:
                args.raw_uart.parent.mkdir(parents=True, exist_ok=True)
                args.raw_uart.write_bytes(reader.raw)
        if args.output is not None:
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(json.dumps(report, indent=2) + '\n')

    if reader is not None and not report.get('matched'):
        raise SystemExit(1)


def integers(text):
    return set() if not text else {int(v) for v in text.split(',')}


def injections(text):
    """Parse KIND@INDEX pairs into {packet index: kind}."""
    result = {}
    for part in text.split(','):
        if not part:
            continue
        kind, _, index = part.partition('@')
        if kind not in INJECTIONS or not index.isdigit():
            raise argparse.ArgumentTypeError(
                f'expected KIND@INDEX with KIND in {{{", ".join(INJECTIONS)}}}: {part!r}')
        result[int(index)] = kind
    return result


def build_parser():
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='Examples:\n'
               '  # dump frames only, no privileges and no board needed\n'
               '  python3 validation/phase7/feed_traffic.py --dump _build/frames --count 4\n'
               '  # send 20 packets with a gap after #5 and a duplicate after #9,\n'
               '  # then compare the UART counter delta against the model\n'
               '  sudo python3 validation/phase7/feed_traffic.py --iface enp1s0 \\\n'
               '      --serial /dev/ttyUSB1 --count 20 --gap-after 5 --duplicate-after 9\n'
               '  # repeat runs need no reset: the sequencer position carries over, so\n'
               '  # the second run continues rather than replaying and going stale\n'
               '  # heavy soak: 2000 MTU-sized packets alternating deep and wide, with\n'
               '  # malformed declared sizes and a corrupted IPv4 checksum mixed in\n'
               '  sudo python3 validation/phase7/feed_traffic.py --iface enp1s0 \\\n'
               '      --serial /dev/ttyUSB1 --count 2000 --shape mtu-deep,mtu-wide \\\n'
               '      --last-only --inject bad-size@20,beyond-packet@30 \\\n'
               '      --bad-ip-after 40 --output _build/soak.json\n'
               '  # unsupported prefixes a message instead of replacing the body, so it\n'
               '  # needs a shape with room to grow: the mtu-* shapes are already the\n'
               '  # largest that fit, and the run is refused before anything is sent\n'
               '  sudo python3 validation/phase7/feed_traffic.py --iface enp1s0 \\\n'
               '      --serial /dev/ttyUSB1 --count 2000 --shape 8x4 --last-only \\\n'
               '      --inject unsupported@10,bad-size@20,beyond-packet@30 \\\n'
               '      --bad-ip-after 40 --output _build/soak_injections.json\n')
    parser.add_argument('--iface', help='network interface to transmit on (needs CAP_NET_RAW)')
    parser.add_argument('--serial', help='harness UART device, e.g. /dev/ttyUSB1')
    parser.add_argument('--dump', type=Path, help='write .eth.bin/.mii.bin frames here instead of/besides sending')
    parser.add_argument('--count', type=int, default=1, help='number of packets to send (default 1)')
    parser.add_argument('--sequence', type=int,
                        help='starting MDP packet sequence. Default: continue where the '
                             f'last run left off, or {DEFAULT_SEQUENCE} on a freshly '
                             'reset board. Set it explicitly to force a gap or a replay; '
                             'the prediction accounts for either.')
    parser.add_argument('--assume-next-sequence', type=int, metavar='N',
                        help='declare what the board expects next, when this script has '
                             'no record of it and the board has not been reset')
    parser.add_argument('--state', type=Path, default=DEFAULT_STATE,
                        help='where the sequencer position is remembered between runs '
                             '(default: %(default)s)')
    parser.add_argument('--forget-state', action='store_true',
                        help='ignore any remembered sequencer position for this run')
    parser.add_argument('--shape', type=shapes, metavar='SHAPE[,SHAPE...]',
                        help='per-packet layout, cycled across the run: MESSAGESxENTRIES '
                             f'(e.g. 8x4) or one of {", ".join(NAMED_SHAPES)} '
                             f'(mtu-deep={MTU_ENTRIES} entries, mtu-wide={MTU_MESSAGES} '
                             'messages, aligned=whole 8-byte beats). Default 1x1.')
    parser.add_argument('--messages', type=int, help='shorthand for --shape MESSAGESx<entries>')
    parser.add_argument('--entries', type=int, help='shorthand for --shape <messages>xENTRIES')
    parser.add_argument('--last-only', action='store_true',
                        help='set LastMsgOfEvent on the final message of each packet only, '
                             'so a multi-message packet is one event rather than many')
    parser.add_argument('--port', type=int, default=PORT,
                        help=f'destination UDP port; only {PORT} reaches the parser (default {PORT})')
    parser.add_argument('--gap-after', type=integers, default=set(), metavar='N[,N...]',
                        help='skip sequence numbers after these zero-based packet indices')
    parser.add_argument('--gap-size', type=int, default=1, help='sequence numbers skipped per gap (default 1)')
    parser.add_argument('--duplicate-after', type=integers, default=set(), metavar='N[,N...]',
                        help='resend these zero-based packet indices immediately')
    parser.add_argument('--inject', type=injections, default={}, metavar='KIND@N[,KIND@N...]',
                        help='replace or prefix the messages of these zero-based packet '
                             f'indices to provoke a parser diagnostic; KIND in {{{", ".join(INJECTIONS)}}}')
    parser.add_argument('--bad-ip-after', type=integers, default=set(), metavar='N[,N...]',
                        help='corrupt the IPv4 header checksum of these zero-based packet '
                             'indices (a bad Ethernet FCS cannot be sent from a NIC)')
    parser.add_argument('--interval', type=float, default=0.0, help='seconds between packets (default 0)')
    parser.add_argument('--timeout', type=float, default=8.0, help='UART record timeout in seconds (default 8)')
    parser.add_argument('--settle', type=float, default=3.0,
                        help='extra seconds allowed for counters to settle after sending (default 3)')
    parser.add_argument('--verbose', action='store_true', help='print a line per transmitted frame')
    parser.add_argument('--output', type=Path, help='write a JSON report here')
    parser.add_argument('--raw-uart', type=Path, help='write captured raw UART bytes here')
    return parser


def parse_args(argv=None):
    """Parse and normalise a command line, without running it. Shared with the tests,
    which push the examples in the parser's epilog back through here."""
    parser = build_parser()
    args = parser.parse_args(argv)
    if args.iface is None and args.dump is None:
        parser.error('nothing to do: pass --iface to transmit, --dump to write frames, or both')
    if args.shape is None:
        if (args.messages is not None and args.messages < 1) \
                or (args.entries is not None and args.entries < 1):
            parser.error('--messages and --entries must both be at least 1')
        args.shape = [Shape(args.messages or 1, args.entries or 1)]
    elif args.messages is not None or args.entries is not None:
        parser.error('--shape replaces --messages/--entries; pass one or the other')
    if args.count < 1:
        parser.error('--count must be at least 1')
    return args


def main():
    run(parse_args())


if __name__ == '__main__':
    main()
