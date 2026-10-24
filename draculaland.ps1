<#
.SYNOPSIS
    DRACULALAND - Castle Dracula, 1777. A Scott Adams "Adventureland"-style text adventure.
.DESCRIPTION
    A standalone, single-file PowerShell text adventure in the tradition of Scott Adams'
    1978 "Adventureland". It uses the same classic engine ideas:
      * a two-word VERB NOUN parser that only looks at the first three letters of each word
      * first-person room descriptions ("I'm in a ...", "I can also see: ...")
      * a carry limit, a lamp with a limited supply of oil, and dark rooms that can kill
      * treasures that score points when stored on sanctified ground (the ruined chapel)
    Setting: the Carpathians, 1777. Dracula sleeps in his crypt by day.
    GOAL: find a stake and a mallet, reach the crypt, and drive the stake through
    Dracula's heart before the sun sets.
.PARAMETER SmokeTest
    Plays a scripted winning walkthrough headlessly and verifies the result.
.PARAMETER SaveFile
    Path used by the SAVE and LOAD commands.
.EXAMPLE
    ./draculaland.ps1
    ./draculaland.ps1 -SmokeTest
.NOTES
    Inspired by Scott Adams' Adventureland (1978). Type HELP in game for the verb list.
#>
[CmdletBinding()]
param(
    [switch]$SmokeTest,
    [string]$SaveFile = (Join-Path $HOME '.draculaland.sav')
)

$script:MaxCarry   = 8
$script:SunsetTurn = 300
$script:TurnUsed   = $false
$script:Treasures  = @('goblet', 'ring', 'necklace', 'tiara', 'bottle')

# ----------------------------------------------------------------------------
# World data
# ----------------------------------------------------------------------------
$script:Rooms = @{
    pass      = @{ Dark = $false; Exits = @{ N = 'gate'; E = 'shrine' }
                   Desc = "I'm on the Borgo Pass in the Carpathian mountains, in the Year of Our Lord 1777. The afternoon sun is already low. An abandoned wagon sits in the road. To the north a black castle clings to the cliffs." }
    shrine    = @{ Dark = $false; Exits = @{ W = 'pass' }
                   Desc = "I'm at a weathered roadside shrine. Peasants have hung wreaths of garlic and dried flowers on the carved wooden saint." }
    gate      = @{ Dark = $false; Exits = @{ S = 'pass'; N = 'courtyard' }
                   Desc = "I'm before the great iron gates of Castle Dracula. They stand rusted ajar. Carved bats crouch on the gateposts. A cold wind moans through the arch to the north." }
    courtyard = @{ Dark = $false; Exits = @{ S = 'gate'; N = 'hall'; E = 'forge'; W = 'chapel' }
                   Desc = "I'm in a snow-dusted castle courtyard. A forge stands to the east, a small ruined chapel to the west, and huge oak doors lead north into the castle." }
    forge     = @{ Dark = $false; Exits = @{ W = 'courtyard' }
                   Desc = "I'm in the castle blacksmith's forge. The hearth is cold. Rusted tongs and a great anvil sit among drifts of ash." }
    chapel    = @{ Dark = $false; Exits = @{ E = 'courtyard' }
                   Desc = "I'm in a ruined chapel. Though the roof is open to the sky, the air is calm and clean. The stone altar is bare. This is sanctified ground - a safe place to store treasure." }
    hall      = @{ Dark = $false; Exits = @{ S = 'courtyard'; N = 'dining'; E = 'armory'; W = 'library'; U = 'gallery'; D = 'cellar' }
                   Desc = "I'm in the Great Hall of Castle Dracula. Tattered banners hang from the rafters. Doorways lead north, east and west, a staircase climbs up to a gallery, and worn steps descend into a cellar." }
    dining    = @{ Dark = $false; Exits = @{ S = 'hall' }
                   Desc = "I'm in a grand dining room. A long table is laid for a feast no living guest will eat. Chairs are overturned and smashed." }
    armory    = @{ Dark = $false; Exits = @{ W = 'hall' }
                   Desc = "I'm in the castle armory. Rusted halberds and shields line the walls. Most of the racks are empty." }
    library   = @{ Dark = $false; Exits = @{ E = 'hall' }
                   Desc = "I'm in a dusty library. Shelves of mouldering books reach to the ceiling. Cobwebs hang like curtains." }
    gallery   = @{ Dark = $false; Exits = @{ D = 'hall'; E = 'bedchamber'; N = 'tower' }
                   Desc = "I'm on an upper gallery overlooking the Great Hall. A huge portrait of a stern Wallachian Voivode hangs here. Doors lead east and north." }
    bedchamber = @{ Dark = $false; Exits = @{ W = 'gallery' }
                   Desc = "I'm in a lavish bedchamber draped in faded crimson silk. The great canopied bed has not been slept in for centuries." }
    tower     = @{ Dark = $false; Exits = @{ S = 'gallery' }
                   Desc = "I'm at the top of a windswept tower. Through the arrow slits I can see the whole pass and the sun sinking toward the peaks." }
    cellar    = @{ Dark = $true;  Exits = @{ U = 'hall'; N = 'wine'; E = 'crypt' }
                   Desc = "I'm in a cold, damp cellar. Rats scurry in the shadows. Passages lead north, and to the east is a massive iron-bound door set in the rock." }
    wine      = @{ Dark = $true;  Exits = @{ S = 'cellar' }
                   Desc = "I'm in a wine cellar. Rows of dust-covered barrels and bottles stretch into the gloom." }
    crypt     = @{ Dark = $true;  Exits = @{ W = 'cellar' }
                   Desc = "I'm in the crypt of Castle Dracula. The air is thick with the smell of old earth. A black coffin lies on a stone dais in the center of the room." }
}

