echo on
setlocal
echo %1
echo %2

rem Run directly from repo tooling; Mainline preflight requires a space-free workspace.
set var1="%~dp0..\Tools\RunAsCurrentUser.exe"
set var2=%~dp0execute_test_batch_side_pc.cmd
set var3=%1
set "var4=%~2"
set var5=%var1% "%var2% %var3% %var4%"

call %var5%
endlocal