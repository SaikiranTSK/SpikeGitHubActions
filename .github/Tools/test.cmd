// 2>nul||@goto :batch
/*
:batch
@ECHO OFF
CLS
set "BATCHFILE=%0"
set LOGTIME=%TIME:~0,8%
set LOGTIME=%LOGTIME::=_%
set LOGTIME=%LOGTIME: =%
set LOGFILE=%temp%\%~n0_%DATE%_%LOGTIME%.log
ECHO Logging can be found at: %LOGFILE% & ECHO Starting script... & call :captureoutput "%~1" "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9">>%LOGFILE% & GOTO:EndOfCommand
:captureoutput
ECHO Start %~n0 %DATE% %TIME%
:::-- find csc.exe
set "csc="
for /r "%SystemRoot%\Microsoft.NET\Framework\" %%# in ("*csc.exe") do  set "csc=%%#"
if not exist "%csc%" (echo no .net framework installed & exit /b 10) & if exist "%temp%\%~n0.exe" del /F /Q "%temp%\%~n0.exe"
if not exist "%temp%\%~n0.exe" (call %csc% /nologo /w:0 /out:"%temp%\%~n0.exe" "%~dpsfnx0" || (exit /b %errorlevel%))
echo Starting: %temp%\%~n0.exe "%BATCHFILE%" "%LOGFILE%" "%~1" "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9" & %temp%\%~n0.exe "%BATCHFILE%" "%LOGFILE%" "%~1" "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9"
if exist "%temp%\%~n0.exe" del /F /Q "%temp%\%~n0.exe"
ECHO End %~n0 %DATE% %TIME%
GOTO:EOF

:EndOfCommand
ECHO Ending script...
GOTO:EOF
*/

using System;
using System.IO;

class Program
{
    private static string _title = "Sample";
    private static string _version = "1.0.0003";
    private static string _initialCreator = "M. Tiellemans";
    private static string _lastChanger = "M. Tiellemans";
    private static string _history = @"
Initial script (max 62 characters)
Updated the default logging
Updated the startup details
";
    private static string _description = "Sample default C# script file";
    private static string _scriptName = "na";
    static void Main(string[] args)
    {
        WriteStartupDetails(args);
        var scriptDir = Path.GetDirectoryName(args[0]);
        var logFile = args[1];
        LogMessage("ScriptDir: " + scriptDir);
        LogMessage("logFile (read only): " + logFile);
        LogMessage("Example");
        File.Copy(logFile, @"d:\" + Path.GetFileName(logFile));
    }

    private static void LogMessage(string message)
    {
        //Both loggings are required to store logging into the logfile and on the screen.
        //this writes the message into the log file (call :captureoutput "%0" "%~1" "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8">>%LOGFILE%).
        Console.WriteLine(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss::") + message);
        //this writes the message into the command window (only errors will be show on the command window and not logged).
        Console.Error.WriteLine(message);
    }
    private static void WriteStartupDetails(string[] args)
    {
        var tmpHistory = _history.Split('\r');
        var history = tmpHistory[tmpHistory.Length - 2].Substring(1);
        history = history.Substring(0, Math.Min(history.Length, 61));
        _scriptName = Path.GetFileName(args[0]);
        _title = _title.Substring(0, Math.Min(_title.Length, 68));
        _version = _version.Substring(0, Math.Min(_version.Length, 66));
        _scriptName = _scriptName.Substring(0, Math.Min(_scriptName.Length, 62));
        _initialCreator = _initialCreator.Substring(0, Math.Min(_initialCreator.Length, 63));
        _lastChanger = _lastChanger.Substring(0, Math.Min(_lastChanger.Length, 58));
        _description = _description.Substring(0, Math.Min(_description.Length, 62));
        Console.Error.WriteLine("###############################################################################");
        Console.Error.WriteLine("#                                                                             #");
        Console.Error.WriteLine("# Title: " + _title.PadRight(68, ' ') + " #");
        Console.Error.WriteLine("# Version: " + _version.PadRight(66, ' ') + " #");
        Console.Error.WriteLine("# Script name: " + _scriptName.PadRight(62, ' ') + " #");
        Console.Error.WriteLine("# Created by: " + _initialCreator.PadRight(63, ' ') + " #");
        Console.Error.WriteLine("#                                                                             #");
        Console.Error.WriteLine("# Last changed by: " + _lastChanger.PadRight(58, ' ') + " #");
        Console.Error.WriteLine("# Last changes: " + history.PadRight(61, ' ') + " #");
        Console.Error.WriteLine("#                                                                             #");
        Console.Error.WriteLine("# Description: " + _description.PadRight(62, ' ') + " #");
        Console.Error.WriteLine("#                                                                             #");
        Console.Error.WriteLine("###############################################################################");
    }
}
