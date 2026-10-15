# Jenkins: abort during stage 'Execute Tests' -> the rest of the loop body still runs (see StartStage_ExecuteTestsAfterCancel).
. "$PSScriptRoot\Common.ps1"
StartStage_ExecuteTestsAfterCancel
$global:LASTEXITCODE = 0
exit 0
