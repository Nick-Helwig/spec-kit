#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODEX_HOME="$(cd "${SCRIPT_DIR}/.." && pwd)"
NODE_BIN="${NODE_BIN:-node}"
NPM_BIN="${NPM_BIN:-npm}"
REPO_DIR="${CODEX_SUBAGENTS_REPO:-$HOME/.codex/subagents/codex-subagents-mcp}"
REPO_URL="${CODEX_SUBAGENTS_REPO_URL:-https://github.com/leonardsellem/codex-subagents-mcp.git}"
REPO_REF="${CODEX_SUBAGENTS_REPO_REF:-}"
FORCE=0

if [[ "${1:-}" == "--force" ]]; then
  FORCE=1
fi

if ! command -v "$NODE_BIN" >/dev/null 2>&1; then
  echo "[codex-subagents] Node.js (>=18) is required." >&2
  exit 1
fi

if ! command -v "$NPM_BIN" >/dev/null 2>&1; then
  echo "[codex-subagents] npm is required." >&2
  exit 1
fi

ensure_repo() {
  if [[ -d "$REPO_DIR/.git" ]]; then
    return
  fi

  if [[ -e "$REPO_DIR" && ! -d "$REPO_DIR" ]]; then
    echo "[codex-subagents] $REPO_DIR exists but is not a directory. Remove it or set CODEX_SUBAGENTS_REPO." >&2
    exit 1
  fi

  if [[ -d "$REPO_DIR" && ! -d "$REPO_DIR/.git" ]]; then
    echo "[codex-subagents] $REPO_DIR exists but is not a git repo. Remove or point CODEX_SUBAGENTS_REPO elsewhere." >&2
    exit 1
  fi

  if ! command -v git >/dev/null 2>&1; then
    cat >&2 <<EOF
[codex-subagents] git is required to clone codex-subagents-mcp automatically.
Install git or clone the repo manually into:
  $REPO_DIR
EOF
    exit 1
  fi

  mkdir -p "$(dirname "$REPO_DIR")"
  echo "[codex-subagents] Cloning codex-subagents-mcp into $REPO_DIR"
  if ! git clone "$REPO_URL" "$REPO_DIR"; then
    echo "[codex-subagents] git clone failed. Clone manually and rerun." >&2
    exit 1
  fi
}

ensure_repo

sync_repo() {
  if [[ ! -d "$REPO_DIR/.git" ]]; then
    return
  fi

  if ! command -v git >/dev/null 2>&1; then
    echo "[codex-subagents] git is required to sync $REPO_DIR. Skipping git pull/checkout." >&2
    return
  fi

  if [[ -n "$REPO_REF" ]]; then
    echo "[codex-subagents] Checking out codex-subagents ref $REPO_REF"
    if ! git -C "$REPO_DIR" fetch --tags --prune; then
      echo "[codex-subagents] git fetch failed while preparing $REPO_REF." >&2
      exit 1
    fi
    if ! git -C "$REPO_DIR" checkout "$REPO_REF"; then
      echo "[codex-subagents] git checkout $REPO_REF failed. Ensure the ref exists or update CODEX_SUBAGENTS_REPO_REF." >&2
      exit 1
    fi
    return
  fi

  if [[ $FORCE -eq 1 ]]; then
    echo "[codex-subagents] Refreshing codex-subagents repo in $REPO_DIR"
    if ! git -C "$REPO_DIR" fetch --tags --prune; then
      echo "[codex-subagents] git fetch failed during refresh." >&2
      exit 1
    fi
    current_branch="$(git -C "$REPO_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
    if [[ -n "$current_branch" && "$current_branch" != "HEAD" ]]; then
      if ! git -C "$REPO_DIR" pull --ff-only origin "$current_branch"; then
        echo "[codex-subagents] git pull failed while refreshing $current_branch." >&2
        exit 1
      fi
    else
      echo "[codex-subagents] Repo is detached; set CODEX_SUBAGENTS_REPO_REF to pin a release." >&2
    fi
  fi
}

sync_repo

if [[ $FORCE -eq 1 ]]; then
  rm -rf "$REPO_DIR/node_modules" "$REPO_DIR/dist"
fi

NEED_INSTALL=0
[[ ! -d "$REPO_DIR/node_modules" ]] && NEED_INSTALL=1

NEED_BUILD=0
[[ ! -f "$REPO_DIR/dist/codex-subagents.mcp.js" ]] && NEED_BUILD=1

if [[ $NEED_INSTALL -eq 0 && $NEED_BUILD -eq 0 ]]; then
  echo "[codex-subagents] Dependencies and build artifacts already present at $REPO_DIR"
  exit 0
fi

pushd "$REPO_DIR" >/dev/null
if [[ $NEED_INSTALL -eq 1 ]]; then
  echo "[codex-subagents] Installing npm dependencies in $REPO_DIR"
  if ! NPM_CONFIG_LOGLEVEL=error "$NPM_BIN" install; then
    echo "[codex-subagents] npm install failed. Ensure you have network access or preinstall dependencies manually." >&2
    popd >/dev/null
    exit 1
  fi
fi

if [[ $NEED_BUILD -eq 1 ]]; then
  echo "[codex-subagents] Building codex-subagents-mcp"
  if ! "$NPM_BIN" run build; then
    echo "[codex-subagents] npm run build failed." >&2
    popd >/dev/null
    exit 1
  fi
fi
popd >/dev/null

echo "[codex-subagents] Ready. Run .codex/scripts/run-subagents.sh via Codex."
