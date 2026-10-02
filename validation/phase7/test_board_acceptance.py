# University of Florida
# Author: Bohdan Purtell
# Module: "test_board_acceptance.py"
# Host capture must recover framing and preserve deadline/failure behavior, and the
# traffic builders shared with feed_traffic.py must encode what they claim.
#
# These are host-side checks only. The parser's behaviour is verified in Hardcaml under
# test/cme/, so nothing here asserts what the hardware does -- only that the bytes put on
# the wire, and the counter deltas the sender predicts for them, are what the shape names
# say they are.
import argparse
import contextlib
import io
import os
import pty
import shlex
import struct
import sys
import tempfile
import time
import unittest
from pathlib import Path

from board_acceptance import (COUNTERS, MAX_UDP_PAYLOAD, MESSAGE_OVERHEAD, MTU_ENTRIES,
                         MTU_MESSAGES, PACKET_HEADER, PORT, ROOT_BLOCK, Case, UartReader,
                         cases, checksum, ethernet, message, mii_frame, mtu_cases,
                         raw_message, run_cases, write_vectors)

# Largest untagged Ethernet frame, headers included and FCS excluded.
MAX_FRAME = 1514

import feed_traffic


def payload_of(body):
    return Case('probe', 1, (), (), body=body).payload


def split_messages(body):
    """Walk a packet body by each message's declared size, as the iterator does."""
    offset = 0
    while offset < len(body):
        size = struct.unpack_from('<H', body, offset)[0]
        yield body[offset:offset + size]
        offset += size


class BoardCasesTests(unittest.TestCase):
    def test_network_fixtures(self):
        for case in cases(True):
            frame = ethernet(case)
            self.assertEqual(checksum(frame[14:34]) == 0, not case.bad_ip)
            self.assertEqual(struct.unpack('!H', frame[38:40])[0], len(case.payload) + 8)
            self.assertEqual(frame[42:], case.payload)
            self.assertEqual(mii_frame(case)[:8], b'\x55' * 7 + b'\xd5')

    def test_uart_resynchronizes_and_keeps_consecutive_records(self):
        master, slave = pty.openpty()
        reader = UartReader(os.ttyname(slave))
        try:
            # Keep a partial magic through a timeout, then finish it next read.
            os.write(master, b'garbageCME')
            with self.assertRaises(TimeoutError):
                reader.record(time.monotonic() + 0.02)
            expected = (6, 7, 6, 2, 0, 0, 1, 1)
            os.write(master, b'7' + struct.pack('<8I', *expected)
                     + b'CME7' + struct.pack('<8I', *expected))
            self.assertEqual(reader.record(time.monotonic() + 1), expected)
            self.assertEqual(reader.record(time.monotonic() + 1), expected)
            self.assertTrue(reader.raw.startswith(b'garbageCME7'))
        finally:
            os.close(reader.fd)
            os.close(master)
            os.close(slave)


class MessageEncodingTests(unittest.TestCase):
    def test_declared_sizes_describe_the_bytes_that_follow(self):
        for entries in (0, 1, 7, MTU_ENTRIES):
            encoded = message(entries)
            self.assertEqual(struct.unpack('<H', encoded[:2])[0], len(encoded))
            self.assertEqual(len(encoded), MESSAGE_OVERHEAD + (entries * 32))

    # Root padding is the only way to reach a payload that is a whole number of 8-byte
    # beats: the packet header is 12 bytes and an unpadded message is a multiple of 8, so
    # every other fixture in the repository ends on a partial beat.
    def test_root_block_padding_aligns_the_payload_to_whole_beats(self):
        padded = message(1, root_block=feed_traffic.ALIGNED_ROOT_BLOCK)
        self.assertEqual(struct.unpack_from('<H', padded, 2)[0],
                         feed_traffic.ALIGNED_ROOT_BLOCK)
        self.assertEqual(struct.unpack('<H', padded[:2])[0], len(padded))
        self.assertEqual(len(payload_of(padded)) % 8, 0)
        self.assertNotEqual(len(payload_of(message(1))) % 8, 0)

    def test_last_of_event_sets_only_the_flagged_message(self):
        flags = [encoded[18] for encoded in
                 split_messages(message(1, last_of_event=False) + message(1))]
        self.assertEqual(flags, [0, 0x80])

    def test_raw_messages_declare_a_size_they_do_not_have(self):
        self.assertLess(struct.unpack('<H', raw_message(9, b'bad')[:2])[0], 10)
        beyond = raw_message(1000, b'short')
        self.assertGreater(struct.unpack('<H', beyond[:2])[0], len(payload_of(beyond)))


