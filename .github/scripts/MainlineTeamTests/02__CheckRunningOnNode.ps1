# Jenkins stage 'Check running on node': defaultmethods.CheckRunningOnNode() from functions.groovy (Shared\functions.ps1).
. "$PSScriptRoot\Common.ps1"

CheckRunningOnNode
Add-Summary "$env:SYSTEM_NAME\$env:JOB_TITLE. Runner: $env:RUNNER_NAME, machine: $env:COMPUTERNAME"
exit 0
