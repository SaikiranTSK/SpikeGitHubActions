def dataLocation
def copyResult = true

pipeline
{
  agent
  {
    label env.SystemName
  }

  options
  {
    lock(resource: "lock_" + env.SystemName)
  }

  stages
  {
    stage('Copy tools from share')
    {
      steps
      {
        bat label: 'Copying Jenkins batches & tools', returnStatus: true, script: 
        '''
          robocopy /E /ZB "//nlybstqvp4dt7nv.code1.emi.philips.com/JenkinsBatches/Tools" "D:/Jenkins/Tools"
          robocopy /E /ZB "//nlybstqvp4dt7nv.code1.emi.philips.com/JenkinsBatches/Batches/GenericApproach" "D:/Jenkins/GenericApproach"
        '''
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
        bat label: 'Copying nunit & specflow files', returnStatus: true, script: 
        '''
          call "D:/Jenkins/GenericApproach/copy_nunit_specflow.cmd"
        '''
        
        bat label: 'Killing Tasks', returnStatus: true, script:
        '''
            echo "Killing tasks"
            taskkill /IM TAFTafFVAdapterCSExeCOMServer.exe /F
            taskkill /IM nunit-agent-x86.exe >nul /F
            taskkill /IM RunAsCurrentUser.exe /F
        '''

        bat label: 'Install FAST', returnStatus: true, script:
        "D:/Jenkins/GenericApproach/install_fast_jenkins.cmd ${Branch}"
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
          if (UploadELK == "true")
          {
            try
            {
              def data = bat(label: 'Copy results to nightbatch', script: "D:/Jenkins/GenericApproach/copy_results_to_nightbatch_jenkins.cmd ${env.JOB_BASE_NAME}", returnStdout: true).replace('[','').replace("'",'').replace(']','').split(',')
              echo "${data}"
              dataLocation = data[0] =~ /\{.+?\}/
              echo "${dataLocation}"
              dataLocation = dataLocation[0].replace('{','').replace('}','')
              echo "${dataLocation}"            
            }
            catch(Exception e)
            {
              copyResult = false
            }
          }
          else
          {
            echo "Upload to ELK skipped"
            bat label: 'Copy results to nightbatch', script:
            "D:/Jenkins/GenericApproach/copy_results_to_nightbatch_jenkins.cmd ${env.JOB_BASE_NAME}"
          }
        }
      }
    }

    stage('Upload results to ELK')
    {
      agent
      {
          label 'master'
      }

      steps
      {
        dir("C:/Users/NLYBSTQVP4-sys134")
        {
          script
          {
            if (UploadELK == "true")
            {
              if (copyResult == true)
              {
                // For this to work, every Side PC needs to be installed with Python and corresponding modules.
                // Because of this, Upload to ELK will run on the Jenkins master.
                // bat label: 'Upload results to ELK', script:
                // "D:/Jenkins/GenericApproach/upload_results_to_elk_jenkins.cmd ${env.JOB_BASE_NAME} system_performance ${dataLocation}"

                try
                {
                  catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE')
                  {
                    bat label: 'Upload results to ELK', returnStatus: true, script:
                    'python ..//..//JenkinsBatches/Batches/GenericApproach/ELK/DataParseAndUploadScript.py' + ' --indexname system_performance --datalocation ' + dataLocation
                    
                  }
                }
                catch(Exception e)
                {
                  echo "Upload to ELK skipped, because python script failed"
                }
              }
              else
              {
                echo "Upload to ELK skipped, because copy results failed"
              }
            }
            else
            {
              echo "Upload to ELK skipped"
            }
          }
        }
      }
    }
  }
}
