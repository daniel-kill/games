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

## 🚀 Quick Start

Ensure PowerShell 7 (`pwsh`) or Windows PowerShell is installed.

```powershell
# Play Monopoly
./monopoly.ps1

# Play The Wizard's Castle
./The-Wizards-Castle.ps1

# Run automated smoke test for Monopoly
./monopoly.ps1 -SmokeTest
```

---

## 📁 Repository Structure

```text
├── monopoly.ps1            # Terminal Monopoly engine & AI opponent logic
├── The-Wizards-Castle.ps1  # The Wizard's Castle retro RPG dungeon crawler
├── .private/               # Architecture & repository memory (ignored)
├── .gitignore              # Git ignore definitions
└── README.md               # Repository overview & manual
```

---

## 📜 License

MIT © [Daniel Kill](https://github.com/daniel-kill)
