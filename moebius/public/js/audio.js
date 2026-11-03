/**
 * Moebius: The Orb of Celestial Harmony
 * Authentic Retro Web Audio Chiptune & Sound Synthesis
 */

class MoebiusAudio {
  constructor() {
    this.ctx = null;
    this.musicTracks = null;
    this.currentTrack = null;
    this.isPlayingMusic = false;
    this.musicTimeout = null;
    this.currentVoiceNodes = [];
    
    this.masterGain = null;
    this.musicGain = null;
    this.sfxGain = null;

    this.isMuted = false;
    this.masterVol = 0.7;
    this.musicVol = 0.5;
    this.sfxVol = 0.6;
    
    this.tempoScale = 0.00095; // Converted from original SLB timer units to seconds
  }

  init() {
    if (this.ctx) return;
    try {
      const AudioCtx = window.AudioContext || window.webkitAudioContext;
      this.ctx = new AudioCtx();

      // Master output
      this.masterGain = this.ctx.createGain();
      this.masterGain.gain.setValueAtTime(this.masterVol, this.ctx.currentTime);
      this.masterGain.connect(this.ctx.destination);

      // Music sub-bus
      this.musicGain = this.ctx.createGain();
      this.musicGain.gain.setValueAtTime(this.musicVol, this.ctx.currentTime);
      this.musicGain.connect(this.masterGain);

      // SFX sub-bus
      this.sfxGain = this.ctx.createGain();
      this.sfxGain.gain.setValueAtTime(this.sfxVol, this.ctx.currentTime);
      this.sfxGain.connect(this.masterGain);

      this.loadMusicData();
    } catch (e) {
      console.warn('Web Audio API not supported or blocked:', e);
    }
  }

  async loadMusicData() {
    try {
      const res = await fetch('assets/music_tracks.json');
      if (res.ok) {
        this.musicTracks = await res.json();
      }
    } catch (err) {
      console.warn('Failed to load music_tracks.json:', err);
    }
  }

  ensureContext() {
    if (!this.ctx) this.init();
    if (this.ctx && this.ctx.state === 'suspended') {
      this.ctx.resume();
    }
  }

  setMute(muted) {
    this.isMuted = muted;
    if (this.masterGain && this.ctx) {
      this.masterGain.gain.setValueAtTime(this.isMuted ? 0 : this.masterVol, this.ctx.currentTime);
    }
  }

  toggleMute() {
    this.setMute(!this.isMuted);
    return this.isMuted;
  }

  stopMusic() {
    this.isPlayingMusic = false;
    if (this.musicTimeout) {
      clearTimeout(this.musicTimeout);
      this.musicTimeout = null;
    }
    this.currentVoiceNodes.forEach(node => {
      try {
        node.stop();
        node.disconnect();
      } catch (e) {}
    });
    this.currentVoiceNodes = [];
  }

  playMusic(trackIndex, loop = true) {
    this.ensureContext();
    if (!this.ctx || !this.musicTracks) return;
    this.stopMusic();

    let track = null;
    if (Array.isArray(this.musicTracks)) {
      track = this.musicTracks[trackIndex % this.musicTracks.length];
    } else if (typeof this.musicTracks === 'object') {
      const keys = Object.keys(this.musicTracks);
      const key = keys[trackIndex % keys.length];
      track = this.musicTracks[key];
    }

    if (!track) return;
    const events = Array.isArray(track) ? track : (track.events || []);
    if (events.length === 0) return;

    this.isPlayingMusic = true;
    let now = this.ctx.currentTime + 0.05;
    let totalDuration = 0;

    for (let i = 0; i < events.length; i++) {
      const ev = events[i];
      const durSec = Math.max(0.04, (ev.duration || 100) * this.tempoScale);
      const startTime = now + totalDuration;

      if (ev.freq && ev.freq > 20 && ev.freq < 5000) {
        // Synthesize 3-voice retro SID style note
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();

        // Alternate waveforms for authentic chiptune warmth
        osc.type = (i % 2 === 0) ? 'sawtooth' : 'square';
        osc.frequency.setValueAtTime(ev.freq, startTime);

        // Envelope: quick attack, subtle decay
        gain.gain.setValueAtTime(0.001, startTime);
        gain.gain.linearRampToValueAtTime(0.18, startTime + 0.02);
        gain.gain.exponentialRampToValueAtTime(0.001, startTime + durSec);

        osc.connect(gain);
        gain.connect(this.musicGain);

        try {
          osc.start(startTime);
          osc.stop(startTime + durSec);
          this.currentVoiceNodes.push(osc);
        } catch (e) {}
      }

      totalDuration += durSec;
    }

    if (loop && this.isPlayingMusic) {
      this.musicTimeout = setTimeout(() => {
        if (this.isPlayingMusic) {
          this.playMusic(trackIndex, loop);
        }
      }, (totalDuration * 1000) - 100);
    }
  }

  // --- Sound Effects ---

  playPunch() {
    this.ensureContext();
    if (!this.ctx) return;
    const t = this.ctx.currentTime;
    
    // Low punch osc
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = 'triangle';
    osc.frequency.setValueAtTime(160, t);
    osc.frequency.exponentialRampToValueAtTime(40, t + 0.12);

    gain.gain.setValueAtTime(0.6, t);
    gain.gain.exponentialRampToValueAtTime(0.01, t + 0.12);

    osc.connect(gain);
    gain.connect(this.sfxGain);
    osc.start(t);
    osc.stop(t + 0.12);

    // Punch impact noise
    this.playNoise(0.08, 0.4, 600);
  }

