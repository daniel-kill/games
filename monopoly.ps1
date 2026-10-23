param(
    [ValidateRange(1, 3)][int]$CpuCount = 0,
    [switch]$Help,
    [switch]$SmokeTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Show-HelpText {
    Write-Host @"
Standalone Monopoly (PowerShell)

Usage:
  ./monopoly.ps1 [-CpuCount 1..3]
  ./monopoly.ps1 -Help
  ./monopoly.ps1 -SmokeTest

Overview:
  - Single-player Monopoly against 1, 2, or 3 configurable CPU opponents.
  - Faithful to classic official Monopoly board game rules:
    * Standard 40-space board & starting bankroll of `$1,500.
    * 32 Houses and 12 Hotels total bank supply limit with housing shortages.
    * Official 16 Chance and 16 Community Chest shuffled decks with bottom recycling.
    * Property Auctions: If a player lands on an unowned property and declines/cannot afford,
      it is immediately auctioned to all active players.
    * Official Bankruptcy: When bankrupted by another player, all cash and properties transfer
      to the creditor. Mortgaged properties retain mortgage.
    * Even building rule: You must build evenly across a color group.
    * Double rent on unimproved full color monopolies.
    * 10% mortgage interest upon unmortgage.
    * Speeding in jail rule (3 consecutive doubles).

Parameters:
  -CpuCount <1..3>  Number of computer opponents (default prompts if interactive, or 3).
  -SmokeTest        Runs non-interactive headless verification tests and exits with code 0.
  -Help             Displays this help manual.

Quick controls:
  - Follow the phase menu prompts.
  - Type q to quit at most prompts.
"@
}

if ($Help) {
    Show-HelpText
    exit 0
}

# ---------------- Constants ----------------

$ALL_TOKENS = @('TopHat', 'Car', 'Ship', 'Dog')
$ALL_NAMES  = @('You', 'Comet', 'Stella', 'Biscuit')

$STARTING_MONEY = 1500
$GO_SALARY = 200
$JAIL_POSITION = 10
$JAIL_FINE = 50
$MAX_JAIL_TURNS = 3
$MAX_ROUNDS = 200

$TOTAL_BANK_HOUSES = 32
$TOTAL_BANK_HOTELS = 12

$BOARD = @(
    [ordered]@{ type = 'go'; name = 'GO'; price = $null; rent = $null; houseCost = $null; color = $null; amount = $null },
    [ordered]@{ type = 'property'; name = 'Mediterranean Ave'; color = 'brown'; price = 60; rent = @(2, 10, 30, 90, 160, 250); houseCost = 50; amount = $null },
    [ordered]@{ type = 'community_chest'; name = 'Community Chest'; price = $null; rent = $null; houseCost = $null; color = $null; amount = $null },
    [ordered]@{ type = 'property'; name = 'Baltic Ave'; color = 'brown'; price = 60; rent = @(4, 20, 60, 180, 320, 450); houseCost = 50; amount = $null },
    [ordered]@{ type = 'tax'; name = 'Income Tax'; amount = 200; price = $null; rent = $null; houseCost = $null; color = $null },
    [ordered]@{ type = 'railroad'; name = 'Reading Railroad'; price = 200; rent = $null; houseCost = $null; color = $null; amount = $null },
    [ordered]@{ type = 'property'; name = 'Oriental Ave'; color = 'lightblue'; price = 100; rent = @(6, 30, 90, 270, 400, 550); houseCost = 50; amount = $null },
    [ordered]@{ type = 'chance'; name = 'Chance'; price = $null; rent = $null; houseCost = $null; color = $null; amount = $null },
    [ordered]@{ type = 'property'; name = 'Vermont Ave'; color = 'lightblue'; price = 100; rent = @(6, 30, 90, 270, 400, 550); houseCost = 50; amount = $null },
    [ordered]@{ type = 'property'; name = 'Connecticut Ave'; color = 'lightblue'; price = 120; rent = @(8, 40, 100, 300, 450, 600); houseCost = 50; amount = $null },
    [ordered]@{ type = 'jail'; name = 'Jail / Just Visiting'; price = $null; rent = $null; houseCost = $null; color = $null; amount = $null },
    [ordered]@{ type = 'property'; name = 'St. Charles Place'; color = 'pink'; price = 140; rent = @(10, 50, 150, 450, 625, 750); houseCost = 100; amount = $null },
    [ordered]@{ type = 'utility'; name = 'Electric Company'; price = 150; rent = $null; houseCost = $null; color = $null; amount = $null },
    [ordered]@{ type = 'property'; name = 'States Ave'; color = 'pink'; price = 140; rent = @(10, 50, 150, 450, 625, 750); houseCost = 100; amount = $null },
    [ordered]@{ type = 'property'; name = 'Virginia Ave'; color = 'pink'; price = 160; rent = @(12, 60, 180, 500, 700, 900); houseCost = 100; amount = $null },
    [ordered]@{ type = 'railroad'; name = 'Pennsylvania Railroad'; price = 200; rent = $null; houseCost = $null; color = $null; amount = $null },
    [ordered]@{ type = 'property'; name = 'St. James Place'; color = 'orange'; price = 180; rent = @(14, 70, 200, 550, 750, 950); houseCost = 100; amount = $null },
    [ordered]@{ type = 'community_chest'; name = 'Community Chest'; price = $null; rent = $null; houseCost = $null; color = $null; amount = $null },
    [ordered]@{ type = 'property'; name = 'Tennessee Ave'; color = 'orange'; price = 180; rent = @(14, 70, 200, 550, 750, 950); houseCost = 100; amount = $null },
    [ordered]@{ type = 'property'; name = 'New York Ave'; color = 'orange'; price = 200; rent = @(16, 80, 220, 600, 800, 1000); houseCost = 100; amount = $null },
    [ordered]@{ type = 'freeparking'; name = 'Free Parking'; price = $null; rent = $null; houseCost = $null; color = $null; amount = $null },
    [ordered]@{ type = 'property'; name = 'Kentucky Ave'; color = 'red'; price = 220; rent = @(18, 90, 250, 700, 875, 1050); houseCost = 150; amount = $null },
    [ordered]@{ type = 'chance'; name = 'Chance'; price = $null; rent = $null; houseCost = $null; color = $null; amount = $null },
    [ordered]@{ type = 'property'; name = 'Indiana Ave'; color = 'red'; price = 220; rent = @(18, 90, 250, 700, 875, 1050); houseCost = 150; amount = $null },
    [ordered]@{ type = 'property'; name = 'Illinois Ave'; color = 'red'; price = 240; rent = @(20, 100, 300, 750, 925, 1100); houseCost = 150; amount = $null },
    [ordered]@{ type = 'railroad'; name = 'B&O Railroad'; price = 200; rent = $null; houseCost = $null; color = $null; amount = $null },
    [ordered]@{ type = 'property'; name = 'Atlantic Ave'; color = 'yellow'; price = 260; rent = @(22, 110, 330, 800, 975, 1150); houseCost = 150; amount = $null },
    [ordered]@{ type = 'property'; name = 'Ventnor Ave'; color = 'yellow'; price = 260; rent = @(22, 110, 330, 800, 975, 1150); houseCost = 150; amount = $null },
    [ordered]@{ type = 'utility'; name = 'Water Works'; price = 150; rent = $null; houseCost = $null; color = $null; amount = $null },
    [ordered]@{ type = 'property'; name = 'Marvin Gardens'; color = 'yellow'; price = 280; rent = @(24, 120, 360, 850, 1025, 1200); houseCost = 150; amount = $null },
    [ordered]@{ type = 'gotojail'; name = 'Go to Jail'; price = $null; rent = $null; houseCost = $null; color = $null; amount = $null },
    [ordered]@{ type = 'property'; name = 'Pacific Ave'; color = 'green'; price = 300; rent = @(26, 130, 390, 900, 1100, 1275); houseCost = 200; amount = $null },
    [ordered]@{ type = 'property'; name = 'North Carolina Ave'; color = 'green'; price = 300; rent = @(26, 130, 390, 900, 1100, 1275); houseCost = 200; amount = $null },
    [ordered]@{ type = 'community_chest'; name = 'Community Chest'; price = $null; rent = $null; houseCost = $null; color = $null; amount = $null },
    [ordered]@{ type = 'property'; name = 'Pennsylvania Ave'; color = 'green'; price = 320; rent = @(28, 150, 450, 1000, 1200, 1400); houseCost = 200; amount = $null },
    [ordered]@{ type = 'railroad'; name = 'Short Line Railroad'; price = 200; rent = $null; houseCost = $null; color = $null; amount = $null },
    [ordered]@{ type = 'chance'; name = 'Chance'; price = $null; rent = $null; houseCost = $null; color = $null; amount = $null },
    [ordered]@{ type = 'property'; name = 'Park Place'; color = 'darkblue'; price = 350; rent = @(35, 175, 500, 1100, 1300, 1500); houseCost = 200; amount = $null },
    [ordered]@{ type = 'tax'; name = 'Luxury Tax'; amount = 100; price = $null; rent = $null; houseCost = $null; color = $null },
    [ordered]@{ type = 'property'; name = 'Boardwalk'; color = 'darkblue'; price = 400; rent = @(50, 200, 600, 1400, 1700, 2000); houseCost = 200; amount = $null }
)

$COLOR_GROUPS = [ordered]@{
    brown     = @(1, 3)
    lightblue = @(6, 8, 9)
    pink      = @(11, 13, 14)
    orange    = @(16, 18, 19)
    red       = @(21, 23, 24)
    yellow    = @(26, 27, 29)
    green     = @(31, 32, 34)
    darkblue  = @(37, 39)
}

$RAILROAD_POSITIONS = @(5, 15, 25, 35)
$UTILITY_POSITIONS = @(12, 28)

# ---------------- Shuffled Standard Decks ----------------

function Get-StandardCommunityChestDeck {
    @(
        @{ id = 'cc_advance_go'; text = 'Advance to GO (Collect $200)'; action = 'advance_go' },
        @{ id = 'cc_bank_error'; text = 'Bank error in your favor. Collect $200'; action = 'bank_error' },
        @{ id = 'cc_doctor'; text = 'Doctor fee. Pay $50'; action = 'doctor_fee' },
        @{ id = 'cc_stock_sale'; text = 'From sale of stock you get $50'; action = 'stock_sale' },
        @{ id = 'cc_jail_free'; text = 'Get Out of Jail Free card'; action = 'jail_free' },
        @{ id = 'cc_goto_jail'; text = 'Go to Jail. Go directly to jail, do not pass GO, do not collect $200'; action = 'goto_jail' },
        @{ id = 'cc_holiday_fund'; text = 'Holiday fund matures. Receive $100'; action = 'holiday_fund' },
        @{ id = 'cc_tax_refund'; text = 'Income tax refund. Collect $20'; action = 'tax_refund' },
        @{ id = 'cc_birthday'; text = 'It is your birthday. Collect $10 from every player'; action = 'birthday' },
        @{ id = 'cc_life_insurance'; text = 'Life insurance matures. Collect $100'; action = 'life_insurance' },
        @{ id = 'cc_hospital'; text = 'Pay hospital fees of $100'; action = 'hospital_fee' },
        @{ id = 'cc_school_fee'; text = 'Pay school fees of $50'; action = 'school_fee' },
        @{ id = 'cc_consultancy'; text = 'Receive $25 consultancy fee'; action = 'consultancy_fee' },
        @{ id = 'cc_street_repairs'; text = 'You are assessed for street repairs: $40 per house, $115 per hotel'; action = 'street_repairs' },
        @{ id = 'cc_beauty_contest'; text = 'You have won second prize in a beauty contest. Collect $10'; action = 'beauty_contest' },
        @{ id = 'cc_inherit'; text = 'You inherit $100'; action = 'inherit' }
    ) | Sort-Object { Get-Random }
}

function Get-StandardChanceDeck {
    @(
        @{ id = 'ch_advance_go'; text = 'Advance to GO (Collect $200)'; action = 'advance_go' },
        @{ id = 'ch_advance_illinois'; text = 'Advance to Illinois Ave. If you pass GO, collect $200'; action = 'advance_illinois' },
        @{ id = 'ch_advance_st_charles'; text = 'Advance to St. Charles Place. If you pass GO, collect $200'; action = 'advance_st_charles' },
        @{ id = 'ch_advance_utility'; text = 'Advance token to nearest Utility. If unowned you may buy it; if owned throw dice and pay 10x throw'; action = 'advance_utility' },
        @{ id = 'ch_advance_railroad_1'; text = 'Advance token to the nearest Railroad and pay owner twice the rental to which he is entitled'; action = 'advance_railroad' },
        @{ id = 'ch_advance_railroad_2'; text = 'Advance token to the nearest Railroad and pay owner twice the rental to which he is entitled'; action = 'advance_railroad' },
        @{ id = 'ch_bank_dividend'; text = 'Bank pays you dividend of $50'; action = 'bank_dividend' },
        @{ id = 'ch_jail_free'; text = 'Get Out of Jail Free card'; action = 'jail_free' },
        @{ id = 'ch_back_3'; text = 'Go Back 3 Spaces'; action = 'back_3' },
        @{ id = 'ch_goto_jail'; text = 'Go to Jail. Go directly to jail, do not pass GO, do not collect $200'; action = 'goto_jail' },
        @{ id = 'ch_general_repairs'; text = 'Make general repairs on all your property: For each house pay $25, for each hotel $100'; action = 'general_repairs' },
        @{ id = 'ch_poor_tax'; text = 'Speeding fine / Poor tax. Pay $15'; action = 'poor_tax' },
        @{ id = 'ch_trip_reading'; text = 'Take a trip to Reading Railroad. If you pass GO, collect $200'; action = 'trip_reading' },
        @{ id = 'ch_boardwalk'; text = 'Take a walk on the Boardwalk. Advance token to Boardwalk'; action = 'advance_boardwalk' },
        @{ id = 'ch_chairman'; text = 'You have been elected Chairman of the Board. Pay each player $50'; action = 'chairman' },
        @{ id = 'ch_building_loan'; text = 'Your building loan matures. Collect $150'; action = 'building_loan' }
    ) | Sort-Object { Get-Random }
}

# ---------------- Utility ----------------

function New-Player([int]$Index) {
    @{
        name              = $ALL_NAMES[$Index]
        token             = $ALL_TOKENS[$Index]
        money             = $STARTING_MONEY
        position          = 0
        inJail            = $false
        jailTurns         = 0
        getOutOfJailCards = 0
        bankrupt          = $false
        doublesCount      = 0
        isCpu             = ($Index -gt 0)
    }
}

function New-Game([int]$NumCpus = 3) {
    $props = @(for ($i = 0; $i -lt 40; $i++) { $null })

    $playerList = @()
    $playerList += (New-Player 0) # Human player "You"
    for ($c = 1; $c -le $NumCpus; $c++) {
        $playerList += (New-Player $c)
    }

    @{
        round            = 1
        phase            = 'roll'
        pendingBuySquare = $null
        players          = $playerList
        properties       = $props
        lastDice         = $null
        bankHouses       = $TOTAL_BANK_HOUSES
        bankHotels       = $TOTAL_BANK_HOTELS
        chanceDeck       = [System.Collections.Generic.List[hashtable]](Get-StandardChanceDeck)
        chestDeck        = [System.Collections.Generic.List[hashtable]](Get-StandardCommunityChestDeck)
        events           = @("Game started with $($NumCpus) CPU opponent(s). You go first!")
    }
}

function Roll-Dice {
    $d1 = Get-Random -Minimum 1 -Maximum 7
    $d2 = Get-Random -Minimum 1 -Maximum 7
    [ordered]@{ d1 = $d1; d2 = $d2; total = $d1 + $d2; doubles = ($d1 -eq $d2) }
}

function Clone-Game([hashtable]$Game) {
    $json = $Game | ConvertTo-Json -Depth 15
    $cloneObj = $json | ConvertFrom-Json -Depth 15
    return ($cloneObj | ConvertTo-Json -Depth 15 | ConvertFrom-Json -AsHashtable -Depth 15)
}

function Add-Event([hashtable]$Game, [string]$Message) {
    $recent = @($Game.events + $Message)
    if ($recent.Count -gt 18) {
        $Game.events = $recent[($recent.Count - 18)..($recent.Count - 1)]
    }
    else {
        $Game.events = $recent
    }
}

function Get-ActivePlayers([hashtable]$Game) {
    @($Game.players | Where-Object { -not $_.bankrupt })
}

function Get-TotalHousesAndHotelsOnBoard([hashtable]$Game) {
    $houses = 0
    $hotels = 0
    for ($i = 0; $i -lt 40; $i++) {
        $p = $Game.properties[$i]
        if ($null -ne $p) {
            $h = [int]$p.houses
            if ($h -eq 5) { $hotels++ }
            elseif ($h -gt 0) { $houses += $h }
        }
    }
    return @{ houses = $houses; hotels = $hotels }
}

function Get-NetWorth([hashtable]$Game, [int]$PlayerIndex) {
    $p = $Game.players[$PlayerIndex]
    $worth = [int]$p.money
    for ($i = 0; $i -lt 40; $i++) {
        $prop = $Game.properties[$i]
        if ($null -ne $prop -and $prop.owner -eq $PlayerIndex) {
            $base = [int]($BOARD[$i].price | ForEach-Object { if ($_ -eq $null) { 0 } else { $_ } })
            $worth += if ($prop.mortgaged) { [math]::Floor($base / 2) } else { $base }
            $worth += [int]($prop.houses) * [int]($BOARD[$i].houseCost | ForEach-Object { if ($_ -eq $null) { 0 } else { $_ } })
        }
    }
    return $worth
}

function Test-GameOver([hashtable]$Game) {
    if (@(Get-ActivePlayers $Game).Count -le 1) { return $true }
    if ($Game.round -gt $MAX_ROUNDS) { return $true }
    return $false
}

function Get-Winner([hashtable]$Game) {
    $active = @(Get-ActivePlayers $Game)
    if ($active.Count -eq 1) { return $active[0] }

    $best = $null
    $bestWorth = -1
    for ($i = 0; $i -lt $Game.players.Count; $i++) {
        $w = Get-NetWorth $Game $i
        if ($w -gt $bestWorth) {
            $bestWorth = $w
            $best = $Game.players[$i]
        }
    }
    return $best
}

function Send-ToJail([hashtable]$Game, [int]$PlayerIndex) {
    $p = $Game.players[$PlayerIndex]
    $p.position = $JAIL_POSITION
    $p.inJail = $true
    $p.jailTurns = 0
    $p.doublesCount = 0
}

function Handle-Bankruptcy([hashtable]$Game, [int]$DebtorIndex, [Nullable[int]]$CreditorIndex) {
    $debtor = $Game.players[$DebtorIndex]
    if ($debtor.bankrupt) { return }

    $debtor.bankrupt = $true
    $cashLeft = [int]$debtor.money
    $debtor.money = 0

    if ($null -ne $CreditorIndex -and $CreditorIndex -ge 0 -and $CreditorIndex -lt $Game.players.Count) {
        $creditor = $Game.players[$CreditorIndex]
        $creditor.money += $cashLeft
        $debtorCards = [int]$debtor.getOutOfJailCards
        $debtor.getOutOfJailCards = 0
        $creditor.getOutOfJailCards += $debtorCards

        # All properties transfer to creditor
        $transferredCount = 0
        for ($i = 0; $i -lt 40; $i++) {
            $prop = $Game.properties[$i]
            if ($null -ne $prop -and $prop.owner -eq $DebtorIndex) {
                # Sell off all houses to Bank at half price first per official rules
                if ([int]$prop.houses -gt 0) {
                    $h = [int]$prop.houses
                    $sellVal = if ($h -eq 5) {
                        [math]::Floor(([int]$BOARD[$i].houseCost * 5) / 2)
                    } else {
                        [math]::Floor(([int]$BOARD[$i].houseCost * $h) / 2)
                    }
                    $creditor.money += $sellVal
                    if ($h -eq 5) { $Game.bankHotels++ } else { $Game.bankHouses += $h }
                    $prop.houses = 0
                }
                $prop.owner = $CreditorIndex
                $transferredCount++
            }
        }
        Add-Event $Game ("{0} is BANKRUPT! Turned over all cash (`${1}) and {2} property(ies) to {3}." -f $debtor.name, $cashLeft, $transferredCount, $creditor.name)
    }
    else {
        # Bankrupted by Bank (taxes or bank fines)
        for ($i = 0; $i -lt 40; $i++) {
            $prop = $Game.properties[$i]
            if ($null -ne $prop -and $prop.owner -eq $DebtorIndex) {
                if ([int]$prop.houses -gt 0) {
                    $h = [int]$prop.houses
                    if ($h -eq 5) { $Game.bankHotels++ } else { $Game.bankHouses += $h }
                }
                $Game.properties[$i] = $null # Returned to bank unowned
            }
        }
        Add-Event $Game ("{0} is BANKRUPT to the Bank! Properties returned to Bank." -f $debtor.name)
    }
}

