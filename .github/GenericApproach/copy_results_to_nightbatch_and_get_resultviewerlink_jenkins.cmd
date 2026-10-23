@echo on
setlocal EnableExtensions EnableDelayedExpansion
 
rem ===== arg passthrough (optional) =====
 
set "var1=D:/Jenkins/Tools/RunAsCurrentUser.exe"
set "var2=D:/Jenkins/GenericApproach/copy_results_to_nightbatch_and_get_resultviewerlink_side_pc.cmd"
set "var3=%1"
set "var4=%var1% "%var2% %var3%""
 
echo %var2%
echo %var3%
echo %var4%
 
rem ===== path to the side script =====
set SIDE=%var1% "%var2% %var3%"
 
echo %SIDE%
 
rem ===== sanity check =====
if not exist "%var2%" (
  echo [jenkins] ERROR: Side script not found: "%var2%"
  echo RESULT=
  endlocal & exit /b 3
)
 
rem ===== run side script and capture its output to a temp log =====
for %%F in ("%TEMP%\side_out_%RANDOM%.log") do set "LOG=%%~fF"
echo [jenkins] Executing side_pc script 
call %SIDE% > "%LOG%" 2>&1
set "RC=%ERRORLEVEL%"
 
 
echo DEBUG: LOG=%LOG%
if not exist "%LOG%" echo ERROR: Log file missing
 
rem ===== parse ResultViewerLink=<value> from the log =====
set "ResultViewerLink="
for /f "usebackq tokens=1,* delims==" %%A in (`findstr /i "ResultViewerLink=" "%LOG%"`) do (
    set "ResultViewerLink=%%B"
)

 
echo DEBUG: ResultViewerLink=%ResultViewerLink%
 
rem ===== output for Jenkins/Groovy and exit =====
if defined ResultViewerLink (  
  echo ResultViewerLink=!ResultViewerLink!
  rem del /q "%LOG%" >nul 2>&1
  endlocal & exit /b 0
) else (
  echo [jenkins] ERROR: ResultViewerLink= not found in side output. RC=%RC%
  type "%LOG%"
  rem del /q "%LOG%" >nul 2>&1
  echo ResultViewerLink=
  endlocal & exit /b 1
)