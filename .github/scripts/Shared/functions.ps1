# PowerShell version of Jenkins\Tools\functions.groovy.
# Jenkins:  def defaultmethods = load "Tools/functions.groovy"; defaultmethods.CheckRunningOnNode()
# GHA:      . "$PSScriptRoot\..\Shared\functions.ps1";               CheckRunningOnNode
# Same method names, parameters and behaviour. Jenkins-only parts:
#   currentBuild.displayName -> heading in the job summary (the run name itself is set by run-name: in the workflow)
#   stage(...)               -> ::group:: block in the step log (steps cannot be created at run time)
#   error(...)               -> throw (stops the step red, like error stops the stage)
#   build job: 'OtherTest'   -> OtherTest only runs CheckRunningOnNode + StartTestBatch on the same SystemName, so it runs inline
# Inputs from env: SYSTEM_NAME (SystemName), RUN_JOB (RunJob), RUNNER_NAME (NODE_NAME).
# GITHUB_WORKSPACE takes priority; DATA_PATH is an optional local execution override.

$RepositoryPath = if ($env:GITHUB_WORKSPACE) {
    $env:GITHUB_WORKSPACE
} else {
    (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
}
$FunctionsDataPath = if (-not $env:GITHUB_WORKSPACE -and $env:DATA_PATH) { $env:DATA_PATH } else { $RepositoryPath }

# Jenkins 'bat' step: runs the command line as given, returns the exit code.
function Invoke-Bat([string] $Label, [string] $Script) {
    Write-Host "[$Label] $Script"
    $env:FUNCTIONS_BAT = $Script
    cmd.exe /d /s /c --% "%FUNCTIONS_BAT%" | Out-Host
    $rc = $LASTEXITCODE
    $global:LASTEXITCODE = 0
    return $rc
}

function Write-FunctionsSummary([string] $Line) {
    if ($env:GITHUB_STEP_SUMMARY) { $Line | Out-File -FilePath $env:GITHUB_STEP_SUMMARY -Append -Encoding utf8 }
}

function CheckRunningOnNode([switch] $WithRunJob) {
    $nodeName = $env:RUNNER_NAME
    $systemName = $env:SYSTEM_NAME
    if (($nodeName -eq $systemName) -and ($nodeName -ne 'master')) {
        Write-Host "Running on Agent: $systemName"
        # catchError(SUCCESS, SUCCESS) { bat 'hostname' }
        [void](Invoke-Bat 'hostname' 'hostname')
    } else {
        Write-Host "::error::This test cannot run on the master! (runner '$nodeName', SystemName '$systemName')"
        throw 'This test cannot run on the master!'
    }
    # currentBuild.displayName
    $displayName = if ($WithRunJob) { "$systemName\$env:RUN_JOB" } else { $systemName }
    Write-Host "Build name: $displayName"
    if (-not $global:FunctionsDisplayNameWritten) {
        Write-FunctionsSummary "### $displayName"
        $global:FunctionsDisplayNameWritten = $true
    }
}

function KillTasks {
    # each taskkill in catchError(SUCCESS, SUCCESS): exit codes ignored
    [void](Invoke-Bat 'Kill' 'taskkill /IM RunAsCurrentUser.exe /F')
    [void](Invoke-Bat 'Kill' 'taskkill /IM RunInCurrentUser.exe /F')
    [void](Invoke-Bat 'Kill' 'taskkill /IM TAFTafFVAdapterCSExeCOMServer.exe /F')
    [void](Invoke-Bat 'Kill' 'taskkill /IM nunit-agent-x86.exe >nul /F')
}

function TalkText([string] $Text, [int] $Volume = 100) {
    # plain 'bat' (no catchError): a failure fails the build
    $talkPath = Join-Path $FunctionsDataPath 'Tools/Talk.cmd'
    $rc = Invoke-Bat 'RunTest' "`"$talkPath`" `"$Text`" $Volume"
    if ($rc -ne 0) { throw "TalkText failed with exit code $rc." }
}

function StartTestBatch {
    $runJob = $env:RUN_JOB
    Write-Host "::group::stage $env:GITHUB_WORKFLOW ($runJob)"
    try {
        $exitCode = -1
        KillTasks
        # catchError(SUCCESS, SUCCESS) { returnStatus }
        $launcherPath = Join-Path $FunctionsDataPath 'Tools/RunAsCurrentUser.exe'
        $batchPath = Join-Path $FunctionsDataPath $runJob
        $exitCode = Invoke-Bat 'RunTest' "`"$launcherPath`" `"$batchPath`" `"$runJob`""
        Write-Host "RunTest exit code: $exitCode"
        if ($exitCode -eq 9999) {
            TalkText 'Job stopped by user'
            Write-Host '::warning::currentBuild.result = ABORTED (exit code 9999)'
        }
        if ($exitCode -ne 0) { throw 'Job Failed' }
    } finally {
        Write-Host '::endgroup::'
    }
}

# Jenkins: CheckRunningOnNode() + build job: 'OtherTest' (SystemName, RunJob = <batchFolderName>\<batchFileNameFull>)
# inside catchError(buildResult, stageResult). Returns 'SUCCESS' or 'FAILURE'; the caller (StartTestsFromBatch) acts on it.
function StartJob([string] $BatchFileName, [string] $JobPipelineName, [string] $SystemName, [string] $BatchFolderName,
                  [string] $BatchFileNameFull, [string] $BuildResult, [string] $StageResult) {
    TalkText "$BatchFileName has been started" 100
    $result = $null
    $savedRunJob = $env:RUN_JOB
    $savedSystem = $env:SYSTEM_NAME
    try {
        CheckRunningOnNode
        $env:SYSTEM_NAME = $SystemName
        $env:RUN_JOB = "$BatchFolderName\$BatchFileNameFull"
        Write-Host "build job: $JobPipelineName (SystemName=$SystemName, RunJob=$env:RUN_JOB), run inline on this runner"
        # OtherTest: node(SystemName) { CheckRunningOnNode(); StartTestBatch() }
        CheckRunningOnNode
        StartTestBatch
        $result = 'SUCCESS'
    } catch {
        Write-Host "::warning::$BatchFileName : $($_.Exception.Message) (catchError buildResult=$BuildResult, stageResult=$StageResult)"
        $result = 'FAILURE'
    } finally {
        $env:RUN_JOB = $savedRunJob
        $env:SYSTEM_NAME = $savedSystem
    }
    TalkText "$BatchFileName has been completed with $result" 100
    return $result
}

function StartTestsFromBatch([string] $BatchfilesPath, [string] $SystemName, [string] $BatchFolderName) {
    $skipOnPass = $true
    $anyFail = $false

    # @dir /b /o:N /a:-D "<path>\*.cmd"
    Write-Host "Command to find all batchfiles: @dir /b /o:N /a:-D `"$BatchfilesPath\*.cmd`" 2>nul"
    $files = @(Get-ChildItem -LiteralPath $BatchfilesPath -Filter '*.cmd' -File -ErrorAction SilentlyContinue |
        Sort-Object Name | ForEach-Object Name)
    if ($files.Count -eq 0) { throw "No batch files found in $BatchfilesPath." }

    Write-Host 'Found batch files:'
    $files | ForEach-Object { Write-Host $_ }

    foreach ($batchFileNameFull in $files) {
        Write-Host $batchFileNameFull
        KillTasks
        $filePart = $batchFileNameFull.Replace('.cmd', '') -split '__'
        $batchFileNumber = $filePart[0]
        $batchFileName = $filePart[1]
        $param = 'SOF'
        if ($filePart.Count -ge 3) { $param = $filePart[2] }

        Write-Host "::group::stage $batchFileName"
        Write-Host "Running test $($batchFileNumber): $batchFileName"
        $jobPipelineName = 'OtherTest'
        $e2e = $null
        switch ($param) {
            'COF' {
                Write-Host 'Continue on fail'
                $e2e = StartJob $batchFileName $jobPipelineName $SystemName $BatchFolderName $batchFileNameFull 'SUCCESS' 'FAILURE'
                if ($e2e -eq 'FAILURE') { $skipOnPass = $false; $anyFail = $true }
            }
            'POF' {
                Write-Host 'Pass on fail'
                $e2e = StartJob $batchFileName $jobPipelineName $SystemName $BatchFolderName $batchFileNameFull 'SUCCESS' 'SUCCESS'
                if ($e2e -eq 'FAILURE') { $anyFail = $true }
            }
            'SOP' {
                Write-Host 'Skip on Pass'
                if ($skipOnPass -eq $false) {
                    $e2e = StartJob $batchFileName $jobPipelineName $SystemName $BatchFolderName $batchFileNameFull 'SUCCESS' 'FAILURE'
                    if ($e2e -eq 'FAILURE') { $anyFail = $true }
                } else {
                    TalkText "$batchFileName has been skipped" 100
                    Write-Host "::notice::Stage $batchFileName skipped"
                }
            }
            default {
                Write-Host 'Stop on Fail (default)'
                $e2e = StartJob $batchFileName $jobPipelineName $SystemName $BatchFolderName $batchFileNameFull 'FAILURE' 'FAILURE'
                Write-Host $e2e
                if ($e2e -eq 'FAILURE') { $anyFail = $true }
            }
        }
        Write-FunctionsSummary "| $batchFileName ($param) | $(if ($e2e) { $e2e } else { 'SKIPPED' }) |"
        Write-Host '::endgroup::'
        if (($e2e -eq 'FAILURE') -and ($param -eq 'SOF')) { throw 'Batch failed.' }
    }
    if ($anyFail) { throw 'Batch failed.' }
}
