@echo off
rem Usage: install.cmd <SidePcName> <RegistrationToken> [extra install.ps1 parameters]
if "%~2"=="" (
    echo Usage: install.cmd ^<SidePcName^> ^<RegistrationToken^>
    exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" -RunnerName %1 -Token %2 %3 %4 %5 %6 %7 %8 %9
