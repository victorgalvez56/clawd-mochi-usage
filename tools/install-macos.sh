#!/usr/bin/env bash
# Installs the Clawd Mochi Claude Code status-line bridge for the current user.
# Usage: ./tools/install-macos.sh [--port /dev/cu.usbmodem101] [--force]

set -euo pipefail

force=false
port=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --force) force=true ;;
    --port)
      shift
      [ "$#" -gt 0 ] || { printf '%s\n' 'Missing value after --port.' >&2; exit 1; }
      port="$1"
      ;;
    -h|--help)
      printf '%s\n' 'Usage: ./tools/install-macos.sh [--port /dev/cu.usbmodem101] [--force]'
      exit 0
      ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 1 ;;
  esac
  shift
done

if ! command -v jq >/dev/null 2>&1; then
  printf '%s\n' 'This bridge needs jq. Install it with: brew install jq'
  exit 1
fi
if ! command -v node >/dev/null 2>&1; then
  printf '%s\n' 'This installer needs Node.js to safely update Claude Code settings.'
  printf '%s\n' 'Install Node.js, then run this command again.'
  exit 1
fi

script_dir=$(cd "$(dirname "$0")" && pwd)
claude_dir="$HOME/.claude"
settings_path="$claude_dir/settings.json"
bridge_path="$claude_dir/clawd-mochi-statusline.sh"

mkdir -p "$claude_dir"

export CLAWD_MOCHI_SETTINGS_PATH="$settings_path"
export CLAWD_MOCHI_BRIDGE_PATH="$bridge_path"
export CLAWD_MOCHI_FORCE="$force"
export CLAWD_MOCHI_PORT_TO_SAVE="$port"

node <<'NODE'
const fs = require('fs');

const settingsPath = process.env.CLAWD_MOCHI_SETTINGS_PATH;
const bridgePath = process.env.CLAWD_MOCHI_BRIDGE_PATH;
const force = process.env.CLAWD_MOCHI_FORCE === 'true';
const port = process.env.CLAWD_MOCHI_PORT_TO_SAVE;
let settings = {};

if (fs.existsSync(settingsPath)) {
  try {
    settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));
  } catch {
    console.error(`Cannot read valid JSON from ${settingsPath}. Fix it before installing.`);
    process.exit(1);
  }
}

if (settings.statusLine && !force) {
  console.error('Claude Code already has a statusLine. No settings were changed.');
  console.error('Run again with --force to replace it; a dated backup will be made first.');
  process.exit(2);
}

if (fs.existsSync(settingsPath)) {
  const backup = `${settingsPath}.before-clawd-mochi-${new Date().toISOString().replace(/[:.]/g, '-')}`;
  fs.copyFileSync(settingsPath, backup);
  console.log(`Backed up existing settings to ${backup}`);
}

const shellQuote = value => `'${value.replace(/'/g, `'\\''`)}'`;
let command = shellQuote(bridgePath);
if (port) command = `CLAWD_MOCHI_PORT=${shellQuote(port)} ${command}`;

settings.statusLine = { type: 'command', command, refreshInterval: 30 };
fs.writeFileSync(settingsPath, `${JSON.stringify(settings, null, 2)}\n`, { mode: 0o600 });
NODE

cp "$script_dir/claude-mochi-statusline.sh" "$bridge_path"
chmod 700 "$bridge_path"

printf '%s\n' 'Clawd Mochi is connected to Claude Code for this macOS user.'
printf '%s\n' 'Restart Claude Code, send one prompt, and wait up to 30 seconds for the usage screen.'
