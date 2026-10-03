# Claude Code status line + Clawd Mochi USB usage bridge for Windows.
# Claude Code writes a session JSON document to stdin. This script forwards only
# the weekly and five-hour rate-limit values to Mochi over USB serial. It uses
# only what ships with Windows 10 and 11: no jq, Node.js, or drivers.
#
# -Port COM3  Use a specific port instead of detecting the Mochi.
# -Quiet      Forward to Mochi but print nothing, so an existing status line
#             script can pipe its own stdin here and keep its own output.
param(
    [string]$Port,
    [switch]$Quiet
)

$inputText = [Console]::In.ReadToEnd()

try {
    $data = $inputText | ConvertFrom-Json
} catch {
    if (-not $Quiet) { Write-Output '[Claude] usage pending' }
    exit 0
}

$model = if ($data.model.display_name) { $data.model.display_name } else { 'Claude' }
$weekly = $data.rate_limits.seven_day.used_percentage
$fiveHour = $data.rate_limits.five_hour.used_percentage

function Format-Reset([object]$epoch) {
    if ($null -eq $epoch) { return 'unknown' }
    try {
        return [DateTimeOffset]::FromUnixTimeSeconds([int64]$epoch).ToLocalTime().ToString('MMM d HH:mm')
    } catch {
        return 'unknown'
    }
}

# The ESP32-C3 Super Mini enumerates with Espressif's USB ID (VID 303A, PID 1001).
# Reading its COM name from the registry is instant, unlike a WMI query.
function Find-MochiPort {
    $present = [System.IO.Ports.SerialPort]::GetPortNames()
    $usbRoot = 'HKLM:\SYSTEM\CurrentControlSet\Enum\USB'
    $espressif = Get-ChildItem $usbRoot -ErrorAction SilentlyContinue |
        Where-Object { $_.PSChildName -like 'VID_303A&PID_1001*' }
    foreach ($device in $espressif) {
        foreach ($instance in (Get-ChildItem $device.PSPath -ErrorAction SilentlyContinue)) {
            $name = (Get-ItemProperty (Join-Path $instance.PSPath 'Device Parameters') -ErrorAction SilentlyContinue).PortName
            if ($name -and $present -contains $name) { return $name }
        }
    }
    # Boards with a separate USB-serial chip use other IDs; accept the only USB serial port present.
    $usbPorts = @(Get-CimInstance Win32_PnPEntity -Filter "PNPClass='Ports'" -ErrorAction SilentlyContinue |
        ForEach-Object { if ($_.PNPDeviceID -like 'USB*' -and $_.Name -match '\((COM\d+)\)') { $Matches[1] } })
    if ($usbPorts.Count -eq 1) { return $usbPorts[0] }
    return $null
}

function Send-UsageToMochi {
    if ($null -eq $weekly -or $null -eq $fiveHour) { return }

    $portName = $Port
    if ([string]::IsNullOrWhiteSpace($portName)) { $portName = $env:CLAWD_MOCHI_PORT }
    if ([string]::IsNullOrWhiteSpace($portName)) { $portName = Find-MochiPort }
    if ([string]::IsNullOrWhiteSpace($portName)) { return }

    $weeklyReset = Format-Reset $data.rate_limits.seven_day.resets_at
    $fiveHourReset = Format-Reset $data.rate_limits.five_hour.resets_at
    $message = 'USAGE|{0}|{1}|{2}|{3}' -f [Math]::Round([double]$weekly), [Math]::Round([double]$fiveHour), $weeklyReset, $fiveHourReset

    $serial = [System.IO.Ports.SerialPort]::new($portName, 115200, 'None', 8, 'One')
    try {
        # Keep DTR and RTS low: toggling them can reset the ESP32-C3.
        $serial.DtrEnable = $false
        $serial.RtsEnable = $false
        $serial.WriteTimeout = 500
        $serial.NewLine = "`n"
        $serial.Open()
        $serial.WriteLine($message)
    } catch {
        # Leaving the status line functional is more important than surfacing a
        # transient USB error when the Mochi is unplugged or busy.
    } finally {
        if ($serial.IsOpen) { $serial.Close() }
        $serial.Dispose()
    }
}

Send-UsageToMochi

if ($Quiet) { exit 0 }
if ($null -ne $weekly -and $null -ne $fiveHour) {
    Write-Output ('[{0}] 5h {1}% | week {2}%' -f $model, [Math]::Round([double]$fiveHour), [Math]::Round([double]$weekly))
} else {
    Write-Output ('[{0}] usage pending' -f $model)
}
