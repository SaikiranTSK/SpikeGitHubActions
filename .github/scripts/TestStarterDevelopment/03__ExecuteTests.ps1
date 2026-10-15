# Jenkins: stage 'Execute Tests' (StartStage_ExecuteTests of TestStarterDevelopmentStages.groovy):
# per loop StartTest, RunResetTest, CopyResultsToNightbatch, UploadToELK, then 'Killing Tasks'.
. "$PSScriptRoot\Common.ps1"
StartStage_ExecuteTests
$global:LASTEXITCODE = 0
exit 0