class BoardRunSequenceTests(unittest.TestCase):
    """The acceptance sequence is a chain of absolute counter tuples, so a single wrong
    number quietly shifts every case after it. These check the chain's own shape; the XML
    oracle in phase7_contracts.ml separately decodes the payloads and confirms the
    numbers themselves."""

    def test_mtu_cases_continue_where_the_base_sequence_stops(self):
        base, heavy = cases(), mtu_cases()
        self.assertEqual(base[-1].expected[0] + 1, heavy[0].expected[0])
        self.assertEqual(base[-1].sequence + 1, heavy[0].sequence)

    def test_every_transmitted_frame_fits_the_wire(self):
        for case in run_cases():
            self.assertLessEqual(len(case.payload), MAX_UDP_PAYLOAD, case.name)
            self.assertLessEqual(len(ethernet(case)), MAX_FRAME, case.name)

    def test_counters_never_go_backwards_and_count_every_selected_packet(self):
        previous = (0,) * len(COUNTERS)
        for case in run_cases():
            for name, before, after in zip(COUNTERS, previous, case.expected):
                self.assertGreaterEqual(after, before, f'{case.name}.{name}')
            expected_packets = previous[0] + (1 if case.port == PORT else 0)
            self.assertEqual(case.expected[0], expected_packets, case.name)
            previous = case.expected

    # Only one case is padded to a whole number of beats; if that stopped being true the
    # full-beat claim would be silently untested rather than failing.
    def test_exactly_one_case_ends_on_a_full_beat(self):
        full = [c.name for c in run_cases() if len(c.payload) % 8 == 0]
        self.assertEqual(full, ['mtu_full_final_beat'])

    # An independent statement of the same expectations: the sender's model derives the
    # tuples from the sequencing rules instead of reading them off the case list.
    def test_the_sender_model_reproduces_every_expected_tuple(self):
        model = feed_traffic.Model()
        for case in run_cases():
            model.observe(case, dict(
                updates=sum(case.counts),
                end_of_event=1 if case.last_only else len(case.counts),
                diagnostics=0))
            self.assertEqual(model.expected, case.expected, case.name)

    # The heavy cases are payload fixtures for the oracle only. Keeping them out of the
    # MII vectors is what holds iverilog to an elaboration and compile gate.
    def test_mtu_cases_are_fixtures_but_not_mii_vectors(self):
        with tempfile.TemporaryDirectory() as directory:
            directory = Path(directory)
            write_vectors(directory)
            lines = (directory / 'mii_vectors.txt').read_text().splitlines()
            self.assertEqual(len(lines), len(cases(True)))
            for case in run_cases():
                self.assertEqual((directory / f'{case.name}.bin').read_bytes(),
                                 case.payload, case.name)


