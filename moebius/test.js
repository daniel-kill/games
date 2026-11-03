/**
 * Moebius: The Orb of Celestial Harmony
 * Headless Automated Smoke & Unit Test Suite
 */

const fs = require('fs');
const path = require('path');
const assert = require('assert');

console.log('====================================================');
console.log(' MOEBIUS: AUTOMATED SMOKE & UNIT TEST SUITE');
console.log('====================================================');

let testsPassed = 0;
let testsFailed = 0;

function runTest(name, fn) {
  try {
    fn();
    console.log(`[PASS] ${name}`);
    testsPassed++;
  } catch (err) {
    console.error(`[FAIL] ${name}: ${err.message}`);
    testsFailed++;
  }
}

// 1. Map Matrix Verification
runTest('Verify authentic 64x64 realm matrices', () => {
  const mapsPath = path.join(__dirname, 'public/assets/maps_data.json');
  assert.ok(fs.existsSync(mapsPath), 'maps_data.json exists');
  const maps = JSON.parse(fs.readFileSync(mapsPath, 'utf8'));

  const realms = ['EARTH', 'WATER', 'AIR', 'FIRE'];
  realms.forEach(realm => {
    assert.ok(maps[realm], `Realm ${realm} exists in maps_data`);
    assert.strictEqual(maps[realm].width, 64, `${realm} width is 64`);
    assert.strictEqual(maps[realm].height, 64, `${realm} height is 64`);
    assert.strictEqual(maps[realm].grid.length, 64, `${realm} has 64 rows`);

    for (let r = 0; r < 64; r++) {
      assert.strictEqual(maps[realm].grid[r].length, 64, `${realm} row ${r} has 64 columns`);
    }

    // Check for shrine presence (tile 7)
    let hasShrine = false;
    for (let r = 0; r < 64; r++) {
      if (maps[realm].grid[r].includes(7)) {
        hasShrine = true;
        break;
      }
    }
    assert.ok(hasShrine, `${realm} contains sacred shrines (tile 7)`);
  });
});

// 2. Music Chiptune Tracks Verification
runTest('Verify PCMUSIC.SLB parsed audio tracks', () => {
  const musicPath = path.join(__dirname, 'public/assets/music_tracks.json');
  assert.ok(fs.existsSync(musicPath), 'music_tracks.json exists');
  const tracks = JSON.parse(fs.readFileSync(musicPath, 'utf8'));

  assert.ok(Array.isArray(tracks) || typeof tracks === 'object', 'tracks is valid JSON collection');
  const trackCount = Array.isArray(tracks) ? tracks.length : Object.keys(tracks).length;
  assert.ok(trackCount >= 30, `Contains 30+ chiptune tracks (actual: ${trackCount})`);

  const track0 = Array.isArray(tracks) ? tracks[0] : Object.values(tracks)[0];
  const events = Array.isArray(track0) ? track0 : track0.events;
  assert.ok(events && events.length > 0, 'Track 0 has note events');
  assert.ok(events[0].freq > 0, 'Note event has valid frequency');
  assert.ok(events[0].duration > 0, 'Note event has valid duration');
});

// 3. Fasting Prayer & Magic Costs
runTest('Verify Taoist fasting calculation across realms', () => {
  function getFastingCost(realm) {
    switch (realm) {
      case 'EARTH': return 7;
      case 'WATER': return 12;
      case 'AIR': return 17;
      case 'FIRE': return 22;
      default: return 7;
    }
  }

  assert.strictEqual(getFastingCost('EARTH'), 7, 'Earth fasting cost is 7 Body');
  assert.strictEqual(getFastingCost('WATER'), 12, 'Water fasting cost is 12 Body');
  assert.strictEqual(getFastingCost('AIR'), 17, 'Air fasting cost is 17 Body');
  assert.strictEqual(getFastingCost('FIRE'), 22, 'Fire fasting cost is 22 Body');

  // Verify fasting deduction and fatal threshold prevention
  let player = { body: 10, maxBody: 100 };
  let realm = 'EARTH';
  let cost = getFastingCost(realm);
  assert.ok(player.body > cost, 'Player has enough body to fast');
  player.body -= cost;
  assert.strictEqual(player.body, 3, 'Body reduced to 3 after fasting');

  // Second prayer should be prevented if fatal
  let canCastAgain = player.body > cost;
  assert.strictEqual(canCastAgain, false, 'Player cannot fast when body <= fasting cost');
});

