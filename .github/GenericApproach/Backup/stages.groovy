import org.jenkinsci.plugins.pipeline.modeldefinition.Utils

def StartStage_CheckRunningOnNode(withRunJob = false) {
	stage('Check running on node') {	
		script
		{
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

def StartStage_RestartSidePC() {
    stage('Restart SidePC') {
        script
        {
                bat label: 'Restart SidePC', returnStatus: true, script: 
                '''
                call ''' + env.DataPath + '''Tools/RunAsCurrentUser.exe "%SYSTEMROOT%\\system32\\shutdown.exe /r /f /t 5"
                '''
        }
    }
}

return  this