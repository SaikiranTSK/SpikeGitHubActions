import org.jenkinsci.plugins.pipeline.modeldefinition.Utils

def CheckRunningOnNode(withRunJob = false) {
	if (( "${NODE_NAME}" == SystemName ) && ( "${NODE_NAME}" != "master" )) {
		echo "Running on Agent: ${SystemName}"
		catchError(buildResult: "SUCCESS", stageResult: "SUCCESS") {
			bat label: 'hostname', script: "hostname"
		}
		
	} else {
		error 'This test cannot run on the master!'
	}
	script {
		if (withRunJob) {
			currentBuild.displayName = "${SystemName}\\${RunJob}"
		} else {
			currentBuild.displayName = "${SystemName}"
		}
	}
}

def KillTasks() {
        catchError(buildResult: "SUCCESS", stageResult: "SUCCESS") {
			bat label: 'Kill', script: "taskkill /IM RunAsCurrentUser.exe /F"
        }
        catchError(buildResult: "SUCCESS", stageResult: "SUCCESS") {
            bat label: 'Kill', script: "taskkill /IM RunInCurrentUser.exe /F"
        }
        catchError(buildResult: "SUCCESS", stageResult: "SUCCESS") {
            bat label: 'Kill', script: "taskkill /IM TAFTafFVAdapterCSExeCOMServer.exe /F"
        }
        catchError(buildResult: "SUCCESS", stageResult: "SUCCESS") {
            bat label: 'Kill', script: "taskkill /IM nunit-agent-x86.exe >nul /F"
        }
}

def StartTestBatch() {
    stage(env.JOB_NAME) {
        def exitCode = -1
        KillTasks()
        catchError(buildResult: "SUCCESS", stageResult: "SUCCESS") {
            exitCode = bat label: 'RunTest', returnStatus: true, script: "\"${env.DataPath}tools\\RunAsCurrentUser.exe\" \"${env.DataPath}${RunJob}\" \"${RunJob}\""
        }
        if (exitCode == 9999) {
            TalkText("Job stopped by user")
            currentBuild.result = 'ABORTED'
        }
        if (exitCode != 0) {
            error("Job Failed")
        }
    }      
}

def StartJob(batchFileName, jobPipelineName, systemName, batchFolderName, batchFileNameFull, buildResult, stageResult)
{
    TalkText(batchFileName + " has been started", 100)
    def result
    catchError(buildResult: "${buildResult}", stageResult: "${stageResult}") {

        CheckRunningOnNode()
        result = build(job: jobPipelineName, parameters: [string(name: 'SystemName', value: systemName),string(name: 'RunJob', value: "${batchFolderName}\\${batchFileNameFull}")]);
    }
    if (result != null) { 
        TalkText(batchFileName + " has been completed with ${result.result}", 100)
        return result.result
    } else {
       TalkText(batchFileName + " has been completed with FAILURE", 100)
       return "FAILURE"
    }
}

def TalkText(text, volume = 100)
{
    bat label: 'RunTest', returnStdout: false, script: env.DataPath + "\\Tools\\Talk.cmd \"" + text + "\" " + volume
}

def StartTestsFromBatch(batchfilesPath, systemName, batchFolderName) {
    def files
    def skipOnPass = true
    def anyFail = false

    // Setup command to get all .cmd files within the specified batchfilesPath
	def command = "@dir /b /o:N /a:-D \"" + batchfilesPath + "\\*.cmd\" 2>nul"
	echo "Command to find all batchfiles: " + command
    // Get all .cmd files within the specified batchfilesPath
	def ret=bat(script: command, returnStdout: true)
    // split the found files to get an array
	files = ret.split('\\r?\\n')

    echo "Found batch files:"
    files.each { batchFileNameFull -> 
        echo batchFileNameFull
    }

    files.each { batchFileNameFull -> 
        echo batchFileNameFull
        KillTasks()
        def filePart = batchFileNameFull.replace('.cmd','').split('__')
        def batchFileNumber = filePart[0]
        def batchFileName = filePart[1]

        // Set default param value
        def param = "SOF"
        stage(batchFileName) {
            echo "Running test ${batchFileNumber}: ${batchFileName}"
            def jobPipelineName = "OtherTest"

            if (filePart.size() >= 3) {
                param = filePart[2]
            }

            def e2e
            switch(param) {
                case "COF":
                    echo "Continue on fail"
                    e2e = StartJob(batchFileName, jobPipelineName, systemName, batchFolderName, batchFileNameFull, "SUCCESS", "FAILURE")
                    if (e2e == "FAILURE") {
                        skipOnPass = false;
                        anyFail = true;
                    }
                    break;
                case "POF":
                    echo "Pass on fail"
                    e2e = StartJob(batchFileName, jobPipelineName, systemName, batchFolderName, batchFileNameFull, "SUCCESS", "SUCCESS")
                    if (e2e == "FAILURE") {
                        anyFail = true;
                    }
                    break;
                case "SOP":
                    echo "Skip on Pass"
                    if (skipOnPass == false) {
                        e2e = StartJob(batchFileName, jobPipelineName, systemName, batchFolderName, batchFileNameFull, "SUCCESS", "FAILURE")
                        if (e2e == "FAILURE") {
                            anyFail = true;
                        }
                    } else {
                        TalkText("${batchFileName} has been skipped", 100)
                        Utils.markStageSkippedForConditional(batchFileName)
                    }
                    break;
                //SOF -> Stop on Fail (default)
                default: 
                    echo "Stop on Fail (default)"
                    e2e = StartJob(batchFileName, jobPipelineName, systemName, batchFolderName, batchFileNameFull, "FAILURE", "FAILURE")
                    echo e2e
                    if (e2e == "FAILURE") {
                        anyFail = true;
                    }
                    break
            }
            if ((e2e == "FAILURE") && (param == "SOF")) {
                error('Batch failed.')
            }
        }
    }
    if (anyFail) {
        error('Batch failed.')
    }
}
return  this