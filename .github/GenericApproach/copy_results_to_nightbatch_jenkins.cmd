echo on
echo %1

rem Run directly from repo tooling; Mainline preflight requires a space-free workspace.
set var1="%~dp0..\Tools\RunAsCurrentUser.exe"
set var2=%~dp0copy_results_to_nightbatch_side_pc.cmd
set var3=%1
set var4=%var1% "%var2% %var3%"

call %var4%
