/**
 * Moebius: The Orb of Celestial Harmony
 * Authentic Retro Canvas Graphics & Sprite Engine (320x200)
 */

class MoebiusGraphics {
  constructor(canvas) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.width = 320;
    this.height = 200;
    this.canvas.width = this.width;
    this.canvas.height = this.height;

    // Palette Mode: 'C64' or 'EGA'
    this.paletteMode = 'C64';

    this.C64_PALETTE = [
      '#000000', '#ffffff', '#880000', '#aaffee',
      '#cc44cc', '#00cc55', '#0000aa', '#eeee77',
      '#dd8855', '#664400', '#ff7777', '#333333',
      '#777777', '#aaff66', '#0088ff', '#bbbbbb'
    ];

    this.EGA_PALETTE = [
      '#000000', '#0000aa', '#00aa00', '#00aaaa',
      '#aa0000', '#aa00aa', '#aa5500', '#aaaaaa',
      '#555555', '#5555ff', '#55ff55', '#55ffff',
      '#ff5555', '#ff55ff', '#ffff55', '#ffffff'
    ];

    // Image Sprites
    this.sprites = {};
    this.spritesLoaded = false;
    this.loadSprites();

    // Tile cache
    this.animTimer = 0;
  }

  get palette() {
    return this.paletteMode === 'C64' ? this.C64_PALETTE : this.EGA_PALETTE;
  }

  loadSprites() {
    const spriteNames = [
      'windwalker_c64', 'windwalker_dos', 'arena_wall', 'combat_tray',
      'overworld_tray', 'karma_yinyang', 'wings_dexterity', 'tile_tiger',
      'cross_skeleton', 'divination_box', 'divination_hand', 'title_c64',
      'portrait_guard', 'portrait_maiden', 'portrait_monk', 'portrait_ninja',
      'portrait_peasant', 'portrait_priest'
    ];

    let loaded = 0;
    spriteNames.forEach(name => {
      const img = new Image();
      img.src = `assets/sprites/${name}.png`;
      img.onload = () => {
        this.sprites[name] = img;
        loaded++;
        if (loaded >= spriteNames.length) {
          this.spritesLoaded = true;
        }
      };
      img.onerror = () => {
        loaded++;
      };
    });

    // Authentic Commodore 64 Screens
    const c64Screens = [
      { key: 'c64_title_dojo', src: 'assets/screens/c64_title_dojo.png' },
      { key: 'c64_arena_earth', src: 'assets/screens/c64_arena_earth.png' },
      { key: 'c64_arena_water', src: 'assets/screens/c64_arena_water.png' },
      { key: 'c64_arena_air', src: 'assets/screens/c64_arena_air.png' }
    ];
    c64Screens.forEach(sc => {
      const img = new Image();
      img.src = sc.src;
      img.onload = () => { this.sprites[sc.key] = img; };
    });

    // Authentic Commodore 64 Windwalker Martial Arts Animation Frames
    const c64PlayerMoves = [
      { key: 'windwalker_idle_0', src: 'assets/c64_sprites/windwalker/frame_00.png' },
      { key: 'windwalker_idle_1', src: 'assets/c64_sprites/windwalker/frame_01.png' },
      { key: 'windwalker_punch_high', src: 'assets/c64_sprites/windwalker/frame_08.png' },
      { key: 'windwalker_punch_mid', src: 'assets/c64_sprites/windwalker/frame_10.png' },
      { key: 'windwalker_punch_low', src: 'assets/c64_sprites/windwalker/frame_14.png' },
      { key: 'windwalker_kick_high', src: 'assets/c64_sprites/windwalker/frame_16.png' },
      { key: 'windwalker_kick_mid', src: 'assets/c64_sprites/windwalker/frame_18.png' },
      { key: 'windwalker_kick_low', src: 'assets/c64_sprites/windwalker/frame_20.png' },
      { key: 'windwalker_block', src: 'assets/c64_sprites/windwalker/frame_26.png' },
      { key: 'windwalker_swing', src: 'assets/c64_sprites/windwalker/frame_38.png' },
      { key: 'windwalker_hit', src: 'assets/c64_sprites/windwalker/frame_52.png' },
      { key: 'windwalker_fall', src: 'assets/c64_sprites/windwalker/frame_68.png' }
    ];
    c64PlayerMoves.forEach(mv => {
      const img = new Image();
      img.src = mv.src;
      img.onload = () => { this.sprites[mv.key] = img; };
    });

    // Authentic Commodore 64 Sparring Monk / Opponent Animation Frames
    const c64MonkMoves = [
      { key: 'monk_idle_0', src: 'assets/c64_sprites/monk/frame_00.png' },
      { key: 'monk_idle_1', src: 'assets/c64_sprites/monk/frame_01.png' },
      { key: 'monk_punch', src: 'assets/c64_sprites/monk/frame_08.png' },
      { key: 'monk_kick', src: 'assets/c64_sprites/monk/frame_16.png' },
      { key: 'monk_block', src: 'assets/c64_sprites/monk/frame_26.png' },
      { key: 'monk_swing', src: 'assets/c64_sprites/monk/frame_38.png' },
      { key: 'monk_hit', src: 'assets/c64_sprites/monk/frame_52.png' },
      { key: 'monk_fall', src: 'assets/c64_sprites/monk/frame_68.png' }
    ];
    c64MonkMoves.forEach(mv => {
      const img = new Image();
      img.src = mv.src;
      img.onload = () => { this.sprites[mv.key] = img; };
    });

    // Authentic Commodore 64 Enemies
    const c64Enemies = [
      { key: 'enemy_ninja', src: 'assets/c64_sprites/enemies_m5/frame_00.png' },
      { key: 'enemy_guard', src: 'assets/c64_sprites/enemies_m5/frame_24.png' },
      { key: 'enemy_tiger', src: 'assets/c64_sprites/enemies_m5/frame_40.png' }
    ];
    c64Enemies.forEach(en => {
      const img = new Image();
      img.src = en.src;
      img.onload = () => { this.sprites[en.key] = img; };
    });
  }

  clear(colorIdx = 0) {
    this.ctx.fillStyle = this.palette[colorIdx];
    this.ctx.fillRect(0, 0, this.width, this.height);
  }

  // --- Title Screen Renderer ---
  drawTitleScreen(timer) {
    this.clear(0);
    const pal = this.palette;

    // Authentic C64 Title Screen Background
    if (this.sprites['c64_title_dojo']) {
      this.ctx.drawImage(this.sprites['c64_title_dojo'], 0, 0, 320, 130);
    } else if (this.sprites['title_c64']) {
      this.ctx.fillStyle = pal[9]; // Brown
      this.ctx.fillRect(4, 4, 312, 192);
      this.ctx.fillStyle = pal[0]; // Black
      this.ctx.fillRect(8, 8, 304, 184);
      this.ctx.drawImage(this.sprites['title_c64'], 16, 12, 288, 110);
    } else {
      // Outer decorative bamboo frame
      this.ctx.fillStyle = pal[9]; // Brown
      this.ctx.fillRect(4, 4, 312, 192);
      this.ctx.fillStyle = pal[0]; // Black
      this.ctx.fillRect(8, 8, 304, 184);

      // Procedural title fallback
      this.ctx.fillStyle = pal[7]; // Yellow
      this.ctx.font = '16px monospace';
      this.ctx.textAlign = 'center';
      this.ctx.fillText('M O E B I U S', 160, 50);
      this.ctx.fillStyle = pal[1];
      this.ctx.font = '8px monospace';
      this.ctx.fillText('THE ORB OF CELESTIAL HARMONY', 160, 70);
    }

    // Bottom banner
    this.ctx.fillStyle = pal[0];
    this.ctx.fillRect(0, 130, 320, 70);
    this.ctx.fillStyle = pal[11];
    this.ctx.fillRect(0, 130, 320, 2);

    // Credits & Instructions
    this.ctx.textAlign = 'center';
    this.ctx.font = '8px monospace';
    this.ctx.fillStyle = pal[13]; // Light Green
    this.ctx.fillText('ORIGIN SYSTEMS (1987) / GREG MALONE • COMMODORE 64', 160, 146);

    // Flashing Press Start
    if (Math.floor(timer * 2) % 2 === 0) {
      this.ctx.fillStyle = pal[1]; // White
      this.ctx.fillText('PRESS SPACEBAR OR ENTER TO BEGIN', 160, 164);
    }

    this.ctx.fillStyle = pal[15]; // Light Gray
    this.ctx.fillText('Swordsmanship • Martial Arts • Divination', 160, 180);
  }

  // --- Overworld Viewport Renderer (11x11 Grid centered on Player) ---
  drawOverworld(mapGrid, playerX, playerY, timeOfDay, hasTorch, realmName, npcs = []) {
    const pal = this.palette;
    this.animTimer++;
    const shimmer = Math.floor(this.animTimer / 15) % 2 === 0;

    // Viewport window: 11x11 tiles, each 18x16 pixels
    const tileW = 18;
    const tileH = 16;
    const startX = 14;
    const startY = 12;

    // Viewport border
    this.ctx.fillStyle = pal[9]; // Brown
    this.ctx.fillRect(startX - 2, startY - 2, (11 * tileW) + 4, (11 * tileH) + 4);
    this.ctx.fillStyle = pal[0];
    this.ctx.fillRect(startX, startY, 11 * tileW, 11 * tileH);

    for (let dy = -5; dy <= 5; dy++) {
      for (let dx = -5; dx <= 5; dx++) {
        const mx = playerX + dx;
        const my = playerY + dy;
        const screenX = startX + (dx + 5) * tileW;
        const screenY = startY + (dy + 5) * tileH;

        if (mx < 0 || mx >= 64 || my < 0 || my >= 64) {
          // Out of bounds
          this.ctx.fillStyle = pal[11];
          this.ctx.fillRect(screenX, screenY, tileW, tileH);
          continue;
        }

        const tileId = mapGrid[my][mx];
        this.drawTile(tileId, screenX, screenY, tileW, tileH, shimmer, realmName);
      }
    }

    // Draw wandering NPCs/beasts in view
    npcs.forEach(npc => {
      const dx = npc.x - playerX;
      const dy = npc.y - playerY;
      if (Math.abs(dx) <= 5 && Math.abs(dy) <= 5) {
        const sx = startX + (dx + 5) * tileW;
        const sy = startY + (dy + 5) * tileH;
        this.drawOverworldEntity(npc, sx, sy, tileW, tileH);
      }
    });

    // Draw Player Disciple in center (0, 0)
    const centerSX = startX + 5 * tileW;
    const centerSY = startY + 5 * tileH;
    this.drawPlayerOverworld(centerSX, centerSY, tileW, tileH);

    // Apply Day/Night Ambient Light Filter
    this.applyDayNightFilter(timeOfDay, hasTorch, startX, startY, 11 * tileW, 11 * tileH);

    // Right Side Status & Compass Tray
    this.drawOverworldTray(224, startY, realmName, playerX, playerY, timeOfDay);
  }

  drawTile(tileId, x, y, w, h, shimmer, realm) {
    const pal = this.palette;

    // Elemental Map Tile Logic
    if (tileId === 3 || tileId === 34 || tileId === 35 || tileId === 36) {
      // Water stream / ocean
      this.ctx.fillStyle = shimmer ? pal[6] : pal[14]; // Blue / Light blue
      this.ctx.fillRect(x, y, w, h);
      this.ctx.fillStyle = pal[1];
      this.ctx.fillRect(x + (shimmer ? 3 : 8), y + 4, 4, 1);
      this.ctx.fillRect(x + (shimmer ? 9 : 2), y + 10, 5, 1);
      return;
    }

    if (tileId === 4 || tileId === 37) {
      // Mountains / High Crags
      this.ctx.fillStyle = pal[11]; // Dark gray
      this.ctx.fillRect(x, y, w, h);
      this.ctx.fillStyle = pal[12]; // Gray
      this.ctx.beginPath();
      this.ctx.moveTo(x + w / 2, y + 2);
      this.ctx.lineTo(x + 2, y + h - 2);
      this.ctx.lineTo(x + w - 2, y + h - 2);
      this.ctx.fill();
      return;
    }

    if (tileId === 7) {
      // Shrine (Tainted or Clean)
      this.ctx.fillStyle = pal[5]; // Green base
      this.ctx.fillRect(x, y, w, h);
      this.ctx.fillStyle = pal[7]; // Golden roof
      this.ctx.fillRect(x + 2, y + 2, w - 4, 4);
      this.ctx.fillStyle = pal[2]; // Red shrine pillar
      this.ctx.fillRect(x + 4, y + 6, 2, h - 8);
      this.ctx.fillRect(x + w - 6, y + 6, 2, h - 8);
      return;
    }

    if (tileId === 12) {
      // Cistern / Healing Spring
      this.ctx.fillStyle = pal[15]; // Light gray stone
      this.ctx.fillRect(x, y, w, h);
      this.ctx.fillStyle = pal[14]; // Shimmering water
      this.ctx.fillRect(x + 3, y + 3, w - 6, h - 6);
      return;
    }

    if (tileId === 14) {
      // Cross / Tomb / Ancestor Grave
      this.ctx.fillStyle = pal[5]; // Grass
      this.ctx.fillRect(x, y, w, h);
      this.ctx.fillStyle = pal[1]; // White cross
      this.ctx.fillRect(x + w / 2 - 1, y + 2, 2, h - 4);
      this.ctx.fillRect(x + 3, y + 5, w - 6, 2);
      return;
    }

    if (tileId === 15 || tileId === 16 || tileId === 17) {
      // Bamboo forest / Trees
      this.ctx.fillStyle = pal[5]; // Dark green
      this.ctx.fillRect(x, y, w, h);
      this.ctx.fillStyle = pal[13]; // Light green shoots
      this.ctx.fillRect(x + 3, y + 1, 2, h - 2);
      this.ctx.fillRect(x + 8, y + 3, 2, h - 4);
      this.ctx.fillRect(x + 13, y + 2, 2, h - 3);
      return;
    }

    if (tileId === 18 || tileId === 19 || tileId === 20 || tileId === 21) {
      // Palace of Moebius Walls
      this.ctx.fillStyle = pal[2]; // Red lacquered wood
      this.ctx.fillRect(x, y, w, h);
      this.ctx.fillStyle = pal[7]; // Gold insets
      this.ctx.fillRect(x + 2, y + 2, w - 4, 2);
      this.ctx.fillRect(x + 2, y + h - 4, w - 4, 2);
      return;
    }

    if (tileId === 29) {
      // Astral Gate (Vortex)
      this.ctx.fillStyle = shimmer ? pal[4] : pal[3]; // Purple / Cyan vortex
      this.ctx.fillRect(x, y, w, h);
      this.ctx.fillStyle = pal[1];
      this.ctx.beginPath();
      this.ctx.arc(x + w / 2, y + h / 2, 5, 0, Math.PI * 2);
      this.ctx.fill();
      return;
    }

    if (tileId === 31) {
      // Wooden Bridge
      this.ctx.fillStyle = pal[6]; // Water underneath
      this.ctx.fillRect(x, y, w, h);
      this.ctx.fillStyle = pal[9]; // Brown planks
      this.ctx.fillRect(x + 1, y + 2, w - 2, h - 4);
      this.ctx.fillStyle = pal[0];
      this.ctx.fillRect(x + 1, y + 5, w - 2, 1);
      this.ctx.fillRect(x + 1, y + 9, w - 2, 1);
      return;
    }

    if (tileId === 42 || tileId === 43 || tileId === 44) {
      // Fire Realm Lava
      this.ctx.fillStyle = shimmer ? pal[2] : pal[8]; // Red / Orange
      this.ctx.fillRect(x, y, w, h);
      this.ctx.fillStyle = pal[7]; // Yellow bubbles
      this.ctx.fillRect(x + 4, y + 4, 3, 3);
      this.ctx.fillRect(x + 10, y + 9, 2, 2);
      return;
    }

    if (tileId === 33 || tileId === 40 || tileId === 41) {
      // Air Realm Clouds / Abyss
      if (tileId === 33) {
        this.ctx.fillStyle = pal[6]; // Blue sky
        this.ctx.fillRect(x, y, w, h);
      } else {
        this.ctx.fillStyle = pal[1]; // White fluffy cloud
        this.ctx.fillRect(x, y, w, h);
        this.ctx.fillStyle = pal[3];
        this.ctx.fillRect(x + 2, y + h - 3, w - 4, 2);
      }
      return;
    }

    // Default Grass / Plains / Ground
    this.ctx.fillStyle = pal[5]; // Green
    this.ctx.fillRect(x, y, w, h);
    if ((x + y) % 5 === 0) {
      this.ctx.fillStyle = pal[13]; // Light green tuft
      this.ctx.fillRect(x + 4, y + 4, 2, 2);
    }
  }

  drawPlayerOverworld(x, y, w, h) {
    const pal = this.palette;
    // White Gi with Black Belt & Headband
    this.ctx.fillStyle = pal[1]; // White uniform
    this.ctx.fillRect(x + 5, y + 3, 8, 10);
    this.ctx.fillStyle = pal[8]; // Peach/Tan skin
    this.ctx.fillRect(x + 7, y + 2, 4, 3);
    this.ctx.fillStyle = pal[0]; // Black belt & hair
    this.ctx.fillRect(x + 6, y + 1, 6, 2);
    this.ctx.fillRect(x + 5, y + 8, 8, 2);
    // Legs
    this.ctx.fillStyle = pal[1];
    this.ctx.fillRect(x + 5, y + 13, 3, 3);
    this.ctx.fillRect(x + 10, y + 13, 3, 3);
  }

  drawOverworldEntity(npc, x, y, w, h) {
    const pal = this.palette;
    if (npc.type === 'tiger') {
      this.ctx.fillStyle = pal[8]; // Orange body
      this.ctx.fillRect(x + 2, y + 5, 14, 7);
      this.ctx.fillStyle = pal[0]; // Stripes
      this.ctx.fillRect(x + 5, y + 4, 2, 4);
      this.ctx.fillRect(x + 9, y + 4, 2, 4);
      return;
    }

    // Humanoid NPC
    const color = (npc.type === 'monk') ? pal[7] :
                  (npc.type === 'ninja') ? pal[0] :
                  (npc.type === 'guard') ? pal[2] :
                  (npc.type === 'maiden') ? pal[4] : pal[9];

    this.ctx.fillStyle = color;
    this.ctx.fillRect(x + 5, y + 3, 8, 10);
    this.ctx.fillStyle = pal[8]; // Skin
    this.ctx.fillRect(x + 7, y + 2, 4, 3);
  }

  applyDayNightFilter(timeOfDay, hasTorch, x, y, w, h) {
    if (timeOfDay === 'DAY') return;

    this.ctx.save();
    if (timeOfDay === 'DUSK') {
      this.ctx.fillStyle = 'rgba(160, 60, 20, 0.25)';
      this.ctx.fillRect(x, y, w, h);
    } else if (timeOfDay === 'DAWN') {
      this.ctx.fillStyle = 'rgba(200, 140, 40, 0.2)';
      this.ctx.fillRect(x, y, w, h);
    } else if (timeOfDay === 'NIGHT') {
      if (hasTorch) {
        // Torch creates a circle around player
        const cx = x + w / 2;
        const cy = y + h / 2;
        const grad = this.ctx.createRadialGradient(cx, cy, 24, cx, cy, 65);
        grad.addColorStop(0, 'rgba(0, 5, 25, 0.1)');
        grad.addColorStop(1, 'rgba(0, 5, 25, 0.85)');
        this.ctx.fillStyle = grad;
        this.ctx.fillRect(x, y, w, h);
      } else {
        // Pitch darkness
        this.ctx.fillStyle = 'rgba(0, 5, 25, 0.82)';
        this.ctx.fillRect(x, y, w, h);
      }
    }
    this.ctx.restore();
  }

  drawOverworldTray(x, y, realm, px, py, timeOfDay) {
    const pal = this.palette;
    this.ctx.fillStyle = pal[9]; // Brown tray frame
    this.ctx.fillRect(x, y, 84, 176);
    this.ctx.fillStyle = pal[0];
    this.ctx.fillRect(x + 2, y + 2, 80, 172);

    // Realm Header
    this.ctx.fillStyle = pal[7]; // Gold
    this.ctx.font = '7px monospace';
    this.ctx.textAlign = 'center';
    this.ctx.fillText(realm, x + 42, y + 16);

    // Coordinates
    this.ctx.fillStyle = pal[15];
    this.ctx.fillText(`X:${px} Y:${py}`, x + 42, y + 30);

    // Time of day
    this.ctx.fillStyle = (timeOfDay === 'NIGHT') ? pal[14] : pal[7];
    this.ctx.fillText(timeOfDay, x + 42, y + 44);

    // Compass Rose
    this.ctx.fillStyle = pal[12];
    this.ctx.fillRect(x + 20, y + 54, 44, 44);
    this.ctx.fillStyle = pal[0];
    this.ctx.fillRect(x + 22, y + 56, 40, 40);
    this.ctx.fillStyle = pal[2]; // Red North
    this.ctx.fillText('N', x + 42, y + 66);
    this.ctx.fillStyle = pal[1];
    this.ctx.fillText('S', x + 42, y + 92);
    this.ctx.fillText('W', x + 28, y + 79);
    this.ctx.fillText('E', x + 56, y + 79);

    // Winged Dexterity & Karma Icons
    if (this.sprites['wings_dexterity']) {
      this.ctx.drawImage(this.sprites['wings_dexterity'], x + 28, y + 104, 28, 28);
    }
    if (this.sprites['karma_yinyang']) {
      this.ctx.drawImage(this.sprites['karma_yinyang'], x + 28, y + 138, 28, 28);
    }
  }

  // --- Tactical Combat Screen Renderer (Side-View) ---
  drawCombat(combatState) {
    const pal = this.palette;
    this.clear(0);

    // Arena background (Authentic Commodore 64 Arena / Dojo screens)
    let arenaBg = this.sprites['c64_arena_earth'];
    if (combatState.realm === 'WATER') arenaBg = this.sprites['c64_arena_water'] || arenaBg;
    else if (combatState.realm === 'AIR' || combatState.realm === 'FIRE') arenaBg = this.sprites['c64_arena_air'] || arenaBg;
    else if (combatState.isDojo) arenaBg = this.sprites['c64_title_dojo'] || arenaBg;

    if (arenaBg) {
      this.ctx.drawImage(arenaBg, 0, 0, 320, 130);
    } else if (this.sprites['arena_wall']) {
      this.ctx.drawImage(this.sprites['arena_wall'], 0, 0, 320, 130);
    } else {
      // Procedural bamboo dojo wall
      this.ctx.fillStyle = pal[9];
      this.ctx.fillRect(0, 0, 320, 130);
      for (let i = 0; i < 320; i += 16) {
        this.ctx.fillStyle = pal[8];
        this.ctx.fillRect(i, 0, 2, 130);
      }
    }

    // Floor mat
    this.ctx.fillStyle = pal[11]; // Dark gray mat
    this.ctx.fillRect(0, 130, 320, 70);
    this.ctx.fillStyle = pal[12];
    this.ctx.fillRect(0, 130, 320, 2);

    // Fighters: Left = Player, Right = Opponent
    this.drawCombatPlayer(combatState.player);
    this.drawCombatOpponent(combatState.opponent);

    // Combat HUD Bar at Bottom
    this.drawCombatHUD(combatState);
  }

  drawCombatPlayer(p) {
    const pal = this.palette;
    const x = p.x;
    const y = 88;
    const isSword = (p.weapon === 'SWORD');

    // Authentic C64 Sprite Selection
    let frame = null;
    if (p.action === 'BLOCK') frame = this.sprites['windwalker_block'];
    else if (p.action === 'KICK_HIGH') frame = this.sprites['windwalker_kick_high'];
    else if (p.action === 'KICK_MID') frame = this.sprites['windwalker_kick_mid'];
    else if (p.action === 'KICK_LOW') frame = this.sprites['windwalker_kick_low'];
    else if (p.action === 'PUNCH_HIGH') frame = this.sprites['windwalker_punch_high'];
    else if (p.action === 'PUNCH_MID') frame = this.sprites['windwalker_punch_mid'];
    else if (p.action === 'PUNCH_LOW') frame = this.sprites['windwalker_punch_low'];
    else if (p.action === 'SWING') frame = this.sprites['windwalker_swing'];
    else if (p.action === 'HIT') frame = this.sprites['windwalker_hit'];
    else if (p.action === 'FALL') frame = this.sprites['windwalker_fall'];
    else {
      // Stance idle animation cycle
      frame = (Math.floor(this.animTimer / 15) % 2 === 0) ? this.sprites['windwalker_idle_0'] : this.sprites['windwalker_idle_1'];
    }

    if (frame) {
      this.ctx.save();
      // Ground shadow
      this.ctx.fillStyle = 'rgba(0, 0, 0, 0.45)';
      this.ctx.beginPath();
      this.ctx.ellipse(x + 24, 130, 16, 5, 0, 0, Math.PI * 2);
      this.ctx.fill();

      // Render 48x42 Authentic C64 Sprite
      this.ctx.drawImage(frame, x, y, 48, 42);

      // Katana overlay if sword equipped
      if (isSword && p.action !== 'SWING') {
        this.ctx.fillStyle = pal[15];
        this.ctx.fillRect(x + 36, y + 10, 2, 22);
        this.ctx.fillStyle = pal[7];
        this.ctx.fillRect(x + 34, y + 24, 6, 2);
      }
      this.ctx.restore();
      return;
    }

    this.ctx.save();
    // Shadow
    this.ctx.fillStyle = 'rgba(0, 0, 0, 0.4)';
    this.ctx.beginPath();
    this.ctx.ellipse(x + 16, y + 50, 14, 5, 0, 0, Math.PI * 2);
    this.ctx.fill();

    // Body Gi
    this.ctx.fillStyle = pal[1]; // White gi
    if (p.action === 'BLOCK') {
      // Defensive stance: arms crossed
      this.ctx.fillRect(x + 8, y + 16, 16, 24);
      this.ctx.fillStyle = pal[8]; // Skin
      this.ctx.fillRect(x + 10, y + 6, 12, 10);
      this.ctx.fillStyle = pal[0]; // Headband
      this.ctx.fillRect(x + 8, y + 5, 16, 3);
      // Crossed arms
      this.ctx.fillStyle = pal[1];
      this.ctx.fillRect(x + 16, y + 18, 12, 12);
      // Spark if blocking
      this.ctx.fillStyle = pal[3];
      this.ctx.fillRect(x + 28, y + 20, 4, 4);
    } else if (p.action === 'KICK_HIGH' || p.action === 'KICK_MID' || p.action === 'KICK_LOW') {
      // Flying / extended kick frame
      this.ctx.fillRect(x + 4, y + 16, 16, 20);
      this.ctx.fillStyle = pal[8];
      this.ctx.fillRect(x + 6, y + 6, 12, 10);
      this.ctx.fillStyle = pal[0];
      this.ctx.fillRect(x + 4, y + 5, 16, 3);
      // Extended leg
      const legY = (p.action === 'KICK_HIGH') ? y + 10 : (p.action === 'KICK_MID') ? y + 22 : y + 36;
      this.ctx.fillStyle = pal[1];
      this.ctx.fillRect(x + 16, legY, 20, 6);
    } else if (p.action === 'PUNCH_HIGH' || p.action === 'PUNCH_MID' || p.action === 'PUNCH_LOW' || p.action === 'SWING') {
      // Extended punch or sword thrust
      this.ctx.fillRect(x + 8, y + 16, 16, 24);
      this.ctx.fillStyle = pal[8];
      this.ctx.fillRect(x + 10, y + 6, 12, 10);
      this.ctx.fillStyle = pal[0];
      this.ctx.fillRect(x + 8, y + 5, 16, 3);

      const armY = (p.action === 'PUNCH_HIGH') ? y + 12 : (p.action === 'PUNCH_MID' || p.action === 'SWING') ? y + 20 : y + 30;
      this.ctx.fillStyle = pal[1];
      this.ctx.fillRect(x + 20, armY, 18, 6);

      if (p.weapon === 'SWORD') {
        // Blade extension
        this.ctx.fillStyle = pal[15]; // Steel
        this.ctx.fillRect(x + 36, armY - 1, 22, 3);
        this.ctx.fillStyle = pal[7]; // Gold hilt
        this.ctx.fillRect(x + 36, armY - 3, 2, 7);
      }
    } else {
      // Neutral martial arts stance
      this.ctx.fillRect(x + 8, y + 16, 16, 24);
      this.ctx.fillStyle = pal[8];
      this.ctx.fillRect(x + 10, y + 6, 12, 10);
      this.ctx.fillStyle = pal[0];
      this.ctx.fillRect(x + 8, y + 5, 16, 3);
      // Stance arms
      this.ctx.fillStyle = pal[1];
      this.ctx.fillRect(x + 18, y + 20, 8, 5);
      this.ctx.fillRect(x + 4, y + 22, 6, 5);
      // Legs
      this.ctx.fillRect(x + 6, y + 38, 7, 14);
      this.ctx.fillRect(x + 17, y + 38, 7, 14);

      if (p.weapon === 'SWORD') {
        this.ctx.fillStyle = pal[15];
        this.ctx.fillRect(x + 22, y + 12, 3, 18);
      }
    }

    this.ctx.restore();
  }

  drawCombatOpponent(opp) {
    const pal = this.palette;
    const x = opp.x;
    const y = 88;

    let frame = null;
    if (opp.type === 'tiger') {
      frame = this.sprites['enemy_tiger'] || this.sprites['tile_tiger'];
    } else if (opp.type === 'ninja') {
      frame = this.sprites['enemy_ninja'];
    } else if (opp.type === 'guard') {
      frame = this.sprites['enemy_guard'];
    } else {
      // Sparring monk / martial artist opponent
      if (opp.action === 'BLOCK') frame = this.sprites['monk_block'];
      else if (opp.action === 'STRIKE' || opp.action === 'PUNCH') frame = this.sprites['monk_punch'];
      else if (opp.action === 'KICK') frame = this.sprites['monk_kick'];
      else if (opp.action === 'SWING') frame = this.sprites['monk_swing'];
      else if (opp.action === 'HIT') frame = this.sprites['monk_hit'];
      else if (opp.action === 'FALL') frame = this.sprites['monk_fall'];
      else {
        frame = (Math.floor(this.animTimer / 15) % 2 === 0) ? this.sprites['monk_idle_0'] : this.sprites['monk_idle_1'];
      }
    }

    if (frame) {
      this.ctx.save();
      // Ground shadow
      this.ctx.fillStyle = 'rgba(0, 0, 0, 0.45)';
      this.ctx.beginPath();
      this.ctx.ellipse(x + 24, 130, 16, 5, 0, 0, Math.PI * 2);
      this.ctx.fill();

      // Render flipped horizontally so opponent faces left toward player
      this.ctx.translate(x + 48, y);
      this.ctx.scale(-1, 1);
      this.ctx.drawImage(frame, 0, 0, 48, 42);
      this.ctx.restore();
      return;
    }

    this.ctx.save();
    // Shadow
    this.ctx.fillStyle = 'rgba(0, 0, 0, 0.4)';
    this.ctx.beginPath();
    this.ctx.ellipse(x + 16, y + 50, 14, 5, 0, 0, Math.PI * 2);
    this.ctx.fill();

    const color = (opp.type === 'ninja') ? pal[0] :
                  (opp.type === 'guard') ? pal[2] :
                  (opp.type === 'kaimen') ? pal[4] : pal[9];

    this.ctx.fillStyle = color;
    if (opp.action === 'BLOCK') {
      this.ctx.fillRect(x + 8, y + 16, 16, 24);
      this.ctx.fillStyle = pal[8];
      this.ctx.fillRect(x + 10, y + 6, 12, 10);
      this.ctx.fillStyle = color;
      this.ctx.fillRect(x + 4, y + 18, 12, 12);
    } else if (opp.action === 'STRIKE') {
      this.ctx.fillRect(x + 8, y + 16, 16, 24);
      this.ctx.fillStyle = pal[8];
      this.ctx.fillRect(x + 10, y + 6, 12, 10);
      this.ctx.fillStyle = color;
      this.ctx.fillRect(x - 12, y + 20, 20, 6);
    } else {
      // Neutral
      this.ctx.fillRect(x + 8, y + 16, 16, 24);
      this.ctx.fillStyle = pal[8];
      this.ctx.fillRect(x + 10, y + 6, 12, 10);
      this.ctx.fillStyle = color;
      this.ctx.fillRect(x + 6, y + 38, 7, 14);
      this.ctx.fillRect(x + 17, y + 38, 7, 14);
    }

    this.ctx.restore();
  }

  drawCombatHUD(combatState) {
    const pal = this.palette;
    const y = 146;

    // Tray background
    this.ctx.fillStyle = pal[0];
    this.ctx.fillRect(10, y, 300, 50);
    this.ctx.fillStyle = pal[9];
    this.ctx.strokeRect(10, y, 300, 50);

    // Player stats
    this.ctx.font = '7px monospace';
    this.ctx.fillStyle = pal[1];
    this.ctx.fillText(`PLAYER: ${combatState.player.name}`, 20, y + 12);
    
    // Player Body Bar
    this.ctx.fillStyle = pal[2]; // Red
    const playerBodyW = Math.max(0, (combatState.player.body / combatState.player.maxBody) * 80);
    this.ctx.fillRect(20, y + 16, playerBodyW, 6);
    this.ctx.strokeRect(20, y + 16, 80, 6);

    // Player Fatigue Bar
    this.ctx.fillStyle = pal[14]; // Blue
    const playerFatigueW = Math.max(0, (combatState.player.fatigue / 100) * 80);
    this.ctx.fillRect(20, y + 26, playerFatigueW, 6);
    this.ctx.strokeRect(20, y + 26, 80, 6);

    // Opponent stats
    this.ctx.fillStyle = pal[7];
    this.ctx.textAlign = 'right';
    this.ctx.fillText(`ENEMY: ${combatState.opponent.name}`, 300, y + 12);

    // Opponent Body Bar
    this.ctx.fillStyle = pal[2];
    const oppBodyW = Math.max(0, (combatState.opponent.body / combatState.opponent.maxBody) * 80);
    this.ctx.fillRect(220, y + 16, oppBodyW, 6);
    this.ctx.strokeRect(220, y + 16, 80, 6);

    // Combat Mode Info
    this.ctx.textAlign = 'center';
    this.ctx.fillStyle = pal[13];
    this.ctx.fillText(`[${combatState.player.weapon}] SPACE: BLOCK | T: SHURIKEN | ESC: FLEE`, 160, y + 42);
  }

  // --- Divination Minigame Screen Renderer ---
  drawDivination(spiritX, spiritY, energy, centeredTime) {
    const pal = this.palette;
    this.clear(0);

    // Divination Frame
    const boxX = 85;
    const boxY = 25;
    const boxSize = 150;

    this.ctx.fillStyle = pal[9]; // Brown outer
    this.ctx.fillRect(boxX - 4, boxY - 4, boxSize + 8, boxSize + 8);
    this.ctx.fillStyle = pal[0];
    this.ctx.fillRect(boxX, boxY, boxSize, boxSize);

    // Concentric meditation circles
    this.ctx.strokeStyle = pal[11];
    this.ctx.beginPath();
    this.ctx.arc(boxX + boxSize / 2, boxY + boxSize / 2, 45, 0, Math.PI * 2);
    this.ctx.stroke();

    this.ctx.strokeStyle = pal[12];
    this.ctx.beginPath();
    this.ctx.arc(boxX + boxSize / 2, boxY + boxSize / 2, 20, 0, Math.PI * 2);
    this.ctx.stroke();

    // Center target
    this.ctx.fillStyle = pal[7];
    this.ctx.fillRect(boxX + boxSize / 2 - 2, boxY + boxSize / 2 - 2, 4, 4);

    // Floating Yin-Yang Spirit
    const sx = boxX + boxSize / 2 + spiritX;
    const sy = boxY + boxSize / 2 + spiritY;

    if (this.sprites['karma_yinyang']) {
      this.ctx.drawImage(this.sprites['karma_yinyang'], sx - 10, sy - 10, 20, 20);
    } else {
      this.ctx.fillStyle = pal[1];
      this.ctx.beginPath();
      this.ctx.arc(sx, sy, 8, 0, Math.PI * 2);
      this.ctx.fill();
    }

    // Mental Energy Bar at bottom
    this.ctx.fillStyle = pal[15];
    this.ctx.font = '7px monospace';
    this.ctx.textAlign = 'center';
    this.ctx.fillText('DIVINATION: KEEP THE SPIRIT CENTERED', 160, 16);
    this.ctx.fillText(`MENTAL ENERGY: ${Math.floor(energy)} / 160`, 160, 188);

    const energyW = Math.max(0, (energy / 160) * 150);
    this.ctx.fillStyle = pal[4]; // Purple Mind Energy
    this.ctx.fillRect(boxX, 192, energyW, 4);
    this.ctx.strokeStyle = pal[1];
    this.ctx.strokeRect(boxX, 192, boxSize, 4);
  }
}

window.MoebiusGraphics = MoebiusGraphics;
