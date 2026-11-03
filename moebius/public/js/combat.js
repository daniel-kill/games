/**
 * Moebius: The Orb of Celestial Harmony
 * Tactical Side-View Combat Engine (Martial Arts & Swordplay)
 */

class MoebiusCombat {
  constructor(audio) {
    this.audio = audio;
    this.inCombat = false;
    this.player = null;
    this.opponent = null;
    this.combatLog = [];
    this.shurikenProjectile = null;
  }

  startCombat(playerState, enemyType, enemyName = null) {
    this.inCombat = true;
    this.combatLog = [];
    this.shurikenProjectile = null;

    // Initialize Combat Player
    this.player = {
      name: playerState.name || 'Windwalker',
      x: 75,
      body: playerState.body,
      maxBody: playerState.maxBody || 100,
      fatigue: playerState.fatigue || 100,
      weapon: playerState.swordEquipped ? 'SWORD' : 'UNARMED',
      action: 'IDLE',
      actionTimer: 0,
      activeSpells: playerState.activeSpells || {}
    };

    // Determine enemy stats
    let oppBody = 50;
    let oppPower = 8;
    let name = enemyName || 'Palace Guard';

    if (enemyType === 'tiger') {
      name = 'Wild Golden Tiger';
      oppBody = 70;
      oppPower = 12;
    } else if (enemyType === 'ninja') {
      name = 'Shadow Ninja';
      oppBody = 60;
      oppPower = 10;
    } else if (enemyType === 'guard') {
      name = 'Warlord Sentry';
      oppBody = 65;
      oppPower = 9;
    } else if (enemyType === 'cultist') {
      name = 'Dark Acolyte';
      oppBody = 55;
      oppPower = 8;
    } else if (enemyType === 'kaimen') {
      name = 'Warlord Kaimen';
      oppBody = 150;
      oppPower = 18;
    }

    this.opponent = {
      name: name,
      type: enemyType,
      x: 235,
      body: oppBody,
      maxBody: oppBody,
      action: 'IDLE',
      actionTimer: 0,
      paralyzedTurns: 0,
      aiCooldown: 25,
      power: oppPower
    };

    this.addLog(`A hostile ${name} engages you in mortal combat!`);
    if (this.audio) {
      this.audio.playMusic(2, true); // Play combat track
    }
  }

  addLog(msg) {
    this.combatLog.unshift(msg);
    if (this.combatLog.length > 20) this.combatLog.pop();
  }

  handlePlayerInput(cmd, playerState) {
    if (!this.inCombat || this.player.actionTimer > 0) return;

    // Movement: Steps and Strides
    if (cmd === 'STEP_BACK') {
      this.player.x = Math.max(30, this.player.x - 12);
      this.player.fatigue = Math.max(0, this.player.fatigue - 3);
      if (this.audio) this.audio.playStep();
      return;
    }
    if (cmd === 'STEP_FWD') {
      this.player.x = Math.min(this.opponent.x - 30, this.player.x + 12);
      this.player.fatigue = Math.max(0, this.player.fatigue - 3);
      if (this.audio) this.audio.playStep();
      return;
    }
    if (cmd === 'STRIDE_BACK') {
      this.player.x = Math.max(20, this.player.x - 28);
      this.player.fatigue = Math.max(0, this.player.fatigue - 7);
      if (this.audio) this.audio.playStep();
      return;
    }
    if (cmd === 'STRIDE_FWD') {
      this.player.x = Math.min(this.opponent.x - 30, this.player.x + 28);
      this.player.fatigue = Math.max(0, this.player.fatigue - 7);
      if (this.audio) this.audio.playStep();
      return;
    }

    // Toggle Weapon
    if (cmd === 'TOGGLE_WEAPON') {
      this.player.weapon = (this.player.weapon === 'SWORD') ? 'UNARMED' : 'SWORD';
      this.addLog(`Readied ${this.player.weapon}.`);
      return;
    }

    // Defensive Block
    if (cmd === 'BLOCK') {
      this.player.action = 'BLOCK';
      this.player.actionTimer = 14;
      this.player.fatigue = Math.max(0, this.player.fatigue - 5);
      if (this.audio) this.audio.playBlock();
      return;
    }

    // Ranged Shuriken Throw
    if (cmd === 'THROW_SHURIKEN') {
      if (playerState.shurikens > 0) {
        playerState.shurikens--;
        this.shurikenProjectile = { x: this.player.x + 20, y: 100, vx: 9 };
        this.addLog('You hurl a sharp shuriken!');
        if (this.audio) this.audio.playShuriken();
      } else {
        this.addLog('You have no shurikens left!');
      }
      return;
    }

    // Break & Run (Escape)
    if (cmd === 'FLEE') {
      const dist = Math.abs(this.opponent.x - this.player.x);
      if (dist >= 90 || Math.random() < 0.55) {
        this.addLog('You disengage and escape the duel!');
        this.endCombat(false, 'ESCAPED');
      } else {
        this.addLog('Your retreat was cut off! The foe presses the assault!');
        this.player.fatigue = Math.max(0, this.player.fatigue - 15);
      }
      return;
    }

    // Strikes: High / Mid / Low Punch, Kick, or Swing
    if (['PUNCH_HIGH', 'PUNCH_MID', 'PUNCH_LOW', 'KICK_HIGH', 'KICK_MID', 'KICK_LOW', 'SWING'].includes(cmd)) {
      this.executePlayerStrike(cmd);
    }
  }

