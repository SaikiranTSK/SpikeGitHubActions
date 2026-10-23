script
{
   currentBuild.description = env.JobName
}

pipeline
{
  // # of executors should be set to 4

  agent
  {
    label env.SystemName
  }

  stages
  {
    stage ('Invoke SWInstallation')
    {
      steps
      {
        catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE')
        {
          script
          {
            build job: '../Steps/SWInstallation', parameters: [
              string(name: 'SystemName', value: env.SystemName),
              string(name: 'PDCVersion', value: env.PDCVersion),
              string(name: 'PDCPath', value: env.PDCPath),
              string(name: 'SystemConfigFile', value: env.SystemConfigFile),
              string(name: 'SystemManifestFile', value: env.SystemManifestFile),
              string(name: 'WVDSystemManifestFile', value: env.WVDSystemManifestFile),
              string(name: 'RetryInstallation', value: env.RetryInstallation)
            ]
          }
        }
      }
    }

    stage ('Invoke UploadLicense')
    {
      steps
      {
        catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE')
        {
          script
          {
            build job: '../Steps/UploadLicense', parameters: [
              string(name: 'SystemName', value: env.SystemName),
              string(name: 'PDCVersion', value: env.PDCVersion),
              string(name: 'PDCPath', value: env.PDCPath),
              string(name: 'LicenseFilePath', value: env.LicenseFilePath),
              string(name: 'LicenseType', value: env.LicenseType)
            ]
          }
        }
      }
    }

    stage ('Invoke Customization')
    {
      steps
      {
        catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE')
        {
          script
          {
            build job: '../Steps/Customization', parameters: [
              string(name: 'SystemName', value: env.SystemName),
              string(name: 'PDCVersion', value: env.PDCVersion),
              string(name: 'PDCPath', value: env.PDCPath),
              string(name: 'EPXBatchVerification', value: env.EPXBatchVerification),
              string(name: 'RadiationAtPowerOnDisabledStatusValue', value: env.RadiationAtPowerOnDisabledStatusValue),
              string(name: 'CalibrationData', value: env.CalibrationData),
              string(name: 'TimeServer', value: env.TimeServer),
              string(name: 'TableIsoHeight', value: env.TableIsoHeight),
              string(name: 'AirflowBox', value: env.AirflowBox),
              string(name: 'CeilingInlet', value: env.CeilingInlet),
              string(name: 'CeilingRailExtensionSide', value: env.CeilingRailExtensionSide),
              string(name: 'MinimalFloorDistance', value: env.MinimalFloorDistance),
              string(name: 'PivotDirection', value: env.PivotDirection),
              string(name: 'Spacer', value: env.Spacer),
              string(name: 'TableTiltAngleLimitNegative', value: env.TableTiltAngleLimitNegative),
              string(name: 'TableTiltAngleLimitPositive', value: env.TableTiltAngleLimitPositive),
              string(name: 'LoadEPXDatabase', value: env.LoadEPXDatabase),
              string(name: 'HospitalName', value: env.HospitalName),
              string(name: 'DepartmentName', value: env.DepartmentName),
              string(name: 'LocalSystemId', value: env.LocalSystemId),
              string(name: 'HospitalNetwork', value: env.HospitalNetwork),
              string(name: 'HospitalNetworkIPAddress', value: env.HospitalNetworkIPAddress),
              string(name: 'HospitalNetworkSubnetMask', value: env.HospitalNetworkSubnetMask),
              string(name: 'HospitalNetworkDefaultGateway', value: env.HospitalNetworkDefaultGateway),
              string(name: 'HospitalNetworkDNS1', value: env.HospitalNetworkDNS1),
              string(name: 'HospitalNetworkDNS2', value: env.HospitalNetworkDNS2),
              string(name: 'HospitalNetworkDNSSuffix', value: env.HospitalNetworkDNSSuffix),
              string(name: 'VolumeEndOfExposureBeep', value: env.VolumeEndOfExposureBeep),
              string(name: 'VolumeEndOfRunBeep', value: env.VolumeEndOfRunBeep),
              string(name: 'VolumeExposureActiveBuzzer', value: env.VolumeExposureActiveBuzzer),
              string(name: 'VolumeFluo5minBuzzer', value: env.VolumeFluo5minBuzzer),
              string(name: 'VolumeFluoActiveBuzzer', value: env.VolumeFluoActiveBuzzer),
              string(name: 'VolumeHighDoseFluoBuzzer', value: env.VolumeHighDoseFluoBuzzer),
              string(name: 'VolumeBodyGuardOverrideBuzzer', value: env.VolumeBodyGuardOverrideBuzzer),
              string(name: 'PhysioChannel1', value: env.PhysioChannel1),
              string(name: 'PhysioChannel2', value: env.PhysioChannel2),
              string(name: 'PhysioChannel3', value: env.PhysioChannel3),
              string(name: 'PhysioChannel4', value: env.PhysioChannel4),
              string(name: 'PhysioChannelRTOP_DIG', value: env.PhysioChannelRTOP_DIG),
              string(name: 'PhysioChannelQRS', value: env.PhysioChannelQRS),
              string(name: 'DoorContactPresence', value: env.DoorContactPresence)
            ]
          }
        }  
      }
    }

    stage ('Invoke Restore')
    {
      steps
      {
        catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE')
        {
          script
          {
            build job: '../Steps/Restore', parameters: [
              string(name: 'SystemName', value: env.SystemName),
              string(name: 'PDCVersion', value: env.PDCVersion),
              string(name: 'PDCPath', value: env.PDCPath),
              string(name: 'RestoreName', value: env.RestoreName),
              string(name: 'RestoreLocationOnSuitePC', value: env.RestoreLocationOnSuitePC),
              string(name: 'RestoreFromLocation', value: env.RestoreFromLocation),
              string(name: 'Customization', value: env.Customization),
              string(name: 'RestoreValueForEPXBatchVerification', value: env.RestoreValueForEPXBatchVerification),
              string(name: 'RestoreValueForLoadEPXDatabase', value: env.RestoreValueForLoadEPXDatabase),
              string(name: 'RestoreValueForRadiationAtPowerOnDisabledStatusValue', value: env.RestoreValueForRadiationAtPowerOnDisabledStatusValue),
              string(name: 'GeoCalibrationRestoreFromLocation', value: env.GeoCalibrationRestoreFromLocation),
              string(name: 'GeoCalibrationRestoreName', value: env.GeoCalibrationRestoreName),
              string(name: 'RestoreGeoCalibration', value: env.RestoreGeoCalibration)
            ]
          }
        }
      }
    }

    stage ('Invoke Backup')
    {
      steps
      {
        catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE')
        {
          script
          {
            build job: '../Steps/Backup', parameters: [
              string(name: 'SystemName', value: env.SystemName),
              string(name: 'PDCVersion', value: env.PDCVersion),
              string(name: 'PDCPath', value: env.PDCPath),
              string(name: 'BackupName', value: env.BackupName),
              string(name: 'BackupLocationOnSuitePC', value: env.BackupLocationOnSuitePC),
              string(name: 'BackupToLocation', value: env.BackupToLocation),
              string(name: 'BackupLocationForGeoCalibrationOnSuitePC', value: env.BackupLocationForGeoCalibrationOnSuitePC),
              string(name: 'BackupToLocationForGeoCalibration', value: env.BackupToLocationForGeoCalibration),
              string(name: 'BackupNameForGeoCalibration', value: env.BackupNameForGeoCalibration),
              string(name: 'BackupGeoCalibration', value: env.BackupGeoCalibration)
            ]
          }
        }
      }
    }

    stage ('Invoke AcceptanceTesting')
    {
      steps
      {
        catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE')
        {
          script
          {
            build job: '../Steps/AcceptanceTesting', parameters: [
              string(name: 'SystemName', value: env.SystemName),
              string(name: 'PDCVersion', value: env.PDCVersion),
              string(name: 'PDCPath', value: env.PDCPath)
            ]
          }
        }
      }
    }
  }
}
