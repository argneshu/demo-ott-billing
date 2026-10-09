# detect-stage-scopes.ps1 — PowerShell variant of detect-stage-scopes.sh. See that file for the full
# contract. Prints has_unit_tests/has_behavior_tests/has_e2e_tests/manifest_resolved, suitable for
# appending to $env:GITHUB_OUTPUT.
param([string]$EvalKey = "")
$ErrorActionPreference = "Continue"

$Config = "tests/.evals/config.json"

function Test-DirNonEmpty($path) {
  if (-not (Test-Path $path -PathType Container)) { return $false }
  $first = Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
  return $null -ne $first
}

$hasUnitTests = Test-DirNonEmpty "tests/unit"

$hasBehaviorTests = $false
if (Test-DirNonEmpty "tests/behavior") {
  $hasBehaviorTests = $true
} elseif (Test-Path "spec/behavior.feature" -PathType Leaf) {
  $hasBehaviorTests = $true
} elseif (Test-Path "spec/behavior" -PathType Container) {
  $feature = Get-ChildItem -Path "spec/behavior" -Filter "*.feature" -File -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($null -ne $feature) { $hasBehaviorTests = $true }
}

$hasE2eTests = $false
if ($EvalKey) {
  $hasE2eTests = Test-DirNonEmpty (Join-Path "tests/e2e" $EvalKey)
}

$manifestResolved = $false
if ((Test-Path $Config) -and (Get-Command jq -ErrorAction SilentlyContinue)) {
  $state = (jq -r '.ci.manifestState // "resolved"' $Config) 2>$null
  if (-not $state) { $state = "resolved" }
  $manifestResolved = ($state -eq "resolved")
}

function BoolStr($b) { if ($b) { "true" } else { "false" } }

$lines = @(
  "has_unit_tests=$(BoolStr $hasUnitTests)",
  "has_behavior_tests=$(BoolStr $hasBehaviorTests)",
  "has_e2e_tests=$(BoolStr $hasE2eTests)",
  "manifest_resolved=$(BoolStr $manifestResolved)"
)

$lines | ForEach-Object { Write-Output $_ }
if ($env:GITHUB_OUTPUT) { $lines | Out-File -Append -Encoding utf8 $env:GITHUB_OUTPUT }