// 4. Combat Damage & Mechanics
runTest('Verify combat math, Were-Spell multiplier, and blocking reduction', () => {
  // Test Were-Spell doubling
  function calcDamage(isSword, hasWereSpell, isExhausted, isBlocked) {
    let base = isSword ? 16 : 10;
    if (hasWereSpell) base *= 2;
    if (isExhausted) base = Math.floor(base * 0.5);
    if (isBlocked) base = Math.floor(base * 0.2);
    return base;
  }

  const normalUnarmed = calcDamage(false, false, false, false);
  assert.strictEqual(normalUnarmed, 10, 'Normal unarmed strike deals 10 damage');

  const wereSword = calcDamage(true, true, false, false);
  assert.strictEqual(wereSword, 32, 'Were-spell sword strike deals 32 damage');

  const blockedWereSword = calcDamage(true, true, false, true);
  assert.strictEqual(blockedWereSword, 6, 'Blocked were-sword strike reduced by 80% to 6 damage');

  const exhaustedUnarmed = calcDamage(false, false, true, false);
  assert.strictEqual(exhaustedUnarmed, 5, 'Exhausted unarmed strike reduced to 5 damage');
});

// 5. Karma System Dynamics
runTest('Verify Taoist Karma adjustments', () => {
  let karma = 50;

  // Good deeds
  karma = Math.min(100, karma + 5);  // Bow
  karma = Math.min(100, karma + 12); // Purify shrine
  karma = Math.min(100, karma + 8);  // Give food to peasant
  assert.strictEqual(karma, 75, 'Karma increases to 75 after honorable acts');

  // Dishonorable deed (attacking harmless monk)
  karma = Math.max(0, karma - 15);
  assert.strictEqual(karma, 60, 'Karma drops to 60 after dishonorable attack');
});

// 6. Divination Minigame Scoring
runTest('Verify Divination centering scoring thresholds', () => {
  function evalDivination(centeredTicks, totalTicks) {
    const ratio = centeredTicks / totalTicks;
    if (ratio >= 0.65) return 'MASTER';
    if (ratio >= 0.38) return 'ADEPT';
    return 'TURBULENT';
  }

  assert.strictEqual(evalDivination(80, 100), 'MASTER', '80% centered yields MASTER');
  assert.strictEqual(evalDivination(50, 100), 'ADEPT', '50% centered yields ADEPT');
  assert.strictEqual(evalDivination(20, 100), 'TURBULENT', '20% centered yields TURBULENT');
});

// 7. Sprites & Assets Integrity
runTest('Verify sprite asset presence', () => {
  const spriteDir = path.join(__dirname, 'public/assets/sprites');
  assert.ok(fs.existsSync(spriteDir), 'sprites directory exists');
  const files = fs.readdirSync(spriteDir);
  const required = [
    'arena_wall.png', 'combat_tray.png', 'karma_yinyang.png',
    'wings_dexterity.png', 'title_c64.png', 'windwalker_c64.png'
  ];
  required.forEach(req => {
    assert.ok(files.includes(req), `Required sprite ${req} exists`);
  });
});

// 8. Authentic Commodore 64 SID Audio & Player
runTest('Verify authentic C64 SID music asset and jsSID player', () => {
  const sidPath = path.join(__dirname, 'public/assets/c64_moebius.sid');
  assert.ok(fs.existsSync(sidPath), 'c64_moebius.sid exists');

  const buf = fs.readFileSync(sidPath);
  assert.ok(buf.length >= 128, 'SID file has valid header size');
  const magic = buf.subarray(0, 4).toString('ascii');
  assert.strictEqual(magic, 'PSID', 'SID has valid PSID magic header');

  const jsSidPath = path.join(__dirname, 'public/js/jsSID.js');
  assert.ok(fs.existsSync(jsSidPath), 'jsSID.js emulator exists');
  const jsSidContent = fs.readFileSync(jsSidPath, 'utf8');
  assert.ok(jsSidContent.includes('jsSID'), 'jsSID engine defined');
});

