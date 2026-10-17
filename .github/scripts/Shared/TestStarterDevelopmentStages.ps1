# PowerShell version of Jenkins\Batches\TestStarterDevelopment\TestStarterDevelopmentStages.groovy (loaded on the side PC
# from D:\Jenkins\Batches\TestStarterDevelopment\<GroovyScriptFile> by the TestStarterDevelopment job).
# Jenkins:  def loadedStages = load "...\TestStarterDevelopmentStages.groovy"; loadedStages.TriggerStagePipeline()
# GHA:      . "$PSScriptRoot\..\Shared\TestStarterDevelopmentStages.ps1"; StartStage_PrepareEnvironment / StartStage_ExecuteTests
# Same method names, parameters and behaviour. Jenkins-only parts:
#   TriggerStagePipeline()        -> the two stages are two workflow steps ('Prepare Environment', 'Execute Tests')
#   _buildFailed / _buildAborted  -> kept between the steps in GITHUB_ENV (TSD_BUILD_FAILED / TSD_BUILD_ABORTED)
#   currentBuild.currentResult    -> NOT_BUILT only when a catchError in ExecuteCommand caught an error (TSD_NOT_BUILT)
#   currentBuild.description      -> line in the job summary
#   UploadToELK()                 -> _uploadToELK is always false in the groovy file, so only the 'Skip uploading' line runs
# Inputs from env: DATA_PATH (env.DataPath, default D:\Jenkins\), SERVER_DATA_PATH (env.ServerDataPath),
# JENKINS_BATCHES_PATH (env.JenkinsBatchesPath), both default BATCHES_SHARE + '\', RESULT_VIEWER_URL (env.ResultViewerURL),
# SYSTEM_NAME, TESTS_LOCATION, TEST_LIBRARY, TEST_PARAMETERS, ASSIGNED_ID, SAVE_LOCATION, LOOPS,
# SAVE_SCREENSHOTS_AND_VIDEOS_TO_LOCATION.
# TSD_TESTS_FOLDER / TSD_TRACING_FOLDER / TSD_RESULTS_FOLDER only exist for local tests (hard-coded in the groovy file).

if (-not (Get-Command Invoke-Bat -ErrorAction SilentlyContinue)) { . "$PSScriptRoot\functions.ps1" }

