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
SET "_Version=0.0001"&SET "_ChangeDate=20180410"&SET "_Author=Mark Tiellemans"&SET "_LastChange=Initial Version                                       "
SET "_Version=0.0002"&SET "_ChangeDate=20190131"&SET "_Author=Mark Tiellemans"&SET "_LastChange=After run failure, kill process before retry.         "
SET "_Version=0.0003"&SET "_ChangeDate=20190201"&SET "_Author=Mark Tiellemans"&SET "_LastChange=Kill process tree based on PID, fixed DAILYSUTLIB     "
SET "_Version=0.0004"&SET "_ChangeDate=20190911"&SET "_Author=Mark Tiellemans"&SET "_LastChange=Updated nightbatch path                               "

SET CURRENTCOMMAND=%0
SET COMMANDONLY=%~n0
SET LOGDIR=%temp%
set LOGTIME=%TIME:~0,8%
set LOGTIME=%LOGTIME::=_%
set LOGTIME=%LOGTIME: =0%
set LOGFILE=%LOGDIR%\%COMMANDONLY%_%1_%DATE%_%LOGTIME%.log
set _NIGHTBATCHPATH=\\rdcemea-t3.storage.philips.com\IGTs_Nightbatch\Nightbatch\%COMMANDONLY%
set _NIGHTBATCHLOGPATH=!_NIGHTBATCHPATH!\%COMPUTERNAME%

SET _Title=
SET _Title=!_Title!###############################################################################!LF!
SET _Title=!_Title!#                                                                             #!LF!
SET _Title=!_Title!# Title: %~n0                                                     #!LF!
SET _Title=!_Title!# Version: !_Version!  Date: !_ChangeDate!                                             #!LF!
SET _Title=!_Title!# Script name: %~n0%~x0                                           #!LF!
SET _Title=!_Title!# Created by: !_InitialCreator!                                                   #!LF!
SET _Title=!_Title!#                                                                             #!LF!
SET _Title=!_Title!# Last changed by: !_Author!                                            #!LF!
SET _Title=!_Title!# Last Changes: !_LastChange!        #!LF!
SET _Title=!_Title!#                                                                             #!LF!
SET _Title=!_Title!# Description: Uninstall and Install TAF,TestRobot,Sutlib,Testscripts.        #!LF!
SET _Title=!_Title!#                                                                             #!LF!
SET _Title=!_Title!###############################################################################!LF!

ECHO !_Title!

:::-Check on parameters
IF [%1]==[] GOTO MISSINGPARAMETER
IF [%2]==[] GOTO MISSINGPARAMETER

IF ["%~1"]==["DAILYSUTLIB"] (
    IF [%3]==[] GOTO MISSINGPARAMETER
  echo "DAILYSUTLIB"
)

ECHO Installation type: %~1
ECHO MSIPath or DirectoryPath: %~2
ECHO Optional PDC Path: %~3!LF!
ECHO Logging can be found at: %LOGFILE%!LF!
ECHO Starting script...
call :captureoutput "%~1" "%~2" "%~3">>%LOGFILE%

goto :EndOfCommand


:captureoutput
ECHO Start %COMMANDONLY% %DATE% %TIME%
net.exe session 1>NUL 2>NUL || (Echo This script has run without elevated rights)

:: find csc.exe
set "csc="
for /r "%SystemRoot%\Microsoft.NET\Framework\" %%# in ("*csc.exe") do  set "csc=%%#"

if not exist "%csc%" (
   echo no .net framework installed
   exit /b 10
)

if not exist "%temp%\%~n0.exe" (
   call %csc% /nologo /w:0 /out:"%temp%\%~n0.exe" "%~dpsfnx0" || (
      exit /b %errorlevel% 
   )
)
%temp%\%~n0.exe "%~1" "%~2" "%~3"
if exist "%temp%\%~n0.exe" del /F /Q "%temp%\%~n0.exe"

ECHO End %COMMANDONLY% %DATE% %TIME%
GOTO:EOF

:EndOfCommand

CALL:COPY "%LOGFILE%" "!_NIGHTBATCHLOGPATH!\"
endlocal
exit /B 0

