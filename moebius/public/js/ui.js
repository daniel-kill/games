/**
 * Moebius: The Orb of Celestial Harmony
 * User Interface & Modal Management
 */

class MoebiusUI {
  constructor() {
    this.modalOverlay = document.getElementById('modal-overlay');
    this.modalTitle = document.getElementById('modal-title');
    this.modalBody = document.getElementById('modal-body');
    this.messageBox = document.getElementById('message-box');

    this.bodyBar = document.getElementById('bar-body');
    this.fatigueBar = document.getElementById('bar-fatigue');
    this.mindBar = document.getElementById('bar-mind');
    this.karmaBar = document.getElementById('bar-karma');

    this.bodyVal = document.getElementById('val-body');
    this.fatigueVal = document.getElementById('val-fatigue');
    this.mindVal = document.getElementById('val-mind');
    this.karmaVal = document.getElementById('val-karma');

    this.headerRealm = document.getElementById('stat-realm');
    this.headerFood = document.getElementById('stat-food');
    this.headerWater = document.getElementById('stat-water');
    this.headerTorches = document.getElementById('stat-torches');
  }

  addMessage(text, styleClass = '') {
    if (!this.messageBox) return;
    const line = document.createElement('div');
    line.className = `msg-line ${styleClass}`;
    line.textContent = `> ${text}`;
    this.messageBox.insertBefore(line, this.messageBox.firstChild);

    // Limit log length
    while (this.messageBox.children.length > 40) {
      this.messageBox.removeChild(this.messageBox.lastChild);
    }
  }

  updateVitals(player, realm) {
    if (this.bodyBar) {
      const bPct = Math.max(0, Math.min(100, (player.body / player.maxBody) * 100));
      this.bodyBar.style.width = `${bPct}%`;
      this.bodyVal.textContent = `${Math.floor(player.body)}/${player.maxBody}`;
    }
    if (this.fatigueBar) {
      const fPct = Math.max(0, Math.min(100, player.fatigue));
      this.fatigueBar.style.width = `${fPct}%`;
      this.fatigueVal.textContent = `${Math.floor(player.fatigue)}`;
    }
    if (this.mindBar) {
      const mPct = Math.max(0, Math.min(100, (player.mind / player.maxMind) * 100));
      this.mindBar.style.width = `${mPct}%`;
      this.mindVal.textContent = `${Math.floor(player.mind)}`;
    }
    if (this.karmaBar) {
      const kPct = Math.max(0, Math.min(100, player.karma));
      this.karmaBar.style.width = `${kPct}%`;
      this.karmaVal.textContent = `${Math.floor(player.karma)}`;
    }

    if (this.headerRealm) this.headerRealm.textContent = realm;
    if (this.headerFood) this.headerFood.textContent = player.food;
    if (this.headerWater) this.headerWater.textContent = player.water;
    if (this.headerTorches) this.headerTorches.textContent = player.torches;
  }

  showModal(title, contentElement) {
    if (!this.modalOverlay) return;
    this.modalTitle.textContent = title;
    this.modalBody.innerHTML = '';
    this.modalBody.appendChild(contentElement);
    this.modalOverlay.style.display = 'flex';
  }

  hideModal() {
    if (this.modalOverlay) {
      this.modalOverlay.style.display = 'none';
    }
  }

