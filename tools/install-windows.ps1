<#
Installs the Clawd Mochi Claude Code status-line bridge for the current Windows user.
Usage: powershell -ExecutionPolicy Bypass -File .\tools\install-windows.ps1 [-Port COM3] [-Force]
#>
param(
    [string]$Port,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

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
    throw 'Claude Code already has a statusLine. No settings were changed. To keep it, ask Claude Code to follow SETUP.md, which adds Mochi to the existing status line. To replace it, run again with -Force; a dated backup will be made first.'
}

if (Test-Path $settingsPath) {
    $backupPath = "$settingsPath.before-clawd-mochi-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item $settingsPath $backupPath
    Write-Output "Backed up existing settings to $backupPath"
}

# Claude Code runs status lines through Git Bash when it is installed, which
# strips backslashes, so the path uses forward slashes and no PowerShell syntax.
$command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$($bridgePath.Replace('\', '/'))`""
if (-not [string]::IsNullOrWhiteSpace($Port)) {
    $command = "$command -Port $Port"
}
$statusLine = [PSCustomObject]@{
    type = 'command'
    command = $command
    refreshInterval = 30
}
$settings | Add-Member -NotePropertyName statusLine -NotePropertyValue $statusLine -Force

# Windows PowerShell 5.1 can serialize arrays as {"value":[...],"Count":n}
# unless this type data is removed, which would corrupt other settings.
Remove-TypeData System.Array -ErrorAction SilentlyContinue
$json = $settings | ConvertTo-Json -Depth 50
$null = $json | ConvertFrom-Json
# Set-Content -Encoding UTF8 adds a byte order mark in PowerShell 5.1; write without one.
[System.IO.File]::WriteAllText($settingsPath, $json, [System.Text.UTF8Encoding]::new($false))
Copy-Item (Join-Path $PSScriptRoot 'claude-mochi-statusline.ps1') $bridgePath -Force

Write-Output 'Clawd Mochi is connected to Claude Code for this Windows user.'
Write-Output 'Restart Claude Code and send one prompt; the usage screen appears right after the response.'
