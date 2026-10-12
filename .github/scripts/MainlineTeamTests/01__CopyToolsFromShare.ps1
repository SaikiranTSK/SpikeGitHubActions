# Jenkins stage 'Copy tools from share' (returnStatus: true -> never fails).
. "$PSScriptRoot\Common.ps1"
$share = if ($env:BATCHES_SHARE) { $env:BATCHES_SHARE } else { '\\nlybstqvp4dt7nv\JenkinsBatches' }

while (-not (Test-Path -LiteralPath $share)) {
    Write-Host 'Checking connection... Server busy... waiting'
    Start-Sleep -Seconds 10
}

Write-Host 'Starting copy...'
foreach ($pair in @(@("$share\Tools", "$DataPath\Tools"), @("$share\Batches\GenericApproach", "$DataPath\GenericApproach"))) {
    & robocopy.exe $pair[0] $pair[1] /E /XO /FFT /MT:8 /R:3 /W:5 /NP /NFL /NDL | Out-Host
    $rc = $LASTEXITCODE
    Write-Host "robocopy $($pair[0]) -> $($pair[1]) exit code $rc"
    if ($rc -ge 8) { Write-Host "::warning::robocopy to $($pair[1]) returned $rc (ignored, as in Jenkins)." }
}
exit 0
