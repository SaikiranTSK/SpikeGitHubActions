echo "Clean C:\Temp\FAST\Tests"
RD /S /Q C:\Temp\FAST\Tests

echo "Clean C:\Temp\FAST\Results"
RD /S /Q C:\Temp\FAST\Results

echo "Clean C:\Temp\Tools\SpecflowReporter 2.3.2"
RD /S /Q "C:\Temp\FAST\Tools\SpecFlow.2.3.2"

echo "Clean C:\Temp\Tools\duurtest_*"
RD /S /Q "C:\Temp\Tools\duurtest_*"

echo "Copy SpecflowReporter"
robocopy "\\nlybstqvp4dt7nv.code1.emi.philips.com\JenkinsBatches\Packages\SpecFlow.2.3.2" "C:\Temp\FAST\Tools\SpecFlow.2.3.2" /IS /W:30 /R:100 /np
IF %ERRORLEVEL% EQU 1 (
  set "errorlevel=0"  
)
