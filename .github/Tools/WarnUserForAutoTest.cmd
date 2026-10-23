:: check if a TAF batch is running
SET ABORTTEST=NO
set schedulertoolspath=%~dp0
call %schedulertoolspath%\CheckIfTafOrTestRobotIsExecutingATest.exe
IF %ERRORLEVEL%==0 (
echo Taf batch running abort scheduled test
GOTO ABORT
)
:LOOP
@echo off
TITLE Starting scheduled test

::show wait menu
cls
color C0
ECHO -------------------------------------------------------------------------------
ECHO An automatic test will start within 5 minutes
ECHO For more information contact Mark Tiellemans or Marcel van Veggel
ECHO if needed select an action or wait till the test is started automatically
ECHO -------------------------------------------------------------------------------

ECHO 0 - Start automatic test now (default)
ECHO 1 - Delay This test for 10 minutes
ECHO 2 - Delay This test for 30 minutes
ECHO 3 - Delay This test for 1 hour
ECHO 4 - Delay This test for 2 hour
ECHO 5 - Delay This test for 3 hour
ECHO 6 - Delay This test for 4 hour
ECHO 7 - Delay This test for 6 hour
ECHO 8 - Delay This test for 8 hour
ECHO 9 - Delay This test for 10 hour
ECHO A - Delay This test for 12 hour
ECHO B - Delay This test for 24 hour
ECHO C - Delay This test for 48 hour
ECHO D - Abort this test

rem Choice /C 0123456789abc /M "Wait 5 minutes to start or select a Delay period" /T 10 /D 0
start /wait /min %schedulertoolspath%\SetMaxVol.exe
Start /min %schedulertoolspath%\PlaySound.exe

Choice /C 0123456789abcd /M "Wait 5 minutes to start or select a Delay period" /T 300 /D 0
GOTO %ERRORLEVEL%

:1
SET WaitTime=0
GOTO NOWAIT
:2
SET WaitTime=10
GOTO end
:3
SET WaitTime=30
GOTO end
:4
SET WaitTime=60
GOTO end
:5
SET WaitTime=120
GOTO end
:6
SET WaitTime=180
GOTO end
:7
SET WaitTime=240
GOTO end
:8
SET WaitTime=360
GOTO end
:9
SET WaitTime=480
GOTO end
:10
SET WaitTime=600
GOTO end
:11
SET WaitTime=720
GOTO end
:12
SET WaitTime=1440
GOTO end
:13
SET WaitTime=2880
GOTO end
:14
:ABORT
taskkill.exe /F /IM PlaySound.exe
del %2\Status\%1_JobStart.txt
move %schedulertoolspath%\..\Executing\%1 %2\done\
echo %1>%2\Status\%1_JobReady.txt
exit 8
:end
taskkill.exe /F /IM PlaySound.exe
color 47
cls
Echo Automatic test is delayed for %WaitTime% Minutes, delay started on:
date /t
time /t
::log paused

SET /A WaitTime=%WaitTime% * 60
call %schedulertoolspath%\sleep.exe %WaitTime%
GOTO LOOP

:NOWAIT
color C0
taskkill.exe /F /IM PlaySound.exe
cls
@echo on


