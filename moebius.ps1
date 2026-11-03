<#
.SYNOPSIS
    Moebius: The Orb of Celestial Harmony (1987) — Retro RPG & Martial Arts Simulation
.DESCRIPTION
    Authentic recreation of Origin Systems' classic 1987 martial arts RPG.
    Explores 4 elemental realms (Earth, Water, Air, Fire) across 64x64 tile matrices,
    featuring tactical side-view combat, Taoist karma, divination meditation, and
    original 3-voice chiptune soundtrack parsed from PCMUSIC.SLB.
.PARAMETER SmokeTest
    Runs the automated headless test suite and exits immediately.
.PARAMETER Port
    HTTP port for the local server (default: 3085).
.PARAMETER NoBrowser
    Do not automatically open the default web browser upon launch.
.EXAMPLE
    .\moebius.ps1
    Launches the game and opens the browser.
.EXAMPLE
    .\moebius.ps1 -SmokeTest
    Runs headless automated unit tests.
#>

[CmdletBinding()]
param (
    [switch]$SmokeTest,
    [int]$Port = 3085,
    [switch]$NoBrowser,
    [switch]$Help
)

if ($Help) {
    Get-Help $MyInvocation.MyCommand.Path -Detailed
    return
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$GameDir = Join-Path $ScriptDir "moebius"

# Check if running under Windows with WSL or native Node
$HasWsl = (Get-Command wsl -ErrorAction SilentlyContinue) -ne $null
$HasNode = (Get-Command node -ErrorAction SilentlyContinue) -ne $null

if ($SmokeTest) {
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host " Running Moebius Automated Smoke Test Suite..." -ForegroundColor Yellow
    Write-Host "====================================================" -ForegroundColor Cyan

    if ($HasWsl) {
        & wsl -d daniel-kill bash -l -c "cd /home/daniel/Repos/games/moebius && node test.js"
        exit $LASTEXITCODE
    } elseif ($HasNode) {
        Set-Location $GameDir
        & node test.js
        exit $LASTEXITCODE
    } else {
        Write-Error "Neither WSL nor Node.js was found in PATH."
        exit 1
    }
}

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║       MOEBIUS: THE ORB OF CELESTIAL HARMONY (1987)         ║" -ForegroundColor Yellow
Write-Host "║           Authentic Retro RPG & Martial Arts Sim           ║" -ForegroundColor Green
Write-Host "╠════════════════════════════════════════════════════════════╣" -ForegroundColor Green
Write-Host "║  Starting game server at: http://localhost:$Port             ║" -ForegroundColor White
Write-Host "║  Four Realms: EARTH • WATER • AIR • FIRE                   ║" -ForegroundColor Cyan
Write-Host "║  Press Ctrl+C to stop the game server                      ║" -ForegroundColor Gray
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green

if (-not $NoBrowser) {
    Start-Process "http://localhost:$Port"
}

if ($HasWsl) {
    & wsl -d daniel-kill bash -l -c "cd /home/daniel/Repos/games/moebius && node server.js --port $Port"
} elseif ($HasNode) {
    Set-Location $GameDir
    & node server.js --port $Port
} else {
    Write-Error "Neither WSL nor Node.js was found in PATH."
    exit 1
}
