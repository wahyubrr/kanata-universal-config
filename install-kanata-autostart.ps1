param([switch]$CheckOnly)

$ErrorActionPreference = 'Stop'

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
if (-not $CheckOnly -and -not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Run this installer from PowerShell as administrator.'
}

$installDirectory = (Get-Location).ProviderPath
$startupDirectory = [Environment]::GetFolderPath('CommonStartup')
$files = @('kanata_windows_gui_winIOv2_x64.exe', 'graphite-universal.kbd')
foreach ($file in $files) {
    if (-not (Test-Path -LiteralPath (Join-Path $installDirectory $file) -PathType Leaf)) {
        throw "Missing source file: $file"
    }
}

$escapedDirectory = $installDirectory.Replace('"', '""')
$launcher = @"
Set shell = CreateObject("WScript.Shell")
shell.Environment("PROCESS")("KANATA_PLATFORM") = "windows"
shell.CurrentDirectory = "$escapedDirectory"
shell.Run """$escapedDirectory\kanata_windows_gui_winIOv2_x64.exe"" --cfg ""$escapedDirectory\graphite-universal.kbd""", 0, False
"@
$launcherPath = Join-Path $startupDirectory 'Kanata.vbs'
if ($CheckOnly) {
    Write-Output $launcher
    return
}
Set-Content -LiteralPath $launcherPath -Value $launcher -Encoding Unicode
Write-Host "Kanata will run directly from $installDirectory"
Write-Host "All-users login launcher: $launcherPath"
Write-Host 'Kanata will start in each user session at the next login.'
