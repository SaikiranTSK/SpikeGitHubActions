// 2>nul||@goto :batch
/*
:batch
@ECHO OFF
CLS
set "BATCHFILE=%~0"
set LOGTIME=%TIME:~0,8%
set LOGTIME=%LOGTIME::=_%
set LOGTIME=%LOGTIME: =%
set MYDATE=UNKNOWN
echo %date% | >nul findstr /i /r /c:"^[A-Z][a-z][a-z] [0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]" && ( set MYDATE=%date:~10,4%-%date:~4,2%-%date:~7,2%)
echo %date% | >nul findstr /i /r /c:"^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]" && ( set MYDATE=%date:~0,4%-%date:~5,2%-%date:~8,2%)
set LOGFILE=%temp%\%~n0_%MYDATE%_%LOGTIME%.log
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

using Microsoft.Win32;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Security.Principal;
using System.Threading;

class Program
{
    //Variables for tracking changelog and version details.
    private static string _version = "1.0.0007";
    private static string _initialCreator = "M. Tiellemans";
    private static string _lastChanger = "M. Tiellemans";
    private static string _history = @"
Initial script (max 62 characters)
Add uninstall and install for FAST.
Added iWatt installation.
Added fix for TestRobot error -8 issue.
Added CUSTOMSUTLIB installation.
";
    private static string _description = "Uninstall+Install TAF,TestRobot,Sutlib,Scripts,FAST,IWATT.";
    const string Regkey = @"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall";
    private static string _installPath = "";
    private static string _scriptFileFullPath_arg0 = "";
    private static string _logFileFullPath_arg1 = "";
    private static string _processResults = "";
    private static string _programToInstall_arg2 = "";
    private static string _msiToInstall_arg3 = "";
    private static string _pdcDirectory_arg4 = "";
    const string _nightbatchPath = @"\\code1.emi.philips.com\storage\IGTs_Nightbatch\Nightbatch\";

    //Your script entry point.
    static void Main(string[] args)
    {
        //args holds 11 values, scriptfile, logfile and 9 empte or filled in parameters.
        WriteStartupDetails(args);
        _scriptFileFullPath_arg0 = args[0];
        _logFileFullPath_arg1 = args[1];
        _programToInstall_arg2 = args[2].ToUpper();
        _msiToInstall_arg3 = args[3];
        _pdcDirectory_arg4 = args[4];
        var scriptDir = Path.GetDirectoryName(_scriptFileFullPath_arg0);
        if (!(new WindowsPrincipal(WindowsIdentity.GetCurrent())).IsInRole(WindowsBuiltInRole.Administrator))
        {
            LogMessage("This script only runs correctly as it rans as admin user");
            return;
        }

        try
        {
            if (CheckImputParameters() == false)
            {
                CopyLoggingToNightbatch(args, _logFileFullPath_arg1);
                return;
            }
            var installedPrograms = GetInstalledProgramList(Regkey);
            //Uninstallation pre steps..
            KillTafTestRobotAndFAST();
            foreach (var installedProgram in installedPrograms)
            {
                switch (_programToInstall_arg2)
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
                    case "CUSTOMSUTLIB":
                        Uninstall(installedProgram, "sutkeywordlibrary ");
                        break;
                    case "DAILYTESTSCRIPTS":
                        Uninstall(installedProgram, "taftestscripts ");
                        break;
					case "DAILYFAST":
                    case "FAST":
                        Uninstall(installedProgram, "fast ");
                        break;
                    case "IWATT":
                        Uninstall(installedProgram, "iwatt ");
                        break;
                }
            }
            //Uninstallation post steps
            switch (_programToInstall_arg2)
            {
                case "TAF":
                    _installPath = "C:\\Program Files (x86)\\Taf";
                    if (Directory.Exists(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData) + "\\..\\Roaming\\Philips\\TAF"))
                    {
                        DeleteFolder(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData) + "\\..\\Roaming\\Philips\\TAF");
                    }
                    break;
                case "TESTROBOT":
                    _installPath = "C:\\Program Files (x86)\\Philips\\TestRobot";
                    if (Directory.Exists(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData) + "\\..\\Roaming\\Philips\\TestRobot"))
                    {
                        DeleteFolder(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData) + "\\..\\Roaming\\Philips\\TestRobot");
                    }
                    break;
                case "SUTLIB":
                    _installPath = "C:\\Program Files (x86)\\TAF_SUTKeywordLibrary";
                    break;
                case "TESTSCRIPTS":
                    _installPath = "C:\\Program Files (x86)\\TAF_TestScripts";
                    break;
                case "DAILYSUTLIB":
                    _installPath = "C:\\Program Files (x86)\\TAF_SUTKeywordLibrary";
                    break;
                case "CUSTOMSUTLIB":
                    _installPath = "C:\\Program Files (x86)\\TAF_SUTKeywordLibrary";
                    break;
                case "DAILYTESTSCRIPTS":
                    _installPath = "C:\\Program Files (x86)\\TAF_TestScripts";
                    break;
				case "DAILYFAST":
                case "FAST":
                    _installPath = "C:\\Program Files (x86)\\FAST";
                    _msiToInstall_arg3 = GetAlternativeFASTPathIfNeeded(_msiToInstall_arg3);
                    break;
                case "IWATT":
                    _installPath = "C:\\Philips Healthcare\\IoccWorkflowAnalysisTestTool\\";
                    break;
            }
            if (!_installPath.Equals(""))
            {
                while (Directory.Exists(_installPath))
                {
                    DeleteFolder(_installPath);
                    Thread.Sleep(5000);
                }
            }
            //Uncheck case(til break) for extra msi logging
            switch (_programToInstall_arg2)
            {
                //case "SUTLIB":
                //    InstallAndLog(msiToInstall);
                //    break;
                //case "DAILYSUTLIB":
                //    InstallAndLog(msiToInstall);
                //    break;
                default:
                    while (!Directory.Exists(_installPath))
                    {
                        Install(_msiToInstall_arg3);
                        if (Directory.Exists(_installPath) || _installPath.Equals("")) break;
                        EndTask("msiexec");
                        Thread.Sleep(5000);
                    }
                    break;
            }
            //After installation post steps
            switch (_programToInstall_arg2)
            {
                case "TAF":
                    LogMessage("Starting TAF");
                    RunCommand("C:\\Program Files (x86)\\Taf\\taf.exe", "", 10);
                    KillTafTestRobotAndFAST();
                    SetTestRobotExclusionPorts();
                    break;
                case "TESTROBOT":
                    LogMessage("Adding registry settings for excel");
                    RunCommandAndWait("reg.exe",
                        "add \"HKCU\\Software\\Microsoft\\Office\\14.0\\Excel\\Security\\Trusted Locations\\Location99\" /v Path /t REG_SZ /d \"C:\\Program Files (x86)\\Philips\\TestRobot\\templates\" /f");
                    RunCommandAndWait("reg.exe",
                        "add \"HKCU\\Software\\Microsoft\\Office\\14.0\\Excel\\Security\\Trusted Locations\\Location99\" /v Description /t REG_SZ /d \"Required for TestRobot\" /f");
                    LogMessage("Starting TestRobot");
                    RunCommand("C:\\Program Files (x86)\\Philips\\TestRobot\\testrobot.exe", "", 10);
                    KillTafTestRobotAndFAST();
                    SetTestRobotExclusionPorts();
                    break;
                case "SUTLIB":
                    break;
                case "TESTSCRIPTS":
                    break;
				case "DAILYFAST":
                case "FAST":
                    break;
            }
            Thread.Sleep(1000);
            EndTask("msiexec");
        }
        catch (Exception ex)
        {
            LogMessage("Error while running C#Script: " + ex.Message + " " + ex.StackTrace);
        }

        CopyLoggingToNightbatch(args, _logFileFullPath_arg1);
    }

    static void CopyLoggingToNightbatch(string[] args, string logFile)
    {
        var nightbatchDirectory = _nightbatchPath + Path.GetFileNameWithoutExtension(args[0]) + @"\" + Environment.MachineName + @"\";
        LogMessage("Copy data to nightbatchDirectory " + nightbatchDirectory);
        if (!Directory.Exists(nightbatchDirectory)) Directory.CreateDirectory(nightbatchDirectory);
        File.Copy(logFile, nightbatchDirectory + Path.GetFileNameWithoutExtension(logFile) + "_" + args[2] + DateTime.Now.ToString("_yyyy-MM-dd_hh_mm_ss_tt", CultureInfo.InvariantCulture) + ".log");
    }

    static void KillTafTestRobotAndFAST()
    {
        if (File.Exists("C:\\Program Files (x86)\\Philips\\TestRobot\\testrobot.exe"))
        {
            LogMessage("Stopping TestRobot");
            RunCommand("C:\\Program Files (x86)\\Philips\\TestRobot\\testrobot.exe", "/ExitApplication", 10);
        }
        if (File.Exists("C:\\Program Files (x86)\\Philips\\TAF\\taf.exe"))
        {
            LogMessage("Stopping TAF");
            RunCommand("C:\\Program Files (x86)\\Philips\\TAF\\taf.exe", "/ExitApplication", 10);
        }
        EndTask("taf");
        EndTask("TestRobot.exe");
        EndTask("TAFControllerService.exe");
        EndTask("TAFScriptRunner.exe");
        EndTask("TAFTafFVAdapterCSExeCOMServer.exe");
        EndTask("TAFControllerService.exe");
        EndTask("nunit-agent-x86.exe");
        EndTask("nunit-x86.exe");
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
    static bool CheckImputParameters()
    {
        //Remove quotes
        _programToInstall_arg2 = _programToInstall_arg2.Trim('"');
        _msiToInstall_arg3 = _msiToInstall_arg3.Trim('"');
        var msiFile = "";
        switch (_programToInstall_arg2.ToUpper())
        {
            case "TESTROBOT":
                msiFile = _msiToInstall_arg3;
                break;
            case "TAF":
                msiFile = _msiToInstall_arg3;
                break;
            case "SUTLIB":
                msiFile = _msiToInstall_arg3;
                break;
            case "TESTSCRIPTS":
                msiFile = _msiToInstall_arg3;
                break;
            case "FAST":
                msiFile = _msiToInstall_arg3;
                msiFile = GetAlternativeFASTPathIfNeeded(msiFile);
                break;
            case "IWATT":
                msiFile = _msiToInstall_arg3;
                break;
            case "DAILYSUTLIB":
                if (_pdcDirectory_arg4.Equals(""))
                {
                    LogMessage("Error capturing amounth of input parameters (require at least 3).");
                    return false;
                }
                //remove the optional quotes and add to the msiline PDCSOURCEDIR=args4
                _pdcDirectory_arg4 = _pdcDirectory_arg4.Replace("\"", "").TrimEnd(' ').TrimEnd('\\') + '\\';
                if (CheckDirectory(_msiToInstall_arg3) && CheckDirectory(_pdcDirectory_arg4))
                {
                    var sortedDirectories = new DirectoryInfo(_msiToInstall_arg3).GetDirectories()
                                                      .OrderBy(f => f.CreationTime)
                                                      .ToList();
                    msiFile = sortedDirectories.Last().FullName + @"\Install\SpecialPackages\SUTKeywordLibrary.msi";
                    _msiToInstall_arg3 = msiFile + "\" PDCSOURCEDIR=\"" + _pdcDirectory_arg4;
                    LogMessage("Found msiFile: " + msiFile);
                }
                else
                {
                    LogMessage("Installation aborted");
                    return false;
                }
                break;
            case "CUSTOMSUTLIB":
                if (_pdcDirectory_arg4.Equals(""))
                {
                    LogMessage("Error capturing amounth of input parameters (require at least 3).");
                    return false;
                }
                //remove the optional quotes and add to the msiline PDCSOURCEDIR=args4
                _pdcDirectory_arg4 = _pdcDirectory_arg4.Replace("\"", "").TrimEnd(' ').TrimEnd('\\') + '\\';
                if (CheckDirectory(_pdcDirectory_arg4))
                {
                    msiFile = _msiToInstall_arg3;
                    _msiToInstall_arg3 = _msiToInstall_arg3 + "\" PDCSOURCEDIR=\"" + _pdcDirectory_arg4;
                }
                else
                {
                    LogMessage("Installation aborted");
                    return false;
                }
                break;
            case "DAILYTESTSCRIPTS":
                if (CheckDirectory(_msiToInstall_arg3))
                {
                    var sortedDirectories = new DirectoryInfo(_msiToInstall_arg3).GetDirectories().OrderBy(f => f.CreationTime).ToList();
                    msiFile = sortedDirectories.Last().FullName + @"\Install\TestSystemsInstall\TAFTestScripts\TAFTestScripts.msi";
                    _msiToInstall_arg3 = msiFile;
                    LogMessage("Found msiFile: " + msiFile);
                }
                else
                {
                    LogMessage("Installation aborted");
                    return false;
                }
                break;
			case "DAILYFAST":
                if (_pdcDirectory_arg4.Equals(""))
                {
                    LogMessage("Error capturing amounth of input parameters (require at least 3).");
                    return false;
                }
                //remove the optional quotes and add to the msiline PDCSOURCEDIR=args4
                _pdcDirectory_arg4 = _pdcDirectory_arg4.Replace("\"", "").TrimEnd(' ').TrimEnd('\\') + '\\';
                if (CheckDirectory(_msiToInstall_arg3) && CheckDirectory(_pdcDirectory_arg4))
                {
                    var sortedDirectories = new DirectoryInfo(_msiToInstall_arg3).GetDirectories()
                        .OrderBy(f => f.CreationTime)
                        .ToList();
                    msiFile = sortedDirectories.Last().FullName + "\\Install\\TestSystemsInstall\\FAST\\FAST.msi";
                    _msiToInstall_arg3 = msiFile + "\" PDCSOURCEDIR=\"" + _pdcDirectory_arg4;
                    LogMessage("Found msiFile: " + msiFile);
                }
                else
                {
                    LogMessage("Installation aborted");
                    return false;
                }
                break;
            default:
                LogMessage("Supported input parameters are: TAF, TESTROBOT, SUTLIB, TESTSCRIPTS, DAILYSUTLIB, CUSTOMSUTLIB, DAILYTESTSCRIPTS, FAST, DAILYFAST, IWATT");
                return false;
        }

        for (int nr = 0; nr < 10; nr++)
        {
            if (File.Exists(msiFile))
            {
                return true;
            }
            LogMessage("Check if file exists: " + msiFile);
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
        RunCommandAndWait("msiexec.exe", arguments, 1000, 3);
    }

    static void InstallAndLog(string msi)
    {
        var logPath = @"c:\temp\msilog.log";
        if (File.Exists(logPath)) File.Delete(logPath);
        var arguments = "/QN /I \"" + msi + "\" /L*v \"" + logPath + "\"";
        LogMessage("Installing: msiexec.exe arguments: " + arguments);
        RunCommandAndWait("msiexec.exe", arguments, 1000, 3);
        if (File.Exists(logPath))
        {
            LogMessage(File.ReadAllText(logPath));
            File.Delete(logPath);
        }
        else
        {
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
            LogMessage("Check for other msi installations");
            //Wait until msiinstallations are done installing
            var processes = Process.GetProcessesByName("msiexec");
            var waitTimer = 36; //3 min
            while (processes.Count() >= 1)
            {
                processes = Process.GetProcessesByName("msiexec");
                LogMessage("Wait until other msi installations where done");
                Thread.Sleep(5000);
                waitTimer--;
                if (waitTimer <= 0)
                {
                    EndTask("msiexec");
                    break;
                }
            }
            LogMessage("Uninstalling: " + program.Key + " with: " + command + " arguments: " + arguments);
            RunCommandAndWait(command, arguments);
            LogMessage("Wait until msi uninstallations where done, when the msi is done, not all settings are alway's removed or updated...");
            Thread.Sleep(5000);
            CheckUninstalled(program);
            EndTask("msiexec");
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
        startInfo.WorkingDirectory = Path.GetDirectoryName(command);
        process.StartInfo = startInfo;
        for (var nr = 0; nr < retries; nr++)
        {
            process.Start();
            LogMessage("Run command process id: " + process.Id);
            var returnCode = process.WaitForExit(timeoutInSeconds * 1000);
            if (returnCode) return;
            LogMessage("Command failed, retry..");
            EndProcessTree(process.Id);
            EndTask(command);
        }
    }

    static void RunCommand(string command, string arguments, int timeoutInSeconds = 120)
    {
        var process = new Process();
        var startInfo = new ProcessStartInfo();
        startInfo.WindowStyle = ProcessWindowStyle.Hidden;
        startInfo.FileName = command;
        startInfo.Arguments = arguments;
        startInfo.WorkingDirectory = Path.GetDirectoryName(command);
        process.StartInfo = startInfo;
        process.Start();
        LogMessage("Run command process id: " + process.Id);
        var returnCode = process.WaitForExit(timeoutInSeconds * 1000);
    }

    static void EndTask(string taskname)
    {
        string processName = taskname;
        string fixstring = taskname.Replace(".exe", "");

        var processes = Process.GetProcessesByName(fixstring);
        while (processes.Count() >= 1)
        {
            try
            {
                foreach (var process in processes)
                {
                    process.Kill();
                }
            }
            catch { }
            processes = Process.GetProcessesByName(fixstring);
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

    private static void LogMessage(string message)
    {
        if (message == null) return;
        if (!message.Contains("Unable to show progress information."))
        {
            //Both loggings are required to store logging into the logfile and on the screen.
            //this writes the message into the log file (call :captureoutput "%~1" "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9">>%LOGFILE%).
            Console.WriteLine(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss::") + message);
            //this writes the message into the command window (only errors will be show on the command window and not logged).
            Console.Error.WriteLine(message);
        }
    }

    //This will set the testrobot exclusion ports 50000 and 50001 (required by installing testrobot or TAF).
    static bool SetTestRobotExclusionPorts()
    {
        var result = false;
        var exclusionPorts = ExecuteProcessWithReturnresults(Environment.SystemDirectory + "\\netsh.exe", " int ipv4 show excludedportrange tcp");
        var exclusionPortLines = exclusionPorts.Split(Environment.NewLine.ToCharArray());
        foreach (var line in exclusionPortLines)
        {
            if (line.Contains("50000") && line.Contains("50001"))
            {
                LogMessage("Exclusionports are already added.");
                result = true;
                break;
            }
        }

        if (!result)
        {
            ExecuteProcessWithReturnresults(Environment.SystemDirectory + "\\netsh.exe", " int ipv4 add excludedportrange tcp 50000 2 persistent");
            exclusionPorts = ExecuteProcessWithReturnresults(Environment.SystemDirectory + "\\netsh.exe", " int ipv4 show excludedportrange tcp");
            exclusionPortLines = exclusionPorts.Split(Environment.NewLine.ToCharArray());
            foreach (var line in exclusionPortLines)
            {
                if (line.Contains("50000") && line.Contains("50001"))
                {
                    LogMessage("Exclusionports are added.");
                    result = true;
                    break;
                }
            }
            LogMessage("Failed to add Exclusionports.");
        }
        return result;
    }

    //This method start a process with the given executable name and arguments, result will be the commandline results produced by the command.
    static string ExecuteProcessWithReturnresults(string executable, string arguments)
    {
        _processResults = "";
        //Set redirect output and error from running process to event within this process
        var processStartInfo = new ProcessStartInfo {CreateNoWindow = true,RedirectStandardOutput = true,RedirectStandardInput = false,RedirectStandardError = true,ErrorDialog = false,UseShellExecute = false,Arguments = arguments,FileName = executable};
        //Grab the console data of the process (all output so also errors to output data)
        var process = new Process { StartInfo = processStartInfo, EnableRaisingEvents = true };
        process.OutputDataReceived += Process_OutputDataReceived;
        process.ErrorDataReceived += Process_OutputDataReceived;
        process.Start();
        process.BeginOutputReadLine();
        process.BeginErrorReadLine();
        process.WaitForExit();
        process.CancelErrorRead();
        process.CancelOutputRead();
        process.OutputDataReceived -= Process_OutputDataReceived;
        process.ErrorDataReceived -= Process_OutputDataReceived;
        return _processResults;
    }

    //This method get events on the executed external process (what's normal in the command output)
    private static void Process_OutputDataReceived(object sender, DataReceivedEventArgs e)
    {
        //Only do something with data, else skip
        if (e.Data != null)
        {
            _processResults += e.Data + Environment.NewLine;
        }
    }

    //Writes the details to the command console window by only writing the the error buffer.
    private static void WriteStartupDetails(string[] args)
    {
        //Split history on newlines (remove last newline as else we get an empty string in the array as well)
        var tmpHistory = (_history.TrimEnd(Environment.NewLine.ToArray())).Split(Environment.NewLine.ToArray());
        //Select the last history data
        var history = tmpHistory.Last();
        //Also remove newlines
        history = history.Substring(0, Math.Min(history.Length, 61));
        var title = Path.GetFileNameWithoutExtension(args[0]);
        title = title.Substring(0, Math.Min(title.Length, 68));
        var scriptName = Path.GetFileName(args[0]);
        scriptName = scriptName.Substring(0, Math.Min(scriptName.Length, 62));
        _version = _version.Substring(0, Math.Min(_version.Length, 66));
        _initialCreator = _initialCreator.Substring(0, Math.Min(_initialCreator.Length, 63));
        _lastChanger = _lastChanger.Substring(0, Math.Min(_lastChanger.Length, 58));
        _description = _description.Substring(0, Math.Min(_description.Length, 62));
        Console.Error.WriteLine("###############################################################################");
        Console.Error.WriteLine("#                                                                             #");
        Console.Error.WriteLine("# Title: " + title.PadRight(68, ' ') + " #");
        Console.Error.WriteLine("# Version: " + _version.PadRight(66, ' ') + " #");
        Console.Error.WriteLine("# Script name: " + scriptName.PadRight(62, ' ') + " #");
        Console.Error.WriteLine("# Created by: " + _initialCreator.PadRight(63, ' ') + " #");
        Console.Error.WriteLine("#                                                                             #");
        Console.Error.WriteLine("# Last changed by: " + _lastChanger.PadRight(58, ' ') + " #");
        Console.Error.WriteLine("# Last changes: " + history.PadRight(61, ' ') + " #");
        Console.Error.WriteLine("#                                                                             #");
        Console.Error.WriteLine("# Description: " + _description.PadRight(62, ' ') + " #");
        Console.Error.WriteLine("#                                                                             #");
        Console.Error.WriteLine("###############################################################################");
    }

    //In case a given path to the FAST msi does not exist, another path option is used
    private static string GetAlternativeFASTPathIfNeeded(string fastMsiPath)
    {
        string originalPath = fastMsiPath;
        //Since FAST repository has been moved, it is possible to have multiple paths, depending on the project.
        //The following piece of code tries to find the .msi in two possible paths
        if(!File.Exists(fastMsiPath))
        {
            if(fastMsiPath.Contains("TestSystemsInstall"))
            {
                fastMsiPath = fastMsiPath.Replace(@"TestSystemsInstall\FAST", "SpecialPackages").Replace(@"TestTooling\master", @"TestTooling\SS_SUTKeywords_Int");
            }
            else
            {
                fastMsiPath= fastMsiPath.Replace("SpecialPackages", @"TestSystemsInstall\FAST").Replace(@"TestTooling\SS_SUTKeywords_Int", @"TestTooling\master");
            }
            LogMessage("Path to FAST msi '"+originalPath+ "' not found, so we also tried the following: " +fastMsiPath);
        }
        return fastMsiPath;
    }
}
