# Jenkins stage 'Prepare Environment': Killing Tasks + wait 5 s, then Install FAST unless UseInstalledPDC.
# Both bat calls had returnStatus: true -> exit codes are logged, never fail the stage.
. "$PSScriptRoot\Common.ps1"

Stop-TestTasks
Start-Sleep -Seconds 5

if ($env:USE_INSTALLED_PDC -eq 'true') {
    Write-Host 'Skipping FAST installation because UseInstalledPDC is checked.'
} else {
    if (-not "$env:FAST_MSI_PATH".Trim()) { throw 'FastMsiPath is required when UseInstalledPDC is false.' }
    if (-not (Test-LocalRunnerPath $env:FAST_MSI_PATH)) {
        throw 'FastMsiPath must be on a local runner drive; network shares and mapped network drives are not supported.'
    }
    if (-not (Test-Path -LiteralPath $env:FAST_MSI_PATH -PathType Leaf)) {
        throw "FAST MSI not found at FastMsiPath '$env:FAST_MSI_PATH'."
    }
    if ($env:FAST_MSI_SHA256 -notmatch '^[A-Fa-f0-9]{64}$') {
        throw 'FastMsiSha256 must be a 64-character SHA-256 checksum when UseInstalledPDC is false.'
    }
    $actualHash = (Get-FileHash -LiteralPath $env:FAST_MSI_PATH -Algorithm SHA256).Hash
    if (-not [string]::Equals($actualHash, $env:FAST_MSI_SHA256, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "FAST MSI checksum mismatch for '$env:FAST_MSI_PATH'."
    }
    New-Item -ItemType Directory -Path 'C:\Temp\FAST' -Force | Out-Null
    Copy-Item -LiteralPath $env:FAST_MSI_PATH -Destination 'C:\Temp\FAST\FAST.msi' -Force
    $rc = Invoke-Batch 'Install FAST' "`"$DataPath\GenericApproach\install_fast_jenkins.cmd`""
    if ($rc -ne 0) { throw "Install FAST failed with exit code $rc." }
}
exit 0
