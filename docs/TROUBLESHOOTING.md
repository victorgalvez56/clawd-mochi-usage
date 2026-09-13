# Troubleshooting Claude usage over USB-C

## The display shows eyes but never shows usage

This is the safe default: it means Mochi has not received valid usage data yet.

1. Run the sample test command in the [main setup guide](../README.md#2-confirm-the-display-before-configuring-claude).
   If that works, the wiring and firmware are correct.
2. Restart Claude Code after running the installer.
3. Send a prompt and wait for Claude's response. The rate-limit data is available
   to the status line only after that first response.
4. Confirm the Claude account or gateway provides rate-limit values to Claude
   Code. The bridge cannot show limits that Claude Code does not provide.

## macOS says `install jq to send Mochi usage`

Install the one required parser, then restart Claude Code:

```bash
brew install jq
```

## The installer says that a status line already exists

The installer protects the existing Claude Code customization. Either keep that
status line and merge this project's forwarding logic into it, or explicitly
replace it with the installer. A backup is created before replacement.

```bash
./tools/install-macos.sh --force
```

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\install-windows.ps1 -Force
```

## More than one serial device is connected

Save the port explicitly when installing. On macOS, list likely Mochi ports:

```bash
ls /dev/cu.usbmodem*
```

Then run the macOS installer with `--port /dev/cu.usbmodem…`. On Windows, use
the `COM` number shown in Device Manager and run the installer with `-Port COM3`.

## The sample test cannot find a port

Use a USB-C data cable, not a charge-only cable. Reconnect the device, wait a
few seconds, and check whether a new serial port appears. On Windows, if there
is still no COM port, install the serial driver appropriate for the USB chip on
the specific ESP32-C3 Super Mini board.

## Why is there no Fable meter?

The official Claude Code status-line payload documents weekly and five-hour
rate-limit values. It does not provide a separate Fable value. Showing a made-up
or scraped number would be misleading, so Mochi displays only the data Claude
Code officially supplies.
