#!/usr/bin/env bash
# Sends sample percentages to validate a flashed Mochi without Claude Code.
# Usage: ./tools/send-test-usage-macos.sh [weekly] [five-hour] [port]

set -euo pipefail

weekly="${1:-22}"
five_hour="${2:-5}"
port="${3:-${CLAWD_MOCHI_PORT:-}}"

if [ -z "$port" ]; then
  for candidate in /dev/cu.usbmodem*; do
    [ -e "$candidate" ] || continue
    port="$candidate"
    break
  done
fi

if [ -z "$port" ] || [ ! -e "$port" ]; then
  printf '%s\n' 'No Mochi serial port found. Connect it, or pass /dev/cu.usbmodem… as the third argument.' >&2
  exit 1
fi

stty -f "$port" 115200 raw -echo -icrnl -onlcr
printf 'USAGE|%s|%s|Weekly reset|5h reset\n' "$weekly" "$five_hour" > "$port"
printf 'Sent test usage to %s: week %s%%, 5h %s%%.\n' "$port" "$weekly" "$five_hour"
