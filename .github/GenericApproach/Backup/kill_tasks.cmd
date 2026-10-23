@echo off

echo "START Killing tasks (START IGNORE ERRORS)"
taskkill /IM TAFTafFVAdapterCSExeCOMServer.exe /F
taskkill /IM nunit-agent-x86.exe >nul /F
taskkill /IM RunAsCurrentUser.exe /F
echo "END Killing tasks (END IGNORE ERRORS)"
