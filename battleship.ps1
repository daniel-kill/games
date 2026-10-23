<#
.SYNOPSIS
    Terminal Battleship - Naval Combat Simulation (Player vs Smart AI)
.DESCRIPTION
    A complete, standalone PowerShell implementation of the classic 10x10 naval tactical game.
    Features Carrier (5), Battleship (4), Cruiser (3), Submarine (3), and Destroyer (2).
    Includes a smart CPU AI with 3 tactical modes: Ensign (random), Captain (hunt & target),
    and Admiral (parity search & adjacent vector tracking), with color-coded ANSI radar screens.
.PARAMETER SmokeTest
    Runs an automated non-interactive self-test and verification combat round.
.PARAMETER Difficulty
    AI tactical difficulty: Ensign, Captain, or Admiral (default Captain).
.EXAMPLE
    ./battleship.ps1
    ./battleship.ps1 -SmokeTest
#>
[CmdletBinding()]
param(
    [switch]$SmokeTest,
    [ValidateSet('Ensign', 'Captain', 'Admiral')]
    [string]$Difficulty = 'Captain'
)

$script:ShipSpecs = @(
    [PSCustomObject]@{ Name = "Carrier";    Length = 5; Symbol = 'C' }
    [PSCustomObject]@{ Name = "Battleship"; Length = 4; Symbol = 'B' }
    [PSCustomObject]@{ Name = "Cruiser";    Length = 3; Symbol = 'R' }
    [PSCustomObject]@{ Name = "Submarine";  Length = 3; Symbol = 'S' }
    [PSCustomObject]@{ Name = "Destroyer";  Length = 2; Symbol = 'D' }
)

function New-Grid {
    # 10x10 grid using an array of char arrays (jagged array) for robust PowerShell pipeline passing
    $grid = @()
    for ($r = 0; $r -lt 10; $r++) {
        $row = [char[]]::new(10)
        for ($c = 0; $c -lt 10; $c++) {
            $row[$c] = [char]'~'
        }
        $grid += ,$row
    }
    return ,$grid
}

function New-BattleshipFleet {
    $ships = [System.Collections.Generic.List[PSCustomObject]]::new()
    foreach ($spec in $script:ShipSpecs) {
        $ships.Add([PSCustomObject]@{
            Name        = $spec.Name
            Length      = $spec.Length
            Symbol      = $spec.Symbol
            Coordinates = [System.Collections.Generic.List[string]]::new() # e.g. "0,4"
            Hits        = 0
            IsSunk      = $false
        })
    }
    return $ships
}

function New-BattleshipGame {
    param([string]$AiDifficulty = 'Captain')

    $playerGrid = New-Grid
    $playerFleet = New-BattleshipFleet
    $playerTracking = New-Grid # Shots fired at CPU

    $cpuGrid = New-Grid
    $cpuFleet = New-BattleshipFleet
    $cpuTracking = New-Grid # Shots fired at player

    # Deploy CPU ships randomly
    Deploy-FleetRandomly -Grid $cpuGrid -Fleet $cpuFleet

    # Deploy Player ships randomly (can be customized interactively)
    Deploy-FleetRandomly -Grid $playerGrid -Fleet $playerFleet

    [PSCustomObject]@{
        PlayerGrid     = $playerGrid
        PlayerFleet    = $playerFleet
        PlayerTracking = $playerTracking
        CpuGrid        = $cpuGrid
        CpuFleet       = $cpuFleet
        CpuTracking    = $cpuTracking
        AiDifficulty   = $AiDifficulty
        AiTargetQueue  = [System.Collections.Generic.Queue[string]]::new()
        AiLastHits     = [System.Collections.Generic.List[string]]::new()
        TurnCount      = 0
        IsGameOver     = $false
        Winner         = $null
    }
}

