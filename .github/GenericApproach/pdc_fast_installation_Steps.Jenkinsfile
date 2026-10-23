pipeline
{
  agent
  {
    label env.SystemName
  }

  // should not be used for jobs in the Support folder
  options
  {
    lock(resource: "lock_" + env.SystemName)
  }

  stages
  {
    stage ('Invoke HardShutdownRecovery')
    {
      steps
      {
        catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS')
        {
          script
          {
            if (env.JOB_BASE_NAME == 'UploadLicense')
            {
              build job: '../Support/HardShutdownRecovery', parameters: [
                string(name: 'SystemName', value: env.SystemName),
                string(name: 'PDCVersion', value: env.PDCVersion),
                string(name: 'PDCPath', value: env.PDCPath)
              ]
            }
            else if (env.JOB_BASE_NAME == 'Customization')
            {
              build job: '../Support/HardShutdownRecovery', parameters: [
                string(name: 'SystemName', value: env.SystemName),
                string(name: 'PDCVersion', value: env.PDCVersion),
                string(name: 'PDCPath', value: env.PDCPath)
              ]
            }
            else if (env.JOB_BASE_NAME == 'Backup')
            {
              build job: '../Support/HardShutdownRecovery', parameters: [
                string(name: 'SystemName', value: env.SystemName),
                string(name: 'PDCVersion', value: env.PDCVersion),
                string(name: 'PDCPath', value: env.PDCPath)
              ]
            }
            else if (env.JOB_BASE_NAME == 'Restore')
            {
              build job: '../Support/HardShutdownRecovery', parameters: [
                string(name: 'SystemName', value: env.SystemName),
                string(name: 'PDCVersion', value: env.PDCVersion),
                string(name: 'PDCPath', value: env.PDCPath)
              ]
            }
            else if (env.JOB_BASE_NAME == 'VTP')
            {
              build job: '../Support/HardShutdownRecovery', parameters: [
                string(name: 'SystemName', value: env.SystemName),
                string(name: 'PDCVersion', value: env.PDCVersion),
                string(name: 'PDCPath', value: env.PDCPath)
              ]
            }
          }
        }
      }
    }

    stage('Copy tools from share')
    {
      steps
      {
        script
        {
          def defaultmethods = load "D:/Jenkins/Batches/GenericApproach/functions.groovy"
          defaultmethods.CopyFile(env.JenkinsBatchesPath + "Batches\\GenericApproach\\functions.groovy" , env.DataPath + "Batches\\GenericApproach\\functions.groovy")
          defaultmethods.StartStage_PrepareEnvironment()
        }
      }
    }

    stage('Check running on node')
    {
      steps
      {
        script
        {
          def defaultmethods = load "D:/Jenkins/Tools/functions.groovy"
          defaultmethods.CheckRunningOnNode()
        }
      }
    }

    stage('Prepare Environment')
    {
      steps
      {
        bat label: 'Killing Tasks', returnStatus: true, script:
        '''
            echo "Killing tasks"
            taskkill /IM TAFTafFVAdapterCSExeCOMServer.exe /F
            taskkill /IM nunit-agent-x86.exe >nul /F
            taskkill /IM RunAsCurrentUser.exe /F
        '''

        script
        {
          if (env.JOB_BASE_NAME == 'SWInstallation')
          {
            bat label: 'Install FAST from PDC for SWInstallation', returnStatus: true, script:
            "D:/Jenkins/GenericApproach/pdc_install_fast_jenkins.cmd ${env.JOB_BASE_NAME} \
              \"${PDCVersion}\" \
              \"${PDCPath}\" \
              \"${SystemConfigFile}\" \
              \"${SystemManifestFile}\" \
              \"${WVDSystemManifestFile}\" \
              \"${RetryInstallation}\""
          }
          else if (env.JOB_BASE_NAME == 'UploadLicense')
          {
            bat label: 'Install FAST from PDC for UploadLicense', returnStatus: true, script:
            "D:/Jenkins/GenericApproach/pdc_install_fast_jenkins.cmd ${env.JOB_BASE_NAME} \
              \"${PDCVersion}\" \
              \"${PDCPath}\" \
              \"${LicenseFilePath}\" \
              \"${LicenseType}\""
          }
          else if (env.JOB_BASE_NAME == 'Customization')
          {
            bat label: 'Install FAST from PDC for Customization', returnStatus: true, script:
            "D:/Jenkins/GenericApproach/pdc_install_fast_jenkins.cmd ${env.JOB_BASE_NAME} \
              \"${PDCVersion}\" \
              \"${PDCPath}\" \
              \"${EPXBatchVerification}\" \
              \"${RadiationAtPowerOnDisabledStatusValue}\" \
              \"${CalibrationData}\" \
              \"${TimeServer}\" \
              \"${TableIsoHeight}\" \
              \"${AirflowBox}\" \
              \"${CeilingInlet}\" \
              \"${CeilingRailExtensionSide}\" \
              \"${MinimalFloorDistance}\" \
              \"${PivotDirection}\" \
              \"${Spacer}\" \
              \"${TableTiltAngleLimitNegative}\" \
              \"${TableTiltAngleLimitPositive}\" \
              \"${LoadEPXDatabase}\" \
              \"${HospitalName}\" \
              \"${DepartmentName}\" \
              \"${LocalSystemId}\" \
              \"${HospitalNetwork}\" \
              \"${HospitalNetworkIPAddress}\" \
              \"${HospitalNetworkSubnetMask}\" \
              \"${HospitalNetworkDefaultGateway}\" \
              \"${HospitalNetworkDNS1}\" \
              \"${HospitalNetworkDNS2}\" \
              \"${HospitalNetworkDNSSuffix}\" \
              \"${VolumeEndOfExposureBeep}\" \
              \"${VolumeEndOfRunBeep}\" \
              \"${VolumeExposureActiveBuzzer}\" \
              \"${VolumeFluo5minBuzzer}\" \
              \"${VolumeFluoActiveBuzzer}\" \
              \"${VolumeHighDoseFluoBuzzer}\" \
              \"${VolumeBodyGuardOverrideBuzzer}\" \
              \"${PhysioChannel1}\" \
              \"${PhysioChannel2}\" \
              \"${PhysioChannel3}\" \
              \"${PhysioChannel4}\" \
              \"${PhysioChannelRTOP_DIG}\" \
              \"${PhysioChannelQRS}\" \
              \"${DoorContactPresence}\""
          }
          else if (env.JOB_BASE_NAME == 'Backup')
          {
            bat label: 'Create a System Backup', returnStatus: true, script:
            "D:/Jenkins/GenericApproach/pdc_install_fast_jenkins.cmd ${env.JOB_BASE_NAME} \
              \"${PDCVersion}\" \
              \"${PDCPath}\" \
              \"${BackupName}\" \
              \"${BackupLocationOnSuitePC}\" \
              \"${BackupToLocation}\" \
              \"${BackupLocationForGeoCalibrationOnSuitePC}\" \
              \"${BackupToLocationForGeoCalibration}\" \
              \"${BackupNameForGeoCalibration}\" \
              \"${BackupGeoCalibration}\""
          }
         else if (env.JOB_BASE_NAME == 'Restore')
          {
            bat label: 'Restore a system backup', returnStatus: true, script:
            "D:/Jenkins/GenericApproach/pdc_install_fast_jenkins.cmd ${env.JOB_BASE_NAME} \
              \"${PDCVersion}\" \
              \"${PDCPath}\" \
              \"${RestoreName}\" \
              \"${RestoreLocationOnSuitePC}\" \
              \"${RestoreFromLocation}\" \
              \"${Customization}\" \
              \"${RestoreValueForEPXBatchVerification}\" \
              \"${RestoreValueForLoadEPXDatabase}\" \
              \"${RestoreValueForRadiationAtPowerOnDisabledStatusValue}\" \
              \"${GeoCalibrationRestoreFromLocation}\" \
              \"${GeoCalibrationRestoreName}\" \
              \"${RestoreGeoCalibration}\""
          }
          else if (env.JOB_BASE_NAME == 'VTP')
          {
            bat label: 'Update VTP software', returnStatus: true, script:
            "D:/Jenkins/GenericApproach/pdc_install_fast_jenkins.cmd ${env.JOB_BASE_NAME} \
              \"${PDCVersion}\" \
              \"${PDCPath}\""
          }
          else
          {
            bat label: 'Install FAST from PDC', returnStatus: true, script:
            "D:/Jenkins/GenericApproach/pdc_install_fast_jenkins.cmd ${env.JOB_BASE_NAME} \
              \"${PDCVersion}\" \
              \"${PDCPath}\""
          }
        }
      }
    }

    stage('Execute Tests')
    {
      steps
      {
        catchError
        {
          bat label: 'Execute Tests', script:
          "D:/Jenkins/GenericApproach/execute_test_batch_jenkins.cmd ${env.JOB_BASE_NAME}"
        }
      }
    }

    stage('Copy results to nightbatch')
    {
      steps
      {
        script
        {
          bat label: 'Copy results to nightbatch', script:
          "D:/Jenkins/GenericApproach/copy_results_to_nightbatch_jenkins.cmd ${env.JOB_BASE_NAME}"
        }
      }
    }
  }
}
