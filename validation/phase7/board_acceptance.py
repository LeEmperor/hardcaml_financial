#!/usr/bin/env python3
# University of Florida
# Author: Bohdan Purtell
# Module: "board_acceptance.py"
# Fixed Phase 7 board acceptance: the wire encoders, the MII vector set, and the
# machine-checked UART capture of one pass/fail sequence with absolute counter tuples.
# The sibling script, feed_traffic.py, generates arbitrary traffic against these encoders
# and derives its own expectations instead.
import argparse
import dataclasses
import datetime
import hashlib
import json
import os
from pathlib import Path
import select
import socket
import struct
import termios
import time
import zlib

COUNTERS = ('packets', 'updates', 'end_of_event', 'diagnostics',
            'crc_errors', 'ip_errors', 'sequence_gaps', 'duplicates')
PORT = 31337
DEFAULT_IFACE = 'enx207bd25880ef'
TEMPLATE = 46
ROOT_BLOCK = 11
ENTRY_BLOCK = 32
# 1500-byte Ethernet MTU less the 20-byte IPv4 and 8-byte UDP headers.
MAX_UDP_PAYLOAD = 1472
# 4-byte sequence number plus 8-byte sending time.
PACKET_HEADER = 12
# SBE header, root block, MBP group dimension and the empty order-ID group.
MESSAGE_OVERHEAD = 10 + ROOT_BLOCK + 3 + 8
LAST_MSG_OF_EVENT = 0x80
# Root-block padding that lands the payload on an exact 8-byte beat boundary. A packet
# header is 12 bytes and an unpadded message is a multiple of 8, so without padding every
# datagram ends on a partial beat and the board never sees a full final beat.
ALIGNED_ROOT_BLOCK = ROOT_BLOCK + 4