$script:Items = @{
    lantern  = @{ Name = 'brass lantern';          Nouns = @('lantern', 'lamp');       Take = $true; Desc = 'A sturdy brass lantern. It needs oil and a light.' }
    mutton   = @{ Name = 'joint of mutton';        Nouns = @('mutton', 'meat', 'joint'); Take = $true; Desc = 'A joint of mutton left on the wagon. It still smells good - to a wolf.' }
    crucifix = @{ Name = 'silver crucifix';        Nouns = @('crucifix');              Take = $true; Desc = 'A heavy silver crucifix, blessed by a village priest.' }
    mallet   = @{ Name = 'heavy iron mallet';      Nouns = @('mallet', 'hammer');      Take = $true; Desc = 'A blacksmith''s mallet. It would drive a stake home.' }
    water    = @{ Name = 'vial of holy water';     Nouns = @('water', 'vial', 'holy'); Take = $true; Desc = 'A glass vial of holy water.' }
    dagger   = @{ Name = 'steel dagger';           Nouns = @('dagger', 'knife', 'blade'); Take = $true; Desc = 'A keen steel dagger. Good for carving wood.' }
    leg      = @{ Name = 'oak chair leg';          Nouns = @('leg', 'oak');            Take = $true; Desc = 'A stout leg of seasoned oak, snapped from a chair. If only it had a point...' }
    stake    = @{ Name = 'sharpened oak stake';    Nouns = @('stake', 'point');        Take = $true; Desc = 'A sharpened oak stake. Exactly what a vampire hunter needs.' }
    key      = @{ Name = 'iron key';               Nouns = @('key');                   Take = $true; Desc = 'A large, ancient iron key.' }
    journal  = @{ Name = 'monk''s journal';        Nouns = @('journal', 'diary', 'notes'); Take = $true
                  Desc = "It reads: 'The Count sleeps in his crypt below the cellars by day. A black ward seals the door; holy water breaks it. The key hides behind the Voivode''s portrait. Only a mallet and a stake of oak driven through his heart will end him - and he wakes at sunset.'" }
    oil      = @{ Name = 'flask of lamp oil';      Nouns = @('oil', 'flask');          Take = $true; Desc = 'A flask of lamp oil. FILL the lantern with it.' }
    goblet   = @{ Name = 'gold goblet';            Nouns = @('goblet', 'chalice');     Take = $true; Desc = 'A jewelled gold goblet. A TREASURE!' }
    ring     = @{ Name = 'ruby ring';              Nouns = @('ring', 'ruby');          Take = $true; Desc = 'A blood-red ruby ring. A TREASURE!' }
    necklace = @{ Name = 'emerald necklace';       Nouns = @('necklace', 'emerald');   Take = $true; Desc = 'A glittering emerald necklace. A TREASURE!' }
    tiara    = @{ Name = 'silver tiara';           Nouns = @('tiara');                 Take = $true; Desc = 'A delicate silver tiara. A TREASURE!' }
    bottle   = @{ Name = 'bottle of ancient Tokaji'; Nouns = @('bottle', 'tokaji', 'wine'); Take = $true; Desc = 'A bottle of impossibly old Tokaji wine. A TREASURE!' }
}

$script:StartLoc = @{
    lantern = 'pass'; mutton = 'pass'; crucifix = 'shrine'; mallet = 'forge'; water = 'chapel'
    dagger = 'armory'; leg = 'dining'; stake = 'gone'; key = 'hidden'; journal = 'library'
    oil = 'tower'; goblet = 'dining'; ring = 'hidden'; necklace = 'bedchamber'; tiara = 'tower'
    bottle = 'wine'
}

$script:DirNames = [ordered]@{ N = 'North'; S = 'South'; E = 'East'; W = 'West'; U = 'Up'; D = 'Down' }
$script:DirMap   = @{ n = 'N'; nor = 'N'; s = 'S'; sou = 'S'; e = 'E'; eas = 'E'; w = 'W'; wes = 'W'; u = 'U'; up = 'U'; d = 'D'; dow = 'D' }

# ----------------------------------------------------------------------------
# Parser tables (Scott Adams engine: only the first 3 letters matter)
# ----------------------------------------------------------------------------
function Get-Prefix([string]$Word) {
    $w = $Word.ToLower()
    return $w.Substring(0, [Math]::Min(3, $w.Length))
}

