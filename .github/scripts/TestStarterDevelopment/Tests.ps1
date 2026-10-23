$ErrorActionPreference = 'Stop'

function Assert([bool] $Condition, [string] $Message) {
    if (-not $Condition) { throw $Message }
}

$repository = (Resolve-Path "$PSScriptRoot\..\..\..").Path
$temp = Join-Path $env:TEMP ("tsd tests {0}" -f [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp | Out-Null
try {
    $env:GITHUB_WORKSPACE = $repository
    $env:RUNNER_TEMP = $temp
    $env:GITHUB_ENV = ''
    $env:GITHUB_STEP_SUMMARY = ''
    $env:TEST_LIBRARY = 'FAST.SystemTests.Acceptance.dll'
    $env:TEST_PARAMETERS = '"/include:Test.PreLoop.Generic,Test.Batch.Acceptance"'
    $env:TESTS_LOCATION = '"\\test-input\Acceptance"'
    $env:SAVE_LOCATION = '\\test-results\Nightbatch'
    $env:SYSTEM_NAME = 'TestRunner'
    $env:LOOPS = '1'
    $env:SAVE_SCREENSHOTS_AND_VIDEOS_TO_LOCATION = 'true'
    $env:DATA_PATH = 'Z:\legacy-do-not-use\'
    $env:SERVER_DATA_PATH = '\\legacy-do-not-use\tooling'
    $env:JENKINS_BATCHES_PATH = '\\legacy-do-not-use\batches'
    $env:TSD_BUILD_FAILED = ''
    $env:TSD_BUILD_ABORTED = ''
    $env:TSD_NOT_BUILT = ''
    $env:TSD_MAJOR_VERSION = ''
    $env:TSD_NUNIT_EXECUTABLE = ''

    . "$PSScriptRoot\..\Shared\functions.ps1"
    $batCalls = [Collections.Generic.List[string]]::new()
    function Invoke-Bat([string] $Label, [string] $Script) {
        $batCalls.Add($Script)
        return 0
    }
    . "$PSScriptRoot\Common.ps1"
    $realExecuteCommand = ${function:ExecuteCommand}
    $script:commands = @()
    function ExecuteCommand([string] $Title, [string] $Command, [bool] $SkipOnAbort = $true) {
        Assert ($Command.StartsWith($temp + '\')) 'Generated command must be under RUNNER_TEMP.'
        $text = [IO.File]::ReadAllText($Command)
        Assert ($text -notmatch 'legacy-do-not-use|JenkinsBatches|D:\\Jenkins') 'Generated command uses legacy tooling.'
        Assert ($text.Contains('"%~f0"')) 'Self-cleanup must quote command paths containing spaces.'
        $script:commands += [pscustomobject]@{ Title = $Title; Text = $text; SkipOnAbort = $SkipOnAbort }
        return 0
    }
    function Invoke-BatScript { return 0 }
    function Start-Sleep {}
    function powershell {
        $global:LASTEXITCODE = 0
        return "$script:frameworkMajor.0.0"
    }
    function cmd.exe {
        $global:LASTEXITCODE = 0
        return '1.2.3.pdcVersion'
    }

    & "$PSScriptRoot\01__PrepareNode.ps1"
    Assert ($batCalls.Count -eq 2) 'Prepare Node should only stop old launchers, not copy tooling.'
    Assert ($TSDToolsPath -eq (Join-Path $repository '.github\Tools')) 'Tool path must use checkout.'
    Assert ($TSDPackagesPath -eq (Join-Path $repository '.github\Packages')) 'Package path must use checkout.'

    StartStage_PrepareEnvironment
    $prepare = $script:commands[-1].Text
    Assert (([regex]::Matches($prepare, 'robocopy')).Count -eq 1) 'Preparation should copy test inputs only.'
    Assert ($prepare.Contains('"\\test-input\Acceptance"')) 'Quoted test input path must be preserved.'
    Assert ($prepare.Contains('"c:\temp\FAST\tests"')) 'Test destination must be preserved.'

    foreach ($script:frameworkMajor in @('2', '3')) {
        StartTest
        $test = $script:commands[-1].Text
        $expected = if ($script:frameworkMajor -eq '2') {
            Join-Path $TSDPackagesPath 'NUnit 2.6.2\bin\nunit-console-x86.exe'
        } else {
            Join-Path $TSDPackagesPath 'NUnit.org\nunit-console\nunit3-console.exe'
        }
        Assert ($global:nunitExecutable -eq $expected) 'Incorrect NUnit runner selection.'
        Assert ($test.Contains('"' + $expected + '"')) 'NUnit path must be quoted.'
        Assert ($test.Contains($env:TEST_LIBRARY)) 'Test library must be retained.'
        if ($script:frameworkMajor -eq '3') {
            Assert ($test.Contains("--where `"cat =~ 'Test.PreLoop.Generic|Test.Batch.Acceptance'`"")) 'NUnit 3 categories changed.'
            Assert ($test.Contains(';format=nunit3')) 'NUnit 3 result format changed.'
        } else {
            Assert ($test.Contains($env:TEST_PARAMETERS)) 'NUnit 2 parameters changed.'
        }
        $global:_buildAborted = $true
        RunResetTest
        Assert ($script:commands[-1].Text.Contains('FAST.SystemTests.SetupTeardown.dll')) 'Reset library changed.'
        Assert ($script:commands[-1].Text.Contains('"' + $expected + '"')) 'Reset must use checked-out runner.'
        Assert (-not $script:commands[-1].SkipOnAbort) 'Reset must run after abort.'
        $global:_buildAborted = $false
    }

    $env:TEST_PARAMETERS = '/runlist:testlist.txt'
    $env:ASSIGNED_ID = 'assigned'
    StartTest
    Assert ($script:commands[-1].Text.Contains('--testlist "C:\Temp\FAST\Tests\assigned.txt"')) 'Runlist mapping changed.'

    $beforeLoop = $script:commands.Count
    StartStage_ExecuteTests
    Assert ($script:commands.Count -eq ($beforeLoop + 2)) 'Successful loop should run test and result copy, without reset.'

    CopyResultsToNightbatch
    $results = $script:commands[-1].Text
    Assert ($results.Contains($env:SAVE_LOCATION + '\' + $env:SYSTEM_NAME)) 'Nightbatch output path changed.'
    Assert ($results.Contains('icapture-data.json')) 'Optional media copy is missing.'
    Assert ($env:TSD_BAT.StartsWith('"' + $TSDToolsPath + '\RunAsCurrentUser.exe"')) 'PDC lookup must use checkout launcher.'

    StartStage_ExecuteTestsAfterCancel
    Assert ($global:_buildAborted -and $global:_buildFailed) 'Cancellation state was not preserved.'
    Assert ($script:commands[-2].Title -eq 'Running Reset Test') 'Cancellation should reset before copying results.'
    Assert ($script:commands[-1].Title -eq 'Copying data') 'Cancellation should copy results.'

    $global:_buildFailed = $false
    [void](& $realExecuteCommand 'Mock execution' $TSDCommandPath)
    Assert ($batCalls[-1] -eq ('"' + $TSDToolsPath + '\RunAsCurrentUser.exe" "' + $TSDCommandPath + '"')) 'Launcher or command path quoting changed.'

    $script:frameworkMajor = '4'
    $unsupportedRejected = $false
    try { InitializeNunitSettings } catch {
        if ($_.Exception.Message -notlike '*Unsupported NUnit version*') { throw }
        $unsupportedRejected = $true
    }
    Assert $unsupportedRejected 'Unsupported NUnit must fail explicitly.'

    $script:frameworkMajor = '3'
    $TSDPackagesPath = Join-Path $temp 'missing packages'
    $missingRejected = $false
    try { InitializeNunitSettings } catch {
        if ($_.Exception.Message -notlike '*checked-out NUnit runner is missing*') { throw }
        $missingRejected = $true
    }
    Assert $missingRejected 'Missing checked-out NUnit must fail explicitly.'

    $env:GITHUB_WORKSPACE = ''
    $env:RUNNER_TEMP = ''
    . "$PSScriptRoot\Common.ps1"
    Assert ($TSDRepositoryPath -eq $repository) 'Outside Actions, tooling must resolve relative to this script.'
    Assert ($TSDTempPath -eq $env:TEMP) 'Outside Actions, command files must use TEMP.'
    Write-Host 'PASS: checkout assets, preparation, NUnit 2/3, runlist, loops, reset, results, cancellation, quoting and missing-tool errors.'
} finally {
    foreach ($name in @('tsd-command.cmd', 'tsd-reset.cmd')) {
        $file = Join-Path $temp $name
        if (Test-Path -LiteralPath $file) { Remove-Item -LiteralPath $file -Force }
    }
    Remove-Item -LiteralPath $temp -Force
}
