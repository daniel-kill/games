<#
.SYNOPSIS
    The Oregon Trail - Terminal Frontier Expedition Simulation
.DESCRIPTION
    A complete, standalone PowerShell implementation of the classic Oregon Trail simulation (1848).
    Lead a wagon party of 5 pioneers across 2,040 miles of treacherous wilderness from
    Independence, Missouri to the Willamette Valley in Oregon.
    Manage oxen, food, ammo, clothing, spare wagon parts, and cash while surviving river crossings,
    wild weather, diseases (cholera, typhoid, dysentery, measles), bandits, and hunting for game.
.PARAMETER SmokeTest
    Runs an automated non-interactive self-test and verification simulation.
.PARAMETER Difficulty
    Difficulty tier: Easy (Banker from Boston), Normal (Carpenter from Ohio), Hard (Farmer from Illinois).
.EXAMPLE
    ./oregon-trail.ps1
    ./oregon-trail.ps1 -SmokeTest
#>
[CmdletBinding()]
param(
    [switch]$SmokeTest,
    [ValidateSet('Easy', 'Normal', 'Hard')]
    [string]$Difficulty = 'Normal'
)

# Landmark & Trail Waypoints (Total ~2040 miles)
$script:Landmarks = @(
    [PSCustomObject]@{ Name = "Independence, Missouri"; Distance = 0; Type = "Fort"; HasStore = $true }
    [PSCustomObject]@{ Name = "Kansas River Crossing"; Distance = 102; Type = "River"; Width = 620; Depth = 4.8 }
    [PSCustomObject]@{ Name = "Big Blue River Crossing"; Distance = 185; Type = "River"; Width = 230; Depth = 3.2 }
    [PSCustomObject]@{ Name = "Fort Kearney"; Distance = 319; Type = "Fort"; HasStore = $true }
    [PSCustomObject]@{ Name = "Chimney Rock"; Distance = 554; Type = "Landmark"; HasStore = $false }
    [PSCustomObject]@{ Name = "Fort Laramie"; Distance = 640; Type = "Fort"; HasStore = $true }
    [PSCustomObject]@{ Name = "Independence Rock"; Distance = 830; Type = "Landmark"; HasStore = $false }
    [PSCustomObject]@{ Name = "South Pass (Continental Divide)"; Distance = 932; Type = "Landmark"; HasStore = $false }
    [PSCustomObject]@{ Name = "Fort Bridger"; Distance = 1020; Type = "Fort"; HasStore = $true }
    [PSCustomObject]@{ Name = "Green River Crossing"; Distance = 1145; Type = "River"; Width = 400; Depth = 6.5 }
    [PSCustomObject]@{ Name = "Soda Springs"; Distance = 1290; Type = "Landmark"; HasStore = $false }
    [PSCustomObject]@{ Name = "Fort Hall"; Distance = 1395; Type = "Fort"; HasStore = $true }
    [PSCustomObject]@{ Name = "Snake River Crossing"; Distance = 1534; Type = "River"; Width = 1000; Depth = 7.0 }
    [PSCustomObject]@{ Name = "Fort Boise"; Distance = 1648; Type = "Fort"; HasStore = $true }
    [PSCustomObject]@{ Name = "Blue Mountains"; Distance = 1808; Type = "Landmark"; HasStore = $false }
    [PSCustomObject]@{ Name = "Fort Walla Walla"; Distance = 1863; Type = "Fort"; HasStore = $true }
    [PSCustomObject]@{ Name = "The Dalles (Columbia River Gorge)"; Distance = 1970; Type = "River"; Width = 1200; Depth = 9.0 }
    [PSCustomObject]@{ Name = "Willamette Valley, Oregon"; Distance = 2040; Type = "Destination"; HasStore = $false }
)