# Deepest MBP group, and most single-entry messages, that still fit one datagram.
MTU_ENTRIES = (MAX_UDP_PAYLOAD - PACKET_HEADER - MESSAGE_OVERHEAD) // ENTRY_BLOCK
MTU_MESSAGES = (MAX_UDP_PAYLOAD - PACKET_HEADER) // (MESSAGE_OVERHEAD + ENTRY_BLOCK)
# The same, once root padding has taken its bytes out of the entry budget.
MTU_ALIGNED_ENTRIES = ((MAX_UDP_PAYLOAD - PACKET_HEADER - MESSAGE_OVERHEAD
                        - (ALIGNED_ROOT_BLOCK - ROOT_BLOCK)) // ENTRY_BLOCK)


def message(entries=1, time_value=123, template=TEMPLATE, last_of_event=True,
            root_block=ROOT_BLOCK):
    # CME Production schema 1/version 13, template 46; reserved padding is explicit.
    # root_block above 11 appends reserved root padding the decoder must skip, which is
    # also the only way to reach a payload length that is a whole number of 8-byte beats.
    entry = struct.pack('<qiiIiBBBi', -123, 10, 1234, 7, 3, 2, 1, ord('0'), 9) + b'\0'
    body = struct.pack('<QB', time_value, LAST_MSG_OF_EVENT if last_of_event else 0)
    body += b'\0' * (root_block - 9)
    body += struct.pack('<HB', ENTRY_BLOCK, entries) + entry * entries
    body += struct.pack('<H', 24) + b'\0' * 6  # empty order-ID group
    return struct.pack('<5H', 10 + len(body), root_block, template, 1, 13) + body


def pack_messages(counts, last_only=False, root_block=ROOT_BLOCK):
    """Assemble one packet body: one message per entry count in [counts].

    With [last_only] the LastMsgOfEvent flag is set on the final message alone, so a
    multi-message packet is one event rather than one event per message, which is the
    shape a real incremental refresh arrives in."""
    counts = tuple(counts)
    return b''.join(
        message(count, 123 + index, root_block=root_block,
                last_of_event=not last_only or index == len(counts) - 1)
        for index, count in enumerate(counts))


def raw_message(declared_size, body=b''):
    """An SBE header whose declared size does not describe the bytes that follow.

    Below 10 the size cannot even cover the header (invalid_message_size); beyond what
    the datagram holds the message runs off the end (message_beyond_packet)."""
    return struct.pack('<5H', declared_size, ROOT_BLOCK, TEMPLATE, 1, 13) + body


@dataclasses.dataclass(frozen=True)
class Case:
    name: str
    sequence: int
    counts: tuple
    expected: tuple
    port: int = PORT
    bad_crc: bool = False
    bad_ip: bool = False
    # Set LastMsgOfEvent on the final message only, collapsing the packet to one event.
    last_only: bool = False
    # Reserved root padding the decoder must skip; the only route to a full final beat.
    root_block: int = ROOT_BLOCK
    # Pre-encoded message bytes, for shapes [counts] cannot express such as a malformed
    # declared size. When empty the body is built from [counts].
    body: bytes = b''

    @property
    def payload(self):
        body = self.body or pack_messages(self.counts, self.last_only, self.root_block)
        payload = struct.pack('<IQ', self.sequence, 99) + body
        if len(payload) > MAX_UDP_PAYLOAD:
            raise ValueError(f'{self.name}: {len(payload)} payload bytes exceeds the '
                             f'{MAX_UDP_PAYLOAD}-byte MTU limit')
        return payload


def cases(include_errors=False):
    result = [
        Case('single_partial_tail', 100, (1,), (1, 1, 1, 0, 0, 0, 0, 0)),
        Case('multiple_messages', 101, (1, 2), (2, 4, 3, 0, 0, 0, 0, 0)),
        Case('sequence_gap', 103, (1,), (3, 5, 4, 1, 0, 0, 1, 0)),
        Case('duplicate', 103, (1,), (4, 5, 4, 2, 0, 0, 1, 1)),
        Case('after_duplicate', 104, (1,), (5, 6, 5, 2, 0, 0, 1, 1)),
        Case('filtered_port', 900, (1,), (5, 6, 5, 2, 0, 0, 1, 1), port=PORT + 1),
        Case('after_filtered', 105, (1,), (6, 7, 6, 2, 0, 0, 1, 1)),
    ]
    if include_errors:
        result += [
            Case('late_bad_fcs', 106, (1,), (7, 8, 7, 2, 1, 0, 1, 1), bad_crc=True),
            Case('bad_ip_checksum', 107, (1,), (8, 9, 8, 2, 1, 1, 1, 1), bad_ip=True),
        ]
    return result


def mtu_cases():
    """Board-run acceptance at MTU scale, continuing the counters [cases] leaves behind:
    six packets, next sequence 106, and (6, 7, 6, 2, 0, 0, 1, 1) already on the wire.

    These are deliberately absent from the MII vector set. iverilog is the elaboration and
    compile gate, and functional coverage of heavy traffic lives in Cyclesim under
    test/cme/validation_core/validation_core_heavy_traffic_tests.ml. What a board run adds
    is the one thing no simulation shows: the same shapes surviving a real PHY, a real MAC
    and the real 25 MHz application clock, back to back at line rate.

    Every expected tuple here is checked independently by the XML oracle in
    phase7_contracts.ml, which decodes these payloads with the golden decoder rather than
    trusting the arithmetic below."""
    deep = (MTU_ENTRIES,)
    return [
        # One message with the deepest MBP group a datagram can carry.
        Case('mtu_deep_group', 106, deep, (7, 51, 7, 2, 0, 0, 1, 1)),
        # The same byte budget spent on single-entry messages, one event each.
        Case('mtu_many_messages', 107, (1,) * MTU_MESSAGES, (8, 73, 29, 2, 0, 0, 1, 1)),
        # Many messages that together form one event.
        Case('mtu_single_event', 108, (4,) * 8, (9, 105, 30, 2, 0, 0, 1, 1),
             last_only=True),
        # Payload is a whole number of 8-byte beats: the final beat is full.
        Case('mtu_full_final_beat', 109, (MTU_ALIGNED_ENTRIES,), (10, 149, 31, 2, 0, 0, 1, 1),
             root_block=ALIGNED_ROOT_BLOCK),
        # A gap raises a diagnostic but the heavy payload behind it still parses.
        Case('mtu_sequence_gap', 111, deep, (11, 193, 32, 3, 0, 0, 2, 1)),
        # A duplicate is dropped whole, however many entries it carries.
        Case('mtu_duplicate', 111, deep, (12, 193, 32, 4, 0, 0, 2, 2)),
        Case('mtu_after_duplicate', 112, deep, (13, 237, 33, 4, 0, 0, 2, 2)),
    ]


def run_cases():
    """Everything a board run transmits, in order. Error cases are excluded: a NIC
    generates the real Ethernet FCS, and a frame it emits always carries a valid one."""
    return cases() + mtu_cases()


def checksum(data):
    total = sum(struct.unpack('!%dH' % (len(data) // 2), data))
    while total >> 16:
        total = (total & 0xffff) + (total >> 16)
    return (~total) & 0xffff


def ethernet(case):
    udp = struct.pack('!4H', 12345, case.port, 8 + len(case.payload), 0) + case.payload
    ip = bytearray(struct.pack('!BBHHHBBH4s4s', 0x45, 0, 20 + len(udp), 0,
                               0x4000, 64, 17, 0, socket.inet_aton('192.168.1.10'),
                               socket.inet_aton('192.168.1.1')))
    struct.pack_into('!H', ip, 10, checksum(ip) ^ int(case.bad_ip))
    return bytes.fromhex('020000000001 deadbeef0002 0800') + ip + udp


def mii_frame(case):
    frame = ethernet(case)
    frame += b'\0' * max(0, 60 - len(frame))
    fcs = zlib.crc32(frame) ^ int(case.bad_crc)
    return b'\x55' * 7 + b'\xd5' + frame + struct.pack('<I', fcs)


def write_vectors(directory):
    directory.mkdir(parents=True, exist_ok=True)
    vector_cases = cases(True)
    with (directory / 'mii_vectors.txt').open('w') as stream:
        for case in vector_cases:
            frame = mii_frame(case)
            stream.write(f'{len(frame):x} ' + ' '.join(f'{v:02x}' for v in frame)
                         + ' ' + ' '.join(f'{v:x}' for v in case.expected) + '\n')
    # Payload fixtures cover the MTU-scale board cases as well, so the XML oracle checks
    # their expected counters even though they never enter the MII vector set.
    named = {case.name: case for case in vector_cases + mtu_cases()}
    for case in named.values():
        (directory / f'{case.name}.bin').write_bytes(case.payload)
    (directory / 'cases.json').write_text(json.dumps([
        dict(name=c.name, payload_bytes=len(c.payload), sequence=c.sequence,
             in_mii_vectors=c in vector_cases,
             expected=dict(zip(COUNTERS, c.expected))) for c in named.values()],
        indent=2) + '\n')


class UartReader:
    def __init__(self, device):
        self.fd = os.open(device, os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
        config = termios.tcgetattr(self.fd)
        config[0] = config[1] = config[3] = 0
        config[2] = termios.CS8 | termios.CREAD | termios.CLOCAL
        config[4] = config[5] = termios.B115200
        config[6][termios.VMIN] = config[6][termios.VTIME] = 0
        termios.tcsetattr(self.fd, termios.TCSANOW, config)
        termios.tcflush(self.fd, termios.TCIFLUSH)
        self.buffer = bytearray()
        self.raw = bytearray()

    def record(self, deadline):
        while time.monotonic() < deadline:
            start = self.buffer.find(b'CME7')
            if start >= 0:
                del self.buffer[:start]
                if len(self.buffer) >= 36:
                    record = struct.unpack('<8I', self.buffer[4:36])
                    del self.buffer[:36]
                    return record
            elif len(self.buffer) > 3:
                del self.buffer[:-3]
            if select.select([self.fd], [], [], max(0, deadline - time.monotonic()))[0]:
                data = os.read(self.fd, 4096)
                self.raw.extend(data)
                self.buffer.extend(data)
        raise TimeoutError('No complete CME7 UART record before timeout')


def provenance():
    root = Path(__file__).resolve().parents[2]
    paths = [root / 'cme_feed_parser_validation_harness_arty.v',
             root / 'cme_mdp3_feed_parser.v',
             root / 'validation/constraints/cme_arty.xdc', root / 'docs/templates.xml']
    package_record = root / '_build/phase7/networking_package.txt'
    result = dict(sha256={str(p): hashlib.sha256(p.read_bytes()).hexdigest()
                          for p in paths if p.exists()})
    if package_record.exists():
        result['networking_package'] = package_record.read_text().strip()
    return result


def board_run(args):
    # Never append FCS on a NIC: its hardware generates the actual Ethernet FCS.
    report = dict(started_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                  device='xc7a100tcsg324-1', application_clock_mhz=25,
                  interface=args.iface, serial=args.serial, results=[], passed=False,
                  **provenance())
    reader = UartReader(args.serial)
    try:
        baseline = reader.record(time.monotonic() + args.timeout)
        if baseline != (0,) * 8:
            raise RuntimeError(f'Reset the board before this run; counters are {baseline}')
        with socket.socket(socket.AF_PACKET, socket.SOCK_RAW, socket.htons(0x0800)) as tx:
            tx.bind((args.iface, 0))
            for case in run_cases():
                tx.send(ethernet(case))
                deadline = time.monotonic() + args.timeout
                matched = 0
                observations = []
                result = dict(case=case.name, expected=dict(zip(COUNTERS, case.expected)),
                              observations=observations, passed=False)
                report['results'].append(result)
                while matched < 2:
                    observed = reader.record(deadline)
                    observations.append(dict(zip(COUNTERS, observed)))
                    matched = matched + 1 if observed == case.expected else 0
                    # All counters are monotonic within this short, reset-isolated run.
                    if any(a > b for a, b in zip(observed, case.expected)):
                        break
                result['passed'] = matched == 2
                if matched != 2:
                    raise RuntimeError(f'{case.name}: counter mismatch: {observed}')
                print(f'PASS {case.name}: {observed}', flush=True)
        report['passed'] = True
    except Exception as error:
        report['error'] = str(error)
        raise
    finally:
        os.close(reader.fd)
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(report, indent=2) + '\n')
        args.output.with_suffix('.uart.bin').write_bytes(reader.raw)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    vectors = commands.add_parser('vectors', help='write deterministic simulation inputs; sends no traffic')
    vectors.add_argument('directory', type=Path)
    run = commands.add_parser('run', help='send board cases and verify UART counters (CAP_NET_RAW required)')
    run.add_argument('--iface', default=DEFAULT_IFACE,
                     help='network interface to transmit on (default: %(default)s)')
    run.add_argument('--serial', required=True)
    run.add_argument('--output', type=Path, required=True)
    run.add_argument('--timeout', type=float, default=8)
    args = parser.parse_args()
    if args.command == 'vectors':
        write_vectors(args.directory)
    else:
        board_run(args)


if __name__ == '__main__':
    main()
