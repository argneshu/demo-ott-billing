#!/usr/bin/env bash
# detect-stage-scopes.sh — emits the directory/config facts the split-job pipeline's per-stage `if:`
# conditions read (CI-SPLIT-JOBS-PLAN.md Section 1/2). Runs ONCE, inside the `setup` job, right after
# "Read manifest". A NEW, separate script from read-manifest.sh on purpose: read-manifest.sh's contract
# is STACK facts (has_node, node_version, ...); this script's contract is DIRECTORY/CONFIG SCOPE facts
# — a different concern, same single-responsibility split the framework already uses for
# resolve-eval-key.sh / read-manifest.sh / ci-manifest-runner.sh.
#
# Contract: takes the resolved EVAL_KEY as $1. Prints, suitable for appending to $GITHUB_OUTPUT:
#   has_unit_tests=true|false
#   has_behavior_tests=true|false
#   has_e2e_tests=true|false
#   manifest_resolved=true|false
#
# 🔴 has_e2e_tests is scoped to THIS work unit's own Playwright directory (tests/e2e/${EVAL_KEY}/),
#    never "does tests/e2e/ exist anywhere in the repo" — a later story's specs must never make an
#    earlier/unrelated story's CI job run Playwright (Section 1's own rule). ${EVAL_KEY} is already the
#    same work-unit slug every other evidence path is addressed by (reports/eval-evidence/${EVAL_KEY}),
#    so tests/e2e/${EVAL_KEY}/ follows the identical convention rather than inventing a second one.
#
# 🔴 A skipped job is an EARNED N/A, never a silent pass or a failure — these booleans are what let the
#    generated workflow's job-level `if:` express that ("Per-stage job conditionals from directory
#    structure", common/ci-pipeline-generation.md Section 4.0j).
set -uo pipefail

EVAL_KEY="${1:-}"
CONFIG="tests/.evals/config.json"

dir_nonempty() {
  [ -d "$1" ] && [ -n "$(find "$1" -type f -print -quit 2>/dev/null)" ]
}

has_unit_tests=false
dir_nonempty "tests/unit" && has_unit_tests=true

has_behavior_tests=false
if dir_nonempty "tests/behavior"; then
  has_behavior_tests=true
elif [ -f "spec/behavior.feature" ]; then
  has_behavior_tests=true
elif [ -d "spec/behavior" ] && find "spec/behavior" -maxdepth 1 -type f -name '*.feature' -print -quit 2>/dev/null | grep -q .; then
  has_behavior_tests=true
fi

has_e2e_tests=false
if [ -n "$EVAL_KEY" ] && dir_nonempty "tests/e2e/${EVAL_KEY}"; then
  has_e2e_tests=true
fi

manifest_resolved=false
if [ -f "$CONFIG" ] && command -v jq >/dev/null 2>&1; then
  state="$(jq -r '.ci.manifestState // "resolved"' "$CONFIG" 2>/dev/null || echo "resolved")"
  [ "$state" = "resolved" ] && manifest_resolved=true
fi

echo "has_unit_tests=${has_unit_tests}"
echo "has_behavior_tests=${has_behavior_tests}"
echo "has_e2e_tests=${has_e2e_tests}"
echo "manifest_resolved=${manifest_resolved}"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "has_unit_tests=${has_unit_tests}"
    echo "has_behavior_tests=${has_behavior_tests}"
    echo "has_e2e_tests=${has_e2e_tests}"
    echo "manifest_resolved=${manifest_resolved}"
  } >> "$GITHUB_OUTPUT"
fi
