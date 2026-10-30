@echo off
rem Usage: uninstall.cmd <RemovalToken>
if "%~1"=="" (
    echo Usage: uninstall.cmd ^<RemovalToken^>
    exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1" -Token %1 %2 %3
