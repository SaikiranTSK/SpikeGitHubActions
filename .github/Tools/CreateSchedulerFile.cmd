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
using System.Threading;

class Program
{
    private static object _syncLock = new object();
    private static string _template = @"<?xml version=""1.0"" encoding=""UTF-16""?>
<Task version=""1.2"" xmlns=""http://schemas.microsoft.com/windows/2004/02/mit/task"">
  <RegistrationInfo>
    <Date>2015-10-07T17:57:59.0940415</Date>
    <Author>CODE1\NLYBSTQVP4-sys134</Author>
  </RegistrationInfo>
  <Triggers>
    <CalendarTrigger>
      <Repetition>
        <Interval>PT1M</Interval>
        <StopAtDurationEnd>false</StopAtDurationEnd>
      </Repetition>
      <StartBoundary>2015-10-07T17:55:28</StartBoundary>
      <Enabled>true</Enabled>
      <ScheduleByDay>
        <DaysInterval>1</DaysInterval>
      </ScheduleByDay>
    </CalendarTrigger>
    <LogonTrigger>
      <Repetition>
        <Interval>PT1M</Interval>
        <StopAtDurationEnd>false</StopAtDurationEnd>
      </Repetition>
      <Enabled>true</Enabled>
      <Delay>PT30S</Delay>
    </LogonTrigger>
  </Triggers>
  <Principals>
    <Principal id=""Author"">
      <UserId>CODE1\NLYBSTQVP4-sys134</UserId>
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>true</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>
    <AllowHardTerminate>false</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>true</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context=""Author"">
    <Exec>
      <Command>\\nlybstqvp1ms368\att\Scheduler_V2.1\Scheduler.exe</Command>
      <Arguments>#SYSTEM#</Arguments>
    </Exec>
  </Actions>
</Task>";
    static void Main(string[] args)
    {
        var tmpToWrite = "";
        var scriptDir = args[0].TrimEnd(Path.DirectorySeparatorChar);
        try
        {
            scriptDir = Path.GetDirectoryName(scriptDir);
        }
        catch (Exception ex)
        {
            LogMessage(ex.Message + " Trace: " + ex.StackTrace);
        }
        if (args.Length < 2)
        {
            LogMessage("Input parameter is required, name of the system between quotes..");
            LogMessage("CreateSchedulerFile.cmd \"SystemName\"");
            return;
        }
        if (args[1].Equals(""))
        {
            LogMessage("Input parameter is required, name of the system between quotes..");
            LogMessage("CreateSchedulerFile.cmd \"SystemName\"");
            return;
        }
        try
        {
            tmpToWrite = _template.Replace("#SYSTEM#", args[1]);
        }
        catch (Exception ex)
        {
            LogMessage(ex.Message + " Trace: " + ex.StackTrace);
        }
        try
        {
            var path = scriptDir + @"\SchedulerV2_1" + args[1] + ".xml";
            LogMessage("Creating template for system: " + args[1] + " as: " + path);
            File.WriteAllText(path, tmpToWrite);
        }
        catch (Exception ex)
        {
            LogMessage(ex.Message + " Trace: " + ex.StackTrace);
        }
    }

    private static void LogMessage(string message)
    {
        if (!message.Contains("Unable to show progress information."))
        {
            lock (_syncLock)
            {
                Console.WriteLine(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss::") + message);
                Console.Error.WriteLine(message);
            }
        }
    }
}
