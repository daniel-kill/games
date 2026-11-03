# Moebius: The Orb of Celestial Harmony (1987) — Web & Retro Engine Recreation

> [!WARNING]
> ### ⚠️ Work-in-Progress / Incomplete Conversion Notice
> This project is an **active work-in-progress recreation and reverse-engineering conversion** of Origin Systems' classic 1987 martial arts RPG created by Greg Malone.
>
> While core engine subsystems—including authentic 64×64 elemental realm matrices, Commodore 64 SID 6581 music emulation, decompressed C64 martial arts animation frames, baseline-aligned combat, and Taoist meditation/fasting—are fully implemented and playable, **higher-level quest scripting, full NPC dialogue trees, palace dungeon delving, and endgame celestial recovery sequences are incomplete and actively under development**.

---

## 🥋 Project Overview

*Moebius: The Orb of Celestial Harmony* is a pioneering open-world martial arts RPG originally published by Origin Systems in 1987. Players assume the role of a martial arts disciple sent by the Master Moebius into the realms of **Earth, Water, Air, and Fire** to recover the stolen Orb of Celestial Harmony from the treacherous warlord Kzo.

This recreation aims for maximum historical authenticity by extracting and executing original Commodore 64 and MS-DOS game assets directly in modern cross-platform environments (WSL and modern web browsers).

---

## 🚧 Conversion & Implementation Status

| Subsystem | Status | Description |
|---|---|---|
| **64×64 Realm Maps** | ✅ Complete | 100% authentic matrices extracted from original `EARTH.MTX`, `WATER.MTX`, `AIR.MTX`, `FIRE.MTX` disk files. |
| **C64 SID Audio Engine** | ✅ Complete | Real-time Commodore 64 SID 6581 sound synthesis using `jsSID` playing Joe Garrett's authentic 1987 score (`c64_moebius.sid`). |
| **PC Chiptune Synthesis** | ✅ Complete | 31 synthesized tracks parsed from `PCMUSIC.SLB` with Web Audio API procedural fallback. |
| **C64 Martial Arts Sprites** | ✅ Complete | Custom C64 RLE 8×8 character cell graphics decompressed from `M10.prg` (Windwalker), `M11.prg` (Monk), and `M5`/`M6`/`M9`/`M10` (Enemies). |
| **Ground Baseline Alignment** | ✅ Complete | Dynamic vertical alignment (`groundY = 132`) ensuring standing (72px), crouching (48px), and floor knockdowns (24px) remain grounded. |
| **Divination Meditation** | ✅ Complete | Interactive Yin-Yang spiritual balance minigame with momentum physics and Mind energy restoration. |
| **Taoist Magic & Fasting** | ✅ Complete | 5 Fasting prayers (Speak with Dead, Protection, Waterwalk, Cure Sickness, Guiding Light) and 6 component charms (Ventriloquism, Paralysis, Teleport, Invisibility, Spirit Walk, Were-Spell). |
| **Tactical 1-on-1 Combat** | 🟡 Work-in-Progress | 6 attack zones (High/Mid/Low Kick, Punch, Swing), blocking, fatigue management, and shuriken projectiles are working; advanced opponent combat AI is being refined. |
| **NPC Interaction & Dialogue** | 🟡 Work-in-Progress | Modal conversation interface implemented; full binary dialogue trees and branching conversations from original disk images are being decoded. |
| **Palace Dungeons & Maze Delving** | ⏳ Incomplete / Planned | First-person palace interior navigation and dungeon puzzles are planned for future milestones. |
| **Full Story & Endgame Objectives** | ⏳ Incomplete / Planned | Warlord confrontation, recovery of the Orb of Celestial Harmony, and victory scrolls are in development. |

---

## 🔬 Reverse-Engineering Insights

1. **MTX Overworld Matrices:**
   - The four realms each reside in a contiguous 4,096-byte array forming a 64×64 tile grid.
   - Tiles correspond to mountains, forests, rice paddies, rivers, temples, walls, and cisterns.

2. **Custom Commodore 64 Sprite Format:**
   - Contrary to standard 64-byte hardware sprites, Moebius uses a custom, highly optimized RLE-compressed 8×8 character cell format.
   - Header pointer tables store 16-bit relative offsets to each frame.
   - Each frame specifies width cells (`w_cells`), height cells (`h_cells`), and a dynamic RLE escape byte.
   - Bit 0 indicates foreground pixels while Bit 1 indicates transparency.

3. **Audio Architecture:**
   - Emulates the MOS Technology 6581 SID chip directly in the browser via Web Audio script processor (`jsSID`).
   - Supports switching on the fly between C64 SID music and EGA/PC-speaker synthesized tracks.

---

## 🕹️ Controls & Keyboard Shortcuts

### Overworld Navigation
| Key | Action |
|---|---|
| **W / A / S / D** or **Arrow Keys** | Move North, West, South, East |
| **P** | Open Fasting Prayers menu |
| **C** | Open Component Charms menu |
| **M** | Enter Divination meditation |
| **I** | Inspect Pouch (provisions, items, karma) |
| **W** | Toggle barehand / sword weapon |
| **?** | View instruction scroll |

### Tactical Combat
| Key | Action |
|---|---|
| **A / D** or **Left / Right** | Advance toward / retreat from opponent |
| **B** or **Down Arrow** | Defensive Block |
| **7 / 8 / 9** | High Kick / High Punch / High Swing |
| **4 / 5 / 6** | Mid Kick / Mid Punch / Mid Swing |
| **1 / 2 / 3** | Low Kick / Low Punch / Low Swing |
| **S** | Throw Shuriken projectile |

---

## 🚀 Running the Game

### Prerequisites
- Node.js (v18+) or WSL (Ubuntu / Debian with Node.js)
- Modern web browser (Chrome, Edge, Firefox)

### From Windows PowerShell:
```powershell
# Launch web server and open browser
./moebius.ps1

# Run automated headless smoke test suite
./moebius.ps1 -SmokeTest
```

### From WSL / Linux Bash:
```bash
# Launch web server
./moebius.sh

# Run automated test suite
./moebius.sh --test
```

---

## 📜 Original Authors & Credits
- **Original Game Design & Programming:** Greg Malone (Origin Systems, Inc., 1987)
- **Original Commodore 64 Music & Sound:** Joe Garrett
- **Recreation & Reverse-Engineering:** [Daniel Kill](https://github.com/daniel-kill)
