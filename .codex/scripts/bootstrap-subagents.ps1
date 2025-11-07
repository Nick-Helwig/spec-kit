#!/usr/bin/env pwsh
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$nodeBin = if ($env:NODE_BIN) { $env:NODE_BIN } else { "node" }
$npmBin = if ($env:NPM_BIN) { $env:NPM_BIN } else { "npm" }
$repoDir = if ($env:CODEX_SUBAGENTS_REPO) { $env:CODEX_SUBAGENTS_REPO } else { Join-Path $HOME ".codex/subagents/codex-subagents-mcp" }
$repoUrl = if ($env:CODEX_SUBAGENTS_REPO_URL) { $env:CODEX_SUBAGENTS_REPO_URL } else { "https://github.com/leonardsellem/codex-subagents-mcp.git" }
$force = $false
if ($args.Length -gt 0 -and $args[0] -eq "--force") {
    $force = $true
}

if (-not (Get-Command $nodeBin -ErrorAction SilentlyContinue)) {
    Write-Error "[codex-subagents] Node.js (>=18) is required."
}

if (-not (Get-Command $npmBin -ErrorAction SilentlyContinue)) {
    Write-Error "[codex-subagents] npm is required."
}

function Ensure-Repo {
    $gitDir = Join-Path $repoDir ".git"
    if (Test-Path $gitDir) {
        return
    }

    if ((Test-Path $repoDir) -and (-not (Test-Path $gitDir))) {
        Write-Error "[codex-subagents] $repoDir exists but is not a git repo. Remove it or set CODEX_SUBAGENTS_REPO."
    }

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Error "[codex-subagents] git is required to clone codex-subagents-mcp automatically."
    }

    $parentDir = Split-Path -Parent $repoDir
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir | Out-Null
    }

    Write-Host "[codex-subagents] Cloning codex-subagents-mcp into $repoDir"
    git clone $repoUrl $repoDir | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "[codex-subagents] git clone failed. Clone manually and rerun."
    }
}

Ensure-Repo

if ($force) {
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue (Join-Path $repoDir "node_modules")
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue (Join-Path $repoDir "dist")
}

$needsInstall = -not (Test-Path (Join-Path $repoDir "node_modules"))
$needsBuild = -not (Test-Path (Join-Path $repoDir "dist/codex-subagents.mcp.js"))

if (-not $needsInstall -and -not $needsBuild) {
    Write-Host "[codex-subagents] Dependencies and build artifacts already exist at $repoDir"
    exit 0
}

Push-Location $repoDir
if ($needsInstall) {
    Write-Host "[codex-subagents] Installing npm dependencies in $repoDir"
    $env:NPM_CONFIG_LOGLEVEL = "error"
    & $npmBin install
    if ($LASTEXITCODE -ne 0) {
        Pop-Location
        Write-Error "[codex-subagents] npm install failed. Ensure dependencies are available."
    }
}

if ($needsBuild) {
    Write-Host "[codex-subagents] Building codex-subagents-mcp"
    & $npmBin run build
    if ($LASTEXITCODE -ne 0) {
        Pop-Location
        Write-Error "[codex-subagents] npm run build failed."
    }
}
Pop-Location
Write-Host "[codex-subagents] Ready. Codex can now launch sub-agents."
