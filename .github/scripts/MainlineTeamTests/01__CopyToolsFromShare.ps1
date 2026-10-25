# Compatibility entry point only; the workflow fetches .github directly into GITHUB_WORKSPACE.
. "$PSScriptRoot\Common.ps1"
Write-Host "No tooling copy required. Using $ToolsPath and $GenericApproachPath directly."
exit 0
