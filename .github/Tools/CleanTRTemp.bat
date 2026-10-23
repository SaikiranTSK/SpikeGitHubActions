@ECHO OFF
SET _MAXAGE=14

CALL:DELETE "C:\Temp\TAF_Test_Runs"
CALL:DELETE "C:\Users\nlybstqvp4-sys134\AppData\Local\Temp\TAF_Test_Runs"

GOTO:EOF

:DELETE
IF EXIST %1 IF %1 NEQ "" (
	ForFiles /D -%_MAXAGE% /P %1 /C "cmd /c IF @isdir == TRUE rd /S /Q @path && echo @path >> c:\temp\deletedtestdata.txt"
)
GOTO:EOF