@ECHO OFF
:::-- Prepare the command processor
SETLOCAL
SETLOCAL ENABLEEXTENSIONS
SETLOCAL ENABLEDELAYEDEXPANSION
REM Two empty lines are necessary
set LF=^


REM Two empty lines are necessary
CLS

:::-Check on parameters
IF [%~1]==[] GOTO MISSINGPARAMETER
%~1 %~2 %~3 %~4 %~5 %~6 %~7 %~8 %~9

GOTO:EOF

:MISSINGPARAMETER
	echo "Failed to run command."
	echo "%~n0.cmd c:\temp\test.cmd"
GOTO:EOF