  showPrelude(discipleName, onStart, onTrain) {
    const container = document.createElement('div');
    container.style.display = 'flex';
    container.style.flexDirection = 'column';
    container.style.gap = '10px';

    const intro = document.createElement('p');
    intro.style.color = '#cfa83b';
    intro.style.fontSize = '9px';
    intro.style.lineHeight = '1.6';
    intro.textContent = 'Welcome, Disciple, to the House of Moebius. The sacred Orb of Celestial Harmony has been stolen by the treacherous Warlord Kaimen, plunging the elemental realms into chaos. Prepare your mind and body before embarking!';

    // Name input
    const nameRow = document.createElement('div');
    nameRow.style.display = 'flex';
    nameRow.style.alignItems = 'center';
    nameRow.style.gap = '8px';
    const nameLabel = document.createElement('span');
    nameLabel.textContent = 'DISCIPLE NAME:';
    nameLabel.style.fontSize = '9px';
    const nameInput = document.createElement('input');
    nameInput.type = 'text';
    nameInput.value = discipleName;
    nameInput.maxLength = 12;
    nameInput.style.background = '#090c07';
    nameInput.style.border = '1px solid #5d8a43';
    nameInput.style.color = '#fff';
    nameInput.style.fontFamily = 'inherit';
    nameInput.style.fontSize = '9px';
    nameInput.style.padding = '4px';

    nameRow.appendChild(nameLabel);
    nameRow.appendChild(nameInput);

    // Menu options
    const list = document.createElement('div');
    list.className = 'menu-list';

    const btnSwords = document.createElement('button');
    btnSwords.className = 'menu-item-btn';
    btnSwords.innerHTML = '<span>1. TRAIN: SWORDSMANSHIP</span> <span>+Dexterity</span>';
    btnSwords.onclick = () => onTrain('SWORDS');

    const btnMartial = document.createElement('button');
    btnMartial.className = 'menu-item-btn';
    btnMartial.innerHTML = '<span>2. TRAIN: MARTIAL ARTS</span> <span>+Fatigue</span>';
    btnMartial.onclick = () => onTrain('MARTIAL');

    const btnDivination = document.createElement('button');
    btnDivination.className = 'menu-item-btn';
    btnDivination.innerHTML = '<span>3. TRAIN: DIVINATION</span> <span>+Mind</span>';
    btnDivination.onclick = () => onTrain('DIVINATION');

    const btnBegin = document.createElement('button');
    btnBegin.className = 'retro-btn gold';
    btnBegin.style.padding = '10px';
    btnBegin.style.marginTop = '8px';
    btnBegin.textContent = '⚔ ENTER THE REALM OF EARTH (BEGIN ADVENTURE)';
    btnBegin.onclick = () => {
      this.hideModal();
      onStart(nameInput.value.trim() || 'Windwalker');
    };

    list.appendChild(btnSwords);
    list.appendChild(btnMartial);
    list.appendChild(btnDivination);

    container.appendChild(intro);
    container.appendChild(nameRow);
    container.appendChild(list);
    container.appendChild(btnBegin);

    this.showModal('HOUSE OF MOEBIUS — DISCIPLE PREPARATION', container);
  }

  showPrayerMenu(prayers, fastingCost, onCast) {
    const list = document.createElement('div');
    list.className = 'menu-list';

    const desc = document.createElement('p');
    desc.style.fontSize = '8px';
    desc.style.color = '#eab308';
    desc.style.marginBottom = '6px';
    desc.textContent = `Fasting Requirement: Invoking a prayer consumes ${fastingCost} Body points in this realm.`;
    list.appendChild(desc);

    prayers.forEach(p => {
      const btn = document.createElement('button');
      btn.className = 'menu-item-btn';
      btn.innerHTML = `<div><strong>${p.name}</strong><br><small style="color:#8da47e;">${p.desc}</small></div><span style="color:#f87171;">-${fastingCost} Body</span>`;
      btn.onclick = () => {
        this.hideModal();
        onCast(p.id);
      };
      list.appendChild(btn);
    });

    const closeBtn = document.createElement('button');
    closeBtn.className = 'retro-btn';
    closeBtn.style.marginTop = '8px';
    closeBtn.textContent = 'CLOSE PRAYER SCROLL';
    closeBtn.onclick = () => this.hideModal();
    list.appendChild(closeBtn);

    this.showModal('TAOIST PRAYER SCROLL', list);
  }

  showCharmMenu(charms, components, onCast) {
    const list = document.createElement('div');
    list.className = 'menu-list';

    const desc = document.createElement('p');
    desc.style.fontSize = '8px';
    desc.style.color = '#aaffee';
    desc.style.marginBottom = '6px';
    desc.textContent = 'Charms harness elemental components found across the realms:';
    list.appendChild(desc);

    charms.forEach(c => {
      const count = components[c.component] || 0;
      const btn = document.createElement('button');
      btn.className = 'menu-item-btn';
      btn.innerHTML = `<div><strong>${c.name}</strong><br><small style="color:#8da47e;">${c.desc}</small></div><span style="color:${count > 0 ? '#4ade80' : '#f87171'};">${c.component.toUpperCase()}: ${count}</span>`;
      btn.disabled = (count <= 0);
      btn.style.opacity = (count <= 0) ? '0.45' : '1.0';
      btn.onclick = () => {
        this.hideModal();
        onCast(c.id);
      };
      list.appendChild(btn);
    });

    const closeBtn = document.createElement('button');
    closeBtn.className = 'retro-btn';
    closeBtn.style.marginTop = '8px';
    closeBtn.textContent = 'CLOSE CHARMS';
    closeBtn.onclick = () => this.hideModal();
    list.appendChild(closeBtn);

    this.showModal('ELEMENTAL CHARMS & TALISMANS', list);
  }

