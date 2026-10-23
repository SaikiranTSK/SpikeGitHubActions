# Shared helpers for the TestStarterDevelopment (family D) stage scripts (dot-sourced).
# Inputs come from the job-level env of .github\workflows\TestStarterDevelopment.yml.
$ErrorActionPreference = 'Stop'

# Always load the repository's PowerShell stages implementation.
. "$PSScriptRoot\..\Shared\TestStarterDevelopmentStages.ps1"

# PrintStageHeader() of the TestStarterDevelopment Jenkinsfile
function PrintStageHeader([string] $headerName) {
    $stageData = "# STAGE $headerName".PadRight(119) + '#'
    Write-Host ('#' * 120)
    Write-Host $stageData
    Write-Host ('#' * 120)
}

# CopyFile() of the TestStarterDevelopment Jenkinsfile: reads the file on the server (share), writes it on the node.
function CopyFile([string] $serverPath, [string] $clientPath) {
    Write-Host "Copy from server '$serverPath' to client '$clientPath'."
    if (-not $env:RUNNER_NAME) {
        throw "envvar 'NODE_NAME' is not set, probably not inside an node {} or running an older version of Jenkins!"
    }
    $data = [IO.File]::ReadAllBytes($serverPath)
    $dir = Split-Path -Parent $clientPath
    if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [IO.File]::WriteAllBytes($clientPath, $data)
}