function Get-TsdPath([string] $Value, [string] $Default) {
    $p = if ($Value) { $Value } else { $Default }
    if (-not $p.EndsWith('\')) { $p += '\' }
    return $p
}

$TSDDataPath = Get-TsdPath $env:DATA_PATH 'D:\Jenkins\'
$TSDShare = if ($env:BATCHES_SHARE) { $env:BATCHES_SHARE } else { '\\nlybstqvp4dt7nv\JenkinsBatches' }
$TSDServerDataPath = Get-TsdPath $env:SERVER_DATA_PATH $TSDShare
$TSDJenkinsBatchesPath = Get-TsdPath $env:JENKINS_BATCHES_PATH $TSDShare
$TSDResultViewerURL = if ($env:RESULT_VIEWER_URL) { $env:RESULT_VIEWER_URL } else { 'http://igts-resultviewer.ta.philips.com/#/testrun/' }
$TSDTracingFolder = if ($env:TSD_TRACING_FOLDER) { $env:TSD_TRACING_FOLDER } else { 'D:\Collected\Tracing\FAST' }
$TSDResultsFolder = if ($env:TSD_RESULTS_FOLDER) { $env:TSD_RESULTS_FOLDER } else { 'C:\Temp\FAST\Results' }

# @Field
$testLibraryFolder = if ($env:TSD_TESTS_FOLDER) { $env:TSD_TESTS_FOLDER } else { 'C:\Temp\FAST\Tests\' }
# robocopy target of TestsLocation in StartStage_PrepareEnvironment (hard-coded lower case in the groovy file)
$TSDTestsCopyTarget = if ($env:TSD_TESTS_FOLDER) { $env:TSD_TESTS_FOLDER.TrimEnd('\') } else { 'c:\temp\FAST\tests' }
$nunitOutputFolder = "$TSDResultsFolder\TestOutput"

# TriggerStagePipeline(): _buildFailed = false; _uploadToELK = false; _buildAborted = false; _pdc = "0.0.0"
$global:_buildFailed = ($env:TSD_BUILD_FAILED -eq 'true')
$global:_buildAborted = ($env:TSD_BUILD_ABORTED -eq 'true')
$global:_notBuilt = ($env:TSD_NOT_BUILT -eq 'true')
$global:_uploadToELK = $false
$global:_pdc = '0.0.0'
$global:_lastNightbatchLocation = ''
$global:majorVersion = if ($env:TSD_MAJOR_VERSION) { $env:TSD_MAJOR_VERSION } else { '' }
$global:nunitExecutable = if ($env:TSD_NUNIT_EXECUTABLE) { $env:TSD_NUNIT_EXECUTABLE } else { '' }
$_systemName = $env:SYSTEM_NAME

function Set-TsdState([string] $Name, [string] $Value) {
    Set-Item -Path "env:$Name" -Value $Value
    if ($env:GITHUB_ENV) { "$Name=$Value" | Out-File -FilePath $env:GITHUB_ENV -Append -Encoding ascii }
}

# writeFile(encoding: "UTF-8") = UTF-8 without BOM
function Write-TsdFile([string] $Path, [string] $Text) {
    [IO.File]::WriteAllText($Path, $Text, [Text.UTF8Encoding]::new($false))
}

# Jenkins 'bat' with a multi-line script: runs it as a .cmd file, returns the exit code.
function Invoke-BatScript([string] $Label, [string] $Script) {
    $dir = if ($env:RUNNER_TEMP) { $env:RUNNER_TEMP } else { $env:TEMP }
    $file = Join-Path $dir ("bat_{0}.cmd" -f [guid]::NewGuid().ToString('N'))
    Write-TsdFile $file $Script
    try {
        return (Invoke-Bat $Label "`"$file`"")
    } finally {
        Remove-Item -LiteralPath $file -Force -ErrorAction SilentlyContinue
    }
}

function Get-TsdDescription {
    return $env:TEST_LIBRARY.Replace('.dll', '').Replace('FAST.SystemTests.', '')
}

function StartStage_ExecuteTests {
    PrintHeader 'STAGE EXECUTE TESTS'
    # (env.Loops as Integer): a non-number fails the stage
    $loopsAmount = [int]::Parse($env:LOOPS) + 1
    for ($loopNr = 1; $loopNr -lt $loopsAmount; $loopNr++) {
        $description = "$(Get-TsdDescription) ($loopNr/$($env:LOOPS))"
        Write-FunctionsSummary "| Loop $loopNr | $description |"
        try {
            StartTest
            RunResetTest
            CopyResultsToNightbatch
            UploadToELK
        } finally {
            # bat(label: 'Killing Tasks', returnStatus: true, ...)
            [void](Invoke-BatScript 'Killing Tasks' ((GetKillingCommands) + "exit /B 0`n"))
        }
        $currentResult = if ($global:_notBuilt) { 'NOT_BUILT' } else { 'SUCCESS' }
        Write-Host "Build result: $currentResult"
        if ($currentResult -eq 'NOT_BUILT') { throw 'Build Failed' }
        if ($global:_buildAborted -eq $true) { throw 'Build Aborted' }
    }
}

# Jenkins abort (Stop button / REST stop): the running bat is interrupted, catchError in ExecuteCommand catches it,
# and the loop body continues (RunResetTest, CopyResultsToNightbatch, UploadToELK, Killing Tasks, "Build result: ABORTED").
# In GitHub a cancel kills the step, so its dedicated cancelled-step handler runs this cleanup.
function StartStage_ExecuteTestsAfterCancel {
    # The workflow only invokes this after Execute Tests was cancelled. Persist the abort
    # state here because GitHub terminates the cancelled step before it can save it.
    $global:_buildFailed = $true
    $global:_buildAborted = $true
    Set-TsdState 'TSD_BUILD_FAILED' 'true'
    Set-TsdState 'TSD_BUILD_ABORTED' 'true'

    try {
        if (-not $global:majorVersion -or -not $global:nunitExecutable) {
            try {
                InitializeNunitSettings
            } catch {
                Write-Host "::warning::Unable to determine NUnit settings for cancelled-build reset: $($_.Exception.Message)"
            }
        }
        if ($global:majorVersion -and $global:nunitExecutable) {
            RunResetTest
        } else {
            Write-Host '::warning::Skipping reset test because NUnit settings are unavailable.'
        }
        CopyResultsToNightbatch
        UploadToELK
    } finally {
        [void](Invoke-BatScript 'Killing Tasks' ((GetKillingCommands) + "exit /B 0`n"))
    }
    Write-Host 'Build result: ABORTED'
}

function StartTest {
    PrintHeader 'EXECUTE TEST'
    $testParameters = $env:TEST_PARAMETERS
    InitializeNunitSettings
    if ($env:TEST_PARAMETERS.Contains('/runlist:testlist.txt')) {
        Write-Host 'Updating TestParameters...'
        $testParameters = '/runlist:' + $testLibraryFolder
        $testParameters += "$env:ASSIGNED_ID"
        $testParameters += '.txt'
    }
    Write-Host "TestParameters: $testParameters ? $testLibraryFolder + $(if ($env:ASSIGNED_ID) { $env:ASSIGNED_ID } else { 'null' })"
    $commandData = ''
    $commandData += GetKillingCommands
    $commandData += "ECHO Delete data from previous tests... `n"
    $commandData += "del /F /Q $TSDTracingFolder\SpecflowLogging.log `n"
    $commandData += "del /F /Q $TSDTracingFolder\SystemFingerPrint.xml `n"
    $commandData += "del /F /Q $TSDTracingFolder\measurements.xml `n"
    $commandData += "del /F /Q $TSDTracingFolder\system-info.xml `n"
    $commandData += "del /F /Q $TSDTracingFolder\EventLogErrors.txt `n"
    $commandData += "rmdir /Q /S $TSDResultsFolder `n"
    $commandData += "ECHO Start test... `n"

    $formattedArgs = BuildNunitArgs $testParameters $global:majorVersion $nunitOutputFolder

    $work = if ($global:majorVersion -eq '3') { "--work=`"$nunitOutputFolder`" " } else { "/work:`"$nunitOutputFolder`" " }
    $commandData += "`"$global:nunitExecutable`" " + $work + "$formattedArgs " + "`"$testLibraryFolder$($env:TEST_LIBRARY)`"`n"

    $commandData += "Echo cleanup`n"
    $commandData += "DEL /F /Q %~f0`n"
    Write-Host $commandData
    Write-TsdFile "$($TSDDataPath)command.cmd" $commandData
    [void](ExecuteCommand 'Cleanup and then start test' "$($TSDDataPath)command.cmd")
}

function InitializeNunitSettings {
    # Detect NUnit version from nunit.framework.dll (bat returnStdout: a non-zero exit code fails the stage)
    $nunitDllPath = "$($testLibraryFolder)nunit.framework.dll"
    $out = @(powershell -NoProfile -Command "(Get-Item '$nunitDllPath').VersionInfo.ProductVersion" | ForEach-Object { "$_" })
    $rc = $LASTEXITCODE
    $global:LASTEXITCODE = 0
    if ($rc -ne 0) { throw "script returned exit code $rc" }
    # Extract only the first line that looks like a version
    $nunitVersion = $out | Where-Object { $_ -match '^\d+(\.\d+)+.*$' } | Select-Object -First 1
    if (-not $nunitVersion) { $nunitVersion = '' }
    Write-Host "Detected NUnit framework DLL version: $nunitVersion"
    $global:majorVersion = if ($nunitVersion) { ($nunitVersion.Split('.') | Where-Object { $_ -ne '' })[0] } else { '' }
    Write-Host "Major version: $global:majorVersion"
    if ($global:majorVersion -eq '2') {
        $global:nunitExecutable = $TSDDataPath + 'Packages\NUnit 2.6.2\bin\nunit-console-x86.exe'
    } elseif ($global:majorVersion -eq '3') {
        $global:nunitExecutable = $TSDDataPath + 'Packages\NUnit.org\nunit-console\nunit3-console.exe'
    } else {
        throw "[ERROR] Unsupported NUnit version: $global:majorVersion"
    }
    Set-TsdState 'TSD_MAJOR_VERSION' $global:majorVersion
    Set-TsdState 'TSD_NUNIT_EXECUTABLE' $global:nunitExecutable
}

function StartStage_PrepareEnvironment {
    PrintHeader 'STAGE PREPARE ENVIRONMENT'
    # Run*CurrentUser.exe are in use and cannot be copied, newest version is already copied via jenkins so skip the copy of it.
    # Create batch file to run as Jenkins has a bug on parsing dualquotes to the batch call.
    # Also when creating batch file, the RunAsCurrentUser doesn't have to run for each call.
    $commandData = ''
    $commandData += GetKillingCommands

    # -------- TOOLS (incremental copy: new + updated files only) --------
    $commandData += "robocopy.exe `"$($TSDServerDataPath)Tools`" `"$($TSDDataPath)Tools`" "
    $commandData += "/E /XO /FFT /XF Run*CurrentUser.exe /MT:8 /R:100 /W:30 /NP /NFL /NDL`n"

    # -------- PACKAGES (incremental copy: new + updated files only) --------
    $commandData += "robocopy.exe `"$($TSDServerDataPath)Packages`" `"$($TSDDataPath)Packages`" "
    $commandData += "/E /XO /FFT /XF Run*CurrentUser.exe /MT:8 /R:100 /W:30 /NP /NFL /NDL`n"

    # -------- BATCHES (incremental copy: new + updated files only) --------
    $commandData += "robocopy.exe `"$($TSDServerDataPath)Batches`" `"$($TSDDataPath)Batches`" "
    $commandData += "/E /XO /FFT /XF Run*CurrentUser.exe /MT:8 /R:100 /W:30 /NP /NFL /NDL`n"

    $commandData += 'robocopy.exe /E /IS /W:30 /R:100 /np "'
    $commandData += "$($env:TESTS_LOCATION.Trim())"
    $commandData += "`" `"$TSDTestsCopyTarget`"`n"
    $commandData += "Echo cleanup`n"
    $commandData += "DEL /F/Q %~f0`n"
    # commandData.replaceAll('""', '"'): the TestsLocation default already has quotes
    $commandData = $commandData.Replace('""', '"')
    Write-TsdFile "$($TSDDataPath)command.cmd" $commandData
    [void](ExecuteCommand 'Copying data' "$($TSDDataPath)command.cmd")
}

function CopyResultsToNightbatch {
    PrintHeader 'COPY RESULTS TO NIGHTBATCH'
    # new Date().format() runs on the Jenkins master (Europe/Amsterdam), not on the side PC
    $now = [TimeZoneInfo]::ConvertTimeBySystemTimeZoneId([DateTime]::UtcNow, 'W. Europe Standard Time').ToString('yyyy-MM-dd_HH-mm-ss')
    $testNameIncludingDateTime = "$(Get-TsdDescription)_$now"
    Write-Host "testNameIncludingDateTime: $testNameIncludingDateTime"
    if (-not $testNameIncludingDateTime) {
        Write-Host 'testNameIncludingDateTime is empty after processing, setting to default value'
        $testNameIncludingDateTime = '0.0.0'
        Write-Host "testNameIncludingDateTime set to default value: $testNameIncludingDateTime"
    }
    $fromLocation = $TSDTracingFolder
    $toLocation = "$TSDResultsFolder\TestOutput"
    $fileNames = '"SpecflowLogging.log"'
    $pdcVersionResult = ''
    # bat returnStdout: true -> the output starts with the echoed command line (no @), then the dir output
    $pdcCommand = "`"$($TSDDataPath)Tools\RunAsCurrentUser.exe`" `"dir /B /O:D $fromLocation\*.pdcVersion`""
    try {
        $env:TSD_BAT = $pdcCommand
        $pdcOut = @(cmd.exe /d /s /c --% "%TSD_BAT%"
        )
        $rc = $LASTEXITCODE
        $global:LASTEXITCODE = 0
        if ($rc -ne 0) { throw "script returned exit code $rc" }
        $pdcVersionResult = "`r`n$((Get-Location).Path)>$pdcCommand`r`n" + (($pdcOut | ForEach-Object { "$_" }) -join "`r`n")
    } catch {
        Write-Host "Error executing bat command: $($_.Exception.Message)"
    }
    Write-Host "pdcVersionResult: $pdcVersionResult"
    if ($pdcVersionResult) {
        $idx = $pdcVersionResult.LastIndexOf('.pdcVersion', [StringComparison]::Ordinal)
        if ($idx -ne -1) {
            # Extract the filename without the extension
            $pdcVersionResult = $pdcVersionResult.Substring(0, $idx)
            Write-Host "pdcVersionResult after removing .pdcVersion: $pdcVersionResult"
            $global:_pdc = $pdcVersionResult.Substring($pdcVersionResult.LastIndexOf('):', [StringComparison]::Ordinal) + 3)
            Write-Host "_pdc: $global:_pdc"
        } else {
            $global:_pdc = '0.0.0'
            Write-Host 'No .pdcVersion found in pdcVersionResult'
        }
    } else {
        Write-Host 'No .pdcVersion file found'
        $global:_pdc = '0.0.0'
        Write-Host "_pdc set to default value: $global:_pdc"
    }

    # Check if _pdc is empty or not #.#.# and set to default if necessary
    if (-not $global:_pdc -or $global:_pdc -cnotmatch '^\d+\.\d+\.\d+$') {
        Write-Host '_pdc is empty or did not contain a valid PDC number after processing, setting to default value'
        $global:_pdc = '0.0.0'
        Write-Host "_pdc set to default value: $global:_pdc"
    } else {
        Write-Host "_pdc is in the correct format: $global:_pdc"
    }
    $global:_lastNightbatchLocation = "$($env:SAVE_LOCATION)\$($env:SYSTEM_NAME)\$($global:_pdc)\$testNameIncludingDateTime"

    $media = "$env:SAVE_SCREENSHOTS_AND_VIDEOS_TO_LOCATION".Trim()
    $copyCapturedMedia = $media -ieq 'true'
    Write-Host "SaveScreenshotsAndVideosToLocation: $(if ($env:SAVE_SCREENSHOTS_AND_VIDEOS_TO_LOCATION) { $env:SAVE_SCREENSHOTS_AND_VIDEOS_TO_LOCATION } else { 'null' })"
    Write-Host "copyCapturedMedia: $($copyCapturedMedia.ToString().ToLower())"

    $commandData = ''
    $commandData += "ECHO Copy results to $toLocation`n"
    $commandData += "robocopy /W:30 /R:100 `"$fromLocation`" `"$toLocation`" $fileNames`n"
    # 'Move ...' and 'Copy ...' below are not echoed in the groovy file either (cmd prints a syntax error, ignored).
    $commandData += "Move results to $toLocation`n"
    $fileNames = '"SystemFingerPrint.xml" "measurements.xml" "system-info.xml"'
    $commandData += "robocopy /W:30 /R:100 /MOV `"$fromLocation`" `"$toLocation`" $fileNames`n"
    $fromLocation = $TSDResultsFolder
    $commandData += "Copy result/report to Nightbatch from $fromLocation to $($global:_lastNightbatchLocation)`n"
    $commandData += "robocopy `"$fromLocation`" `"$($global:_lastNightbatchLocation)`" /V /NP /MIR /W:30 /R:100`n"

    if ($copyCapturedMedia) {
        $commandData += "@ECHO Copying captured images/videos to Specified Location.`n"
        $copyCapturedMediaToSpecifiedLocationCommand = $CopyCapturedMediaTemplate.Replace('__LOCATION__', $global:_lastNightbatchLocation)
        $commandData += '@' + $copyCapturedMediaToSpecifiedLocationCommand + "`n"
    }
    $commandData += "echo Create link for resultviewer`n"
    $commandData += "echo [InternetShortcut] > `"$($global:_lastNightbatchLocation)\LinkToResultViewer.url`"`n"
    $commandData += "echo URL=$TSDResultViewerURL$_systemName/$($global:_pdc)/$testNameIncludingDateTime >> `"$($global:_lastNightbatchLocation)\LinkToResultViewer.url`"`n"
    $commandData += "Echo cleanup`n"
    $commandData += "DEL /F/Q %~f0`n"
    Write-TsdFile "$($TSDDataPath)command.cmd" $commandData
    [void](ExecuteCommand 'Copying data' "$($TSDDataPath)command.cmd" $false)
    Write-FunctionsSummary "| Results | $($global:_lastNightbatchLocation) |"
}

# The inline powershell command of CopyResultsToNightbatch(), character for character (__LOCATION__ = _lastNightbatchLocation).
$CopyCapturedMediaTemplate = @'
powershell -NoProfile -ExecutionPolicy Bypass -Command "$metadataFile='__LOCATION__\TestOutput\icapture-data.json'; $destination='__LOCATION__\TestOutput\ICapture_Screenshots_Data'; $copiedAny=$false; $logLines=@(); $lastSourcePath=''; if (Test-Path -LiteralPath $metadataFile) { if (-not (Test-Path -LiteralPath $destination)) { New-Item -ItemType Directory -Path $destination | Out-Null }; $items=Get-Content -LiteralPath $metadataFile -Raw | ConvertFrom-Json; foreach ($item in $items) { if (-not $item.ImageVideoSavedPath -or -not $item.ImageVideoName) { continue }; $sourceFile=Join-Path $item.ImageVideoSavedPath $item.ImageVideoName; if (Test-Path -LiteralPath $sourceFile) { $fileInfo=Get-Item -LiteralPath $sourceFile; Copy-Item -LiteralPath $sourceFile -Destination $destination -Force; $size=if($fileInfo.Length -ge 1MB){('{0:N1} m' -f ($fileInfo.Length/1MB))}else{$fileInfo.Length}; if($lastSourcePath -ne $item.ImageVideoSavedPath){ $logLines+=''; $logLines+='Source path:'; $logLines+=$item.ImageVideoSavedPath; $logLines+=''; $lastSourcePath=$item.ImageVideoSavedPath; } $logLines+=('    New File   {0,10}    {1}' -f $size,$item.ImageVideoName); $copiedAny=$true; } else { $logLines+=('    File not found: ' + $sourceFile); } } if($copiedAny){ Write-Host ''; Write-Host 'Destination path:'; Write-Host $destination; Write-Host ''; Write-Host 'Captured images/videos copied successfully to Specified Location.'; Write-Host ''; Write-Host 'Details of copied images/videos and their source paths:'; Write-Host ''; $logLines | ForEach-Object { Write-Host $_ }; } else { Write-Host 'No iCapture media files copied.'; } } else { Write-Host ('Metadata file not found: ' + $metadataFile); }"
'@

function UploadToELK {
    PrintHeader 'UPLOAD RESULTS TO ELK'
    if ($global:_uploadToELK -eq $true) {
        # Dead code in the groovy file (_uploadToELK is never set to true): node('master') + DataParseAndUploadScript.py.
        throw 'UploadToELK with _uploadToELK = true is not ported (never true in TestStarterDevelopmentStages.groovy).'
    } else {
        Write-Host "Skip uploading to ELK as ``_uploadToELK != true``, actual: $($global:_uploadToELK.ToString().ToLower())"
    }
}

function PrintHeader([string] $headerName) {
    $stageData = "# $headerName".PadRight(119) + '#'
    Write-Host ('#' * 120)
    Write-Host $stageData
    Write-Host ('#' * 120)
}

function GetKillingCommands {
    # As the live share copy of TestStarterDevelopmentStages.groovy (wmic replaced by Get-Process | Stop-Process).
    $commandData = ''
    $commandData += "ECHO Killing Tasks.`n"
    $commandData += 'powershell -NoProfile -Command "Get-Process | Where-Object { $_.ProcessName -like ''nunit*'' } | Stop-Process -Force -ErrorAction SilentlyContinue"' + "`n"
    $commandData += 'powershell -NoProfile -Command "Get-Process | Where-Object { $_.ProcessName -eq ''TAFTafFVAdapterCSExeCOMServer'' } | Stop-Process -Force -ErrorAction SilentlyContinue"' + "`n"
    $commandData += 'powershell -NoProfile -Command "Get-Process | Where-Object { $_.ProcessName -like ''iCapture*'' } | Stop-Process -Force -ErrorAction SilentlyContinue"' + "`n"
    $commandData += 'powershell -NoProfile -Command "Get-Process | Where-Object { $_.ProcessName -like ''testcentric*'' } | Stop-Process -Force -ErrorAction SilentlyContinue"' + "`n"
    return $commandData
}

function BuildNunitArgs([string] $testParameters, [string] $majorVersion, [string] $nunitOutputFolder) {
    if ($majorVersion -eq '3') {
        $whereClause = $testParameters.Trim() -replace '^"(.*)"$', '$1'
        if ($whereClause.StartsWith('/include:')) {
            $categories = $whereClause.Replace('/include:', '').Replace(',', '|').Trim()
            $whereClause = "--where `"cat =~ '$categories'`""
        } elseif ($whereClause.StartsWith('/runlist:')) {
            $listFile = $whereClause.Replace('/runlist:', '').Trim()
            $whereClause = "--testlist `"$listFile`""
        }
        return "$whereClause --result=`"$nunitOutputFolder/TestResult.xml;format=nunit3`""
    }
    return $testParameters
}

function RunResetTest {
    if (-not $global:_buildAborted) {
        Write-Host 'Reset skipped — previous execution succeeded.'
        return
    }
    PrintHeader 'POST ACTIONS (Triggered Automatically)'
    Write-Host 'Running Reset Test because execution failed or was aborted...'

    $resetLibrary = 'FAST.SystemTests.SetupTeardown.dll'
    $resetArgs = BuildNunitArgs '/include:Test.PostLoop.Reset' $global:majorVersion $nunitOutputFolder
    $work = if ($global:majorVersion -eq '3') { "--work=`"$nunitOutputFolder`" " } else { "/work:`"$nunitOutputFolder`" " }
    $resetCmd = "`"$global:nunitExecutable`" " + $work + "$resetArgs " + "`"$testLibraryFolder$resetLibrary`"`n"
    $resetCmd += "DEL /F /Q %~f0`n"
    Write-Host $resetCmd
    Write-TsdFile "$($TSDDataPath)resetCmd.cmd" $resetCmd
    [void](ExecuteCommand 'Running Reset Test' "$($TSDDataPath)resetCmd.cmd" $false)
    Write-Host 'Reset execution finished — environment restored.'
}

function ExecuteCommand([string] $commandTitle, [string] $command, [bool] $skipOnAbort = $true, [bool] $runOnMaster = $false) {
    $exitCode = -1
    if ($skipOnAbort -eq $true -and $global:_buildFailed -eq $true) {
        Write-Host "Skip command $command due to abort or build failure"
    } else {
        # bat label: 'Killing Tasks', returnStatus: true
        [void](Invoke-BatScript 'Killing Tasks' ("@echo off`n" +
            "echo `"Killing RunAs/InCurrentUser (ignore the process not found errors)`" `n" +
            "taskkill /F /IM `"RunAsCurrentUser.exe`"`n" +
            "taskkill /F /IM `"RunInCurrentUser.exe`"`n" +
            "exit /B 0`n"))
        $runAsCurrentUser = "$($TSDDataPath)Tools\RunAsCurrentUser.exe"
        if ($runOnMaster -eq $true) {
            $runAsCurrentUser = "$($TSDJenkinsBatchesPath)Tools\RunAsCurrentUser.exe"
        }
        Start-Sleep -Seconds 1
        Write-Host "### EXECUTE $($commandTitle): $command"
        # catchError(buildResult: "NOT_BUILT", stageResult: "FAILURE") around a returnStatus bat:
        # only a bat that cannot start is caught; the exit code itself never fails the stage.
        try {
            $exitCode = Invoke-Bat $commandTitle "`"$runAsCurrentUser`" `"$command`""
        } catch {
            Write-Host "::error::$commandTitle : $($_.Exception.Message)"
            $global:_notBuilt = $true
            Set-TsdState 'TSD_NOT_BUILT' 'true'
        }
        # Script stopped by user via ForceClose button
        if ($exitCode -eq 9999) {
            $global:_buildFailed = $true
            $global:_buildAborted = $true
            Set-TsdState 'TSD_BUILD_FAILED' 'true'
            Set-TsdState 'TSD_BUILD_ABORTED' 'true'
        }
    }
    return $exitCode
}