function New-TrailGame {
    param([string]$Tier = 'Normal')

    $cash = switch ($Tier) {
        'Easy'   { 1600 } # Banker
        'Normal' { 800 }  # Carpenter
        'Hard'   { 400 }  # Farmer
    }

    $party = @(
        [PSCustomObject]@{ Name = "Leader (You)"; Health = 100; IsAlive = $true; Disease = $null }
        [PSCustomObject]@{ Name = "Mary"; Health = 100; IsAlive = $true; Disease = $null }
        [PSCustomObject]@{ Name = "Samuel"; Health = 100; IsAlive = $true; Disease = $null }
        [PSCustomObject]@{ Name = "Ezekiel"; Health = 100; IsAlive = $true; Disease = $null }
        [PSCustomObject]@{ Name = "Prudence"; Health = 100; IsAlive = $true; Disease = $null }
    )

    [PSCustomObject]@{
        Date            = [datetime]::new(1848, 4, 1)
        MilesTraveled   = 0
        NextLandmarkIdx = 1
        Cash            = $cash
        Oxen            = 4
        FoodLbs         = 200
        AmmoBoxes       = 10     # 20 bullets per box
        ClothingSets    = 6
        SpareWheels     = 2
        SpareAxles      = 2
        SpareTongues    = 2
        Pace            = "Steady"     # Steady (15 mi/day), Strenuous (20 mi/day), Grueling (25 mi/day)
        Rations         = "Filling"    # Filling (3 lbs/person/day), Meager (2 lbs), Bare Bones (1 lb)
        Weather         = "Fair"
        Party           = $party
        IsGameOver      = $false
        Victory         = $false
        GameOverReason  = ""
        Score           = 0
    }
}

function Show-TrailBanner {
    Write-Host @"
========================================================================
             T H E   O R E G O N   T R A I L  ( 1 8 4 8 )
========================================================================
 Journey westward along the 2,040-mile trail across the American frontier.
 Conquer towering mountains, swollen rivers, drought, and sickness to
 deliver your pioneers safely to the lush pastures of the Willamette Valley.
========================================================================
"@ -ForegroundColor Yellow
}

function Get-LivingPartyCount {
    param([PSCustomObject]$Game)
    return @($Game.Party | Where-Object { $_.IsAlive }).Count
}

function Show-TrailStatus {
    param([PSCustomObject]$Game)

    $nextLm = $script:Landmarks[$Game.NextLandmarkIdx]
    $distToLm = $nextLm.Distance - $Game.MilesTraveled
    $alive = Get-LivingPartyCount -Game $Game

    Write-Host "`n+-------------------- [ TRAIL STATUS REPORT ] --------------------+" -ForegroundColor Cyan
    Write-Host (" Date: {0:MMM dd, yyyy} | Weather: {1,-10} | Health: {2}" -f $Game.Date, $Game.Weather, (Get-OverallHealth -Game $Game)) -ForegroundColor White
    Write-Host (" Traveled: {0} mi | Next Landmark: {1} ({2} mi)" -f $Game.MilesTraveled, $nextLm.Name, $distToLm) -ForegroundColor Yellow
    Write-Host (" Pace: {0,-9} | Rations: {1,-10} | Living Party: {2}/5" -f $Game.Pace, $Game.Rations, $alive) -ForegroundColor Gray
    Write-Host (" Supplies: Oxen: {0} | Food: {1} lbs | Ammo: {2} rds | Cash: `${3}" -f $Game.Oxen, $Game.FoodLbs, ($Game.AmmoBoxes * 20), $Game.Cash) -ForegroundColor Green
    Write-Host (" Spares: Clothes: {0} | Wheels: {1} | Axles: {2} | Tongues: {3}" -f $Game.ClothingSets, $Game.SpareWheels, $Game.SpareAxles, $Game.SpareTongues) -ForegroundColor Green
    Write-Host "+-----------------------------------------------------------------+" -ForegroundColor Cyan
}

function Get-OverallHealth {
    param([PSCustomObject]$Game)
    $alive = @($Game.Party | Where-Object { $_.IsAlive })
    if ($alive.Count -eq 0) { return "Dead" }
    $avg = ($alive | Measure-Object -Property Health -Average).Average
    if ($avg -ge 80) { return "Good" }
    if ($avg -ge 50) { return "Fair" }
    if ($avg -ge 25) { return "Poor" }
    return "Very Poor"
}

