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

script_dir=$(cd "$(dirname "$0")" && pwd)
claude_dir="$HOME/.claude"
settings_path="$claude_dir/settings.json"
bridge_path="$claude_dir/clawd-mochi-statusline.sh"

mkdir -p "$claude_dir"

export CLAWD_MOCHI_SETTINGS_PATH="$settings_path"
export CLAWD_MOCHI_BRIDGE_PATH="$bridge_path"
export CLAWD_MOCHI_FORCE="$force"
export CLAWD_MOCHI_PORT_TO_SAVE="$port"

# JavaScript for Automation ships with macOS, so no Node.js or jq is needed.
osascript -l JavaScript <<'JXA'
ObjC.import('Foundation');
ObjC.import('stdlib');
const env = $.NSProcessInfo.processInfo.environment;
const getEnv = name => ObjC.unwrap(env.objectForKey(name)) || '';
const settingsPath = getEnv('CLAWD_MOCHI_SETTINGS_PATH');
const bridgePath = getEnv('CLAWD_MOCHI_BRIDGE_PATH');
const force = getEnv('CLAWD_MOCHI_FORCE') === 'true';
const port = getEnv('CLAWD_MOCHI_PORT_TO_SAVE');
const fm = $.NSFileManager.defaultManager;
const readText = path => ObjC.unwrap($.NSString.stringWithContentsOfFileEncodingError(path, $.NSUTF8StringEncoding, null));
const writeText = (path, text) => $(text).writeToFileAtomicallyEncodingError(path, true, $.NSUTF8StringEncoding, null);
const fail = (message, code) => { console.log(message); $.exit(code); };

let settings = {};
if (fm.fileExistsAtPath(settingsPath)) {
  try {
    settings = JSON.parse(readText(settingsPath));
  } catch (error) {
    fail(`Cannot read valid JSON from ${settingsPath}. Fix it before installing.`, 1);
  }
}

if (settings.statusLine && !force) {
  fail('Claude Code already has a statusLine. No settings were changed.\n' +
    'To keep it, ask Claude Code to follow SETUP.md, which adds Mochi to the existing status line.\n' +
    'To replace it, run again with --force; a dated backup will be made first.', 2);
}

if (fm.fileExistsAtPath(settingsPath)) {
  const backup = `${settingsPath}.before-clawd-mochi-${new Date().toISOString().replace(/[:.]/g, '-')}`;
  fm.copyItemAtPathToPathError(settingsPath, backup, null);
  console.log(`Backed up existing settings to ${backup}`);
}

const shellQuote = value => `'${value.replace(/'/g, `'\\''`)}'`;
let command = shellQuote(bridgePath);
if (port) command = `CLAWD_MOCHI_PORT=${shellQuote(port)} ${command}`;

settings.statusLine = { type: 'command', command, refreshInterval: 30 };
writeText(settingsPath, `${JSON.stringify(settings, null, 2)}\n`);
// osascript prints the value of the last expression; end on undefined to print nothing.
undefined;
JXA
chmod 600 "$settings_path"

cp "$script_dir/claude-mochi-statusline.sh" "$bridge_path"
chmod 700 "$bridge_path"

printf '%s\n' 'Clawd Mochi is connected to Claude Code for this macOS user.'
printf '%s\n' 'Restart Claude Code and send one prompt; the usage screen appears right after the response.'
