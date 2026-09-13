#!/usr/bin/env bash
# Claude Code status line + Clawd Mochi USB usage bridge for macOS.
# Claude Code supplies a session JSON document through stdin every time the
# status line refreshes. This script forwards only the public rate-limit values
# to the ESP32-C3 over USB serial; it never reads credentials.

if ! command -v jq >/dev/null 2>&1; then
  # This stays visible in Claude Code and makes a missing prerequisite obvious
  # without interrupting the session or producing shell error noise.
  printf '[Claude] install jq to send Mochi usage'
  exit 0
fi

input=$(cat)

model=$(printf '%s' "$input" | jq -r '.model.display_name // "Claude"')
weekly=$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
five_hour=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')

format_reset() {
  local epoch="$1"
  if [ -n "$epoch" ]; then
    date -r "$epoch" "+%b %-d %H:%M" 2>/dev/null || printf 'unknown'
  else
    printf 'unknown'
  fi
}

send_usage_to_mochi() {
  [ -n "$weekly" ] && [ -n "$five_hour" ] || return

  local weekly_int five_hour_int weekly_reset five_hour_reset port candidate
  weekly_int=$(printf '%.0f' "$weekly")
  five_hour_int=$(printf '%.0f' "$five_hour")
  weekly_reset=$(format_reset "$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')")
  five_hour_reset=$(format_reset "$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')")

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

if [ -n "$weekly" ] && [ -n "$five_hour" ]; then
  printf '[%s] 5h %s%% · week %s%%' "$model" "$(printf '%.0f' "$five_hour")" "$(printf '%.0f' "$weekly")"
else
  printf '[%s] usage pending' "$model"
fi
