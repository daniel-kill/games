/**
 * Moebius: The Orb of Celestial Harmony
 * Magic System: Taoist Fasting Prayers & Component-Based Charms
 */

class MoebiusMagic {
  constructor() {
    this.PRAYERS = [
      {
        id: 'SPEAK_WITH_DEAD',
        name: 'Speak with Dead',
        desc: 'Commune with ancient spirits resting in holy cross tombs.',
        needTarget: 'CROSS'
      },
      {
        id: 'PROTECTION',
        name: 'Protection',
        desc: 'Envelops the disciple in an ethereal shield, halving damage.',
        duration: 25
      },
      {
        id: 'WATERWALK',
        name: 'Waterwalk',
        desc: 'Tread lightly upon streams, oceans, and airy abysses.',
        duration: 35
      },
      {
        id: 'CURE_SICKNESS',
        name: 'Cure Sickness',
        desc: 'Purges venom, disease, and restores depleted stamina.',
        duration: 0
      },
      {
        id: 'GUIDING_LIGHT',
        name: 'Guiding Light',
        desc: 'A celestial beam reveals the bearing to the nearest defiled shrine.',
        duration: 0
      }
    ];

    this.CHARMS = [
      {
        id: 'VENTRILOQUISM',
        name: 'Ventriloquism',
        component: 'incense',
        desc: 'Projects vocal illusions to divert hostile sentries and beasts.'
      },
      {
        id: 'PARALYSIS',
        name: 'Paralysis',
        component: 'lotus',
        desc: 'Casts a binding mist that freezes your combat foe for several turns.'
      },
      {
        id: 'TELEPORT',
        name: 'Teleport',
        component: 'jade',
        desc: 'Instant spiritual transmigration back to the realm sanctuary.'
      },
      {
        id: 'INVISIBILITY',
        name: 'Invisibility',
        component: 'silk',
        duration: 35,
        desc: 'Unseen by mortal eyes, slipping past patrols and prowling beasts.'
      },
      {
        id: 'SPIRIT_WALK',
        name: 'Spirit Walk',
        component: 'bell',
        duration: 18,
        desc: 'Permeate solid mountain stone and fortress masonry as a phantom.'
      },
      {
        id: 'WERE_SPELL',
        name: 'Were-Spell',
        component: 'pearl',
        duration: 30,
        desc: 'Awaken the ferocity of the golden tiger, doubling all strike power!'
      }
    ];
  }

  // Fasting cost across realms
  getFastingCost(realm) {
    switch (realm) {
      case 'EARTH': return 7;
      case 'WATER': return 12;
      case 'AIR': return 17;
      case 'FIRE': return 22;
      default: return 7;
    }
  }

