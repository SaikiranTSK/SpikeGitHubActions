# Jenkins stage 'Prepare Environment': Killing Tasks + wait 5 s, then Install FAST unless UseInstalledPDC.
# Both bat calls had returnStatus: true -> exit codes are logged, never fail the stage.
. "$PSScriptRoot\Common.ps1"

Stop-TestTasks
Start-Sleep -Seconds 5

if ($env:USE_INSTALLED_PDC -eq 'true') {
    Write-Host 'Skipping FAST installation because UseInstalledPDC is checked.'
} else {
    if ($env:BRANCH -notmatch '^[A-Za-z0-9._\-]+$') { throw "Invalid Branch '$env:BRANCH'." }
    $rc = Invoke-Batch 'Install FAST' "`"$GenericApproachPath\install_fast_jenkins.cmd`" $env:BRANCH"
    if ($rc -ne 0) { Write-Host "::warning::Install FAST returned $rc (ignored, as in Jenkins)." }
}
exit 0
