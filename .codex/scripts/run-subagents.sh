#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODEX_HOME="$(cd "${SCRIPT_DIR}/.." && pwd)"
AGENTS_DIR="${CODEX_HOME}/agents"
CACHE_DIR="${CODEX_HOME}/.cache/subagents"
NODE_BIN="${NODE_BIN:-node}"

if ! command -v "$NODE_BIN" >/dev/null 2>&1; then
  echo "[codex-subagents] Missing dependency: node (>=18)." >&2
  exit 1
fi

SERVER_JS="$CACHE_DIR/node_modules/codex-subagents-mcp/dist/codex-subagents.mcp.js"

if [[ ! -f "$SERVER_JS" ]]; then
  echo "[codex-subagents] MCP server not installed at:" >&2
  echo "  $SERVER_JS" >&2
  echo "Run [bash] .codex/scripts/bootstrap-subagents.sh (or the PowerShell equivalent) before using Codex sub-agents." >&2
  exit 1
fi

exec "$NODE_BIN" "$SERVER_JS" --agents-dir "${AGENTS_DIR}" "$@"
