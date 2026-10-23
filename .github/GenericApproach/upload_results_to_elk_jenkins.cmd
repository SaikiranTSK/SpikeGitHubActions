echo on
echo %1
echo %2
echo %3

set var1="D:/Jenkins/Tools/RunAsCurrentUser.exe"
set var2=D:/Jenkins/GenericApproach/upload_results_to_elk_side_pc.cmd
set var3=%1
set var4=%2
set var5=%3
set var6=%var1% "%var2% %var3% %var4% %var5%"

call %var6%
