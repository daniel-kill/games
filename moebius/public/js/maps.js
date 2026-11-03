/**
 * Moebius: The Orb of Celestial Harmony
 * Realm Maps Engine (Authentic 64x64 Matrices: Earth, Water, Air, Fire)
 */

class MoebiusMaps {
  constructor() {
    this.mapsData = null;
    this.currentRealm = 'EARTH';
    this.fogOfWar = {
      EARTH: this.createEmptyGrid(64, 64, false),
      WATER: this.createEmptyGrid(64, 64, false),
      AIR: this.createEmptyGrid(64, 64, false),
      FIRE: this.createEmptyGrid(64, 64, false)
    };

    // Realm Shrines state: 2 tainted shrines per realm
    this.shrineStates = {
      EARTH: [
        { x: 30, y: 3, purified: false },
        { x: 50, y: 45, purified: false }
      ],
      WATER: [
        { x: 20, y: 15, purified: false },
        { x: 42, y: 38, purified: false }
      ],
      AIR: [
        { x: 12, y: 24, purified: false },
        { x: 52, y: 18, purified: false }
      ],
      FIRE: [
        { x: 28, y: 28, purified: false },
        { x: 48, y: 52, purified: false }
      ]
    };

    // Astral Gates locations
    this.gateLocations = {
      EARTH: { x: 30, y: 25 },
      WATER: { x: 32, y: 32 },
      AIR: { x: 28, y: 40 },
      FIRE: { x: 32, y: 16 } // Kaimen's Volcano Lair
    };

    // Active realm NPCs
    this.realmNPCs = [];
  }

  createEmptyGrid(w, h, val) {
    const arr = [];
    for (let y = 0; y < h; y++) {
      arr.push(new Array(w).fill(val));
    }
    return arr;
  }

  async init() {
    try {
      const res = await fetch('assets/maps_data.json');
      if (res.ok) {
        this.mapsData = await res.json();
      }
    } catch (err) {
      console.warn('Failed to load maps_data.json:', err);
    }
    this.spawnRealmNPCs();
  }

  getGrid(realm = this.currentRealm) {
    if (!this.mapsData || !this.mapsData[realm]) return null;
    return this.mapsData[realm].grid;
  }

  getTile(x, y, realm = this.currentRealm) {
    const grid = this.getGrid(realm);
    if (!grid || y < 0 || y >= 64 || x < 0 || x >= 64) return 0;
    return grid[y][x];
  }

  isPassable(x, y, playerState) {
    if (x < 0 || x >= 64 || y < 0 || y >= 64) return false;
    const tile = this.getTile(x, y);

    // Spirit Walk charm lets disciple walk through solid stone/walls
    if (playerState && playerState.activeSpells && playerState.activeSpells.spiritWalk > 0) {
      return true;
    }

    // Mountain crags
    if (tile === 4 || tile === 37) return false;

    // Deep water / streams
    if (tile === 3 || tile === 34 || tile === 35 || tile === 36) {
      // Waterwalk prayer active?
      if (playerState && playerState.activeSpells && playerState.activeSpells.waterwalk > 0) {
        return true;
      }
      return false;
    }

    // Sky abyss in Air realm
    if (this.currentRealm === 'AIR' && tile === 33) {
      if (playerState && playerState.activeSpells && playerState.activeSpells.waterwalk > 0) {
        return true;
      }
      return false;
    }

    // Palace walls (impassable except gate tile 22)
    if ((tile === 18 || tile === 19 || tile === 20 || tile === 21) && tile !== 22) {
      return false;
    }

    return true;
  }

  revealFog(px, py, radius = 5) {
    const fog = this.fogOfWar[this.currentRealm];
    for (let dy = -radius; dy <= radius; dy++) {
      for (let dx = -radius; dx <= radius; dx++) {
        const x = px + dx;
        const y = py + dy;
        if (x >= 0 && x < 64 && y >= 0 && y < 64) {
          fog[y][x] = true;
        }
      }
    }
  }

  isShrinePurified(shrineIdx, realm = this.currentRealm) {
    const shrines = this.shrineStates[realm];
    if (shrines && shrines[shrineIdx]) {
      return shrines[shrineIdx].purified;
    }
    return false;
  }

  areAllShrinesPurified(realm = this.currentRealm) {
    const shrines = this.shrineStates[realm];
    return shrines.every(s => s.purified);
  }

  purifyShrineAt(x, y) {
    const shrines = this.shrineStates[this.currentRealm];
    for (let s of shrines) {
      if (Math.abs(s.x - x) <= 1 && Math.abs(s.y - y) <= 1) {
        if (!s.purified) {
          s.purified = true;
          return { success: true, allClean: this.areAllShrinesPurified() };
        }
      }
    }
    return { success: false, alreadyClean: true };
  }

  spawnRealmNPCs() {
    this.realmNPCs = [];
    const count = 12;
    const grid = this.getGrid(this.currentRealm);
    if (!grid) return;

    const types = (this.currentRealm === 'EARTH') ? ['monk', 'peasant', 'tiger', 'guard'] :
                  (this.currentRealm === 'WATER') ? ['peasant', 'maiden', 'guard', 'ninja'] :
                  (this.currentRealm === 'AIR') ? ['monk', 'ninja', 'priest', 'guard'] :
                  ['guard', 'ninja', 'cultist'];

    for (let i = 0; i < count; i++) {
      let x = Math.floor(Math.random() * 54) + 5;
      let y = Math.floor(Math.random() * 54) + 5;
      const tile = grid[y][x];
      if (tile !== 4 && tile !== 37 && tile !== 3) {
        const type = types[i % types.length];
        this.realmNPCs.push({
          id: i,
          x: x,
          y: y,
          type: type,
          hostile: (type === 'tiger' || type === 'guard' || type === 'ninja' || type === 'cultist'),
          talked: false
        });
      }
    }
  }

  moveNPCs() {
    this.realmNPCs.forEach(npc => {
      if (Math.random() < 0.3) {
        const dx = Math.floor(Math.random() * 3) - 1;
        const dy = Math.floor(Math.random() * 3) - 1;
        const nx = npc.x + dx;
        const ny = npc.y + dy;
        if (nx >= 0 && nx < 64 && ny >= 0 && ny < 64) {
          const tile = this.getTile(nx, ny);
          if (tile !== 4 && tile !== 37 && tile !== 3) {
            npc.x = nx;
            npc.y = ny;
          }
        }
      }
    });
  }

  getNPCAt(x, y) {
    return this.realmNPCs.find(n => n.x === x && n.y === y);
  }

  removeNPC(id) {
    this.realmNPCs = this.realmNPCs.filter(n => n.id !== id);
  }
}

window.MoebiusMaps = MoebiusMaps;
