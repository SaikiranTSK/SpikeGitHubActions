# Shared helpers for the MainlineTeamTests stage scripts (dot-sourced).
$ErrorActionPreference = 'Stop'

# = def defaultmethods = load "D:/Jenkins/Tools/functions.groovy"
. "$PSScriptRoot\..\Shared\functions.ps1"

$DataPath = 'D:\Jenkins'
$HooksIni = 'C:\Program Files (x86)\FAST\Hooks.ini'
$InstallationIni = 'C:\Program Files (x86)\FAST\Installation.ini'
$RestoreLocationOnSuitePC = 'D:\SystemBackups'

# Runs a command line like Jenkins 'bat' (arguments passed as given) and returns its exit code.
function Invoke-Batch([string] $Label, [string] $CommandLine) {
    Write-Host "### $Label : $CommandLine"
    $env:BATCH_CMD = $CommandLine
    cmd.exe /d /s /c --% "%BATCH_CMD%" | Out-Host
    $rc = $LASTEXITCODE
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

# Same text and messages as the Jenkins bat lines: update writes "TestEndDateTime = <value>" (trailing space when
# empty), reset writes "TestEndDateTime =".
function Set-HooksTestEndDateTime([string] $Value, [switch] $Reset) {
    if ($Reset) {
        $line = 'TestEndDateTime ='
        $msgs = 'Hooks.ini file not found. Skipping TestEndDateTime reset.', 'TestEndDateTime reset completed.', 'TestEndDateTime key was missing, added as empty value.'
    } else {
        $line = "TestEndDateTime = $Value"
        $msgs = 'Hooks.ini file not found. Skipping TestEndDateTime update.', 'TestEndDateTime updated in Hooks.ini.', 'TestEndDateTime key was missing, added to Hooks.ini.'
    }
    if (-not (Test-Path -LiteralPath $HooksIni)) {
        Write-Host $msgs[0]
        return
    }
    $content = Get-Content -LiteralPath $HooksIni
    if ($content -match '^TestEndDateTime\s*=') {
        $content -replace '^TestEndDateTime\s*=.*', $line.Replace('$', '$$') | Set-Content -LiteralPath $HooksIni
        Write-Host $msgs[1]
    } else {
        Add-Content -LiteralPath $HooksIni $line
        Write-Host $msgs[2]
    }
}

function Add-Summary([string] $Line) {
    if ($env:GITHUB_STEP_SUMMARY) { $Line | Out-File -FilePath $env:GITHUB_STEP_SUMMARY -Append -Encoding utf8 }
}
