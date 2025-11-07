#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: scripts/bash/lint-branchmap.sh <specs/feature-dir>" >&2
  exit 1
fi

FEATURE_DIR="$1"
PLAN_FILE="$FEATURE_DIR/plan.md"
TASKS_FILE="$FEATURE_DIR/tasks.md"
STATUS=0

check_file_exists() {
  local file_path="$1"
  local friendly="$2"
  if [[ ! -f "$file_path" ]]; then
    echo "ERROR: Expected $friendly at $file_path (run /speckit.plan or /speckit.tasks first)." >&2
    STATUS=1
    return 1
  fi
  return 0
}

require_pattern() {
  local file_path="$1"
  local label="$2"
  local pattern="$3"
  if ! grep -q "$pattern" "$file_path"; then
    echo "ERROR: $label missing from $file_path (pattern: $pattern)." >&2
    STATUS=1
  fi
}

check_file_exists "$PLAN_FILE" "plan.md"
if [[ -f "$PLAN_FILE" ]]; then
  require_pattern "$PLAN_FILE" "Plan Branch Map section" "## Branch Map & Checkpoints"
  require_pattern "$PLAN_FILE" "Checkpoint A Summary" "### Checkpoint A Summary"
  require_pattern "$PLAN_FILE" "Checkpoint B Summary" "### Checkpoint B Summary"
fi

check_file_exists "$TASKS_FILE" "tasks.md"
if [[ -f "$TASKS_FILE" ]]; then
  require_pattern "$TASKS_FILE" "Tasks Branch Map snapshot" "## Branch Map Snapshot (Tasks)"
  require_pattern "$TASKS_FILE" "Checkpoint C Summary" "## Checkpoint C Summary"
fi

if [[ $STATUS -ne 0 ]]; then
  echo "Branch Map/Checkpoint lint failed for $FEATURE_DIR." >&2
  exit "$STATUS"
fi

echo "Branch Map/Checkpoint lint passed for $FEATURE_DIR."
