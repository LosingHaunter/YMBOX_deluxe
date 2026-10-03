(function initializeToolboxShell() {
  "use strict";

  const i18n = window.YMBOXI18n;
  const byId = id => document.getElementById(id);
  const toolboxElements = {
    homeView: byId("homeView"),
    toolGrid: byId("toolGrid"),
    readyToolCount: byId("readyToolCount"),
    languageSwitch: byId("languageSwitch"),
  };

  function createToolCard(tool) {
    const button = document.createElement("button");
    const isReady = tool.status === "ready";

    button.type = "button";
    button.className = `tool-card tone-${tool.tone}`;
    button.disabled = !isReady;
    button.dataset.toolId = tool.id;

    const icon = document.createElement("span");
    icon.className = "tool-card-icon";
    icon.textContent = tool.icon;

    const copy = document.createElement("span");
    copy.className = "tool-card-copy";

    const title = document.createElement("strong");
    title.textContent = tool.title;

    const subtitle = document.createElement("span");
    subtitle.textContent = tool.subtitle;

    const state = document.createElement("span");
    state.className = "tool-card-state";
    state.textContent = i18n.t(isReady ? "toolbox.open" : "toolbox.planned");

    copy.append(title, subtitle);
    button.append(icon, copy, state);

    if (isReady) {
      button.addEventListener("click", () => {
        window.location.hash = `#/${tool.id}`;
      });
    }

    return button;
  }

  function renderToolbox() {
    const tools = window.YMBOXToolbox.getTools();
    const readyCount = tools.filter(tool => tool.status === "ready").length;
    toolboxElements.readyToolCount.textContent = readyCount.toString();
    toolboxElements.toolGrid.replaceChildren(...tools.map(createToolCard));
  }

  function showRoute() {
    const routeId = window.location.hash.replace(/^#\/?/, "");
    const tool = routeId ? window.YMBOXToolbox.getTool(routeId) : null;
    const view = tool && tool.status === "ready" ? byId(tool.viewId) : null;

    document.querySelectorAll("[data-tool-view]").forEach(toolView => {
      toolView.hidden = toolView !== view;
    });

    toolboxElements.homeView.hidden = Boolean(view);
    mountLanguageSwitch(view);
    document.body.dataset.route = view ? tool.id : "home";
    document.title = view ? `${tool.title} · ${i18n.t("document.toolboxTitle")}` : i18n.t("document.toolboxTitle");
    window.scrollTo({top: 0, behavior: "auto"});
  }

  function updateLanguageSwitch() {
    const activeLocale = i18n.getLocale();
    toolboxElements.languageSwitch.querySelectorAll("[data-language]").forEach(button => {
      const active = button.dataset.language === activeLocale;
      button.classList.toggle("is-active", active);
      button.setAttribute("aria-pressed", String(active));
    });
  }

  // One switch serves every tool page: it moves into the navigation bar of the page being shown.
  function mountLanguageSwitch(view) {
    const navigation = (view || byId("ymboxConfigurationView")).querySelector(".calculator-nav");
    if (!navigation) return;
    if (toolboxElements.languageSwitch.parentElement !== navigation) navigation.append(toolboxElements.languageSwitch);
    toolboxElements.languageSwitch.hidden = false;
  }

  function refreshLocalizedChrome() {
    i18n.translate(document);
    renderToolbox();
    updateLanguageSwitch();
    showRoute();
  }

  toolboxElements.languageSwitch.addEventListener("click", event => {
    const button = event.target.closest("[data-language]");
    if (!button) return;
    if (button.dataset.language === i18n.getLocale()) {
      refreshLocalizedChrome();
      return;
    }
    i18n.setLocale(button.dataset.language);
  });

  document.querySelectorAll("[data-back-toolbox]").forEach(button => {
    button.addEventListener("click", () => {
      window.location.hash = "#/";
    });
  });

  window.addEventListener("hashchange", showRoute);
  window.addEventListener("ymbox:language-changed", refreshLocalizedChrome);

  mountLanguageSwitch();
  refreshLocalizedChrome();
})();

