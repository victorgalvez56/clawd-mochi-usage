# Clawd Mochi Usage Display

Turn a Clawd Mochi into a USB-C companion for Claude Code. It works without
Wi-Fi: when it is not connected to a computer it shows its eyes; when Claude
Code is active, it adds a rotating usage screen.

**Public repository:** <https://github.com/victorgalvez56/clawd-mochi-usage>

## What it shows

| Claude Code has usage data | Mochi cycle |
| --- | --- |
| No | Normal eyes 5 s → animated eyes 5 s |
| Yes | Usage 10 s → normal eyes 5 s → animated eyes 5 s |

The usage screen shows the all-model weekly percentage and the five-hour
percentage, plus their reset times. It only receives those four public values
from Claude Code's status-line data. It never reads prompts, project files,
passwords, cookies, API keys, or OAuth credentials.

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

The installers copy the bridge into the current user's Claude Code folder and
safely add a `statusLine` entry with a 30-second refresh. If a person already
uses a custom Claude Code status line, the installer stops rather than replacing
it. They can choose `--force` / `-Force`, and a dated settings backup is made
first.

### macOS

Requirements: Claude Code 2.1.251 or newer, Node.js, and `jq`.

```bash
brew install jq                 # only if jq is not already installed
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

Windows uses its built-in serial-port support. Most current Windows systems add
the ESP32-C3 USB serial device automatically when online; if no COM port appears,
install the USB serial driver supplied for the board's USB chip.

## 4. Use it

Restart Claude Code after installing, open any session, and send one prompt.
After Claude responds, wait up to 30 seconds. The status line forwards the two
available rate-limit percentages to Mochi, which starts the three-screen cycle.

The exact message sent to the ESP32 is simple and can be used by other tools:

```text
USAGE|<weekly percent>|<five-hour percent>|<weekly reset label>|<five-hour reset label>
```

Example:

```text
USAGE|22|5|Sep 10 04:59|Sep 8 16:00
```

## Selling checklist

1. Flash the firmware and confirm normal/animated eye rotation unplugged from a computer.
2. Connect USB-C and run the test command for the buyer's operating system.
3. Include this repository link and tell the buyer to run the installer for their OS.
4. State clearly that the usage card needs a compatible Claude Code account and
   that the device still works as an eye display without it.

## Credits

This project builds on [yousifamanuel/clawd-mochi](https://github.com/yousifamanuel/clawd-mochi),
released under the MIT License. See [LICENSE](LICENSE).
