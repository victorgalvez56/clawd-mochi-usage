<#
Installs the Clawd Mochi Claude Code status-line bridge for the current Windows user.
Usage: powershell -ExecutionPolicy Bypass -File .\tools\install-windows.ps1 [-Port COM3] [-Force]
#>
param(
    [string]$Port,
    [switch]$Force
)

$claudeDir = Join-Path $env:USERPROFILE '.claude'
$settingsPath = Join-Path $claudeDir 'settings.json'
$bridgePath = Join-Path $claudeDir 'clawd-mochi-statusline.ps1'

New-Item -ItemType Directory -Force -Path $claudeDir | Out-Null

$settings = [PSCustomObject]@{}
if (Test-Path $settingsPath) {
    try {
        $settings = Get-Content -Raw $settingsPath | ConvertFrom-Json
    } catch {
        throw "Cannot read valid JSON from $settingsPath. Fix it before installing."
    }
}

if ($null -ne $settings.statusLine -and -not $Force) {
    throw 'Claude Code already has a statusLine. No settings were changed. Run again with -Force to replace it; a dated backup will be made first.'
}

if (Test-Path $settingsPath) {
    $backupPath = "$settingsPath.before-clawd-mochi-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item $settingsPath $backupPath
    Write-Output "Backed up existing settings to $backupPath"
}

$command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$bridgePath`""
if (-not [string]::IsNullOrWhiteSpace($Port)) {
    $command = "`$env:CLAWD_MOCHI_PORT='$Port'; $command"
}
$statusLine = [PSCustomObject]@{
    type = 'command'
    command = $command
    refreshInterval = 30
}
$settings | Add-Member -NotePropertyName statusLine -NotePropertyValue $statusLine -Force
$settings | ConvertTo-Json -Depth 20 | Set-Content -Encoding UTF8 $settingsPath
Copy-Item (Join-Path $PSScriptRoot 'claude-mochi-statusline.ps1') $bridgePath -Force

Write-Output 'Clawd Mochi is connected to Claude Code for this Windows user.'
Write-Output 'Restart Claude Code, send one prompt, and wait up to 30 seconds for the usage screen.'
