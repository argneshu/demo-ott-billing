# merge-verdict.ps1 — PowerShell variant of merge-verdict.sh. See that file for the full contract and
# rationale. Runs inside the `verdict` job; downloads of every gate-<name> artifact must already be in
# place under $DownloadRoot before this runs.
param(
  [string]$DownloadRoot = "tests/.evals/_run/downloaded"
)
$ErrorActionPreference = "Continue"

$EvalKey = $env:EVAL_KEY
if (-not $EvalKey) { Write-Error "merge-verdict: ERROR: EVAL_KEY is required"; exit 2 }

$EvidenceDir = "reports/eval-evidence/$EvalKey"
New-Item -ItemType Directory -Force -Path $EvidenceDir | Out-Null
New-Item -ItemType Directory -Force -Path "tests/.evals/_run" | Out-Null

$Config = "tests/.evals/config.json"
$Model = "unknown"; $RubricVersion = "unknown"
if (Test-Path $Config) {
  try {
    $cfg = Get-Content $Config -Raw | ConvertFrom-Json
    if ($cfg.judge.model) { $Model = $cfg.judge.model }
    if ($cfg.judge.rubricVersion) { $RubricVersion = $cfg.judge.rubricVersion }
  } catch {}
}
$Gates = @()
if (Test-Path $Config) {
  try { $Gates = @((Get-Content $Config -Raw | ConvertFrom-Json).ci.gates) } catch { $Gates = @() }
}

function Get-JobDefaultStatus($result) {
  if ($result -eq "skipped") { return "N/A" }
  return "ERROR"
}
function Get-JobDefaultReason($result) {
  if ($result -eq "skipped") { return "job skipped - its condition was not met (earned N/A, common/ci-pipeline-generation.md Section 4.0j)" }
  if (-not $result) { return "job result unavailable - gate produced no result" }
  return "job result '$result' but the gate produced no downloaded evidence file - declared but never run"
}

$GateStatus = @{}
$GateReason = @{}

# 🔴 EVERY path below is FLAT: $DownloadRoot/gate-<name>/<filename> — never nested, even though each
#    gate job's own upload step uploads a repo-relative directory/file list. actions/upload-artifact@v4
#    strips the least-common-ancestor of whatever `path:` it is given, so a repo-relative prefix never
#    survives to the downloaded artifact. See merge-verdict.sh's matching comment for the production
#    failure this fixes.

# D1-D7 + unitCoverage: concatenate gate-static's and gate-unit's own static-results.json.gates copies.
foreach ($sub in @("gate-static", "gate-unit")) {
  $f = Join-Path $DownloadRoot "$sub/static-results.json.gates"
  if (Test-Path $f) {
    Get-Content $f | ForEach-Object {
      $parts = $_ -split "`t"
      if ($parts.Length -ge 2 -and $parts[0]) {
        $GateStatus[$parts[0]] = $parts[1]
        $GateReason[$parts[0]] = if ($parts.Length -ge 3) { $parts[2] } else { "" }
      }
    }
  }
}

# J1/J2 from the judge job's own eval.json — only these two entries are trusted from it.
$judgeEvalJson = Join-Path $DownloadRoot "gate-judge/eval.json"
if (Test-Path $judgeEvalJson) {
  try {
    $je = Get-Content $judgeEvalJson -Raw | ConvertFrom-Json
    foreach ($g in @("J1_architecture", "J2_security")) {
      if ($je.gates.$g) {
        $GateStatus[$g] = $je.gates.$g.status
        $GateReason[$g] = $je.gates.$g.reason
      }
    }
  } catch {}
}

# behaviorB1/B2/B3 from the behavior job's own status files.
foreach ($t in @("behaviorB1", "behaviorB2", "behaviorB3")) {
  $sf = Join-Path $DownloadRoot "gate-behavior/$t.status"
  if (Test-Path $sf) {
    $GateStatus[$t] = (Get-Content $sf -Raw).Trim()
    $GateReason[$t] = "from workflow step outcome"
  }
}

# sonarqube from the sonarqube job's own status file.
$sonarStatusFile = Join-Path $DownloadRoot "gate-sonar/sonarqube.status"
if (Test-Path $sonarStatusFile) {
  $GateStatus["sonarqube"] = (Get-Content $sonarStatusFile -Raw).Trim()
  $GateReason["sonarqube"] = "from workflow step outcome"
}
$sonarConditions = Join-Path $DownloadRoot "gate-sonar/sonar-conditions.txt"
if (Test-Path $sonarConditions) { Copy-Item $sonarConditions "tests/.evals/_run/sonar-conditions.txt" -Force }

