$ErrorActionPreference = 'Stop'

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Run this installer from PowerShell as administrator.'
}

$installDirectory = Join-Path $env:ProgramData 'Kanata'
$startupDirectory = [Environment]::GetFolderPath('CommonStartup')
$files = @('kanata_windows_gui_winIOv2_x64.exe', 'graphite-universal.kbd')
foreach ($file in $files) {
    if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot $file) -PathType Leaf)) {
        throw "Missing source file: $file"
    }
}

New-Item -ItemType Directory -Path $installDirectory -Force | Out-Null
foreach ($file in $files) {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot $file) -Destination (Join-Path $installDirectory $file) -Force
}

$escapedDirectory = $installDirectory.Replace('"', '""')
$launcher = @"
Set shell = CreateObject("WScript.Shell")
shell.Environment("PROCESS")("KANATA_PLATFORM") = "windows"
shell.CurrentDirectory = "$escapedDirectory"
shell.Run """$escapedDirectory\kanata_windows_gui_winIOv2_x64.exe"" --cfg ""$escapedDirectory\graphite-universal.kbd""", 0, False
"@
$launcherPath = Join-Path $startupDirectory 'Kanata.vbs'
Set-Content -LiteralPath $launcherPath -Value $launcher -Encoding Unicode
Write-Host "Installed Kanata in $installDirectory"
Write-Host "All-users login launcher: $launcherPath"
Write-Host 'Kanata will start in each user session at the next login.'
