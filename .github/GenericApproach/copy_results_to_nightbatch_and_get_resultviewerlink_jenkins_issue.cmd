@echo on
setlocal EnableExtensions EnableDelayedExpansion

rem ===== arg passthrough (optional) =====

set "var1=D:\\Jenkins\\Tools\\RunAsCurrentUser.exe"
set "var2=D:\\Jenkins\\GenericApproach\\copy_results_to_nightbatch_and_get_resultviewerlink_side_pc.cmd"
set var3=%1
set var4=%var1% "%var2% %var3%"

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
for %%F in ("%TEMP%\side_out_%RANDOM%.log") do set "LOG=%%~fF "
call %SIDE% > "%LOG%" 2>&1
rem call "%SIDE%" %ARG% > "%LOG%" 2>&1
set "RC=%ERRORLEVEL%"

echo DEBUG: LOG=%LOG%
if not exist "%LOG%" 
	echo ERROR: Log file missing

rem ===== robust parse RESULT=<value> from the log =====
set "RESULT="
for /f "usebackq delims=" %%L in (`findstr /i "RESULT=" "%LOG%"`) do (
    set "LINE=%%L"
    rem Extract everything after the first "RESULT="
    for /f "tokens=2* delims==" %%A in ("!LINE:*=RESULT=!") do (
        set "RESULT=%%A"
    )
)

echo DEBUG: RESULT=!RESULT!

rem ===== output for Jenkins/Groovy and exit =====
set "EC=1"

if defined RESULT (
  echo RESULT=!RESULT!
  rem del /q "%LOG%" >nul 2>&1
  set "EC=0"
) else (
  echo [jenkins] ERROR: RESULT= not found in side output. RC=%RC%
  type "%LOG%"
  rem del /q "%LOG%" >nul 2>&1
  echo RESULT=
)

goto :_return

:_return
endlocal & exit /b %EC%