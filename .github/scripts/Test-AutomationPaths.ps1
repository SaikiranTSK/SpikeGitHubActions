$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$batchNames = @(
    'install_fast_jenkins.cmd', 'install_fast_side_pc.cmd',
    'execute_test_batch_jenkins.cmd', 'execute_test_batch_side_pc.cmd',
    'copy_results_to_nightbatch_jenkins.cmd', 'copy_results_to_nightbatch_side_pc.cmd',
    'generate_specflow_report.cmd', 'copy_nunit_specflow.cmd'
)
$scripts = @(Get-ChildItem (Join-Path $root '.github/scripts') -Recurse -Filter '*.ps1' -File)
$activeFiles = @(
    Get-ChildItem (Join-Path $root '.github/workflows') -Recurse -File |
        Where-Object { $_.Extension -in '.yml', '.yaml' }
    $scripts
    foreach ($name in $batchNames) { Get-Item (Join-Path $root ".github/GenericApproach/$name") }
    Get-Item (Join-Path $root '.github/Tools/Talk.cmd')
)
foreach ($file in $activeFiles) {
    if ((Get-Content -LiteralPath $file.FullName -Raw) -match '(?i)[a-z]:[\\/]Jenkins(?:[\\/]|[^a-z0-9_]|$)') {
        throw "Hardcoded drive-root Jenkins path in $($file.FullName)"
    }
}
foreach ($file in $scripts) {
    $tokens = $null
    $parseErrors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw "PowerShell parse failure in $($file.FullName): $parseErrors" }
}

function Assert-Equal($Actual, $Expected, [string] $Label) {
    if ($Actual -cne $Expected) { throw "${Label}: expected [$Expected], got [$Actual]" }
}

$savedWorkspace = $env:GITHUB_WORKSPACE
$savedDataPath = $env:DATA_PATH
$savedRunJob = $env:RUN_JOB
$savedCapture = $env:AUTOMATION_PATHS_CAPTURE
$scratch = Join-Path $root ('.automation-paths-' + [guid]::NewGuid().ToString('N'))
$workspace = Join-Path $scratch 'workspace with spaces'
$functionsFile = Join-Path $root '.github/scripts/Shared/functions.ps1'
$commonFile = Join-Path $root '.github/scripts/MainlineTeamTests/Common.ps1'
New-Item -ItemType Directory -Path $workspace -Force | Out-Null
Push-Location $scratch
try {
    $env:GITHUB_WORKSPACE = $workspace
    $env:DATA_PATH = Join-Path $scratch 'ignored override'
    . $commonFile
    Assert-Equal $RepositoryPath $workspace 'Workspace repository priority'
    Assert-Equal $FunctionsDataPath $workspace 'Workspace data priority'
    Assert-Equal $DataPath $workspace 'Mainline workspace'

    $script:commands = @()
    function Invoke-Bat([string] $Label, [string] $Script) {
        $script:commands += $Script
        return 0
    }
    $script:kills = 0
    function KillTasks { $script:kills++ }
    TalkText 'A spoken message' 42
    $env:RUN_JOB = 'Batch folder/job name.cmd'
    StartTestBatch
    $talk = Join-Path $workspace 'Tools/Talk.cmd'
    $launcher = Join-Path $workspace 'Tools/RunAsCurrentUser.exe'
    $batch = Join-Path $workspace $env:RUN_JOB
    Assert-Equal $script:commands.Count 2 'Mocked command count'
    Assert-Equal $script:commands[0] "`"$talk`" `"A spoken message`" 42" 'Quoted Talk command'
    Assert-Equal $script:commands[1] "`"$launcher`" `"$batch`" `"$env:RUN_JOB`"" 'Quoted batch command'
    Assert-Equal $script:kills 1 'Mocked KillTasks call'

    $env:GITHUB_WORKSPACE = $null
    . $functionsFile
    Assert-Equal $RepositoryPath $root 'Repository fallback from unrelated CWD'
    Assert-Equal $FunctionsDataPath $env:DATA_PATH 'Local data override'
    $env:DATA_PATH = $null
    . $commonFile
    Assert-Equal $FunctionsDataPath $root 'Local data fallback'
    Assert-Equal $DataPath $root 'Mainline local repository'

    if ($env:OS -eq 'Windows_NT') {
        $tools = Join-Path $workspace 'Tools'
        $generic = Join-Path $workspace 'GenericApproach'
        New-Item -ItemType Directory -Path $tools, $generic -Force | Out-Null
        $env:AUTOMATION_PATHS_CAPTURE = Join-Path $scratch 'arguments.txt'
        # Capture launcher arguments without running the real launcher or any child batch.
        Add-Type -TypeDefinition @'
using System;
using System.IO;
public class AutomationPathCapture {
    public static void Main(string[] args) {
        File.WriteAllLines(Environment.GetEnvironmentVariable("AUTOMATION_PATHS_CAPTURE"), args);
    }
}
'@ -OutputAssembly (Join-Path $tools 'RunAsCurrentUser.exe') -OutputType ConsoleApplication
        foreach ($name in @('install_fast', 'execute_test_batch', 'copy_results_to_nightbatch')) {
            $wrapper = Join-Path $generic "${name}_jenkins.cmd"
            Copy-Item (Join-Path $root ".github/GenericApproach/${name}_jenkins.cmd") $wrapper
            foreach ($job in @('Job with spaces', 'ResetNidaq')) {
                $categories = if ($name -eq 'execute_test_batch' -and $job -ne 'ResetNidaq') { 'Smoke, Category with spaces' } else { '' }
                Remove-Item $env:AUTOMATION_PATHS_CAPTURE -ErrorAction SilentlyContinue
                $command = "`"$wrapper`" `"$job`" `"$categories`""
                & $env:ComSpec /d /s /c "`"$command`"" | Out-Host
                Assert-Equal $LASTEXITCODE 0 "Wrapper exit: $name"
                $captured = @(Get-Content -LiteralPath $env:AUTOMATION_PATHS_CAPTURE)
                $expectedCount = if ($name -eq 'execute_test_batch') { 3 } else { 2 }
                Assert-Equal $captured.Count $expectedCount "Launcher argument count: $name"
                Assert-Equal $captured[0] (Join-Path $generic "${name}_side_pc.cmd") "Child path: $name"
                Assert-Equal $captured[1] $job "Job argument: $name"
                if ($expectedCount -eq 3) { Assert-Equal $captured[2] $categories 'Category argument' }
            }
        }
    } else {
        Write-Host 'SKIP: Windows batch/EXE argument capture requires Windows.'
    }
} finally {
    Pop-Location
    $env:GITHUB_WORKSPACE = $savedWorkspace
    $env:DATA_PATH = $savedDataPath
    $env:RUN_JOB = $savedRunJob
    $env:AUTOMATION_PATHS_CAPTURE = $savedCapture
    Remove-Item -LiteralPath $scratch -Recurse -Force
}
Write-Host "PASS: $($activeFiles.Count) active files checked; PowerShell parsing and path/command tests passed."
