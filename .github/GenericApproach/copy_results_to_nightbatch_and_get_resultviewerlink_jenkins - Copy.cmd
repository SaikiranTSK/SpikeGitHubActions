echo on
echo %1

set var1="D:/Jenkins/Tools/RunAsCurrentUser.exe"
set var2=D:/Jenkins/GenericApproach/copy_results_to_nightbatch_and_get_resultviewerlink_side_pc.cmd
set var3=%1
set var4=%var1% "%var2% %var3%"

call %var4%
echo RESULT=%ResultViewerLink%
