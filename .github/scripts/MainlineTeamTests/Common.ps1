# Shared helpers for the MainlineTeamTests stage scripts (dot-sourced).
$ErrorActionPreference = 'Stop'

# = def defaultmethods = load "D:/Jenkins/Tools/functions.groovy"
. "$PSScriptRoot\..\Shared\functions.ps1"

$DataPath = 'D:\Jenkins'
$HooksIni = 'C:\Program Files (x86)\FAST\Hooks.ini'
$InstallationIni = 'C:\Program Files (x86)\FAST\Installation.ini'
$RestoreLocationOnSuitePC = 'D:\SystemBackups'

# Runs a command line like Jenkins 'bat'. The test wrapper can mask RunAsCurrentUser's 9999 with exit code 0.
function Invoke-Batch([string] $Label, [string] $CommandLine, [switch] $DetectRunAsCurrentUserAbort) {
    Write-Host "### $Label : $CommandLine"
    $env:BATCH_CMD = $CommandLine
    $runAsResult = @{ Code = $null }
    cmd.exe /d /s /c --% "%BATCH_CMD%" | ForEach-Object {
        if ($DetectRunAsCurrentUserAbort -and $_ -match '^\s*\[Info\].*:\s*Result code:\s*([0-9]+)\s*$') {
            $runAsResult.Code = $Matches[1]
        }
        $_
    } | Out-Host
    $rc = $LASTEXITCODE
    if ($DetectRunAsCurrentUserAbort -and $runAsResult.Code -eq '9999' -and $rc -ne 9999) {
        Write-Host "### $Label - RunAsCurrentUser returned 9999; batch wrapper returned $rc."
        $rc = 9999
    }
    Write-Host "### $Label exit code: $rc"
    return $rc
}

# = GetKillingCommands() of the Jenkins script.
function Stop-TestTasks {
    Write-Host 'Killing Tasks.'
    Get-Process -ErrorAction SilentlyContinue |
        Where-Object { $_.ProcessName -like 'nunit*' -or $_.ProcessName -eq 'TAFTafFVAdapterCSExeCOMServer' -or
                       $_.ProcessName -like 'iCapture*' -or $_.ProcessName -like 'testcentric*' } |
        ForEach-Object {
            Write-Host "  stop $($_.ProcessName) ($($_.Id))"
            Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
        }
}

function Set-HooksTestEndDateTime([string] $Value) {
    if (-not (Test-Path -LiteralPath $HooksIni)) {
        Write-Host 'Hooks.ini file not found. Skipping TestEndDateTime update.'
        return
    }
    $content = @(Get-Content -LiteralPath $HooksIni)
    if ($content -match '^TestEndDateTime\s*=') {
        $content -replace '^TestEndDateTime\s*=.*', "TestEndDateTime = $Value".TrimEnd() | Set-Content -LiteralPath $HooksIni
        Write-Host 'TestEndDateTime updated in Hooks.ini.'
    } else {
        Add-Content -LiteralPath $HooksIni "TestEndDateTime = $Value".TrimEnd()
        Write-Host 'TestEndDateTime key was missing, added to Hooks.ini.'
    }
}

function Add-Summary([string] $Line) {
    if ($env:GITHUB_STEP_SUMMARY) { $Line | Out-File -FilePath $env:GITHUB_STEP_SUMMARY -Append -Encoding utf8 }
}