function Check-Bankruptcy([hashtable]$Game, [int]$PlayerIndex) {
    $p = $Game.players[$PlayerIndex]
    if ($p.money -le 0 -and -not $p.bankrupt) {
        Handle-Bankruptcy $Game $PlayerIndex $null
    }
}

function Count-OwnedRailroads([hashtable]$Game, [int]$PlayerIndex) {
    @($RAILROAD_POSITIONS | Where-Object {
        $prop = $Game.properties[$_]
        $null -ne $prop -and $prop.owner -eq $PlayerIndex
    }).Count
}

function Count-OwnedUtilities([hashtable]$Game, [int]$PlayerIndex) {
    @($UTILITY_POSITIONS | Where-Object {
        $prop = $Game.properties[$_]
        $null -ne $prop -and $prop.owner -eq $PlayerIndex
    }).Count
}

function Test-Monopoly([hashtable]$Game, [int]$PlayerIndex, [string]$Color) {
    if (-not $COLOR_GROUPS.Contains($Color)) { return $false }
    $group = $COLOR_GROUPS[$Color]
    foreach ($pos in $group) {
        $prop = $Game.properties[$pos]
        if ($null -eq $prop -or $prop.owner -ne $PlayerIndex) { return $false }
    }
    return $true
}

function Get-MonopolyColors([hashtable]$Game, [int]$PlayerIndex) {
    $colors = @()
    foreach ($k in $COLOR_GROUPS.Keys) {
        if (Test-Monopoly $Game $PlayerIndex $k) { $colors += $k }
    }
    return @($colors)
}

