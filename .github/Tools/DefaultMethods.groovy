import org.jenkinsci.plugins.pipeline.modeldefinition.Utils

def WarnUser() {
    stage('WarnUser') {
        //def exitCode = -1
        //catchError(buildResult: "SUCCESS", stageResult: "SUCCESS") {
        //    exitCode = bat label: 'WarnUser', returnStatus: true, script: "\"${env.DataPath}tools\\RunAsCurrentUser.exe\" \"${env.DataPath}tools\\WarnUser.exe\""
        //}
        //if (exitCode == 9998) {
        //    TalkText("Job canceled by user")
        //    currentBuild.result = 'ABORTED'
        //}
        //if (exitCode != 0) {
        //    error("Job Failed with exit code: " + exitCode)
        //} else {
            KillTasks()
        //}
    }
}

def CheckRunningOnNode(withRunJob = false) {
    stage('CheckRunningOnNode') {
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
}

def KillTasks() {
        catchError(buildResult: "SUCCESS", stageResult: "SUCCESS") {
            bat label: 'Kill', script: "taskkill /IM RunAsCurrentUser.exe /F"
        }
        catchError(buildResult: "SUCCESS", stageResult: "SUCCESS") {
            bat label: 'Kill', script: "taskkill /IM RunInCurrentUser.exe /F"
        }
        catchError(buildResult: "SUCCESS", stageResult: "SUCCESS") {
            bat label: 'Kill', script: "taskkill /IM RunAsCurrentUserBangalore.exe /F"
        }
        catchError(buildResult: "SUCCESS", stageResult: "SUCCESS") {
            bat label: 'Kill', script: "taskkill /IM RunInCurrentUserBangalore.exe /F"
        }
        catchError(buildResult: "SUCCESS", stageResult: "SUCCESS") {
            bat label: 'Kill', script: "taskkill /IM TAFTafFVAdapterCSExeCOMServer.exe /F"
        }
        catchError(buildResult: "SUCCESS", stageResult: "SUCCESS") {
            bat label: 'Kill', script: "taskkill /IM nunit-agent-x86.exe /F"
        }
}

def StartTestBatch() {
    stage(env.JOB_NAME) {
        def exitCode = -1
        KillTasks()
        echo("Running from RunAsCurrentUser.exe")
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

def StartTestBatchBangalore() {
    stage(env.JOB_NAME) {
        def exitCode = -1
        KillTasks()
        catchError(buildResult: "SUCCESS", stageResult: "SUCCESS") {
            exitCode = bat label: 'RunTest', returnStatus: true, script: "\"${env.DataPath}tools\\RunAsCurrentUserBangalore.exe\" \"${env.DataPath}${RunJob}\" \"${RunJob}\""
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

def StartJob(TestName, JobPipelineName, SystemName, Batch, item, br, sr)
{
    TalkText(TestName + " has been started", 100)
    def result
    catchError(buildResult: "${br}", stageResult: "${sr}") {
        result = build(job: JobPipelineName, parameters: [string(name: 'SystemName', value: SystemName),string(name: 'RunJob', value: "${Batch}\\${item}")]);
    }
    if (result != null) { 
        TalkText(TestName + " has been completed with ${result.result}", 100)
        return result.result
    } else {
       TalkText(TestName + " has been completed with FAILURE", 100)
       return "FAILURE"
    }
}

def TalkText(text, volume = 100)
{
    bat label: 'RunTest', returnStdout: false, script: env.DataPath + "\\Tools\\Talk.cmd \"" + text + "\" " + volume
}

def SaveParametersForTesting(Batch)
{
    echo env.DataPath
    echo Batch
    echo TestsLocation
    bat label: 'CreateTestParameters', returnStdout: true, script: env.DataPath + "\\Tools\\WriteParams.cmd \"" + Batch +"\" " + TestsLocation
}

def StartTestsFromBatch(runPath) {
    def files
    def skipOnPass = true
    def anyFail = false
    stage("GetData") {
        def command = "@dir /b /o:N /a:-D \"" + runPath + "\\*.cmd\" 2>nul"
        echo command
        def ret=bat(script: command, returnStdout: true)
        files = ret.split('\\r?\\n')
    }
    //def jobs = Hudson.instance.getAllItems(org.jenkinsci.plugins.workflow.job.WorkflowJob)*.fullName
    files.each { item -> 
        echo item
    }
    files.each { item -> 
        echo item
        KillTasks()
        def filePart = item.replace('.cmd','').split('__')
        def param = ""
        stage(filePart[1]) {
            echo "Running test ${filePart[0]}: ${filePart[1]}"
            def JobPipelineName = "OtherTest"
            //if (filePart[1] in jobs) {
            //    JobPipelineName = "${filePart[1]}"
            //} else {
            //    JobPipelineName = "OtherTest"
            //}
            if (filePart.size() >= 3) {
                param = filePart[2]
            } else {
                param = "SOF"
            }
            def e2e
            switch(param) {
                case "COF":
                    echo "Continue on fail"
                    e2e = StartJob(filePart[1], JobPipelineName, SystemName, Batch, item, "SUCCESS", "FAILURE")
                    if (e2e == "FAILURE") {
                        skipOnPass = false;
                        anyFail = true;
                    }
                    break;
                case "POF":
                    echo "Pass on fail"
                    e2e = StartJob(filePart[1], JobPipelineName, SystemName, Batch, item, "SUCCESS", "SUCCESS")
                    if (e2e == "FAILURE") {
                        anyFail = true;
                    }
                    break;
                case "SOP":
                    echo "Skip on Pass"
                    if (skipOnPass == false) {
                        e2e = StartJob(filePart[1], JobPipelineName, SystemName, Batch, item, "SUCCESS", "FAILURE")
                        if (e2e == "FAILURE") {
                            anyFail = true;
                        }
                    } else {
                        TalkText("${filePart[1]} has been skipped", 100)
                        Utils.markStageSkippedForConditional(filePart[1])
                    }
                    break;
                //SOF -> Stop on Fail (default)
                default: 
                    echo "Stop on Fail (default)"
                    e2e = StartJob(filePart[1], JobPipelineName, SystemName, Batch, item, "FAILURE", "FAILURE")
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