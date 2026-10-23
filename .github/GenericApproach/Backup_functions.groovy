import org.jenkinsci.plugins.pipeline.modeldefinition.Utils
import hudson.FilePath;
import jenkins.model.Jenkins;
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

def TalkText(text, volume = 100)
{
    bat label: 'RunTest', returnStdout: false, script: env.DataPath + "\\Tools\\Talk.cmd \"" + text + "\" " + volume
}

def CopyFile(String serverPath, String clientPath)
{
    println("Copy from server '" + serverPath + "' to client '" + clientPath + "'.")
    if (env['NODE_NAME'] == null) {
        error "envvar 'NODE_NAME' is not set, probably not inside an node {} or running an older version of Jenkins!";
    } else if (env['NODE_NAME'].equals("master")) {
        fp = new FilePath(clientPath);
    } else {
        fp = new FilePath(Jenkins.getInstance().getComputer(env['NODE_NAME']).getChannel(), clientPath);
    }
    if(fp != null)
    {
        def data = new File(serverPath)
        fp.copyFrom(new ByteArrayInputStream(data.bytes)); //writing to file
    }
}

def PrintStageHeader(headerName)
{
	def stageData = "# STAGE ${headerName}".padRight(119) + "#";
	echo "########################################################################################################################\n${stageData}\n########################################################################################################################";
}

def StartStage_PrepareEnvironment()
{
    stage('Prepare Environment')
    {
		script
		{
			
			/*
			Run*CurrentUser.exe are in use and cannot be copied, newest version is already copied via jenkins so skip the copy of it.
			Create batch file to run as Jenkins has a bug on parsing dualquotes to the batch call.
			Also when creating batch file, the RunAsCurrentUser doesn't have to run for each call.
			*/
			def commandData = "";
            commandData += GetKillingCommands();
           	commandData += "robocopy.exe /E /MIR \"${env.ServerDataPath}Tools\" \"${env.DataPath}Tools\" /XF Run*CurrentUser.exe\n";
			commandData += "robocopy.exe /E /MIR \"${env.ServerDataPath}Packages\" \"${env.DataPath}Packages\" /XF Run*CurrentUser.exe\n";
			commandData += "robocopy.exe /E /MIR \"${env.ServerDataPath}Batches\" \"${env.DataPath}Batches\" /XF Run*CurrentUser.exe\n";
			commandData += "robocopy.exe /E /MIR \"${env.ServerDataPath}Packages\\SpecFlow.2.3.2\" \"C:\\Temp\\FAST\\Tools\\SpecFlow.2.3.2\" /XF Run*CurrentUser.exe\n";
			commandData += "Echo cleanup\n";
			commandData += "DEL /F/Q %~f0\n";
			writeFile(file: "${env.DataPath}command.cmd", text: commandData, encoding: "UTF-8");
			ExecuteCommand("Copying data", "${env.DataPath}command.cmd");
		}
	}
}

def ExecuteCommand(commandTitle, command, skipOnAbort = true, runOnMaster = false)
{
	def exitCode = -1;
	
	    bat label: 'Killing Tasks', returnStatus: true, script:
		'''
            @echo off
			echo "Killing tasks (ignore the process not found errors)" 
			taskkill /F /IM "TAFTafFVAdapterCSExeCOMServer.exe"
			taskkill /F /IM "nunit-agent-x86.exe"
			taskkill /F /IM "RunAsCurrentUser.exe"
			taskkill /F /IM "RunInCurrentUser.exe"
			taskkill /F /IM "iCaptureRestServer.exe"
			taskkill /F /IM "iCapture.exe"
            exit /B 0
		'''
		def runAsCurrentUser = "${env.DataPath}Tools\\RunAsCurrentUser.exe";
		if (runOnMaster == true)
		{
			runAsCurrentUser = "${env.JenkinsBatchesPath}Tools\\RunAsCurrentUser.exe";
		}
		sleep(time:1,unit:"SECONDS")
		println("### EXECUTE ${commandTitle}: ${command}")
		//Don't fail the build on failed stage, only fail the stage.
		catchError(buildResult: "NOT_BUILT", stageResult: "FAILURE")
		{
			exitCode = bat label: commandTitle, returnStatus: true, script: "\"${runAsCurrentUser}\" \"${command}\""
		}
		//Script stopped by user via ForceClose button
		if (exitCode == 9999) {
			_buildFailed = true;
			_buildAborted = true;
		}
		
	return exitCode;
}

return  this