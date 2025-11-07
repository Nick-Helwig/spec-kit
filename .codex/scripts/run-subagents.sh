#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODEX_HOME="$(cd "${SCRIPT_DIR}/.." && pwd)"
AGENTS_DIR="${CODEX_HOME}/agents"
NODE_BIN="${NODE_BIN:-node}"
SUBAGENT_REPO="${CODEX_SUBAGENTS_REPO:-$HOME/.codex/subagents/codex-subagents-mcp}"
SERVER_JS="${SUBAGENT_REPO}/dist/codex-subagents.mcp.js"
BOOTSTRAP_SCRIPT="${CODEX_HOME}/scripts/bootstrap-subagents.sh"

run_bootstrap() {
  if [[ -x "$BOOTSTRAP_SCRIPT" ]]; then
    "$BOOTSTRAP_SCRIPT"
  else
    cat >&2 <<EOF
[codex-subagents] Build artifacts missing and bootstrap script not found.
Expected at: $BOOTSTRAP_SCRIPT
Ensure the Spec Kit repository is intact or run the bootstrap process manually.
EOF
    exit 1
  fi
}

if ! command -v "$NODE_BIN" >/dev/null 2>&1; then
  echo "[codex-subagents] Missing dependency: node (>=18)." >&2
  exit 1
fi

if [[ ! -d "$SUBAGENT_REPO" ]]; then
  echo "[codex-subagents] codex-subagents-mcp repo missing at $SUBAGENT_REPO. Bootstrapping..." >&2
  run_bootstrap
fi

if [[ ! -f "$SERVER_JS" ]]; then
  echo "[codex-subagents] Build artifacts missing for codex-subagents-mcp. Bootstrapping..." >&2
  run_bootstrap
fi

if [[ ! -d "$SUBAGENT_REPO" ]] || [[ ! -f "$SERVER_JS" ]]; then
  cat >&2 <<EOF
[codex-subagents] Failed to prepare codex-subagents-mcp automatically.
Verify the repository exists at $SUBAGENT_REPO and rerun:
  $BOOTSTRAP_SCRIPT
EOF
  exit 1
fi

exec "$NODE_BIN" "$SERVER_JS" --agents-dir "${AGENTS_DIR}" "$@"
