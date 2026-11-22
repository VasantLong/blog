/* 界面语言层（UI i18n）：同一份 URL，只在浏览器里替换界面文案，不动正文。
   中文原文由服务端渲染，这里负责 zh <-> en 互换；<html data-ui-lang> 由 head 的引导脚本先设好。 */
(function () {
  "use strict";

  var KEY = "uiLang";
  var dict = window.__UI_I18N__ || {};
  var strings = dict.strings || {};
  var patterns = dict.patterns || [];
  var root = document.documentElement;

  /* 正文与标题永不替换；data-ui-skip 供切换器自己豁免 */
  var SKIP = ".article-content,.article-link__summary,article h1,pre,code,kbd,samp,textarea,script,style,[data-ui-skip]";
  var ATTRS = ["title", "aria-label", "placeholder", "alt"];

  var compiled = [];
  for (var i = 0; i < patterns.length; i++) {
    compiled.push({ p: patterns[i], re: new RegExp(patterns[i].re) });
  }

  var textNodes = [];
  var attrNodes = [];

  function fill(tpl, match) {
    return tpl.replace(/\$(\d)/g, function (_, digit) {
      var value = match[+digit];
      return value === undefined ? "" : value;
    });
  }

  function translate(text) {
    var hit = strings[text];
    if (typeof hit === "string") return hit;
    for (var i = 0; i < compiled.length; i++) {
      var pattern = compiled[i].p;
      var match = text.match(compiled[i].re);
      if (!match) continue;
      if (pattern.one || pattern.other) {
        var count = parseInt(match[1], 10);
        var plural = count === 1 ? pattern.one || pattern.other : pattern.other || pattern.one;
        return fill(plural, match);
      }
      if (pattern.en) return fill(pattern.en, match);
    }
    return null;
  }

  function applyText(node) {
    if (node.__uiZh !== undefined) return;
    var raw = node.data;
    if (!raw) return;
    var core = raw.trim();
    if (!core) return;
    var out = translate(core);
    if (out === null || out === core) return;
    node.__uiZh = raw;
    textNodes.push(node);
    node.data = raw.replace(core, out);
  }

  function applyAttrs(el) {
    for (var i = 0; i < ATTRS.length; i++) {
      var attr = ATTRS[i];
      var raw = el.getAttribute(attr);
      if (!raw) continue;
      var core = raw.trim();
      if (!core) continue;
      var store = el.__uiZhAttr || (el.__uiZhAttr = {});
      if (store[attr] !== undefined) continue;
      var out = translate(core);
      if (out === null || out === core) continue;
      store[attr] = raw;
      el.setAttribute(attr, raw.replace(core, out));
      if (attrNodes.indexOf(el) === -1) attrNodes.push(el);
    }
  }

  function skipped(node) {
    var el = node.nodeType === 1 ? node : node.parentElement;
    return !!(el && el.closest(SKIP));
  }

  function translateAll() {
    var walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, null);
    var batch = [];
    var node;
    while ((node = walker.nextNode())) batch.push(node);
    for (var i = 0; i < batch.length; i++) {
      if (!skipped(batch[i])) applyText(batch[i]);
    }
    var els = document.querySelectorAll("[title],[aria-label],[placeholder],[alt]");
    for (var j = 0; j < els.length; j++) applyAttrs(els[j]);
  }

  function restoreAll() {
    for (var i = 0; i < textNodes.length; i++) {
      textNodes[i].data = textNodes[i].__uiZh;
      delete textNodes[i].__uiZh;
    }
    for (var j = 0; j < attrNodes.length; j++) {
      var store = attrNodes[j].__uiZhAttr || {};
      for (var attr in store) attrNodes[j].setAttribute(attr, store[attr]);
      delete attrNodes[j].__uiZhAttr;
    }
    textNodes = [];
    attrNodes = [];
  }

  function current() {
    return root.getAttribute("data-ui-lang") === "en" ? "en" : "zh";
  }

  function syncButtons() {
    var buttons = document.querySelectorAll("[data-ui-lang-btn]");
    for (var i = 0; i < buttons.length; i++) {
      var pressed = buttons[i].getAttribute("data-ui-lang-btn") === current();
      buttons[i].setAttribute("aria-pressed", pressed ? "true" : "false");
    }
  }

  function setLang(lang, persist) {
    lang = lang === "en" ? "en" : "zh";
    if (persist) {
      try {
        localStorage.setItem(KEY, lang);
      } catch (error) {
        /* localStorage 在隐私模式/被禁用时会抛错，降级为「只在本次页面生效」 */
        void error;
      }
    }
    root.setAttribute("data-ui-lang", lang);
    if (lang === "en") translateAll();
    else restoreAll();
    syncButtons();
  }

  document.addEventListener("click", function (event) {
    var target = event.target;
    if (!target || !target.closest) return;
    var button = target.closest("[data-ui-lang-btn]");
    if (!button) return;
    event.preventDefault();
    setLang(button.getAttribute("data-ui-lang-btn"), true);
  });

  window.addEventListener("storage", function (event) {
    if (event.key === KEY) setLang(event.newValue, false);
  });

  function boot() {
    if (current() === "en") translateAll();
    syncButtons();
  }

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", boot);
  else boot();
})();