:MISSINGPARAMETER
	echo "Failed to run command."
	echo "For Taf: %~n0.cmd TAF MSIInstallPackageLocation"
	echo "For TestRobot: %~n0.cmd TESTROBOT MSIInstallPackageLocation"
	echo "For SutLibrary: %~n0.cmd SUTLIB MSIInstallPackageLocation"
	echo "For TestScripts: %~n0.cmd TESTSCRIPTS MSIInstallPackageLocation"
	echo "For Daily SutLibrary: %~n0.cmd DAILYSUTLIB MSIInstallPackageLocationPath PDCPATH"
	echo "For Daily TestScripts: %~n0.cmd DAILYTESTSCRIPTS MSIInstallPackageLocationPath"
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
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Threading;
using Microsoft.Win32;


class QE
{
    const string Regkey = @"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall";
    static void Main(string[] args)
    {
        try
        {
            if (CheckImputParameters(args) == false) return;
            var programToInstall = args[0].ToUpper();
            var msiToInstall = args[1];
            var installedPrograms = GetInstalledProgramList(Regkey);
            //Uninstallation pre steps..
            KillTafAndTestRobot();
            foreach (var installedProgram in installedPrograms)
            {
                switch (programToInstall)
                {
                    case "TAF":
                        Uninstall(installedProgram, "taf ");
                        break;
                    case "TESTROBOT":
                        Uninstall(installedProgram, "testrobot");
                        break;
                    case "SUTLIB":
                        Uninstall(installedProgram, "sutkeywordlibrary ");
                        break;
                    case "TESTSCRIPTS":
                        Uninstall(installedProgram, "taftestscripts ");
                        break;
                    case "DAILYSUTLIB":
                        Uninstall(installedProgram, "sutkeywordlibrary ");
                        break;
                    case "DAILYTESTSCRIPTS":
                        Uninstall(installedProgram, "taftestscripts ");
                        break;
                }
            }
            //Uninstallation post steps
            switch (programToInstall)
            {
                case "TAF":
                    DeleteFolder("C:\\Program Files (x86)\\Taf");
                    break;
                case "TESTROBOT":
                    DeleteFolder("C:\\Program Files (x86)\\Philips\\TestRobot");
                    break;
                case "SUTLIB":
                    DeleteFolder("C:\\Program Files (x86)\\TAF_SUTKeywordLibrary");
                    break;
                case "TESTSCRIPTS":
                    DeleteFolder("C:\\Program Files (x86)\\TAF_TestScripts");
                    break;
                case "DAILYSUTLIB":
                    DeleteFolder("C:\\Program Files (x86)\\TAF_SUTKeywordLibrary");
                    break;
                case "DAILYTESTSCRIPTS":
                    DeleteFolder("C:\\Program Files (x86)\\TAF_TestScripts");
                    break;
            }
            //Uncheck case(til break) for extra msi logging
            switch (programToInstall)
            {
                //case "SUTLIB":
                //    InstallAndLog(msiToInstall);
                //    break;
                //case "DAILYSUTLIB":
                //    InstallAndLog(msiToInstall);
                //    break;
                default:
                    Install(msiToInstall);
                    break;
            }
            //After installation post steps
            switch (programToInstall)
            {
                case "TAF":
                    LogMessage("Starting TAF");
                    RunCommandAndWait("C:\\Program Files (x86)\\Taf\\taf.exe", "", 10, 1);
                    KillTafAndTestRobot();
                    break;
                case "TESTROBOT":
                    LogMessage("Adding registry settings for excel");
                    RunCommandAndWait("reg.exe",
                        "add \"HKCU\\Software\\Microsoft\\Office\\14.0\\Excel\\Security\\Trusted Locations\\Location99\" /v Path /t REG_SZ /d \"C:\\Program Files (x86)\\Philips\\TestRobot\\templates\" /f");
                    RunCommandAndWait("reg.exe",
                        "add \"HKCU\\Software\\Microsoft\\Office\\14.0\\Excel\\Security\\Trusted Locations\\Location99\" /v Description /t REG_SZ /d \"Required for TestRobot\" /f");
                    LogMessage("Starting TestRobot");
                    RunCommandAndWait("C:\\Program Files (x86)\\Philips\\TestRobot\\testrobot.exe", "", 10, 1);
                    KillTafAndTestRobot();
                    break;
                case "SUTLIB":
                    break;
                case "TESTSCRIPTS":
                    break;
            }
        }
        catch (Exception ex)
        {
            LogMessage("Error while running C#Script: " + ex.Message + " " + ex.StackTrace);
        }
    }

