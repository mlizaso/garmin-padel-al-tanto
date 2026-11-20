#!/bin/zsh
set -eu

carpeta="${0:A:h}"
local_sdk="$carpeta/work/herramientas/sdk"
config="$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg"
if [[ -x /opt/homebrew/opt/openjdk@17/bin/java ]]; then
    export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
fi

if [[ -n "${CONNECTIQ_HOME:-}" ]]; then
    sdk="$CONNECTIQ_HOME"
elif [[ -d "$local_sdk/ciq/bin/ConnectIQ.app" ]]; then
    sdk="$local_sdk/ciq"
    export JAVA_TOOL_OPTIONS="${JAVA_TOOL_OPTIONS:-} -Djava.awt.headless=true -Duser.home=\"$local_sdk/profile\""
elif [[ -f "$config" ]]; then
    sdk="$(<"$config")"
elif (( $+commands[monkeydo] )); then
    sdk="${commands[monkeydo]:h:h}"
else
    echo 'Instala Connect IQ y el perfil fēnix 7 con Garmin SDK Manager, o define CONNECTIQ_HOME.' >&2
    exit 1
fi
if [[ "$sdk" == "$local_sdk/ciq" ]]; then
    open --env "CFFIXED_USER_HOME=$local_sdk/profile" -a "$sdk/bin/ConnectIQ.app"
else
    open -a "$sdk/bin/ConnectIQ.app"
fi
sleep 2
exec "$sdk/bin/monkeydo" "$carpeta/PADELAT.PRG" fenix7
