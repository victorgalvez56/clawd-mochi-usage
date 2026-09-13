# Clawd Mochi Usage Display

Firmware and USB bridges for macOS and Windows for a Clawd Mochi built with an ESP32-C3 Super Mini
and a 1.54-inch 240×240 ST7789 IPS display.

The Mochi is a desk companion first: with no computer data it alternates between
normal eyes and animated eyes. When Claude Code usage is available over USB-C,
it rotates through a usage card for 10 seconds, normal eyes for 5 seconds, and
animated eyes for 5 seconds.

## Hardware

| Display | ESP32-C3 Super Mini |
| --- | --- |
| GND | GND |
| VCC | 3.3V only |
| SCL | GPIO 8 |
| SDA | GPIO 10 |
| RES | GPIO 2 |
| DC | GPIO 1 |
| CS | GPIO 4 |
| BLK / BKL | GPIO 3 |

`SCL` and `SDA` on this display are SPI clock and SPI MOSI, not I²C.

## Flash the firmware

1. Install Arduino IDE and the **esp32 by Espressif Systems** board package.
2. Install these libraries from Library Manager:
   - `Adafruit GFX Library`
   - `Adafruit ST7735 and ST7789 Library`
3. Open `firmware/clawd_mochi/clawd_mochi.ino`.
4. Select **ESP32C3 Dev Module**, enable **USB CDC On Boot**, select 160 MHz,
   and upload at 921600 baud.

The firmware has been tested with the display wiring listed above. VCC must not
be connected to 5V.

## Connect Claude Code usage over USB-C

Keep the Mochi connected to the computer by USB-C. Claude Code sends its status-line
JSON to a shell command after it receives a response. The included command reads
the weekly and five-hour percentages and sends a small serial message to Mochi.
It does not read passwords, OAuth tokens, prompts, or project files.

### Install the status line

```bash
chmod +x tools/claude-mochi-statusline.sh
```

Add this field to `~/.claude/settings.json` (preserve any settings you already
have):

```json
{
  "statusLine": {
    "type": "command",
    "command": "/absolute/path/to/claude-mochi-statusline.sh",
    "refreshInterval": 30
  }
}
```

Replace `/absolute/path/to` with the folder in which you cloned this repository.
If you already use a Claude Code status line, merge the `send_usage_to_mochi`
function into it instead of replacing it.

Start or resume a Claude Code session and send one prompt. On eligible Claude.ai
plans, Claude Code provides the `five_hour` and `seven_day` rate-limit values to
the status line after the first response. The Mochi will begin the three-screen
rotation as soon as it receives them.

If several serial devices are attached, set the exact device port before starting
Claude Code:

```bash
export CLAWD_MOCHI_PORT=/dev/cu.usbmodem101
```

### Windows

Windows 10 and 11 normally install the ESP32-C3 USB serial driver automatically
when online. Connect the Mochi, then find its `COM` port in **Device Manager →
Ports (COM & LPT)**. If more than one USB serial device is attached, set that
port before launching Claude Code:

```powershell
$env:CLAWD_MOCHI_PORT = 'COM3'
```

Configure Claude Code to use the PowerShell bridge in its user settings. Replace
the path with the location where you cloned this repository:

```json
{
  "statusLine": {
    "type": "command",
    "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"C:\\path\\to\\claude-mochi-statusline.ps1\"",
    "refreshInterval": 30
  }
}
```

The script is at `tools/claude-mochi-statusline.ps1`. It uses Windows' built-in
serial-port support and does not require Python, Arduino IDE, or a separate USB
driver download on current Windows versions. As on macOS, merge its send logic
into an existing Claude Code status line instead of replacing one you already
use.

## Display behaviour

| Data available | Cycle |
| --- | --- |
| No Claude usage received | Normal eyes 5 s → animated eyes 5 s |
| Claude usage received | Usage 10 s → normal eyes 5 s → animated eyes 5 s |

The display keeps working as an eyes-only companion without Wi-Fi or a computer.
The ESP32-C3's USB interface is serial, so this usage connection does not require
joining the Mochi Wi-Fi network on macOS or Windows.

## USB protocol

The firmware accepts a newline-delimited message at 115200 baud:

```text
USAGE|<weekly percent>|<five-hour percent>|<weekly reset label>|<five-hour reset label>
```

Example:

```text
USAGE|22|5|Sep 10 04:59|Sep 8 16:00
```

The current bridge intentionally uses the two rate-limit fields that Claude Code
provides to its supported status-line interface: weekly all-model usage and the
five-hour window. A separate Fable allowance is not part of that supported
payload, so it is not guessed or synthesized here.

## Credits

This project builds on [yousifamanuel/clawd-mochi](https://github.com/yousifamanuel/clawd-mochi),
released under the MIT License. See `LICENSE`.