    static void KillTafAndTestRobot()
    {
        LogMessage("Stopping TestRobot and TAF.");
        EndTask("taf");
        EndTask("TestRobot.exe");
        EndTask("TAFControllerService.exe");
        EndTask("TAFScriptRunner.exe");
        EndTask("TAFTafFVAdapterCSExeCOMServer.exe");
        EndTask("TAFControllerService.exe");
    }

    static void DeleteFolder(string folder)
    {
        LogMessage("Deleting folder: " + folder);
        if (Directory.Exists(folder)) RunCommandAndWait("cmd.exe", "/C rmdir /S /Q \"" + folder + "\"");
        if (Directory.Exists(folder))
        {
            LogMessage("Deleting folder: " + folder + " failed..");
        }
        else
        {
            LogMessage("Deleting folder: " + folder + " passed..");
        }
    }

    static bool CheckImputParameters(string[] args)
    {
        if (args == null)
        {
            LogMessage("Error no input parameters found.");
            return false;
        }
        if (args.Length < 2)
        {
            LogMessage("Error capturing amounth of input parameters (require at least 2).");
            return false;
        }
        args[0] = args[0].Trim('"');
        args[1] = args[1].Trim('"');
        var msiFile = "";
        switch (args[0].ToUpper())
        {
            case "TESTROBOT":
                msiFile = args[1];
                break;
            case "TAF":
                msiFile = args[1];
                break;
            case "SUTLIB":
                msiFile = args[1];
                break;
            case "TESTSCRIPTS":
                msiFile = args[1];
                break;
            case "DAILYSUTLIB":
                if (args.Length < 3)
                {
                    LogMessage("Error capturing amounth of input parameters (require at least 3).");
                    return false;
                }
                args[2] = args[2].Trim('"');
                if (CheckDirectory(args[1]) && CheckDirectory(args[2]))
                {
                    var sortedDirectories = new DirectoryInfo(args[1]).GetDirectories()
                                                      .OrderBy(f => f.CreationTime)
                                                      .ToList();
                    msiFile = sortedDirectories.Last().FullName + @"\Install\SpecialPackages\SUTKeywordLibrary.msi";
                    args[1] = msiFile + "\" PDCSOURCEDIR=\"" + args[2];
                    LogMessage("Found msiFile: " + msiFile);
                }
                else
                {
                    LogMessage("Installation aborted");
                    return false;
                }
                break;
            case "DAILYTESTSCRIPTS":
                if (CheckDirectory(args[1]))
                {
                    var sortedDirectories = new DirectoryInfo(args[1]).GetDirectories().OrderBy(f => f.CreationTime).ToList();
                    msiFile = sortedDirectories.Last().FullName + @"\Install\TestSystemsInstall\TAFTestScripts\TAFTestScripts.msi";
                    args[1] = msiFile;
                    LogMessage("Found msiFile: " + msiFile);
                }
                else
                {
                    LogMessage("Installation aborted");
                    return false;
                }
                break;
            default:
                LogMessage("Supported input parameters are: TAF, TESTROBOT, SUTLIB, TESTSCRIPTS, DAILYSUTLIB, DAILYTESTSCRIPTS");
                return false;
        }

        for (int nr = 0; nr < 10; nr++)
        {
            if (File.Exists(msiFile)) return true;
            Thread.Sleep(1000);
        }
        LogMessage("MSI Path could not be found: " + msiFile);
        return false;
    }

    static bool CheckDirectory(string directory)
    {
        for (int nr = 0; nr < 10; nr++)
        {
            if (Directory.Exists(directory)) return true;
            Thread.Sleep(1000);
        }
        LogMessage("Input parameter check failed, path not exist: " + directory);
        return false;
    }

    static void Install(string msi)
    {
        var arguments = "/QN /I \"" + msi + "\"";
        LogMessage("Installing: msiexec.exe arguments: " + arguments);
        RunCommandAndWait("msiexec.exe", arguments, 180, 3);
    }

    static void InstallAndLog(string msi)
    {
        var logPath = @"c:\temp\msilog.log";
        if (File.Exists(logPath)) File.Delete(logPath);
        var arguments = "/QN /I \"" + msi + "\" /L*v \"" + logPath + "\"";
        LogMessage("Installing: msiexec.exe arguments: " + arguments);
        RunCommandAndWait("msiexec.exe", arguments, 180, 3);
        if (File.Exists(logPath))
        {
            LogMessage(File.ReadAllText(logPath));
            File.Delete(logPath);
        } else {
            LogMessage("Logfile: " + logPath + " was not created");
        }
    }