# playwright — only meaningful when appended to ci.gates.
$playwrightStatusFile = Join-Path $DownloadRoot "gate-playwright/playwright.status"
if (Test-Path $playwrightStatusFile) {
  $GateStatus["playwright"] = (Get-Content $playwrightStatusFile -Raw).Trim()
  $GateReason["playwright"] = "from workflow step outcome"
}

function Get-GateOwnerResult($g) {
  if ($g -match '^D[1-7]_') { return $env:STATIC_RESULT }
  switch ($g) {
    "unitCoverage" { return $env:UNIT_RESULT }
    "behaviorB1" { return $env:BEHAVIOR_RESULT }
    "behaviorB2" { return $env:BEHAVIOR_RESULT }
    "behaviorB3" { return $env:BEHAVIOR_RESULT }
    "playwright" { return $env:PLAYWRIGHT_RESULT }
    "J1_architecture" { return $env:JUDGE_RESULT }
    "J2_security" { return $env:JUDGE_RESULT }
    "sonarqube" { return $env:SONAR_RESULT }
    default { return "" }
  }
}

$AggFail = @{}
$gatesOut = [ordered]@{}
$anyFail = $false
foreach ($g in $Gates) {
  if ($GateStatus.ContainsKey($g)) {
    $st = $GateStatus[$g]; $rs = $GateReason[$g]
  } else {
    $owner = Get-GateOwnerResult $g
    $st = Get-JobDefaultStatus $owner
    $rs = Get-JobDefaultReason $owner
  }
  if ($st -eq "FAIL" -or $st -eq "ERROR") {
    $anyFail = $true
    if ($g -match '^D[1-7]_') { $AggFail["static"] = 1 }
    elseif ($g -eq "unitCoverage") { $AggFail["unit"] = 1; $AggFail["coverage"] = 1 }
    elseif ($g -like "behavior*") { $AggFail["behavior"] = 1 }
    elseif ($g -eq "playwright") { $AggFail["playwright"] = 1 }
    elseif ($g -eq "J1_architecture" -or $g -eq "J2_security") { $AggFail["judge"] = 1 }
    elseif ($g -eq "sonarqube") { $AggFail["sonar"] = 1 }
  }
  $gatesOut[$g] = [ordered]@{ status = $st; reason = $rs }
}

$evalJsonObj = [ordered]@{
  evalKey = $EvalKey
  model = $Model
  rubricVersion = $RubricVersion
  gates = $gatesOut
  verdict = if ($anyFail) { "FAIL" } else { "PASS" }
}
$evalJsonPath = "$EvidenceDir/eval.json"
$evalJsonObj | ConvertTo-Json -Depth 10 | Set-Content -Encoding utf8 $evalJsonPath

$summaryLines = @("# AIRE eval summary - $EvalKey", "", "| Gate | Status | Notes |", "|---|---|---|")
foreach ($g in $Gates) {
  $summaryLines += "| $g | $($gatesOut[$g].status) | $($gatesOut[$g].reason) |"
}
$summaryLines += ""
$summaryLines += "**Verdict:** $($evalJsonObj.verdict)"
$summaryLines | Set-Content -Encoding utf8 "$EvidenceDir/eval-summary.md"

$aggregates = @(
  @{ name = "static"; result = $env:STATIC_RESULT },
  @{ name = "unit"; result = $env:UNIT_RESULT },
  @{ name = "coverage"; result = $env:UNIT_RESULT },
  @{ name = "behavior"; result = $env:BEHAVIOR_RESULT },
  @{ name = "playwright"; result = $env:PLAYWRIGHT_RESULT },
  @{ name = "judge"; result = $env:JUDGE_RESULT },
  @{ name = "sonar"; result = $env:SONAR_RESULT }
)
$failed = New-Object System.Collections.Generic.List[string]
foreach ($a in $aggregates) {
  $isAggFail = $AggFail.ContainsKey($a.name)
  if ($a.result -eq "failure" -or $a.result -eq "cancelled" -or $isAggFail) {
    if (-not $failed.Contains($a.name)) { $failed.Add($a.name) }
  }
}
$failed | Sort-Object -Unique | Set-Content -Encoding utf8 "tests/.evals/_run/failed-gates.txt"

Write-Output "merge-verdict: wrote $evalJsonPath (verdict $($evalJsonObj.verdict)); failed-gates.txt: $($failed -join ' ')"
if ($failed.Count -gt 0) { exit 1 }
exit 0
