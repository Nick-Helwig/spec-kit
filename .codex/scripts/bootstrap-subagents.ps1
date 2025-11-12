#!/usr/bin/env pwsh
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$nodeBin = if ($env:NODE_BIN) { $env:NODE_BIN } else { "node" }
$npmBin = if ($env:NPM_BIN) { $env:NPM_BIN } else { "npm" }
$repoDir = if ($env:CODEX_SUBAGENTS_REPO) { $env:CODEX_SUBAGENTS_REPO } else { Join-Path $HOME ".codex/subagents/codex-subagents-mcp" }
$repoUrl = if ($env:CODEX_SUBAGENTS_REPO_URL) { $env:CODEX_SUBAGENTS_REPO_URL } else { "https://github.com/leonardsellem/codex-subagents-mcp.git" }
$repoRef = if ($env:CODEX_SUBAGENTS_REPO_REF) { $env:CODEX_SUBAGENTS_REPO_REF } else { "" }
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

function Sync-Repo {
    if (-not (Test-Path (Join-Path $repoDir ".git"))) {
        return
    }

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Warning "[codex-subagents] git is required to sync $repoDir. Skipping git pull/checkout."
        return
    }

    if ($repoRef) {
        Write-Host "[codex-subagents] Checking out codex-subagents ref $repoRef"
        git -C $repoDir fetch --tags --prune | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Error "[codex-subagents] git fetch failed while preparing $repoRef."
        }
        git -C $repoDir checkout $repoRef | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Error "[codex-subagents] git checkout $repoRef failed. Ensure the ref exists or update CODEX_SUBAGENTS_REPO_REF."
        }
        return
    }

    if ($force) {
        Write-Host "[codex-subagents] Refreshing codex-subagents repo in $repoDir"
        git -C $repoDir fetch --tags --prune | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Error "[codex-subagents] git fetch failed during refresh."
        }
        $currentBranch = git -C $repoDir rev-parse --abbrev-ref HEAD
        if ($LASTEXITCODE -eq 0 -and $currentBranch -ne "HEAD") {
            git -C $repoDir pull --ff-only origin $currentBranch | Out-Null
            if ($LASTEXITCODE -ne 0) {
                Write-Error "[codex-subagents] git pull failed while refreshing $currentBranch."
            }
        }
        else {
            Write-Warning "[codex-subagents] Repo is detached; set CODEX_SUBAGENTS_REPO_REF to pin a release."
        }
    }
}

Sync-Repo

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
