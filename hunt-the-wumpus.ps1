<#
.SYNOPSIS
    Hunt the Wumpus - Classic 1973 Text Adventure & Cave Deduction Game
.DESCRIPTION
    A complete, standalone PowerShell implementation of Gregory Yob's classic 1973 game.
    Navigate a 20-room dodecahedron cave system, listen for sensory cues, avoid bottomless pits
    and giant bats, and shoot crooked arrows into adjacent rooms to defeat the fearsome Wumpus.
.PARAMETER SmokeTest
    Runs an automated non-interactive self-test and verification round.
.PARAMETER RoomCount
    Number of rooms in the cave (default 20, standard dodecahedron).
.PARAMETER Arrows
    Starting number of crooked arrows (default 5).
.EXAMPLE
    ./hunt-the-wumpus.ps1
    ./hunt-the-wumpus.ps1 -SmokeTest
#>
[CmdletBinding()]
param(
    [switch]$SmokeTest,
    [int]$RoomCount = 20,
    [int]$Arrows = 5
)

# Standard 20-node Dodecahedron Cave Topology
# Each vertex has exactly 3 adjacent neighbors.
$script:DodecahedronCave = @{
    1  = @(2, 5, 8)
    2  = @(1, 3, 10)
    3  = @(2, 4, 12)
    4  = @(3, 5, 14)
    5  = @(1, 4, 6)
    6  = @(5, 7, 15)
    7  = @(6, 8, 17)
    8  = @(1, 7, 9)
    9  = @(8, 10, 18)
    10 = @(2, 9, 11)
    11 = @(10, 12, 19)
    12 = @(3, 11, 13)
    13 = @(12, 14, 20)
    14 = @(4, 13, 15)
    15 = @(6, 14, 16)
    16 = @(15, 17, 20)
    17 = @(7, 16, 18)
    18 = @(9, 17, 19)
    19 = @(11, 18, 20)
    20 = @(13, 16, 19)
}

function New-WumpusGame {
    param([int]$InitialArrows = 5)

    # Place player, wumpus, 2 pits, 2 bats in distinct rooms
    $allRooms = 1..20 | Sort-Object { Get-Random }
    
    $playerRoom = $allRooms[0]
    $wumpusRoom = $allRooms[1]
    $pitRooms   = @($allRooms[2], $allRooms[3])
    $batRooms   = @($allRooms[4], $allRooms[5])

    $visited = [System.Collections.Generic.HashSet[int]]::new()
    [void]$visited.Add([int]$playerRoom)

    [PSCustomObject]@{
        PlayerRoom   = $playerRoom
        WumpusRoom   = $wumpusRoom
        PitRooms     = $pitRooms
        BatRooms     = $batRooms
        Arrows       = $InitialArrows
        IsGameOver   = $false
        Victory      = $false
        GameOverReason = ''
        TurnCount    = 0
        VisitedRooms = $visited
    }
}

function Show-WumpusBanner {
    Write-Host @"
=============================================================
         H U N T   T H E   W U M P U S
=============================================================
 You are a brave hunter entering the damp, subterranean caves
 of the feared Wumpus. Armed with a bow and 5 crooked arrows,
 you must track the beast by its repulsive stench.

 Beware:
  - Bottomless pits will swallow you into the dark abyss.
  - Giant super-bats will snatch you and drop you anywhere.
  - Waking the Wumpus may cause it to charge into your room!
=============================================================
"@ -ForegroundColor Yellow
}

function Get-AdjacentRooms {
    param([int]$Room)
    return $script:DodecahedronCave[$Room]
}

function Get-SensoryWarnings {
    param([PSCustomObject]$Game)

    $adj = Get-AdjacentRooms -Room $Game.PlayerRoom
    $warnings = [System.Collections.Generic.List[string]]::new()

    if ($adj -contains $Game.WumpusRoom) {
        $warnings.Add("You smell something terrible nearby... (I smell a Wumpus!)")
    }
    foreach ($pit in $Game.PitRooms) {
        if ($adj -contains $pit) {
            $warnings.Add("You feel a cold, eerie draft... (I feel a draft!)")
            break
        }
    }
    foreach ($bat in $Game.BatRooms) {
        if ($adj -contains $bat) {
            $warnings.Add("You hear fluttering wings in the dark... (Bats nearby!)")
            break
        }
    }

    return $warnings
}

