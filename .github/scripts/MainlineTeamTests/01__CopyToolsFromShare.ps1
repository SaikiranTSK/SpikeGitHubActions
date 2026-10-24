# Stage the repository-owned MainlineTeamTests runtime files on the runner.
. "$PSScriptRoot\Common.ps1"

$repositoryGitHub = Join-Path $env:GITHUB_WORKSPACE '.github'
$toolsSource = Join-Path $repositoryGitHub 'Tools'
$genericApproachSource = Join-Path $repositoryGitHub 'GenericApproach'
$packagesSource = Join-Path $repositoryGitHub 'Packages\SpecFlow.2.3.2'

$requiredFiles = @(
    (Join-Path $toolsSource 'RunAsCurrentUser.exe'),
    (Join-Path $toolsSource 'UninstallInstallJenkins.cmd'),
    (Join-Path $genericApproachSource 'copy_nunit_specflow.cmd'),
    (Join-Path $genericApproachSource 'execute_test_batch_jenkins.cmd'),
    (Join-Path $genericApproachSource 'execute_test_batch_side_pc.cmd'),
    (Join-Path $genericApproachSource 'collect_mainline_results_jenkins.cmd'),
    (Join-Path $genericApproachSource 'collect_mainline_results_side_pc.cmd'),
    (Join-Path $genericApproachSource 'install_fast_jenkins.cmd'),
    (Join-Path $genericApproachSource 'install_fast_side_pc.cmd'),
    (Join-Path $packagesSource 'TechTalk.SpecFlow.dll')
)

$missingFiles = @($requiredFiles | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) })
if ($missingFiles.Count -gt 0) {
    throw "Repository-owned MainlineTeamTests files are missing: $($missingFiles -join ', ')"
}

New-Item -ItemType Directory -Path "$DataPath\Tools" -Force | Out-Null
New-Item -ItemType Directory -Path "$DataPath\GenericApproach" -Force | Out-Null
New-Item -ItemType Directory -Path "$DataPath\Packages" -Force | Out-Null

& robocopy.exe $toolsSource "$DataPath\Tools" /E /IS /IT /R:2 /W:2 /NP /NFL /NDL | Out-Host
if ($LASTEXITCODE -ge 8) { throw "Failed to stage repository tools: robocopy exit code $LASTEXITCODE" }

$genericApproachFiles = @(
    'copy_nunit_specflow.cmd',
    'execute_test_batch_jenkins.cmd',
    'execute_test_batch_side_pc.cmd',
    'collect_mainline_results_jenkins.cmd',
    'collect_mainline_results_side_pc.cmd',
    'install_fast_jenkins.cmd',
    'install_fast_side_pc.cmd'
)
foreach ($file in $genericApproachFiles) {
    Copy-Item -LiteralPath (Join-Path $genericApproachSource $file) `
        -Destination (Join-Path "$DataPath\GenericApproach" $file) -Force
}

& robocopy.exe $packagesSource "$DataPath\Packages\SpecFlow.2.3.2" /E /IS /IT /R:2 /W:2 /NP /NFL /NDL | Out-Host
if ($LASTEXITCODE -ge 8) { throw "Failed to stage repository SpecFlow package: robocopy exit code $LASTEXITCODE" }

$resultsRoot = Join-Path $env:RUNNER_TEMP 'MainlineTeamTests\results'
if (Test-Path -LiteralPath $resultsRoot) {
    Remove-Item -LiteralPath $resultsRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $resultsRoot -Force | Out-Null

Write-Host "MainlineTeamTests tools staged from $repositoryGitHub."
Write-Host "Per-run test results will be collected under $resultsRoot."
exit 0
