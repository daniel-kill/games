/**
 * Moebius: The Orb of Celestial Harmony
 * Master Game Engine & Controller
 */

class MoebiusEngine {
  constructor() {
    this.canvas = document.getElementById('gameCanvas');
    this.graphics = new MoebiusGraphics(this.canvas);
    this.audio = new MoebiusAudio();
    this.maps = new MoebiusMaps();
    this.combat = new MoebiusCombat(this.audio);
    this.divination = new MoebiusDivination(this.audio);
    this.magic = new MoebiusMagic();
    this.ui = new MoebiusUI();

    this.gameState = 'TITLE'; // TITLE, PRELUDE, OVERWORLD, COMBAT, DIVINATION, VICTORY, GAME_OVER

    this.player = {
      name: 'Windwalker',
      realm: 'EARTH',
      x: 24,
      y: 24,
      body: 100,
      maxBody: 100,
      fatigue: 100,
      mind: 80,
      maxMind: 100,
      karma: 50,
      dexterity: 75,
      food: 35,
      water: 35,
      torches: 5,
      torchActive: false,
      whetstone: 3,
      shurikens: 12,
      swordEquipped: true,
      components: {
        incense: 3,
        lotus: 2,
        jade: 1,
        silk: 2,
        bell: 2,
        pearl: 1
      },
      activeSpells: {
        protection: 0,
        waterwalk: 0,
        invisibility: 0,
        spiritWalk: 0,
        wereSpell: 0
      },
      orbPieces: 0
    };

    this.stepCount = 0;
    this.titleTimer = 0;
    this.timeOfDay = 'DAY'; // DAWN, DAY, DUSK, NIGHT
    this.crtScanlines = true;

    this.keysDown = {};
  }

  async init() {
    await this.maps.init();
    this.setupEventListeners();
    this.ui.updateVitals(this.player, this.maps.currentRealm);
    this.ui.addMessage('Moebius: The Orb of Celestial Harmony initialized.', 'msg-good');
    this.ui.addMessage('Press SPACEBAR or click START to enter the House of Moebius.', 'msg-tao');

    // Start main game loop
    requestAnimationFrame(this.gameLoop.bind(this));
  }

  setupEventListeners() {
    // Keyboard listeners
    window.addEventListener('keydown', (e) => {
      this.audio.ensureContext();
      this.keysDown[e.key] = true;
      this.handleKeyDown(e);
    });

    window.addEventListener('keyup', (e) => {
      this.keysDown[e.key] = false;
    });

    // Tray buttons
    document.getElementById('btn-talk')?.addEventListener('click', () => this.triggerNearbyEncounter());
    document.getElementById('btn-prayer')?.addEventListener('click', () => this.openPrayerMenu());
    document.getElementById('btn-charm')?.addEventListener('click', () => this.openCharmMenu());
    document.getElementById('btn-meditate')?.addEventListener('click', () => this.startDivination());
    document.getElementById('btn-inventory')?.addEventListener('click', () => this.openInventory());
    document.getElementById('btn-attack')?.addEventListener('click', () => this.toggleSword());
    document.getElementById('btn-rest')?.addEventListener('click', () => this.restOrDrink());
    document.getElementById('btn-help')?.addEventListener('click', () => this.ui.showHelp());

    // Footer Controls
    document.getElementById('btn-toggle-crt')?.addEventListener('click', () => this.toggleCRT());
    document.getElementById('btn-toggle-palette')?.addEventListener('click', () => this.togglePalette());
    document.getElementById('btn-toggle-sound')?.addEventListener('click', () => this.toggleSound());
    document.getElementById('btn-save-game')?.addEventListener('click', () => this.saveGame());
    document.getElementById('btn-load-game')?.addEventListener('click', () => this.loadGame());
  }

