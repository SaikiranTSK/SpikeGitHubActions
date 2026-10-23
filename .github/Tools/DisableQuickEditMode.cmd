// 2>nul||@goto :batch
/*
:batch
@echo off
setlocal

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
%temp%\%~n0.exe
if exist "%temp%\%~n0.exe" del /F /Q "%temp%\%~n0.exe"

endlocal & exit /b %errorlevel%

*/

using System;
using System.Runtime.InteropServices;


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

    static void Main(string[] args)
    {
        try
        {
            int mode;
            IntPtr handle = GetStdHandle(STD_INPUT_HANDLE);
            GetConsoleMode(handle, out mode);
            SetConsoleMode(handle, mode &= ~CHECK_QUICK_EDIT);
        }
        catch (Exception e) {
            Environment.Exit(5);
        }

    }
}