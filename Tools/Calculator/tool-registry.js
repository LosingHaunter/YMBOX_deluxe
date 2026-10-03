(function initializeToolRegistry(global) {
  const tools = [];
  const validStatuses = new Set(["ready", "planned"]);
  const i18n = global.YMBOXI18n;

  function registerTool(definition) {
    const required = ["id", "titleKey", "subtitleKey", "icon", "tone", "status", "viewId"];
    required.forEach((key) => {
      if (!definition[key]) {
        throw new Error(`YMBOX tool registration is missing: ${key}`);
      }
    });

    if (!validStatuses.has(definition.status)) {
      throw new Error(`Unsupported YMBOX tool status: ${definition.status}`);
    }

    if (tools.some((tool) => tool.id === definition.id)) {
      throw new Error(`Duplicate YMBOX tool id: ${definition.id}`);
    }

    tools.push(Object.freeze({ ...definition }));
  }

  function localizeTool(tool) {
    return Object.freeze({
      ...tool,
      title: i18n.t(tool.titleKey),
      subtitle: i18n.t(tool.subtitleKey),
    });
  }

  global.YMBOXToolbox = Object.freeze({
    registerTool,
    getTools: () => tools.map(localizeTool),
    getTool: (id) => {
      const tool = tools.find((candidate) => candidate.id === id);
      return tool ? localizeTool(tool) : undefined;
    },
  });

  registerTool({
    id: "motor-super-calculator",
    titleKey: "tools.motor.title",
    subtitleKey: "tools.motor.subtitle",
    icon: "M+",
    tone: "green",
    status: "ready",
    viewId: "motorCalculatorView",
  });

  registerTool({
    id: "ymbox-configuration",
    titleKey: "tools.ymbox.title",
    subtitleKey: "tools.ymbox.subtitle",
    icon: "YM",
    tone: "blue",
    status: "ready",
    viewId: "ymboxConfigurationView",
  });

  registerTool({
    id: "reserved-tool-04",
    titleKey: "tools.reserved04.title",
    subtitleKey: "tools.reserved04.subtitle",
    icon: "04",
    tone: "pink",
    status: "planned",
    viewId: "reservedTool04",
  });
})(window);
