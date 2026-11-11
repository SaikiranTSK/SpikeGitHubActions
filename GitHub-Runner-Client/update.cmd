@echo off
setlocal

rem Replaces the runner in the default C:\actions-runner folder.
rem The old folder is preserved as C:\actions-runner.previous, including _work.
rem Usage: update.cmd <SidePcName> <RemovalToken> <RegistrationToken>

if "%~3"=="" (
    echo Usage: update.cmd ^<SidePcName^> ^<RemovalToken^> ^<RegistrationToken^>
    exit /b 1
)

set "INSTALL_DIR=C:\actions-runner"
set "BACKUP_DIR=C:\actions-runner.previous"

if not exist "%INSTALL_DIR%\config.cmd" (
    echo No configured runner found in "%INSTALL_DIR%".
    exit /b 1
)

if exist "%BACKUP_DIR%" (
    echo Backup path "%BACKUP_DIR%" already exists.
    echo Rename or remove it after verifying the previous update before retrying.
    exit /b 1
)

choice /M "Unregister the current runner and install it again as %~1"
if errorlevel 2 exit /b 0

pushd "%~dp0"
call uninstall.cmd "%~2"
if errorlevel 1 (
    echo Runner removal failed. The old installation folder was not moved.
    popd
    exit /b 1
)

move "%INSTALL_DIR%" "%BACKUP_DIR%" >nul
if errorlevel 1 (
    echo Could not preserve "%INSTALL_DIR%" as "%BACKUP_DIR%".
    echo The runner has been unregistered; resolve this before installing again.
    popd
    exit /b 1
)

call install.cmd "%~1" "%~3"
set "INSTALL_EXIT_CODE=%ERRORLEVEL%"
popd

if not "%INSTALL_EXIT_CODE%"=="0" (
    echo Runner installation failed with exit code %INSTALL_EXIT_CODE%.
    echo The previous installation is preserved at "%BACKUP_DIR%".
    exit /b %INSTALL_EXIT_CODE%
)

echo Update completed. Verify the runner is Idle and run a test workflow.
echo The previous installation, including _work, is preserved at "%BACKUP_DIR%".
exit /b 0
