/**
 * Moebius: The Orb of Celestial Harmony
 * Divination Minigame (Spirit Centering Taoist Meditation)
 */

class MoebiusDivination {
  constructor(audio) {
    this.audio = audio;
    this.active = false;
    this.spiritX = 0;
    this.spiritY = 0;
    this.vx = 0;
    this.vy = 0;
    this.energy = 160;
    this.maxEnergy = 160;
    this.totalTicks = 0;
    this.centeredTicks = 0;
    this.lastPingTimer = 0;
  }

  start() {
    this.active = true;
    this.spiritX = (Math.random() - 0.5) * 40;
    this.spiritY = (Math.random() - 0.5) * 40;
    this.vx = (Math.random() - 0.5) * 2;
    this.vy = (Math.random() - 0.5) * 2;
    this.energy = this.maxEnergy;
    this.totalTicks = 0;
    this.centeredTicks = 0;
    this.lastPingTimer = 0;
  }

  applyForce(fx, fy) {
    if (!this.active) return;
    this.vx += fx * 0.9;
    this.vy += fy * 0.9;
  }

  update() {
    if (!this.active) return null;

    this.totalTicks++;
    this.energy -= 0.65;

    // Cosmic spiritual turbulence drift
    this.vx += (Math.random() - 0.5) * 0.75;
    this.vy += (Math.random() - 0.5) * 0.75;

    // Apply friction
    this.vx *= 0.93;
    this.vy *= 0.93;

    this.spiritX += this.vx;
    this.spiritY += this.vy;

    // Bounds constraint (-60 to +60)
    const maxBound = 60;
    if (this.spiritX > maxBound) { this.spiritX = maxBound; this.vx = -this.vx * 0.5; }
    if (this.spiritX < -maxBound) { this.spiritX = -maxBound; this.vx = -this.vx * 0.5; }
    if (this.spiritY > maxBound) { this.spiritY = maxBound; this.vy = -this.vy * 0.5; }
    if (this.spiritY < -maxBound) { this.spiritY = -maxBound; this.vy = -this.vy * 0.5; }

    // Distance from center
    const dist = Math.hypot(this.spiritX, this.spiritY);
    const isCentered = dist < 22;

    if (isCentered) {
      this.centeredTicks++;
    }

    this.lastPingTimer++;
    if (this.lastPingTimer % 35 === 0 && this.audio) {
      this.audio.playDivinationPing(isCentered);
    }

    // Energy exhausted -> compute divination prophecy
    if (this.energy <= 0) {
      this.active = false;
      const scoreRatio = this.centeredTicks / Math.max(1, this.totalTicks);
      return this.computeResult(scoreRatio);
    }

    return null;
  }

  computeResult(ratio) {
    if (ratio >= 0.65) {
      return {
        success: true,
        mastery: 'MASTER',
        ratio: ratio,
        mindGain: 12,
        karmaGain: 5,
        message: 'The celestial veil parts! The sacred Astral Gate and Shrines glow with radiant clarity upon your inner eye.'
      };
    } else if (ratio >= 0.38) {
      return {
        success: true,
        mastery: 'ADEPT',
        ratio: ratio,
        mindGain: 6,
        karmaGain: 2,
        message: 'A serene vision passes: "He who purifies the two defiled shrines opens the path across the elements."'
      };
    } else {
      return {
        success: false,
        mastery: 'TURBULENT',
        ratio: ratio,
        mindGain: 1,
        karmaGain: 0,
        message: 'Your spirit was buffeted by turbulent winds. Meditation ends without a vision.'
      };
    }
  }
}

window.MoebiusDivination = MoebiusDivination;
