echo on

set jenkinsJobName=%1
SHIFT
set pdcVersion=%1
SHIFT
set pdcPath=%1
SHIFT
set var4=%1
SHIFT
set var5=%1
SHIFT
set var6=%1
SHIFT
set var7=%1
SHIFT
set var8=%1
SHIFT
set var9=%1
SHIFT
set var10=%1
SHIFT
set var11=%1
SHIFT
set var12=%1
SHIFT
set var13=%1
SHIFT
set var14=%1
SHIFT
set var15=%1
SHIFT
set var16=%1
SHIFT
set var17=%1
SHIFT
set var18=%1
SHIFT
set var19=%1
SHIFT
set var20=%1
SHIFT
set var21=%1
SHIFT
set var22=%1
SHIFT
set var23=%1
SHIFT
set var24=%1
SHIFT
set var25=%1
SHIFT
set var26=%1
SHIFT
set var27=%1
SHIFT
set var28=%1
SHIFT
set var29=%1
SHIFT
set var30=%1
SHIFT
set var31=%1
SHIFT
set var32=%1
SHIFT
set var33=%1
SHIFT
set var34=%1
SHIFT
set var35=%1
SHIFT
set var36=%1
SHIFT
set var37=%1
SHIFT
set var38=%1
SHIFT
set var39=%1
SHIFT
set var40=%1
SHIFT
set var41=%1

set pdcHardShutdownRecoveryJobName=HardShutdownRecovery
set pdcSWInstallationJobName=SWInstallation
set pdcUploadLicenseJobName=UploadLicense
set pdcCustomizationJobName=Customization
set pdcBackupJobName=Backup
set pdcRestoreJobName=Restore
set pdcVtpJobName=VTP
set pdcAcceptanceJobName=AcceptanceTesting

set test=false
if %test%==true (
    goto :WIP
) else (
    goto :PDC
)

:WIP
echo "Copy Tests from WIP storage"
set branchFolder=master
set wipFastMsiFolder=\\code1.emi.philips.com\storage\IGTS_WIP_Storage\CIBuilds\TestTooling\%branchFolder%
echo %wipFastMsiFolder%
Rem Go through build folders from Electricflow. Start with the most recent one.
FOR /F "delims=" %%i IN ('dir %wipFastMsiFolder% /b /ad-h /t:c /o-d') DO (
    Rem If FAST.msi exists inside build folder, the build was succesful, so it can be used for testing
    IF exist %wipFastMsiFolder%\%%i\Install\TestSystemsInstall\FAST\FAST.msi (
        SET buildfolder=%wipFastMsiFolder%\%%i\Install\TestSystemsInstall\FAST
        GOTO :found
    )
)

:PDC
echo "Copy Tests from PDC storage"
set pdcFastMsiFolder=%pdcPath%\%pdcVersion%
echo %pdcFastMsiFolder%
Rem If FAST.msi exists inside build folder, the build was succesful, so it can be used for testing
IF exist %pdcFastMsiFolder%\TestSystemsInstall\FAST\FAST.msi (
    SET buildfolder=%pdcFastMsiFolder%\TestSystemsInstall\FAST
    GOTO :found
)

Rem If none of the build folders would have a FAST.msi installer we do no proceed
echo "Could not find any build folders with FAST.msi"
GOTO: EOF

:found
echo Most recent subfolder with succesful build: %buildfolder%

robocopy %buildfolder% C:\Temp\FAST\Tests FAST.msi /W:30 /R:10 /np
IF %ERRORLEVEL% EQU 1 (
    set "errorlevel=0"
)

echo Uninstall FAST (might fail, because it can only unistall the same MSI as is currently installed)
msiexec /x C:\Temp\FAST\Tests\FAST.msi /passive /l*v "C:\Temp\fastMsiUninstall.log"
echo Install FAST (without input parameters, might remove previous install first if it is not the same)
msiexec /i C:\Temp\FAST\Tests\FAST.msi /l*v "C:\Temp\fastMsiInstall.log"

