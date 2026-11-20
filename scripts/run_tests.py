#!/usr/bin/env python3
"""Run and verify a Connect IQ test binary."""

import argparse
from contextlib import contextmanager, suppress
import os
from pathlib import Path
import re
import signal
import socket
import subprocess
import sys
from tempfile import TemporaryFile
import time


def passed_test_names(output: str) -> set[str]:
    # The last RESULTS block is the simulator's report for this invocation.
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
    return names


def compiled_test_names(registry: Path) -> list[str]:
    source = registry.read_text(encoding="utf-8")
    sizes = re.findall(r"^\s*idToName = new \[([0-9]+)\];$", source, flags=re.MULTILINE)
    entries = re.findall(
        r'^\s*idToName\[([0-9]+)\] = "([A-Za-z_][A-Za-z0-9_.$]*)";$',
        source,
        flags=re.MULTILINE,
    )
    names = [name for _, name in entries]
    if (
        len(sizes) != 1
        or not names
        or len(names) != int(sizes[0])
        or len(set(names)) != len(names)
        or any(int(index) != position for position, (index, _) in enumerate(entries))
    ):
        raise ValueError(f"Invalid or empty Connect IQ test registry: {registry}")
    return names


def simulator_listening() -> bool:
    try:
        with socket.create_connection(("127.0.0.1", 1234), timeout=0.2):
            return True
    except OSError:
        return False


@contextmanager
def fresh_simulator():
    if simulator_listening():
        raise ValueError("Port 1234 is already in use. Isolated tests need their own simulator.")

    with TemporaryFile(mode="w+", encoding="utf-8", errors="replace") as log:
        simulator = subprocess.Popen(["simulator"], stdout=log, stderr=subprocess.STDOUT)
        finished = False
        try:
            for _ in range(60):
                if simulator.poll() is not None:
                    raise ValueError(f"Simulator exited with status {simulator.returncode} at startup.")
                if simulator_listening():
                    break
                time.sleep(0.5)
            else:
                raise ValueError("Simulator did not open port 1234 in 30 seconds.")
            yield
            finished = True
        finally:
            if simulator.poll() is None:
                simulator.terminate()
                try:
                    simulator.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    simulator.kill()
                    simulator.wait()
            if not finished:
                log.seek(0)
                print(log.read(), end="", file=sys.stderr, flush=True)


def run_monkeydo(command: list[str], timeout: int) -> set[str]:
    with subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        encoding="utf-8",
        errors="replace",
        start_new_session=True,
    ) as process:
        try:
            output, _ = process.communicate(timeout=timeout)
        except subprocess.TimeoutExpired:
            # monkeydo starts Java and the SDK shell as child processes.
            with suppress(ProcessLookupError):
                os.killpg(process.pid, signal.SIGKILL)
            output, _ = process.communicate()
            print(output, end="", flush=True)
            raise ValueError(f"Monkey Do timed out after {timeout} seconds.") from None

    print(output, end="", flush=True)
    # Garmin's SDK can return 1 even when every case passes.
    if process.returncode not in (0, 1):
        raise ValueError(f"Monkey Do exited with status {process.returncode}.")
    return passed_test_names(output)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("device", help="Connect IQ device ID")
    parser.add_argument("program", type=Path, help="PRG compiled with --unit-test")
    parser.add_argument("--monkeydo", default="monkeydo", help="path to the SDK's monkeydo")
    parser.add_argument(
        "--isolated-tests",
        type=Path,
        metavar="UNIT_TESTS_MCGEN",
        help="use the generated test registry and start a new simulator for each case",
    )
    parser.add_argument("--timeout", type=int, default=120, help="Monkey Do timeout per invocation (default: 120 s)")
    args = parser.parse_args()
    if args.timeout <= 0:
        parser.error("--timeout must be positive")
    if not args.program.is_file():
        parser.error(f"test binary does not exist: {args.program}")

    command = [args.monkeydo, str(args.program.resolve()), args.device, "-t"]
    try:
        if args.isolated_tests is None:
            count = len(run_monkeydo(command, args.timeout))
        else:
            names = compiled_test_names(args.isolated_tests)
            count = len(names)
            for index, name in enumerate(names, start=1):
                print(f"{args.device}: {name} ({index}/{count})", flush=True)
                with fresh_simulator():
                    passed = run_monkeydo([*command, name], args.timeout)
                    if passed != {name}:
                        reported = ", ".join(sorted(passed))
                        raise ValueError(f"Expected test {name}, but Monkey Do reported: {reported}.")
    except (OSError, ValueError) as error:
        print(f"{args.device}: {error}", file=sys.stderr)
        return 1

    print(f"{args.device}: {count} tests passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
