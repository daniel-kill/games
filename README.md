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

## 🚀 Quick Start

Ensure PowerShell 7 (`pwsh`) or Windows PowerShell is installed.

```powershell
# Run the game with interactive opponent selection
./monopoly.ps1

# Start directly with 2 CPU opponents
./monopoly.ps1 -CpuCount 2

# Run headless automated smoke tests
./monopoly.ps1 -SmokeTest

# Display full rules & command options
./monopoly.ps1 -Help
```

---

## 📁 Repository Structure

```text
├── monopoly.ps1         # Terminal Monopoly engine & AI opponent logic
├── .private/            # Architecture & repository memory (ignored)
├── .gitignore           # Git ignore definitions
└── README.md            # Repository overview & manual
```

---

## 📜 License

MIT © [Daniel Kill](https://github.com/daniel-kill)