function Get-PropertyRent([hashtable]$Game, [int]$SquareIndex, [int]$DiceTotal, [bool]$DoubleRailroad = $false, [bool]$TenTimesDice = $false) {
    $sq = $BOARD[$SquareIndex]
    $prop = $Game.properties[$SquareIndex]
    if ($null -eq $prop) { return 0 }

    $owner = [int]$prop.owner

    if ($sq.type -eq 'railroad') {
        if ($prop.mortgaged) { return 0 }
        $owned = Count-OwnedRailroads $Game $owner
        $baseRent = [int](25 * [math]::Pow(2, $owned - 1))
        if ($DoubleRailroad) { return $baseRent * 2 } else { return $baseRent }
    }

    if ($sq.type -eq 'utility') {
        if ($prop.mortgaged) { return 0 }
        if ($TenTimesDice) { return $DiceTotal * 10 }
        $owned = Count-OwnedUtilities $Game $owner
        $multiplier = if ($owned -ge 2) { 10 } else { 4 }
        return $DiceTotal * $multiplier
    }

    if ($sq.type -eq 'property') {
        if ($prop.mortgaged) { return 0 }
        $houses = [int]$prop.houses
        if ($houses -gt 0) { return [int]$sq.rent[$houses] }
        if (Test-Monopoly $Game $owner $sq.color) { return [int]$sq.rent[0] * 2 }
        return [int]$sq.rent[0]
    }

    return 0
}

function Get-MortgageValue([int]$SquareIndex) {
    $sq = $BOARD[$SquareIndex]
    if ($null -eq $sq.price) { return 0 }
    return [int][math]::Floor($sq.price / 2)
}

function Get-UnmortgageCost([int]$SquareIndex) {
    # Official rules: Pay mortgage principal back + 10% interest
    [int][math]::Ceiling((Get-MortgageValue $SquareIndex) * 1.1)
}

function Test-CanMortgageSquare([hashtable]$Game, [int]$PlayerIndex, [int]$SquareIndex) {
    $sq = $BOARD[$SquareIndex]
    $prop = $Game.properties[$SquareIndex]

    if ($null -eq $prop -or $prop.owner -ne $PlayerIndex) { return $false }
    if (@('property', 'railroad', 'utility') -notcontains $sq.type) { return $false }
    if ([int]$prop.houses -gt 0) { return $false }
    if ($prop.mortgaged) { return $false }

    if ($sq.type -eq 'property' -and $null -ne $sq.color -and $COLOR_GROUPS.Contains($sq.color)) {
        foreach ($pos in $COLOR_GROUPS[$sq.color]) {
            $gp = $Game.properties[$pos]
            if ($null -ne $gp -and $gp.owner -eq $PlayerIndex -and [int]$gp.houses -gt 0) {
                return $false
            }
        }
    }

    return $true
}

function Test-CanUnmortgageSquare([hashtable]$Game, [int]$PlayerIndex, [int]$SquareIndex) {
    $prop = $Game.properties[$SquareIndex]
    if ($null -eq $prop -or $prop.owner -ne $PlayerIndex -or -not $prop.mortgaged) { return $false }
    return ([int]$Game.players[$PlayerIndex].money -ge (Get-UnmortgageCost $SquareIndex))
}

function Get-MortgageableSquares([hashtable]$Game, [int]$PlayerIndex) {
    $out = @()
    for ($i = 0; $i -lt 40; $i++) {
        if (Test-CanMortgageSquare $Game $PlayerIndex $i) { $out += $i }
    }
    return @($out)
}

function Get-UnmortgageableSquares([hashtable]$Game, [int]$PlayerIndex) {
    $out = @()
    for ($i = 0; $i -lt 40; $i++) {
        if (Test-CanUnmortgageSquare $Game $PlayerIndex $i) { $out += $i }
    }
    return @($out)
}

function Invoke-MortgageSquare([hashtable]$Game, [int]$PlayerIndex, [int]$SquareIndex) {
    if (-not (Test-CanMortgageSquare $Game $PlayerIndex $SquareIndex)) {
        Add-Event $Game 'Mortgage failed: not allowed.'
        return $false
    }

    $value = Get-MortgageValue $SquareIndex
    $Game.properties[$SquareIndex].mortgaged = $true
    $Game.players[$PlayerIndex].money += $value
    Add-Event $Game ("{0} mortgaged {1} for `${2}." -f $Game.players[$PlayerIndex].name, $BOARD[$SquareIndex].name, $value)
    return $true
}

function Invoke-UnmortgageSquare([hashtable]$Game, [int]$PlayerIndex, [int]$SquareIndex) {
    if (-not (Test-CanUnmortgageSquare $Game $PlayerIndex $SquareIndex)) {
        Add-Event $Game 'Unmortgage failed: not allowed.'
        return $false
    }

    $cost = Get-UnmortgageCost $SquareIndex
    $Game.players[$PlayerIndex].money -= $cost
    $Game.properties[$SquareIndex].mortgaged = $false
    Add-Event $Game ("{0} unmortgaged {1} for `${2}." -f $Game.players[$PlayerIndex].name, $BOARD[$SquareIndex].name, $cost)
    return $true
}

function Get-BuildableSquares([hashtable]$Game, [int]$PlayerIndex) {
    $buildable = @()
    foreach ($color in (Get-MonopolyColors $Game $PlayerIndex)) {
        $group = $COLOR_GROUPS[$color]

        $isGroupMortgaged = $false
        foreach ($pos in $group) {
            $gp = $Game.properties[$pos]
            if ($null -ne $gp -and $gp.owner -eq $PlayerIndex -and $gp.mortgaged) {
                $isGroupMortgaged = $true
                break
            }
        }
        if ($isGroupMortgaged) { continue }

        $houseCounts = @()
        foreach ($pos in $group) {
            $houseCounts += [int]$Game.properties[$pos].houses
        }
        $min = ($houseCounts | Measure-Object -Minimum).Minimum
        $cost = [int]$BOARD[$group[0]].houseCost

        for ($i = 0; $i -lt $group.Count; $i++) {
            $pos = $group[$i]
            $h = [int]$houseCounts[$i]
            if ($h -eq $min -and $h -lt 5 -and $Game.players[$PlayerIndex].money -ge $cost) {
                # Supply check: If upgrading to hotel (4 -> 5), need bank hotels > 0.
                # If building a house (< 4), need bank houses > 0.
                if ($h -eq 4 -and $Game.bankHotels -le 0) { continue }
                if ($h -lt 4 -and $Game.bankHouses -le 0) { continue }
                $buildable += $pos
            }
        }
    }
    return @($buildable)
}

function Build-House([hashtable]$Game, [int]$PlayerIndex, [int]$SquareIndex) {
    $sq = $BOARD[$SquareIndex]
    $prop = $Game.properties[$SquareIndex]
    if ($null -eq $prop -or $prop.owner -ne $PlayerIndex) { return $false }
    if ($null -eq $sq.houseCost) { return $false }

    $houses = [int]$prop.houses
    if ($houses -ge 5) { return $false }
    if ($Game.players[$PlayerIndex].money -lt [int]$sq.houseCost) { return $false }

    # Bank supply check
    if ($houses -eq 4) {
        if ($Game.bankHotels -le 0) { return $false }
    }
    else {
        if ($Game.bankHouses -le 0) { return $false }
    }

    $group = $COLOR_GROUPS[$sq.color]
    $min = ($group | ForEach-Object { [int]$Game.properties[$_].houses } | Measure-Object -Minimum).Minimum
    if ($houses -gt $min) { return $false }

    $Game.players[$PlayerIndex].money -= [int]$sq.houseCost
    if ($houses -eq 4) {
        $Game.bankHotels--
        $Game.bankHouses += 4 # 4 houses returned to the bank when hotel built
    }
    else {
        $Game.bankHouses--
    }

    $Game.properties[$SquareIndex].houses = $houses + 1
    return $true
}

function Test-IsTradableSquare([hashtable]$Game, [int]$SquareIndex, [int]$OwnerIndex) {
    if ($SquareIndex -lt 0 -or $SquareIndex -ge 40) { return $false }
    $sq = $BOARD[$SquareIndex]
    if (@('property', 'railroad', 'utility') -notcontains $sq.type) { return $false }
    $prop = $Game.properties[$SquareIndex]
    if ($null -eq $prop -or $prop.owner -ne $OwnerIndex) { return $false }
    if ([int]$prop.houses -gt 0) { return $false }
    if ($prop.mortgaged) { return $false }
    return $true
}

function Get-TradableOwnedSquares([hashtable]$Game, [int]$PlayerIndex) {
    $out = @()
    for ($i = 0; $i -lt 40; $i++) {
        if (Test-IsTradableSquare $Game $i $PlayerIndex) { $out += $i }
    }
    return @($out)
}

function Get-SquareMarketValue([int]$SquareIndex) {
    $sq = $BOARD[$SquareIndex]
    if ($null -eq $sq.price) { return 0 }

    if ($sq.type -eq 'railroad') { return [int]$sq.price + 40 }
    if ($sq.type -eq 'utility') { return [int]$sq.price + 20 }
    if ($sq.type -eq 'property') {
        $baseRent = [int]$sq.rent[0]
        return [int]$sq.price + ($baseRent * 8)
    }
    return [int]$sq.price
}

function Get-ScorePlayerPosition([hashtable]$Game, [int]$PlayerIndex) {
    $p = $Game.players[$PlayerIndex]
    if ($null -eq $p -or $p.bankrupt) { return 0 }

    $score = [int]$p.money
    for ($i = 0; $i -lt 40; $i++) {
        $prop = $Game.properties[$i]
        if ($null -eq $prop -or $prop.owner -ne $PlayerIndex) { continue }

        $sq = $BOARD[$i]
        $score += if ($prop.mortgaged) { [math]::Floor((Get-SquareMarketValue $i) * 0.45) } else { Get-SquareMarketValue $i }

        if ($sq.type -eq 'railroad') {
            $rr = Count-OwnedRailroads $Game $PlayerIndex
            $score += $rr * 70
            continue
        }

        if ($sq.type -eq 'utility') {
            $ut = Count-OwnedUtilities $Game $PlayerIndex
            $score += if ($ut -ge 2) { 120 } else { 35 }
            continue
        }

        if ($sq.type -eq 'property') {
            $group = $COLOR_GROUPS[$sq.color]
            $owned = @($group | Where-Object {
                $gp = $Game.properties[$_]
                $null -ne $gp -and $gp.owner -eq $PlayerIndex
            }).Count
            $size = if ($group.Count -eq 0) { 1 } else { $group.Count }

            if ($owned -eq $size) { $score += 260 }
            elseif ($owned -eq ($size - 1)) { $score += 120 }
            else { $score += ($owned * 20) }

            $houses = [int]$prop.houses
            if ($houses -gt 0) {
                $score += $houses * [int]$sq.houseCost * 1.5
                $score += [int]$sq.rent[$houses] * 3
            }
        }
    }

    return [int]$score
}