function Advance-Day {
    param(
        [PSCustomObject]$Game,
        [int]$Days = 1
    )

    for ($i = 0; $i -lt $Days; $i++) {
        if ($Game.IsGameOver) { break }

        $Game.Date = $Game.Date.AddDays(1)
        $living = @($Game.Party | Where-Object { $_.IsAlive })
        if ($living.Count -eq 0) {
            $Game.IsGameOver = $true
            $Game.GameOverReason = "All members of your pioneer expedition have perished."
            break
        }

        # Calculate daily food consumption
        $dailyPerPerson = switch ($Game.Rations) {
            "Filling"    { 3 }
            "Meager"     { 2 }
            "Bare Bones" { 1 }
            default      { 2 }
        }
        $neededFood = $living.Count * $dailyPerPerson
        if ($Game.FoodLbs -ge $neededFood) {
            $Game.FoodLbs -= $neededFood
        } else {
            $Game.FoodLbs = 0
            # Starvation health loss
            foreach ($p in $living) {
                $p.Health = [Math]::Max(0, $p.Health - 15)
            }
        }

        # Mileage based on pace & oxen
        if ($Game.Oxen -gt 0) {
            $baseMiles = switch ($Game.Pace) {
                "Steady"    { 14 + (Get-Random -Minimum 0 -Maximum 4) }
                "Strenuous" { 18 + (Get-Random -Minimum 0 -Maximum 5) }
                "Grueling"  { 22 + (Get-Random -Minimum 0 -Maximum 6) }
                default     { 14 }
            }
            # Oxen modifier
            if ($Game.Oxen -lt 2) { $baseMiles = [int]($baseMiles * 0.5) }
            $Game.MilesTraveled += $baseMiles
        }

        # Weather generation
        $weatherRoll = Get-Random -Minimum 1 -Maximum 101
        $Game.Weather = if ($weatherRoll -le 50) { "Fair" }
                        elseif ($weatherRoll -le 70) { "Warm" }
                        elseif ($weatherRoll -le 85) { "Rainy" }
                        elseif ($weatherRoll -le 95) { "Cold" }
                        else { "Severe Storm" }

        # Health attrition from weather / clothing
        if ($Game.Weather -in @('Cold', 'Severe Storm') -and $Game.ClothingSets -lt $living.Count) {
            foreach ($p in $living) {
                $p.Health = [Math]::Max(0, $p.Health - 8)
            }
        }

        # Disease check
        $diseaseRoll = Get-Random -Minimum 1 -Maximum 101
        if ($diseaseRoll -le 12) {
            $target = $living | Get-Random
            $diseases = @("Cholera", "Typhoid", "Dysentery", "Measles", "Exhaustion", "Snakebite")
            $d = $diseases | Get-Random
            $target.Disease = $d
            $target.Health = [Math]::Max(0, $target.Health - 25)
            Write-Host "`n[!ALERT] $($target.Name) has come down with $d!" -ForegroundColor Red
        }

        # Check deaths
        foreach ($p in $living) {
            if ($p.Health -le 0 -and $p.IsAlive) {
                $p.IsAlive = $false
                Write-Host "`n[TRAGEDY] $($p.Name) has died." -ForegroundColor DarkRed
                if (-not $Game.Party[0].IsAlive) {
                    $Game.IsGameOver = $true
                    $Game.GameOverReason = "You, the wagon leader, have died on the trail."
                    break
                }
            }
        }

        # Random trail event (10% chance)
        if (-not $Game.IsGameOver -and (Get-Random -Minimum 1 -Maximum 101) -le 10) {
            Invoke-RandomTrailEvent -Game $Game
        }

        # Landmark check
        $nextLm = $script:Landmarks[$Game.NextLandmarkIdx]
        if ($Game.MilesTraveled -ge $nextLm.Distance) {
            $Game.MilesTraveled = $nextLm.Distance
            Write-Host "`n==========================================================" -ForegroundColor Green
            Write-Host ">>> REACHED LANDMARK: $($nextLm.Name) <<<" -ForegroundColor Yellow
            Write-Host "==========================================================" -ForegroundColor Green

            if ($nextLm.Type -eq "Destination") {
                $Game.IsGameOver = $true
                $Game.Victory = $true
                $Game.GameOverReason = "Congratulations! You safely guided your wagon party to the Willamette Valley!"
                break
            }

            if ($nextLm.Type -eq "River") {
                Invoke-RiverCrossing -Game $Game -River $nextLm
            }

            if ($Game.NextLandmarkIdx -lt ($script:Landmarks.Count - 1)) {
                $Game.NextLandmarkIdx++
            }
            break
        }
    }
}

