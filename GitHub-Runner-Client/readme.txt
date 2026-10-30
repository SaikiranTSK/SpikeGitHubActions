GitHub Actions runner for side PCs (replaces Jenkins\Jenkins-CI-Client)
=======================================================================

Same software on every side PC, but each side PC is registered as its own runner.
Do NOT copy a configured C:\actions-runner folder to another PC; always install from this package.

installing:
1. On GitHub go to the repo > Settings > Actions > Runners > New self-hosted runner (Windows, x64).
   Copy the token from the "config.cmd --url ... --token XXXXX" line (valid for about 1 hour).
2. Copy GitHub-Runner-Client to the side PC.
   Optional (no internet on the side PC): also copy actions-runner-win-x64-2.337.0.zip into this folder.
3. Start an admin command prompt and run:
     cd <path>\GitHub-Runner-Client [enter]
     install.cmd <SidePcName> <Token> [enter]
   e.g. install.cmd Kratu_BLR <Token>
   SidePcName must match the SystemName option in the workflow (take care about the capital letters!!!)
   The service runs as Local System (like the Jenkins agent); tests are started in the logged-in
   user's session by RunAsCurrentUser.exe, so keep the test user logged in (auto-logon).
4. Check GitHub > Settings > Actions > Runners: the runner shows as Idle with labels
   self-hosted, Windows, X64, <SidePcName>.

optional parameters (append after the token):
   -ServiceAccount DOMAIN\user                          run the service as this account instead of Local System
                                                        (.\user = local; password is asked for)
   -UseNetworkService                                   run the service as NT AUTHORITY\NETWORK SERVICE (no password)
   -Proxy http://proxy:8080                             if the side PC needs a proxy to reach github.com
   -RepoUrl https://github.com/<org>/<repo>             default: https://github.com/SaikiranTSK/SpikeGitHubActions
   -InstallDir C:\actions-runner                        default install folder
   -WorkDir D:\Jenkins\_work                            runner work folder (Jenkins "Remote root directory"); default _work
   -Labels nlybstqvp4dt7nv                              extra labels, comma separated
                                                        (always added: <SidePcName> and the PC host name = Jenkins node label)

more runners on one PC (only for the Jenkins server PC, e.g. more parallel ELK / RV&S uploads):
     install.cmd nlybstqvp4dt7nv-2 <Token> -InstallDir C:\actions-runner-2 -Labels nlybstqvp4dt7nv
   Side PCs keep ONE runner (1 runner = 1 job = the Jenkins lock_<PC>).

workflow:
   The workflow must target the side PC by its label:
     runs-on: [self-hosted, Windows, '${{ inputs.SystemName }}']
   With only [self-hosted, Windows, X64], a job can go to any free side PC.

uninstalling:
1. On GitHub: Settings > Actions > Runners > <runner> > ... > Remove, copy the removal token.
2. Start an admin command prompt and run:
     cd <path>\GitHub-Runner-Client [enter]
     uninstall.cmd <RemovalToken> [enter]

Jenkins vs GitHub Actions:
   Jenkins-CI-Client                         GitHub-Runner-Client
   agent.jar + Java 8 + Jenkins-Agent.exe    actions-runner zip (no Java needed)
   edit [NODENAME] in Jenkins-Agent.xml      install.cmd <SidePcName> <Token>
   service jenkins-nlybstqvp4dt7nv-agent     service actions.runner.<owner>-<repo>.<SidePcName>
   connects to Jenkins server :8080          outbound HTTPS to github.com only
