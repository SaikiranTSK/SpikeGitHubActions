# Jenkins: the script {} block before the pipeline (echo of the parameters, description) + stage 'Prepare Node'.
# The node check of the script block ("Specified node ... not available") is job check-runner.
. "$PSScriptRoot\Common.ps1"

function Show([string] $Value) { if ($null -eq $Value -or $Value -eq '') { 'null' } else { $Value } }
Write-Host "TestSystem: $env:SYSTEM_NAME"
Write-Host "GroovyScriptFile: $(Show $env:GROOVY_SCRIPT_FILE)"
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
CopyFile ($TSDJenkinsBatchesPath + 'Tools\RunAsCurrentUser.exe') ($TSDDataPath + 'Tools\RunAsCurrentUser.exe')
CopyFile ($TSDJenkinsBatchesPath + 'Tools\RunInCurrentUser.exe') ($TSDDataPath + 'Tools\RunInCurrentUser.exe')
CopyFile ($TSDJenkinsBatchesPath + "Batches\TestStarterDevelopment\$env:GROOVY_SCRIPT_FILE") ($TSDDataPath + "Batches\TestStarterDevelopment\$env:GROOVY_SCRIPT_FILE")
Write-Host "Loading groovy file: $($TSDDataPath)Batches\TestStarterDevelopment\$env:GROOVY_SCRIPT_FILE"
if ($SupportedGroovyScriptFiles -notcontains $env:GROOVY_SCRIPT_FILE) {
    throw "GroovyScriptFile '$env:GROOVY_SCRIPT_FILE' has no PowerShell version (supported: $($SupportedGroovyScriptFiles -join ', '))."
}
# loadedStages.TriggerStagePipeline() -> next steps 'Prepare Environment' and 'Execute Tests'
$global:LASTEXITCODE = 0
exit 0