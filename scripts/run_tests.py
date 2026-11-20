#!/usr/bin/env python3
"""Run and verify a Connect IQ test binary on an already running simulator."""

import argparse
from contextlib import suppress
import os
from pathlib import Path
import re
import signal
import subprocess
import sys


def passed_test_count(output: str) -> int:
    # The last RESULTS block is the simulator's report for the entire suite.
    report = re.split(r"^RESULTS[ \t]*$", output, flags=re.MULTILINE)
    if len(report) == 1:
        raise ValueError("Monkey Do did not produce a RESULTS block.")

    lines = [line.strip() for line in report[-1].splitlines() if line.strip()]
    while lines and lines[-1] in {"Connection Finished", "Closing shell and port"}:
        lines.pop()
    if len(lines) < 4 or not re.fullmatch(r"Test:\s+Status:", lines[0]):
        raise ValueError("Monkey Do produced an incomplete RESULTS block.")

    total = re.fullmatch(r"Ran ([0-9]+) tests?", lines[-2])
    if total is None:
        raise ValueError("Monkey Do did not report a valid test total.")

    footer = lines[-1]
    passed = re.fullmatch(r"PASSED \(passed=([0-9]+), failed=0, errors=0\)", footer)
    if passed is None and footer != "PASSED (failures=0, errors=0)":
        raise ValueError(f"Monkey Do did not report a clean test run: {footer}")

    names = set()
    for line in lines[1:-2]:
        row = re.fullmatch(r"(\S+)\s+PASS", line, flags=re.IGNORECASE)
        if row is None or row[1] in names:
            raise ValueError(f"Invalid or unsuccessful test result: {line}")
        names.add(row[1])

    count = int(total[1])
    if count == 0 or count != len(names) or (passed and count != int(passed[1])):
        raise ValueError("Monkey Do reported inconsistent test totals.")
    return count


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("device", help="Connect IQ device ID")
    parser.add_argument("program", type=Path, help="PRG compiled with --unit-test")
    parser.add_argument("--monkeydo", default="monkeydo", help="path to the SDK's monkeydo")
    parser.add_argument("--timeout", type=int, default=120, help="timeout in seconds (default: 120)")
    args = parser.parse_args()
    if args.timeout <= 0:
        parser.error("--timeout must be positive")
    if not args.program.is_file():
        parser.error(f"test binary does not exist: {args.program}")

    command = [args.monkeydo, str(args.program.resolve()), args.device, "-t"]
    try:
        with subprocess.Popen(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            encoding="utf-8",
            errors="replace",
            start_new_session=True,
        ) as process:
            try:
                output, _ = process.communicate(timeout=args.timeout)
            except subprocess.TimeoutExpired:
                # monkeydo starts Java and the SDK shell as child processes.
                with suppress(ProcessLookupError):
                    os.killpg(process.pid, signal.SIGKILL)
                output, _ = process.communicate()
                print(output, end="", flush=True)
                raise ValueError(f"Monkey Do timed out after {args.timeout} seconds.") from None

        print(output, end="", flush=True)
        # Garmin's SDK can return 1 even when every case passes.
        if process.returncode not in (0, 1):
            raise ValueError(f"Monkey Do exited with status {process.returncode}.")
        count = passed_test_count(output)
    except (OSError, ValueError) as error:
        print(f"{args.device}: {error}", file=sys.stderr)
        return 1

    print(f"{args.device}: {count} tests passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
