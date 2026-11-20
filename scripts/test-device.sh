#!/usr/bin/env bash
# Run in the Linux simulator environment with a display (xvfb-run in CI).
set -euo pipefail

device=${1:?Provide a Garmin device ID}
project=$(cd "$(dirname "$0")/.." && pwd)
build=$(mktemp -d)
umask 077
trap 'rm -rf "$build"' EXIT

openssl genrsa 4096 | openssl pkcs8 -topk8 -nocrypt -outform DER -out "$build/test-key.der"
args=(-f "$project/PadelAlTanto/monkey.jungle" -d "$device" -y "$build/test-key.der")
monkeyc "${args[@]}" -r -o "$build/PADELAT.PRG"
monkeyc "${args[@]}" -t -o "$build/tests.prg"

registries=("$build"/gen/*/source/UnitTests.mcgen)
if (( ${#registries[@]} != 1 )) || [[ ! -f "${registries[0]}" ]]; then
    echo "Expected one compiler-generated UnitTests.mcgen for $device." >&2
    exit 1
fi
python3 "$project/scripts/run_tests.py" "$device" "$build/tests.prg" --isolated-tests "${registries[0]}"
