#!/usr/bin/env bash
# Run in the Linux simulator environment with a display (xvfb-run in CI).
set -euo pipefail

device=${1:?Provide a Garmin device ID}
project=$(cd "$(dirname "$0")/.." && pwd)
build=$(mktemp -d)
umask 077
simulator_pid=
cleanup() {
    result=$?
    if [[ -n "$simulator_pid" ]]; then
        kill "$simulator_pid" 2>/dev/null || true
        wait "$simulator_pid" 2>/dev/null || true
    fi
    if [[ "$result" != 0 && -f "$build/simulator.log" ]]; then
        cat "$build/simulator.log" >&2
    fi
    rm -rf "$build"
}
trap cleanup EXIT

openssl genrsa 4096 | openssl pkcs8 -topk8 -nocrypt -outform DER -out "$build/test-key.der"
args=(-f "$project/PadelAlTanto/monkey.jungle" -d "$device" -y "$build/test-key.der")
monkeyc "${args[@]}" -r -o "$build/PADELAT.PRG"
monkeyc "${args[@]}" -t -o "$build/tests.prg"

simulator >"$build/simulator.log" 2>&1 &
simulator_pid=$!
for ((attempt=0; attempt<60; attempt++)); do
    kill -0 "$simulator_pid"
    if (: > /dev/tcp/127.0.0.1/1234) 2>/dev/null; then
        break
    fi
    sleep 0.5
done
if ((attempt == 60)); then
    echo "Simulator did not open port 1234 in 30 seconds." >&2
    exit 1
fi
python3 "$project/scripts/run_tests.py" "$device" "$build/tests.prg"
