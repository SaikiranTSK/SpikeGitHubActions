echo off
setlocal

echo %1
echo %2
echo basePath=%3
echo selectedJobandSystemName=%4

set "basePath=%~3"
set "jobAndSystem=%~4"

set "lockFile=%TEMP%\RVSAutomatedCompanionTool.lock"

rem ----------- WAIT WITH 5-MINUTE MESSAGE LOGIC -------------
set "printedWaitMsg=0"
set "waitCounter=0"

:WAIT_LOOP
if not exist "%lockFile%" goto LOCK_FREE

rem Print the first wait message only once
if "%printedWaitMsg%"=="0" (
    echo Another process is running... waiting
    set "printedWaitMsg=1"
) else (
    rem Print every 5 minutes
    if %waitCounter% GEQ 60 (
       echo Still waiting for other process to complete...
       set "waitCounter=0"
    )
)    

rem Wait 5 seconds
ping 127.0.0.1 -n 6 >nul
set /a waitCounter+=1
goto WAIT_LOOP 
	
:LOCK_FREE

rem ----------- END WAIT LOGIC -------------

:: Create lock file
echo Locked > "%lockFile%"

rem Get datetime in a reliable format
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set dt=%%a
set "YYYY=%dt:~0,4%" & set "MM=%dt:~4,2%" & set "DD=%dt:~6,2%"
set "HH=%dt:~8,2%" & set "Min=%dt:~10,2%" & set "Sec=%dt:~12,2%"

rem Desired timestamp format
set "fullstamp=%YYYY%-%MM%-%DD%_%HH%-%Min%-%Sec%"
echo Current timestamp: %fullstamp%

set "logFileName=%jobAndSystem%_%fullstamp%.log"
echo Log FileName: %logFileName%

rem Convert forward slashes to backslashes (important!)
set "basePath=%basePath:/=\%"

rem Final log filename: Job_Machine_Timestamp.log
set "logfilePath=%basePath%RVS_V1.0\Logs\%jobAndSystem%_%fullstamp%.log"
echo Log filePath will be: %logfilePath%

echo Process is not running. Proceeding to execute RVSAutomatedCompanionTool.exe...
echo Attempting to upload to RVS
cd /d "%basePath%RVS_V1.0"

Call RVSAutomatedCompanionTool.exe --host="%5" --port="%6" --user="nlybstqvp4-sys134" --projectname="/IGTs/IGT_System_Automation_COE" --objective="NormCompliance" --resultviewerlink="%1" --testprotocoldocumentids="%2" --LogFileName="%logFileName%"
echo Attempt to upload to RVS completed

rem Print the log to Jenkins console
echo -------------------------------------------------
echo Printing log to console:
if exist "%logfilePath%" (
    type "%logfilePath%"
) else (
    echo Log file not found: "%logfilePath%"
)
echo -------------------------------------------------

:: Delete lock file
del "%lockFile%"