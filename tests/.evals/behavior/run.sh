#!/bin/sh
# Behaviour gate entry point. Usage: run.sh <b1|b2|b3>
# B1 needs AIRE_STORY_KEY (e.g. story-1.1). Exit 0 pass, 1 fail, 3 N/A (empty active set).
# Runs through pytest-bdd; the caller (a developer or CI) wraps it in the Podman pod.
set -u
TIER="${1:-}"
[ -n "$TIER" ] || { echo "run.sh: no tier supplied" >&2; exit 2; }
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT" || exit 2
KEY="${AIRE_STORY_KEY:-}"
PY="${AIRE_PYTHON:-python3}"
OUT="${AIRE_REPORT_DIR:-reports/behavior-test-evidence/${KEY:-cycle}/$TIER}"
mkdir -p "$OUT"
module_for() { printf 'tests/behavior/test_%s.py' "$(printf '%s' "$1" | tr '.-' '__')"; }
# Active units = tracker rows (shared table plus fragments) whose status is not Ready for Development.
active_units() {
  "$PY" - <<'PYEOF'
import glob, re
rows = {}
for path in ["runtime-artifacts/aire-state.md"] + glob.glob("runtime-artifacts/stories/*/state.md"):
    for line in open(path):
        m = re.match(r"\|\s*(\d+\.\d+)\s*\|.*\|\s*(Ready for Development|In Development|Ready for Testing)\s*\|", line)
        if m:
            rows[m.group(1)] = m.group(2)
for unit, state in sorted(rows.items()):
    if state != "Ready for Development":
        print("story-" + unit)
PYEOF
}
case "$TIER" in
  b1)
    [ -n "$KEY" ] || { echo "run.sh: AIRE_STORY_KEY is required for b1" >&2; exit 2; }
    TARGETS="$(module_for "$KEY")" ;;
  b2)
    TARGETS=""
    for unit in $(active_units); do
      [ "$unit" = "$KEY" ] && continue
      [ -f "$(module_for "$unit")" ] && TARGETS="$TARGETS $(module_for "$unit")"
    done
    if [ -z "$TARGETS" ]; then echo "B2: no other active feature file - N/A"; exit 3; fi ;;
  b3)
    TARGETS="tests/behavior" ;;
  *) echo "run.sh: unknown tier $TIER" >&2; exit 2 ;;
esac
echo "tier=$TIER key=$KEY targets=$TARGETS"
# shellcheck disable=SC2086
"$PY" -m pytest $TARGETS -p no:cacheprovider -q --no-header --junitxml="$OUT/behavior-test-junit.xml" 2>&1 | tee "$OUT/behavior-test-run.log"
STATUS=$?
exit "$STATUS"