function Move-Wumpus {
    param([PSCustomObject]$Game)

    # Wumpus has a 75% chance to move to an adjacent room when startled
    $roll = Get-Random -Minimum 1 -Maximum 101
    if ($roll -le 75) {
        $adj = Get-AdjacentRooms -Room $Game.WumpusRoom
        $target = $adj | Get-Random
        $Game.WumpusRoom = $target
        if ($Game.WumpusRoom -eq $Game.PlayerRoom) {
            $Game.IsGameOver = $true
            $Game.Victory = $false
            $Game.GameOverReason = "The disturbed Wumpus stomped into your room and devoured you whole!"
        }
    }
}

function Move-Player {
    param(
        [PSCustomObject]$Game,
        [int]$TargetRoom
    )

    $adj = Get-AdjacentRooms -Room $Game.PlayerRoom
    if ($adj -notcontains $TargetRoom) {
        return [PSCustomObject]@{
            Success = $false
            Message = "You cannot reach Room $TargetRoom directly from Room $($Game.PlayerRoom). Valid tunnels: $($adj -join ', ')."
        }
    }

    $Game.PlayerRoom = $TargetRoom
    [void]$Game.VisitedRooms.Add($TargetRoom)
    $Game.TurnCount++

    # Check encounters
    if ($Game.PlayerRoom -eq $Game.WumpusRoom) {
        $Game.IsGameOver = $true
        $Game.Victory = $false
        $Game.GameOverReason = "You stumbled directly into the sleeping Wumpus! It woke up and ate you!"
        return [PSCustomObject]@{ Success = $true; Message = "Encountered Wumpus!" }
    }

    if ($Game.PitRooms -contains $Game.PlayerRoom) {
        $Game.IsGameOver = $true
        $Game.Victory = $false
        $Game.GameOverReason = "YYYIIIIEEEE!... You tumbled down into a bottomless pit to your death!"
        return [PSCustomObject]@{ Success = $true; Message = "Fell into pit!" }
    }

    if ($Game.BatRooms -contains $Game.PlayerRoom) {
        $dropRoom = (1..20 | Where-Object { $_ -ne $TargetRoom } | Sort-Object { Get-Random })[0]
        $oldRoom = $Game.PlayerRoom
        $Game.PlayerRoom = $dropRoom
        [void]$Game.VisitedRooms.Add($dropRoom)

        # Move the bat to another vacant room
        $newBatRoom = (1..20 | Where-Object { $_ -ne $oldRoom -and $_ -ne $dropRoom } | Sort-Object { Get-Random })[0]
        $Game.BatRooms = @($Game.BatRooms | Where-Object { $_ -ne $oldRoom }) + @($newBatRoom)

        $msg = "A giant super-bat swooped down, grabbed you by your collar, and dropped you into Room $dropRoom!"
        
        # Check hazards in drop room
        if ($Game.PlayerRoom -eq $Game.WumpusRoom) {
            $Game.IsGameOver = $true
            $Game.Victory = $false
            $Game.GameOverReason = "$msg Right onto the Wumpus! CHOMP!"
        } elseif ($Game.PitRooms -contains $Game.PlayerRoom) {
            $Game.IsGameOver = $true
            $Game.Victory = $false
            $Game.GameOverReason = "$msg Right down a bottomless pit!"
        }

        return [PSCustomObject]@{ Success = $true; Message = $msg }
    }

    return [PSCustomObject]@{
        Success = $true
        Message = "You crept through the tunnel into Room $TargetRoom."
    }
}

