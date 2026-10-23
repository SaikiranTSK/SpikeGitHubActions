@ECHO OFF
:::-- Prepare the command processor
SETLOCAL
SETLOCAL ENABLEEXTENSIONS
SETLOCAL ENABLEDELAYEDEXPANSION
REM Two empty lines are necessary
set LF=^


REM Two empty lines are necessary
CLS

SET "_InitialCreator=M. Tiellemans"
:::-- History
:::-- Version               ChangeDate YYYYMMDD        Author                        LastChange
SET "_Version=0.0001"&SET "_ChangeDate=20171130"&SET "_Author=Mark Tiellemans"&SET "_LastChange=Initial Version                                       "


SET _Title=
SET _Title=!_Title!###############################################################################!LF!
SET _Title=!_Title!#                                                                             #!LF!
SET _Title=!_Title!# Title: %~n0                                                           #!LF!
SET _Title=!_Title!# Version: !_Version!  Date: !_ChangeDate!                                             #!LF!
SET _Title=!_Title!# Script name: %~n0%~x0                                                 #!LF!
SET _Title=!_Title!# Created by: !_InitialCreator!                                                   #!LF!
SET _Title=!_Title!#                                                                             #!LF!
SET _Title=!_Title!# Last changed by: !_Author!                                            #!LF!
SET _Title=!_Title!# Last Changes: !_LastChange!        #!LF!
SET _Title=!_Title!#                                                                             #!LF!
SET _Title=!_Title!# Description: Set System sut name for TAF and TestRobot                      #!LF!
SET _Title=!_Title!#                                                                             #!LF!
SET _Title=!_Title!###############################################################################!LF!



ECHO !_Title!
ECHO.

::###############################################################################
::#                                                                             #
::#              E N V I R O M E N T A L  V A R I A B L E S                     #
::#                                                                             #
::###############################################################################
SET _LOCALPATH=%TEMP%
CALL:SETLOGFILE %_LOCALPATH%

:::-Check on parameters
IF [%1]==[] GOTO MISSINGPARAMETER
CALL:SETVARANDLOG "_SCHEDULERTOOLSPATH=%~dp0"


::###############################################################################
::#                                                                             #
::#                           S T A R T  S C R I P T                            #
::#                                                                             #
::###############################################################################

echo off
!_SCHEDULERTOOLSPATH!psexec -h setx TAF_SUT_NAME "%~1" /M
GOTO:EOF

:DEBUGANDLOG
	IF NOT "%~1"=="" (
		CALL:GETDATETIME
		ECHO !_yyyy!-!_mm!-!_dd! !_hour!:!_minute! %~1
		IF NOT "%_LOGFILE%"=="" (
			ECHO !_yyyy!-!_mm!-!_dd! !_hour!:!_minute! %~1 >> !_LOGFILE!
		)
	)	
GOTO:EOF

:SETVARANDLOG
	IF NOT "%~1"=="" (
		CALL:DEBUGANDLOG "!_yyyy!-!_mm!-!_dd! !_hour!:!_minute! SET %~1"
		SET %1
	)
GOTO:EOF

:GETDATETIME
:: Use WMIC to retrieve date and time
FOR /F "skip=1 tokens=1-6" %%G IN ('WMIC Path Win32_LocalTime Get Day^,Hour^,Minute^,Month^,Second^,Year /Format:table') DO (
	IF "%%~L"=="" (
		:: Pad digits with leading zeros
		Set _mm=!_mm:~-2!
		Set _dd=!_dd:~-2!
		Set _hour=!_hour:~-2!
		Set _minute=!_minute:~-2!
		GOTO:EOF
   )
	Set _yyyy=%%L
	Set _mm=00%%J
	Set _dd=00%%G
	Set _hour=00%%H
	SET _minute=00%%I
)
GOTO:EOF

:SETLOGFILE
CALL:GETDATETIME
SET "_LOGFILE=%~1\%~n0!_yyyy!!_mm!!_dd!!_hour!!_minute!.log"
GOTO:EOF

:KILLTASK
	IF NOT "%~1"=="" (
		SET _COMMAND=taskkill.exe /IM %~1
		CALL:DEBUGANDLOG "KILLTASK: !_COMMAND!
		!_COMMAND! >> !_LOGFILE! 2>&1
		SET _COMMAND=taskkill.exe /F /IM %~1
		CALL:DEBUGANDLOG "KILLTASK: !_COMMAND!
		!_COMMAND! >> !_LOGFILE! 2>&1
		SET _COMMAND=tskill.exe %~1
		CALL:DEBUGANDLOG "KILLTASK: !_COMMAND!
		!_COMMAND! >> !_LOGFILE! 2>&1
		SET _COMMAND=tskill.exe /A %~1
		CALL:DEBUGANDLOG "KILLTASK: !_COMMAND!
		!_COMMAND! >> !_LOGFILE! 2>&1
		ECHO.
	) ELSE (
		CALL:DEBUGANDLOG "Missing parameter for KILLTASK"
	)
GOTO:EOF

:MISSINGPARAMETER
	CALL:DEBUGANDLOG "Failed to start %~n0."
	CALL:DEBUGANDLOG "ERROR: One or more missing parameters."
	ECHO Usage: %~n0%~x0 "SystemName"