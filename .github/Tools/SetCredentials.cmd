// 2>nul||@goto :batch
/*
:batch
@ECHO OFF
CLS
set LOGTIME=%TIME:~0,8%
set LOGTIME=%LOGTIME::=_%
set LOGTIME=%LOGTIME: =%
set LOGFILE=%temp%\%~n0_%DATE%_%LOGTIME%.log
ECHO Logging can be found at: %LOGFILE% & ECHO Starting script... & call :captureoutput "%0" "%~1" "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8">>%LOGFILE% & GOTO:EndOfCommand
:captureoutput
ECHO Start %~n0 %DATE% %TIME%
:::-- find csc.exe
set "csc="
for /r "%SystemRoot%\Microsoft.NET\Framework\" %%# in ("*csc.exe") do  set "csc=%%#"
if not exist "%csc%" (echo no .net framework installed & exit /b 10) & if exist "%temp%\%~n0.exe" del /F /Q "%temp%\%~n0.exe"
if not exist "%temp%\%~n0.exe" (call %csc% /nologo /w:0 /out:"%temp%\%~n0.exe" "%~dpsfnx0" || (exit /b %errorlevel%))
echo Starting: %temp%\%~n0.exe "%~1" "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9" & %temp%\%~n0.exe "%~1" "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9"
if exist "%temp%\%~n0.exe" del /F /Q "%temp%\%~n0.exe"
ECHO End %~n0 %DATE% %TIME%
GOTO:EOF

:EndOfCommand
ECHO Ending script...
GOTO:EOF
*/

using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Threading;
using System.Runtime.InteropServices;
using System.Text.RegularExpressions;

class QE
{
    private static System.Diagnostics.Process process = new System.Diagnostics.Process();
    private static System.Diagnostics.ProcessStartInfo startInfo = new System.Diagnostics.ProcessStartInfo();

    private static void Main(string[] args)
    {
	SetCredentials("192.68.32.1");
	SetCredentials("192.68.32.2");
	SetCredentials("192.68.32.9");
	SetCredentials("192.68.32.11");
	SetCredentials("192.68.32.13");
	SetCredentials("192.68.32.14");
	SetCredentials("192.68.32.15");
    }

    private static void SetCredentials(string ip)
    {
	string command = "net use \\\\" + ip + " /delete";
	LogMessage("Start: " + command); RunProcess(command);
	command = "cmdkey /delete:" + ip;
	LogMessage("Start: " + command); RunProcess(command);
	command = "cmdkey /add:" + ip;
	LogMessage("Start: " + command); RunProcess(command + " /user:PHDataUser /pass:#fP4w$0s$bH4W.!");
    }

    private static void RunProcess(string command)
    {
	startInfo.WindowStyle = System.Diagnostics.ProcessWindowStyle.Hidden;
	startInfo.RedirectStandardInput = true;
	startInfo.RedirectStandardOutput = true;
	startInfo.UseShellExecute = false;
	startInfo.FileName = "cmd.exe";
	startInfo.Arguments = "/C " + command;
	process.StartInfo = startInfo;
	process.Start();
	LogMessage(process.StandardOutput.ReadToEnd());
    }

    private static void LogMessage(string message)
    {
        Console.WriteLine(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss::") + message);
        Console.Error.WriteLine(message);
    }
}