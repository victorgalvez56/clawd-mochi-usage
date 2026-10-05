# Clawd Mochi Usage Display

Turn a Clawd Mochi into a USB-C companion for Claude Code. It works without
Wi-Fi: connected to a computer it shows your Claude usage; on a charger it
shows its eyes.

**Public repository:** <https://github.com/victorgalvez56/clawd-mochi-usage>

## What it shows

| Situation | Mochi screen |
| --- | --- |
| Connected to the computer and usage received | Usage card (default) or Clawd's face, kept on screen and updated after each Claude response |
| Connected to a charger or power bank, or no usage received yet | Normal eyes 5 s → animated eyes 5 s |

Mochi stores the last usage it received, so after a restart it shows it as soon
as it is connected to the computer again.

The usage screen shows the all-model weekly percentage and the five-hour
percentage, plus their reset times. It only receives those four public values
from Claude Code's status-line data. It never reads prompts, project files,
passwords, cookies, API keys, or OAuth credentials.

### Choose the usage screen: card or Clawd's face

While connected, Mochi shows one of two screens. The firmware setting
`USAGE_SCREEN` picks which one:

| `USAGE_SCREEN` | Screen |
| --- | --- |
| `USAGE_SCREEN_CARD` (default) | The usage card: weekly and five-hour bars, percentages, and reset times |
| `USAGE_SCREEN_FACE` | Clawd's animated pixel-art face. It shows no numbers; its mood follows how much is left of the tighter limit |

