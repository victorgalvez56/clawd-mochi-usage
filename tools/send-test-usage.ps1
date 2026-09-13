<# Sends sample percentages to validate a flashed Mochi without Claude Code. #>
param(
    [int]$Weekly = 22,
    [int]$FiveHour = 5,
    [string]$Port
)

if ([string]::IsNullOrWhiteSpace($Port)) { $Port = $env:CLAWD_MOCHI_PORT }
if ([string]::IsNullOrWhiteSpace($Port)) {
    $Port = Get-CimInstance Win32_SerialPort |
        Where-Object { $_.PNPDeviceID -like 'USB*' } |
        Select-Object -First 1 -ExpandProperty DeviceID
}
if ([string]::IsNullOrWhiteSpace($Port)) {
    throw 'No Mochi serial port found. Connect it, or run with -Port COM3.'
}

$serial = [System.IO.Ports.SerialPort]::new($Port, 115200, 'None', 8, 'One')
try {
    $serial.NewLine = "`n"
    $serial.Open()
    $serial.WriteLine("USAGE|$Weekly|$FiveHour|Weekly reset|5h reset")
    Write-Output "Sent test usage to $Port: week $Weekly%, 5h $FiveHour%."
} finally {
    if ($serial.IsOpen) { $serial.Close() }
    $serial.Dispose()
}