  handleKeyDown(e) {
    if (this.gameState === 'TITLE') {
      if (e.key === ' ' || e.key === 'Enter') {
        this.gameState = 'PRELUDE';
        this.openPrelude();
      }
      return;
    }

    if (this.gameState === 'OVERWORLD') {
      let dx = 0;
      let dy = 0;

      if (e.key === 'ArrowUp' || e.key === 'w' || e.key === 'W') dy = -1;
      else if (e.key === 'ArrowDown' || e.key === 's' || e.key === 'S') dy = 1;
      else if (e.key === 'ArrowLeft' || e.key === 'a' || e.key === 'A') dx = -1;
      else if (e.key === 'ArrowRight' || e.key === 'd' || e.key === 'D') dx = 1;
      else if (e.key === 'p' || e.key === 'P') { this.openPrayerMenu(); return; }
      else if (e.key === 'c' || e.key === 'C') { this.openCharmMenu(); return; }
      else if (e.key === 'm' || e.key === 'M') { this.startDivination(); return; }
      else if (e.key === 'i' || e.key === 'I') { this.openInventory(); return; }
      else if (e.key === 't' || e.key === 'T') { this.triggerNearbyEncounter(); return; }
      else if (e.key === ' ') { this.triggerCombatEncounter(); return; }

      if (dx !== 0 || dy !== 0) {
        this.movePlayer(dx, dy);
      }
      return;
    }

    if (this.gameState === 'COMBAT') {
      // Combat commands
      if (e.key === ' ') {
        this.combat.handlePlayerInput('BLOCK', this.player);
      } else if (e.key === '7' || e.key === 'u' || e.key === 'U') {
        this.combat.handlePlayerInput('PUNCH_HIGH', this.player);
      } else if (e.key === '4' || e.key === 'j' || e.key === 'J') {
        this.combat.handlePlayerInput('PUNCH_MID', this.player);
      } else if (e.key === '1' || e.key === 'm' || e.key === 'M') {
        this.combat.handlePlayerInput('PUNCH_LOW', this.player);
      } else if (e.key === '9' || e.key === 'o' || e.key === 'O') {
        this.combat.handlePlayerInput('KICK_HIGH', this.player);
      } else if (e.key === '6' || e.key === 'l' || e.key === 'L') {
        this.combat.handlePlayerInput('KICK_MID', this.player);
      } else if (e.key === '3' || e.key === '.') {
        this.combat.handlePlayerInput('KICK_LOW', this.player);
      } else if (e.key === 'z' || e.key === 'Z') {
        this.combat.handlePlayerInput('STEP_BACK', this.player);
      } else if (e.key === 'x' || e.key === 'X') {
        this.combat.handlePlayerInput('STEP_FWD', this.player);
      } else if (e.key === 'a' || e.key === 'A') {
        this.combat.handlePlayerInput('STRIDE_BACK', this.player);
      } else if (e.key === 's' || e.key === 'S') {
        this.combat.handlePlayerInput('STRIDE_FWD', this.player);
      } else if (e.key === 't' || e.key === 'T') {
        this.combat.handlePlayerInput('THROW_SHURIKEN', this.player);
      } else if (e.key === 'w' || e.key === 'W') {
        this.combat.handlePlayerInput('TOGGLE_WEAPON', this.player);
      } else if (e.key === 'Escape' || e.key === 'Enter') {
        this.combat.handlePlayerInput('FLEE', this.player);
      }
      return;
    }

    if (this.gameState === 'DIVINATION') {
      if (e.key === 'ArrowUp' || e.key === 'w' || e.key === 'W') this.divination.applyForce(0, -1.2);
      if (e.key === 'ArrowDown' || e.key === 's' || e.key === 'S') this.divination.applyForce(0, 1.2);
      if (e.key === 'ArrowLeft' || e.key === 'a' || e.key === 'A') this.divination.applyForce(-1.2, 0);
      if (e.key === 'ArrowRight' || e.key === 'd' || e.key === 'D') this.divination.applyForce(1.2, 0);
      return;
    }
  }