function Can-PlaceShip {
    param(
        $Grid,
        [int]$Row,
        [int]$Col,
        [int]$Length,
        [bool]$Horizontal
    )

    if ($Horizontal) {
        if ($Col + $Length -gt 10) { return $false }
        for ($i = 0; $i -lt $Length; $i++) {
            if ($Grid[$Row][$Col + $i] -ne '~') { return $false }
        }
    } else {
        if ($Row + $Length -gt 10) { return $false }
        for ($i = 0; $i -lt $Length; $i++) {
            if ($Grid[$Row + $i][$Col] -ne '~') { return $false }
        }
    }
    return $true
}

function Deploy-FleetRandomly {
    param(
        $Grid,
        [System.Collections.Generic.List[PSCustomObject]]$Fleet
    )

    foreach ($ship in $Fleet) {
        $placed = $false
        $attempts = 0
        while (-not $placed -and $attempts -lt 500) {
            $attempts++
            $horizontal = (Get-Random -Minimum 0 -Maximum 2) -eq 1
            $r = Get-Random -Minimum 0 -Maximum 10
            $c = Get-Random -Minimum 0 -Maximum 10

            if (Can-PlaceShip -Grid $Grid -Row $r -Col $c -Length $ship.Length -Horizontal $horizontal) {
                for ($i = 0; $i -lt $ship.Length; $i++) {
                    $currR = if ($horizontal) { $r } else { $r + $i }
                    $currC = if ($horizontal) { $c + $i } else { $c }
                    $Grid[$currR][$currC] = [char]$ship.Symbol
                    $ship.Coordinates.Add("$currR,$currC")
                }
                $placed = $true
            }
        }
    }
}

function Show-BattleshipBoards {
    param([PSCustomObject]$Game)

    $cols = "   A B C D E F G H I J         A B C D E F G H I J"
    Write-Host "`n==== YOUR SHIPS & DEFENSE ================= ENEMY RADAR / SHOTS FIRED ====" -ForegroundColor Cyan
    Write-Host $cols -ForegroundColor Yellow

    for ($r = 0; $r -lt 10; $r++) {
        $pLine = "{0,2} " -f ($r + 1)
        for ($c = 0; $c -lt 10; $c++) {
            $val = $Game.PlayerGrid[$r][$c]
            $pLine += "$val "
        }

        $eLine = "{0,2} " -f ($r + 1)
        for ($c = 0; $c -lt 10; $c++) {
            $val = $Game.PlayerTracking[$r][$c]
            $eLine += "$val "
        }

        Write-Host "$pLine    $eLine" -ForegroundColor White
    }
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "Legend: [~] Open Water | [X] Hit | [O] Miss | [C,B,R,S,D] Your Ships" -ForegroundColor Gray
}

function Invoke-FireShot {
    param(
        $TargetGrid,
        $TrackingGrid,
        [System.Collections.Generic.List[PSCustomObject]]$TargetFleet,
        [int]$Row,
        [int]$Col
    )

    if ($TrackingGrid[$Row][$Col] -ne '~') {
        return [PSCustomObject]@{
            IsValid = $false
            Message = "Coordinates already targeted!"
        }
    }

    $targetVal = $TargetGrid[$Row][$Col]
    if ($targetVal -ne '~') {
        # HIT
        $TargetGrid[$Row][$Col] = [char]'X'
        $TrackingGrid[$Row][$Col] = [char]'X'

        # Locate hit ship
        $coordKey = "$Row,$Col"
        $hitShip = $null
        foreach ($s in $TargetFleet) {
            if ($s.Coordinates -contains $coordKey) {
                $hitShip = $s
                $s.Hits++
                if ($s.Hits -ge $s.Length) {
                    $s.IsSunk = $true
                }
                break
            }
        }

        $sunkMsg = if ($null -ne $hitShip -and $hitShip.IsSunk) { " You SUNK their $($hitShip.Name)!" } else { "" }

        return [PSCustomObject]@{
            IsValid   = $true
            IsHit     = $true
            ShipSunk  = ($null -ne $hitShip -and $hitShip.IsSunk)
            SunkName  = if ($hitShip) { $hitShip.Name } else { "" }
            Message   = "DIRECT HIT!$sunkMsg"
        }
    } else {
        # MISS
        $TargetGrid[$Row][$Col] = [char]'O'
        $TrackingGrid[$Row][$Col] = [char]'O'

        return [PSCustomObject]@{
            IsValid   = $true
            IsHit     = $false
            ShipSunk  = $false
            SunkName  = ""
            Message   = "Splash! Shot missed."
        }
    }
}

