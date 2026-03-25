/**
 * i18n 中英文切换脚本
 * 通过 data-i18n 属性标记需翻译的元素
 * data-i18n-html 标记需要用 innerHTML 替换的元素（含 <br/> 等）
 * 语言状态存储在 localStorage 中，跨页面保持一致
 */
(function () {
  let i18nData = null;
  let currentLang = localStorage.getItem('lang') || 'en';

  // 加载翻译数据
  async function loadI18nData() {
    if (i18nData) return i18nData;
    try {
      const resp = await fetch('/i18n.json');
      i18nData = await resp.json();
      return i18nData;
    } catch (e) {
      console.error('Failed to load i18n data:', e);
      return null;
    }
  }

  // 获取嵌套对象值: "nav.home" => data.nav.home
  function getNestedValue(obj, path) {
    return path.split('.').reduce((acc, key) => acc && acc[key], obj);
  }

  // 翻译页面
  function translatePage(lang) {
    if (!i18nData) return;

    // 翻译所有 data-i18n 元素（textContent）
    document.querySelectorAll('[data-i18n]').forEach(el => {
      const key = el.getAttribute('data-i18n');
      const entry = getNestedValue(i18nData, key);
      if (entry && entry[lang]) {
        el.textContent = entry[lang];
      }
    });

    // 翻译所有 data-i18n-html 元素（innerHTML，支持 <br/> 等）
    document.querySelectorAll('[data-i18n-html]').forEach(el => {
      const key = el.getAttribute('data-i18n-html');
      const entry = getNestedValue(i18nData, key);
      if (entry && entry[lang]) {
        el.innerHTML = entry[lang];
      }
    });

    // 翻译动态内容：works 卡片标题、分类、描述等
    translateDynamicContent(lang);

    // 更新按钮状态
    updateToggleButton(lang);

    // 更新 html lang 属性
    document.documentElement.lang = lang === 'zh' ? 'zh-CN' : 'en';
  }

  // 翻译动态渲染的内容（works 卡片、分类标签等）
  function translateDynamicContent(lang) {
    if (!i18nData) return;

    // 翻译分类名称 (首页卡片标题 + works页筛选标签)
    document.querySelectorAll('[data-i18n-category]').forEach(el => {
      const category = el.getAttribute('data-i18n-category');
      const entry = i18nData.categories && i18nData.categories[category];
      if (entry && entry[lang]) {
        el.textContent = entry[lang];
      }
    });

    // 翻译项目标题
    document.querySelectorAll('[data-i18n-title]').forEach(el => {
      const title = el.getAttribute('data-i18n-title');
      const entry = i18nData.projectTitles && i18nData.projectTitles[title];
      if (entry && entry[lang]) {
        el.textContent = entry[lang];
      }
    });

    // 翻译项目描述
    document.querySelectorAll('[data-i18n-desc]').forEach(el => {
      const projectId = el.getAttribute('data-i18n-desc');
      const entry = i18nData.projectDescriptions && i18nData.projectDescriptions[projectId];
      if (entry && entry.description && entry.description[lang]) {
        el.textContent = entry.description[lang];
      }
    });

    // 翻译项目案例
    document.querySelectorAll('[data-i18n-case]').forEach(el => {
      const projectId = el.getAttribute('data-i18n-case');
      const entry = i18nData.projectDescriptions && i18nData.projectDescriptions[projectId];
      if (entry && entry.case && entry.case[lang]) {
        el.textContent = entry.case[lang];
      }
    });

    // 翻译 "X Projects" 文本
    document.querySelectorAll('[data-i18n-projects-count]').forEach(el => {
      const count = el.getAttribute('data-i18n-projects-count');
      el.textContent = lang === 'zh' ? count + ' 个项目' : count + ' Projects';
    });

    // 翻译详情页图文段落标题 (格式: "projectId:imageIndex")
    document.querySelectorAll('[data-i18n-img-title]').forEach(el => {
      const val = el.getAttribute('data-i18n-img-title');
      if (!val) return;
      const [projectId, imgIdx] = val.split(':');
      const entry = i18nData.projectDescriptions && i18nData.projectDescriptions[projectId];
      if (entry && entry.images && entry.images[imgIdx] && entry.images[imgIdx].title && entry.images[imgIdx].title[lang]) {
        el.textContent = entry.images[imgIdx].title[lang];
      }
    });

    // 翻译详情页图文段落描述 (格式: "projectId:imageIndex")
    document.querySelectorAll('[data-i18n-img-text]').forEach(el => {
      const val = el.getAttribute('data-i18n-img-text');
      if (!val) return;
      const [projectId, imgIdx] = val.split(':');
      const entry = i18nData.projectDescriptions && i18nData.projectDescriptions[projectId];
      if (entry && entry.images && entry.images[imgIdx] && entry.images[imgIdx].text && entry.images[imgIdx].text[lang]) {
        el.textContent = entry.images[imgIdx].text[lang];
      }
    });

    // 翻译详情页视频字幕 (格式: "projectId:imageIndex:captionIndex")
    document.querySelectorAll('[data-i18n-img-caption]').forEach(el => {
      const val = el.getAttribute('data-i18n-img-caption');
      if (!val) return;
      const parts = val.split(':');
      const projectId = parts[0];
      const imgIdx = parts[1];
      const captionIdx = parts[2];
      const entry = i18nData.projectDescriptions && i18nData.projectDescriptions[projectId];
      if (entry && entry.images && entry.images[imgIdx] && entry.images[imgIdx].captions && entry.images[imgIdx].captions[captionIdx] && entry.images[imgIdx].captions[captionIdx][lang]) {
        el.textContent = entry.images[imgIdx].captions[captionIdx][lang];
      }
    });
  }

  // 更新切换按钮状态
  function updateToggleButton(lang) {
    const btn = document.getElementById('langToggle');
    if (!btn) return;
    const label = btn.querySelector('.lang-label');
    if (label) {
      label.textContent = lang === 'en' ? 'EN' : '中';
    }
  }

  // 切换语言
  function toggleLanguage() {
    currentLang = currentLang === 'en' ? 'zh' : 'en';
    localStorage.setItem('lang', currentLang);
    translatePage(currentLang);
  }

  // 初始化
  async function init() {
    await loadI18nData();

    // 绑定切换按钮
    const btn = document.getElementById('langToggle');
    if (btn) {
      btn.addEventListener('click', function (e) {
        e.preventDefault();
        toggleLanguage();
      });
    }

    // 如果存储的语言是中文，立即翻译
    if (currentLang === 'zh') {
      translatePage('zh');
    } else {
      updateToggleButton('en');
    }
  }

  // DOM 加载后初始化
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
