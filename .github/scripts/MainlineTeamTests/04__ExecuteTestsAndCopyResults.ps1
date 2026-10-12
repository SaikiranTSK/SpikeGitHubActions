# Jenkins stage 'Execute Tests and Copy Results'.
# Hooks.ini update, then per job: refresh, (RestoreMain ini), execute, 9999 -> ResetNidaq + stop, copy results, kill tasks.
# The Hooks.ini reset runs in the workflow's post step (also after failure / cancel).
. "$PSScriptRoot\Common.ps1"

if ($env:SKIP_HOOKS_INI -ne 'true') {
    $value = "$env:TEST_END_TIME".Trim()
    if ($value) { Write-Host "Updating Hooks.ini: $value" } else { Write-Host 'TEST_END_TIME empty -> clearing value in Hooks.ini' }
    Set-HooksTestEndDateTime $value
}

$endTime = $null
if ("$env:TEST_END_TIME".Trim()) {
    $endTime = [datetime]::ParseExact($env:TEST_END_TIME.Trim(), 'yyyy-MM-dd HH:mm', [Globalization.CultureInfo]::InvariantCulture)
    Write-Host "Execution End Time: $endTime"
}

if ($env:RUN_ALL_JOBS -eq 'true') {
    $jobsToRun = @($env:ALL_JOBS.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
} else {
    $jobsToRun = @($env:JOB_NAME)
}
Write-Host "Jobs selected for execution: $($jobsToRun -join ', ')"

Add-Summary ''
Add-Summary '| Job | Test exit code | Copy results | Duration | Result |'
Add-Summary '|---|---|---|---|---|'

foreach ($job in $jobsToRun) {
    if ($job -notmatch '^[A-Za-z0-9_\-]+$') { throw "Invalid job name '$job'." }
    if ($null -ne $endTime -and (Get-Date) -gt $endTime) {
        Write-Host "Skipping $job - End time reached"
        Add-Summary "| $job | - | - | - | skipped (end time) |"
        break
    }
    $start = Get-Date
    $testCode = '-'; $copyCode = '-'; $result = 'failed'
    Write-Host "::group::Running job: $job"
    try {
        Invoke-Batch "Refresh Environment - $job" "`"$DataPath\GenericApproach\copy_nunit_specflow.cmd`"" | Out-Null

        if ($job -eq 'RestoreMain') {
            Write-Host 'RestoreMain selected. Validating restore parameters before updating Installation.ini'
            $skip = $null
            if (-not "$env:RESTORE_NAME".Trim()) { $skip = 'RestoreName is mandatory for RestoreMain execution.' }
            elseif (-not "$env:RESTORE_FROM_LOCATION".Trim()) { $skip = 'RestoreFromLocation is mandatory for RestoreMain execution.' }
            elseif (-not (Test-Path -LiteralPath $InstallationIni)) { $skip = 'Installation.ini file not found.' }
            if ($skip) {
                Write-Host "$skip Skipping RestoreMain and continuing with remaining jobs."
                $result = 'skipped (restore params)'
                continue
            }
            $content = Get-Content -LiteralPath $InstallationIni
            $content = $content -replace '^RestoreLocationOnSuitePC\s*=.*', "RestoreLocationOnSuitePC = $RestoreLocationOnSuitePC"
            $content = $content -replace '^RestoreFromLocation\s*=.*', "RestoreFromLocation = $env:RESTORE_FROM_LOCATION"
            $content = $content -replace '^RestoreName\s*=.*', "RestoreName = $env:RESTORE_NAME"
            Set-Content -LiteralPath $InstallationIni -Value $content
            Write-Host 'Restore parameters updated successfully'
        }

        $testCode = Invoke-Batch "Execute Tests - $job" "`"$DataPath\GenericApproach\execute_test_batch_jenkins.cmd`" $job `"$env:TEST_CATEGORIES`"" -DetectRunAsCurrentUserAbort
        if ($testCode -eq 9999) {
            Write-Host 'Abort detected. Running ResetNidaq...'
            $resetCode = Invoke-Batch 'Reset Logic' "`"$DataPath\GenericApproach\execute_test_batch_jenkins.cmd`" ResetNidaq"
            if ($resetCode -ne 0) { Write-Host "::error::ResetNidaq failed with exit code $resetCode" }
            $result = 'aborted (9999)'
            throw "Pipeline stopped due to abort in $job"
        }
        if ($testCode -ne 0) { Write-Host "::warning::Test batch $job returned $testCode (ignored, as in Jenkins)." }

        $copyCode = Invoke-Batch "Copy Results to nightbatch- $job" "`"$DataPath\GenericApproach\copy_results_to_nightbatch_jenkins.cmd`" $job"
        if ($copyCode -ne 0) { throw "Copy Results to nightbatch failed for $job with exit code $copyCode." }
        $result = 'done'
    }
    finally {
        Stop-TestTasks
        Write-Host '::endgroup::'
        $duration = '{0:hh\:mm\:ss}' -f ((Get-Date) - $start)
        Add-Summary "| $job | $testCode | $copyCode | $duration | $result |"
    }
}
exit 0
