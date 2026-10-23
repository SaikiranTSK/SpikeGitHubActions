echo on
echo %1

set ctqTestJobName=CriticalToQualityTesting
set crtTestJobName=ClinicalResponseTimesTesting
set crtElkTestJobName=ClinicalResponseTimesELK
set performanceJobName=PerformanceMain 

Setlocal EnableDelayedExpansion
set "yourDir=D:\Collected\Tracing\FAST\"
set "yourExt=pdcVersion"
pushd %yourDir%
for %%a in (*.%yourExt%) do set pdcVersion=%%~na
popd

echo "Copy SpecflowLogging to C:\Temp\Fast"
robocopy /W:30 /R:100 "D:\Collected\Tracing\FAST" "C:\Temp\FAST\Results\TestOutput" "SpecflowLogging.log"

if exist "D:\Collected\Tracing\TAF\nunit-agent-x86_*.mdmp" (
  echo "Move (so this file won't be available for the next run) NUnit minidump to C:\Temp\Fast"
  robocopy /W:30 /R:100 /MOV "D:\Collected\Tracing\TAF" "C:\Temp\FAST\Results\TestOutput" "nunit-agent-x86_*.mdmp"
)

echo "Move (so this file won't be available for the next run) SystemFingerPrint to C:\Temp\Fast"
robocopy /W:30 /R:100 /MOV "D:\Collected\Tracing\FAST" "C:\Temp\FAST\Results\TestOutput" "SystemFingerPrint.xml"

if %1==%ctqTestJobName% (
  echo "Move (so this file won't be available for the next run) measurements.xml to C:\Temp\Fast"
  robocopy /W:30 /R:100 /MOV "D:\Collected\Tracing\FAST" "C:\Temp\FAST\Results\TestOutput" "measurements.xml"
)

if %1==%crtTestJobName% (
  echo "Move (so this file won't be available for the next run) measurements.xml to C:\Temp\Fast"
  robocopy /W:30 /R:100 /MOV "D:\Collected\Tracing\FAST" "C:\Temp\FAST\Results\TestOutput" "measurements.xml"
)

if %1==%crtElkTestJobName% (
  echo "Move (so this file won't be available for the next run) measurements.xml to C:\Temp\Fast"
  robocopy /W:30 /R:100 /MOV "D:\Collected\Tracing\FAST" "C:\Temp\FAST\Results\TestOutput" "measurements.xml"
)

if %1==%performanceJobName% (
  echo "Move (so this file won't be available for the next run) measurements.xml to C:\Temp\Fast"
  robocopy /W:30 /R:100 /MOV "D:\Collected\Tracing\FAST" "C:\Temp\FAST\Results\TestOutput" "measurements.xml"
)

echo "Move (so this file won't be available for the next run) system-info.xml to C:\Temp\Fast"
robocopy /W:30 /R:100 /MOV "D:\Collected\Tracing\FAST" "C:\Temp\FAST\Results\TestOutput" "system-info.xml"

set sutName = %TAF_SUT_NAME%

for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "YY=%dt:~2,2%" & set "YYYY=%dt:~0,4%" & set "MM=%dt:~4,2%" & set "DD=%dt:~6,2%"
set "HH=%dt:~8,2%" & set "Min=%dt:~10,2%" & set "Sec=%dt:~12,2%"

set "datestamp=%YYYY%%MM%%DD%" & set "timestamp=%HH%%Min%%Sec%"
set "fullstamp=%YYYY%-%MM%-%DD%_%HH%-%Min%-%Sec%"
set "batchName=%1"
set "PathToShare=\\code1.emi.philips.com\storage\IGTs_Nightbatch\Nightbatch\FAST\%TAF_SUT_NAME%\"
set "PathToShareWithSutAndPDC=%PathToShare%%pdcVersion%\"
set "ResultViewerURL=http://igts-resultviewer.ta.philips.com/#/testrun/"

if /I "%batchName:Main=%" NEQ "%batchName%" (
    set "fileName=MainlineTeamTests_%batchName:Main=%_%fullstamp%"
) else (
    set "fileName=%batchName%_%fullstamp%"
)
echo ===========================
echo Batch Name : %batchName%
echo File Name  : %fileName%
echo ===========================
set "FullPathWithDateAndBatch=%PathToShareWithSutAndPDC%%fileName%"
set "URLExtension=%TAF_SUT_NAME%/%pdcVersion%/%fileName%"

echo %FullPathWithDateAndBatch%

mkdir %FullPathWithDateAndBatch%

CALL:COPY "Report to NightBatch" "C:\Temp\FAST\Results" "%FullPathWithDateAndBatch%"
echo "Find the report at {[ %FullPathWithDateAndBatch% ]}"

echo [InternetShortcut] >"%FullPathWithDateAndBatch%\LinkToResultViewer.url"
echo URL=%ResultViewerURL%%URLExtension% >>"%FullPathWithDateAndBatch%\LinkToResultViewer.url"

endlocal
GOTO:EOF

:COPY
echo "Copy %~1"
robocopy "%~2" "%~3" /V /NP /MIR /W:30 /R:100
IF %ERRORLEVEL% EQU 1 (
  set "errorlevel=0"  
)
GOTO:EOF