  movePlayer(dx, dy) {
    const targetX = this.player.x + dx;
    const targetY = this.player.y + dy;

    if (!this.maps.isPassable(targetX, targetY, this.player)) {
      this.ui.addMessage('Your path is blocked by rugged terrain.', 'msg-alert');
      return;
    }

    // Check if an NPC is on target tile
    const npc = this.maps.getNPCAt(targetX, targetY);
    if (npc) {
      if (npc.hostile && this.player.activeSpells.invisibility <= 0) {
        this.ui.addMessage(`A prowling ${npc.type.toUpperCase()} ambushes you!`, 'msg-combat');
        this.startCombat(npc.type, npc.id);
        return;
      } else {
        this.ui.showConversation(npc, (action) => this.handleConversationAction(npc, action));
        return;
      }
    }

    this.player.x = targetX;
    this.player.y = targetY;
    this.stepCount++;
    this.audio.playStep();

    // Reveal fog of war
    this.maps.revealFog(this.player.x, this.player.y, 5);

    // Decrement active spell durations
    Object.keys(this.player.activeSpells).forEach(key => {
      if (this.player.activeSpells[key] > 0) {
        this.player.activeSpells[key]--;
        if (this.player.activeSpells[key] === 0) {
          this.ui.addMessage(`The enchantment of ${key.toUpperCase()} has dissipated.`, 'msg-alert');
        }
      }
    });

    // Advance Day/Night Cycle (0-300 step clock)
    const dayTick = this.stepCount % 300;
    if (dayTick < 120) this.timeOfDay = 'DAY';
    else if (dayTick < 150) this.timeOfDay = 'DUSK';
    else if (dayTick < 270) {
      this.timeOfDay = 'NIGHT';
      if (this.player.torchActive && this.stepCount % 50 === 0) {
        this.player.torches = Math.max(0, this.player.torches - 1);
        if (this.player.torches === 0) {
          this.player.torchActive = false;
          this.ui.addMessage('Your torch burns out into cold ash!', 'msg-alert');
        }
      }
    } else {
      this.timeOfDay = 'DAWN';
    }

    // Survival attrition every 16 steps
    if (this.stepCount % 16 === 0) {
      if (this.player.water > 0) this.player.water--;
      else {
        this.player.body = Math.max(0, this.player.body - 2);
        this.ui.addMessage('Thirst parches your throat! (-2 Body)', 'msg-alert');
      }

      if (this.stepCount % 32 === 0) {
        if (this.player.food > 0) this.player.food--;
        else {
          this.player.body = Math.max(0, this.player.body - 2);
          this.ui.addMessage('Hunger gnaws at your strength! (-2 Body)', 'msg-alert');
        }
      }
    }

    // Move wandering NPCs occasionally
    this.maps.moveNPCs();

    // Tile-specific triggers
    this.evaluateCurrentTile();

    // Check Death
    if (this.player.body <= 0) {
      this.triggerGameOver();
      return;
    }

    this.ui.updateVitals(this.player, this.maps.currentRealm);
  }

  evaluateCurrentTile() {
    const tile = this.maps.getTile(this.player.x, this.player.y);

    // Shrine (tile 7)
    if (tile === 7) {
      const res = this.maps.purifyShrineAt(this.player.x, this.player.y);
      if (res.success) {
        this.audio.playChant();
        this.player.karma = Math.min(100, this.player.karma + 12);
        this.player.body = Math.min(this.player.maxBody, this.player.body + 20);
        this.player.mind = Math.min(this.player.maxMind, this.player.mind + 20);
        this.ui.addMessage('✨ You have cleansed the defiled shrine of dark magic! (+Karma, +Mind)', 'msg-good');

        if (res.allClean) {
          this.audio.playFanfare();
          this.ui.addMessage('🌟 Both elemental shrines are purified! The Astral Gate now hums with cosmic power!', 'msg-good');
        }
      } else {
        this.ui.addMessage('You rest peacefully at the purified shrine.', 'msg-tao');
      }
      return;
    }

    // Cistern / Spring (tile 12)
    if (tile === 12) {
      this.audio.playWater();
      this.player.water = 35;
      this.player.fatigue = 100;
      this.player.body = Math.min(this.player.maxBody, this.player.body + 15);
      this.ui.addMessage('You drink deeply from the sacred cistern and refill your flask. (+Body, Fatigue restored)', 'msg-good');
      return;
    }

    // Cross / Ancestral Grave (tile 14)
    if (tile === 14) {
      this.ui.addMessage('You stand before the grave of a fallen master. Invoke the prayer "Speak with Dead" (Key P) to commune.', 'msg-tao');
      return;
    }

    // Astral Gate (tile 29)
    if (tile === 29) {
      if (this.maps.areAllShrinesPurified()) {
        this.transitionToNextRealm();
      } else {
        this.ui.addMessage('The Astral Gate is dormant. You must purify both defiled shrines in this realm first!', 'msg-alert');
      }
      return;
    }

    // Kaimen's Volcano Lair in Fire Realm
    if (this.maps.currentRealm === 'FIRE' && (tile === 42 || (this.player.x >= 30 && this.player.x <= 34 && this.player.y <= 18))) {
      this.startCombat('kaimen');
      return;
    }

    // Random hostile encounter (small chance on untamed terrain)
    if (Math.random() < 0.035 && this.player.activeSpells.invisibility <= 0) {
      const enemy = (this.maps.currentRealm === 'EARTH') ? 'tiger' :
                    (this.maps.currentRealm === 'WATER') ? 'guard' :
                    (this.maps.currentRealm === 'AIR') ? 'ninja' : 'cultist';
      this.startCombat(enemy);
    }
  }

