# Jenkins: the script {} block before the pipeline (echo of the parameters, description) + stage 'Prepare Node'.
# The node check of the script block ("Specified node ... not available") is job check-runner.
. "$PSScriptRoot\Common.ps1"

function Show([string] $Value) { if ($null -eq $Value -or $Value -eq '') { 'null' } else { $Value } }
Write-Host "TestSystem: $env:SYSTEM_NAME"
# The Jenkinsfile prints env.TestLocation (not TestsLocation), which does not exist
Write-Host 'TestLocation: null'
Write-Host "TestLibrary: $(Show $env:TEST_LIBRARY)"
Write-Host "TestParameters: $(Show $env:TEST_PARAMETERS)"
Write-Host "AssignedId: $(Show $env:ASSIGNED_ID)"
Write-Host "SaveLocation: $(Show $env:SAVE_LOCATION)"
Write-Host "SaveScreenshotsAndVideosToLocation: $(Show $env:SAVE_SCREENSHOTS_AND_VIDEOS_TO_LOCATION)"
Write-Host "Loops: $(Show $env:LOOPS)"
Write-FunctionsSummary "### $env:SYSTEM_NAME"
Write-FunctionsSummary "$(Get-TsdDescription)"
Write-FunctionsSummary ''
Write-FunctionsSummary '| Item | Value |'
Write-FunctionsSummary '|---|---|'

PrintStageHeader 'PREPARE NODE'
# catchError(SUCCESS, SUCCESS) around each taskkill
[void](Invoke-Bat 'Kill' 'taskkill /F /IM RunAsCurrentUser.exe')
[void](Invoke-Bat 'Kill' 'taskkill /F /IM RunInCurrentUser.exe')
foreach ($tool in @(
    "$TSDToolsPath\RunAsCurrentUser.exe",
    "$TSDToolsPath\RunInCurrentUser.exe",
    "$TSDPackagesPath\NUnit 2.6.2\bin\nunit-console-x86.exe",
    "$TSDPackagesPath\NUnit.org\nunit-console\nunit3-console.exe"
)) {
    if (-not (Test-Path -LiteralPath $tool -PathType Leaf)) {
        throw "Required checked-out tooling is missing: $tool"
    }
}
# loadedStages.TriggerStagePipeline() -> next steps 'Prepare Environment' and 'Execute Tests'
$global:LASTEXITCODE = 0
exit 0
