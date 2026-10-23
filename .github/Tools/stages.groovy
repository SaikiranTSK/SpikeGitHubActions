import org.jenkinsci.plugins.pipeline.modeldefinition.Utils

def testBatchLocation = "NOT_FILLED_IN"
def testBatch = ""
def pdc = ""
def exitCode = -1
def copyResult = true
def genericApproachLocation = "GenericApproach2"
def buildFailed = false

def StartStage_CheckRunningOnNode(withRunJob = false)
{
	stage('Check running on node') {	
		script
		{		
			println("########################################\n# STAGE CHECK RUNNING ON NODE          #\n########################################")
			if (( "${NODE_NAME}" == SystemName ) && ( "${NODE_NAME}" != "master" )) {
				echo "Running on Agent: ${SystemName}"
				catchError(buildResult: "SUCCESS", stageResult: "SUCCESS") {
					bat label: 'hostname', script: "hostname"
				}
			} else {
				error 'This test cannot run on the master!'
			}
			if (withRunJob) {
				currentBuild.displayName = "${SystemName}\\${RunJob}"
			} else {
				currentBuild.displayName = "${SystemName}"
			}
		}
	}
}

def StartStage_RestartSidePC()
{
    stage('Restart SidePC') {
        script
        {
			println("########################################\n# STAGE RESTART SIDEPC                 #\n########################################")
			ExecuteCommand("Restart SidePC", "%SYSTEMROOT%\\system32\\shutdown.exe /r /f /t 5");
        }
    }
}

def StartStage_PrepareEnvironment()
{
    stage('Prepare Environment')
    {
		script
		{
			println("########################################\n# STAGE PREPARE ENVIRONMENT            #\n########################################")
			ExecuteCommand("Copying nunit & specflow files", "${env.DataPath}Batches\\${genericApproachLocation}\\copy_nunit_specflow.cmd");
			ExecuteCommand("Killing Tasks", "${env.DataPath}Batches\\${genericApproachLocation}\\kill_tasks.cmd");
			ExecuteCommand("Install FAST", "${env.DataPath}Batches\\${genericApproachLocation}\\install_fast_side_pc.cmd");
		}
    }
}

def StartStage_ExecuteTests()
{
    stage('Execute Tests')
    {
		script
		{
			println("########################################\n# STAGE EXECUTE TESTS                  #\n########################################")
			ExecuteCommand("Execute Tests", "\\\"${env.DataPath}Batches\\${genericApproachLocation}\\execute_test_batch_side_pc.cmd\\\" \\\"${env.JOB_BASE_NAME}\\\"");
		}
    }
}

def StartStage_CopyResultsToNightbatch()
{
    stage('Copy results to nightbatch')
    {
		script
        {
			println("########################################\n# STAGE COPY RESULTS TO NIGHTBATCH     #\n########################################")
			try
			{
				ExecuteCommand("Copy results to nightbatch", "\\\"${env.DataPath}Batches\\${genericApproachLocation}\\copy_results_to_nightbatch_side_pc.cmd\\\" \\\"${env.JOB_BASE_NAME}\\\"");
				if (UploadELK == "true")
				{
					//Get location from copy results to nightbatch
					echo "${data}"
					testBatchLocation = (data.replace('[','').replace("'",'').replace(']','').split(','))[0] =~ /\{.+?\}/
					echo "${testBatchLocation}"
					testBatchLocation = testBatchLocation[0].replace('{','').replace('}','')
					echo "${testBatchLocation}"
				}
			}
			catch(Exception e)
			{
				copyResult = false
			}
        }
    }
}

def StartStage_UploadToELK()
{
	stage('Upload results to ELK')
	{
		agent
		{
			label 'master'
		}
	
		script
		{
			println("########################################\n# STAGE UPLOAD RESULTS TO ELK          #\n########################################")
			if (UploadELK == "true")
			{
				//Check location format
				if (testBatchLocation != "NOT_FILLED_IN" && testBatchLocation != "")
                {
                    //Update location by removing last backslash if supplied.
                    if (testBatchLocation.reverse().take(1).reverse() == '\\')
                    {
                        testBatchLocation = testBatchLocation.substring(0, testBatchLocation.length() - 1)
                    }
                    //Trim spaces is not working, so remove last space if supplied.
                    if (testBatchLocation.reverse().take(1).reverse() == ' ')
                    {
                        testBatchLocation = testBatchLocation.substring(0, testBatchLocation.length() - 1)
                    }
                    //Trim spaces is not working, so remove first space if supplied.
                    if (testBatchLocation.take(1) == ' ')
                    {
                        testBatchLocation = testBatchLocation.substring(1)
                    }
                    //Set buildname.
                    def urlData = testBatchLocation
                    testBatch = urlData.substring(urlData.lastIndexOf('\\') + 1, urlData.length())
                    urlData = urlData.substring(0, urlData.lastIndexOf('\\'))
                    pdc = urlData.substring(urlData.lastIndexOf('\\') + 1, urlData.length())
                    urlData = urlData.substring(0, urlData.lastIndexOf('\\'))
                    def system = urlData.substring(urlData.lastIndexOf('\\') + 1, urlData.length())

                    println "Uploading '" + urlData + "' to ELK."
                    try
                    {
						ExecuteCommand("Install ElasticSearch Module", "pip install elasticsearch");
                        if (exitCode != 0)
                        {
                            error("Installation of ElasticSearch Module failed...")
                        }
						ExecuteCommand("Upload results to ELK", "python \"${JenkinsBatchesPath}Batches\\${genericApproachLocation}\\ELK\\DataParseAndUploadScript.py\" --indexname system_performance --datalocation \"${testBatchLocation}\"");
                        if (exitCode != 0)
                        {
                            error("Upload of the testbatch data failed failed, check results in logging...")
                        }
                    }
                    catch (Exception ex)
                    {
                        error("Upload to ELK skipped, because python script failed: " + ex.toString())
                    }
                }
                else
                {
                    error("Incorrect input path: " + testBatchLocation)
                }		
			}
			else
			{
				println("Skip uploading to ELK as `UploadELK != true`, actual: " + UploadELK);
			}
		}
	}
}

def ExecuteCommand(commandTitle, command)
{
	println("### EXECUTE ${commandTitle}: ${command}")
	//Don't fail the build on failed stage, only fail the stage.
	catchError(buildResult: "SUCCESS", stageResult: "FAILURE")
	{
		exitCode = bat label: commandTitle, returnStatus: true, script: "\"${env.DataPath}Tools\\RunAsCurrentUser.exe\" \"${command}\""
	}
	//Script stopped by user via ForceClose button
    if (exitCode == 9999) {
        currentBuild.result = 'ABORTED'
    }	
}

return  this