#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODEX_HOME="$(cd "${SCRIPT_DIR}/.." && pwd)"
AGENTS_DIR="${CODEX_HOME}/agents"

if ! command -v npx >/dev/null 2>&1; then
  echo "[codex-subagents] Missing dependency: npx (Node.js ≥18)." >&2
  exit 1
fi

exec npx -y codex-subagents-mcp --agents-dir "${AGENTS_DIR}" "$@"