function Get-SuggestedTradeCash([int[]]$OfferSquares, [int[]]$RequestSquares) {
    $offeredValue = ($OfferSquares | ForEach-Object { Get-SquareMarketValue $_ } | Measure-Object -Sum).Sum
    $requestedValue = ($RequestSquares | ForEach-Object { Get-SquareMarketValue $_ } | Measure-Object -Sum).Sum
    return [int]$requestedValue - [int]$offeredValue
}

function Invoke-ExecuteTrade(
    [hashtable]$Game,
    [int]$FromIndex,
    [int]$ToIndex,
    [int[]]$OfferSquares,
    [int[]]$RequestSquares,
    [Nullable[int]]$ExplicitCashFromFromToTo
) {
    if ($FromIndex -eq $ToIndex) { return @{ ok = $false; message = 'Cannot trade with the same player.' } }

    $from = $Game.players[$FromIndex]
    $to = $Game.players[$ToIndex]
    if ($null -eq $from -or $null -eq $to -or $from.bankrupt -or $to.bankrupt) {
        return @{ ok = $false; message = 'One of the players cannot trade now.' }
    }

    $offerSquares = @($OfferSquares | Where-Object { $_ -ge 0 -and $_ -lt 40 } | Select-Object -Unique)
    $requestSquares = @($RequestSquares | Where-Object { $_ -ge 0 -and $_ -lt 40 } | Select-Object -Unique)
    if ($offerSquares.Count -eq 0 -or $requestSquares.Count -eq 0) {
        return @{ ok = $false; message = 'Choose at least one property on both sides.' }
    }

    foreach ($pos in $offerSquares) {
        if (-not (Test-IsTradableSquare $Game $pos $FromIndex)) {
            return @{ ok = $false; message = 'One offered property is not tradable.' }
        }
    }
    foreach ($pos in $requestSquares) {
        if (-not (Test-IsTradableSquare $Game $pos $ToIndex)) {
            return @{ ok = $false; message = 'One requested property is not tradable.' }
        }
    }

    $cash = if ($null -ne $ExplicitCashFromFromToTo) { [int]$ExplicitCashFromFromToTo } else { Get-SuggestedTradeCash $offerSquares $requestSquares }

    $fromAfter = [int]$from.money - $cash
    $toAfter = [int]$to.money + $cash
    if ($fromAfter -lt 0 -or $toAfter -lt 0) {
        return @{ ok = $false; message = 'Trade failed due to insufficient cash.' }
    }

    $clone = Clone-Game $Game
    foreach ($pos in $offerSquares) { $clone.properties[$pos].owner = $ToIndex }
    foreach ($pos in $requestSquares) { $clone.properties[$pos].owner = $FromIndex }
    $clone.players[$FromIndex].money -= $cash
    $clone.players[$ToIndex].money += $cash

    $fromDelta = (Get-ScorePlayerPosition $clone $FromIndex) - (Get-ScorePlayerPosition $Game $FromIndex)
    $toDelta = (Get-ScorePlayerPosition $clone $ToIndex) - (Get-ScorePlayerPosition $Game $ToIndex)

    if ($ToIndex -ne 0) {
        $minCpuGain = 12
        $cpuReserve = 120
        if ($toDelta -lt $minCpuGain -or $toAfter -lt $cpuReserve) {
            return @{ ok = $false; message = ("{0} rejected the trade as unfavorable." -f $to.name) }
        }
    }

    if ($FromIndex -eq 0 -and $fromDelta -lt -60) {
        return @{ ok = $false; message = 'Trade would hurt your position too much.' }
    }

    foreach ($pos in $offerSquares) { $Game.properties[$pos].owner = $ToIndex }
    foreach ($pos in $requestSquares) { $Game.properties[$pos].owner = $FromIndex }
    $Game.players[$FromIndex].money = $fromAfter
    $Game.players[$ToIndex].money = $toAfter

    $offerName = ($offerSquares | ForEach-Object { $BOARD[$_].name }) -join ', '
    $requestName = ($requestSquares | ForEach-Object { $BOARD[$_].name }) -join ', '
    $cashLine = if ($cash -eq 0) {
        'with no cash adjustment'
    }
    elseif ($cash -gt 0) {
        ("with `${0} paid by {1}" -f $cash, $from.name)
    }
    else {
        ("with `${0} paid by {1}" -f ([math]::Abs($cash)), $to.name)
    }

    Add-Event $Game ("Trade completed: {0} traded {1} for {2} {3}." -f $from.name, $offerName, $requestName, $cashLine)
    return @{ ok = $true; fromDelta = $fromDelta; toDelta = $toDelta; cash = $cash }
}

function Pay-ToBank([hashtable]$Game, [int]$PlayerIndex, [int]$Amount, [string]$Note) {
    $player = $Game.players[$PlayerIndex]
    $actual = [math]::Min($Amount, [int]$player.money)
    $player.money -= $actual
    if ($Note) { Add-Event $Game $Note }
    if ($player.money -le 0 -and $actual -lt $Amount) {
        Handle-Bankruptcy $Game $PlayerIndex $null
    }
    return $actual
}

function Pay-Rent([hashtable]$Game, [int]$PayerIndex, [int]$OwnerIndex, [int]$Amount) {
    $payer = $Game.players[$PayerIndex]
    $owner = $Game.players[$OwnerIndex]
    $actual = [math]::Min($Amount, [int]$payer.money)
    $payer.money -= $actual
    $owner.money += $actual
    Add-Event $Game ("{0} paid `${1} rent to {2}." -f $payer.name, $actual, $owner.name)
    if ($payer.money -le 0 -and $actual -lt $Amount) {
        Handle-Bankruptcy $Game $PayerIndex $OwnerIndex
    }
}

# ---------------- Official Property Auction ----------------

function Invoke-PropertyAuction([hashtable]$Game, [int]$SquareIndex, [bool]$Interactive = $true) {
    $sq = $BOARD[$SquareIndex]
    Add-Event $Game ("AUCTION: {0} (Face value: `${1}) is up for auction!" -f $sq.name, $sq.price)

    $activePlayers = @(Get-ActivePlayers $Game)
    if ($activePlayers.Count -eq 0) { return }

    $highBid = 0
    $highBidder = $null
    $passed = @{}

    # AI valuation for auction
    $maxBids = @{}
    for ($i = 0; $i -lt $Game.players.Count; $i++) {
        $p = $Game.players[$i]
        if ($p.bankrupt) {
            $passed[$i] = $true
            continue
        }
        if ($i -eq 0) {
            $maxBids[0] = [int]$p.money
        }
        else {
            # CPU max bid strategy: up to property base price or 85% of market value, capped at money - reserve ($80)
            $valuation = [math]::Floor((Get-SquareMarketValue $SquareIndex) * 0.85)
            $spendable = [math]::Max(0, [int]$p.money - 80)
            $maxBids[$i] = [math]::Min($valuation, $spendable)
        }
    }

    $auctionActive = $true
    $round = 1

    while ($auctionActive -and $round -le 20) {
        $activeBidders = 0
        for ($i = 0; $i -lt $Game.players.Count; $i++) {
            if ($passed.ContainsKey($i) -and $passed[$i]) { continue }
            $p = $Game.players[$i]
            if ($p.bankrupt -or $p.money -le $highBid) {
                $passed[$i] = $true
                continue
            }
            $activeBidders++

            if ($i -eq 0 -and $Interactive) {
                Write-Host ''
                Write-Host ("AUCTION: {0} | High bid: `${1} ({2})" -f $sq.name, $highBid, (if ($null -ne $highBidder) { $highBidder.name } else { 'None' })) -ForegroundColor Yellow
                Write-Host ("Your money: `${0}" -f $p.money) -ForegroundColor Cyan
                $choice = (Read-Host "Enter bid (min `$$($highBid + 10)) or 'p' to pass").Trim().ToLowerInvariant()
                if ($choice -eq 'p' -or $choice -eq '') {
                    $passed[0] = $true
                    Add-Event $Game 'You passed in the auction.'
                }
                else {
                    $bidVal = 0
                    if ([int]::TryParse($choice, [ref]$bidVal) -and $bidVal -gt $highBid -and $bidVal -le $p.money) {
                        $highBid = $bidVal
                        $highBidder = $p
                        Add-Event $Game ("You bid `${0} on {1}." -f $highBid, $sq.name)
                    }
                    else {
                        Write-Host 'Invalid bid amount or insufficient cash. Passing.' -ForegroundColor Red
                        $passed[0] = $true
                    }
                }
            }
            else {
                # CPU bidding logic
                $targetMax = [int]$maxBids[$i]
                $minRaise = if ($highBid -eq 0) { 10 } else { $highBid + 10 }
                if ($targetMax -ge $minRaise -and $p.money -ge $minRaise) {
                    $highBid = $minRaise
                    $highBidder = $p
                    Add-Event $Game ("{0} bid `${1}." -f $p.name, $highBid)
                }
                else {
                    $passed[$i] = $true
                }
            }
        }

        # Check if only one or zero bidders remain
        $remaining = @(Get-ActivePlayers $Game | Where-Object { -not ($passed.ContainsKey($Game.players.IndexOf($_)) -and $passed[$Game.players.IndexOf($_)]) })
        if ($remaining.Count -le 1 -and $highBid -gt 0) {
            break
        }
        if ($remaining.Count -eq 0) {
            break
        }
        $round++
    }

    if ($null -ne $highBidder -and $highBid -gt 0) {
        $highBidderIdx = $Game.players.IndexOf($highBidder)
        $highBidder.money -= $highBid
        $Game.properties[$SquareIndex] = [ordered]@{ owner = $highBidderIdx; houses = 0; mortgaged = $false }
        Add-Event $Game ("AUCTION WON: {0} won {1} for `${2}!" -f $highBidder.name, $sq.name, $highBid)
    }
    else {
        Add-Event $Game ("AUCTION ENDED: No bids on {0}. It remains unowned." -f $sq.name)
    }
}

# ---------------- Deck Draw Actions ----------------

