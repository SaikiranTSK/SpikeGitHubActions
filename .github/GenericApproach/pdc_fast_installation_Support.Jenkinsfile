pipeline
{
  agent
  {
    label env.SystemName
  }

  stages
  {
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
          bat label: 'Install FAST from PDC for HardShutdownRecovery', returnStatus: true, script:
          "D:/Jenkins/GenericApproach/pdc_install_fast_jenkins.cmd ${env.JOB_BASE_NAME} \
            \"${PDCVersion}\" \
            \"${PDCPath}\""
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
