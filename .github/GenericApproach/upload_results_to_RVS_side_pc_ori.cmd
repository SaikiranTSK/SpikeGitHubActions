@echo on
setlocal

:: ----------------------------
:: Parameters
:: ----------------------------
echo %1
echo %2
echo basePath=%3
set "basePath=%~3"

set "lockFile=%TEMP%\RVSAutomatedCompanionTool.lock"

:WAIT_LOCK
if exist "%lockFile%" (
    echo Another process is running... waiting 5 seconds
    timeout /t 5 >nul
    goto WAIT_LOCK
)

:: Create lock file
echo Locked > "%lockFile%"

:: ----------------------------
:: Execute the process since it's not running
:: ----------------------------
echo exe is not running. Starting the process...
echo Attempting to upload to RVS
cd /d "%basePath%RVS_V1.0"
Call RVSAutomatedCompanionTool.exe --host="ilmt.igts.ta.philips.com" --port="7001" --user="nlybstqvp4-sys134" --projectname="/IGTs/IGT_System_Automation_COE" --objective="NormCompliance" --resultviewerlink="%1" --testprotocoldocumentids="%2"
echo Attempt to upload to RVS completed

:: Delete lock file
del "%lockFile%"