function Draw-CommunityChest([hashtable]$Game, [int]$PlayerIndex) {
    $p = $Game.players[$PlayerIndex]
    if ($Game.chestDeck.Count -eq 0) {
        $Game.chestDeck = [System.Collections.Generic.List[hashtable]](Get-StandardCommunityChestDeck)
    }

    $card = $Game.chestDeck[0]
    $Game.chestDeck.RemoveAt(0)
    # Put back on bottom unless it's Keep card (jail free)
    if ($card.action -ne 'jail_free') {
        $Game.chestDeck.Add($card)
    }

    Add-Event $Game ("Community Chest: {0}" -f $card.text)

    switch ($card.action) {
        'advance_go' {
            $p.position = 0
            $p.money += $GO_SALARY
        }
        'bank_error' { $p.money += 200 }
        'doctor_fee' { [void](Pay-ToBank $Game $PlayerIndex 50 $null) }
        'stock_sale' { $p.money += 50 }
        'jail_free' { $p.getOutOfJailCards++ }
        'goto_jail' { Send-ToJail $Game $PlayerIndex }
        'holiday_fund' { $p.money += 100 }
        'tax_refund' { $p.money += 20 }
        'birthday' {
            $total = 0
            for ($i = 0; $i -lt $Game.players.Count; $i++) {
                if ($i -ne $PlayerIndex -and -not $Game.players[$i].bankrupt) {
                    $amt = [math]::Min(10, [int]$Game.players[$i].money)
                    $Game.players[$i].money -= $amt
                    $total += $amt
                }
            }
            $p.money += $total
        }
        'life_insurance' { $p.money += 100 }
        'hospital_fee' { [void](Pay-ToBank $Game $PlayerIndex 100 $null) }
        'school_fee' { [void](Pay-ToBank $Game $PlayerIndex 50 $null) }
        'consultancy_fee' { $p.money += 25 }
        'street_repairs' {
            $cost = 0
            for ($i = 0; $i -lt 40; $i++) {
                $prop = $Game.properties[$i]
                if ($null -ne $prop -and $prop.owner -eq $PlayerIndex) {
                    $h = [int]$prop.houses
                    $cost += if ($h -eq 5) { 115 } else { $h * 40 }
                }
            }
            if ($cost -gt 0) { [void](Pay-ToBank $Game $PlayerIndex $cost $null) }
        }
        'beauty_contest' { $p.money += 10 }
        'inherit' { $p.money += 100 }
    }
}

function Draw-Chance([hashtable]$Game, [int]$PlayerIndex, [int]$DiceTotal, [bool]$Interactive = $true) {
    $p = $Game.players[$PlayerIndex]
    $pos = [int]$p.position
    $pendingBuy = $false

    if ($Game.chanceDeck.Count -eq 0) {
        $Game.chanceDeck = [System.Collections.Generic.List[hashtable]](Get-StandardChanceDeck)
    }

    $card = $Game.chanceDeck[0]
    $Game.chanceDeck.RemoveAt(0)
    if ($card.action -ne 'jail_free') {
        $Game.chanceDeck.Add($card)
    }

    Add-Event $Game ("Chance: {0}" -f $card.text)

    function Move-To([int]$Target, [bool]$DoubleRailroad = $false, [bool]$TenTimesDice = $false) {
        if ($Target -lt $pos) {
            $p.money += $GO_SALARY
            Add-Event $Game ("{0} passed GO and collected `${1}." -f $p.name, $GO_SALARY)
        }
        $p.position = $Target
        $script:chancePendingBuy = Invoke-LandingEffect $Game $PlayerIndex $Target $DiceTotal $true $DoubleRailroad $TenTimesDice $Interactive
    }

    $script:chancePendingBuy = $false

    switch ($card.action) {
        'advance_go' {
            $p.position = 0
            $p.money += $GO_SALARY
        }
        'advance_illinois' {
            Move-To 24
            $pendingBuy = $script:chancePendingBuy
        }
        'advance_st_charles' {
            Move-To 11
            $pendingBuy = $script:chancePendingBuy
        }
        'advance_utility' {
            $next = if ($pos -ge 12 -and $pos -lt 28) { 28 } else { 12 }
            Move-To $next $false $true
            $pendingBuy = $script:chancePendingBuy
        }
        'advance_railroad' {
            $railroads = @(5, 15, 25, 35)
            $next = ($railroads | Where-Object { $_ -gt $pos } | Select-Object -First 1)
            if ($null -eq $next) { $next = 5 }
            Move-To $next $true $false
            $pendingBuy = $script:chancePendingBuy
        }
        'bank_dividend' { $p.money += 50 }
        'jail_free' { $p.getOutOfJailCards++ }
        'back_3' {
            $newPos = ($pos - 3 + 40) % 40
            $p.position = $newPos
            Add-Event $Game ("{0} moved back 3 spaces to {1}." -f $p.name, $BOARD[$newPos].name)
            $pendingBuy = Invoke-LandingEffect $Game $PlayerIndex $newPos $DiceTotal $true $false $false $Interactive
        }
        'goto_jail' { Send-ToJail $Game $PlayerIndex }
        'general_repairs' {
            $cost = 0
            for ($i = 0; $i -lt 40; $i++) {
                $prop = $Game.properties[$i]
                if ($null -ne $prop -and $prop.owner -eq $PlayerIndex) {
                    $h = [int]$prop.houses
                    $cost += if ($h -eq 5) { 100 } else { $h * 25 }
                }
            }
            if ($cost -gt 0) { [void](Pay-ToBank $Game $PlayerIndex $cost $null) }
        }
        'poor_tax' { [void](Pay-ToBank $Game $PlayerIndex 15 $null) }
        'trip_reading' {
            Move-To 5
            $pendingBuy = $script:chancePendingBuy
        }
        'advance_boardwalk' {
            Move-To 39
            $pendingBuy = $script:chancePendingBuy
        }
        'chairman' {
            for ($i = 0; $i -lt $Game.players.Count; $i++) {
                if ($i -ne $PlayerIndex -and -not $Game.players[$i].bankrupt) {
                    $amt = [math]::Min(50, [int]$p.money)
                    $p.money -= $amt
                    $Game.players[$i].money += $amt
                }
            }
            Check-Bankruptcy $Game $PlayerIndex
        }
        'building_loan' { $p.money += 150 }
    }

    return $pendingBuy
}

# ---------------- Landing Effect ----------------

function Invoke-LandingEffect(
    [hashtable]$Game,
    [int]$PlayerIndex,
    [int]$SquareIndex,
    [int]$DiceTotal,
    [bool]$FromCard = $false,
    [bool]$DoubleRailroad = $false,
    [bool]$TenTimesDice = $false,
    [bool]$Interactive = $true
) {
    $sq = $BOARD[$SquareIndex]
    $p = $Game.players[$PlayerIndex]

    switch ($sq.type) {
        'go' {
            Add-Event $Game ("{0} landed on GO." -f $p.name)
            return $false
        }
        'jail' {
            Add-Event $Game ("{0} is just visiting jail." -f $p.name)
            return $false
        }
        'freeparking' {
            Add-Event $Game ("{0} landed on Free Parking." -f $p.name)
            return $false
        }
        'gotojail' {
            Send-ToJail $Game $PlayerIndex
            Add-Event $Game ("{0} landed on Go To Jail!" -f $p.name)
            return $false
        }
        'tax' {
            [void](Pay-ToBank $Game $PlayerIndex ([int]$sq.amount) ("{0} paid `${1} for {2}." -f $p.name, $sq.amount, $sq.name))
            return $false
        }
        'community_chest' {
            if (-not $FromCard) { Draw-CommunityChest $Game $PlayerIndex }
            return $false
        }
        'chance' {
            if (-not $FromCard) {
                return (Draw-Chance $Game $PlayerIndex $DiceTotal $Interactive)
            }
            return $false
        }
        default {
            if (@('property', 'railroad', 'utility') -contains $sq.type) {
                $prop = $Game.properties[$SquareIndex]

                if ($null -eq $prop) {
                    $canAfford = [int]$p.money -ge [int]$sq.price
                    if ($PlayerIndex -eq 0) {
                        if ($canAfford) {
                            Add-Event $Game ("You landed on unowned {0} (`${1}). Buy or Auction." -f $sq.name, $sq.price)
                            return $true
                        }
                        Add-Event $Game ("You landed on {0} (`${1}) but cannot afford it. Sent to Auction." -f $sq.name, $sq.price)
                        Invoke-PropertyAuction $Game $SquareIndex $Interactive
                        return $false
                    }

                    # CPU landed on unowned property
                    # CPU buys if money left after purchase is >= $100
                    if ($canAfford -and ([int]$p.money - [int]$sq.price -ge 100)) {
                        $Game.properties[$SquareIndex] = [ordered]@{ owner = $PlayerIndex; houses = 0; mortgaged = $false }
                        $p.money -= [int]$sq.price
                        Add-Event $Game ("{0} bought {1} for `${2}." -f $p.name, $sq.name, $sq.price)
                    }
                    else {
                        Add-Event $Game ("{0} passed on buying {1}. Auctioning property!" -f $p.name, $sq.name)
                        Invoke-PropertyAuction $Game $SquareIndex $Interactive
                    }
                    return $false
                }

                if ($prop.owner -eq $PlayerIndex) {
                    Add-Event $Game ("{0} landed on owned property {1}." -f $p.name, $sq.name)
                    return $false
                }

                if ($Game.players[$prop.owner].bankrupt) {
                    Add-Event $Game ("{0} landed on abandoned property {1}." -f $p.name, $sq.name)
                    return $false
                }

                $rent = Get-PropertyRent $Game $SquareIndex $DiceTotal $DoubleRailroad $TenTimesDice
                if ($rent -gt 0) {
                    Pay-Rent $Game $PlayerIndex ([int]$prop.owner) $rent
                }
                return $false
            }

            return $false
        }
    }
}

# ---------------- Turn Resolution ----------------

function Invoke-ProcessHumanRoll([hashtable]$Game, [int]$d1, [int]$d2) {
    $p = $Game.players[0]
    $dice = [ordered]@{ d1 = $d1; d2 = $d2; total = $d1 + $d2; doubles = ($d1 -eq $d2) }
    $Game.lastDice = $dice

    if ($dice.doubles) {
        $p.doublesCount++
        if ($p.doublesCount -ge 3) {
            Send-ToJail $Game 0
            Add-Event $Game ("Speeding! You rolled {0}+{1}={2} (3rd double). Go to jail." -f $d1, $d2, $dice.total)
            $p.doublesCount = 0
            return @{ pendingBuy = $false; wentToJail = $true }
        }
        Add-Event $Game ("You rolled {0}+{1}={2} (doubles)." -f $d1, $d2, $dice.total)
    }
    else {
        $p.doublesCount = 0
        Add-Event $Game ("You rolled {0}+{1}={2}." -f $d1, $d2, $dice.total)
    }

    $oldPos = [int]$p.position
    $newPos = ($oldPos + $dice.total) % 40
    if ($newPos -lt $oldPos -and $dice.total -gt 0) {
        $p.money += $GO_SALARY
        Add-Event $Game ("You passed GO and collected `${0}." -f $GO_SALARY)
    }
    $p.position = $newPos

    Add-Event $Game ("You moved to {0} (space {1})." -f $BOARD[$newPos].name, $newPos)
    $pendingBuy = Invoke-LandingEffect $Game 0 $newPos $dice.total $false $false $false $true
    return @{ pendingBuy = $pendingBuy; wentToJail = $false }
}