$script:VerbMap = @{}
function Add-Verbs([string]$Canon, [string[]]$Words) {
    foreach ($w in $Words) { $script:VerbMap[(Get-Prefix $w)] = $Canon }
}
Add-Verbs 'go'        @('go', 'walk', 'run', 'head')
Add-Verbs 'take'      @('take', 'get', 'grab', 'pick')
Add-Verbs 'drop'      @('drop', 'leave', 'put', 'discard')
Add-Verbs 'look'      @('look', 'l')
Add-Verbs 'examine'   @('examine', 'x', 'inspect', 'read', 'search', 'check')
Add-Verbs 'inventory' @('inventory', 'inv', 'i')
Add-Verbs 'open'      @('open', 'unlock')
Add-Verbs 'light'     @('light', 'ignite', 'kindle')
Add-Verbs 'douse'     @('extinguish', 'douse', 'snuff')
Add-Verbs 'throw'     @('throw', 'toss', 'feed')
Add-Verbs 'show'      @('show', 'hold', 'brandish', 'raise')
Add-Verbs 'carve'     @('carve', 'whittle', 'sharpen', 'cut')
Add-Verbs 'move'      @('move', 'push', 'slide', 'shift', 'pull', 'lift')
Add-Verbs 'sprinkle'  @('sprinkle', 'pour', 'splash', 'bless')
Add-Verbs 'fill'      @('fill', 'refuel')
Add-Verbs 'stake'     @('stake', 'drive', 'hammer', 'impale', 'kill', 'slay', 'attack', 'hit', 'stab', 'strike')
Add-Verbs 'score'     @('score')
Add-Verbs 'help'      @('help', 'hint', '?')
Add-Verbs 'save'      @('save')
Add-Verbs 'load'      @('load', 'restore')
Add-Verbs 'quit'      @('quit', 'q', 'exit')
Add-Verbs 'wait'      @('wait', 'z')
Add-Verbs 'pray'      @('pray')
Add-Verbs 'use'       @('use')

$script:StopWords = @('the', 'a', 'an', 'to', 'at', 'on', 'with', 'in', 'into', 'onto', 'of', 'from', 'my', 'some', 'it', 'using', 'and')
$script:DraculaWords = @('dracula', 'vampire', 'count', 'voivode', 'vlad', 'heart', 'him', 'master', 'dra')

function Test-Noun([string]$Word, [string[]]$Aliases) {
    if (-not $Word) { return $false }
    $p = Get-Prefix $Word
    foreach ($a in $Aliases) { if ((Get-Prefix $a) -eq $p) { return $true } }
    return $false
}

# ----------------------------------------------------------------------------
# Output helpers
# ----------------------------------------------------------------------------
function Say([string]$Text, [string]$Color = 'Gray') {
    $line = ''
    foreach ($word in ($Text -split ' ')) {
        if ($line.Length -gt 0 -and ($line.Length + $word.Length + 1) -gt 76) {
            Write-Host $line -ForegroundColor $Color
            $line = $word
        }
        elseif ($line) { $line = "$line $word" }
        else { $line = $word }
    }
    if ($line) { Write-Host $line -ForegroundColor $Color }
}

# ----------------------------------------------------------------------------
# State helpers
# ----------------------------------------------------------------------------
function New-State {
    return @{
        Room = 'pass'; Turn = 0; Oil = 220; Lit = $false; Over = $false; Won = $false
        Flags = @{}; ItemLoc = $script:StartLoc.Clone()
    }
}

function Get-ItemsAt([string]$Loc) {
    $s = $script:State
    return @($s.ItemLoc.Keys | Where-Object { $s.ItemLoc[$_] -eq $Loc } | Sort-Object)
}

function Find-Item([string]$Word, [string[]]$Where) {
    if (-not $Word) { return $null }
    $s = $script:State
    foreach ($k in ($script:Items.Keys | Sort-Object)) {
        if ($Where -contains $s.ItemLoc[$k] -and (Test-Noun $Word $script:Items[$k].Nouns)) { return $k }
    }
    return $null
}

function Get-CarryCount { return @(Get-ItemsAt 'inv').Count }

function Get-StoredCount {
    $s = $script:State
    return @($script:Treasures | Where-Object { $s.ItemLoc[$_] -eq 'chapel' }).Count
}

function Test-HasLight {
    $s = $script:State
    return ($s.Lit -and @('inv', $s.Room) -contains $s.ItemLoc['lantern'])
}

function Test-Dark {
    $s = $script:State
    return ($script:Rooms[$s.Room].Dark -and -not (Test-HasLight))
}

