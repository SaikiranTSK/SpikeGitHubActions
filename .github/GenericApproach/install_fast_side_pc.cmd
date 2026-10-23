echo on
echo %1

set branchFolder=%1

echo "Copy Tests"
Rem Go through build folders from Electricflow. Start with the most recent one.
FOR /F "delims=" %%i IN ('dir \\code1.emi.philips.com\storage\IGTS_WIP_Storage\CIBuilds\TestTooling\%branchFolder% /b /ad-h /t:c /o-d') DO (
	Rem If FAST.msi exists inside build folder, the build was succesful, so it can be used for testing
	IF exist \\code1.emi.philips.com\storage\IGTS_WIP_Storage\CIBuilds\TestTooling\%branchFolder%\%%i\Install\TestSystemsInstall\FAST\FAST.msi (
                echo [INFO] FAST.msi found in: %%i
		SET buildfolder=%%i
		GOTO :found
	)
)

Rem If none of the build folders would have a FAST.msi installer we do no proceed
echo "Could not find any build folders with FAST.msi"
GOTO: EOF

:found
echo Most recent subfolder with succesful build: %buildfolder%

echo =====================================
echo Copying FAST.msi
echo =====================================

robocopy \\code1.emi.philips.com\storage\IGTS_WIP_Storage\CIBuilds\TestTooling\%branchFolder%\%buildfolder%\Install\TestSystemsInstall\FAST\ C:\Temp\FAST\Tests FAST.msi /W:30 /R:10 /np
echo [INFO] Robocopy FAST.msi ERRORLEVEL: %ERRORLEVEL%
IF %ERRORLEVEL% EQU 1 (
  set "errorlevel=0"  
)

echo =====================================
echo Copying Install Script
echo =====================================

Rem copy uninstallUninstall script
robocopy \\code1.emi.philips.com\storage\IGT-ATT\Scheduler\Tools C:\Temp\FAST\AuxiliaryInstallationScript UninstallInstallJenkins.cmd /W:30 /R:10 /np
echo [INFO] Robocopy Script ERRORLEVEL: %ERRORLEVEL%
IF %ERRORLEVEL% EQU 1 (
  set "errorlevel=0"  
)

echo =====================================
echo Starting Installation
echo =====================================
echo [TIME] Before install: %TIME%

Rem Uninstall old version of FAST and installs current one
START /WAIT powershell start -verb runas C:\Temp\FAST\AuxiliaryInstallationScript\UninstallInstallJenkins.cmd -ArgumentList "FAST", "C:\Temp\FAST\Tests\FAST.msi" -Wait
IF %ERRORLEVEL% EQU 1 (
  set "errorlevel=0"  
)
echo [TIME] After install: %TIME%
echo [INFO] Installation ERRORLEVEL: %ERRORLEVEL%

echo Old version of FAST was uninstalled and newest version was installed