function Shoot-Arrow {
    param(
        [PSCustomObject]$Game,
        [int[]]$RoomPath
    )

    if ($Game.Arrows -le 0) {
        return [PSCustomObject]@{
            Success = $false
            Message = "You have no arrows left!"
        }
    }

    $Game.Arrows--
    $Game.TurnCount++

    if ($null -eq $RoomPath -or $RoomPath.Count -eq 0) {
        return [PSCustomObject]@{
            Success = $false
            Message = "You must specify at least one room for the arrow's flight."
        }
    }

    if ($RoomPath.Count -gt 5) {
        $RoomPath = $RoomPath[0..4]
    }

    $currentRoom = $Game.PlayerRoom
    $hitTarget = $false

    foreach ($nextRoom in $RoomPath) {
        $adj = Get-AdjacentRooms -Room $currentRoom
        if ($adj -notcontains $nextRoom) {
            # Arrow takes a random crooked ricochet through one of the valid exits
            $nextRoom = $adj | Get-Random
        }

        $currentRoom = $nextRoom

        # Check if arrow hit Wumpus
        if ($currentRoom -eq $Game.WumpusRoom) {
            $Game.IsGameOver = $true
            $Game.Victory = $true
            $Game.GameOverReason = "AHA! Your crooked arrow struck true into the heart of the Wumpus! You win!"
            $hitTarget = $true
            break
        }

        # Check if arrow hit Player
        if ($currentRoom -eq $Game.PlayerRoom) {
            $Game.IsGameOver = $true
            $Game.Victory = $false
            $Game.GameOverReason = "OUCH! The crooked arrow ricocheted through the caves and struck you right between the eyes!"
            $hitTarget = $true
            break
        }
    }

    if (-not $hitTarget) {
        # Arrow missed! Startle the Wumpus
        Move-Wumpus -Game $Game
        if (-not $Game.IsGameOver -and $Game.Arrows -eq 0) {
            $Game.IsGameOver = $true
            $Game.Victory = $false
            $Game.GameOverReason = "You fired your last arrow into the dark and missed. Without arrows, the caves claimed you."
        }
    }

    return [PSCustomObject]@{
        Success = $true
        Message = if ($Game.Victory) { "Direct hit on the Wumpus!" } else { "The arrow echoed through the tunnels and landed with a thud." }
    }
}

function Show-CaveRadar {
    param([PSCustomObject]$Game)

    $adj = Get-AdjacentRooms -Room $Game.PlayerRoom
    Write-Host "`n--- [ Cave Radar: Room $($Game.PlayerRoom) ] ---" -ForegroundColor Cyan
    Write-Host "Tunnels lead to Rooms: $($adj -join ', ')" -ForegroundColor White
    Write-Host "Remaining Crooked Arrows: $($Game.Arrows)" -ForegroundColor Green

    $warnings = Get-SensoryWarnings -Game $Game
    if ($warnings.Count -gt 0) {
        Write-Host "`n[Sensory Clues]:" -ForegroundColor Magenta
        foreach ($w in $warnings) {
            Write-Host "  * $w" -ForegroundColor Yellow
        }
    } else {
        Write-Host "`nAll seems calm and quiet in the immediate tunnels..." -ForegroundColor Gray
    }
    Write-Host "----------------------------------" -ForegroundColor Cyan
}

function Invoke-WumpusSmokeTest {
    Write-Host "[Wumpus] Running automated headless smoke test..." -ForegroundColor Cyan

    $game = New-WumpusGame -InitialArrows 5
    if ($null -eq $game -or $game.PlayerRoom -lt 1 -or $game.PlayerRoom -gt 20) {
        throw "Failed to initialize game properly."
    }

    Write-Host "[Wumpus] Initialized: Player at Room $($game.PlayerRoom), Arrows=$($game.Arrows)" -ForegroundColor Green
    
    $adj = Get-AdjacentRooms -Room $game.PlayerRoom
    if ($adj.Count -ne 3) {
        throw "Cave topology error: Room must have 3 neighbors."
    }

    # Test move
    $target = $adj[0]
    $moveResult = Move-Player -Game $game -TargetRoom $target
    if (-not $moveResult.Success -and -not $game.IsGameOver) {
        throw "Move to adjacent room $target failed."
    }
    Write-Host "[Wumpus] Moved to Room $($game.PlayerRoom): $($moveResult.Message)" -ForegroundColor Green

    # Test sensory warnings
    $warnings = Get-SensoryWarnings -Game $game
    Write-Host "[Wumpus] Sensory warnings count: $($warnings.Count)" -ForegroundColor Green

    # Test arrow shooting
    $shootAdj = Get-AdjacentRooms -Room $game.PlayerRoom
    $shootResult = Shoot-Arrow -Game $game -RoomPath @($shootAdj[0])
    if ($game.Arrows -ne 4) {
        throw "Arrow count should decrement to 4."
    }
    Write-Host "[Wumpus] Fired arrow: $($shootResult.Message), Arrows Left: $($game.Arrows)" -ForegroundColor Green

    Write-Host "[Wumpus] Smoke test PASSED successfully!" -ForegroundColor Green
    return $true
}

