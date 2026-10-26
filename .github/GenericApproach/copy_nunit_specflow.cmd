echo "Clean C:\Temp\FAST\Tests"
RD /S /Q C:\Temp\FAST\Tests

echo "Clean C:\Temp\FAST\Results"
RD /S /Q C:\Temp\FAST\Results

echo "Clean C:\Temp\Tools\SpecflowReporter 2.3.2"
RD /S /Q "C:\Temp\FAST\Tools\SpecFlow.2.3.2"

echo "Clean C:\Temp\Tools\duurtest_*"
RD /S /Q "C:\Temp\Tools\duurtest_*"

echo "Copy SpecflowReporter from repository workspace"
if not exist "%~dp0..\Packages\SpecFlow.2.3.2\specflow.exe" (
  echo [ERROR] Workspace SpecFlow package is missing.
  exit /b 1
)

robocopy "%~dp0..\Packages\SpecFlow.2.3.2" "C:\Temp\FAST\Tools\SpecFlow.2.3.2" /E /IS /W:5 /R:2 /NP
if errorlevel 8 exit /b %ERRORLEVEL%
exit /b 0