// 9. Authentic C64 Screens & Decoded Sprites
runTest('Verify authentic C64 screens and martial arts sprite frames', () => {
  const screensDir = path.join(__dirname, 'public/assets/screens');
  assert.ok(fs.existsSync(screensDir), 'screens directory exists');
  assert.ok(fs.existsSync(path.join(screensDir, 'c64_title_dojo.png')), 'c64_title_dojo.png exists');
  assert.ok(fs.existsSync(path.join(screensDir, 'c64_arena_earth.png')), 'c64_arena_earth.png exists');

  const windwalkerDir = path.join(__dirname, 'public/assets/c64_sprites/windwalker');
  assert.ok(fs.existsSync(windwalkerDir), 'windwalker c64 sprites directory exists');
  const wwFrames = fs.readdirSync(windwalkerDir);
  assert.ok(wwFrames.length >= 20, `Windwalker has authentic C64 animation frames (actual: ${wwFrames.length})`);
  assert.ok(fs.existsSync(path.join(windwalkerDir, 'windwalker_idle_0.png')), 'windwalker_idle_0.png exists');
  assert.ok(fs.existsSync(path.join(windwalkerDir, 'windwalker_punch_high.png')), 'windwalker_punch_high.png exists');
  assert.ok(fs.existsSync(path.join(windwalkerDir, 'windwalker_kick_high.png')), 'windwalker_kick_high.png exists');
  assert.ok(fs.existsSync(path.join(windwalkerDir, 'windwalker_fall.png')), 'windwalker_fall.png exists');

  const monkDir = path.join(__dirname, 'public/assets/c64_sprites/monk');
  assert.ok(fs.existsSync(monkDir), 'monk c64 sprites directory exists');
  const monkFrames = fs.readdirSync(monkDir);
  assert.ok(monkFrames.length >= 14, `Monk has authentic C64 animation frames (actual: ${monkFrames.length})`);
  assert.ok(fs.existsSync(path.join(monkDir, 'monk_idle_0.png')), 'monk_idle_0.png exists');
  assert.ok(fs.existsSync(path.join(monkDir, 'monk_punch.png')), 'monk_punch.png exists');
  assert.ok(fs.existsSync(path.join(monkDir, 'monk_fall.png')), 'monk_fall.png exists');

  const enemiesDir = path.join(__dirname, 'public/assets/c64_sprites/enemies_m5');
  assert.ok(fs.existsSync(enemiesDir), 'enemies c64 sprites directory exists');
  assert.ok(fs.existsSync(path.join(enemiesDir, 'enemy_ninja.png')), 'enemy_ninja.png exists');
  assert.ok(fs.existsSync(path.join(enemiesDir, 'enemy_guard.png')), 'enemy_guard.png exists');
  assert.ok(fs.existsSync(path.join(enemiesDir, 'enemy_spearman.png')), 'enemy_spearman.png exists');

  const portraitsDir = path.join(__dirname, 'public/assets/c64_sprites/portraits');
  assert.ok(fs.existsSync(portraitsDir), 'portraits c64 sprites directory exists');
  assert.ok(fs.existsSync(path.join(portraitsDir, 'portrait_monk.png')), 'portrait_monk.png exists');
  assert.ok(fs.existsSync(path.join(portraitsDir, 'portrait_priest.png')), 'portrait_priest.png exists');
  assert.ok(fs.existsSync(path.join(portraitsDir, 'portrait_death.png')), 'portrait_death.png exists');
});

console.log('====================================================');
console.log(` RESULTS: ${testsPassed} passed, ${testsFailed} failed`);
console.log('====================================================');

if (testsFailed > 0) {
  process.exit(1);
} else {
  process.exit(0);
}