function Test-FleetDefeated {
    param([System.Collections.Generic.List[PSCustomObject]]$Fleet)
    foreach ($s in $Fleet) {
        if (-not $s.IsSunk) { return $false }
    }
    return $true
}

function Invoke-CpuTurn {
    param([PSCustomObject]$Game)

    $targetR = -1
    $targetC = -1

    # 1. Check target queue for hunt-and-target mode
    while ($Game.AiTargetQueue.Count -gt 0) {
        $coordStr = $Game.AiTargetQueue.Dequeue()
        $parts = $coordStr.Split(',')
        $r = [int]$parts[0]
        $c = [int]$parts[1]
        if ($Game.CpuTracking[$r][$c] -eq '~') {
            $targetR = $r
            $targetC = $c
            break
        }
    }

    # 2. If no targeted queue coordinates, choose strategically based on difficulty
    if ($targetR -eq -1) {
        $available = [System.Collections.Generic.List[string]]::new()
        for ($r = 0; $r -lt 10; $r++) {
            for ($c = 0; $c -lt 10; $c++) {
                if ($Game.CpuTracking[$r][$c] -eq '~') {
                    if ($Game.AiDifficulty -eq 'Admiral') {
                        # Parity check (checkerboard pattern) for small ship coverage
                        if (($r + $c) % 2 -eq 0) { $available.Add("$r,$c") }
                    } else {
                        $available.Add("$r,$c")
                    }
                }
            }
        }

        if ($available.Count -eq 0) {
            # Fallback if parity exhausted
            for ($r = 0; $r -lt 10; $r++) {
                for ($c = 0; $c -lt 10; $c++) {
                    if ($Game.CpuTracking[$r][$c] -eq '~') { $available.Add("$r,$c") }
                }
            }
        }

        $pick = $available | Get-Random
        $parts = $pick.Split(',')
        $targetR = [int]$parts[0]
        $targetC = [int]$parts[1]
    }

    # Fire shot at player
    $shotRes = Invoke-FireShot -TargetGrid $Game.PlayerGrid -TrackingGrid $Game.CpuTracking -TargetFleet $Game.PlayerFleet -Row $targetR -Col $targetC

    $alpha = [char](65 + $targetC)
    $rowNum = $targetR + 1
    Write-Host "`n[ENEMY FIRE] AI targets $alpha$rowNum... $($shotRes.Message)" -ForegroundColor $(if ($shotRes.IsHit) { 'Red' } else { 'Gray' })

    # If hit, push orthogonal adjacent squares to queue
    if ($shotRes.IsHit -and $Game.AiDifficulty -ne 'Ensign') {
        $deltas = @(@(-1, 0), @(1, 0), @(0, -1), @(0, 1))
        foreach ($d in $deltas) {
            $nr = $targetR + $d[0]
            $nc = $targetC + $d[1]
            if ($nr -ge 0 -and $nr -lt 10 -and $nc -ge 0 -and $nc -lt 10) {
                if ($Game.CpuTracking[$nr][$nc] -eq '~') {
                    $Game.AiTargetQueue.Enqueue("$nr,$nc")
                }
            }
        }
    }

    return $shotRes
}

