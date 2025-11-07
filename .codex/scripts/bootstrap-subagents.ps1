#!/usr/bin/env pwsh
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$nodeBin = if ($env:NODE_BIN) { $env:NODE_BIN } else { "node" }
$npmBin = if ($env:NPM_BIN) { $env:NPM_BIN } else { "npm" }
$repoDir = if ($env:CODEX_SUBAGENTS_REPO) { $env:CODEX_SUBAGENTS_REPO } else { Join-Path $HOME ".codex/subagents/codex-subagents-mcp" }
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

if (-not (Test-Path $repoDir)) {
    Write-Error "[codex-subagents] Repository not found at $repoDir. Clone https://github.com/leonardsellem/codex-subagents-mcp there (or set CODEX_SUBAGENTS_REPO) first."
}

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
