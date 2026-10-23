# TestStarterDevelopment tooling

`TestStarterDevelopment.yml` checks out `.github` on the selected Windows runner.
The workflow uses `.github\Tools\RunAsCurrentUser.exe` (and the adjacent
`RunInCurrentUser.exe`) and detects which checked-in NUnit runner to use:

- NUnit 2: `.github\Packages\NUnit 2.6.2\bin\nunit-console-x86.exe`
- NUnit 3: `.github\Packages\NUnit.org\nunit-console\nunit3-console.exe`

Keep each package's accompanying DLLs and configuration files in the checkout.
Prepare Node fails explicitly if a required launcher or runner is missing.
No tooling is copied from Jenkins shares or staged under `D:\Jenkins`.
The workflow ignores the legacy `DATA_PATH`, `SERVER_DATA_PATH`,
`JENKINS_BATCHES_PATH`, and `BATCHES_SHARE` tooling overrides.

Generated test, reset, preparation, and result-copy command files use
`RUNNER_TEMP` (`TEMP` when running outside Actions), including cancellation
cleanup. The interactive user launched by `RunAsCurrentUser.exe` must have
read/execute access to the checkout and read/write access to that temp directory.
The existing interactive-session and installed .NET prerequisites still apply.

`TestsLocation` remains the source of test inputs. `SaveLocation`, tracing,
results, optional media copying, loop behavior, and cancellation/reset behavior
are unchanged. `GenericApproach` is not invoked by this workflow: its stages
generate NUnit and result-copy commands directly. Other workflows and the
legacy helpers in `Shared\functions.ps1` retain their existing paths.

Run the isolated regression checks from the repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .github\scripts\TestStarterDevelopment\Tests.ps1
```

These checks mock process execution and network access. They do not launch
NUnit, kill processes, or copy real test data. A full acceptance run still
requires the selected self-hosted Windows test system and its input/output shares.
