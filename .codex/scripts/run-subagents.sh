#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODEX_HOME="$(cd "${SCRIPT_DIR}/.." && pwd)"
AGENTS_DIR="${CODEX_HOME}/agents"
CACHE_DIR="${CODEX_HOME}/.cache/subagents"
NODE_BIN="${NODE_BIN:-node}"
NPM_BIN="${NPM_BIN:-npm}"

if ! command -v "$NODE_BIN" >/dev/null 2>&1; then
  echo "[codex-subagents] Missing dependency: node (>=18)." >&2
  exit 1
fi

if ! command -v "$NPM_BIN" >/dev/null 2>&1; then
  echo "[codex-subagents] Missing dependency: npm." >&2
  exit 1
fi

SERVER_JS="$CACHE_DIR/node_modules/codex-subagents-mcp/dist/codex-subagents.mcp.js"

install_server() {
  mkdir -p "$CACHE_DIR"
  if [[ ! -f "$CACHE_DIR/package.json" ]]; then
    (cd "$CACHE_DIR" && "$NPM_BIN" init -y >/dev/null 2>&1)
  fi
  (cd "$CACHE_DIR" && NPM_CONFIG_LOGLEVEL=silent "$NPM_BIN" install codex-subagents-mcp@latest >/dev/null 2>&1)
}

if [[ ! -f "$SERVER_JS" ]]; then
  echo "[codex-subagents] Installing codex-subagents-mcp (first run)..." >&2
  install_server || {
    echo "[codex-subagents] Failed to install codex-subagents-mcp. Ensure npm can reach the network." >&2
    exit 1
  }
fi

exec "$NODE_BIN" "$SERVER_JS" --agents-dir "${AGENTS_DIR}" "$@"
