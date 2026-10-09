#!/usr/bin/env bash
# behavior/run.sh — the SINGLE entry point for the Gherkin tiers. The developer, AIRE's local gate and
# CI all call `./tests/.evals/behavior/run.sh <tier>` so tier membership can never drift (Section 4.1b).
#
#   b1  this work unit's feature file only
#   b2  every OTHER ACTIVE feature file under spec/behavior/
#   b3  the whole ACTIVE cycle plus spec/behavior.feature (cross-story journeys) — last unit / base-branch PR
#
# 🔴 NO STUBS. A tier that cannot resolve any feature files exits NON-ZERO with the reason — it never
#    prints "ok" and exits 0 (Section 5.0). Tier membership is read from the spec/ layout here, never
#    duplicated in YAML.
#
# 🔴 THE ACTIVATION RULE (behavior-spec.md Section 6.0). EVERY work unit's .feature file is authored at
#    the STOP CHECKPOINT, before ANY code is generated (CLAUDE.md Step 1.7). So spec/behavior/ is fully
#    populated from the start, including units nobody has begun. Running those would fail the gate for
#    work never claimed to be done — a false negative, not a regression. A unit is ACTIVE when its row
#    in the RESOLVED Story Tracker is NOT "Ready for Development" — the shared ## Story Tracker in
#    runtime-artifacts/aire-state.md plus every runtime-artifacts/stories/*/state.md fragment
#    (parallel-work-state.md Section 4): claims live in fragments, so the shared row alone can be stale.
#    A unit with no row anywhere, or no state file at all, counts as ACTIVE (conservative).
#    B2/B3 run only ACTIVE files and PRINT the excluded ones. B1 is exempt — the unit being built is
#    active by definition.
#
# 🔴 exit 3 = N/A, in exactly these cases:
#    - spec/behavior/ contains ZERO feature files of ANY kind (no cycle in flight); or
#    - NO file is ACTIVE — the epic-level pre-handoff smoke test runs before any unit is started
#      (ci-pipeline-generation.md Section 4.0.6's documented "does NOT validate" scope), so every tier
#      is N/A there rather than a false ERROR; or
#    - the run's key is not a work unit at all (ci-*, ve-*) — all tiers N/A.
#    A tier that finds none of ITS OWN files while OTHER ACTIVE feature files exist is still a real
#    contract violation and stays exit 2 (ERROR).
set -uo pipefail

TIER="${1:-}"
BEHAVIOR_DIR="spec/behavior"
CROSS_STORY="spec/behavior.feature"

[ -n "$TIER" ] || { echo "run.sh: no tier supplied (b1|b2|b3)" >&2; exit 2; }

# 🔴 THIS FILE IS COPIED BYTE-FOR-BYTE. The ONLY region a generated repo may fill is between the
#    STACK-RESOLVED BEHAVIOUR RUNNER markers below. Editing anything else here is template drift
#    (ci-pipeline-generation.md Section 1): the fix lives in ONE repo, the next regeneration deletes
#    it, and every other project keeps the bug. A behaviour change belongs in templates/ci/behavior/run.sh.
#
# Environment:
#   AIRE_STORY_KEY  (optional but STRONGLY preferred for b1) — this work unit's key, e.g. "story-1.10",
#                   resolving to spec/behavior/story-1.10.feature. Set by the invoking implement
#                   workflow and by the CI behaviour step. Without it, b1 accepts a single feature file
#                   and ERRORS when several exist rather than guessing which unit is under test.
#
# The generator resolves the concrete runner invocation for this stack (cucumber-js / pytest-bdd /
# mvn verify / godog / reqnroll) between the markers below (Section 3). It MUST fail the process on a
# scenario failure and MUST NOT be replaced by an `echo ok`.
run_features() { # $@ = feature files
  [ "$#" -gt 0 ] || { echo "run.sh: tier ${TIER} resolved zero feature files" >&2; return 2; }
  # >>> STACK-RESOLVED BEHAVIOUR RUNNER START <<<
  echo "run.sh: no behaviour runner resolved for this stack — generation defect (ERROR, not a pass)" >&2
  return 2
  # >>> STACK-RESOLVED BEHAVIOUR RUNNER END <<<
}

no_stories_yet() { # true iff spec/behavior/ has literally zero *.feature files (not just zero for this tier)
  [ -z "$(ls -1 "${BEHAVIOR_DIR}"/*.feature 2>/dev/null || true)" ]
}

# --- ACTIVATION RULE (behavior-spec.md Section 6.0) ------------------------------------------------
# Every work unit's contract is authored at the STOP CHECKPOINT, before any code exists, so
# spec/behavior/ holds files for units nobody has started. Those are EXCLUDED from b2/b3 (and reported),
# because failing them would penalise work no one claimed to have done.
STATE_FILE="runtime-artifacts/aire-state.md"
ACTIVE=()
EXCLUDED=()