  transitionToNextRealm() {
    this.audio.playFanfare();
    const realms = ['EARTH', 'WATER', 'AIR', 'FIRE'];
    const idx = realms.indexOf(this.maps.currentRealm);

    if (idx < realms.length - 1) {
      const nextRealm = realms[idx + 1];
      this.maps.currentRealm = nextRealm;
      this.player.realm = nextRealm;
      this.player.x = 20;
      this.player.y = 20;
      this.maps.spawnRealmNPCs();
      this.maps.revealFog(20, 20, 6);
      this.audio.playMusic(1, true);
      this.ui.addMessage(`🌀 You step through the Astral Gate and materialize in the REALM OF ${nextRealm}!`, 'msg-good');
      this.ui.updateVitals(this.player, nextRealm);
    } else {
      // Reached climax!
      this.ui.addMessage('You stand in the heart of the Fire Volcano. Warlord Kaimen awaits!', 'msg-alert');
      this.startCombat('kaimen');
    }
  }

  startCombat(enemyType, npcId = null) {
    this.gameState = 'COMBAT';
    this.combat.startCombat(this.player, enemyType);
    this.activeCombatNpcId = npcId;
  }

  startDivination() {
    if (this.player.mind < 15) {
      this.ui.addMessage('Your mental energy is exhausted. Rest before attempting divination.', 'msg-alert');
      return;
    }
    this.gameState = 'DIVINATION';
    this.divination.start();
    this.audio.playMusic(0, true);
    this.ui.addMessage('Enter the trance of Divination. Use Arrow Keys or WASD to center the Yin-Yang spirit.', 'msg-tao');
  }

  openPrelude() {
    this.ui.showPrelude(
      this.player.name,
      (chosenName) => {
        this.player.name = chosenName;
        this.gameState = 'OVERWORLD';
        this.audio.playMusic(1, true); // Temple theme
        this.maps.revealFog(this.player.x, this.player.y, 6);
        this.ui.addMessage(`Disciple ${chosenName}, your quest across the four realms begins!`, 'msg-good');
        this.ui.updateVitals(this.player, this.maps.currentRealm);
      },
      (trainingType) => {
        if (trainingType === 'SWORDS') {
          this.player.dexterity = Math.min(100, this.player.dexterity + 8);
          this.audio.playSwordClash();
          this.ui.addMessage('You practice swift sword katas. (+8 Dexterity)', 'msg-good');
        } else if (trainingType === 'MARTIAL') {
          this.player.fatigue = 100;
          this.player.maxBody = Math.min(120, this.player.maxBody + 5);
          this.player.body = this.player.maxBody;
          this.audio.playKick();
          this.ui.addMessage('You condition your body with rigorous martial exercises. (+5 Max Body)', 'msg-good');
        } else if (trainingType === 'DIVINATION') {
          this.startDivination();
        }
      }
    );
  }

  openPrayerMenu() {
    const cost = this.magic.getFastingCost(this.maps.currentRealm);
    this.ui.showPrayerMenu(this.magic.PRAYERS, cost, (prayerId) => {
      const res = this.magic.castPrayer(prayerId, this.player, this.maps.currentRealm, this.maps);
      if (res.success) {
        this.audio.playChant();
        this.ui.addMessage(res.message, 'msg-tao');
        this.ui.updateVitals(this.player, this.maps.currentRealm);
      } else {
        this.ui.addMessage(res.error, 'msg-alert');
      }
    });
  }