# Entrypoint Execution
if ($SmokeTest) {
    Invoke-WumpusSmokeTest
    exit 0
}

Show-WumpusBanner
$game = New-WumpusGame -InitialArrows $Arrows

while (-not $game.IsGameOver) {
    Show-CaveRadar -Game $game

    Write-Host "`nActions:" -ForegroundColor Cyan
    Write-Host "  [M] Move to adjacent room"
    Write-Host "  [S] Shoot crooked arrow"
    Write-Host "  [H] Help / Guide"
    Write-Host "  [Q] Quit game"
    
    $action = Read-Host "`nEnter Action (M, S, H, Q)"
    if ([string]::IsNullOrWhiteSpace($action)) { continue }

    switch ($action.Trim().ToUpper()) {
        'M' {
            $adj = Get-AdjacentRooms -Room $game.PlayerRoom
            $destStr = Read-Host "Enter room number to move to ($($adj -join ', '))"
            $dest = 0
            if ([int]::TryParse($destStr, [ref]$dest)) {
                $res = Move-Player -Game $game -TargetRoom $dest
                Write-Host "`n$($res.Message)" -ForegroundColor $(if ($game.IsGameOver -and -not $game.Victory) { 'Red' } else { 'Green' })
            } else {
                Write-Host "Invalid room number." -ForegroundColor Red
            }
        }
        'S' {
            $pathStr = Read-Host "Enter room path (1 to 5 room numbers separated by space, e.g., '2 3 12')"
            if (-not [string]::IsNullOrWhiteSpace($pathStr)) {
                $rooms = @($pathStr.Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries) | ForEach-Object {
                    $r = 0
                    if ([int]::TryParse($_, [ref]$r)) { $r }
                })
                if ($rooms.Count -gt 0) {
                    $sres = Shoot-Arrow -Game $game -RoomPath $rooms
                    Write-Host "`n$($sres.Message)" -ForegroundColor $(if ($game.Victory) { 'Green' } else { 'Yellow' })
                }
            }
        }
        'H' {
            Write-Host @"
HOW TO PLAY:
- The cave is composed of 20 rooms arranged like the vertices of a dodecahedron.
- Each room is connected to exactly 3 other rooms.
- Hazards:
    * Wumpus: Smells terrible from 1 room away. If entered, you get eaten.
    * Bottomless Pits: Creates drafts in adjacent rooms. If entered, you fall.
    * Super Bats: Make flapping noises. If entered, they pick you up and fly you away.
- Shooting:
    * You have 5 crooked arrows that can bend through up to 5 connected rooms.
    * If an arrow path doesn't connect, it ricochets into a random connected room.
    * If it hits the Wumpus, you win! If it hits you, you lose!
    * Missed arrows startle the Wumpus, which might run into your room.
"@ -ForegroundColor DarkCyan
        }
        'Q' {
            Write-Host "Exiting Hunt the Wumpus. Farewell, hunter!" -ForegroundColor Yellow
            $game.IsGameOver = $true
            $game.GameOverReason = "Quit game."
        }
        default {
            Write-Host "Unknown command. Choose M, S, H, or Q." -ForegroundColor Red
        }
    }
}

if (-not [string]::IsNullOrEmpty($game.GameOverReason)) {
    Write-Host "`n=============================================================" -ForegroundColor $(if ($game.Victory) { 'Green' } else { 'Red' })
    Write-Host "GAME OVER: $($game.GameOverReason)" -ForegroundColor $(if ($game.Victory) { 'Green' } else { 'Red' })
    Write-Host "Rooms visited: $($game.VisitedRooms.Count) | Total turns: $($game.TurnCount)"
    Write-Host "=============================================================" -ForegroundColor $(if ($game.Victory) { 'Green' } else { 'Red' })
}
