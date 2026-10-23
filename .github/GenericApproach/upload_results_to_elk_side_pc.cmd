echo on
echo %1
echo %2
echo %3

set ctqTestJobName=CriticalToQualityTesting
set crtTestJobName=ClinicalResponseTimesTesting
set crtElkTestJobName=ClinicalResponseTimesELK

if %1==%ctqTestJobName% goto uploadELK
if %1==%crtTestJobName% goto uploadELK
if %1==%crtElkTestJobName% goto uploadELK

echo No valid ELK upload job found
goto end

:uploadELK
echo "Parse and upload data to ELK for %1"
python "%~dp0ELK\DataParseAndUploadScript.py" --indexname %2 --datalocation "%~3"

:end