  openCharmMenu() {
    this.ui.showCharmMenu(this.magic.CHARMS, this.player.components, (charmId) => {
      const res = this.magic.castCharm(charmId, this.player, this.combat, this.maps);
      if (res.success) {
        this.audio.playFanfare();
        this.ui.addMessage(res.message, 'msg-good');
        this.ui.updateVitals(this.player, this.maps.currentRealm);
      } else {
        this.ui.addMessage(res.error, 'msg-alert');
      }
    });
  }

  openInventory() {
    this.ui.showInventory(this.player, (action) => {
      if (action === 'EAT') {
        if (this.player.food > 0) {
          this.player.food--;
          this.player.body = Math.min(this.player.maxBody, this.player.body + 18);
          this.ui.addMessage('You eat rice provisions. (+18 Body)', 'msg-good');
        } else {
          this.ui.addMessage('Your food sack is empty.', 'msg-alert');
        }
      } else if (action === 'DRINK') {
        if (this.player.water > 0) {
          this.player.water--;
          this.player.fatigue = Math.min(100, this.player.fatigue + 30);
          this.audio.playWater();
          this.ui.addMessage('You drink fresh water from your flask. (+30 Fatigue)', 'msg-good');
        } else {
          this.ui.addMessage('Your water flask is empty. Refill at a stream or cistern.', 'msg-alert');
        }
      } else if (action === 'TORCH') {
        if (this.player.torches > 0) {
          this.player.torchActive = true;
          this.ui.addMessage('You ignite a torch, casting light into the darkness.', 'msg-good');
        } else {
          this.ui.addMessage('You have no torches left.', 'msg-alert');
        }
      }
      this.ui.updateVitals(this.player, this.maps.currentRealm);
    });
  }

  triggerNearbyEncounter() {
    for (let dy = -1; dy <= 1; dy++) {
      for (let dx = -1; dx <= 1; dx++) {
        const npc = this.maps.getNPCAt(this.player.x + dx, this.player.y + dy);
        if (npc) {
          this.ui.showConversation(npc, (action) => this.handleConversationAction(npc, action));
          return;
        }
      }
    }
    this.ui.addMessage('No one is within speaking distance.', 'msg-alert');
  }

  handleConversationAction(npc, action) {
    if (action === 'BOW') {
      this.player.karma = Math.min(100, this.player.karma + 5);
      this.ui.addMessage(`You bow deeply with hands folded. The ${npc.type} returns the respectful greeting. (+5 Karma)`, 'msg-good');
    } else if (action === 'TALK') {
      const clues = [
        '"The defiled shrines emit a baleful violet miasma. Cleanse them to awaken the Astral Gate!"',
        '"A disciple must guard against exhaustion. Stand still or meditate to recover your breath."',
        '"Beware the night! Wild tigers hunt under the moon unless you keep a torch blazing."',
        '"Warlord Kaimen wields dark steel, but the purest heart conquers all."'
      ];
      const clue = clues[Math.floor(Math.random() * clues.length)];
      this.ui.addMessage(`The ${npc.type} speaks: ${clue}`, 'msg-tao');
    } else if (action === 'GIVE') {
      if (this.player.food > 0) {
        this.player.food--;
        this.player.karma = Math.min(100, this.player.karma + 8);
        this.player.components.incense++;
        this.ui.addMessage(`You gift provisions to the ${npc.type}. In gratitude, they bestow sacred Incense! (+Karma)`, 'msg-good');
      } else {
        this.ui.addMessage('You have no spare food to offer.', 'msg-alert');
      }
    } else if (action === 'ATTACK') {
      this.player.karma = Math.max(0, this.player.karma - 15);
      this.ui.addMessage(`You strike against a harmless ${npc.type}! Dishonor stains your spirit! (-15 Karma)`, 'msg-alert');
      this.startCombat(npc.type, npc.id);
    }
    this.ui.updateVitals(this.player, this.maps.currentRealm);
  }