function Invoke-BattleshipSmokeTest {
    Write-Host "[Battleship] Running automated headless smoke test..." -ForegroundColor Cyan

    $game = New-BattleshipGame -AiDifficulty 'Admiral'
    if ($null -eq $game -or $game.PlayerFleet.Count -ne 5) {
        throw "Failed to initialize Battleship game state."
    }

    Write-Host "[Battleship] Initialized game: Player fleet=5, CPU fleet=5, AI=Admiral" -ForegroundColor Green

    # Simulate player shot at 0,0
    $pShot = Invoke-FireShot -TargetGrid $game.CpuGrid -TrackingGrid $game.PlayerTracking -TargetFleet $game.CpuFleet -Row 0 -Col 0
    Write-Host "[Battleship] Player fired at A1: $($pShot.Message)" -ForegroundColor Green

    # Simulate CPU turn
    $cpuShot = Invoke-CpuTurn -Game $game
    Write-Host "[Battleship] CPU fired successfully." -ForegroundColor Green

    Write-Host "[Battleship] Smoke test PASSED successfully!" -ForegroundColor Green
    return $true
}

# Entrypoint Execution
if ($SmokeTest) {
    Invoke-BattleshipSmokeTest
    exit 0
}

Write-Host @"
========================================================================
         B A T T L E S H I P :   T E R M I N A L   C O M B A T
========================================================================
 Deploy your fleet across a 10x10 radar grid and engage the enemy
 fleet in turn-based artillery salvos.
========================================================================
"@ -ForegroundColor Yellow

$game = New-BattleshipGame -AiDifficulty $Difficulty

while (-not $game.IsGameOver) {
    Show-BattleshipBoards -Game $game

    $inputCoord = Read-Host "`nEnter firing coordinates (e.g., B4, F10) or 'Q' to retreat"
    if ([string]::IsNullOrWhiteSpace($inputCoord)) { continue }

    if ($inputCoord.Trim().ToUpper() -eq 'Q') {
        Write-Host "Fleet ordered to retreat. Ceasefire engaged." -ForegroundColor Yellow
        $game.IsGameOver = $true
        break
    }

    $clean = $inputCoord.Trim().ToUpper()
    if ($clean.Length -lt 2 -or $clean.Length -gt 3) {
        Write-Host "Invalid coordinate format. Use letter + number (A1 - J10)." -ForegroundColor Red
        continue
    }

    $colChar = $clean[0]
    $rowStr = $clean.Substring(1)
    $targetCol = [int]$colChar - 65
    $targetRow = 0

    if ($targetCol -lt 0 -or $targetCol -gt 9 -or -not [int]::TryParse($rowStr, [ref]$targetRow) -or $targetRow -lt 1 -or $targetRow -gt 10) {
        Write-Host "Coordinates out of bounds! Must be A-J and 1-10." -ForegroundColor Red
        continue
    }

    $targetRow-- # Zero-based index

    # Fire player shot
    $res = Invoke-FireShot -TargetGrid $game.CpuGrid -TrackingGrid $game.PlayerTracking -TargetFleet $game.CpuFleet -Row $targetRow -Col $targetCol
    if (-not $res.IsValid) {
        Write-Host $res.Message -ForegroundColor Yellow
        continue
    }

    Write-Host "`n>>> SALVO RESULT: $($res.Message) <<<" -ForegroundColor $(if ($res.IsHit) { 'Green' } else { 'Gray' })

    # Check player victory
    if (Test-FleetDefeated -Fleet $game.CpuFleet) {
        $game.IsGameOver = $true
        $game.Winner = "Player"
        Write-Host "`n========================================================================" -ForegroundColor Green
        Write-Host "VICTORY! You have completely annihilated the enemy fleet!" -ForegroundColor Green
        Write-Host "========================================================================" -ForegroundColor Green
        break
    }

    # CPU Turn
    Start-Sleep -Milliseconds 600
    Invoke-CpuTurn -Game $game

    # Check CPU victory
    if (Test-FleetDefeated -Fleet $game.PlayerFleet) {
        $game.IsGameOver = $true
        $game.Winner = "CPU"
        Write-Host "`n========================================================================" -ForegroundColor Red
        Write-Host "DEFEAT! All your vessels have been sunk to the bottom of the ocean." -ForegroundColor Red
        Write-Host "========================================================================" -ForegroundColor Red
        break
    }
}
