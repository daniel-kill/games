# games

A collection of interactive games, simulations, and terminal entertainment utilities built for PowerShell and cross-platform environments.

---

## 🎲 Available Games

### 1. `monopoly.ps1` — Standalone Terminal Monopoly

A single-player Monopoly board game simulator running in PowerShell against 1 to 3 autonomous CPU opponents.

#### ✨ Features & Faithful Rule Compliance:
- **Classic 40-Space Board & Bankroll:** Standard starting balance of $1,500 with all color groups, utilities, and railroads.
- **Supply Limits & Shortages:** Strict bank limit of 32 Houses and 12 Hotels, replicating strategic housing shortages.
- **Card Decks:** Shuffled 16-card Chance and Community Chest decks with card recycling.
- **Auctions:** Real-time auction system when an unowned property is declined or unaffordable.
- **Monopoly Rules:** Double unimproved rent on full sets, even building restrictions, 10% unmortgage fee, and 3-doubles speeding jail penalty.
- **Headless Smoke Tests:** Built-in `-SmokeTest` flag for automated headless verification.

---

### 2. `The-Wizards-Castle.ps1` — The Wizard's Castle (1980 Classic RPG)

A rich terminal recreation of the legendary 1980 dungeon-crawling classic *The Wizard's Castle* originally created by Joseph R. Power.

#### ✨ Features & Gameplay:
- **Explore Zot's Labyrinth:** 8 levels of subterranean chambers with 64 rooms per floor (512 rooms total).
- **Find the Orb of Zot:** Brave lethal monsters (Kobolds, Orcs, Dragons, Gargoyles), discover ancient runic treasures, and escape alive.
- **Character Races & Customization:** Play as Elf, Dwarf, Human, or Hobbit with custom attributes (Strength, Intelligence, Dexterity).
- **Tactical Combat & Spells:** Weapon attacks, flares, web spells, fireballs, and warp teleporters.
- **Map & Save System:** Dynamic automapping and state tracking.

---

### 3. `hunt-the-wumpus.ps1` — Hunt the Wumpus (1973 Classic Cave Deduction)

A complete, standalone PowerShell implementation of Gregory Yob's iconic 1973 text adventure.

#### ✨ Features & Gameplay:
- **20-Room Dodecahedron Cave:** Interconnected cave graph where each vertex links to exactly 3 neighboring rooms.
- **Sensory Cues & Deduction:** Track the Wumpus by its foul odor (*"I smell a Wumpus!"*), sense drafty pits (*"I feel a draft!"*), and listen for fluttering wings (*"Bats nearby!"*).
- **Crooked Arrows:** Shoot crooked arrows bending through up to 5 adjacent rooms to fell the beast before it awakens or charges your room.
- **Interactive Cave Radar:** Colorized ANSI status panel displaying exits and sensory warnings.

---

### 4. `oregon-trail.ps1` — The Oregon Trail: Frontier Expedition (1848)

A deep frontier resource management and survival simulation spanning 2,040 miles from Independence, Missouri to Oregon's Willamette Valley.

#### ✨ Features & Gameplay:
- **Expedition Resource Economy:** Manage cash, oxen, food stores, bullets, clothing sets, and spare wagon parts (wheels, axles, tongues).
- **Dynamic Frontier Encounters:** Navigate swollen rivers (Kansas, Green, Snake, Columbia), trade with native tribes, and handle wagon breakdowns.
- **Diseases & Attrition:** Survive cholera, typhoid, dysentery, measles, snakebites, and bitter blizzards.
- **Hunting & Resting:** Hunt for fresh game to restock meat supplies and rest party members to restore vital health.

---

### 5. `battleship.ps1` — Terminal Battleship (Naval Combat Simulation)

A full 10x10 dual-grid naval tactical warfare game pitching you against an intelligent AI fleet.

#### ✨ Features & Gameplay:
- **Full 5-Vessel Fleet:** Carrier (5), Battleship (4), Cruiser (3), Submarine (3), and Destroyer (2).
- **Color-Coded ANSI Radar:** Side-by-side display of your defense fleet and enemy tracking radar.
- **Multi-Tier AI Tactics:**
  - **Ensign:** Casual random firing.
  - **Captain:** Hunt-and-target mode with orthogonal adjacent tracking upon hits.
  - **Admiral:** Advanced parity checkerboard search coupled with vector-lock ship hunting.

---

### 6. `draculaland.ps1` — Draculaland: Castle Dracula, 1777 (Adventureland-style)

A Scott Adams *Adventureland*-style text adventure. It is set in the Carpathians in 1777, and the goal is to stake Dracula through the heart before sunset.