function End-Game([string]$Message, [bool]$Won) {
    $s = $script:State
    $s.Over = $true
    $s.Won = $Won
    Write-Host ''
    Say $Message $(if ($Won) { 'Green' } else { 'Red' })
    Write-Host ''
    $stored = Get-StoredCount
    Say ("Treasures stored in the chapel: $stored of 5.   Turns taken: $($s.Turn).") 'Cyan'
    if ($Won) {
        $rank = if ($stored -eq 5) { 'GRAND VAMPIRE SLAYER - a perfect hunt!' }
                elseif ($stored -ge 3) { 'Master Vampire Hunter' }
                else { 'Brave Vampire Hunter' }
        Say "Rank: $rank" 'Yellow'
    }
    else {
        Say 'The Count has claimed another soul. Better luck next time.' 'DarkRed'
    }
}

function Show-Room {
    $s = $script:State
    if (Test-Dark) {
        Say "It's pitch dark. I can't see a thing! A light would help." 'DarkGray'
        return
    }
    $room = $script:Rooms[$s.Room]
    Say $room.Desc 'White'
    if ($s.Room -eq 'courtyard' -and -not $s.Flags['wolvesGone']) {
        Say 'A pack of gaunt grey WOLVES circles me, snarling and starving!' 'Red'
    }
    if ($s.Room -eq 'hall' -and -not $s.Flags['brideGone']) {
        Say 'A pale VAMPIRE BRIDE in a tattered wedding gown stands at the foot of the stairs, smiling with long white fangs!' 'Red'
    }
    if ($s.Room -eq 'crypt' -and $s.Flags['coffinOpen']) {
        Say 'The coffin lid is open. DRACULA lies sleeping inside, pale as wax!' 'Red'
    }
    $here = Get-ItemsAt $s.Room
    if ($here.Count -gt 0) {
        Say ('I can also see: ' + (($here | ForEach-Object { $script:Items[$_].Name }) -join ', ') + '.') 'Yellow'
    }
    $exits = @($script:DirNames.Keys | Where-Object { $room.Exits.ContainsKey($_) } | ForEach-Object { $script:DirNames[$_] })
    Say ('Obvious exits: ' + ($exits -join ', ') + '.') 'Cyan'
}

function Show-Banner {
    Write-Host ''
    Write-Host '==========================================================================' -ForegroundColor DarkRed
    Write-Host '                   D R A C U L A L A N D   (1 7 7 7)' -ForegroundColor Red
    Write-Host '        An Adventureland-style text adventure in a single script' -ForegroundColor Gray
    Write-Host '==========================================================================' -ForegroundColor DarkRed
    Say "Transylvania, 1777. The Count preys upon the valleys. By day he sleeps in his crypt. You have until sunset to find a stake and a mallet and drive the stake through his heart. Gather treasures if you dare, and store them on holy ground in the chapel."
    Say 'Give me commands of two words: VERB NOUN (e.g. TAKE LANTERN, GO NORTH). Type HELP for hints.' 'DarkGray'
    Write-Host ''
}

# ----------------------------------------------------------------------------
# Time
# ----------------------------------------------------------------------------
function Step-Time {
    $s = $script:State
    $s.Turn++
    if ($s.Lit) {
        $s.Oil--
        if ($s.Oil -eq 20) { Say 'My lantern is growing dim.' 'Yellow' }
        if ($s.Oil -le 0) { $s.Lit = $false; Say 'My lantern has run out of oil!' 'Red' }
    }
    switch ($s.Turn) {
        200 { Say 'The sun is sinking toward the mountain peaks.' 'Yellow' }
        250 { Say 'Twilight deepens. Somewhere a wolf howls.' 'Yellow' }
        280 { Say 'The last red light fades. Deep below, something stirs...' 'Red' }
    }
    if ($s.Turn -ge $script:SunsetTurn -and -not $s.Over) {
        End-Game 'The sun sets! In the crypt a coffin lid grinds open. Dracula rises, finds me in his castle, and his cold fingers close around my throat. The world goes dark.' $false
    }
}

# ----------------------------------------------------------------------------
# Actions
# ----------------------------------------------------------------------------
function Move-Player([string]$Dir) {
    $s = $script:State
    $room = $script:Rooms[$s.Room]
    if (Test-Dark) {
        Say 'Dangerous to move in the dark!' 'Yellow'
        if ((Get-Random -Minimum 1 -Maximum 101) -le 35) {
            End-Game 'I stumbled in the blackness, tumbled down worn stone steps, and broke my neck!' $false
            return
        }
    }
    if (-not $room.Exits.ContainsKey($Dir)) { Say "I can't go in that direction."; return }
    if ($s.Room -eq 'courtyard' -and $Dir -ne 'S' -and -not $s.Flags['wolvesGone']) {
        Say 'The wolves snarl and snap at my heels. I dare not go that way - they would tear me apart!' 'Red'
        $script:TurnUsed = $true
        return
    }
    if ($s.Room -eq 'hall' -and $Dir -ne 'S' -and -not $s.Flags['brideGone']) {
        Say 'The Vampire Bride glides in front of me, hissing. I cannot get past her! Something holy might drive her off.' 'Red'
        $script:TurnUsed = $true
        return
    }
    if ($s.Room -eq 'cellar' -and $Dir -eq 'E' -and -not $s.Flags['cryptOpen']) {
        Say 'The iron-bound crypt door is shut fast.'
        return
    }
    $s.Room = $room.Exits[$Dir]
    $script:TurnUsed = $true
    Show-Room
}

