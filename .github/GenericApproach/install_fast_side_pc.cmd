echo on
echo %1

set "msiSource=C:\Temp\FAST\FAST.msi"

if not exist "%msiSource%" (
    echo [ERROR] FAST MSI does not exist: "%msiSource%"
    exit /b 1
)

echo =====================================
echo Copying FAST.msi
echo =====================================

if not exist "C:\Temp\FAST\Tests" mkdir "C:\Temp\FAST\Tests"
copy /Y "%msiSource%" "C:\Temp\FAST\Tests\FAST.msi"
if errorlevel 1 exit /b %ERRORLEVEL%

echo =====================================
echo Starting Installation
echo =====================================

echo [TIME] Before install: %TIME%

Rem Uninstall old version of FAST and installs current one
set "MAINLINE_TEAM_TESTS=true"
START /WAIT powershell start -verb runas "%~dp0..\Tools\UninstallInstallJenkins.cmd" -ArgumentList "FAST", "C:\Temp\FAST\Tests\FAST.msi" -Wait
if errorlevel 1 exit /b %ERRORLEVEL%
echo [TIME] After install: %TIME%
echo [INFO] Installation ERRORLEVEL: %ERRORLEVEL%

echo Old version of FAST was uninstalled and newest version was installed
exit /b 0
