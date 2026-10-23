taskkill /f /im storescp.exe
taskkill /f /fi "WINDOWTITLE eq DICOM StoreSCP"
taskkill /f /fi "WINDOWTITLE eq Administrator: DICOM StoreSCP"
taskkill /f /fi "WINDOWTITLE eq Administrator:  DICOM StoreSCP"

set "dicomdir=NONE"
if exist "C:\Data\DICOM Soft\Output" set "dicomdir=C:\Data\DICOM Soft\Output"
if exist "D:\DICOM SOFT\Output" set "dicomdir=D:\DICOM SOFT\Output"

if ("%dicomdir%"=="NONE") exit
start "DICOM StoreSCP" /MIN /D "%dicomdir%" %windir%\system32\cmd.exe /K "color 97&TITLE DICOM StoreSCP&..\bin\storescp.exe" -v -aet LOCAL_AETITLE --reject --ignore -pm -up 7004&exit