#### ✨ Features & Gameplay:
- **Classic Scott Adams Engine:** Two-word `VERB NOUN` parser that only reads the first three letters of each word, first-person room descriptions, and a carry limit.
- **Puzzles:** Feed the wolves, repel a vampire bride with a crucifix, break a ward with holy water, find a hidden key, and carve a stake with a dagger.
- **Dark Rooms & Lamp Oil:** Moving in the dark can kill you, and the lantern burns oil.
- **Treasures & Score:** Store 5 treasures on holy ground in the chapel for a higher rank.
- **Sunset Clock:** 300 moves until Dracula wakes. `SAVE`, `LOAD`, `HELP` and `-SmokeTest` are supported.

---

### 7. `moebius/` & `moebius.ps1` / `moebius.sh` — Moebius: The Orb of Celestial Harmony (1987)

An authentic retro recreation of Origin Systems' iconic 1987 martial arts RPG created by Greg Malone. Built for WSL and modern web browsers with pixel-accurate C64/EGA rendering and 3-voice retro chiptune audio.

#### ✨ Features & Gameplay:
- **Four Elemental Realms:** Explore the authentic 64x64 matrices of Earth, Water, Air, and Fire extracted directly from the original game disk images (`EARTH.MTX`, `WATER.MTX`, `AIR.MTX`, `FIRE.MTX`).
- **Tactical Side-View Combat:** 1-on-1 martial arts and sword duels with 6 strike zones (High/Mid/Low Kick, Punch, or Swing), blocking, stride/step footwork, fatigue management, and shuriken throwing.
- **Divination Minigame:** Keep the restless Yin-Yang spirit centered against cosmic winds using meditation to gain prophecy visions and boost Mind energy.
- **Taoist Karma & Fasting Magic:** 5 Fasting prayers (Speak with Dead, Protection, Waterwalk, Cure Sickness, Guiding Light) and 6 component charms (Ventriloquism, Paralysis, Teleport, Invisibility, Spirit Walk, Were-Spell).
- **Original Music & Sound Effects:** Synthesizes the 31 chiptune tracks extracted from `PCMUSIC.SLB` and authentic SID/PSG chiptune sound effects via Web Audio API.
- **Retro Visual Engine:** 320x200 pixel resolution with CRT scanline toggles, C64 and DOS EGA color palettes, authentic bamboo borders, and extracted original character sprites.
- **Cross-Platform Launchers:** Launch in WSL via `./moebius.sh` or in PowerShell via `./moebius.ps1` (with `-SmokeTest` / `--test` automated verification).

---

## 🚀 Quick Start

Ensure PowerShell 7 (`pwsh`) or Windows PowerShell is installed.

```powershell
# Play Monopoly
./monopoly.ps1

# Play The Wizard's Castle
./The-Wizards-Castle.ps1

# Hunt the Wumpus
./hunt-the-wumpus.ps1

# Embark on The Oregon Trail
./oregon-trail.ps1

# Engage in Battleship naval combat
./battleship.ps1

# Stake Dracula in 1777
./draculaland.ps1

# Launch Moebius (Web & Retro UI)
./moebius.ps1
# or in WSL:
./moebius.sh

# Automated headless smoke tests
./monopoly.ps1 -SmokeTest
./hunt-the-wumpus.ps1 -SmokeTest
./oregon-trail.ps1 -SmokeTest
./battleship.ps1 -SmokeTest
./moebius.ps1 -SmokeTest
```

---

## 📁 Repository Structure

```text
├── monopoly.ps1            # Terminal Monopoly engine & AI opponent logic
├── The-Wizards-Castle.ps1  # The Wizard's Castle retro RPG dungeon crawler
├── hunt-the-wumpus.ps1     # Classic 1973 cave deduction game
├── oregon-trail.ps1        # 1848 frontier pioneer survival simulation
├── battleship.ps1          # 10x10 tactical naval combat with smart AI
├── draculaland.ps1         # Adventureland-style Dracula text adventure (1777)
├── moebius.ps1             # Moebius PowerShell cross-platform launcher
├── moebius.sh              # Moebius WSL bash launcher
├── moebius/                # Moebius retro web game engine & assets
│   ├── server.js           # Node.js HTTP server & REST save/load API
│   ├── test.js             # Headless automated unit test suite
│   ├── package.json        # NPM project definition
│   └── public/             # Static web assets & client scripts
│       ├── index.html      # Retro canvas viewport & HUD layout
│       ├── css/style.css   # CRT scanlines & bamboo border styling
│       ├── js/             # Audio, graphics, maps, combat, magic, divination engines
│       └── assets/         # 64x64 MTX maps, 31 chiptune tracks, sprites, manual
├── .private/               # Architecture & repository memory (git-ignored)
├── .gitignore              # Git ignore definitions
└── README.md               # Repository overview & manual
```

---

## 📜 License

MIT © [Daniel Kill](https://github.com/daniel-kill)