  showInventory(player, onUseItem) {
    const container = document.createElement('div');
    container.style.display = 'flex';
    container.style.flexDirection = 'column';
    container.style.gap = '8px';

    const grid = document.createElement('div');
    grid.style.display = 'grid';
    grid.style.gridTemplateColumns = '1fr 1fr';
    grid.style.gap = '6px';
    grid.style.fontSize = '8px';

    grid.innerHTML = `
      <div style="background:#151c11; padding:6px; border:1px solid #33442a;">
        <strong>PROVISIONS</strong><br>
        • Food Rations: ${player.food}<br>
        • Water Flask: ${player.water}<br>
        • Torches: ${player.torches}
      </div>
      <div style="background:#151c11; padding:6px; border:1px solid #33442a;">
        <strong>ARMAMENT</strong><br>
        • Sword: ${player.swordEquipped ? 'Equipped' : 'Sheathed'}<br>
        • Whetstones: ${player.whetstone}<br>
        • Shurikens: ${player.shurikens}
      </div>
      <div style="background:#151c11; padding:6px; border:1px solid #33442a; grid-column: span 2;">
        <strong>SACRED COMPONENTS</strong><br>
        • Incense: ${player.components.incense} | • Lotus Flower: ${player.components.lotus}<br>
        • Jade Amulet: ${player.components.jade} | • Silk Ribbon: ${player.components.silk}<br>
        • Bronze Bell: ${player.components.bell} | • Dragon Pearl: ${player.components.pearl}
      </div>
    `;

    const btnRow = document.createElement('div');
    btnRow.style.display = 'grid';
    btnRow.style.gridTemplateColumns = 'repeat(3, 1fr)';
    btnRow.style.gap = '4px';

    const btnEat = document.createElement('button');
    btnEat.className = 'retro-btn';
    btnEat.textContent = 'EAT FOOD';
    btnEat.onclick = () => { onUseItem('EAT'); this.hideModal(); };

    const btnDrink = document.createElement('button');
    btnDrink.className = 'retro-btn';
    btnDrink.textContent = 'DRINK WATER';
    btnDrink.onclick = () => { onUseItem('DRINK'); this.hideModal(); };

    const btnTorch = document.createElement('button');
    btnTorch.className = 'retro-btn';
    btnTorch.textContent = 'LIGHT TORCH';
    btnTorch.onclick = () => { onUseItem('TORCH'); this.hideModal(); };

    btnRow.appendChild(btnEat);
    btnRow.appendChild(btnDrink);
    btnRow.appendChild(btnTorch);

    const closeBtn = document.createElement('button');
    closeBtn.className = 'retro-btn';
    closeBtn.textContent = 'CLOSE INVENTORY';
    closeBtn.onclick = () => this.hideModal();

    container.appendChild(grid);
    container.appendChild(btnRow);
    container.appendChild(closeBtn);

    this.showModal('DISCIPLE INVENTORY & POUCH', container);
  }