function Get-SceneryText([string]$Word) {
    $s = $script:State
    switch ($s.Room) {
        'gallery' {
            if (Test-Noun $Word @('portrait', 'painting', 'picture', 'voivode')) {
                return "The Voivode's cruel eyes seem to follow me. The heavy frame is a little loose - perhaps I could MOVE it."
            }
        }
        'library' {
            if (Test-Noun $Word @('books', 'shelves', 'shelf', 'book')) {
                if ($s.ItemLoc['ring'] -eq 'hidden') {
                    $s.ItemLoc['ring'] = 'library'
                    return 'Most of the books crumble to dust. But a hollowed-out volume falls open and a RUBY RING tumbles out!'
                }
                return 'Mouldering books. Nothing more of interest.'
            }
        }
        'chapel' {
            if (Test-Noun $Word @('altar')) { return 'A plain stone altar. Treasures dropped here are safe. I might PRAY here too.' }
        }
        'courtyard' {
            if (Test-Noun $Word @('wolves', 'wolf', 'pack')) { return 'Lean, hungry wolves. They stare at me as if I were dinner. Perhaps I could feed them something.' }
        }
        'hall' {
            if (Test-Noun $Word @('bride', 'woman', 'vampiress') -and -not $s.Flags['brideGone']) {
                return 'A pale vampire bride, beautiful and terrible. She cringes from anything holy.'
            }
        }
        'cellar' {
            if (Test-Noun $Word @('door', 'sigil', 'ward')) {
                if ($s.Flags['cryptOpen']) { return 'The crypt door stands open.' }
                if ($s.Flags['wardBroken']) { return 'A heavy iron-bound door. The ward is gone, but it is locked.' }
                return 'A heavy iron door. A black sigil glows on it - a ward I dare not touch. Something holy might break it.'
            }
        }
        'crypt' {
            if (Test-Noun $Word @('coffin', 'casket', 'lid')) {
                if ($s.Flags['coffinOpen']) { return 'Dracula sleeps within. His chest does not rise.' }
                return 'A black coffin with a heavy lid. I could OPEN it.'
            }
        }
        'forge' {
            if (Test-Noun $Word @('anvil', 'hearth', 'tongs')) { return 'Cold iron and old ash. Nothing useful.' }
        }
        'dining' {
            if (Test-Noun $Word @('table', 'chairs', 'chair', 'feast')) { return 'Rotting food crawls with worms. One chair is broken - its leg lies on the floor.' }
        }
        'shrine' {
            if (Test-Noun $Word @('saint', 'wreath', 'garlic', 'shrine')) { return 'Garlic wreaths hang about the saint. A silver crucifix has been left at its feet by a pilgrim.' }
        }
        'pass' {
            if (Test-Noun $Word @('wagon', 'castle')) { return 'The wagon has been abandoned in a hurry. Its driver is nowhere to be seen. The castle looms to the north.' }
        }
    }
    return $null
}

