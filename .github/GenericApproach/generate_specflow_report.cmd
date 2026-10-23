echo on
REM ==========================
REM Input Parameters
REM ==========================
set "nunitVersion=%~1"   REM Pass 2 or 3 when calling

REM Paths
set "OutputXmlPath=C:\Temp\FAST\Results\TestOutput\TestResult.xml"
set "OutputHtmlPath=C:\Temp\FAST\Results\TestOutput\SpecflowReport.html"
set "ProjectPath=C:\Program Files (x86)\FAST\Acceptance.csproj"
set "SpecFlowExe=C:\Temp\FAST\Tools\SpecFlow.2.3.2\specflow.exe"
set "OutputXmlNUnit2=C:\Temp\FAST\Results\TestOutput\TestResult_NUnit2.xml"

echo ==========================
echo NUnit Version: %nunitVersion%
echo ==========================

REM Generate report
if "%nunitVersion%"=="2" (
    echo Generating SpecFlow Report for NUnit 2...
    "%SpecFlowExe%" nunitexecutionreport "%ProjectPath%" /xmlTestResult:"%OutputXmlPath%" /out:"%OutputHtmlPath%"
) else (
    echo Generating LivingDoc Report for NUnit 3...
   "%SpecFlowExe%" nunitexecutionreport "%ProjectPath%" /xmlTestResult:"%OutputXmlNUnit2%" /out:"%OutputHtmlPath%"
   if exist "%OutputXmlNUnit2%" (
        del /f /q "%OutputXmlNUnit2%"
    )
)