  executePlayerStrike(strikeType) {
    const isSword = (this.player.weapon === 'SWORD');
    const reach = isSword ? 62 : 46;
    const dist = Math.abs(this.opponent.x - this.player.x);

    this.player.action = strikeType;
    this.player.actionTimer = 12;

    const fatigueCost = isSword ? 14 : 9;
    this.player.fatigue = Math.max(0, this.player.fatigue - fatigueCost);

    if (dist <= reach) {
      // Hit connected!
      let baseDamage = isSword ? (14 + Math.floor(Math.random() * 8)) : (8 + Math.floor(Math.random() * 6));

      // Were-Spell damage multiplier
      if (this.player.activeSpells.wereSpell > 0) {
        baseDamage *= 2;
      }

      // Exhaustion penalty
      if (this.player.fatigue <= 10) {
        baseDamage = Math.floor(baseDamage * 0.5);
      }

      // Check if opponent blocked
      if (this.opponent.action === 'BLOCK') {
        const blockedDmg = Math.floor(baseDamage * 0.2);
        this.opponent.body -= blockedDmg;
        this.addLog(`The ${this.opponent.name} blocked your strike! (${blockedDmg} dmg)`);
        if (this.audio) this.audio.playBlock();
      } else {
        this.opponent.body -= baseDamage;
        this.addLog(`Your ${strikeType} strike lands true! (${baseDamage} dmg)`);
        if (this.audio) {
          if (isSword) this.audio.playSwordClash();
          else if (strikeType.startsWith('KICK')) this.audio.playKick();
          else this.audio.playPunch();
        }
      }
    } else {
      this.addLog(`Your ${strikeType} missed through empty air.`);
    }
  }

  update(playerState) {
    if (!this.inCombat) return null;

    // Passive Fatigue recovery
    if (this.player.action === 'IDLE') {
      this.player.fatigue = Math.min(100, this.player.fatigue + 0.35);
    }

    // Action timer decrements
    if (this.player.actionTimer > 0) {
      this.player.actionTimer--;
      if (this.player.actionTimer === 0) {
        this.player.action = 'IDLE';
      }
    }

    if (this.opponent.actionTimer > 0) {
      this.opponent.actionTimer--;
      if (this.opponent.actionTimer === 0) {
        this.opponent.action = 'IDLE';
      }
    }

    // Update Shuriken projectile
    if (this.shurikenProjectile) {
      this.shurikenProjectile.x += this.shurikenProjectile.vx;
      if (this.shurikenProjectile.x >= this.opponent.x) {
        // Projectile hit!
        const dmg = 24 + Math.floor(Math.random() * 12);
        this.opponent.body -= dmg;
        this.addLog(`The shuriken pierces your enemy! (${dmg} dmg)`);
        if (this.audio) this.audio.playSwordClash();
        this.shurikenProjectile = null;
      } else if (this.shurikenProjectile.x > 320) {
        this.shurikenProjectile = null;
      }
    }

    // Opponent Paralyzed check
    if (this.opponent.paralyzedTurns > 0) {
      this.opponent.paralyzedTurns--;
      this.opponent.action = 'IDLE';
    } else {
      // Opponent AI Update
      this.updateOpponentAI(playerState);
    }

    // Check Win/Loss conditions
    if (this.opponent.body <= 0) {
      this.addLog(`You have vanquished the ${this.opponent.name}!`);
      if (this.audio) this.audio.playFanfare();
      return this.endCombat(true, 'VICTORY');
    }

    if (this.player.body <= 0) {
      this.addLog('You have fallen in battle...');
      return this.endCombat(false, 'DEFEAT');
    }

    return null;
  }

  updateOpponentAI(playerState) {
    this.opponent.aiCooldown--;
    if (this.opponent.aiCooldown > 0) return;
    this.opponent.aiCooldown = 18 + Math.floor(Math.random() * 14);

    const dist = Math.abs(this.opponent.x - this.player.x);

    // If out of range, step forward
    if (dist > 55) {
      this.opponent.x = Math.max(this.player.x + 35, this.opponent.x - 14);
      return;
    }

    // If player is striking, high chance to block
    if (this.player.actionTimer > 0 && this.player.action !== 'BLOCK' && Math.random() < 0.5) {
      this.opponent.action = 'BLOCK';
      this.opponent.actionTimer = 14;
      if (this.audio) this.audio.playBlock();
      return;
    }

    // Counterattack!
    this.opponent.action = 'STRIKE';
    this.opponent.actionTimer = 14;

    let dmg = this.opponent.power + Math.floor(Math.random() * 6);

    // Protection prayer aura reduces damage by 50%
    if (this.player.activeSpells.protection > 0) {
      dmg = Math.floor(dmg * 0.5);
    }

    if (this.player.action === 'BLOCK') {
      const blockedDmg = Math.floor(dmg * 0.2);
      this.player.body -= blockedDmg;
      playerState.body = Math.max(0, this.player.body);
      this.addLog(`You blocked the enemy strike! (${blockedDmg} dmg)`);
      if (this.audio) this.audio.playBlock();
    } else {
      this.player.body -= dmg;
      playerState.body = Math.max(0, this.player.body);
      this.addLog(`The ${this.opponent.name} strikes you! (${dmg} dmg)`);
      if (this.audio) this.audio.playPunch();
    }
  }

  endCombat(won, reason) {
    this.inCombat = false;
    return {
      won: won,
      reason: reason,
      enemyType: this.opponent.type,
      enemyName: this.opponent.name,
      remainingBody: Math.max(0, this.player.body)
    };
  }
}

window.MoebiusCombat = MoebiusCombat;
