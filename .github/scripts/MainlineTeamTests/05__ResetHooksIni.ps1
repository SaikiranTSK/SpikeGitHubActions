# Jenkins: "RESET TestEndDateTime BEFORE LOCK RELEASE". Runs as a post step, also after failure or cancel.
. "$PSScriptRoot\Common.ps1"
Write-Host 'Resetting TestEndDateTime in Hooks.ini'
Set-HooksTestEndDateTime ''
exit 0
