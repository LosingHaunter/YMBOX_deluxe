(function initializeYMBOXI18n(global) {
  "use strict";

  const defaultLocale = "en";
  const supportedLocales = Object.freeze(["en", "zh-CN"]);
  const catalogs = {
    en: {
      "document.toolboxTitle": "YMBOX Toolbox",
      "toolbox.title": "YMBOX Toolbox",
      "toolbox.toolCountLabel": "Tool count",
      "toolbox.availableTools": " tools available",
      "toolbox.chooseTool": "Choose a tool",
      "toolbox.open": "Open →",
      "toolbox.planned": "Planned",
      "navigation.backToToolbox": "Back to toolbox",
      "language.label": "Language",
      "language.english": "English",
      "language.chinese": "中文",
      "tools.motor.title": "Motor Parameter Calculator",
      "tools.motor.subtitle": "Flux · Kt · Phase/line parameters",
      "tools.ymbox.title": "YMBOX Configuration",
      "tools.ymbox.subtitle": "Model parameters · Recommendations · JSON export",
      "tools.reserved04.title": "Reserved Tool 04",
      "tools.reserved04.subtitle": "Coming later"
    },
    "zh-CN": {
      "document.toolboxTitle": "YMBOX 工具箱",
      "toolbox.title": "YMBOX 工具箱",
      "toolbox.toolCountLabel": "工具数量",
      "toolbox.availableTools": "个可用工具",
      "toolbox.chooseTool": "选择工具",
      "toolbox.open": "打开 →",
      "toolbox.planned": "待添加",
      "navigation.backToToolbox": "返回工具箱",
      "language.label": "语言",
      "language.english": "English",
      "language.chinese": "中文",
      "tools.motor.title": "电机全参数超级计算器",
      "tools.motor.subtitle": "磁链 · Kt · 相线参数",
      "tools.ymbox.title": "YMBOX配置工具",
      "tools.ymbox.subtitle": "模型全参数 · 推荐 · JSON 导出",
      "tools.reserved04.title": "预留工具 04",
      "tools.reserved04.subtitle": "待添加"
    }
  };
  const textMaps = {en: new Map(), "zh-CN": new Map()};
  const textRules = {en: [], "zh-CN": []};
  const textNodeState = new WeakMap();
  const attributeState = new WeakMap();

  let locale = defaultLocale;

  function normalizeLocale(value) {
    const candidate = String(value || "").trim().toLowerCase();
    if (candidate === "zh" || candidate === "zh-cn" || candidate === "zh-hans") return "zh-CN";
    return "en";
  }

  function interpolate(template, parameters = {}) {
    return String(template).replace(/\{([A-Za-z0-9_]+)\}/g, (match, name) =>
      Object.hasOwn(parameters, name) ? String(parameters[name]) : match);
  }

  function translate(key, parameters) {
    const template = catalogs[locale]?.[key] ?? catalogs[defaultLocale]?.[key] ?? key;
    return interpolate(template, parameters);
  }

  function registerCatalog(targetLocale, entries) {
    const normalized = normalizeLocale(targetLocale);
    if (!entries || typeof entries !== "object" || Array.isArray(entries)) {
      throw new TypeError("Translation catalog entries must be an object.");
    }
    Object.assign(catalogs[normalized], entries);
  }

  function registerTextMap(targetLocale, entries) {
    const normalized = normalizeLocale(targetLocale);
    if (!entries || typeof entries !== "object" || Array.isArray(entries)) {
      throw new TypeError("Localized text entries must be an object.");
    }
    for (const [source, translated] of Object.entries(entries)) {
      textMaps[normalized].set(source, String(translated));
    }
  }

  function registerTextRules(targetLocale, rules) {
    const normalized = normalizeLocale(targetLocale);
    if (!Array.isArray(rules)) throw new TypeError("Localized text rules must be an array.");
    for (const rule of rules) {
      if (!(rule?.pattern instanceof RegExp) || !(typeof rule.replace === "string" || typeof rule.replace === "function")) {
        throw new TypeError("Each localized text rule needs a RegExp pattern and replacement.");
      }
      textRules[normalized].push(rule);
    }
  }

  function translateText(value) {
    const source = String(value ?? "");
    if (locale === "zh-CN") return source;
    const exact = textMaps[locale].get(source);
    if (exact !== undefined) return exact;
    for (const rule of textRules[locale]) {
      rule.pattern.lastIndex = 0;
      if (rule.pattern.test(source)) {
        rule.pattern.lastIndex = 0;
        return source.replace(rule.pattern, rule.replace);
      }
    }
    return source;
  }

  function translateTextNode(node) {
    const current = node.nodeValue || "";
    let state = textNodeState.get(node);
    if (!state || current !== state.rendered) {
      const match = current.match(/^(\s*)([\s\S]*?)(\s*)$/);
      state = {leading: match[1], source: match[2], trailing: match[3], rendered: current};
    }
    const rendered = `${state.leading}${translateText(state.source)}${state.trailing}`;
    state.rendered = rendered;
    textNodeState.set(node, state);
    if (current !== rendered) node.nodeValue = rendered;
  }

  function translateAttribute(node, attribute) {
    if (!node.hasAttribute(attribute)) return;
    const current = node.getAttribute(attribute);
    let states = attributeState.get(node);
    if (!states) {
      states = new Map();
      attributeState.set(node, states);
    }
    let state = states.get(attribute);
    if (!state || current !== state.rendered) state = {source: current, rendered: current};
    const rendered = translateText(state.source);
    state.rendered = rendered;
    states.set(attribute, state);
    if (current !== rendered) node.setAttribute(attribute, rendered);
  }

  function translateFreeText(root) {
    const visitElement = node => {
      for (const attribute of ["placeholder", "title", "aria-label"]) translateAttribute(node, attribute);
    };
    if (root.nodeType === Node.TEXT_NODE) {
      translateTextNode(root);
      return;
    }
    if (root.nodeType === Node.ELEMENT_NODE) visitElement(root);
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_ELEMENT | NodeFilter.SHOW_TEXT);
    while (walker.nextNode()) {
      if (walker.currentNode.nodeType === Node.TEXT_NODE) translateTextNode(walker.currentNode);
      else visitElement(walker.currentNode);
    }
  }

  function matchingNodes(root, selector) {
    const nodes = [...root.querySelectorAll(selector)];
    if (root.nodeType === 1 && root.matches(selector)) nodes.unshift(root);
    return nodes;
  }

  function translateDom(root = document) {
    matchingNodes(root, "[data-i18n]").forEach((node) => {
      node.textContent = translate(node.dataset.i18n);
    });
    for (const [attribute, selector] of [
      ["placeholder", "[data-i18n-placeholder]"],
      ["aria-label", "[data-i18n-aria-label]"],
      ["title", "[data-i18n-title]"]
    ]) {
      matchingNodes(root, selector).forEach((node) => {
        const key = node.dataset[`i18n${attribute.split("-").map(part => part[0].toUpperCase() + part.slice(1)).join("")}`];
        node.setAttribute(attribute, translate(key));
      });
    }
    translateFreeText(root);
  }

  function setLocale(nextLocale) {
    const next = normalizeLocale(nextLocale);
    if (next === locale) {
      document.documentElement.lang = next;
      translateDom(document);
      return locale;
    }
    locale = next;
    document.documentElement.lang = locale;
    translateDom(document);
    global.dispatchEvent(new CustomEvent("ymbox:language-changed", {detail: {locale}}));
    return locale;
  }

  document.documentElement.lang = locale;
  const observer = new MutationObserver(records => {
    for (const record of records) {
      if (record.type === "characterData") translateTextNode(record.target);
      else if (record.type === "attributes") translateAttribute(record.target, record.attributeName);
      else for (const node of record.addedNodes) translateFreeText(node);
    }
  });
  observer.observe(document.documentElement, {
    subtree: true,
    childList: true,
    characterData: true,
    attributes: true,
    attributeFilter: ["placeholder", "title", "aria-label"]
  });
  global.YMBOXI18n = Object.freeze({
    defaultLocale,
    supportedLocales,
    getLocale: () => locale,
    setLocale,
    t: translate,
    text: translateText,
    registerCatalog,
    registerTextMap,
    registerTextRules,
    translate: translateDom
  });
})(window);