  castPrayer(prayerId, player, realm, mapEngine) {
    const cost = this.getFastingCost(realm);
    if (player.body <= cost) {
      return { success: false, error: `You are too weak to fast (${cost} Body required). Meditation would prove fatal!` };
    }

    // Deduct fasting body
    player.body -= cost;

    const prayer = this.PRAYERS.find(p => p.id === prayerId);
    if (!prayer) return { success: false, error: 'Unknown prayer.' };

    if (prayerId === 'SPEAK_WITH_DEAD') {
      const tile = mapEngine.getTile(player.x, player.y);
      // Check surrounding tiles for Cross (tile 14)
      let foundCross = false;
      for (let dy = -1; dy <= 1; dy++) {
        for (let dx = -1; dx <= 1; dx++) {
          if (mapEngine.getTile(player.x + dx, player.y + dy) === 14) {
            foundCross = true;
            break;
          }
        }
      }

      if (!foundCross) {
        return { success: true, prayerName: prayer.name, fastingCost: cost, message: 'You chant the ancient elegy, but no restless spirit answers from the empty soil.' };
      }

      const spiritMessages = [
        '"Heed well, disciple of Moebius: Kaimen has defiled the two shrines to seal the Astral Gate. Cleanse them both with water of the sacred cistern!"',
        '"The sword is swift, but a peaceful heart accumulates great Karma. Slay only those who seek your blood!"',
        '"Beyond the Realm of Earth lies the watery ocean of trials. Prepare your spirit to walk upon water!"',
        '"In the Realm of Fire, within the roaring volcano, Kaimen guards the Orb of Celestial Harmony. Strike high when he sweeps low!"'
      ];
      const spiritMsg = spiritMessages[Math.floor(Math.random() * spiritMessages.length)];
      player.karma = Math.min(100, player.karma + 4);
      return { success: true, prayerName: prayer.name, fastingCost: cost, message: `The spirit awakens: ${spiritMsg}` };
    }

    if (prayerId === 'PROTECTION') {
      player.activeSpells.protection = prayer.duration;
      return { success: true, prayerName: prayer.name, fastingCost: cost, message: 'A shimmering aura of celestial light envelopes your physical form, deflecting harm.' };
    }

    if (prayerId === 'WATERWALK') {
      player.activeSpells.waterwalk = prayer.duration;
      return { success: true, prayerName: prayer.name, fastingCost: cost, message: 'Your feet feel weightless as mountain air. You may now tread upon rivers and the deep sea.' };
    }

    if (prayerId === 'CURE_SICKNESS') {
      player.fatigue = 100;
      return { success: true, prayerName: prayer.name, fastingCost: cost, message: 'A cleansing warmth purges your veins. Fatigue and toxins dissolve into harmony.' };
    }

    if (prayerId === 'GUIDING_LIGHT') {
      // Find nearest unpurified shrine
      const shrines = mapEngine.shrineStates[realm] || [];
      const unpurified = shrines.filter(s => !s.purified);
      if (unpurified.length > 0) {
        const s = unpurified[0];
        const dx = s.x - player.x;
        const dy = s.y - player.y;
        const dir = (Math.abs(dx) > Math.abs(dy)) ? (dx > 0 ? 'East' : 'West') : (dy > 0 ? 'South' : 'North');
        const dist = Math.round(Math.hypot(dx, dy));
        return { success: true, prayerName: prayer.name, fastingCost: cost, message: `A glowing golden dove arcs into the sky, pointing ${dir} toward a defiled shrine (~${dist} paces away).` };
      } else {
        const gate = mapEngine.gateLocations[realm];
        const dx = gate.x - player.x;
        const dy = gate.y - player.y;
        const dir = (Math.abs(dx) > Math.abs(dy)) ? (dx > 0 ? 'East' : 'West') : (dy > 0 ? 'South' : 'North');
        return { success: true, prayerName: prayer.name, fastingCost: cost, message: `All shrines in this realm are purified! The beacon points ${dir} to the Astral Gate.` };
      }
    }

    return { success: true, prayerName: prayer.name, fastingCost: cost, message: 'Prayer concluded.' };
  }

  castCharm(charmId, player, combatEngine, mapEngine) {
    const charm = this.CHARMS.find(c => c.id === charmId);
    if (!charm) return { success: false, error: 'Unknown charm.' };

    const comp = charm.component;
    if (!player.components[comp] || player.components[comp] <= 0) {
      return { success: false, error: `You lack the sacred component: ${comp.toUpperCase()}!` };
    }

    // Consume component
    player.components[comp]--;

    if (charmId === 'VENTRILOQUISM') {
      return { success: true, charmName: charm.name, message: 'You cast a phantom whisper into the distance. Hostile attention wanders away!' };
    }

    if (charmId === 'PARALYSIS') {
      if (combatEngine && combatEngine.inCombat) {
        combatEngine.opponent.paralyzedTurns = 6;
        return { success: true, charmName: charm.name, message: 'A fragrant lotus pollen envelops your foe, freezing them motionless!' };
      }
      return { success: true, charmName: charm.name, message: 'The pollen drifts uselessly into the empty air.' };
    }

    if (charmId === 'TELEPORT') {
      player.x = 24;
      player.y = 24;
      return { success: true, charmName: charm.name, message: 'The jade amulet shatters in a flash of jade lightning! You materialize at the realm sanctuary.' };
    }

    if (charmId === 'INVISIBILITY') {
      player.activeSpells.invisibility = charm.duration;
      return { success: true, charmName: charm.name, message: 'You wrap the silk ribbon around your brow. Your earthly silhouette vanishes from sight!' };
    }

    if (charmId === 'SPIRIT_WALK') {
      player.activeSpells.spiritWalk = charm.duration;
      return { success: true, charmName: charm.name, message: 'The bronze bell tolls deeply. Your body dissolves into spirit, capable of stepping through stone and walls!' };
    }

    if (charmId === 'WERE_SPELL') {
      player.activeSpells.wereSpell = charm.duration;
      return { success: true, charmName: charm.name, message: 'The dragon pearl flares crimson! Primal beast energy courses through your fists, doubling your strike power!' };
    }

    return { success: true, charmName: charm.name, message: 'Charm completed.' };
  }
}

window.MoebiusMagic = MoebiusMagic;
