echo on
setlocal
echo %1
echo %2

set var1="D:/Jenkins/Tools/RunAsCurrentUser.exe"
set var2=D:/Jenkins/GenericApproach/execute_test_batch_side_pc_Daily.cmd
set var3=%1
set "var4=%~2"
set var5=%var1% "%var2% %var3% %var4%"

call %var5%
endlocal