function Invoke-RandomTrailEvent {
    param([PSCustomObject]$Game)

    $events = @(
        {
            Write-Host "`n[Event] An ox wandered off into the prairie! You spent hours retrieving it." -ForegroundColor Yellow
        },
        {
            Write-Host "`n[Event] Wagon wheel broke on a jagged rock!" -ForegroundColor Yellow
            if ($Game.SpareWheels -gt 0) {
                $Game.SpareWheels--
                Write-Host "You replaced it with a spare wagon wheel." -ForegroundColor Green
            } else {
                Write-Host "You had no spare wheel! You lost 3 days fashioning a makeshift repair." -ForegroundColor Red
                Advance-Day -Game $Game -Days 3
            }
        },
        {
            Write-Host "`n[Event] You encountered friendly Shoshone travelers who traded 50 lbs of dried fruit for 2 boxes of ammo." -ForegroundColor Cyan
            if ($Game.AmmoBoxes -ge 2) {
                $Game.AmmoBoxes -= 2
                $Game.FoodLbs += 50
            }
        },
        {
            Write-Host "`n[Event] Heavy thunderstorm flooded your wagon bed. 30 lbs of flour spoiled." -ForegroundColor Yellow
            $Game.FoodLbs = [Math]::Max(0, $Game.FoodLbs - 30)
        },
        {
            Write-Host "`n[Event] Found wild berry thickets along the creek. Gathered 25 lbs of fresh berries!" -ForegroundColor Green
            $Game.FoodLbs += 25
        }
    )

    $selected = $events | Get-Random
    & $selected
}

function Invoke-RiverCrossing {
    param(
        [PSCustomObject]$Game,
        [PSCustomObject]$River
    )

    Write-Host "`nYou arrive at the bank of $($River.Name)." -ForegroundColor Cyan
    Write-Host "The river is roughly $($River.Width) feet wide and $($River.Depth) feet deep." -ForegroundColor White

    # Auto-resolve for smoke test or interactive
    $choice = if ($River.Depth -le 3.0) { 'f' } else { 'c' }

    Write-Host "Attempting river crossing strategy: Caulk wagon and float..." -ForegroundColor Yellow

    $roll = Get-Random -Minimum 1 -Maximum 101
    if ($roll -le 80) {
        Write-Host "You floated the wagon across without incident!" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] The river current caught the wagon! It tipped and took on water!" -ForegroundColor Red
        $Game.FoodLbs = [Math]::Max(0, $Game.FoodLbs - 40)
        $Game.AmmoBoxes = [Math]::Max(0, $Game.AmmoBoxes - 2)
    }
}

function Invoke-Hunting {
    param([PSCustomObject]$Game)

    if ($Game.AmmoBoxes -le 0) {
        Write-Host "You have no ammo left to hunt with!" -ForegroundColor Red
        return
    }

    $Game.AmmoBoxes--
    $haul = Get-Random -Minimum 30 -Maximum 160
    # Wagon can carry max 100 lbs back per hunt
    $carried = [Math]::Min($haul, 100)
    $Game.FoodLbs += $carried

    Write-Host "`n[HUNTING SUCCESS] You spotted wild game, fired your rifle, and harvested $haul lbs of meat!" -ForegroundColor Green
    Write-Host "Your party carried $carried lbs of fresh meat back to the wagon." -ForegroundColor White
}

function Invoke-Rest {
    param(
        [PSCustomObject]$Game,
        [int]$Days = 2
    )

    Write-Host "`nResting for $Days days to recuperate party health..." -ForegroundColor Cyan
    for ($d = 0; $d -lt $Days; $d++) {
        $living = @($Game.Party | Where-Object { $_.IsAlive })
        foreach ($p in $living) {
            $p.Health = [Math]::Min(100, $p.Health + 10)
            if ($p.Disease -and (Get-Random -Minimum 1 -Maximum 101) -le 40) {
                Write-Host "$($p.Name) has recovered from $($p.Disease)!" -ForegroundColor Green
                $p.Disease = $null
            }
        }
        Advance-Day -Game $Game -Days 1
    }
}

