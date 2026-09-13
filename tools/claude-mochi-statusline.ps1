# Claude Code status line + Clawd Mochi USB usage bridge for Windows.
# Claude Code writes a session JSON document to stdin. This script forwards only
# the weekly and five-hour rate-limit values to Mochi over USB serial.

$inputText = [Console]::In.ReadToEnd()

try {
    $data = $inputText | ConvertFrom-Json
} catch {
    Write-Output '[Claude] usage pending'
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

function Send-UsageToMochi {
    if ($null -eq $weekly -or $null -eq $fiveHour) { return }

    $portName = $env:CLAWD_MOCHI_PORT
    if ([string]::IsNullOrWhiteSpace($portName)) {
        $portName = Get-CimInstance Win32_SerialPort |
            Where-Object { $_.PNPDeviceID -like 'USB*' } |
            Select-Object -First 1 -ExpandProperty DeviceID
    }
    if ([string]::IsNullOrWhiteSpace($portName)) { return }

    $weeklyReset = Format-Reset $data.rate_limits.seven_day.resets_at
    $fiveHourReset = Format-Reset $data.rate_limits.five_hour.resets_at
    $message = 'USAGE|{0}|{1}|{2}|{3}' -f [Math]::Round([double]$weekly), [Math]::Round([double]$fiveHour), $weeklyReset, $fiveHourReset

    try {
        $serial = [System.IO.Ports.SerialPort]::new($portName, 115200, 'None', 8, 'One')
        $serial.NewLine = "`n"
        $serial.Open()
        $serial.WriteLine($message)
        $serial.Close()
    } catch {
        # Leaving the status line functional is more important than surfacing a
        # transient USB error when the Mochi is unplugged or busy.
    }
}

Send-UsageToMochi

if ($null -ne $weekly -and $null -ne $fiveHour) {
    Write-Output ('[{0}] 5h {1}% · week {2}%' -f $model, [Math]::Round([double]$fiveHour), [Math]::Round([double]$weekly))
} else {
    Write-Output ('[{0}] usage pending' -f $model)
}
