# Jenkins stage 'Copy tools from repository' (returnStatus: true -> never fails).
. "$PSScriptRoot\Common.ps1"
$workspace = if ($env:GITHUB_WORKSPACE) { $env:GITHUB_WORKSPACE } else { (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path }

Write-Host 'Starting copy...'
foreach ($pair in @(@("$workspace\.github\Tools", "$DataPath\Tools"), @("$workspace\.github\GenericApproach", "$DataPath\GenericApproach"))) {
    & robocopy.exe $pair[0] $pair[1] /E /XO /FFT /MT:8 /R:3 /W:5 /NP /NFL /NDL | Out-Host
    $rc = $LASTEXITCODE
    Write-Host "robocopy $($pair[0]) -> $($pair[1]) exit code $rc"
    if ($rc -ge 8) { Write-Host "::warning::robocopy to $($pair[1]) returned $rc (ignored, as in Jenkins)." }
}
exit 0
