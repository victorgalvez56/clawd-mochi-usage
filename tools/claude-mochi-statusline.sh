#!/usr/bin/env bash
# Claude Code status line + Clawd Mochi USB usage bridge for macOS.
# Claude Code supplies a session JSON document through stdin every time the
# status line refreshes. This script forwards only the public rate-limit values
# to the ESP32-C3 over USB serial; it never reads credentials. It uses only
# tools that ship with macOS (plutil reads the JSON), so nothing needs installing.
#
# --quiet  Forward to Mochi but print nothing, so an existing status line
#          script can pipe its own stdin here and keep its own output.

quiet=false
[ "${1:-}" = "--quiet" ] && quiet=true

input=$(cat)

# Prints the value at a dotted key path, or nothing when it is absent.
json_value() {
  printf '%s' "$input" | plutil -extract "$1" raw -o - - 2>/dev/null
}

model=$(json_value model.display_name)
model=${model:-Claude}
weekly=$(json_value rate_limits.seven_day.used_percentage)
five_hour=$(json_value rate_limits.five_hour.used_percentage)

format_reset() {
  local epoch="$1"
  if [ -n "$epoch" ]; then
    date -r "${epoch%.*}" "+%b %-d %H:%M" 2>/dev/null || printf 'unknown'
  else
    printf 'unknown'
  fi
}

send_usage_to_mochi() {
  [ -n "$weekly" ] && [ -n "$five_hour" ] || return

  local weekly_int five_hour_int weekly_reset five_hour_reset port candidate
  weekly_int=$(printf '%.0f' "$weekly")
  five_hour_int=$(printf '%.0f' "$five_hour")
  weekly_reset=$(format_reset "$(json_value rate_limits.seven_day.resets_at)")
  five_hour_reset=$(format_reset "$(json_value rate_limits.five_hour.resets_at)")

  # Set CLAWD_MOCHI_PORT when more than one USB serial device is connected.
  port="${CLAWD_MOCHI_PORT:-}"
  if [ -z "$port" ]; then
    for candidate in /dev/cu.usbmodem*; do
      [ -e "$candidate" ] || continue
      port="$candidate"
      break
    done
  fi
  [ -n "$port" ] && [ -e "$port" ] || return

  stty -f "$port" 115200 raw -echo -icrnl -onlcr >/dev/null 2>&1 || return
  printf 'USAGE|%s|%s|%s|%s\n' "$weekly_int" "$five_hour_int" "$weekly_reset" "$five_hour_reset" > "$port" 2>/dev/null
}

send_usage_to_mochi

$quiet && exit 0
if [ -n "$weekly" ] && [ -n "$five_hour" ]; then
  printf '[%s] 5h %s%% | week %s%%' "$model" "$(printf '%.0f' "$five_hour")" "$(printf '%.0f' "$weekly")"
else
  printf '[%s] usage pending' "$model"
fi
