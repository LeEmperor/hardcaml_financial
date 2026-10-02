#!/usr/bin/env python3
"""Host-side companion for uart_loopback_validation_harness.

The harness echoes every byte it receives. That makes "did it work" a question
with more than two answers, so this classifies rather than asserts: a probe byte
comes back on time, comes back late, comes back wrong, comes back twice, or does
not come back. Lumping those together is how a marginal baud rate gets recorded
as a pass.

    python3 validation/uart_app.py --echo --port /dev/ttyUSB1
    python3 validation/uart_app.py --echo --count 256 --pattern counter

Needs pyserial. The Arty's USB-UART is normally /dev/ttyUSB1 on Linux (ttyUSB0
is the JTAG channel) and a /dev/tty.usbserial-* on macOS.

The classifier is separated from the serial port on purpose: [classify_echo]
takes a list of received bytes and knows nothing about hardware, which is what
lets test_uart_app_echo.py check it with no board and no serial port.
"""

import argparse
import sys
import time

DEFAULT_PORT = "/dev/ttyUSB1"
DEFAULT_BAUD = 115200

# Verdicts, in the order they are reported.
ON_TIME = "on-time"
LATE = "late"
CORRUPT = "corrupt"
DUPLICATE = "duplicate"
LOST = "lost"
VERDICTS = [ON_TIME, LATE, CORRUPT, DUPLICATE, LOST]


def make_payload(pattern, count):
    """The bytes to send. Each pattern targets a different failure.

    counter   every value in turn: catches a stuck bit that only shows in some
              positions, and is the only pattern that distinguishes a receiver
              that dropped a byte from one that duplicated its neighbour.
    alternate 0x55 / 0xAA: maximum transition density, which is where a baud
              rate that is slightly off first fails.
    zeros     0x00: the byte a receiver that mistook the start bit for data
              loses, because the frame is then all-space.
    ones      0xFF: an idle line looks exactly like this, so a receiver that
              announces without ever having seen a start bit passes everything
              else and fails here.
    """
    if pattern == "counter":
        return bytes((i & 0xFF) for i in range(count))
    if pattern == "alternate":
        return bytes((0x55 if i % 2 == 0 else 0xAA) for i in range(count))
    if pattern == "zeros":
        return bytes(count)
    if pattern == "ones":
        return b"\xff" * count
    raise ValueError(f"unknown pattern: {pattern}")


def classify_echo(sent, received, late_index=None):
    """Classify one echo run. Pure: no serial port, no clock.

    [sent] and [received] are byte strings. [late_index] is the count of bytes
    that had already arrived when the read deadline passed, so anything at or
    after it came back after the timeout. Pass None when the whole run finished
    inside the deadline.

    Returns (verdicts, tally). [verdicts] is one entry per sent byte, so the
    position of a fault is preserved rather than only its count.
    """
    verdicts = []
    n_late = len(sent) if late_index is None else late_index
    for index, expected in enumerate(sent):
        if index >= len(received):
            verdicts.append(LOST)
        elif received[index] != expected:
            verdicts.append(CORRUPT)
        elif index >= n_late:
            verdicts.append(LATE)
        else:
            verdicts.append(ON_TIME)
    # Bytes past the end of what was sent are echoes of nothing.
    for _ in range(len(received) - len(sent)):
        verdicts.append(DUPLICATE)
    tally = {verdict: verdicts.count(verdict) for verdict in VERDICTS}
    return verdicts, tally


def first_fault(sent, received, verdicts):
    """Index, expectation and observation of the first non-on-time byte, or None.

    A tally says how bad; this says where, which is the half that tells you
    whether the line is marginal or the framing is wrong."""
    for index, verdict in enumerate(verdicts):
        if verdict != ON_TIME:
            got = received[index] if index < len(received) else None
            want = sent[index] if index < len(sent) else None
            return index, want, got, verdict
    return None


def report(sent, received, verdicts, tally, elapsed=None):
    print(f"sent {len(sent)} byte(s), received {len(received)}")
    for verdict in VERDICTS:
        print(f"  {verdict:<10} {tally[verdict]}")
    fault = first_fault(sent, received, verdicts)
    if fault is None:
        print("all bytes echoed on time")
    else:
        index, want, got, verdict = fault
        want_s = "--" if want is None else f"0x{want:02x}"
        got_s = "--" if got is None else f"0x{got:02x}"
        print(f"first fault at index {index}: sent {want_s}, got {got_s} ({verdict})")
    if elapsed is not None and sent:
        print(f"elapsed {elapsed:.3f}s ({len(sent) / elapsed:.1f} byte/s)")
    return 0 if tally[ON_TIME] == len(sent) and tally[DUPLICATE] == 0 else 1


def open_port(port, baud, timeout):
    try:
        import serial
    except ImportError:
        sys.exit("error: pyserial is required (pip install pyserial)")
    return serial.Serial(port, baud, timeout=timeout)


def echo(port, baud, count, pattern, timeout, gap):
    """Send the payload, read back what comes, classify it."""
    sent = make_payload(pattern, count)
    handle = open_port(port, baud, timeout)
    received = bytearray()
    late_index = None
    start = time.monotonic()
    deadline = start + timeout + (gap * len(sent))
    handle.reset_input_buffer()
    for byte in sent:
        handle.write(bytes([byte]))
        if gap:
            time.sleep(gap)
        chunk = handle.read(handle.in_waiting or 1)
        received.extend(chunk)
        if late_index is None and time.monotonic() > deadline:
            # Everything from here on came back after the deadline.
            late_index = len(received)
    # Drain whatever is still in flight, so a late echo is counted as late
    # rather than as lost.
    handle.timeout = timeout
    while True:
        chunk = handle.read(handle.in_waiting or 1)
        if not chunk:
            break
        received.extend(chunk)
    elapsed = time.monotonic() - start
    handle.close()
    verdicts, tally = classify_echo(sent, bytes(received), late_index)
    return report(sent, bytes(received), verdicts, tally, elapsed)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--echo", action="store_true",
                        help="send a payload and classify what comes back")
    parser.add_argument("--port", default=DEFAULT_PORT)
    parser.add_argument("--baud", type=int, default=DEFAULT_BAUD)
    parser.add_argument("--count", type=int, default=64)
    parser.add_argument("--pattern", default="counter",
                        choices=["counter", "alternate", "zeros", "ones"])
    parser.add_argument("--timeout", type=float, default=1.0,
                        help="seconds to wait for an echo before calling it late")
    parser.add_argument("--gap", type=float, default=0.0,
                        help="seconds between sent bytes; 0 streams them")
    args = parser.parse_args()
    if not args.echo:
        parser.error("nothing to do: pass --echo")
    return echo(args.port, args.baud, args.count, args.pattern,
                args.timeout, args.gap)


if __name__ == "__main__":
    sys.exit(main())