not_a_work_unit() { # true iff the supplied key belongs to an infrastructure run, not a work unit
  case "${1:-}" in ci-*|ve-*) return 0 ;; *) return 1 ;; esac
}

unit_key_of() { # spec/behavior/story-1.10.feature -> 1.10 ; bug-PROJ-123.feature -> PROJ-123
  local base
  base="$(basename "$1" .feature)"
  base="${base#story-}"
  base="${base#bug-}"
  base="${base#enhancement-}"
  base="${base#enh-}"
  printf '%s' "$base"
}

is_active() { # $1 = feature file path. Active unless EVERY resolved Story Tracker row for it says Ready for Development.
  local key rows f
  local files=()
  [ -f "$STATE_FILE" ] && files+=("$STATE_FILE")
  for f in runtime-artifacts/stories/*/state.md; do [ -f "$f" ] && files+=("$f"); done
  [ "${#files[@]}" -gt 0 ] || return 0        # no state file anywhere -> everything active
  key="$(unit_key_of "$1")"
  # Every row, in the shared file and every fragment, whose cells include the key (Story column or Tracker ID).
  rows="$(awk -v k="$key" -F'|' '
    /^[[:space:]]*\|/ {
      for (i = 2; i <= NF; i++) {
        cell = $i
        gsub(/[[:space:]]+/, "", cell)
        gsub(/\*/, "", cell)
        gsub(/`/, "", cell)
        if (cell == k) { print $0; next }
      }
    }' "${files[@]}" 2>/dev/null || true)"
  [ -n "$rows" ] || return 0                  # no row for this unit -> active (conservative)
  # Statuses only advance, so the unit is active as soon as ANY row (normally the fragment's) has moved on.
  if printf '%s\n' "$rows" | grep -qv "Ready for Development"; then return 0; fi
  return 1
}

partition_active() { # $@ = feature files -> fills ACTIVE[] and EXCLUDED[], reports the exclusions
  ACTIVE=()
  EXCLUDED=()
  local f
  for f in "$@"; do
    if is_active "$f"; then ACTIVE+=("$f"); else EXCLUDED+=("$f"); fi
  done
  if [ "${#EXCLUDED[@]}" -gt 0 ]; then
    echo "run.sh: ${TIER} excluding ${#EXCLUDED[@]} not-yet-started work unit(s) per the activation rule (behavior-spec.md Section 6.0): ${EXCLUDED[*]}" >&2
  fi
}

case "$TIER" in
  b1)
    # 🔴 B1 MUST RUN *THIS* WORK UNIT'S CONTRACT — never a neighbouring one.
    #    AIRE_STORY_KEY names it (e.g. "story-1.10" -> spec/behavior/story-1.10.feature). It is set by
    #    the invoking dev-implement / bug-fix-implement / enhancement-implement run, and by the CI
    #    behaviour step from the already-resolved EVAL_KEY.
    #    Without it this took `ls -1 story-*.feature | tail -n1` — the LEXICOGRAPHICALLY last file.
    #    That is wrong the moment an epic passes nine work units: "story-1.10" sorts BEFORE "story-1.9",
    #    so tail -n1 returns 1.9 and B1 runs an ALREADY-MERGED unit's contract instead of the one being
    #    built — and PASSES, having never tested this unit. A silent pass, and it gets likelier as the
    #    epic grows.
    #    So: use the key when given; accept a lone feature file when there is exactly one; and when
    #    several exist with no key, ERROR rather than guess.
    if [ -n "${AIRE_STORY_KEY:-}" ] && not_a_work_unit "${AIRE_STORY_KEY}"; then
      # An infrastructure run (the epic smoke test's scratch PR, a ve/** docs PR): no work unit is under
      # test, so no behaviour tier can mean anything here. N/A, never ERROR.
      echo "run.sh: b1 N/A — AIRE_STORY_KEY='${AIRE_STORY_KEY}' is not a work unit (infrastructure run)" >&2
      exit 3
    fi
    if [ -n "${AIRE_STORY_KEY:-}" ]; then
      unit_feature="${BEHAVIOR_DIR}/${AIRE_STORY_KEY}.feature"
      if [ ! -f "$unit_feature" ]; then
        # 🔴 AIRE_STORY_KEY is ALWAYS set in CI (the workflow passes the resolved eval key), so this
        #    branch is the ONLY one CI ever takes — the no_stories_yet() N/A exception below MUST be
        #    reachable from here too, not just from the no-key fallback branch at line ~82, or every
        #    epic-level pre-handoff smoke test (zero feature files, by design) reports a false ERROR
        #    instead of the earned N/A. Observed in production (ci-pipeline-generation.md Section 4.0.6).
        if no_stories_yet; then
          echo "run.sh: b1 N/A — spec/behavior/ has zero feature files (no cycle in flight)" >&2
          exit 3
        fi
        mapfile -t all_b1 < <(ls -1 "${BEHAVIOR_DIR}"/*.feature 2>/dev/null || true)
        partition_active "${all_b1[@]}"
        if [ "${#ACTIVE[@]}" -eq 0 ]; then
          # Every unit's contract exists but none has been started -- the epic-level pre-handoff smoke
          # test (ci-pipeline-generation.md Section 4.0.6). Earned N/A, not a false ERROR.
          echo "run.sh: b1 N/A — no work unit has been started yet (all ${#all_b1[@]} feature file(s) inactive per behavior-spec.md Section 6.0)" >&2
          exit 3
        fi
        echo "run.sh: b1 ERROR — AIRE_STORY_KEY='${AIRE_STORY_KEY}' but ${unit_feature} does not exist. B1 must run THIS unit's own contract; refusing to fall back to another unit's feature file." >&2
        exit 2
      fi
    else
      mapfile -t unit_candidates < <(ls -1 "${BEHAVIOR_DIR}"/story-*.feature 2>/dev/null || true)
      if [ "${#unit_candidates[@]}" -eq 1 ]; then
        unit_feature="${unit_candidates[0]}"
      elif [ "${#unit_candidates[@]}" -gt 1 ]; then
        echo "run.sh: b1 ERROR — ${#unit_candidates[@]} story feature files exist and AIRE_STORY_KEY is not set, so THIS unit's contract cannot be identified. Not guessed: the lexicographically last file is story-1.9 when story-1.10 is the unit under test, which passes B1 without testing it. Set AIRE_STORY_KEY=<work-unit-key> (e.g. story-1.10)." >&2
        exit 2
      else
        unit_feature=""
      fi
    fi
    if [ -z "$unit_feature" ]; then
      if no_stories_yet; then
        echo "run.sh: b1 N/A — spec/behavior/ has zero feature files (no cycle in flight)" >&2
        exit 3
      fi
      mapfile -t all_b1 < <(ls -1 "${BEHAVIOR_DIR}"/*.feature 2>/dev/null || true)
      partition_active "${all_b1[@]}"
      if [ "${#ACTIVE[@]}" -eq 0 ]; then
        echo "run.sh: b1 N/A — no work unit has been started yet (all ${#all_b1[@]} feature file(s) inactive per behavior-spec.md Section 6.0)" >&2
        exit 3
      fi
      echo "run.sh: b1 found no story feature file (other feature files exist — this story's own contract is missing)" >&2
      exit 2
    fi
    run_features "$unit_feature" ;;
  b2)
    if [ -n "${AIRE_STORY_KEY:-}" ] && not_a_work_unit "${AIRE_STORY_KEY}"; then
      echo "run.sh: b2 N/A — AIRE_STORY_KEY='${AIRE_STORY_KEY}' is not a work unit (infrastructure run)" >&2
      exit 3
    fi
    mapfile -t others < <(ls -1 "${BEHAVIOR_DIR}"/*.feature 2>/dev/null || true)
    if [ "${#others[@]}" -eq 0 ]; then
      echo "run.sh: b2 N/A — spec/behavior/ has zero feature files (no cycle in flight)" >&2
      exit 3
    fi
    partition_active "${others[@]}"
    if [ "${#ACTIVE[@]}" -eq 0 ]; then
      echo "run.sh: b2 N/A — no work unit has been started yet (all ${#others[@]} feature file(s) inactive per behavior-spec.md Section 6.0)" >&2
      exit 3
    fi
    run_features "${ACTIVE[@]}" ;;
  b3)
    if [ -n "${AIRE_STORY_KEY:-}" ] && not_a_work_unit "${AIRE_STORY_KEY}"; then
      echo "run.sh: b3 N/A — AIRE_STORY_KEY='${AIRE_STORY_KEY}' is not a work unit (infrastructure run)" >&2
      exit 3
    fi
    mapfile -t all < <(ls -1 "${BEHAVIOR_DIR}"/*.feature 2>/dev/null || true)
    if [ "${#all[@]}" -eq 0 ]; then
      if [ -f "$CROSS_STORY" ]; then
        run_features "$CROSS_STORY"
        exit $?
      fi
      echo "run.sh: b3 N/A — spec/behavior/ has zero feature files and no cross-story spec/behavior.feature exists" >&2
      exit 3
    fi
    partition_active "${all[@]}"
    if [ "${#ACTIVE[@]}" -eq 0 ]; then
      echo "run.sh: b3 N/A — no work unit has been started yet (all ${#all[@]} feature file(s) inactive per behavior-spec.md Section 6.0)" >&2
      exit 3
    fi
    [ -f "$CROSS_STORY" ] && ACTIVE+=("$CROSS_STORY")
    run_features "${ACTIVE[@]}" ;;
  *)
    echo "run.sh: unknown tier '${TIER}' (expected b1|b2|b3)" >&2; exit 2 ;;
esac
