<#
.SYNOPSIS
    Installs the GitHub Actions self-hosted runner on a side PC as a Windows service.

.DESCRIPTION
    GitHub Actions equivalent of Jenkins\Jenkins-CI-Client\install.cmd.
    Each side PC is registered as its own runner. The runner name and an extra
    label are both set to the side PC name (e.g. Kratu_BLR), so workflows can
    target it with: runs-on: [self-hosted, Windows, <SystemName>]

.EXAMPLE
    .\install.ps1 -RunnerName Kratu_BLR -Token <registration token>
#>
param(
    # Side PC name; must match the SystemName option in the workflow (take care with capital letters!)
    [Parameter(Mandatory)] [string] $RunnerName,

    # Registration token from GitHub: Settings > Actions > Runners > New self-hosted runner (valid ~1 hour)
    [Parameter(Mandatory)] [string] $Token,

    [string] $RepoUrl = 'https://github.com/SaikiranTSK/SpikeGitHubActions',
    [string] $RunnerVersion = '2.338.2',
    [string] $InstallDir = 'C:\actions-runner',

    # Runner work folder (Jenkins "Remote root directory", D:\Jenkins\ on the side PCs).
    # Relative paths are below InstallDir. Example: -WorkDir D:\Jenkins\_work
    [string] $WorkDir = '_work',

    # Extra labels, comma separated. The runner always gets <RunnerName> and the PC host name
    # (the Jenkins node label). Example for a 2nd runner on the Jenkins server:
    #   -RunnerName nlybstqvp4dt7nv-2 -InstallDir C:\actions-runner-2 -Labels nlybstqvp4dt7nv
    [string] $Labels = '',

    # Default (empty): Local System, same as the Jenkins agent service. Needed because
    # RunAsCurrentUser.exe can only start tests in the logged-in user's session from Local System.
    # Set to e.g. .\user or DOMAIN\user to run the service as that account instead (password is asked for).
    [string] $ServiceAccount = '',
    [string] $ServicePassword = '',

    # Use NT AUTHORITY\NETWORK SERVICE (the GitHub runner default).
    [switch] $UseNetworkService,

    # Optional proxy, e.g. http://proxy.company.com:8080
    [string] $Proxy = ''
)

$ErrorActionPreference = 'Stop'

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Run this script from an administrator PowerShell / command prompt.'
}

if (Test-Path -LiteralPath (Join-Path $InstallDir '.runner')) {
    throw "A runner is already configured in $InstallDir. Run uninstall.cmd first."
}

if ($ServiceAccount -and -not $UseNetworkService) {
    if (-not $ServicePassword) {
        $secure = Read-Host -AsSecureString "Password for $ServiceAccount (runner service account)"
        $ServicePassword = (New-Object System.Net.NetworkCredential('', $secure)).Password
    }

    # Check the password before installing, so the service does not fail to start later.
    Add-Type -AssemblyName System.DirectoryServices.AccountManagement
    $parts = $ServiceAccount -split '\\', 2
    $domain = if ($parts.Count -eq 2) { $parts[0] } else { $env:COMPUTERNAME }
    $user = $parts[-1]
    if ($domain -eq '.' -or $domain -ieq $env:COMPUTERNAME) {
        $domain = $env:COMPUTERNAME
        $context = New-Object System.DirectoryServices.AccountManagement.PrincipalContext('Machine')
    }
    else {
        $context = New-Object System.DirectoryServices.AccountManagement.PrincipalContext('Domain', $domain)
    }
    if (-not $context.ValidateCredentials($user, $ServicePassword)) {
        throw "Wrong password for $ServiceAccount."
    }
    $ServiceAccount = "$domain\$user"
    Write-Host "Runner service will run as $ServiceAccount"
}

New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null

$zipName = "actions-runner-win-x64-$RunnerVersion.zip"
$localZip = Join-Path $PSScriptRoot $zipName
$zip = Join-Path $InstallDir $zipName

if (Test-Path -LiteralPath $localZip) {
    Write-Host "Using runner package from $localZip"
    Copy-Item -LiteralPath $localZip -Destination $zip -Force
}
else {
    $url = "https://github.com/actions/runner/releases/download/v$RunnerVersion/$zipName"
    Write-Host "Downloading $url"
    $webArgs = @{ Uri = $url; OutFile = $zip; UseBasicParsing = $true }
    if ($Proxy) { $webArgs.Proxy = $Proxy; $webArgs.ProxyUseDefaultCredentials = $true }
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest @webArgs
}

Write-Host "Extracting to $InstallDir"
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($zip, $InstallDir)
Remove-Item -LiteralPath $zip -Force

if ($Proxy) {
    # The runner service reads proxy settings from .env in the runner folder.
    "https_proxy=$Proxy`nhttp_proxy=$Proxy" | Set-Content -LiteralPath (Join-Path $InstallDir '.env') -Encoding ASCII
}

try { $hostName = [System.Net.Dns]::GetHostEntry('').HostName } catch { $hostName = $env:COMPUTERNAME }
$labelList = @($RunnerName, $hostName) + ($Labels -split ',') |
    ForEach-Object { $_.Trim() } | Where-Object { $_ } | Sort-Object -Unique
$labelText = $labelList -join ','
Write-Host "Runner labels: self-hosted, Windows, X64, $labelText"

$configArgs = @(
    '--unattended',
    '--url', $RepoUrl,
    '--token', $Token,
    '--name', $RunnerName,
    '--labels', $labelText,
    '--work', $WorkDir,
    '--runasservice',
    '--disableupdate'
)
if ($ServiceAccount -and -not $UseNetworkService) {
    $configArgs += @('--windowslogonaccount', $ServiceAccount, '--windowslogonpassword', $ServicePassword)
}

Push-Location $InstallDir
try {
    & .\config.cmd @configArgs
    if ($LASTEXITCODE -ne 0) { throw "config.cmd failed with exit code $LASTEXITCODE" }
}
finally {
    Pop-Location
}

$services = @(Get-Service -Name 'actions.runner.*')
$service = $services | Where-Object { $_.Name -like "*.$RunnerName" } | Select-Object -First 1
if (-not $service) { $service = $services | Where-Object { $_.Name -like "*$RunnerName*" } | Select-Object -First 1 }
if (-not $service) { throw "Runner service for $RunnerName not found." }

if (-not $ServiceAccount -and -not $UseNetworkService) {
    # Same as services.msc > Log On > Local System account > Apply, then restart.
    Write-Host "Setting '$($service.Name)' to log on as Local System"
    Stop-Service -Name $service.Name -Force
    & sc.exe config $service.Name obj= LocalSystem | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "sc.exe config failed with exit code $LASTEXITCODE" }
    Start-Service -Name $service.Name
}

$info = Get-CimInstance Win32_Service -Filter "Name='$($service.Name)'"
Write-Host "Service '$($info.Name)' is $($info.State), log on as $($info.StartName)."
Write-Host "Done. Check GitHub > Settings > Actions > Runners: '$RunnerName' should show as Idle."
