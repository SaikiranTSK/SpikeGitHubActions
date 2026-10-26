# Jenkins stage 'Execute Tests and Copy Results'.
# Hooks.ini update, then per job: refresh, (RestoreMain ini), execute, 9999 -> ResetNidaq + stop, copy results, kill tasks.
# After the loop: Hooks.ini reset. As in Jenkins (inside catchError) it is skipped when a job stops the loop.
. "$PSScriptRoot\Common.ps1"

if ($env:SKIP_HOOKS_INI -ne 'true') {
    $value = "$env:TEST_END_TIME"
    if (-not $value.Trim()) {
        Write-Host "TEST_END_TIME empty $([char]0x2192) clearing value in Hooks.ini"
        $value = ''
    } else {
        Write-Host "Updating Hooks.ini: $value"
    }
    Set-HooksTestEndDateTime $value
}

# Jenkins parses TEST_END_TIME and checks "now" in Groovy on the Jenkins server (Amsterdam time, also for BLR PCs),
# and prints the end time as a Java Date ("Mon Oct 12 06:00:00 CEST 2026").
$JenkinsTimeZone = [TimeZoneInfo]::FindSystemTimeZoneById('W. Europe Standard Time')
function Get-JenkinsNow { [TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow, $JenkinsTimeZone) }
$endTime = $null
if ("$env:TEST_END_TIME".Trim()) {
    $inv = [Globalization.CultureInfo]::InvariantCulture
    $endTime = [datetime]::ParseExact($env:TEST_END_TIME.Trim(), 'yyyy-MM-dd HH:mm', $inv)
    $zone = if ($JenkinsTimeZone.IsDaylightSavingTime($endTime)) { 'CEST' } else { 'CET' }
    Write-Host "Execution End Time: $($endTime.ToString('ddd MMM dd HH:mm:ss', $inv)) $zone $($endTime.Year)"
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
    if ($null -ne $endTime -and (Get-JenkinsNow) -gt $endTime) {
        Write-Host "Skipping $job - End time reached"
        Add-Summary "| $job | - | - | - | skipped (end time) |"
        break
    }
    $start = Get-Date
    $testCode = '-'; $copyCode = '-'; $result = 'failed'
    Write-Host '======================================'
    Write-Host "Running job: $job"
    Write-Host '======================================'
    try {
        $refreshCode = Invoke-Batch "Refresh Environment - $job" "`"$GenericApproachPath\copy_nunit_specflow.cmd`""
        if ($refreshCode -ne 0) {
            throw "Refresh Environment failed for $job with exit code $refreshCode."
        }

        if ($job -eq 'RestoreMain') {
            Write-Host 'RestoreMain selected. Validating restore parameters before updating Installation.ini'
            $skip = $null
            if (-not "$env:RESTORE_NAME".Trim()) { $skip = 'RestoreName is mandatory for RestoreMain execution.' }
            elseif (-not "$env:RESTORE_FROM_LOCATION".Trim()) { $skip = 'RestoreFromLocation is mandatory for RestoreMain execution.' }
            elseif (-not (Test-Path -LiteralPath $InstallationIni)) {
                Write-Host 'Installation.ini file not found'
                $skip = 'Failed to update Installation.ini for RestoreMain.'
            }
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

        $testCode = Invoke-Batch "Execute Tests - $job" "`"$GenericApproachPath\execute_test_batch_jenkins.cmd`" $job `"$env:TEST_CATEGORIES`"" -DetectAbort
        if ($testCode -eq 9999) {
            Write-Host 'Abort detected. Running ResetNidaq...'
            $resetCode = Invoke-Batch 'Reset Logic' "`"$GenericApproachPath\execute_test_batch_jenkins.cmd`" ResetNidaq"
            if ($resetCode -ne 0) { Write-Host "::error::ResetNidaq failed with exit code $resetCode" }
            $result = 'aborted (9999)'
            throw "Pipeline stopped due to abort in $job"
        }
        if ($testCode -ne 0) { Write-Host "::warning::Test batch $job returned $testCode (ignored, as in Jenkins)." }

        $copyCode = Invoke-Batch "Copy Results to nightbatch- $job" "`"$GenericApproachPath\copy_results_to_nightbatch_jenkins.cmd`" $job"
        if ($copyCode -ne 0) { throw "Copy Results to nightbatch failed for $job with exit code $copyCode." }
        $result = 'done'
    }
    finally {
        Stop-TestTasks
        $duration = '{0:hh\:mm\:ss}' -f ((Get-Date) - $start)
        Add-Summary "| $job | $testCode | $copyCode | $duration | $result |"
    }
}

if ($env:SKIP_HOOKS_INI -ne 'true') {
    # RESET TestEndDateTime BEFORE LOCK RELEASE
    Write-Host 'Resetting TestEndDateTime in Hooks.ini'
    Set-HooksTestEndDateTime -Reset
}
exit 0