function Invoke-Verb([string]$Canon, [string]$Noun) {
    $s = $script:State
    switch ($Canon) {
        'go' {
            if (-not $Noun) { Say 'Go where?'; return }
            $d = $script:DirMap[(Get-Prefix $Noun)]
            if ($d) { Move-Player $d } else { Say "I don't understand that direction." }
        }
        'look' { Show-Room }
        'inventory' {
            $inv = Get-ItemsAt 'inv'
            if ($inv.Count -eq 0) { Say "I'm not carrying anything." }
            else {
                Say ('I am carrying: ' + (($inv | ForEach-Object { $script:Items[$_].Name }) -join ', ') + '.') 'Yellow'
                if ($s.Lit) { Say 'My lantern is lit.' 'DarkGray' }
            }
        }
        'take' {
            if (-not $Noun) { Say 'Take what?'; return }
            if (Test-Dark) { Say "It's too dark to find anything!"; return }
            $k = Find-Item $Noun @($s.Room)
            if (-not $k) {
                if (Find-Item $Noun @('inv')) { Say 'I already have it.' }
                elseif (Get-SceneryText $Noun) { Say "I can't carry that." }
                else { Say "I don't see that here." }
                return
            }
            if ((Get-CarryCount) -ge $script:MaxCarry) { Say "I'm carrying too much. Drop something first."; return }
            $s.ItemLoc[$k] = 'inv'
            Say 'OK'
            $script:TurnUsed = $true
        }
        'drop' {
            if (-not $Noun) { Say 'Drop what?'; return }
            $k = Find-Item $Noun @('inv')
            if (-not $k) { Say "I'm not carrying that."; return }
            $s.ItemLoc[$k] = $s.Room
            $script:TurnUsed = $true
            if ($s.Room -eq 'chapel' -and $script:Treasures -contains $k) {
                Say ("OK. The treasure glows softly on holy ground and is safely stored! (" + (Get-StoredCount) + ' of 5)') 'Green'
            }
            else { Say 'OK' }
        }
        'examine' {
            if (-not $Noun) { Say 'Examine what?'; return }
            $k = Find-Item $Noun @('inv', $(if (Test-Dark) { 'none' } else { $s.Room }))
            if ($k) { Say $script:Items[$k].Desc 'White'; return }
            if (Test-Dark) { Say "It's too dark to see!"; return }
            if ($s.Room -eq 'crypt' -and ($script:DraculaWords -contains $Noun.ToLower() -or (Test-Noun $Noun $script:DraculaWords))) {
                if ($s.Flags['coffinOpen']) { Say 'Dracula sleeps like the dead he is. His heart, I think, is the target.' 'Red' }
                else { Say 'He must be inside the closed coffin.' }
                return
            }
            $t = Get-SceneryText $Noun
            if ($t) { Say $t 'White'; $script:TurnUsed = $true } else { Say 'I see nothing special.' }
        }
        'open' {
            if (-not $Noun) { Say 'Open what?'; return }
            if ($s.Room -eq 'cellar' -and (Test-Noun $Noun @('door', 'iron'))) {
                if ($s.Flags['cryptOpen']) { Say 'It is already open.'; return }
                if (-not $s.Flags['wardBroken']) { Say 'A black ward on the door crackles at my touch and hurls me back. I need something holy!' 'Red'; $script:TurnUsed = $true; return }
                if ($s.ItemLoc['key'] -ne 'inv') { Say 'The door is locked. I need a key.'; return }
                $s.Flags['cryptOpen'] = $true
                Say 'The iron key turns with a groan. The crypt door swings open! A breath of grave-cold air rolls out.' 'Green'
                $script:TurnUsed = $true
                return
            }
            if ($s.Room -eq 'crypt' -and (Test-Noun $Noun @('coffin', 'casket', 'lid'))) {
                if (Test-Dark) { Say "It's too dark to see what I'm doing!"; return }
                if ($s.Flags['coffinOpen']) { Say 'It is already open.'; return }
                $s.Flags['coffinOpen'] = $true
                Say 'With a grinding scrape I heave the lid aside. DRACULA lies within, pale and motionless, the sleep of the undead upon him. His heart awaits a stake!' 'Red'
                $script:TurnUsed = $true
                return
            }
            if ($s.Room -eq 'gate' -and (Test-Noun $Noun @('gate', 'gates'))) { Say 'The gates are rusted open already.'; return }
            Say "I can't open that."
        }
        'light' {
            if ((Find-Item 'lantern' @('inv')) -ne 'lantern') { Say "I don't have a light."; return }
            if ($s.Oil -le 0) { Say 'The lantern is out of oil.'; return }
            if ($s.Lit) { Say 'It is already lit.'; return }
            $s.Lit = $true
            Say 'The lantern flickers to life.' 'Yellow'
            $script:TurnUsed = $true
        }
        'douse' {
            if (-not $s.Lit) { Say "It isn't lit."; return }
            $s.Lit = $false
            Say 'The lantern is out.'
            $script:TurnUsed = $true
        }
        'fill' {
            if ((Find-Item 'oil' @('inv')) -ne 'oil') { Say "I don't have any oil."; return }
            if ((Find-Item 'lantern' @('inv')) -ne 'lantern') { Say "I'm not holding the lantern."; return }
            $s.Oil += 150
            $s.ItemLoc['oil'] = 'gone'
            Say 'I pour the oil into the lantern. It burns bright again.' 'Green'
            $script:TurnUsed = $true
        }
        'throw' {
            if (-not $Noun) { Say 'Throw what?'; return }
            $k = Find-Item $Noun @('inv')
            if (-not $k) { Say "I'm not carrying that."; return }
            if ($k -eq 'mutton' -and $s.Room -eq 'courtyard' -and -not $s.Flags['wolvesGone']) {
                $s.Flags['wolvesGone'] = $true
                $s.ItemLoc['mutton'] = 'gone'
                Say 'I hurl the mutton across the courtyard. The wolves fall upon it in a snarling heap, then drag it away into the shadows. The way is clear!' 'Green'
            }
            else {
                $s.ItemLoc[$k] = $s.Room
                Say 'It clatters to the floor.'
            }
            $script:TurnUsed = $true
        }
        'show' {
            if ((Find-Item 'crucifix' @('inv')) -ne 'crucifix' -or ($Noun -and -not (Test-Noun $Noun $script:Items['crucifix'].Nouns))) {
                Say "I don't have that to show."
                return
            }
            if ($s.Room -eq 'hall' -and -not $s.Flags['brideGone']) {
                $s.Flags['brideGone'] = $true
                Say 'I thrust the crucifix before me. The Vampire Bride shrieks, shields her eyes, and flees up the stairs into the darkness. The way is clear!' 'Green'
            }
            else { Say 'Nothing happens.' }
            $script:TurnUsed = $true
        }
        'sprinkle' {
            if ($Noun -and (Test-Noun $Noun $script:Items['oil'].Nouns)) { Invoke-Verb 'fill' $Noun; return }
            if ((Find-Item 'water' @('inv')) -ne 'water') { Say "I don't have anything to sprinkle."; return }
            if ($s.Room -eq 'cellar' -and -not $s.Flags['wardBroken']) {
                $s.Flags['wardBroken'] = $true
                $s.ItemLoc['water'] = 'gone'
                Say 'I sprinkle holy water on the door. The black sigil sizzles, screams, and fades to ash. The ward is broken!' 'Green'
            }
            elseif ($s.Room -eq 'crypt') {
                Say 'The holy water hisses where it falls on the coffin, but it will not end him. Only a stake will.'
            }
            else { Say 'Nothing happens. I should not waste holy water.' }
            $script:TurnUsed = $true
        }
        'carve' {
            $leg = Find-Item 'leg' @('inv')
            if (-not $leg) { Say "I have nothing to carve."; return }
            if ((Find-Item 'dagger' @('inv')) -ne 'dagger') { Say 'I need a blade to carve with.'; return }
            $s.ItemLoc['leg'] = 'gone'
            $s.ItemLoc['stake'] = 'inv'
            Say 'I whittle the oak leg to a wicked point. I now have a sharpened oak STAKE!' 'Green'
            $script:TurnUsed = $true
        }
        'move' {
            if ($s.Room -eq 'gallery' -and (Test-Noun $Noun @('portrait', 'painting', 'picture', 'frame'))) {
                if ($s.ItemLoc['key'] -eq 'hidden') {
                    $s.ItemLoc['key'] = 'gallery'
                    Say 'I swing the heavy portrait aside. Behind it is a small niche and an iron KEY!' 'Green'
                }
                else { Say 'The portrait swings aside. The niche behind it is empty.' }
                $script:TurnUsed = $true
                return
            }
            Say "I can't move that."
        }
        'stake' {
            $targetOk = (-not $Noun) -or ($script:DraculaWords -contains $Noun.ToLower()) -or (Test-Noun $Noun $script:DraculaWords) -or (Test-Noun $Noun $script:Items['stake'].Nouns) -or (Test-Noun $Noun $script:Items['mallet'].Nouns)
            if ($s.Room -eq 'hall' -and -not $s.Flags['brideGone'] -and (Test-Noun $Noun @('bride', 'woman'))) {
                Say 'She is only his servant - she would shrug off a mere blow. I need the Master himself!'
                return
            }
            if ($s.Room -ne 'crypt') { Say 'There is nothing here to stake.'; return }
            if (-not $targetOk) { Say "I can't do that."; return }
            if (Test-Dark) { Say "It's too dark to see anything!"; return }
            if (-not $s.Flags['coffinOpen']) { Say 'Dracula is hidden inside the closed coffin.'; return }
            $hasStake  = ((Find-Item 'stake' @('inv')) -eq 'stake')
            $hasMallet = ((Find-Item 'mallet' @('inv')) -eq 'mallet')
            if (-not $hasStake)  { Say "I have no stake! I can't pierce his heart with my bare hands."; return }
            if (-not $hasMallet) { Say "I have a stake, but nothing heavy enough to drive it through his chest."; return }
            End-Game ("I set the point above his heart and swing the mallet with all my strength. THUNK! Dracula's eyes snap open and he SHRIEKS - a sound that shakes the stones - then his body withers, blackens, and crumbles to dust. The castle trembles and falls silent. The valleys are free of the Count at last. YOU WIN!") $true
        }
        'pray' {
            if ($s.Room -eq 'chapel') {
                $left = $script:SunsetTurn - $s.Turn
                Say "A deep calm settles over me. A quiet voice whispers that I have about $left moves before the sun sets." 'Cyan'
                $script:TurnUsed = $true
            }
            else { Say 'Nothing happens.' }
        }
        'use' {
            if (-not $Noun) { Say 'Use what?'; return }
            $k = Find-Item $Noun @('inv')
            if (-not $k) { Say "I'm not carrying that."; return }
            switch ($k) {
                'key'      { Invoke-Verb 'open' 'door' }
                'water'    { Invoke-Verb 'sprinkle' 'water' }
                'crucifix' { Invoke-Verb 'show' 'crucifix' }
                'lantern'  { Invoke-Verb 'light' 'lantern' }
                'dagger'   { Invoke-Verb 'carve' 'leg' }
                'leg'      { Invoke-Verb 'carve' 'leg' }
                'mallet'   { Invoke-Verb 'stake' 'dracula' }
                'stake'    { Invoke-Verb 'stake' 'dracula' }
                'oil'      { Invoke-Verb 'fill' 'lantern' }
                'mutton'   { Invoke-Verb 'throw' 'mutton' }
                default    { Say "I don't know how to use that." }
            }
        }
        'wait' { Say 'Time passes...'; $script:TurnUsed = $true }
        'score' {
            $left = $script:SunsetTurn - $s.Turn
            Say ("I've stored " + (Get-StoredCount) + " of 5 treasures. I have taken $($s.Turn) turns; about $left remain before sunset.") 'Cyan'
            Say 'Dracula is not yet destroyed.' 'DarkGray'
        }
        'help' {
            Say 'I understand two-word commands: VERB NOUN. Only the first three letters of each word matter. Directions: N S E W U D (or GO NORTH).' 'Cyan'
            Say 'Verbs: GO TAKE DROP LOOK EXAMINE INVENTORY OPEN LIGHT DOUSE FILL THROW SHOW CARVE MOVE SPRINKLE STAKE PRAY USE WAIT SCORE SAVE LOAD QUIT.' 'Cyan'
            Say 'Hints: Dracula sleeps in his crypt below the cellar until sunset. You need a mallet and a stake. Wolves and a vampire bride bar the way. Examine everything. Store treasures in the chapel.' 'Yellow'
        }
        'save' {
            try { Export-Clixml -InputObject $s -Path $SaveFile; Say "Game saved to $SaveFile." 'Green' }
            catch { Say "I couldn't save the game: $($_.Exception.Message)" 'Red' }
        }
        'load' {
            if (-not (Test-Path $SaveFile)) { Say 'I have no saved game.'; return }
            try { $script:State = Import-Clixml -Path $SaveFile; Say 'Game loaded.' 'Green'; Show-Room }
            catch { Say "I couldn't load the game: $($_.Exception.Message)" 'Red' }
        }
        'quit' {
            $s.Over = $true
            Say 'You flee the castle, a coward to the last. The Count laughs in the dark.' 'Yellow'
        }
        default { Say "I don't understand." }
    }
}

