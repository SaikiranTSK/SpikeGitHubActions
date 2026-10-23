set mydir=%~dp0
%mydir%psexec -h regedit /s "%~dp0\Autologon.reg"
%mydir%psexec -h w32tm /config /update
%mydir%psexec -h \\127.0.0.1 netsh interface ipv4 set address “Control Network” static 192.68.32.7 255.255.255.192

shutdown /r /f /t 5
