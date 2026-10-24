@echo off
setlocal

set "ctqTestJobName=CriticalToQualityTesting"
set "crtTestJobName=ClinicalResponseTimesTesting"
set "crtElkTestJobName=ClinicalResponseTimesELK"
set "performanceJobName=PerformanceMain"
set "testOutput=C:\Temp\FAST\Results\TestOutput"

if not exist "%testOutput%" mkdir "%testOutput%"

if exist "D:\Collected\Tracing\FAST" (
    robocopy /W:30 /R:100 "D:\Collected\Tracing\FAST" "%testOutput%" "SpecflowLogging.log"
)

if exist "D:\Collected\Tracing\TAF\nunit-agent-x86_*.mdmp" (
    robocopy /W:30 /R:100 /MOV "D:\Collected\Tracing\TAF" "%testOutput%" "nunit-agent-x86_*.mdmp"
)

if exist "D:\Collected\Tracing\FAST" (
    robocopy /W:30 /R:100 /MOV "D:\Collected\Tracing\FAST" "%testOutput%" "SystemFingerPrint.xml"
)

if exist "D:\Collected\Tracing\FAST" if /I "%~1"=="%ctqTestJobName%" (
    robocopy /W:30 /R:100 /MOV "D:\Collected\Tracing\FAST" "%testOutput%" "measurements.xml"
)
if exist "D:\Collected\Tracing\FAST" if /I "%~1"=="%crtTestJobName%" (
    robocopy /W:30 /R:100 /MOV "D:\Collected\Tracing\FAST" "%testOutput%" "measurements.xml"
)
if exist "D:\Collected\Tracing\FAST" if /I "%~1"=="%crtElkTestJobName%" (
    robocopy /W:30 /R:100 /MOV "D:\Collected\Tracing\FAST" "%testOutput%" "measurements.xml"
)
if exist "D:\Collected\Tracing\FAST" if /I "%~1"=="%performanceJobName%" (
    robocopy /W:30 /R:100 /MOV "D:\Collected\Tracing\FAST" "%testOutput%" "measurements.xml"
)

if exist "D:\Collected\Tracing\FAST" (
    robocopy /W:30 /R:100 /MOV "D:\Collected\Tracing\FAST" "%testOutput%" "system-info.xml"
)

echo MainlineTeamTests traces collected into "%testOutput%".
endlocal
exit /b 0
