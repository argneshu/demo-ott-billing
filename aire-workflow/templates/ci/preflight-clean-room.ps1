# preflight-clean-room.ps1 — PowerShell variant of preflight-clean-room.sh. See that file for the full
# contract, rationale and the P1/P2/P3 failure-signature list (common/ci-pipeline-generation.md Section
# 4.0i.1/4.0i.2). This script only makes the ENVIRONMENT explicit and reproducible — it does not change
# what counts as a failure or how it is repaired.
param([string]$IntegrationBranch = "")
$ErrorActionPreference = "Continue"

$Wf = ".github/workflows/agentic-eval-pipeline.yml"
$RunDir = "tests/.evals/_run"
New-Item -ItemType Directory -Force -Path $RunDir | Out-Null

if (-not $IntegrationBranch) {
  Write-Error "preflight-clean-room: ERROR: -IntegrationBranch is required (e.g. epic/PROJ-100-title)"
  exit 2
}

function Resolve-Image {
  $runsOn = ""
  if (Test-Path $Wf) {
    $line = Get-Content $Wf | Where-Object { $_ -match 'runs-on:' } | Select-Object -First 1
    if ($line) { $runsOn = ($line -replace '.*runs-on:\s*', '') -replace '"', '' }
  }
  switch -Regex ($runsOn.Trim()) {
    '^ubuntu-latest$|^ubuntu-24\.04$|^$' { return "catthehacker/ubuntu:act-24.04" }
    '^ubuntu-22\.04$' { return "catthehacker/ubuntu:act-22.04" }
    '^ubuntu-20\.04$' { return "catthehacker/ubuntu:act-20.04" }
    default { return "catthehacker/ubuntu:act-24.04" }
  }
}

$BaseSha = $env:BASE_SHA
$behaviorTouched = $false
if ($BaseSha) {
  $changed = git diff --name-only $BaseSha -- tests/.evals/behavior/Containerfile tests/.evals/behavior/run.sh 2>$null
  if ($changed) { $behaviorTouched = $true }
}

if ($behaviorTouched -and (Test-Path "tests/.evals/behavior/Containerfile")) {
  $fromLine = Get-Content "tests/.evals/behavior/Containerfile" | Where-Object { $_ -match '^FROM' } | Select-Object -First 1
  $Image = ($fromLine -split '\s+')[1]
  Write-Output "preflight-clean-room: behaviour Containerfile touched - using its own base image $Image (P3)"
} else {
  $Image = Resolve-Image
}

$podman = Get-Command podman -ErrorAction SilentlyContinue
$fallback = $false
if (-not $podman) {
  $fallback = $true
  "preflight-clean-room: NOTE - podman not installed; falling back to ambient-shell isolation (weaker guarantee, V23-class drift may go undetected)." | Tee-Object -FilePath "$RunDir/preflight-clean-room.log" -Append
}

if (-not $BaseSha) {
  $BaseSha = (git merge-base "origin/$IntegrationBranch" HEAD 2>$null)
}
if (-not $BaseSha) {
  Write-Error "preflight-clean-room: ERROR: could not resolve BASE_SHA = git merge-base origin/$IntegrationBranch HEAD"
  exit 2
}

# P1 - declaration completeness
Write-Output "preflight-clean-room: P1 - declaration completeness (no environment needed)"
if (-not (Test-Path "tests/.evals/_run/merged-manifest.json") -and (Test-Path "tests/.evals/scripts/read-manifest.ps1")) {
  & pwsh -File "tests/.evals/scripts/read-manifest.ps1" | Out-Null
}
if (-not (Test-Path "tests/.evals/_run/merged-manifest.json")) {
  Write-Error "preflight-clean-room: P1 FAILURE - merged-manifest.json could not be derived"
  exit 1
}
$merged = Get-Content "tests/.evals/_run/merged-manifest.json" -Raw | ConvertFrom-Json
$missing = @()
foreach ($root in $merged) {
  foreach ($t in @($root.tools)) {
    if (-not $t) { continue }
    $hasInstall = $root.toolInstallCommands.$t
    if (-not $hasInstall) { $missing += $t }
  }
}
if ($missing.Count -gt 0) {
  Write-Error "preflight-clean-room: P1 FAILURE - tool(s) declared in 'tools' with no matching 'toolInstallCommands' entry: $($missing -join ', ')"
  exit 1
}
Write-Output "preflight-clean-room: P1 passed"

# P2 - clean-room execution of the real CI entrypoints
Write-Output "preflight-clean-room: P2 - clean-room execution of the real CI entrypoints (image: $Image)"
$p2Log = "$RunDir/preflight-clean-room-p2.log"
if ($fallback) {
  & bash tests/.evals/scripts/ci-manifest-runner.sh install $BaseSha 2>&1 | Tee-Object -FilePath $p2Log
  & bash tests/.evals/scripts/ci-manifest-runner.sh build $BaseSha 2>&1 | Tee-Object -FilePath $p2Log -Append
  & bash tests/.evals/scripts/run-static-evals.sh $BaseSha 2>&1 | Tee-Object -FilePath $p2Log -Append
  & bash tests/.evals/scripts/ci-manifest-runner.sh coverage $BaseSha 2>&1 | Tee-Object -FilePath $p2Log -Append
} else {
  $cmd = "bash tests/.evals/scripts/ci-manifest-runner.sh install '$BaseSha' && " +
         "bash tests/.evals/scripts/ci-manifest-runner.sh build '$BaseSha' && " +
         "bash tests/.evals/scripts/run-static-evals.sh '$BaseSha' && " +
         "bash tests/.evals/scripts/ci-manifest-runner.sh coverage '$BaseSha'"
  & podman run --rm -v "${PWD}:/work:Z" -w /work $Image bash -lc $cmd 2>&1 | Tee-Object -FilePath $p2Log
}

$p2Content = Get-Content $p2Log -Raw
$signaturePattern = 'is not installed on this runner|command not found|No such file or directory|ModuleNotFoundError|ImportError|RuntimeError: .* requires the .* package|Cannot find module|ResolutionImpossible|ERESOLVE|no findings at base or head.*zero output at BOTH ends'
if ($p2Content -match $signaturePattern) {
  Write-Error "preflight-clean-room: FAILED at P2 - provisioning/declaration gap detected (Section 4.0i.2). Fix the declaration, never the gate."
  exit 1
}

# P3 - behavioural provisioning note (reuse, never re-run)
if ($behaviorTouched) {
  Write-Output "preflight-clean-room: P3 - behaviour Containerfile/run.sh touched; its own containerised behavioural gate run IS this unit's clean-room evidence for the image change."
} else {
  Write-Output "preflight-clean-room: P3 - behaviour image untouched; reusing already-containerised behavioural gate evidence, never re-run."
}

Write-Output "preflight-clean-room: PASSED - manifest is executable on $Image."
exit 0
