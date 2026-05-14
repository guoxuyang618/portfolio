/**
 * SoundFX - 程序化合成音效管理器
 * 使用 Web Audio API 合成，无需音频文件
 * 支持：hover / click / nav / enter
 * 自动节流（避免连续 hover 爆音）
 * 右下角喇叭开关 + localStorage 记忆
 */
(function () {
  'use strict';

  const STORAGE_KEY = 'soundfx_enabled';
  const HOVER_THROTTLE_MS = 60;

  let audioCtx = null;
  let masterGain = null;
  let lastHoverTime = 0;
  let enabled = localStorage.getItem(STORAGE_KEY) !== 'false';
  let unlocked = false;

  // 初始化音频上下文（首次用户交互时）
  function initAudioContext() {
    if (audioCtx) return;
    try {
      const Ctx = window.AudioContext || window.webkitAudioContext;
      audioCtx = new Ctx();
      masterGain = audioCtx.createGain();
      masterGain.gain.value = 0.3; // 全局音量 30%
      masterGain.connect(audioCtx.destination);
    } catch (e) {
      console.warn('[SoundFX] AudioContext init failed:', e);
    }
  }

  // 解锁音频（浏览器策略：需用户交互后才能播放）
  function unlock() {
    if (unlocked) return;
    initAudioContext();
    if (audioCtx && audioCtx.state === 'suspended') {
      audioCtx.resume();
    }
    unlocked = true;
  }

  // 音效合成核心：单个振荡器
  function tone(opts) {
    if (!enabled || !audioCtx) return;
    const {
      type = 'sine',
      freq = 800,
      freqEnd = null,
      duration = 0.05,
      volume = 1,
      delay = 0
    } = opts;

    const startTime = audioCtx.currentTime + delay;
    const endTime = startTime + duration;

    const osc = audioCtx.createOscillator();
    const gain = audioCtx.createGain();

    osc.type = type;
    osc.frequency.setValueAtTime(freq, startTime);
    if (freqEnd !== null) {
      osc.frequency.exponentialRampToValueAtTime(Math.max(freqEnd, 0.01), endTime);
    }

    // ADSR 包络（防爆音）
    gain.gain.setValueAtTime(0, startTime);
    gain.gain.linearRampToValueAtTime(volume, startTime + 0.005);
    gain.gain.exponentialRampToValueAtTime(0.001, endTime);

    osc.connect(gain);
    gain.connect(masterGain);
    osc.start(startTime);
    osc.stop(endTime + 0.02);
  }

  // 4 种音效定义
  const sounds = {
    // 卡片/按钮悬停 - 极轻 UI tick
    hover: function () {
      const now = Date.now();
      if (now - lastHoverTime < HOVER_THROTTLE_MS) return;
      lastHoverTime = now;
      tone({
        type: 'triangle',
        freq: 1200,
        freqEnd: 1600,
        duration: 0.04,
        volume: 0.18
      });
    },
    // 主 CTA 点击 - 干净哒
    click: function () {
      tone({
        type: 'square',
        freq: 800,
        freqEnd: 400,
        duration: 0.06,
        volume: 0.25
      });
    },
    // 导航切换 - 轻嗖
    nav: function () {
      tone({
        type: 'sine',
        freq: 600,
        freqEnd: 900,
        duration: 0.08,
        volume: 0.3
      });
    },
    // 页面进入 - 双音叮
    enter: function () {
      tone({
        type: 'sine',
        freq: 440,
        duration: 0.18,
        volume: 0.22
      });
      tone({
        type: 'sine',
        freq: 660,
        duration: 0.2,
        volume: 0.18,
        delay: 0.06
      });
    }
  };

  // 公共播放接口
  function play(name) {
    if (!enabled) return;
    if (!audioCtx) initAudioContext();
    if (audioCtx && audioCtx.state === 'suspended') {
      audioCtx.resume();
    }
    if (sounds[name]) sounds[name]();
  }

  // 切换开关
  function setEnabled(value) {
    enabled = !!value;
    localStorage.setItem(STORAGE_KEY, enabled);
    updateToggleUI();
    if (enabled) {
      unlock();
    }
  }

  // ===== 喇叭开关 UI =====
  function createToggle() {
    if (document.getElementById('sfx-toggle')) return;
    const btn = document.createElement('button');
    btn.id = 'sfx-toggle';
    btn.setAttribute('aria-label', 'Toggle sound effects');
    btn.innerHTML = `
      <svg class="sfx-icon-on" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/>
        <path d="M15.54 8.46a5 5 0 0 1 0 7.07"/>
        <path d="M19.07 4.93a10 10 0 0 1 0 14.14"/>
      </svg>
      <svg class="sfx-icon-off" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/>
        <line x1="23" y1="9" x2="17" y2="15"/>
        <line x1="17" y1="9" x2="23" y2="15"/>
      </svg>
    `;
    document.body.appendChild(btn);

    btn.addEventListener('click', function (e) {
      e.stopPropagation();
      setEnabled(!enabled);
      if (enabled) play('click');
    });

    // 悬停音效
    btn.addEventListener('mouseenter', () => play('hover'));
    updateToggleUI();
  }

  function updateToggleUI() {
    const btn = document.getElementById('sfx-toggle');
    if (!btn) return;
    btn.classList.toggle('sfx-off', !enabled);
  }

  // ===== 自动绑定事件 =====
  function bindEvents() {
    // 全局事件委托 - 用 mouseover + relatedTarget 判断（mouseenter 不冒泡）
    const HOVER_SELECTOR = '.project-card, .ability-card, .work-card, .service-card, .principle-card, .highlight-card, .nav-cta, .card-cta, .lang-toggle, .filter-btn, .hero-cta, .btn-primary, .btn-secondary, .timeline-item, .tool-chip, .life-item, .nav-link';

    document.addEventListener('mouseover', function (e) {
      const target = e.target.closest && e.target.closest(HOVER_SELECTOR);
      if (!target) return;
      // 检查 relatedTarget 是否在同一悬停目标内（避免子元素切换重复触发）
      const related = e.relatedTarget;
      if (related && target.contains(related)) return;
      play('hover');
    });

    // 导航/CTA 点击委托
    const NAV_SELECTOR = '.nav-link, .footer-col a';
    const CTA_SELECTOR = '.nav-cta, .hero-cta, .card-cta, .btn-primary, .lang-toggle, .filter-btn, .section-cta a, .section-cta button';

    document.addEventListener('click', function (e) {
      // 优先匹配 CTA
      const ctaTarget = e.target.closest && e.target.closest(CTA_SELECTOR);
      if (ctaTarget) {
        play('click');
        return;
      }
      // 然后匹配导航
      const navTarget = e.target.closest && e.target.closest(NAV_SELECTOR);
      if (navTarget) {
        play('nav');
        return;
      }
    }, true);
  }

  // ===== 初始化 =====
  function init() {
    createToggle();
    bindEvents();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

  // 暴露公共 API
  window.SoundFX = {
    play: play,
    enable: () => setEnabled(true),
    disable: () => setEnabled(false),
    toggle: () => setEnabled(!enabled),
    isEnabled: () => enabled
  };
})();