function Invoke-GameCommand([string]$Line) {
    $script:TurnUsed = $false
    $words = @($Line.ToLower() -split '\s+' | Where-Object { $_ })
    $words = @($words | Where-Object { $script:StopWords -notcontains $_ })
    if ($words.Count -eq 0) { Say 'Tell me what to do.'; return }
    if ($words.Count -gt 1 -and (Get-Prefix $words[0]) -in @('pic', 'tak', 'get', 'gra')) {
        $words = @($words | Where-Object { $_ -ne 'up' })
    }
    $verbWord = $words[0]
    $noun = if ($words.Count -gt 1) { $words[1] } else { $null }

    if ($words.Count -eq 1 -and $script:DirMap.ContainsKey((Get-Prefix $verbWord))) {
        Move-Player $script:DirMap[(Get-Prefix $verbWord)]
    }
    else {
        $canon = $script:VerbMap[(Get-Prefix $verbWord)]
        if (-not $canon) { Say "I don't know how to '$verbWord'."; return }
        Invoke-Verb $canon $noun
    }
    if ($script:TurnUsed -and -not $script:State.Over) { Step-Time }
}

# ----------------------------------------------------------------------------
# Smoke test: a scripted winning walkthrough
# ----------------------------------------------------------------------------
function Invoke-DraculaSmokeTest {
    Write-Host '[Draculaland] Running automated headless smoke test...' -ForegroundColor Cyan
    $script:State = New-State
    $walkthrough = @(
        'take lantern', 'take mutton', 'e', 'take crucifix', 'w', 'n', 'n',
        'throw mutton', 'e', 'take mallet', 'w', 'w', 'take water', 'e',
        'n', 'show crucifix', 'e', 'take dagger', 'w', 'n', 'take leg', 'carve leg', 's',
        'u', 'move portrait', 'take key', 'd', 'light lantern', 'd',
        'sprinkle water', 'open door', 'e', 'open coffin', 'stake dracula'
    )
    foreach ($cmd in $walkthrough) {
        Write-Host "> $cmd" -ForegroundColor DarkGray
        Invoke-GameCommand $cmd
        if ($script:State.Over) { break }
    }
    if (-not $script:State.Won) { throw 'Smoke test failed: the walkthrough did not defeat Dracula.' }

    # Extra checks: carry limit and treasure storing on a fresh state
    $script:State = New-State
    Invoke-GameCommand 'take lantern'
    if ($script:State.ItemLoc['lantern'] -ne 'inv') { throw 'Smoke test failed: TAKE did not pick up the lantern.' }
    $script:State.ItemLoc['goblet'] = 'inv'
    $script:State.Room = 'chapel'
    Invoke-GameCommand 'drop gob'
    if ((Get-StoredCount) -ne 1) { throw 'Smoke test failed: treasure was not stored in the chapel.' }
    Write-Host '[Draculaland] Smoke test PASSED successfully!' -ForegroundColor Green
    return $true
}

# ----------------------------------------------------------------------------
# Entry point
# ----------------------------------------------------------------------------
if ($SmokeTest) {
    Invoke-DraculaSmokeTest
    exit 0
}

$script:State = New-State
Show-Banner
Show-Room
while (-not $script:State.Over) {
    Write-Host ''
    $line = Read-Host 'Tell me what to do'
    if ($null -eq $line) { break }
    Invoke-GameCommand $line
}
