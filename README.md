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

# Automated headless smoke tests
./monopoly.ps1 -SmokeTest
./hunt-the-wumpus.ps1 -SmokeTest
./oregon-trail.ps1 -SmokeTest
./battleship.ps1 -SmokeTest
```

---

## 📁 Repository Structure

```text
├── monopoly.ps1            # Terminal Monopoly engine & AI opponent logic
├── The-Wizards-Castle.ps1  # The Wizard's Castle retro RPG dungeon crawler
├── hunt-the-wumpus.ps1     # Classic 1973 cave deduction game
├── oregon-trail.ps1        # 1848 frontier pioneer survival simulation
├── battleship.ps1          # 10x10 tactical naval combat with smart AI
├── .private/               # Architecture & repository memory (git-ignored)
├── .gitignore              # Git ignore definitions
└── README.md               # Repository overview & manual
```

---

## 📜 License

MIT © [Daniel Kill](https://github.com/daniel-kill)
