<# Sends sample percentages to validate a flashed Mochi without Claude Code. #>
param(
    [int]$Weekly = 22,
    [int]$FiveHour = 5,
    [string]$Port
)

# Same detection as the status-line bridge: Espressif USB ID first, then the only USB serial port.
function Find-MochiPort {
    $present = [System.IO.Ports.SerialPort]::GetPortNames()
    $espressif = Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Enum\USB' -ErrorAction SilentlyContinue |
        Where-Object { $_.PSChildName -like 'VID_303A&PID_1001*' }
    foreach ($device in $espressif) {
        foreach ($instance in (Get-ChildItem $device.PSPath -ErrorAction SilentlyContinue)) {
            $name = (Get-ItemProperty (Join-Path $instance.PSPath 'Device Parameters') -ErrorAction SilentlyContinue).PortName
            if ($name -and $present -contains $name) { return $name }
        }
    }
    $usbPorts = @(Get-CimInstance Win32_PnPEntity -Filter "PNPClass='Ports'" -ErrorAction SilentlyContinue |
        ForEach-Object { if ($_.PNPDeviceID -like 'USB*' -and $_.Name -match '\((COM\d+)\)') { $Matches[1] } })
    if ($usbPorts.Count -eq 1) { return $usbPorts[0] }
    return $null
}

if ([string]::IsNullOrWhiteSpace($Port)) { $Port = $env:CLAWD_MOCHI_PORT }
if ([string]::IsNullOrWhiteSpace($Port)) { $Port = Find-MochiPort }
if ([string]::IsNullOrWhiteSpace($Port)) {
    throw 'No Mochi serial port found. Connect it with a data USB-C cable, or run with -Port COM3.'
}

$serial = [System.IO.Ports.SerialPort]::new($Port, 115200, 'None', 8, 'One')
try {
    $serial.DtrEnable = $false
    $serial.RtsEnable = $false
    $serial.WriteTimeout = 500
    $serial.NewLine = "`n"
    $serial.Open()
    $serial.WriteLine("USAGE|$Weekly|$FiveHour|Weekly reset|5h reset")
    Write-Output "Sent test usage to ${Port}: week $Weekly%, 5h $FiveHour%."
} finally {
    if ($serial.IsOpen) { $serial.Close() }
    $serial.Dispose()
}
