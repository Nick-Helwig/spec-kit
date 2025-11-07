#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODEX_HOME="$(cd "${SCRIPT_DIR}/.." && pwd)"
AGENTS_DIR="${CODEX_HOME}/agents"
NODE_BIN="${NODE_BIN:-node}"
SUBAGENT_REPO="${CODEX_SUBAGENTS_REPO:-$HOME/.codex/subagents/codex-subagents-mcp}"
SERVER_JS="${SUBAGENT_REPO}/dist/codex-subagents.mcp.js"

if ! command -v "$NODE_BIN" >/dev/null 2>&1; then
  echo "[codex-subagents] Missing dependency: node (>=18)." >&2
  exit 1
fi

if [[ ! -d "$SUBAGENT_REPO" ]]; then
  cat >&2 <<EOF
[codex-subagents] Could not find the codex-subagents-mcp repo.
Expected at: $SUBAGENT_REPO
Clone it with:
  git clone https://github.com/leonardsellem/codex-subagents-mcp "$SUBAGENT_REPO"
Then run .codex/scripts/bootstrap-subagents.sh
EOF
  exit 1
fi

if [[ ! -f "$SERVER_JS" ]]; then
  cat >&2 <<EOF
[codex-subagents] Build artifacts missing at $SERVER_JS
Run the bootstrap script to install dependencies and build:
  .codex/scripts/bootstrap-subagents.sh
EOF
  exit 1
fi

exec "$NODE_BIN" "$SERVER_JS" --agents-dir "${AGENTS_DIR}" "$@"