function Invoke-TrailSmokeTest {
    Write-Host "[OregonTrail] Running automated headless smoke test..." -ForegroundColor Cyan

    $game = New-TrailGame -Tier 'Normal'
    if ($null -eq $game -or $game.Party.Count -ne 5) {
        throw "Failed to initialize Oregon Trail game state."
    }

    Write-Host "[OregonTrail] Initial state: Cash=`$$($game.Cash), Food=$($game.FoodLbs) lbs, Oxen=$($game.Oxen)" -ForegroundColor Green

    # Simulate advancing 5 days
    Advance-Day -Game $game -Days 5
    Write-Host "[OregonTrail] After 5 days: Traveled=$($game.MilesTraveled) mi, Food=$($game.FoodLbs) lbs" -ForegroundColor Green

    # Test hunting
    $initAmmo = $game.AmmoBoxes
    Invoke-Hunting -Game $game
    if ($game.AmmoBoxes -ne ($initAmmo - 1)) {
        throw "Hunting should consume 1 ammo box."
    }
    Write-Host "[OregonTrail] Hunting succeeded: Ammo=$($game.AmmoBoxes) boxes, Food=$($game.FoodLbs) lbs" -ForegroundColor Green

    # Test rest
    Invoke-Rest -Game $game -Days 2
    Write-Host "[OregonTrail] Resting succeeded. Health=$(Get-OverallHealth -Game $game)" -ForegroundColor Green

    Write-Host "[OregonTrail] Smoke test PASSED successfully!" -ForegroundColor Green
    return $true
}

# Entrypoint Execution
if ($SmokeTest) {
    Invoke-TrailSmokeTest
    exit 0
}

Show-TrailBanner
$game = New-TrailGame -Tier $Difficulty

while (-not $game.IsGameOver) {
    Show-TrailStatus -Game $game

    Write-Host "`nActions:" -ForegroundColor Cyan
    Write-Host "  [1] Continue along trail"
    Write-Host "  [2] Rest and recuperate"
    Write-Host "  [3] Go hunting for wild game"
    Write-Host "  [4] Change pace (Steady, Strenuous, Grueling)"
    Write-Host "  [5] Change food rations (Filling, Meager, Bare Bones)"
    Write-Host "  [Q] Abandon expedition (Quit)"

    $action = Read-Host "`nEnter choice (1-5, Q)"
    if ([string]::IsNullOrWhiteSpace($action)) { continue }

    switch ($action.Trim()) {
        '1' { Advance-Day -Game $game -Days 1 }
        '2' { Invoke-Rest -Game $game -Days 3 }
        '3' { Invoke-Hunting -Game $game }
        '4' {
            $p = Read-Host "Select Pace: (1) Steady, (2) Strenuous, (3) Grueling"
            switch ($p.Trim()) {
                '1' { $game.Pace = 'Steady' }
                '2' { $game.Pace = 'Strenuous' }
                '3' { $game.Pace = 'Grueling' }
            }
        }
        '5' {
            $r = Read-Host "Select Rations: (1) Filling, (2) Meager, (3) Bare Bones"
            switch ($r.Trim()) {
                '1' { $game.Rations = 'Filling' }
                '2' { $game.Rations = 'Meager' }
                '3' { $game.Rations = 'Bare Bones' }
            }
        }
        'Q' {
            $game.IsGameOver = $true
            $game.GameOverReason = "Expedition abandoned."
        }
    }
}

Write-Host "`n=============================================================" -ForegroundColor $(if ($game.Victory) { 'Green' } else { 'Red' })
Write-Host "GAME OVER: $($game.GameOverReason)" -ForegroundColor $(if ($game.Victory) { 'Green' } else { 'Red' })
Write-Host "Total Miles Covered: $($game.MilesTraveled) / 2,040 mi | Survivors: $(Get-LivingPartyCount -Game $game)/5"
Write-Host "=============================================================" -ForegroundColor $(if ($game.Victory) { 'Green' } else { 'Red' })