  showConversation(npc, onAction) {
    const container = document.createElement('div');
    container.style.display = 'flex';
    container.style.flexDirection = 'column';
    container.style.gap = '10px';

    const p = document.createElement('p');
    p.style.fontSize = '9px';
    p.style.lineHeight = '1.5';
    p.textContent = `You stand before a ${npc.type.toUpperCase()}. How do you approach this earthly encounter?`;

    const list = document.createElement('div');
    list.className = 'menu-list';

    const btnBow = document.createElement('button');
    btnBow.className = 'menu-item-btn';
    btnBow.innerHTML = '<span>1. BOW RESPECTFULLY</span> <span>(+Karma)</span>';
    btnBow.onclick = () => { this.hideModal(); onAction('BOW'); };

    const btnTalk = document.createElement('button');
    btnTalk.className = 'menu-item-btn';
    btnTalk.innerHTML = '<span>2. INQUIRE OF THE REALM</span> <span>(Ask Clues)</span>';
    btnTalk.onclick = () => { this.hideModal(); onAction('TALK'); };

    const btnAid = document.createElement('button');
    btnAid.className = 'menu-item-btn';
    btnAid.innerHTML = '<span>3. OFFER PROVISIONS</span> <span>(Give Food/Water)</span>';
    btnAid.onclick = () => { this.hideModal(); onAction('GIVE'); };

    const btnAttack = document.createElement('button');
    btnAttack.className = 'menu-item-btn';
    btnAttack.style.borderColor = '#b82b2b';
    btnAttack.innerHTML = '<span style="color:#f87171;">4. DRAW WEAPON (ATTACK)</span> <span style="color:#f87171;">(Combat)</span>';
    btnAttack.onclick = () => { this.hideModal(); onAction('ATTACK'); };

    const btnDepart = document.createElement('button');
    btnDepart.className = 'retro-btn';
    btnDepart.textContent = '5. DEPART PEACEFULLY';
    btnDepart.onclick = () => this.hideModal();

    list.appendChild(btnBow);
    list.appendChild(btnTalk);
    list.appendChild(btnAid);
    list.appendChild(btnAttack);
    list.appendChild(btnDepart);

    container.appendChild(p);
    container.appendChild(list);

    this.showModal(`ENCOUNTER: ${npc.type.toUpperCase()}`, container);
  }

  showHelp() {
    const container = document.createElement('div');
    container.style.display = 'flex';
    container.style.flexDirection = 'column';
    container.style.gap = '8px';
    container.style.fontSize = '8px';
    container.style.lineHeight = '1.5';

    container.innerHTML = `
      <p style="color:#eedd44; border: 1px solid #aa8822; padding: 4px 6px; background: rgba(80, 60, 0, 0.3);"><strong>NOTE:</strong> Active work-in-progress conversion. Core exploration, C64 martial arts combat, and meditation systems are operational; advanced quest scripting and palace interiors are in ongoing development.</p>
      <p style="color:#cfa83b;"><strong>OBJECTIVE:</strong> Purify the two defiled shrines in each elemental realm (Earth, Water, Air, Fire) to awaken the Astral Gates. Breach Warlord Kaimen's volcanic lair in the Realm of Fire to reclaim the Orb of Celestial Harmony!</p>
      
      <p><strong>OVERWORLD CONTROLS:</strong><br>
      • Arrow Keys or WASD: Move Disciple<br>
      • P: Invoke Fasting Prayers<br>
      • C: Cast Component Charms<br>
      • M: Meditate / Divination<br>
      • I: Open Inventory & Provisions<br>
      • T: Talk / Bow to nearby NPC<br>
      • Spacebar: Draw Weapon / Engage Hostile</p>

      <p><strong>COMBAT CONTROLS:</strong><br>
      • Spacebar: BLOCK enemy attack (time carefully!)<br>
      • 7 / U: High Strike | 4 / J: Mid Strike | 1 / M: Low Strike<br>
      • 9 / O: High Kick | 6 / L: Mid Kick | 3 / .: Low Kick<br>
      • Z / X: Short Step Back / Forward<br>
      • A / S: Long Stride Back / Forward<br>
      • T: Throw Shuriken | W: Toggle Sword/Barehand<br>
      • Enter / Esc: Break & Run (Escape)</p>

      <p style="color:#aad492;"><strong>DIVINATION MEDITATION:</strong> Use Arrow keys / WASD to counteract cosmic turbulence and keep the Yin-Yang spirit centered inside the meditation circle while mental energy drains.</p>
    `;

    const closeBtn = document.createElement('button');
    closeBtn.className = 'retro-btn';
    closeBtn.textContent = 'RETURN TO GAME';
    closeBtn.onclick = () => this.hideModal();
    container.appendChild(closeBtn);

    this.showModal('SCROLL OF INSTRUCTION & PHILOSOPHY', container);
  }
}

window.MoebiusUI = MoebiusUI;
