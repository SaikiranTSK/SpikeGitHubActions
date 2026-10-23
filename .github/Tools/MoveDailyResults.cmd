// 2>nul||@goto :batch
/*
:batch
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
SET "_Version=0.0001"&SET "_ChangeDate=20190710"&SET "_Author=Mark Tiellemans"&SET "_LastChange=Initial Version                                       "
SET "_Version=0.0002"&SET "_ChangeDate=20190911"&SET "_Author=Mark Tiellemans"&SET "_LastChange=Nightbatch path updated                               "

SET CURRENTCOMMAND=%0
SET COMMANDONLY=%~n0
SET LOGDIR=%temp%
set LOGTIME=%TIME:~0,8%
set LOGTIME=%LOGTIME::=_%
set LOGTIME=%LOGTIME: =0%
set LOGFILE=%LOGDIR%\%~n0_%DATE%_%LOGTIME%.log
set _NIGHTBATCHPATH=\\rdcemea-t3.storage.philips.com\IGTs_Nightbatch\Nightbatch\%~n0
set _NIGHTBATCHLOGPATH=!_NIGHTBATCHPATH!\%COMPUTERNAME%

SET _Title=
SET _Title=!_Title!###############################################################################!LF!
SET _Title=!_Title!#                                                                             #!LF!
SET _Title=!_Title!# Title: %~n0                                                   #!LF!
SET _Title=!_Title!# Version: !_Version!  Date: !_ChangeDate!                                             #!LF!
SET _Title=!_Title!# Script name: %~n0%~x0                                         #!LF!
SET _Title=!_Title!# Created by: !_InitialCreator!                                                   #!LF!
SET _Title=!_Title!#                                                                             #!LF!
SET _Title=!_Title!# Last changed by: !_Author!                                            #!LF!
SET _Title=!_Title!# Last Changes: !_LastChange!        #!LF!
SET _Title=!_Title!#                                                                             #!LF!
SET _Title=!_Title!# Description: Move the dailypdc content to nightbatch                        #!LF!
SET _Title=!_Title!# Description: Uninstall and Install Sutlib and testscripts from dailypdc     #!LF!
SET _Title=!_Title!#                                                                             #!LF!
SET _Title=!_Title!###############################################################################!LF!

ECHO !_Title!

ECHO Logging can be found at: %LOGFILE%!LF!
ECHO Starting script...
call :captureoutput "%~1" "%~2" "%~3">>%LOGFILE%

goto :EndOfCommand


:captureoutput
ECHO Start %COMMANDONLY% %DATE% %TIME%

:: find csc.exe
set "csc="
for /r "%SystemRoot%\Microsoft.NET\Framework\" %%# in ("*csc.exe") do  set "csc=%%#"

if not exist "%csc%" (
   echo no .net framework installed
   exit /b 10
)

if exist "%temp%\%~n0.exe" del /F /Q "%temp%\%~n0.exe"
if not exist "%temp%\%~n0.exe" (
   call %csc% /nologo /w:0 /out:"%temp%\%~n0.exe" "%~dpsfnx0" || (
      exit /b %errorlevel% 
   )
)
echo Starting: %temp%\%~n0.exe %~dp0 "%~1" "%~2" "%~3"
%temp%\%~n0.exe %~dp0 "%~1" "%~2" "%~3"
if exist "%temp%\%~n0.exe" del /F /Q "%temp%\%~n0.exe"

ECHO End %COMMANDONLY% %DATE% %TIME%
GOTO:EOF

:EndOfCommand

CALL:COPY "%LOGFILE%" "!_NIGHTBATCHLOGPATH!\"
endlocal
exit /B 0

:MISSINGPARAMETER
	echo "Failed to run command."
	echo "%~n0.cmd PDC_Path 21.*.8* NightbatchPath"
    endlocal & exit /b %errorlevel%

:COPY
	IF NOT "%~1"=="" IF NOT "%~2"=="" (
		IF NOT EXIST "%~1" ECHO "File %~1 was NOT Found for copying!"
		IF NOT EXIST "%~2" mkdir %2
		SET _COMMAND=copy %1 /V /Y /Z /B %2
		ECHO !_COMMAND!
		!_COMMAND!
	) ELSE (
		Echo "COPYING: Missing parameter for copying..."
	)
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
    [DllImport("kernel32.dll")]
    static extern bool SetConsoleMode(IntPtr hConsoleHandle, int mode);
    [DllImport("kernel32.dll")]
    static extern bool GetConsoleMode(IntPtr hConsoleHandle, out int mode);
    [DllImport("kernel32.dll")]
    static extern IntPtr GetStdHandle(int handle);

    const int STD_INPUT_HANDLE = -10;
    const int DISABLE_QUICK_EDIT_MODE = 0x0080;
    const int CHECK_QUICK_EDIT = 0x0040;

    private static void Main(string[] args)
    {
        try
        {
            int mode;
            IntPtr handle = GetStdHandle(STD_INPUT_HANDLE);
            GetConsoleMode(handle, out mode);
            SetConsoleMode(handle, mode &= ~CHECK_QUICK_EDIT);
        }
        catch (Exception e) {
            LogMessage("Error setting command window to quick edit mode: " + e.Message + " Trace: " + e.StackTrace);
        }
        try
        {
	        LogMessage("Move daily test results from: d:\\AiT\\DailyPDCTestResults\\ to: d:\\AiT\\DailyPDCTestResultsNightbatch\\");
	        RunCommandAndWait("cmd.exe",@"/C robocopy /E /MOVE D:\AiT\DailyPDCTestResults\. D:\AiT\DailyPDCTestResultsNightbatch\. /TEE /LOG:D:\AiT\DailyPDCTestResultsNightbatch\robocopy.log",36000);
        }
        catch (Exception ex)
        {
            LogMessage("Error while running C#Script: " + ex.Message + " " + ex.StackTrace);
        }
        #if DEBUG
            Console.WriteLine("Debug version");
            Console.ReadKey();
        #endif
    }

    private static void DeleteFolder(string folder)
    {
        LogMessage("Deleting folder: " + folder);
        for (var nr = 1; nr < 3; nr++)
        {
            if (Directory.Exists(folder)) RunCommandAndWait("cmd.exe", "/C rmdir /S /Q \"" + folder + "\"");
            if (Directory.Exists(folder)) continue;
            LogMessage("Deleting folder: " + folder + " passed..");
            return;
        }
        LogMessage("Deleting folder: " + folder + " failed..");
    }

    private static bool CheckImputParameters(string[] args)
    {
        if (args == null)
        {
            LogMessage("Error no input parameters found.");
            return false;
        }
        if (args.Length < 4)
        {
            LogMessage("Error capturing amounth of input parameters (require at least 4). found: " + args.Length);
            return false;
        }
        if (!CheckDirectory(args[1]))
        {
            LogMessage("Directory does not exist: " + args[1]);
            return false;
        }
        try
        {
            if (!Directory.Exists(args[3]))
            {
                Directory.CreateDirectory(args[3]);
                LogMessage("Creating nightbatch path: " + args[3]);
            }
        }
        catch (Exception ex)
        {
            LogMessage("Error creating nightbatch path: " + args[3] + " " + ex.Message + " tracing: " + ex.StackTrace);
        }
        if (!CheckDirectory(args[3]))
        {
            LogMessage("Directory does not exist: " + args[3]);
            return false;
        }
        return true;
    }

    private static bool CheckDirectory(string directory)
    {
        for (int nr = 0; nr < 10; nr++)
        {
            if (Directory.Exists(directory)) return true;
            Thread.Sleep(1000);
        }
        return false;
    }

    private static string FindDailyPdc(string[] args)
    {
        string result = "";
        try
        {
            var sortedDirectories = new DirectoryInfo(args[1]).GetDirectories().OrderByDescending(f => Regex.Replace(f.Name, @"\d+", n => n.Value.PadLeft(9, '0'))).ToList();
            foreach (var directory in sortedDirectories)
            {
                if (IsValideDailyPdc(directory.Name, args[2]))
                {
                    var pdcReady = true;
                    var stopwatch = new Stopwatch();
                    stopwatch.Start();
                    while (directory.GetFiles(".ready*").Length == 0)
                    {
                        Thread.Sleep(5000);
                        LogMessage("waiting for .ready file in: " + directory.Name);
                        if (stopwatch.Elapsed.TotalMinutes >= 10)
                        {
                            pdcReady = false;
                            break;
                        }
                    }
                    stopwatch.Stop();
                    if (pdcReady)
                    {
                        var readyFiles = directory.GetFiles(".ready*");
                        foreach (FileInfo readyFile in readyFiles)
                        {
                            if (readyFile.Name.ToLower().Equals(".ready"))
                            {
                                LogMessage("Found .ready file in: " + directory.Name);
                                return directory.Name;
                            }
                        }
                    }
                    LogMessage("Skipped PDC due to missing .ready file in: " + directory.Name);
                }
            }
        }
        catch (Exception ex)
        {
            LogMessage("Error finding PDC path. " + ex.Message + " Trace:" + ex.StackTrace);
        }
        if (!result.Equals(""))
        {
            LogMessage("Found PDC Path: " + result);
        }
        else
        {
            throw new Exception("Error finding PDC Path");
        }
        return null;
    }

    private static bool IsValideDailyPdc(string pdcNumber, string expression)
    {
		if (expression.Equals("*")) return true;
        if (pdcNumber.Contains(".")) pdcNumber = pdcNumber.Replace(".", ".1");
        if (expression.Contains(".")) expression = expression.Replace(".", ".1");
        if (pdcNumber.Equals(expression)) return true;
        var newExpression = expression.Replace("*", "[0-9]{1,10}");
        var match = Regex.Match(pdcNumber, "^" + newExpression + ".[0-9]{1,10}");
        return match.Success;
    }

    private static void RunCommandAndWait(string command, string arguments, int timeoutInSeconds = 120, int retries = 3)
    {
        for (var nr = 0; nr < retries + 1; nr++)
        {
			var process = new Process();
            var startInfo = new ProcessStartInfo
            {
                WindowStyle = ProcessWindowStyle.Hidden,
                FileName = command,
                RedirectStandardOutput = true,
                UseShellExecute = false,
                Arguments = arguments
            };
            process.StartInfo = startInfo;
            var stopwatch = new Stopwatch();
            stopwatch.Start();
            process.Start();
			string line;
			while ((line = process.StandardOutput.ReadLine()) != null)
			{
				LogMessage(line);
                if (timeoutInSeconds > 0) if (stopwatch.ElapsedMilliseconds >= (timeoutInSeconds * 1000)) break;
                if (process.HasExited) break;
            }
            stopwatch.Stop();
			var returnCode = process.WaitForExit(1000);
            if (!process.HasExited)
            {
                try
                {
                    process.Kill();
                    process.Dispose();
                }
                catch (Exception ex)
                {
                    LogMessage("Killing process failed: " + ex.Message + " Tracing: " + ex.StackTrace);
                }
            }
            if (returnCode) return;
            if (nr <= retries - 1)
            {
                LogMessage("Command failed, retry..");
            }
            else
            {
			    LogMessage("Command failed...");
                return;
            }
        }
    }

    private static void LogMessage(string message)
    {
        Console.WriteLine(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss:: ") + message);
        Console.Error.WriteLine(message);
    }
}