  toggleSword() {
    this.player.swordEquipped = !this.player.swordEquipped;
    this.audio.playSwordClash();
    this.ui.addMessage(`Weapon: ${this.player.swordEquipped ? 'Katana Drawn' : 'Unarmed Stance'}`, 'msg-combat');
  }

  restOrDrink() {
    const tile = this.maps.getTile(this.player.x, this.player.y);
    if (tile === 12 || tile === 3) {
      this.player.water = 35;
      this.player.fatigue = 100;
      this.audio.playWater();
      this.ui.addMessage('You drink and refill your water flask to capacity.', 'msg-good');
    } else {
      this.player.fatigue = 100;
      this.ui.addMessage('You sit and rest your body, recovering all fatigue.', 'msg-good');
    }
    this.ui.updateVitals(this.player, this.maps.currentRealm);
  }

  toggleCRT() {
    this.crtScanlines = !this.crtScanlines;
    const vp = document.getElementById('viewport-container');
    if (this.crtScanlines) {
      vp.classList.remove('crt-scanlines-off');
    } else {
      vp.classList.add('crt-scanlines-off');
    }
  }

  togglePalette() {
    this.graphics.paletteMode = (this.graphics.paletteMode === 'C64') ? 'EGA' : 'C64';
    this.ui.addMessage(`Display Palette set to: ${this.graphics.paletteMode}`, 'msg-good');
  }

  toggleSound() {
    const muted = this.audio.toggleMute();
    this.ui.addMessage(`Audio: ${muted ? 'MUTED' : 'UNMUTED'}`, 'msg-good');
  }