function Invoke-ProcessJailRoll([hashtable]$Game, [bool]$PayFine, [bool]$UseCard) {
    $p = $Game.players[0]

    if ($UseCard -and $p.getOutOfJailCards -gt 0) {
        $p.getOutOfJailCards--
        $p.inJail = $false
        $p.jailTurns = 0
        Add-Event $Game 'You used a Get Out of Jail Free card.'
    }
    elseif ($PayFine) {
        [void](Pay-ToBank $Game 0 $JAIL_FINE 'You paid $50 to leave jail.')
        $p.inJail = $false
        $p.jailTurns = 0
        if ($p.bankrupt) {
            return @{ pendingBuy = $false; stayedInJail = $false }
        }
    }
    else {
        $dice = Roll-Dice
        $Game.lastDice = $dice
        $p.jailTurns++
        Add-Event $Game ("You rolled {0}+{1}={2} in jail." -f $dice.d1, $dice.d2, $dice.total)

        if ($dice.doubles) {
            $p.inJail = $false
            $p.jailTurns = 0
            Add-Event $Game 'You rolled doubles and escaped jail!'
        }
        elseif ($p.jailTurns -ge $MAX_JAIL_TURNS) {
            [void](Pay-ToBank $Game 0 $JAIL_FINE 'You served 3 turns and paid $50 fine.')
            $p.inJail = $false
            $p.jailTurns = 0
            if ($p.bankrupt) {
                return @{ pendingBuy = $false; stayedInJail = $false }
            }
        }
        else {
            Add-Event $Game ("You stay in jail ({0}/{1})." -f $p.jailTurns, $MAX_JAIL_TURNS)
            return @{ pendingBuy = $false; stayedInJail = $true }
        }

        $oldPos = [int]$p.position
        $newPos = ($oldPos + $dice.total) % 40
        if ($newPos -lt $oldPos) {
            $p.money += $GO_SALARY
            Add-Event $Game ("You passed GO and collected `${0}." -f $GO_SALARY)
        }
        $p.position = $newPos
        Add-Event $Game ("You moved to {0} (space {1})." -f $BOARD[$newPos].name, $newPos)
        $pendingBuy = Invoke-LandingEffect $Game 0 $newPos $dice.total $false $false $false $true
        return @{ pendingBuy = $pendingBuy; stayedInJail = $false }
    }

    # If escaped via fine or card, roll and advance
    $dice = Roll-Dice
    $Game.lastDice = $dice
    $p.doublesCount = if ($dice.doubles) { 1 } else { 0 }

    Add-Event $Game ("You rolled {0}+{1}={2} after leaving jail." -f $dice.d1, $dice.d2, $dice.total)

    $oldPos = [int]$p.position
    $newPos = ($oldPos + $dice.total) % 40
    if ($newPos -lt $oldPos) {
        $p.money += $GO_SALARY
        Add-Event $Game ("You passed GO and collected `${0}." -f $GO_SALARY)
    }
    $p.position = $newPos
    Add-Event $Game ("You moved to {0} (space {1})." -f $BOARD[$newPos].name, $newPos)
    $pendingBuy = Invoke-LandingEffect $Game 0 $newPos $dice.total $false $false $false $true
    return @{ pendingBuy = $pendingBuy; stayedInJail = $false }
}

function Invoke-RunCpuTurn([hashtable]$Game, [int]$CpuIndex) {
    $p = $Game.players[$CpuIndex]
    if ($p.bankrupt) { return }

    $rollCount = 0
    function Do-CpuRoll {
        if ($script:cpuRollCount -ge 3) { return }
        $script:cpuRollCount++

        if ($p.inJail) {
            if ($p.getOutOfJailCards -gt 0) {
                $p.getOutOfJailCards--
                $p.inJail = $false
                $p.jailTurns = 0
                Add-Event $Game ("{0} used Get Out of Jail Free card." -f $p.name)
            }
            else {
                $dice = Roll-Dice
                $p.jailTurns++
                if ($dice.doubles) {
                    $p.inJail = $false
                    $p.jailTurns = 0
                    Add-Event $Game ("{0} rolled doubles ({1}+{2}) and escaped jail." -f $p.name, $dice.d1, $dice.d2)
                }
                elseif ($p.jailTurns -ge $MAX_JAIL_TURNS) {
                    [void](Pay-ToBank $Game $CpuIndex $JAIL_FINE ("{0} paid `${1} to leave jail." -f $p.name, $JAIL_FINE))
                    $p.inJail = $false
                    $p.jailTurns = 0
                    if ($p.bankrupt) { return }
                }
                else {
                    Add-Event $Game ("{0} stayed in jail ({1}/{2})." -f $p.name, $p.jailTurns, $MAX_JAIL_TURNS)
                    return
                }
            }
        }

        $dice = Roll-Dice
        $doublesSuffix = if ($dice.doubles) { ' (doubles)' } else { '' }
        Add-Event $Game ("{0} rolled {1}+{2}={3}{4}." -f $p.name, $dice.d1, $dice.d2, $dice.total, $doublesSuffix)

        if ($dice.doubles) {
            $p.doublesCount++
            if ($p.doublesCount -ge 3) {
                Send-ToJail $Game $CpuIndex
                Add-Event $Game ("{0} rolled 3 doubles and goes to jail." -f $p.name)
                return
            }
        }
        else {
            $p.doublesCount = 0
        }

        $oldPos = [int]$p.position
        $newPos = ($oldPos + $dice.total) % 40
        if ($newPos -lt $oldPos -or ($oldPos -eq 0 -and $dice.total -gt 0)) {
            if (-not ($oldPos -eq 0 -and $newPos -eq 0)) {
                $p.money += $GO_SALARY
                Add-Event $Game ("{0} passed GO and collected `${1}." -f $p.name, $GO_SALARY)
            }
        }
        $p.position = $newPos
        [void](Invoke-LandingEffect $Game $CpuIndex $newPos $dice.total $false $false $false $false)

        if ($dice.doubles -and -not $p.inJail -and -not $p.bankrupt) {
            Do-CpuRoll
        }
    }

    $script:cpuRollCount = 0
    $p.doublesCount = 0
    Do-CpuRoll

    if (-not $p.bankrupt) {
        # Unmortgage if wealthy
        foreach ($sq in (Get-UnmortgageableSquares $Game $CpuIndex)) {
            if ($p.money -ge 400) {
                [void](Invoke-UnmortgageSquare $Game $CpuIndex $sq)
            }
        }

        # Build houses if possible
        foreach ($sq in (Get-BuildableSquares $Game $CpuIndex)) {
            if (Build-House $Game $CpuIndex $sq) {
                $h = [int]$Game.properties[$sq].houses
                $hName = if ($h -eq 5) { 'a Hotel' } else { "house #$h" }
                Add-Event $Game ("{0} built {1} on {2}." -f $p.name, $hName, $BOARD[$sq].name)
            }
        }
    }
}

function Invoke-TryBestCpuTrade([hashtable]$Game, [int]$CpuIndex) {
    $cpu = $Game.players[$CpuIndex]
    if ($cpu.bankrupt) { return $false }

    $mySquares = @(Get-TradableOwnedSquares $Game $CpuIndex)
    if ($mySquares.Count -eq 0) { return $false }

    $best = $null

    for ($other = 0; $other -lt $Game.players.Count; $other++) {
        if ($other -eq $CpuIndex) { continue }
        $op = $Game.players[$other]
        if ($op.bankrupt) { continue }

        $otherSquares = @(Get-TradableOwnedSquares $Game $other)
        if ($otherSquares.Count -eq 0) { continue }

        foreach ($givePos in $mySquares) {
            foreach ($getPos in $otherSquares) {
                $cash = Get-SuggestedTradeCash @($givePos) @($getPos)
                $cpuAfter = [int]$cpu.money - $cash
                $otherAfter = [int]$op.money + $cash
                if ($cpuAfter -lt 120 -or $otherAfter -lt 80) { continue }

                $clone = Clone-Game $Game
                $clone.properties[$givePos].owner = $other
                $clone.properties[$getPos].owner = $CpuIndex
                $clone.players[$CpuIndex].money -= $cash
                $clone.players[$other].money += $cash

                $fromDelta = (Get-ScorePlayerPosition $clone $CpuIndex) - (Get-ScorePlayerPosition $Game $CpuIndex)
                $toDelta = (Get-ScorePlayerPosition $clone $other) - (Get-ScorePlayerPosition $Game $other)

                if ($fromDelta -lt 25 -or $toDelta -lt 10) { continue }

                if ($null -eq $best -or $fromDelta -gt $best.fromDelta) {
                    $best = @{ other = $other; givePos = $givePos; getPos = $getPos; fromDelta = $fromDelta }
                }
            }
        }
    }

    if ($null -eq $best) { return $false }

    $result = Invoke-ExecuteTrade $Game $CpuIndex $best.other @($best.givePos) @($best.getPos) $null
    if ($result.ok) {
        Add-Event $Game ("{0} negotiated a strong trade." -f $cpu.name)
        return $true
    }

    return $false
}

function Invoke-RunAllCpuTurns([hashtable]$Game) {
    for ($i = 1; $i -lt $Game.players.Count; $i++) {
        if (-not $Game.players[$i].bankrupt) {
            Invoke-RunCpuTurn $Game $i
        }
    }

    for ($i = 1; $i -lt $Game.players.Count; $i++) {
        if (-not $Game.players[$i].bankrupt) {
            [void](Invoke-TryBestCpuTrade $Game $i)
        }
    }
}

function Start-HumanTurn([hashtable]$Game) {
    $p = $Game.players[0]
    if ($p.bankrupt) {
        $Game.phase = 'game_over'
        return
    }
    $p.doublesCount = 0
    $Game.phase = if ($p.inJail) { 'jail_decision' } else { 'roll' }
}

# ---------------- Smoke Test ----------------

