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
