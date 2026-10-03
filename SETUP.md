# Clawd Mochi setup for Claude Code

These instructions are written for Claude Code. A person sets up Mochi by
plugging it in and telling Claude Code:

> Set up my Clawd Mochi following github.com/victorgalvez56/clawd-mochi-usage

Claude Code then follows the steps below. Nothing is installed: the bridge is a
small script that uses only what ships with macOS or Windows.

## What the setup does and does not do

- It adds a Claude Code status line that forwards two numbers to Mochi over USB:
  the weekly and five-hour usage percentages, plus their reset times.
- It never reads prompts, project files, credentials, API keys, or OAuth tokens,
  and it never sends anything over the network.
- It never removes an existing status line. If one exists, Mochi is added to it.

## Requirements to check first

1. **Claude Code 2.1.251 or newer.** Check with `claude --version`.
2. **A claude.ai Pro or Max plan** (or a Claude apps gateway with a spend limit).
   Claude Code only provides usage percentages for these. With an API key there
   is nothing to show, and Mochi stays in its eyes-only mode. Tell the person
   this plainly instead of continuing.
3. **Mochi connected with a data USB-C cable.**

## Step 1. Find the Mochi

### macOS

```bash
ls /dev/cu.usbmodem*
```

One result is the Mochi. None means it is not connected or the cable is
charge-only. If there are several, ask the person to unplug the Mochi, list
again, and use the port that disappeared.

### Windows

```powershell
Get-CimInstance Win32_PnPEntity -Filter "PNPClass='Ports'" | Where-Object PNPDeviceID -like 'USB\VID_303A&PID_1001*' | Select-Object Name
```

The Mochi appears as a `USB Serial Device (COMn)`. The bridge finds it on its
own by this USB ID, so the port does not need to be saved unless several
Espressif boards are connected.

## Step 2. Install the bridge script

Download the bridge into the person's Claude Code folder. Read it before saving
it, and tell the person what it does.

| System | Source | Destination |
| --- | --- | --- |
| macOS | `https://raw.githubusercontent.com/victorgalvez56/clawd-mochi-usage/main/tools/claude-mochi-statusline.sh` | `~/.claude/clawd-mochi-statusline.sh` (then `chmod 700`) |
| Windows | `https://raw.githubusercontent.com/victorgalvez56/clawd-mochi-usage/main/tools/claude-mochi-statusline.ps1` | `%USERPROFILE%\.claude\clawd-mochi-statusline.ps1` |

## Step 3. Connect it to the status line

Read `~/.claude/settings.json` (`%USERPROFILE%\.claude\settings.json` on
Windows). Before changing it, copy it to
`settings.json.before-clawd-mochi-<date>`. Keep every other setting as it is.

### If there is no `statusLine`

Add one. On Windows, write the path with forward slashes: Claude Code runs status
lines through Git Bash when it is installed, and Git Bash strips backslashes.

macOS:

```json
"statusLine": {
  "type": "command",
  "command": "~/.claude/clawd-mochi-statusline.sh",
  "refreshInterval": 30
}
```

Windows (replace the user folder):

```json
"statusLine": {
  "type": "command",
  "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"C:/Users/<user>/.claude/clawd-mochi-statusline.ps1\"",
  "refreshInterval": 30
}
```

### If a `statusLine` already exists

Do not replace it. Keep the person's command and make it also pass the same
input to the bridge in quiet mode, which forwards to Mochi and prints nothing:

- If the command points to a script, edit that script. Right after it reads
  stdin into a variable, add one line that pipes that variable to the bridge:
  - Bash on macOS: `printf '%s' "$input" | ~/.claude/clawd-mochi-statusline.sh --quiet`
  - Bash on Windows (Git Bash): `printf '%s' "$input" | powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:/Users/<user>/.claude/clawd-mochi-statusline.ps1" -Quiet`
  - PowerShell: `$inputText | powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.claude\clawd-mochi-statusline.ps1" -Quiet`
  - Use the script's own variable name for the stdin contents. Run the bridge as
    a separate process as shown: it reads its standard input, so calling it with
    `&` inside the same PowerShell session would not pass the data.
- If the command is inline, move it into a small script that saves stdin,
  pipes it to the bridge in quiet mode, then runs the original command with the
  same input, and point `statusLine.command` to that script.

Show the person the change before saving it.

### Several Espressif boards connected

Pass the port explicitly: on macOS put `CLAWD_MOCHI_PORT=/dev/cu.usbmodemXXXX `
before the command, and on Windows add ` -Port COMn` after the script path.

## Step 4. Verify

1. Run the bridge with sample data. The Mochi switches to the usage screen with
   these values, which are replaced by the real ones after the next response.

   macOS:

   ```bash
   echo '{"rate_limits":{"seven_day":{"used_percentage":22},"five_hour":{"used_percentage":5}}}' | ~/.claude/clawd-mochi-statusline.sh
   ```

   Windows:

   ```powershell
   '{"rate_limits":{"seven_day":{"used_percentage":22},"five_hour":{"used_percentage":5}}}' | powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.claude\clawd-mochi-statusline.ps1"
   ```

   The command prints `[Claude] 5h 5% | week 22%`. Ask the person whether the
   Mochi shows the bars. If it does not, see
   [Troubleshooting](docs/TROUBLESHOOTING.md).
2. Tell the person to restart Claude Code. From then on, Mochi shows the real
   usage right after each Claude response.

## How Mochi behaves afterwards

| Situation | Screen |
| --- | --- |
| Connected to the computer, usage received at least once | Usage, kept on screen and redrawn after each response |
| Connected to a charger or power bank | Eyes, alternating between the still and animated views |
| Never received usage | Eyes |

Mochi stores the last usage, so after a restart it shows it as soon as it is
connected to the computer again.

## Undo

Restore the `settings.json.before-clawd-mochi-<date>` backup, or remove the
`statusLine` entry (or the quiet-mode line added to an existing script), and
delete the bridge script from the Claude Code folder.