![Clawd's five moods: cool, calm, nervous, sleepy, and dizzy](docs/clawd-faces.gif)

| Left | Clawd |
| --- | --- |
| 60–100 % | Cool: "deal with it" sunglasses slide down, smirk |
| 30–59 % | Calm: square eyes look around and blink, small smile |
| 10–29 % | Nervous: `> <` eyes, shaky mouth, sweat drop |
| 1–9 % | Sleepy: heavy eyelids, yawning, floating Zs |
| 0 % | Dizzy: X eyes, tongue out, stars circling |

To use the face, change this line near the top of
[`clawd_mochi.ino`](firmware/clawd_mochi/clawd_mochi.ino) before flashing:

```cpp
#define USAGE_SCREEN USAGE_SCREEN_FACE
```

Everything else stays the same: the bridge, the installers, and the message
sent over USB.

> Claude Code provides these limits only for eligible Claude.ai plans or a
> supported gateway, after its first response. A separate Fable allowance is
> not exposed by this interface, so this project deliberately does not invent
> one. With no available usage values, Mochi remains an eyes-only companion.

## 1. Wire and flash the Mochi

This firmware is for an **ESP32-C3 Super Mini** and a **ZJY 1.54-inch 240×240
ST7789 IPS** display.

| Display pin | ESP32-C3 Super Mini pin |
| --- | --- |
| GND | GND |
| VCC | **3.3V only** |
| SCL | GPIO 8 |
| SDA | GPIO 10 |
| RES | GPIO 2 |
| DC | GPIO 1 |
| CS | GPIO 4 |
| BLK / BKL | GPIO 3 |

`SCL` and `SDA` on this display are SPI clock and SPI MOSI, not I²C. Never put
the display VCC on 5V.

In Arduino IDE:

1. Install the board package **esp32 by Espressif Systems**.
2. Install `Adafruit GFX Library` and `Adafruit ST7735 and ST7789 Library`.
3. Open [`firmware/clawd_mochi/clawd_mochi.ino`](firmware/clawd_mochi/clawd_mochi.ino).
4. Select **ESP32C3 Dev Module**, set **USB CDC On Boot** to enabled, CPU to
   160 MHz, upload speed to 921600, and upload.

Connect the finished device to the buyer's computer using a data-capable USB-C
cable. The cable supplies power and carries the usage message; neither Wi-Fi
nor a network address is used.

## 2. Confirm the display before configuring Claude

Run one test command after plugging in Mochi. It sends sample values only and
lets you verify the bars before depending on any Claude account.

### macOS

```bash
chmod +x tools/send-test-usage-macos.sh tools/install-macos.sh
./tools/send-test-usage-macos.sh
```

If there is more than one USB serial device, specify the Mochi port:

```bash
./tools/send-test-usage-macos.sh 22 5 /dev/cu.usbmodem101
```

### Windows

Open PowerShell in this repository and run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\send-test-usage.ps1
```

If needed, find Mochi's port in **Device Manager → Ports (COM & LPT)** and run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\send-test-usage.ps1 -Port COM3
```

The Mochi changes to the usage screen for ten seconds, then starts its normal
rotation. If it does not, see [Troubleshooting](docs/TROUBLESHOOTING.md).

## 3. Install the Claude Code connection

### Easiest: let Claude Code set it up

With Mochi plugged in, tell Claude Code:

> Set up my Clawd Mochi following github.com/victorgalvez56/clawd-mochi-usage

Claude Code follows [SETUP.md](SETUP.md): it finds the Mochi, adds the bridge to
the status line (keeping any status line you already have), and sends a test.
This works the same on macOS and Windows and needs no downloads.

### Or run the installer

The installers copy the bridge into the current user's Claude Code folder and
safely add a `statusLine` entry with a 30-second refresh. If a person already
uses a custom Claude Code status line, the installer stops rather than replacing
it. They can choose `--force` / `-Force`, and a dated settings backup is made
first.

### macOS

Requirements: Claude Code 2.1.251 or newer. The bridge uses only tools that ship
with macOS.

```bash
chmod +x tools/install-macos.sh
./tools/install-macos.sh
```

For multiple serial devices, save Mochi's specific port into the configuration:

```bash
./tools/install-macos.sh --port /dev/cu.usbmodem101
```

To deliberately replace an existing Claude Code status line:

```bash
./tools/install-macos.sh --force
```

### Windows 10 or 11

Open PowerShell in this repository:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\install-windows.ps1
```

For a particular device port:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\install-windows.ps1 -Port COM3
```

To deliberately replace an existing Claude Code status line:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\install-windows.ps1 -Force
```

Windows uses its built-in serial-port support, and the bridge finds Mochi by its
USB ID, so there is no COM port to choose. Windows 10 and 11 recognize the
ESP32-C3 USB serial device without a driver.

## 4. Use it

Restart Claude Code after installing, open any session, and send one prompt.
Right after Claude responds, the status line forwards the two rate-limit
percentages to Mochi, which switches to the usage screen.

The exact message sent to the ESP32 is simple and can be used by other tools:

```text
USAGE|<weekly percent>|<five-hour percent>|<weekly reset label>|<five-hour reset label>
```

Example:

```text
USAGE|22|5|Sep 10 04:59|Sep 8 16:00
```

## Limitations

These were checked with Claude Code 2.1.288 on Windows 11 and a Pro plan.

- **Only the Claude Code CLI updates Mochi.** The usage values reach Mochi
  through the status line, which the Claude Code terminal runs. The Claude
  desktop app (its Code tab) does not run status lines, so using only the app
  never updates Mochi.
- **Hooks are not a workaround.** The desktop app does run hooks, but their
  input (session, working folder, tool calls, last message) carries no
  rate-limit values.
- **The CLI refreshes with its own responses.** A `claude` session gets new
  values when it receives a response. If you work in the desktop app while a
  terminal session sits idle, Mochi keeps the last values until that session
  answers again.
- **The limits are per account.** The percentages include everything you use
  with the same account: CLI, desktop app, and claude.ai.

### Using it alongside the desktop app

Keep a `claude` session open in a terminal and send it a prompt now and then;
each response brings Mochi up to date with the usage of the whole account.

## Selling checklist

1. Flash the firmware and confirm normal/animated eye rotation unplugged from a computer.
2. Connect USB-C and run the test command for the buyer's operating system.
3. Include this repository link and tell the buyer to ask Claude Code to set up
   Mochi following it (see [SETUP.md](SETUP.md)).
4. State clearly that the usage card needs Claude Code with a claude.ai Pro or Max plan and
   that the device still works as an eye display without it.

## Credits

This project builds on [yousifamanuel/clawd-mochi](https://github.com/yousifamanuel/clawd-mochi),
released under the MIT License. See [LICENSE](LICENSE).
