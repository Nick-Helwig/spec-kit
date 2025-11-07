#!/usr/bin/env pwsh
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$codexHome = (Resolve-Path (Join-Path $scriptDir "..")).Path
$cacheDir = Join-Path $codexHome ".cache/subagents"
$nodeBin = if ($env:NODE_BIN) { $env:NODE_BIN } else { "node" }
$npmBin = if ($env:NPM_BIN) { $env:NPM_BIN } else { "npm" }

if (-not (Get-Command $nodeBin -ErrorAction SilentlyContinue)) {
    Write-Error "[codex-subagents] Node.js (>=18) is required to install the MCP server."
}

if (-not (Get-Command $npmBin -ErrorAction SilentlyContinue)) {
    Write-Error "[codex-subagents] npm is required to install the MCP server."
}

$force = $false
if ($args.Length -gt 0 -and $args[0] -eq "--force") {
    $force = $true
}

New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null

if ($force) {
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue (Join-Path $cacheDir "node_modules")
    Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $cacheDir "package-lock.json")
}

$packageJson = Join-Path $cacheDir "package.json"
if (-not (Test-Path $packageJson)) {
    Push-Location $cacheDir
    & $npmBin init -y *> $null
    Pop-Location
}

Write-Host "[codex-subagents] Installing codex-subagents-mcp into $cacheDir"
Push-Location $cacheDir
$env:NPM_CONFIG_LOGLEVEL = "error"
& $npmBin install codex-subagents-mcp@latest
Pop-Location
Write-Host "[codex-subagents] Installation complete. You can now launch Codex sub-agents."