function Invoke-SmokeTest {
    try {
        # Test 1 CPU opponent
        $g1 = New-Game 1
        if ($g1.players.Count -ne 2) { throw "Expected 2 players with 1 CPU, got $($g1.players.Count)" }

        # Test 2 CPU opponents
        $g2 = New-Game 2
        if ($g2.players.Count -ne 3) { throw "Expected 3 players with 2 CPUs, got $($g2.players.Count)" }

        # Test standard 3 CPU opponents
        $game = New-Game 3
        if ($game.players.Count -ne 4) { throw "Expected 4 players with 3 CPUs, got $($game.players.Count)" }

        if ($game.bankHouses -ne 32 -or $game.bankHotels -ne 12) {
            throw "Initial bank supply wrong. Houses: $($game.bankHouses), Hotels: $($game.bankHotels)"
        }

        if ($game.phase -ne 'roll') {
            throw "Expected initial phase 'roll', got '$($game.phase)'."
        }

        for ($step = 1; $step -le 8; $step++) {
            if ($game.phase -eq 'game_over') { break }

            if ($game.phase -eq 'roll') {
                $dice = Roll-Dice
                $result = Invoke-ProcessHumanRoll $game $dice.d1 $dice.d2
                Check-Bankruptcy $game 0

                if ($game.players[0].bankrupt -or (Test-GameOver $game)) {
                    $game.phase = 'game_over'
                    continue
                }

                if ($result.pendingBuy) {
                    $game.pendingBuySquare = [int]$game.players[0].position
                    $game.phase = 'buy'
                }
                else {
                    $game.phase = 'endturn'
                }
            }

            if ($game.phase -eq 'jail_decision') {
                $jr = Invoke-ProcessJailRoll $game $false $false
                Check-Bankruptcy $game 0

                if ($game.players[0].bankrupt -or (Test-GameOver $game)) {
                    $game.phase = 'game_over'
                }
                elseif ($jr.pendingBuy) {
                    $game.pendingBuySquare = [int]$game.players[0].position
                    $game.phase = 'buy'
                }
                else {
                    $game.phase = 'endturn'
                }
            }

            if ($game.phase -eq 'buy') {
                if ($null -eq $game.pendingBuySquare) {
                    throw 'Buy phase reached without pendingBuySquare.'
                }

                # Smoke test exercises auction fallback on pass
                Invoke-PropertyAuction $game ([int]$game.pendingBuySquare) $false
                $game.pendingBuySquare = $null
                $game.phase = 'endturn'
            }

            if ($game.phase -eq 'endturn') {
                Invoke-RunAllCpuTurns $game
                $game.round++

                if (Test-GameOver $game) {
                    $game.phase = 'game_over'
                }
                else {
                    Start-HumanTurn $game
                }
            }
        }

        if ($game.round -lt 2 -and $game.phase -ne 'game_over') {
            throw "Smoke test did not advance rounds as expected (round=$($game.round))."
        }

        Write-Host ("Smoke test passed. Round={0}, Phase={1}, Players={2}" -f $game.round, $game.phase, $game.players.Count) -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host ("Smoke test failed: {0}" -f $_.Exception.Message) -ForegroundColor Red
        return $false
    }
}

# ---------------- UI helpers ----------------

function Show-RecentEvents([hashtable]$Game) {
    Write-Host ''
    Write-Host 'Recent events:' -ForegroundColor Cyan
    foreach ($line in $Game.events) {
        Write-Host ("  - {0}" -f $line)
    }
}

function Show-PlayerSummary([hashtable]$Game) {
    Write-Host ''
    $supply = "Bank Houses: $($Game.bankHouses)/$TOTAL_BANK_HOUSES | Hotels: $($Game.bankHotels)/$TOTAL_BANK_HOTELS"
    Write-Host ("Round {0}/{1} | Phase: {2} | {3}" -f $Game.round, $MAX_ROUNDS, $Game.phase, $supply) -ForegroundColor Yellow
    for ($i = 0; $i -lt $Game.players.Count; $i++) {
        $p = $Game.players[$i]
        $pos = $BOARD[[int]$p.position].name
        $state = if ($p.bankrupt) { 'BANKRUPT' } elseif ($p.inJail) { ("JAIL({0})" -f $p.jailTurns) } else { 'ACTIVE' }
        $worth = Get-NetWorth $Game $i
        $jailCards = if ($p.getOutOfJailCards -gt 0) { " [GOOJ: $($p.getOutOfJailCards)]" } else { '' }
        Write-Host ("[{0}] {1,-8} ({2,-6}) Money:`${3,-5} Net:`${4,-5} Pos:{5,-22} {6}{7}" -f $i, $p.name, $p.token, $p.money, $worth, $pos, $state, $jailCards)
    }
}

function Show-OwnedProperties([hashtable]$Game, [int]$PlayerIndex) {
    $lines = @()
    for ($i = 0; $i -lt 40; $i++) {
        $prop = $Game.properties[$i]
        if ($null -ne $prop -and $prop.owner -eq $PlayerIndex) {
            $sq = $BOARD[$i]
            $h = [int]$prop.houses
            $housesText = if ($h -eq 0) { '' } elseif ($h -eq 5) { ' [HOTEL]' } else { (" [{0}H]" -f $h) }
            $mort = if ($prop.mortgaged) { ' [MORTGAGED]' } else { '' }
            $colorTag = if ($null -ne $sq.color) { "($($sq.color)) " } else { '' }
            $lines += ("{0,2}: {1,-22} {2}{3}{4}" -f $i, $sq.name, $colorTag, $housesText, $mort)
        }
    }

    if ($lines.Count -eq 0) {
        Write-Host '  (none)'
    }
    else {
        foreach ($line in $lines) { Write-Host ("  {0}" -f $line) }
    }
}

function Show-BoardOverview([hashtable]$Game) {
    Write-Host ''
    Write-Host '--- BOARD OVERVIEW ---' -ForegroundColor Magenta
    for ($i = 0; $i -lt 40; $i++) {
        $sq = $BOARD[$i]
        $prop = $Game.properties[$i]
        $ownerText = 'Unowned'
        $detail = ''
        if ($null -ne $prop) {
            $ownerName = $Game.players[$prop.owner].name
            $h = [int]$prop.houses
            $hText = if ($h -eq 5) { ' [HOTEL]' } elseif ($h -gt 0) { " [${h}H]" } else { '' }
            $mText = if ($prop.mortgaged) { ' [MORT]' } else { '' }
            $ownerText = "$ownerName$hText$mText"
        }
        elseif ($sq.type -in @('property', 'railroad', 'utility')) {
            $ownerText = "`$$($sq.price)"
        }
        else {
            $ownerText = '-'
        }

        # Player tokens present
        $present = @()
        for ($pIdx = 0; $pIdx -lt $Game.players.Count; $pIdx++) {
            $pl = $Game.players[$pIdx]
            if (-not $pl.bankrupt -and [int]$pl.position -eq $i) {
                $present += $pl.token
            }
        }
        $playersAtPos = if ($present.Count -gt 0) { " <-- (" + ($present -join ', ') + ")" } else { "" }

        if ($sq.type -in @('property', 'railroad', 'utility')) {
            Write-Host ("[{0,2}] {1,-24} | {2,-20}{3}" -f $i, $sq.name, $ownerText, $playersAtPos)
        }
    }
}

function Read-Choice([string]$Prompt, [string[]]$Allowed) {
    while ($true) {
        $inputValue = (Read-Host $Prompt).Trim().ToLowerInvariant()
        if ($Allowed -contains $inputValue) { return $inputValue }
        Write-Host ("Please enter one of: {0}" -f ($Allowed -join ', ')) -ForegroundColor DarkYellow
    }
}

function Read-IntOrNull([string]$Prompt) {
    $raw = (Read-Host $Prompt).Trim()
    if ($raw -eq '') { return $null }
    $n = 0
    if ([int]::TryParse($raw, [ref]$n)) { return $n }
    return $null
}

function Read-IntArray([string]$Prompt) {
    $raw = (Read-Host $Prompt).Trim()
    if ([string]::IsNullOrWhiteSpace($raw)) { return @() }

    $list = @()
    foreach ($part in ($raw -split ',')) {
        $t = $part.Trim()
        $n = 0
        if ([int]::TryParse($t, [ref]$n)) { $list += $n }
    }

    return @($list | Select-Object -Unique)
}

function Invoke-HumanBuildMenu([hashtable]$Game) {
    $buildable = @(Get-BuildableSquares $Game 0)
    if ($buildable.Count -eq 0) {
        Add-Event $Game 'No build options available (requires full unmortgaged monopoly and bank supply).'
        return
    }

    Write-Host ''
    Write-Host ("Buildable properties (Bank Houses: {0}, Hotels: {1}):" -f $Game.bankHouses, $Game.bankHotels) -ForegroundColor Cyan
    foreach ($pos in $buildable) {
        $sq = $BOARD[$pos]
        $h = [int]$Game.properties[$pos].houses
        $next = if ($h -eq 4) { 'HOTEL' } else { ("{0} Houses" -f ($h + 1)) }
        Write-Host ("  {0,2}: {1,-20} -> {2,-10} (cost `${3})" -f $pos, $sq.name, $next, $sq.houseCost)
    }

    $pick = Read-IntOrNull 'Enter square index to build (blank to cancel)'
    if ($null -eq $pick) { return }

    if (Build-House $Game 0 $pick) {
        $sq = $BOARD[$pick]
        $h = [int]$Game.properties[$pick].houses
        $hName = if ($h -eq 5) { 'Hotel' } else { "$h house(s)" }
        Add-Event $Game ("You built on {0}. Current status: {1}." -f $sq.name, $hName)
    }
    else {
        Add-Event $Game 'Build failed (check bank supply or even building rule).'
    }
}

function Invoke-HumanMortgageMenu([hashtable]$Game) {
    $mortgageable = @(Get-MortgageableSquares $Game 0)
    $unmortgageable = @(Get-UnmortgageableSquares $Game 0)

    if ($mortgageable.Count -eq 0 -and $unmortgageable.Count -eq 0) {
        Add-Event $Game 'No mortgage actions available.'
        return
    }

    Write-Host ''
    Write-Host 'Mortgage options:' -ForegroundColor Cyan
    foreach ($pos in $mortgageable) {
        Write-Host ("  m:{0} Mortgage {1} (+`${2})" -f $pos, $BOARD[$pos].name, (Get-MortgageValue $pos))
    }
    foreach ($pos in $unmortgageable) {
        Write-Host ("  u:{0} Unmortgage {1} (-`${2} [10% interest])" -f $pos, $BOARD[$pos].name, (Get-UnmortgageCost $pos))
    }

    $raw = (Read-Host 'Choose action (example m:12, u:5, blank to cancel)').Trim().ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace($raw)) { return }

    $parts = $raw -split ':'
    if ($parts.Count -ne 2) {
        Add-Event $Game 'Invalid mortgage input.'
        return
    }

    $action = $parts[0]
    $n = 0
    if (-not [int]::TryParse($parts[1], [ref]$n)) {
        Add-Event $Game 'Invalid square index.'
        return
    }

    if ($action -eq 'm') {
        [void](Invoke-MortgageSquare $Game 0 $n)
    }
    elseif ($action -eq 'u') {
        [void](Invoke-UnmortgageSquare $Game 0 $n)
    }
    else {
        Add-Event $Game 'Unknown mortgage action.'
    }
}