class ShapeTests(unittest.TestCase):
    def shaped(self, name, last_only=False, inject=''):
        body, contribution = feed_traffic.body(
            feed_traffic.NAMED_SHAPES.get(name) or feed_traffic.shape(name),
            last_only, inject)
        return payload_of(body), contribution

    def test_named_mtu_shapes_are_the_largest_that_fit(self):
        for name in ('mtu-deep', 'mtu-wide'):
            payload, _ = self.shaped(name)
            self.assertLessEqual(len(payload), MAX_UDP_PAYLOAD)
        one_deeper = PACKET_HEADER + MESSAGE_OVERHEAD + ((MTU_ENTRIES + 1) * 32)
        one_wider = PACKET_HEADER + ((MTU_MESSAGES + 1) * (MESSAGE_OVERHEAD + 32))
        self.assertGreater(one_deeper, MAX_UDP_PAYLOAD)
        self.assertGreater(one_wider, MAX_UDP_PAYLOAD)

    def test_shapes_predict_one_update_per_entry(self):
        for name, updates in (('mtu-deep', MTU_ENTRIES), ('mtu-wide', MTU_MESSAGES),
                              ('8x4', 32), ('aligned', 1)):
            _, contribution = self.shaped(name)
            self.assertEqual(contribution['updates'], updates, name)

    def test_last_only_collapses_a_packet_to_one_event(self):
        _, many = self.shaped('8x4')
        _, one = self.shaped('8x4', last_only=True)
        self.assertEqual(many['end_of_event'], 8)
        self.assertEqual(one['end_of_event'], 1)
        self.assertEqual(many['updates'], one['updates'])

    # An unsupported template is skipped by its declared size, so the messages after it
    # still parse; a size that cannot be trusted ends the packet instead.
    def test_injections_predict_exactly_one_diagnostic(self):
        _, plain = self.shaped('4x2')
        _, skipped = self.shaped('4x2', inject='unsupported')
        self.assertEqual(skipped['diagnostics'], 1)
        self.assertEqual(skipped['updates'], plain['updates'])
        for kind in ('bad-size', 'beyond-packet'):
            _, aborted = self.shaped('4x2', inject=kind)
            self.assertEqual(aborted, dict(updates=0, end_of_event=0, diagnostics=1))

    def test_bad_shapes_are_rejected(self):
        for text in ('', 'nonsense', '0x1', '1x0', '3'):
            with self.assertRaises(argparse.ArgumentTypeError):
                feed_traffic.shape(text)


class ModelTests(unittest.TestCase):
    def plan(self, **overrides):
        args = argparse.Namespace(
            count=1, sequence=100, shape=[feed_traffic.Shape(1, 1)], last_only=False,
            port=PORT, gap_after=set(), gap_size=1, duplicate_after=set(), inject={},
            bad_ip_after=set())
        vars(args).update(overrides)
        return feed_traffic.plan(args, args.sequence)

    def predict(self, packets, next_sequence=None):
        model = feed_traffic.Model(next_sequence)
        for case, contribution in packets:
            model.observe(case, contribution)
        return dict(zip(feed_traffic.COUNTERS, model.expected))

    def test_gap_duplicate_and_bad_ip_are_predicted_together(self):
        packets = self.plan(count=4, gap_after={0}, duplicate_after={2},
                            bad_ip_after={1})
        self.assertEqual([case.sequence for case, _ in packets],
                         [100, 102, 103, 103, 104])
        self.assertEqual(self.predict(packets), dict(
            packets=5, updates=4, end_of_event=4, diagnostics=2, crc_errors=0,
            ip_errors=1, sequence_gaps=1, duplicates=1))

    # A duplicate's payload is dropped, so however heavy it is it contributes nothing
    # beyond the diagnostic.
    def test_a_duplicate_heavy_packet_contributes_only_its_diagnostic(self):
        packets = self.plan(count=1, duplicate_after={0},
                            shape=[feed_traffic.NAMED_SHAPES['mtu-deep']])
        self.assertEqual(self.predict(packets), dict(
            packets=2, updates=MTU_ENTRIES, end_of_event=1, diagnostics=1, crc_errors=0,
            ip_errors=0, sequence_gaps=0, duplicates=1))

    # Filtered traffic is dropped ahead of the parser, but the IPv4 verdict is raised by
    # the network stack before the port filter and must still be counted.
    def test_filtered_traffic_moves_only_the_network_counter(self):
        packets = self.plan(count=3, port=PORT + 1, bad_ip_after={0, 2})
        self.assertEqual(self.predict(packets), dict(
            packets=0, updates=0, end_of_event=0, diagnostics=0, crc_errors=0,
            ip_errors=2, sequence_gaps=0, duplicates=0))

    def test_shapes_are_cycled_across_the_run(self):
        packets = self.plan(count=4, shape=feed_traffic.shapes('1x1,2x3'))
        self.assertEqual([contribution['updates'] for _, contribution in packets],
                         [1, 6, 1, 6])

    def test_an_oversized_shape_is_refused_before_anything_is_sent(self):
        with self.assertRaises(SystemExit):
            self.plan(count=1, shape=feed_traffic.shapes('30x1'))