  playKick() {
    this.ensureContext();
    if (!this.ctx) return;
    const t = this.ctx.currentTime;

    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(220, t);
    osc.frequency.exponentialRampToValueAtTime(30, t + 0.18);

    gain.gain.setValueAtTime(0.8, t);
    gain.gain.exponentialRampToValueAtTime(0.01, t + 0.18);

    osc.connect(gain);
    gain.connect(this.sfxGain);
    osc.start(t);
    osc.stop(t + 0.18);

    this.playNoise(0.12, 0.5, 350);
  }

  playSwordClash() {
    this.ensureContext();
    if (!this.ctx) return;
    const t = this.ctx.currentTime;

    // Dual ringing metallic harmonics
    [1320, 1860, 2480].forEach((freq, idx) => {
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(freq, t);
      osc.frequency.exponentialRampToValueAtTime(freq * 0.9, t + 0.25);

      gain.gain.setValueAtTime(0.3 / (idx + 1), t);
      gain.gain.exponentialRampToValueAtTime(0.001, t + 0.25);

      osc.connect(gain);
      gain.connect(this.sfxGain);
      osc.start(t);
      osc.stop(t + 0.25);
    });

    this.playNoise(0.05, 0.3, 2200);
  }

  playBlock() {
    this.ensureContext();
    if (!this.ctx) return;
    const t = this.ctx.currentTime;

    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = 'square';
    osc.frequency.setValueAtTime(320, t);
    osc.frequency.exponentialRampToValueAtTime(110, t + 0.09);

    gain.gain.setValueAtTime(0.5, t);
    gain.gain.exponentialRampToValueAtTime(0.01, t + 0.09);

    osc.connect(gain);
    gain.connect(this.sfxGain);
    osc.start(t);
    osc.stop(t + 0.09);
  }

  playShuriken() {
    this.ensureContext();
    if (!this.ctx) return;
    const t = this.ctx.currentTime;

    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = 'sawtooth';
    osc.frequency.setValueAtTime(950, t);
    osc.frequency.exponentialRampToValueAtTime(240, t + 0.15);

    gain.gain.setValueAtTime(0.3, t);
    gain.gain.exponentialRampToValueAtTime(0.01, t + 0.15);

    osc.connect(gain);
    gain.connect(this.sfxGain);
    osc.start(t);
    osc.stop(t + 0.15);

    this.playNoise(0.14, 0.25, 1800);
  }

  playChant() {
    this.ensureContext();
    if (!this.ctx) return;
    const t = this.ctx.currentTime;

    // Resonant Taoist Bell / Gong
    [146.8, 220, 293.7, 440].forEach((freq, i) => {
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(freq, t);

      gain.gain.setValueAtTime(0.35 / (i + 1), t);
      gain.gain.exponentialRampToValueAtTime(0.001, t + 1.6);

      osc.connect(gain);
      gain.connect(this.sfxGain);
      osc.start(t);
      osc.stop(t + 1.6);
    });
  }

  playStep() {
    this.playNoise(0.03, 0.08, 400);
  }

  playWater() {
    this.ensureContext();
    if (!this.ctx) return;
    const t = this.ctx.currentTime;

    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(520, t);
    osc.frequency.linearRampToValueAtTime(840, t + 0.08);
    osc.frequency.linearRampToValueAtTime(420, t + 0.16);

    gain.gain.setValueAtTime(0.2, t);
    gain.gain.exponentialRampToValueAtTime(0.01, t + 0.16);

    osc.connect(gain);
    gain.connect(this.sfxGain);
    osc.start(t);
    osc.stop(t + 0.16);
  }

  playDivinationPing(isCenter) {
    this.ensureContext();
    if (!this.ctx) return;
    const t = this.ctx.currentTime;

    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = 'sine';
    const freq = isCenter ? 880 : 440;
    osc.frequency.setValueAtTime(freq, t);

    gain.gain.setValueAtTime(0.2, t);
    gain.gain.exponentialRampToValueAtTime(0.005, t + 0.1);

    osc.connect(gain);
    gain.connect(this.sfxGain);
    osc.start(t);
    osc.stop(t + 0.1);
  }

  playFanfare() {
    this.ensureContext();
    if (!this.ctx) return;
    const notes = [440, 554.37, 659.25, 880];
    const t = this.ctx.currentTime;

    notes.forEach((freq, idx) => {
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      const startTime = t + (idx * 0.11);
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(freq, startTime);

      gain.gain.setValueAtTime(0.001, startTime);
      gain.gain.linearRampToValueAtTime(0.4, startTime + 0.02);
      gain.gain.exponentialRampToValueAtTime(0.001, startTime + 0.28);

      osc.connect(gain);
      gain.connect(this.sfxGain);
      osc.start(startTime);
      osc.stop(startTime + 0.28);
    });
  }

  playNoise(duration, vol, cutoff = 800) {
    if (!this.ctx) return;
    const t = this.ctx.currentTime;
    const bufferSize = this.ctx.sampleRate * duration;
    const buffer = this.ctx.createBuffer(1, bufferSize, this.ctx.sampleRate);
    const output = buffer.getChannelData(0);
    for (let i = 0; i < bufferSize; i++) {
      output[i] = Math.random() * 2 - 1;
    }

    const whiteNoise = this.ctx.createBufferSource();
    whiteNoise.buffer = buffer;

    const filter = this.ctx.createBiquadFilter();
    filter.type = 'lowpass';
    filter.frequency.setValueAtTime(cutoff, t);

    const gain = this.ctx.createGain();
    gain.gain.setValueAtTime(vol, t);
    gain.gain.exponentialRampToValueAtTime(0.01, t + duration);

    whiteNoise.connect(filter);
    filter.connect(gain);
    gain.connect(this.sfxGain);

    whiteNoise.start(t);
    whiteNoise.stop(t + duration);
  }
}

window.MoebiusAudio = MoebiusAudio;
