#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODEX_HOME="$(cd "${SCRIPT_DIR}/.." && pwd)"
CACHE_DIR="${CODEX_HOME}/.cache/subagents"
NODE_BIN="${NODE_BIN:-node}"
NPM_BIN="${NPM_BIN:-npm}"

if ! command -v "$NODE_BIN" >/dev/null 2>&1; then
  echo "[codex-subagents] Node.js (>=18) is required to install the MCP server." >&2
  exit 1
fi

if ! command -v "$NPM_BIN" >/dev/null 2>&1; then
  echo "[codex-subagents] npm is required to install the MCP server." >&2
  exit 1
fi

FORCE=0
if [[ "${1:-}" == "--force" ]]; then
  FORCE=1
fi

mkdir -p "$CACHE_DIR"

if [[ $FORCE -eq 1 ]]; then
  rm -rf "$CACHE_DIR/node_modules" "$CACHE_DIR/package-lock.json"
fi

if [[ ! -f "$CACHE_DIR/package.json" ]]; then
  (cd "$CACHE_DIR" && "$NPM_BIN" init -y >/dev/null 2>&1)
fi

echo "[codex-subagents] Installing codex-subagents-mcp into $CACHE_DIR"
(cd "$CACHE_DIR" && NPM_CONFIG_LOGLEVEL=error "$NPM_BIN" install codex-subagents-mcp@latest)
echo "[codex-subagents] Installation complete. You can now launch Codex sub-agents."
