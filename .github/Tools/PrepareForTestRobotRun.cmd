Taskkill.exe /IM TAF.exe
Tskill.exe TAF.exe
Taskkill.exe /F /IM TAF.exe
Tskill.exe /A TAF.exe

Taskkill.exe /IM TestRobot.exe
Tskill.exe TestRobot.exe
Taskkill.exe /F /IM TestRobot.exe
Tskill.exe /A TestRobot.exe

Taskkill.exe /F /IM tafScriptrunner.exe
Tskill.exe /A tafScriptrunner.exe
Taskkill.exe /F /IM TAFTafFVAdapterCSExeCOMServer.exe
Tskill.exe /A TAFTafFVAdapterCSExeCOMServer.exe
Taskkill.exe /F /IM TAFControllerService.exe
Tskill.exe /A TAFControllerService.exe
c:\temp\Tools\sleep 3
::clean up tracing
if EXIST c:\temp\taf.xml.txt Copy /b /y c:\temp\taf.xml.txt+c:\temp\taf.xml c:\temp\taf.xml.tmp
if NOT EXIST c:\temp\taf.xml.txt Copy c:\temp\taf.xml c:\temp\taf.xml.tmp
del c:\temp\taf.xml.txt
del c:\temp\taf.xml
ren c:\temp\taf.xml.tmp taf.xml.txt
if EXIST c:\temp\TAFScriptRunner.xml.txt Copy /b /y c:\temp\TAFScriptRunner.xml.txt+c:\temp\TAFScriptRunner.xml c:\temp\TAFScriptRunner.xml.tmp
if NOT EXIST c:\temp\TAFScriptRunner.xml.txt Copy c:\temp\TAFScriptRunner.xml c:\temp\TAFScriptRunner.xml.tmp
del c:\temp\TAFScriptRunner.xml
del c:\temp\TAFScriptRunner.xml.txt
ren c:\temp\TAFScriptRunner.xml.tmp TAFScriptRunner.xml.txt
