#!/usr/bin/env bash
# merge-verdict.sh — runs inside the `verdict` job (CI-SPLIT-JOBS-PLAN.md Section 3). Replaces the old
# single-job "read every sibling step's local file" merge run-evals.sh did when every gate ran inside
# one job. Across jobs, no gate job can see another gate job's local files — each one instead uploaded
# its own partial evidence as its own `gate-<name>` artifact, which the generated workflow already
# downloaded into DOWNLOAD_ROOT (one subdirectory per gate) before calling this script.
#
# 🔴 BYTE-COMPATIBLE OUTPUT CONTRACT — this reproduces the exact shape run-evals.sh used to write in the
#    single-job pipeline: reports/eval-evidence/${EVAL_KEY}/eval.json (evalKey/model/rubricVersion/
#    gates{status,reason}/verdict), eval-summary.md, and tests/.evals/_run/failed-gates.txt containing
#    the SAME seven aggregate names (static/unit/coverage/behavior/playwright/judge/sonar) the old
#    single Verdict step tallied. auto-fix-agent.sh reads both of those and needs ZERO changes.
#
# Usage: bash tests/.evals/scripts/merge-verdict.sh
# Required env: EVAL_KEY
# Optional env: DOWNLOAD_ROOT (default tests/.evals/_run/downloaded)
#   STATIC_RESULT UNIT_RESULT BEHAVIOR_RESULT PLAYWRIGHT_RESULT JUDGE_RESULT SONAR_RESULT
#   — each the workflow's own `needs.<job>.result` (success|failure|skipped|cancelled). A job the
#     workflow never ran (its `if:` was unmet) reports "skipped" here — that is an EARNED N/A, never a
#     failure and never a silent pass (Section 4.0j's own rule, applied at merge time).
set -uo pipefail

EVAL_KEY="${EVAL_KEY:-}"
if [ -z "$EVAL_KEY" ]; then
  echo "merge-verdict: ERROR: EVAL_KEY is required" >&2
  exit 2
fi

DOWNLOAD_ROOT="${DOWNLOAD_ROOT:-tests/.evals/_run/downloaded}"
EVIDENCE_DIR="reports/eval-evidence/${EVAL_KEY}"
mkdir -p "$EVIDENCE_DIR" tests/.evals/_run

CONFIG="tests/.evals/config.json"
MODEL="$(jq -r '.judge.model // "unknown"' "$CONFIG" 2>/dev/null || echo "unknown")"
RUBRIC_VERSION="$(jq -r '.judge.rubricVersion // "unknown"' "$CONFIG" 2>/dev/null || echo "unknown")"

GATES=(); while IFS= read -r line; do GATES+=("$line"); done < <(jq -r '.ci.gates[]?' "$CONFIG" 2>/dev/null | tr -d '\r')

# 🔴 job-result NORMALIZATION — a job whose `if:` was unmet reports result "skipped". That maps to an
#    earned N/A for every gate id that job owns and produced no file for; a job that ran and left no
#    file for a gate id it owns (failure/cancelled/success-with-missing-file) is an ERROR, never N/A,
#    same "declared but never run is never a silent pass" rule run-evals.sh already enforces (Section
#    4.0c.3). Mirrors run_evals.sh's own STATIC_STATUS[$g]:- absent -> ERROR branch, just re-derived
#    here from the job's OWN GitHub Actions result instead of a local file that job never wrote.
job_default_status() {
  case "${1:-}" in
    skipped) echo "N/A" ;;
    *) echo "ERROR" ;;
  esac
}
job_default_reason() {
  case "${1:-}" in
    skipped) echo "job skipped — its condition was not met (earned N/A, common/ci-pipeline-generation.md Section 4.0j)" ;;
    "") echo "job result unavailable — gate produced no result" ;;
    *) echo "job result '${1}' but the gate produced no downloaded evidence file — declared but never run" ;;
  esac
}

# 🔴 EVERY path below is FLAT: ${DOWNLOAD_ROOT}/gate-<name>/<filename> — never a nested repo-relative
#    path. Each gate job's own "Upload gate evidence" step uploads a repo-relative directory or file
#    list (e.g. `reports/eval-evidence/${key}/static/`) — but actions/upload-artifact@v4 strips the
#    least-common-ancestor of whatever `path:` it is given, so what actually survives to the artifact's
#    OWN root is that directory's CONTENTS, flat, never the original repo-relative prefix. Observed in
#    production without this: every gate id fell back to job_default_status/reason below ("declared
#    but never run"), including for jobs that genuinely succeeded — a real PASS was reported as a
#    phantom FAIL/ERROR because its own status file was never found at the (wrong) nested path this
#    script originally assumed. Keep this file's paths matched to the upload side's `path:` values —
#    never re-add a nested prefix here without re-verifying against a real upload/download round trip.