    static void Uninstall(KeyValuePair<string, string> program, string value)
    {
        if (program.Key.ToLower().Contains(value))
        {
            var command = "";
            var arguments = "";
            if (program.Value.Contains(" "))
            {
                command = program.Value.Substring(0, program.Value.IndexOf(" "));
                arguments = program.Value.Substring(program.Value.IndexOf(" ") + 1);
                if (command.ToLower().Equals("msiexec.exe")) arguments = "/QN /X" + arguments.Substring(2);
            }
            else
            {
                command = program.Value;
            }
            LogMessage("Uninstalling: " + program.Key + " with: " + command + " arguments: " + arguments);
            RunCommandAndWait(command, arguments);
            CheckUninstalled(program);
        }
    }

    static bool CheckUninstalled(KeyValuePair<string, string> program)
    {
        var installedPrograms = GetInstalledProgramList(Regkey);
        if (installedPrograms.ContainsKey(program.Key))
        {
            LogMessage("Uninstallation of: " + program.Key + " failed..");
            return false;
        }
        else
        {
            LogMessage("Uninstallation of: " + program.Key + " passed..");
        }
        return true;
    }

    static void RunCommandAndWait(string command, string arguments, int timeoutInSeconds = 120, int retries = 3)
    {
        var process = new Process();
        var startInfo = new ProcessStartInfo();
        startInfo.WindowStyle = ProcessWindowStyle.Hidden;
        startInfo.FileName = command;
        startInfo.Arguments = arguments;
        process.StartInfo = startInfo;
        for (var nr = 0; nr < retries; nr++)
        {
            process.Start();
            LogMessage("Run command process id: " + process.Id);
            var returnCode = process.WaitForExit(timeoutInSeconds * 1000);
            if (returnCode) return;
            if (nr <= retries - 1)
            {
                LogMessage("Command failed, retry..");
                EndProcessTree(process.Id);
            }
            else
            {
                return;
            }
        }
    }

    static void EndTask(string taskname)
    {
        string processName = taskname;
        string fixstring = taskname.Replace(".exe", "");

        if (taskname.Contains(".exe"))
        {
            foreach (Process process in Process.GetProcessesByName(fixstring))
            {
                process.Kill();
            }
        }
        else if (!taskname.Contains(".exe"))
        {
            foreach (Process process in Process.GetProcessesByName(processName))
            {
                process.Kill();
            }
        }
    }

    static void EndProcessTree(Int32 pid)
    {
        Process.Start(new ProcessStartInfo
        {
            FileName = "taskkill",
            Arguments = "/PID {pid} /F /T",
            CreateNoWindow = true,
            UseShellExecute = false
        }).WaitForExit();
        LogMessage("Kill process id: " + pid);
    }
    static Dictionary<string, string> GetInstalledProgramList(string regkey)
    {
        var result = new Dictionary<string, string>();
        var hklm = RegistryKey.OpenBaseKey(RegistryHive.LocalMachine, RegistryView.Registry32);
        var rk = hklm.OpenSubKey(regkey, false);
        if (rk == null) return result;
        foreach (var name in rk.GetSubKeyNames())
        {
            var key = rk.OpenSubKey(name, false);
            if (key == null) continue;
            var value = key.GetValue("DisplayName");
            if (value == null) continue;
            var uninstallstr = key.GetValue("UninstallString");
            if (uninstallstr == null) continue;
            if (!result.ContainsKey(value.ToString().ToLower())) result.Add(value.ToString().ToLower(), uninstallstr.ToString());
        }
        hklm = RegistryKey.OpenBaseKey(RegistryHive.LocalMachine, RegistryView.Registry64);
        rk = hklm.OpenSubKey(regkey, false);
        if (rk == null) return result;
        foreach (var name in rk.GetSubKeyNames())
        {
            var key = rk.OpenSubKey(name, false);
            if (key == null) continue;
            var value = key.GetValue("DisplayName");
            if (value == null) continue;
            var uninstallstr = key.GetValue("UninstallString");
            if (uninstallstr == null) continue;
            if (!result.ContainsKey(value.ToString().ToLower())) result.Add(value.ToString().ToLower(), uninstallstr.ToString());
        }
        return result;
    }

    //This will log to a logfile with date and time and to the screen
    static void LogMessage(string message)
    {
        //call :captureoutput >> logfile.log sends default log lines.
        Console.WriteLine(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss:: ") + message);
        //Force all logging to screen via error message
        Console.Error.WriteLine(message);
    }
}