  saveGame() {
    const state = {
      player: this.player,
      realm: this.maps.currentRealm,
      shrineStates: this.maps.shrineStates,
      stepCount: this.stepCount
    };

    // Save to LocalStorage
    localStorage.setItem('moebius_save', JSON.stringify(state));

    // Also persist to server REST API
    fetch('/api/save', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(state)
    }).then(r => r.json()).then(res => {
      this.ui.addMessage('Game saved successfully to disk and browser storage.', 'msg-good');
    }).catch(e => {
      this.ui.addMessage('Game saved to browser storage.', 'msg-good');
    });
  }

  loadGame() {
    const local = localStorage.getItem('moebius_save');
    if (local) {
      const data = JSON.parse(local);
      this.player = data.player;
      this.maps.currentRealm = data.realm;
      this.maps.shrineStates = data.shrineStates;
      this.stepCount = data.stepCount;
      this.gameState = 'OVERWORLD';
      this.ui.updateVitals(this.player, this.maps.currentRealm);
      this.ui.addMessage('Saved disciple journey restored.', 'msg-good');
      return;
    }

    fetch('/api/load').then(r => r.json()).then(data => {
      this.player = data.player;
      this.maps.currentRealm = data.realm;
      this.maps.shrineStates = data.shrineStates;
      this.stepCount = data.stepCount;
      this.gameState = 'OVERWORLD';
      this.ui.updateVitals(this.player, this.maps.currentRealm);
      this.ui.addMessage('Saved disciple journey loaded from server.', 'msg-good');
    }).catch(e => {
      this.ui.addMessage('No previous save file found.', 'msg-alert');
    });
  }

  triggerGameOver() {
    this.gameState = 'GAME_OVER';
    this.audio.playMusic(5, false); // Death/Elegy track
    this.ui.addMessage('Your physical body has perished. Your spirit dissolves into the celestial void.', 'msg-alert');
  }

  triggerVictory() {
    this.gameState = 'VICTORY';
    this.audio.playMusic(4, true); // Victory fanfare
    this.ui.addMessage('🏆 VICTORIOUS! You have defeated Warlord Kaimen and retrieved the ORB OF CELESTIAL HARMONY!', 'msg-good');
    this.ui.addMessage('Peace, balance, and the sacred Tao are restored to all four realms.', 'msg-tao');
  }

  // Master Render & Update Loop
  gameLoop() {
    this.titleTimer += 0.016;

    if (this.gameState === 'TITLE') {
      this.graphics.drawTitleScreen(this.titleTimer);
    } else if (this.gameState === 'OVERWORLD') {
      const grid = this.maps.getGrid();
      if (grid) {
        this.graphics.drawOverworld(
          grid,
          this.player.x,
          this.player.y,
          this.timeOfDay,
          this.player.torchActive,
          this.maps.currentRealm,
          this.maps.realmNPCs
        );
      }
    } else if (this.gameState === 'COMBAT') {
      const combatOutcome = this.combat.update(this.player);
      this.graphics.drawCombat(this.combat);

      if (combatOutcome) {
        if (combatOutcome.won) {
          if (combatOutcome.enemyType === 'kaimen') {
            this.triggerVictory();
          } else {
            this.gameState = 'OVERWORLD';
            this.player.karma = Math.min(100, this.player.karma + 10);
            this.player.shurikens += 2;
            if (this.activeCombatNpcId !== null) {
              this.maps.removeNPC(this.activeCombatNpcId);
            }
            this.audio.playMusic(1, true); // Return to exploration music
            this.ui.addMessage(`Vanquished the ${combatOutcome.enemyName}! (+10 Karma, +2 Shurikens)`, 'msg-good');
          }
        } else if (combatOutcome.reason === 'ESCAPED') {
          this.gameState = 'OVERWORLD';
          this.audio.playMusic(1, true);
        } else {
          this.triggerGameOver();
        }
        this.ui.updateVitals(this.player, this.maps.currentRealm);
      }
    } else if (this.gameState === 'DIVINATION') {
      const res = this.divination.update();
      this.graphics.drawDivination(
        this.divination.spiritX,
        this.divination.spiritY,
        this.divination.energy,
        this.divination.centeredTicks
      );

      if (res) {
        this.gameState = 'OVERWORLD';
        this.audio.playMusic(1, true);
        this.player.mind = Math.min(this.player.maxMind, this.player.mind + res.mindGain);
        this.player.karma = Math.min(100, this.player.karma + res.karmaGain);
        this.ui.addMessage(res.message, res.success ? 'msg-tao' : 'msg-alert');
        this.ui.updateVitals(this.player, this.maps.currentRealm);
      }
    } else if (this.gameState === 'GAME_OVER') {
      this.graphics.clear(0);
      this.graphics.ctx.fillStyle = '#ff0000';
      this.graphics.ctx.font = '16px monospace';
      this.graphics.ctx.textAlign = 'center';
      this.graphics.ctx.fillText('DISCIPLE HAS FALLEN', 160, 90);
      this.graphics.ctx.fillStyle = '#ffffff';
      this.graphics.ctx.font = '8px monospace';
      this.graphics.ctx.fillText('The Orb of Celestial Harmony remains lost.', 160, 115);
      this.graphics.ctx.fillText('Press SPACEBAR to return to the House of Moebius.', 160, 140);
      if (this.keysDown[' '] || this.keysDown['Enter']) {
        this.gameState = 'PRELUDE';
        this.player.body = 100;
        this.player.fatigue = 100;
        this.player.food = 35;
        this.player.water = 35;
        this.openPrelude();
      }
    } else if (this.gameState === 'VICTORY') {
      this.graphics.clear(0);
      this.graphics.ctx.fillStyle = '#eab308';
      this.graphics.ctx.font = '14px monospace';
      this.graphics.ctx.textAlign = 'center';
      this.graphics.ctx.fillText('THE ORB IS RESTORED', 160, 70);
      this.graphics.ctx.fillStyle = '#4ade80';
      this.graphics.ctx.font = '8px monospace';
      this.graphics.ctx.fillText('CELESTIAL HARMONY REIGNS ETERNAL', 160, 95);
      this.graphics.ctx.fillStyle = '#ffffff';
      this.graphics.ctx.fillText(`Honored Windwalker: ${this.player.name}`, 160, 120);
      this.graphics.ctx.fillText(`Final Karma: ${this.player.karma} | Dexterity: ${this.player.dexterity}`, 160, 135);
    }

    requestAnimationFrame(this.gameLoop.bind(this));
  }
}

window.addEventListener('DOMContentLoaded', () => {
  const engine = new MoebiusEngine();
  engine.init();
  window.moebiusGame = engine;
});