# ── D1-D7 + unitCoverage: concatenate the static-evals job's static-results.json.gates (D1-D7) with
#    the unit-coverage job's own copy (unitCoverage only) — each job started a FRESH file in its own
#    isolated workspace, so concatenating both reproduces exactly what one job's sequential D1-D7-then-
#    coverage run used to leave in a single file. ──
declare -A GATE_STATUS GATE_REASON
STATIC_GATES_FILE="${DOWNLOAD_ROOT}/gate-static/static-results.json.gates"
UNIT_GATES_FILE="${DOWNLOAD_ROOT}/gate-unit/static-results.json.gates"
for f in "$STATIC_GATES_FILE" "$UNIT_GATES_FILE"; do
  [ -f "$f" ] || continue
  while IFS=$'\t' read -r g s r; do
    [ -z "$g" ] && continue
    GATE_STATUS["$g"]="$s"; GATE_REASON["$g"]="$r"
  done < "$f"
done

# ── J1/J2: the judge job's own eval.json still ran run-evals.sh unmodified — it could not see the
#    other jobs' static/behavior/sonar results (they never reached its isolated workspace), so its
#    OWN copy of eval.json records those as ERROR "declared but never run" alongside real J1/J2 scores.
#    We take ONLY the J1_architecture/J2_security entries from it and discard the rest — the real values
#    for every other gate id come from that gate's OWN artifact above/below, never from the judge job's
#    incomplete local view. ──
JUDGE_EVAL_JSON="${DOWNLOAD_ROOT}/gate-judge/eval.json"
if [ -f "$JUDGE_EVAL_JSON" ] && command -v jq >/dev/null 2>&1; then
  for g in J1_architecture J2_security; do
    st="$(jq -r --arg g "$g" '.gates[$g].status // empty' "$JUDGE_EVAL_JSON" 2>/dev/null)"
    rs="$(jq -r --arg g "$g" '.gates[$g].reason // empty' "$JUDGE_EVAL_JSON" 2>/dev/null)"
    [ -n "$st" ] && GATE_STATUS["$g"]="$st"
    [ -n "$rs" ] && GATE_REASON["$g"]="$rs"
  done
fi

# ── behaviorB1/B2/B3: read the behavior job's own *.status files, exactly as run-evals.sh's
#    step_status() used to read them from the SAME job's local tests/.evals/_run/ before the split. ──
for t in behaviorB1 behaviorB2 behaviorB3; do
  sf="${DOWNLOAD_ROOT}/gate-behavior/${t}.status"
  if [ -f "$sf" ]; then
    GATE_STATUS["$t"]="$(cat "$sf")"
    GATE_REASON["$t"]="from workflow step outcome"
  fi
done

# ── sonarqube: same pattern, from the sonarqube job's own artifact. ──
SONAR_STATUS_FILE="${DOWNLOAD_ROOT}/gate-sonar/sonarqube.status"
if [ -f "$SONAR_STATUS_FILE" ]; then
  GATE_STATUS["sonarqube"]="$(cat "$SONAR_STATUS_FILE")"
  GATE_REASON["sonarqube"]="from workflow step outcome"
fi
mkdir -p tests/.evals/_run
[ -f "${DOWNLOAD_ROOT}/gate-sonar/sonar-conditions.txt" ] && \
  cp "${DOWNLOAD_ROOT}/gate-sonar/sonar-conditions.txt" tests/.evals/_run/sonar-conditions.txt

# ── playwright: appended to ci.gates only when playwright.enabled is true (Section 1's own rule) —
#    read it the same way, but it never blocks failed-gates.txt's aggregate tally below unless it is
#    actually a declared gate. ──
PLAYWRIGHT_STATUS_FILE="${DOWNLOAD_ROOT}/gate-playwright/playwright.status"
playwright_status=""
if [ -f "$PLAYWRIGHT_STATUS_FILE" ]; then
  playwright_status="$(cat "$PLAYWRIGHT_STATUS_FILE")"
  GATE_STATUS["playwright"]="$playwright_status"
  GATE_REASON["playwright"]="from workflow step outcome"
fi