function Invoke-HumanTradeMenu([hashtable]$Game) {
    $myTradable = @(Get-TradableOwnedSquares $Game 0)
    if ($myTradable.Count -eq 0) {
        Add-Event $Game 'You have no tradable properties (mortgaged/improved not tradable).'
        return
    }

    $partners = @()
    for ($i = 1; $i -lt $Game.players.Count; $i++) {
        if ($Game.players[$i].bankrupt) { continue }
        $tradable = @(Get-TradableOwnedSquares $Game $i)
        if ($tradable.Count -eq 0) { continue }
        $partners += $i
    }

    if ($partners.Count -eq 0) {
        Add-Event $Game 'No trade partners are available right now.'
        return
    }

    Write-Host ''
    Write-Host 'Trade partners:' -ForegroundColor Cyan
    foreach ($idx in $partners) {
        $count = @(Get-TradableOwnedSquares $Game $idx).Count
        Write-Host ("  {0}: {1} ({2} tradable)" -f $idx, $Game.players[$idx].name, $count)
    }

    $partner = Read-IntOrNull 'Enter partner index (blank to cancel)'
    if ($null -eq $partner) { return }
    if ($partners -notcontains $partner) {
        Add-Event $Game 'Invalid trade partner.'
        return
    }

    $theirTradable = @(Get-TradableOwnedSquares $Game $partner)

    Write-Host ''
    Write-Host 'Your tradable squares:' -ForegroundColor Cyan
    foreach ($pos in $myTradable) { Write-Host ("  {0,2}: {1}" -f $pos, $BOARD[$pos].name) }

    Write-Host ''
    Write-Host (("{0}'s tradable squares:" -f $Game.players[$partner].name)) -ForegroundColor Cyan
    foreach ($pos in $theirTradable) { Write-Host ("  {0,2}: {1}" -f $pos, $BOARD[$pos].name) }

    $offer = Read-IntArray 'Enter your offered square indices (comma-separated)'
    $request = Read-IntArray (("Enter {0}'s requested square indices (comma-separated)" -f $Game.players[$partner].name))

    $cash = Read-IntOrNull 'Cash adjustment (positive = you pay, negative = they pay, blank = auto)'
    $result = Invoke-ExecuteTrade $Game 0 $partner $offer $request $cash

    if (-not $result.ok) {
        Add-Event $Game ("Trade failed: {0}" -f $result.message)
    }
}

function Invoke-HumanBuyDecision([hashtable]$Game) {
    if ($Game.phase -ne 'buy' -or $null -eq $Game.pendingBuySquare) {
        Add-Event $Game 'No buy decision is pending.'
        return
    }

    $sqIdx = [int]$Game.pendingBuySquare
    $sq = $BOARD[$sqIdx]
    $p = $Game.players[0]

    $choice = Read-Choice ("Buy {0} for `${1}? (b=buy, a=decline & auction, q=quit)" -f $sq.name, $sq.price) @('b', 'a', 's', 'q')
    if ($choice -eq 'q') {
        $script:exitGame = $true
        return
    }

    if ($choice -eq 'b') {
        if ($p.money -ge [int]$sq.price) {
            $p.money -= [int]$sq.price
            $Game.properties[$sqIdx] = [ordered]@{ owner = 0; houses = 0; mortgaged = $false }
            Add-Event $Game ("You bought {0} for `${1}." -f $sq.name, $sq.price)

            if ($sq.type -eq 'property' -and $null -ne $sq.color -and (Test-Monopoly $Game 0 $sq.color)) {
                Add-Event $Game ("Monopoly formed in color group: {0}!" -f $sq.color)
            }
        }
        else {
            Add-Event $Game ("You cannot afford {0}. Sending to auction!" -f $sq.name)
            Invoke-PropertyAuction $Game $sqIdx $true
        }
    }
    else {
        Add-Event $Game ("You passed on {0}. Commencing auction to all players!" -f $sq.name)
        Invoke-PropertyAuction $Game $sqIdx $true
    }

    $Game.pendingBuySquare = $null
    $Game.phase = 'endturn'
}

# ---------------- Main game loop ----------------

if ($SmokeTest) {
    if (Invoke-SmokeTest) {
        exit 0
    }
    exit 1
}

# Interactive opponent selection if not specified via command line
$chosenCpus = $CpuCount
if ($chosenCpus -lt 1 -or $chosenCpus -gt 3) {
    Write-Host '===========================================' -ForegroundColor Cyan
    Write-Host '     STANDALONE MONOPOLY (POWERSHELL)      ' -ForegroundColor Yellow
    Write-Host '===========================================' -ForegroundColor Cyan
    Write-Host 'Choose number of Computer Opponents (1 to 3):'
    Write-Host '  1: 2-player game  (You vs Comet [Car])'
    Write-Host '  2: 3-player game  (You vs Comet [Car] & Stella [Ship])'
    Write-Host '  3: 4-player game  (You vs Comet [Car], Stella [Ship], Biscuit [Dog])'
    $inCount = Read-Choice 'Enter CPU count (1, 2, or 3, default=3)' @('1', '2', '3', '')
    if ($inCount -eq '' -or $inCount -eq '3') {
        $chosenCpus = 3
    }
    else {
        $chosenCpus = [int]$inCount
    }
}

$game = New-Game $chosenCpus
$script:exitGame = $false

while (-not $script:exitGame) {
    Show-PlayerSummary $game
    Show-RecentEvents $game

    if ($game.phase -eq 'game_over') {
        $winner = Get-Winner $game
        Write-Host ''
        Write-Host ("Game over! Winner: {0}." -f $winner.name) -ForegroundColor Green
        $again = Read-Choice 'Play again? (y/n)' @('y', 'n')
        if ($again -eq 'y') {
            $game = New-Game $chosenCpus
            continue
        }
        break
    }

    if (Test-GameOver $game) {
        $game.phase = 'game_over'
        continue
    }

    switch ($game.phase) {
        'roll' {
            $rollPrompt = if ($game.players[0].doublesCount -gt 0) {
                ("Roll phase (DOUBLES #{0}!): (r=roll, p=properties, o=board overview, q=quit)" -f $game.players[0].doublesCount)
            } else {
                'Roll phase: (r=roll, p=properties, o=board overview, q=quit)'
            }
            $choice = Read-Choice $rollPrompt @('r', 'p', 'o', 'q')
            if ($choice -eq 'q') {
                $script:exitGame = $true
                continue
            }
            if ($choice -eq 'p') {
                Write-Host ''
                Write-Host 'Your properties:' -ForegroundColor Cyan
                Show-OwnedProperties $game 0
                continue
            }
            if ($choice -eq 'o') {
                Show-BoardOverview $game
                continue
            }

            $dice = Roll-Dice
            $result = Invoke-ProcessHumanRoll $game $dice.d1 $dice.d2
            Check-Bankruptcy $game 0

            if ($game.players[0].bankrupt -or (Test-GameOver $game)) {
                $game.phase = 'game_over'
            }
            elseif ($result.pendingBuy) {
                $game.pendingBuySquare = [int]$game.players[0].position
                $game.phase = 'buy'
            }
            else {
                $game.phase = 'endturn'
            }
        }
        'buy' {
            Invoke-HumanBuyDecision $game
        }
        'jail_decision' {
            $opts = @('r', 'p', 'q')
            $prompt = 'Jail: (r=roll for doubles, p=pay $50, q=quit'
            if ($game.players[0].getOutOfJailCards -gt 0) {
                $opts += 'c'
                $prompt += ', c=use card'
            }
            $prompt += ')'

            $choice = Read-Choice $prompt $opts
            if ($choice -eq 'q') {
                $script:exitGame = $true
                continue
            }

            $pay = $choice -eq 'p'
            $useCard = $choice -eq 'c'
            $jr = Invoke-ProcessJailRoll $game $pay $useCard
            Check-Bankruptcy $game 0

            if ($game.players[0].bankrupt -or (Test-GameOver $game)) {
                $game.phase = 'game_over'
            }
            elseif ($jr.pendingBuy) {
                $game.pendingBuySquare = [int]$game.players[0].position
                $game.phase = 'buy'
            }
            else {
                $game.phase = 'endturn'
            }
        }
        'endturn' {
            $canBuild = @(Get-BuildableSquares $game 0).Count -gt 0
            $canTrade = @(Get-TradableOwnedSquares $game 0).Count -gt 0
            $canMortgage = (@(Get-MortgageableSquares $game 0).Count -gt 0) -or (@(Get-UnmortgageableSquares $game 0).Count -gt 0)
            $isDoubles = ($null -ne $game.lastDice -and $game.lastDice.doubles -and -not $game.players[0].inJail -and $game.players[0].doublesCount -gt 0 -and $game.players[0].doublesCount -lt 3)

            Write-Host ''
            Write-Host 'Turn actions menu:' -ForegroundColor Cyan
            Write-Host '  e: End turn & proceed to CPUs'
            if ($isDoubles) { Write-Host '  r: Roll again (DOUBLES!)' -ForegroundColor Green }
            if ($canBuild) { Write-Host '  b: Build houses / hotels' }
            if ($canTrade) { Write-Host '  t: Trade with opponents' }
            if ($canMortgage) { Write-Host '  m: Mortgage / Unmortgage' }
            Write-Host '  p: Show your properties'
            Write-Host '  o: Board overview'
            Write-Host '  q: Quit game'

            $allowed = @('e', 'p', 'o', 'q')
            if ($isDoubles) { $allowed += 'r' }
            if ($canBuild) { $allowed += 'b' }
            if ($canTrade) { $allowed += 't' }
            if ($canMortgage) { $allowed += 'm' }

            $choice = Read-Choice 'Choose action' $allowed
            switch ($choice) {
                'q' {
                    $script:exitGame = $true
                    continue
                }
                'p' {
                    Write-Host ''
                    Write-Host 'Your properties:' -ForegroundColor Cyan
                    Show-OwnedProperties $game 0
                }
                'o' {
                    Show-BoardOverview $game
                }
                'b' { Invoke-HumanBuildMenu $game }
                't' { Invoke-HumanTradeMenu $game }
                'm' { Invoke-HumanMortgageMenu $game }
                'r' {
                    $game.phase = 'roll'
                    $dice = Roll-Dice
                    $result = Invoke-ProcessHumanRoll $game $dice.d1 $dice.d2
                    Check-Bankruptcy $game 0

                    if ($game.players[0].bankrupt -or (Test-GameOver $game)) {
                        $game.phase = 'game_over'
                    }
                    elseif ($result.pendingBuy) {
                        $game.pendingBuySquare = [int]$game.players[0].position
                        $game.phase = 'buy'
                    }
                    else {
                        $game.phase = 'endturn'
                    }
                }
                'e' {
                    Add-Event $game '--- Computer turns starting ---'
                    Invoke-RunAllCpuTurns $game
                    $game.round++

                    if (Test-GameOver $game) {
                        $game.phase = 'game_over'
                    }
                    else {
                        Start-HumanTurn $game
                        if ($game.phase -eq 'roll') {
                            Add-Event $game ("Round {0}: Your turn! Roll." -f $game.round)
                        }
                        elseif ($game.phase -eq 'jail_decision') {
                            Add-Event $game 'Your turn: You are in Jail. Choose an action.'
                        }
                    }
                }
            }
        }
        default {
            Add-Event $game 'Unknown phase reached. Resetting to roll.'
            $game.phase = 'roll'
        }
    }

    if ($script:exitGame) { break }
}

Write-Host ''
Write-Host 'Monopoly session ended. Thanks for playing!' -ForegroundColor Yellow