class SequencerStateTests(unittest.TestCase):
    """The harness sequencer's expected value is session state that the UART record does
    not carry, so the sender has to track it across runs. Getting this wrong is not a
    cosmetic prediction error: a second run that replays the first run's sequence range is
    entirely duplicates, and the board is right to say so."""

    FRESH = (0,) * len(COUNTERS)

    def args(self, **overrides):
        args = argparse.Namespace(
            count=2000, sequence=None, assume_next_sequence=None,
            shape=[feed_traffic.NAMED_SHAPES['mtu-deep']], last_only=True, port=PORT,
            gap_after=set(), gap_size=1, duplicate_after=set(), inject={},
            bad_ip_after=set(), state=Path('unused'))
        vars(args).update(overrides)
        return args

    def deltas(self, args, baseline, stored):
        known, start, _ = feed_traffic.resolve_sequencer(args, baseline, stored)
        model = feed_traffic.Model(known)
        for case, contribution in feed_traffic.plan(args, start):
            model.observe(case, contribution)
        return start, model, dict(zip(COUNTERS, model.expected))

    def test_a_fresh_board_starts_from_the_default_sequence(self):
        start, model, delta = self.deltas(self.args(), self.FRESH, None)
        self.assertEqual(start, feed_traffic.DEFAULT_SEQUENCE)
        self.assertEqual(delta['packets'], 2000)
        self.assertEqual(delta['updates'], 2000 * MTU_ENTRIES)
        self.assertEqual(delta['duplicates'], 0)
        self.assertEqual(model.next_sequence, feed_traffic.DEFAULT_SEQUENCE + 2000)

    # The reported failure: run twice without resetting the board. The second run used to
    # replay 100..2099 against a sequencer already at 2100 and predict a clean run.
    def test_a_second_run_continues_instead_of_replaying(self):
        first_start, first, _ = self.deltas(self.args(), self.FRESH, None)
        stored = dict(next_sequence=first.next_sequence,
                      counters=list(first.expected))
        start, model, delta = self.deltas(self.args(), first.expected, stored)
        self.assertEqual(start, first.next_sequence)
        self.assertGreater(start, first_start)
        self.assertEqual(delta['duplicates'], 0)
        self.assertEqual(delta['sequence_gaps'], 0)
        self.assertEqual(delta['updates'], 2000 * MTU_ENTRIES)

    # And if the range really is replayed, the prediction must now say so rather than
    # predicting a clean run.
    def test_a_deliberate_replay_is_predicted_as_all_duplicates(self):
        _, first, _ = self.deltas(self.args(), self.FRESH, None)
        stored = dict(next_sequence=first.next_sequence, counters=list(first.expected))
        _, _, delta = self.deltas(
            self.args(sequence=feed_traffic.DEFAULT_SEQUENCE), first.expected, stored)
        self.assertEqual(delta, dict(
            packets=2000, updates=0, end_of_event=0, diagnostics=2000, crc_errors=0,
            ip_errors=0, sequence_gaps=0, duplicates=2000))

    def test_a_forward_jump_is_predicted_as_one_gap(self):
        _, first, _ = self.deltas(self.args(), self.FRESH, None)
        stored = dict(next_sequence=first.next_sequence, counters=list(first.expected))
        _, _, delta = self.deltas(
            self.args(count=3, sequence=first.next_sequence + 500), first.expected, stored)
        self.assertEqual(delta['sequence_gaps'], 1)
        self.assertEqual(delta['diagnostics'], 1)
        self.assertEqual(delta['duplicates'], 0)
        self.assertEqual(delta['updates'], 3 * MTU_ENTRIES)

    # A board carrying traffic this script did not send leaves the sequencer position
    # genuinely unknowable, so it refuses rather than guessing.
    def test_an_unknown_sequencer_position_refuses_to_guess(self):
        busy = (7,) + (0,) * (len(COUNTERS) - 1)
        with self.assertRaises(SystemExit):
            feed_traffic.resolve_sequencer(self.args(), busy, None)
        known, start, _ = feed_traffic.resolve_sequencer(
            self.args(assume_next_sequence=4242), busy, None)
        self.assertEqual((known, start), (4242, 4242))

    def test_a_board_reset_between_runs_is_detected_from_the_baseline(self):
        stale = dict(next_sequence=9999, counters=[5] * len(COUNTERS))
        known, start, note = feed_traffic.resolve_sequencer(
            self.args(), self.FRESH, stale)
        self.assertIsNone(known)
        self.assertEqual(start, feed_traffic.DEFAULT_SEQUENCE)
        self.assertIn('freshly reset', note)

    def test_unexpected_counter_movement_is_called_out(self):
        stored = dict(next_sequence=2100, counters=[1] * len(COUNTERS))
        _, _, note = feed_traffic.resolve_sequencer(
            self.args(), (9,) * len(COUNTERS), stored)
        self.assertIn('WARNING', note)

    def test_state_survives_a_round_trip(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'nested' / 'sender_state.json'
            self.assertEqual(feed_traffic.load_state(path), {})
            entry = {'eth0:31337': dict(next_sequence=2100, counters=[1] * 8)}
            feed_traffic.save_state(path, entry)
            self.assertEqual(feed_traffic.load_state(path), entry)


class EpilogExampleTests(unittest.TestCase):
    """The examples printed by --help are what a new session copies first, so they have to
    stay runs this script still accepts. One of them paired an injection that grows a
    packet with the shapes that are already the largest that fit, and nothing noticed until
    it was run against the board."""

    def examples(self):
        """Recover each shell command from the epilog, comments and continuations aside."""
        commands, current = [], []
        for line in feed_traffic.build_parser().epilog.splitlines():
            line = line.strip()
            if not line or line.startswith('#') or line == 'Examples:':
                continue
            continued = line.endswith('\\')
            current.append(line.rstrip('\\').strip())
            if not continued:
                commands.append(' '.join(current))
                current = []
        self.assertEqual(current, [], 'an example ends on a dangling continuation')
        return commands

    def argv_of(self, command):
        words = shlex.split(command)
        if words[0] == 'sudo':
            words = words[1:]
        self.assertEqual(words[0], 'python3', command)
        self.assertTrue(words[1].endswith('feed_traffic.py'), command)
        return words[2:]

    def refusal(self, command):
        """Plan the example without sending it; return why it was refused, or None."""
        captured = io.StringIO()
        try:
            with contextlib.redirect_stderr(captured):
                args = feed_traffic.parse_args(self.argv_of(command))
                feed_traffic.plan(args, args.sequence or feed_traffic.DEFAULT_SEQUENCE)
        except SystemExit as refused:
            return f'{refused}\n{captured.getvalue()}'.strip()
        return None

    def test_every_example_describes_a_run_that_is_accepted(self):
        examples = self.examples()
        self.assertGreater(len(examples), 1)
        for command in examples:
            refusal = self.refusal(command)
            if refusal is not None:
                self.fail(f'{command}\n  refused: {refusal}')

    # Losing an example silently narrows what --help demonstrates, and the kinds differ in
    # whether they replace a message body or prefix one, which is what constrains the shape
    # they can be used with.
    def test_the_examples_demonstrate_every_injection_kind(self):
        text = ' '.join(self.examples())
        for kind in feed_traffic.INJECTIONS:
            self.assertIn(kind, text, kind)


if __name__ == '__main__':
    unittest.main()