# ── Build the consolidated eval.json — same shape as run-evals.sh's own, iterating ci.gates. A
#    declared gate id with no entry above falls back to the owning job's needs.<job>.result. ──
gate_owner_result() {
  case "$1" in
    D[1-7]_*) echo "${STATIC_RESULT:-}" ;;
    unitCoverage) echo "${UNIT_RESULT:-}" ;;
    behaviorB1|behaviorB2|behaviorB3) echo "${BEHAVIOR_RESULT:-}" ;;
    playwright) echo "${PLAYWRIGHT_RESULT:-}" ;;
    J1_architecture|J2_security) echo "${JUDGE_RESULT:-}" ;;
    sonarqube) echo "${SONAR_RESULT:-}" ;;
    *) echo "" ;;
  esac
}

EVAL_JSON="${EVIDENCE_DIR}/eval.json"
{
  echo '{'
  echo "  \"evalKey\": \"${EVAL_KEY}\","
  echo "  \"model\": \"${MODEL}\","
  echo "  \"rubricVersion\": \"${RUBRIC_VERSION}\","
  echo '  "gates": {'
  first=1
  any_fail=0
  declare -A AGG_FAIL   # aggregate name -> 1 if any gate mapped to it failed
  for g in "${GATES[@]}"; do
    if [ -n "${GATE_STATUS[$g]:-}" ]; then
      st="${GATE_STATUS[$g]}"; rs="${GATE_REASON[$g]:-}"
    else
      owner_result="$(gate_owner_result "$g")"
      st="$(job_default_status "$owner_result")"
      rs="$(job_default_reason "$owner_result")"
    fi
    case "$st" in FAIL|ERROR) any_fail=1 ;; esac
    [ $first -eq 1 ] && first=0 || echo ','
    printf '    "%s": {"status": "%s", "reason": "%s"}' "$g" "$st" "${rs//\"/\\\"}"

    gate_failed=0
    case "$st" in FAIL|ERROR) gate_failed=1 ;; esac
    if [ "$gate_failed" -eq 1 ]; then
      case "$g" in
        D[1-7]_*) AGG_FAIL["static"]=1 ;;
        unitCoverage) AGG_FAIL["unit"]=1; AGG_FAIL["coverage"]=1 ;;
        behaviorB1|behaviorB2|behaviorB3) AGG_FAIL["behavior"]=1 ;;
        playwright) AGG_FAIL["playwright"]=1 ;;
        J1_architecture|J2_security) AGG_FAIL["judge"]=1 ;;
        sonarqube) AGG_FAIL["sonar"]=1 ;;
      esac
    fi
  done
  echo ''
  echo '  },'
  if [ "$any_fail" -ne 0 ]; then echo '  "verdict": "FAIL"'; else echo '  "verdict": "PASS"'; fi
  echo '}'
} > "$EVAL_JSON"

# eval-summary.md — same human view the single-job pipeline used to publish.
{
  echo "# AIRE eval summary — ${EVAL_KEY}"
  echo ""
  echo "| Gate | Status | Notes |"
  echo "|---|---|---|"
  jq -r '.gates | to_entries[] | "| \(.key) | \(.value.status) | \(.value.reason) |"' "$EVAL_JSON"
  echo ""
  echo "**Verdict:** $(jq -r '.verdict' "$EVAL_JSON")"
} > "${EVIDENCE_DIR}/eval-summary.md"

# ── failed-gates.txt — the SAME seven aggregate names the old single Verdict step tallied, so
#    auto-fix-agent.sh needs zero changes. A job that never ran (skipped) never contributes a failure;
#    only a real FAIL/ERROR gate id, or a job result of failure/cancelled with nothing produced, does. ──
: > tests/.evals/_run/failed-gates.txt
for r in "static:${STATIC_RESULT:-}" "unit:${UNIT_RESULT:-}" "coverage:${UNIT_RESULT:-}" \
         "behavior:${BEHAVIOR_RESULT:-}" "playwright:${PLAYWRIGHT_RESULT:-}" \
         "judge:${JUDGE_RESULT:-}" "sonar:${SONAR_RESULT:-}"; do
  name="${r%%:*}"; result="${r##*:}"
  agg_fail="${AGG_FAIL[$name]:-0}"
  if [ "$result" = "failure" ] || [ "$result" = "cancelled" ] || [ "$agg_fail" = "1" ]; then
    echo "$name" >> tests/.evals/_run/failed-gates.txt
  fi
done
# de-duplicate while preserving first-seen order
sort -u -o tests/.evals/_run/failed-gates.txt tests/.evals/_run/failed-gates.txt

overall_verdict="$(jq -r '.verdict' "$EVAL_JSON")"
echo "merge-verdict: wrote ${EVAL_JSON} (verdict ${overall_verdict}); failed-gates.txt: $(tr '\n' ' ' < tests/.evals/_run/failed-gates.txt)"
[ -s tests/.evals/_run/failed-gates.txt ] && exit 1
exit 0