if %jenkinsJobName%==%pdcHardShutdownRecoveryJobName% (
    echo Install FAST for %jenkinsJobName%
    msiexec /x C:\Temp\FAST\Tests\FAST.msi /passive /l*v "C:\Temp\fastMsiUninstall_%jenkinsJobName%.log"
    msiexec /i C:\Temp\FAST\Tests\FAST.msi ^
        PDCVersion="%pdcVersion%" ^
        PDCPath="%pdcPath%" ^
        /l*v "C:\Temp\fastMsiInstall_%jenkinsJobName%.log"
) else if %jenkinsJobName%==%pdcSWInstallationJobName% (
    echo Install FAST for %jenkinsJobName%
    msiexec /x C:\Temp\FAST\Tests\FAST.msi /passive /l*v "C:\Temp\fastMsiUninstall_%jenkinsJobName%.log"
    msiexec /i C:\Temp\FAST\Tests\FAST.msi ^
        PDCVersion="%pdcVersion%" ^
        PDCPath="%pdcPath%" ^
        SystemConfigFile="%var4%" ^
        SystemManifestFile="%var5%" ^
        WVDSystemManifestFile="%var6%" ^
        RetryInstallation="%var7%" ^
        /l*v "C:\Temp\fastMsiInstall_%jenkinsJobName%.log"
) else if %jenkinsJobName%==%pdcUploadLicenseJobName% (
    echo Install FAST for %jenkinsJobName%
    msiexec /x C:\Temp\FAST\Tests\FAST.msi /passive /l*v "C:\Temp\fastMsiUninstall_%jenkinsJobName%.log"
    msiexec /i C:\Temp\FAST\Tests\FAST.msi ^
        PDCVersion="%pdcVersion%" ^
        PDCPath="%pdcPath%" ^
        LicenseFilePath="%var4%" ^
        LicenseType="%var5%" ^
        /l*v "C:\Temp\fastMsiInstall_%jenkinsJobName%.log"
) else if %jenkinsJobName%==%pdcCustomizationJobName% (
    echo Install FAST for %jenkinsJobName%
    msiexec /x C:\Temp\FAST\Tests\FAST.msi /passive /l*v "C:\Temp\fastMsiUninstall_%jenkinsJobName%.log"
    msiexec /i C:\Temp\FAST\Tests\FAST.msi ^
        PDCVersion="%pdcVersion%" ^
        PDCPath="%pdcPath%" ^
        EPXBatchVerification="%var4%" ^
        RadiationAtPowerOnDisabledStatusValue="%var5%" ^
        CalibrationData="%var6%" ^
        TimeServer="%var7%" ^
        TableIsoHeight="%var8%" ^
        AirflowBox="%var9%" ^
        CeilingInlet="%var10%" ^
        CeilingRailExtensionSide="%var11%" ^
        MinimalFloorDistance="%var12%" ^
        PivotDirection="%var13%" ^
        Spacer="%var14%" ^
        TableTiltAngleLimitNegative="%var15%" ^
        TableTiltAngleLimitPositive="%var16%" ^
        LoadEPXDatabase="%var17%" ^
        HospitalName="%var18%" ^
        DepartmentName="%var19%" ^
        LocalSystemId="%var20%" ^
        HospitalNetwork="%var21%" ^
        HospitalNetworkIPAddress="%var22%" ^
        HospitalNetworkSubnetMask="%var23%" ^
        HospitalNetworkDefaultGateway="%var24%" ^
        HospitalNetworkDNS1="%var25%" ^
        HospitalNetworkDNS2="%var26%" ^
        HospitalNetworkDNSSuffix="%var27%" ^
        VolumeEndOfExposureBeep="%var28%" ^
        VolumeEndOfRunBeep="%var29%" ^
        VolumeExposureActiveBuzzer="%var30%" ^
        VolumeFluo5minBuzzer="%var31%" ^
        VolumeFluoActiveBuzzer="%var32%" ^
        VolumeHighDoseFluoBuzzer="%var33%" ^
        VolumeBodyGuardOverrideBuzzer="%var34%" ^
        PhysioChannel1="%var35%" ^
        PhysioChannel2="%var36%" ^
        PhysioChannel3="%var37%" ^
        PhysioChannel4="%var38%" ^
        PhysioChannelRTOP_DIG="%var39%" ^
        PhysioChannelQRS="%var40%" ^
        DoorContactPresence="%var41%" ^
        /l*v "C:\Temp\fastMsiInstall_%jenkinsJobName%.log"
) else if %jenkinsJobName%==%pdcBackupJobName% (
    echo Install FAST for %jenkinsJobName%
    msiexec /x C:\Temp\FAST\Tests\FAST.msi /passive /l*v "C:\Temp\fastMsiUninstall_%jenkinsJobName%.log"
    msiexec /i C:\Temp\FAST\Tests\FAST.msi ^
        PDCVersion="%pdcVersion%" ^
        PDCPath="%pdcPath%" ^
        BackupName="%var4%" ^
        BackupLocationOnSuitePC="%var5%" ^
        BackupToLocation="%var6%" ^
        BackupLocationForGeoCalibrationOnSuitePC="%var7%" ^
        BackupToLocationForGeoCalibration="%var8%" ^
        BackupNameForGeoCalibration="%var9%" ^
        BackupGeoCalibration="%var10%" ^
        /l*v "C:\Temp\fastMsiInstall_%jenkinsJobName%.log"
) else if %jenkinsJobName%==%pdcRestoreJobName% (
    echo Install FAST for %jenkinsJobName%
    msiexec /x C:\Temp\FAST\Tests\FAST.msi /passive /l*v "C:\Temp\fastMsiUninstall_%jenkinsJobName%.log"
    msiexec /i C:\Temp\FAST\Tests\FAST.msi ^
        PDCVersion="%pdcVersion%" ^
        PDCPath="%pdcPath%" ^
        RestoreName="%var4%" ^
        RestoreLocationOnSuitePC="%var5%" ^
        RestoreFromLocation="%var6%" ^
        Customization="%var7%" ^
        RestoreValueForEPXBatchVerification="%var8%" ^
        RestoreValueForLoadEPXDatabase="%var9%" ^
        RestoreValueForRadiationAtPowerOnDisabledStatusValue="%var10%" ^
        GeoCalibrationRestoreFromLocation="%var11%" ^
        GeoCalibrationRestoreName="%var12%" ^
        RestoreGeoCalibration="%var13%" ^
        /l*v "C:\Temp\fastMsiInstall_%jenkinsJobName%.log"
) else if %jenkinsJobName%==%pdcVtpJobName% (
    echo Install FAST for %jenkinsJobName%
    msiexec /x C:\Temp\FAST\Tests\FAST.msi /passive /l*v "C:\Temp\fastMsiUninstall_%jenkinsJobName%.log"
    msiexec /i C:\Temp\FAST\Tests\FAST.msi ^
        PDCVersion="%pdcVersion%" ^
        PDCPath="%pdcPath%" ^
        /l*v "C:\Temp\fastMsiInstall_%jenkinsJobName%.log"
) else if %jenkinsJobName%==%pdcAcceptanceJobName% (
    echo Install FAST for %jenkinsJobName%
    msiexec /x C:\Temp\FAST\Tests\FAST.msi /passive /l*v "C:\Temp\fastMsiUninstall_%jenkinsJobName%.log"
    msiexec /i C:\Temp\FAST\Tests\FAST.msi ^
        PDCVersion="%pdcVersion%" ^
        PDCPath="%pdcPath%" ^
        /l*v "C:\Temp\fastMsiInstall_%jenkinsJobName%.log"
)

echo Old version of FAST was uninstalled and newest version was installed
