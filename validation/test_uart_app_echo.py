#!/usr/bin/env python3
"""Offline check of uart_app.classify_echo().

No board, no serial port, no root: the classifier is pure, so the fake wire here
is just a byte string. What is being verified is that the five outcomes stay
distinguishable - late is not lost, corrupt is not lost, and a duplicate is
neither. Run it after touching the classifier:

    python3 validation/test_uart_app_echo.py    # exit 0 = all cases classified right
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import uart_app as U

FAILURES = []


def check(name, actual, expected):
    if actual != expected:
        FAILURES.append(f"{name}: expected {expected}, got {actual}")


def tally_of(sent, received, late_index=None):
    _, tally = U.classify_echo(sent, received, late_index)
    return {verdict: count for verdict, count in tally.items() if count}


def test_clean_echo():
    sent = U.make_payload("counter", 8)
    check("clean", tally_of(sent, sent), {U.ON_TIME: 8})


def test_lost_tail():
    sent = U.make_payload("counter", 8)
    check("lost tail", tally_of(sent, sent[:5]), {U.ON_TIME: 5, U.LOST: 3})


def test_corrupt_byte():
    sent = U.make_payload("counter", 8)
    received = bytearray(sent)
    received[3] ^= 0x01
    check("corrupt", tally_of(sent, bytes(received)), {U.ON_TIME: 7, U.CORRUPT: 1})


def test_late_is_not_lost():
    """The distinction the whole classifier exists for: the bytes arrived, just
    after the deadline. A tally that called these lost would send you looking
    for a framing bug instead of a slow link."""
    sent = U.make_payload("counter", 8)
    check("late", tally_of(sent, sent, late_index=5), {U.ON_TIME: 5, U.LATE: 3})


def test_duplicate():
    sent = U.make_payload("counter", 4)
    check("duplicate", tally_of(sent, sent + sent[:2]),
          {U.ON_TIME: 4, U.DUPLICATE: 2})


def test_nothing_came_back():
    sent = U.make_payload("counter", 4)
    check("silent", tally_of(sent, b""), {U.LOST: 4})


def test_first_fault_locates_the_byte():
    sent = U.make_payload("counter", 8)
    received = bytearray(sent)
    received[3] = 0xFF
    verdicts, _ = U.classify_echo(sent, bytes(received))
    check("first fault", U.first_fault(sent, bytes(received), verdicts),
          (3, 3, 0xFF, U.CORRUPT))


def test_patterns_are_the_advertised_length_and_shape():
    check("counter", U.make_payload("counter", 4), b"\x00\x01\x02\x03")
    check("alternate", U.make_payload("alternate", 4), b"\x55\xaa\x55\xaa")
    check("zeros", U.make_payload("zeros", 3), b"\x00\x00\x00")
    check("ones", U.make_payload("ones", 3), b"\xff\xff\xff")


def main():
    for name, function in sorted(globals().items()):
        if name.startswith("test_") and callable(function):
            function()
    if FAILURES:
        for failure in FAILURES:
            print(f"FAIL {failure}")
        return 1
    print("all echo classification cases pass")
    return 0


if __name__ == "__main__":
    sys.exit(main())
