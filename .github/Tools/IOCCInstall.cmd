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
echo Starting: %temp%\%~n0.exe "%~dp0" "%~1" "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9" & %temp%\%~n0.exe "%~1" "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9"
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
using System.Threading;

class Program
{
    public static object _syncLock = new object();
    static void Main(string[] args)
    {
        var scriptDir = Path.GetDirectoryName(args[0]);
        if (args.Length < 2)
        {
            LogMessage("Input parameter is required, full path to PDC between quotes..");
            LogMessage("IOCCInstall.cmd \"FULLPATHTOPDC\" \"FULLPATHTOSYSTEMCONFIGURATION.INI\" \"FULLPATHTOSYSTEMMANIFEST.XML\"");
            return;
        }
        if (args.Length < 3)
        {
            LogMessage("Input parameter is required, full path to Systemconfiguration.ini between quotes..");
            LogMessage("IOCCInstall.cmd \"FULLPATHTOPDC\" \"FULLPATHTOSYSTEMCONFIGURATION.INI\" \"FULLPATHTOSYSTEMMANIFEST.XML\"");
            return;
        }
        if (args.Length < 4)
        {
            LogMessage("Input parameter is required, full path to systemmanifest.xml between quotes..");
            LogMessage("IOCCInstall.cmd \"FULLPATHTOPDC\" \"FULLPATHTOSYSTEMCONFIGURATION.INI\" \"FULLPATHTOSYSTEMMANIFEST.XML\"");
            return;
        }
        Console.WriteLine("ScriptDir: " + scriptDir);
        StartProcess(@"c:\windows\system32\cmd.exe", "/c RD /S /Q d:\\pdc");
        StartProcess(@"c:\windows\system32\cmd.exe", "/c robocopy \"" + args[1] + "\" \"D:\\PDC\" /V /NP /MIR /W:30 /R:100");
        StartProcess(@"c:\windows\system32\cmd.exe", "/c xcopy \"" + args[2] + "\" D:\\PDC\\SystemConfiguration.ini /F /Y /Z /R");
        StartProcess(@"c:\windows\system32\cmd.exe", "/c xcopy \"" + args[3] + "\" D:\\PDC\\SystemManifest.xml /F /Y /Z /R");
        StartProcess(@"d:\pdc\Tools\PXE\Installation\Philips.PmsIxr.Misc.Private.Installation.SystemInstallerBridgeHost.exe", "/sysconfig:" + args[2] + " /silent");
        StartProcess(@"D:\PDC\Tools\PXE\Installation\ipmi.exe", "-v -v -H 192.68.32.41 -U ADMIN -P ADMIN power off");
        StartProcess(@"D:\PDC\Tools\PXE\Installation\ipmi.exe", "-v -v -H 192.68.32.42 -U ADMIN -P ADMIN power off");
        Sleeping(10000);
        StartProcess(@"D:\PDC\Tools\PXE\Installation\ipmi.exe", "-v -v -H 192.68.32.41 -U ADMIN -P ADMIN power on");
        StartProcess(@"D:\PDC\Tools\PXE\Installation\ipmi.exe", "-v -v -H 192.68.32.42 -U ADMIN -P ADMIN power on");
        Sleeping(10000);
        SetCredentials("192.68.32.1");
        SetCredentials("192.68.32.2");
        SetCredentials("192.68.32.9");
        SetCredentials("192.68.32.11");
        SetCredentials("192.68.32.13");
        SetCredentials("192.68.32.14");
        SetCredentials("192.68.32.15");
        string path = @"d:\SYSTEM_UPDATE_PROGRESS.token";
        if (File.Exists(path)) File.Delete(path);
        LogMessage("Create: " + path);
        try
        {
            using (var tw = new StreamWriter(path, true))
            {
                tw.Write(@"");
            }
            LogMessage("Create: " + path + " done.");
        } catch(Exception ex)
        {
            LogMessage(ex.Message + " " + ex.StackTrace);
        }
        WaitForDirExists(@"\\192.68.32.1\d$");
        StartProcess(@"c:\windows\system32\cmd.exe", "/c copy " + path + @" \\192.68.32.1\d$\Local\SWF\Infra");
        WaitForDirExists(@"\\192.68.32.2\d$");
        StartProcess(@"c:\windows\system32\cmd.exe", "/c copy " + path + @" \\192.68.32.2\d$\Local\SWF\Infra");
        if (!Directory.Exists(@"c:\Program Files (x86)\Sysinternals Suite\")) Directory.CreateDirectory(@"c:\Program Files (x86)\Sysinternals Suite\");
        StartProcess(@"c:\windows\system32\cmd.exe", "/c copy \"" + scriptDir + "\\psexec.exe\" \"" + @"c:\Program Files (x86)\Sysinternals Suite\" + "\"");
        Sleeping(30000);
        EnableServices("192.68.32.1");
        EnableServices("192.68.32.2");
        RestartPcs("192.68.32.1");
        RestartPcs("192.68.32.2");
    }

    private static void EnableServices(string pc)
    {
        StartProcess(@"c:\Program Files (x86)\Sysinternals Suite\psexec.exe", @" \\" + pc + @" sc config Philips.iengine.powercontrolservice start= disabled");
        StartProcess(@"c:\Program Files (x86)\Sysinternals Suite\psexec.exe", @" \\" + pc + @" sc config Philips.FlexibleViewing.SessionManager start= delayed-auto");
        StartProcess(@"c:\Program Files (x86)\Sysinternals Suite\psexec.exe", @" \\" + pc + @" sc config Philips.IEngine.PowerControlService start= delayed");
        StartProcess(@"c:\Program Files (x86)\Sysinternals Suite\psexec.exe", @" \\" + pc + @" sc config Philips.IEngine.SessionManager start= delayed-auto");
        StartProcess(@"c:\Program Files (x86)\Sysinternals Suite\psexec.exe", @" \\" + pc + @" sc config Philips.PmsIxr.Service.ServiceHub.SessionManager start= delayed-auto");
        StartProcess(@"c:\Program Files (x86)\Sysinternals Suite\psexec.exe", @" \\" + pc + @" sc config Philips.SynchronizationService start= delayed-auto");
    }
    private static void RestartPcs(string pc)
    {
        StartProcess(@"c:\Program Files (x86)\Sysinternals Suite\psexec.exe", @" \\" + pc + @" shutdown -r -t 0");
    }


    private static void Sleeping(int ms)
    {
        LogMessage("Sleeping for: " + ms + "ms");
        Thread.Sleep(ms);
    }

    private static void SetCredentials(string ip)
    {
        var commandExe = @"c:\windows\system32\net.exe";
        var commandParams = "use \\\\" + ip + " /delete";
        LogMessage("Start: " + commandExe); StartProcess(commandExe, commandParams);
        commandExe = @"c:\windows\system32\cmdkey.exe";
        commandParams = "/delete:" + ip;
        LogMessage("Start: " + commandExe); StartProcess(commandExe, commandParams);
        commandExe = @"c:\windows\system32\cmdkey.exe";
        commandParams = "/add:" + ip;
        LogMessage("Start: " + commandExe); StartProcess(commandExe, commandParams + " /user:admin /pass:admin");
    }

    private static void WaitForDirExists(string path)
    {
        LogMessage("Waiting for: " + path);
        var nr = 0;
        while (Directory.Exists(path) == false)
        {
            Thread.Sleep(1000);
            nr++;
            if (nr >= (60 * 5))
            {
                LogMessage("Waiting for: " + path + " done failed.");
                break;
            }
        }
    }

    public static void StartProcess(string processName, string processArguments = "", bool hideParams = false)
    {
        if (!File.Exists(processName))
        {
            LogMessage("Exe file not found in: " + processName);
            return;
        }
        if (hideParams)
        {
            LogMessage("Start process: " + processName);
        }
        else
        {
            LogMessage("Start process: " + processName + " params: " + processArguments);
        }
        var processStartInfo = new ProcessStartInfo();
        processStartInfo.CreateNoWindow = true;
        processStartInfo.RedirectStandardOutput = true;
        processStartInfo.RedirectStandardInput = true;
        processStartInfo.RedirectStandardError = true;
        processStartInfo.ErrorDialog = false;
        processStartInfo.UseShellExecute = false;
        processStartInfo.Arguments = processArguments;
        processStartInfo.FileName = processName;
        var process = new Process();
        process.StartInfo = processStartInfo;
        process.EnableRaisingEvents = true;
        //Grab console data to send to the server
        process.OutputDataReceived += Process_OutputDataReceived; ;
        process.ErrorDataReceived += Process_OutputDataReceived;
        process.Start();
        Console.WriteLine("Process started. (" + process.Id + ")");
        process.BeginOutputReadLine();
        process.BeginErrorReadLine();
        process.WaitForExit();
        process.CancelOutputRead();
        process.CancelErrorRead();
        LogMessage("Process completed. (" + process.Id + ")");
    }

    private static void Process_OutputDataReceived(object sender, DataReceivedEventArgs e)
    {
        LogMessage(e.Data);
    }
    private static void LogMessage(string message)
    {
        lock (_syncLock)
        {
            Console.WriteLine(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss::") + message);
            Console.Error.WriteLine(message);
        }
    }
}
