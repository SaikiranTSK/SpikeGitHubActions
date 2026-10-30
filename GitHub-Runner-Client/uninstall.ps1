<#
.SYNOPSIS
    Removes the GitHub Actions runner service from a side PC and unregisters it from GitHub.

.EXAMPLE
    .\uninstall.ps1 -Token <removal token>
#>
param(
    # Removal token from GitHub: Settings > Actions > Runners > <runner> > ... > Remove
    [Parameter(Mandatory)] [string] $Token,
    [string] $InstallDir = 'C:\actions-runner'
)

$ErrorActionPreference = 'Stop'

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Run this script from an administrator PowerShell / command prompt.'
}

if (-not (Test-Path -LiteralPath (Join-Path $InstallDir 'config.cmd'))) {
    throw "No runner found in $InstallDir."
}

Push-Location $InstallDir
try {
    # Stops and deletes the Windows service, then unregisters the runner from GitHub.
    & .\config.cmd remove --token $Token
    if ($LASTEXITCODE -ne 0) { throw "config.cmd remove failed with exit code $LASTEXITCODE" }
}
finally {
    Pop-Location
}

Write-Host "Runner removed. You can now delete $InstallDir."
