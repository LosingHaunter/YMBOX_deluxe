(function initializeMotorSuperCalculator() {
  const TAU = Math.PI * 2;
  const SQRT2 = Math.sqrt(2);
  const SQRT3 = Math.sqrt(3);
  const OMEGA_AT_1000_RPM = (1000 * TAU) / 60;

  const categories = [
    {
      title: "电机基本参数与转速",
      fields: [
        ["polePairs", "极对数", "p", "-", "极数，或磁链 + 任一 Ke/Kt"],
        ["speedRpm", "机械转速", "n", "rpm", "机械角速度"],
        ["omegaM", "机械角速度", "ωm", "rad/s", "机械转速"],
        ["maxSpeedRpm", "最大机械转速", "nmax", "rpm", "厂家机械转速上限，与当前计算转速分开填写"],
      ],
    },
    {
      title: "机械功率与转矩",
      fields: [
        ["inertia", "转动惯量", "J", "kg·m²", "手动输入或电机辨识结果"],
        ["viscousFriction", "黏性摩擦系数", "B", "N·m·s", "厂家或辨识数据；N·m/krpm 除以 (1000 × 2π/60)"],
        ["maxTorque", "最大转矩", "Tmax", "N·m", "手动输入最大转矩"],
        ["ratedTorque", "额定转矩", "Trated", "N·m", "额定线电流 + 线电流 RMS Kt，或功率 + 转速"],
        ["powerKw", "额定机械功率", "Prated", "kW", "额定转矩 + 转速"],
      ],
    },
    {
      title: "电阻与电感",
      advancedTitle: "凸极比与时间常数",
      fields: [
        ["rLine", "线电阻", "Rline", "Ω", "相电阻 + 绕组接法"],
        ["rPhase", "相电阻", "Rphase", "Ω", "线电阻 + 绕组接法"],
        ["lLine", "线电感（SPM）", "Lline", "mH", "SPM：相电感 + 绕组接法"],
        ["lPhase", "相电感（SPM）", "Lphase", "mH", "SPM：线电感 + 绕组接法"],
        ["ld", "d 轴相电感", "Ld", "mH", "SPM：相/线电感；IPM：Lq + 凸极比"],
        ["lq", "q 轴相电感", "Lq", "mH", "SPM：相/线电感；IPM：Ld + 凸极比"],
        ["saliency", "凸极比", "Lq/Ld", "-", "IPM：Ld + Lq；SPM 默认为 1"],
        ["tauPhase", "相电气时间常数（SPM）", "τphase", "ms", "SPM：相电感 + 相电阻"],
        ["tauD", "d 轴时间常数", "τd", "ms", "Ld + 相电阻"],
        ["tauQ", "q 轴时间常数", "τq", "ms", "Lq + 相电阻"],
      ],
    },
    {
      title: "相 / 线电压电流",
      advancedTitle: "铜耗与电压利用率",
      fields: [
        ["vBus", "母线电压", "Vdc", "V", "手动输入直流母线电压"],
        ["vLine", "SVPWM 最大线电压 RMS", "Vline,rms", "V", "母线电压"],
        ["vPhase", "最大绕组相电压 RMS", "Vphase,rms", "V", "母线电压 + 绕组接法"],
        ["ratedCurrent", "额定线电流 RMS", "Irated", "A", "手动输入额定电流"],
        ["iPhase", "额定相电流 RMS", "Iphase,rms", "A", "额定线电流 + 绕组接法"],
        ["maxPhasePeak", "最大相电流峰值", "Imax,pk", "A", "已知电流上限时直接导入；优先于最大转矩反推电流"],
        ["copperLoss", "额定三相铜耗", "Pcu,rated", "W", "相电阻 + 额定相电流"],
        ["voltageUtilization", "反电势电压利用率", "Ell/Vline", "%", "线反电势 + 母线电压"],
      ],
    },
    {
      title: "磁链、反电势常数与转矩系数",
      advancedTitle: "反电势常数与转速常数",
      fields: [
        ["psiFlux", "永磁体每相峰值磁链", "ψf", "Wb", "极对数 + 任一 Ke/Kt"],
        ["kePhasePeak", "相反电势峰值常数", "Ke,ph,pk", "V/(rad/s)", "ψf + 极对数"],
        ["kePhaseRms", "相反电势 RMS 常数", "Ke,ph,rms", "V/(rad/s)", "任一 Ke"],
        ["keLineRms", "线反电势 RMS 常数", "Ke,ll,rms", "V/(rad/s)", "任一 Ke/Kt"],
        ["keLineKrpm", "线反电势 RMS 常数", "Ke,ll", "V/krpm", "任一 Ke，或 Kv"],
        ["kv", "转速常数", "Kv", "rpm/V", "线反电势 V/krpm"],
        ["ktIqPeak", "dq 峰值电流转矩系数", "Kt,iq,pk", "N·m/Apeak", "ψf + 极对数"],
        ["ktPhaseRms", "相电流 RMS 转矩系数", "Kt,ph,rms", "N·m/Arms", "任一 Kt/Ke"],
        ["ktLineRms", "线电流 RMS 转矩系数", "Kt,ll,rms", "N·m/Aline", "相 RMS Kt + 绕组接法"],
      ],
    },
    {
      title: "指定转速下的反电势",
      fields: [
        ["emfPhasePeak", "相反电势峰值", "Eph,pk", "V", "相峰值 Ke + 机械转速"],
        ["emfPhaseRms", "相反电势 RMS", "Eph,rms", "V", "相 RMS Ke + 机械转速"],
        ["emfLineRms", "线反电势 RMS", "Ell,rms", "V", "线 RMS Ke + 机械转速"],
      ],
    },
  ];

  const fields = categories.flatMap((category) =>
    category.fields.map(([id, name, symbol, unit, requirement]) => ({
      id,
      name,
      symbol,
      unit,
      requirement,
    }))
  );

  const fieldById = new Map(fields.map((field) => [field.id, field]));
  const parameterGroups = [
    [["speedRpm", "rpm"], ["omegaM", "rad/s"]],
    [["rLine", "线电阻"], ["rPhase", "相电阻"]],
    [["lLine", "线电感"], ["lPhase", "相电感"]],
    [["vLine", "线电压"], ["vPhase", "相电压"]],
    [["ratedCurrent", "线电流"], ["iPhase", "相电流"]],
    [["keLineRms", "线 RMS"], ["kePhaseRms", "相 RMS"], ["kePhasePeak", "相峰值"]],
    [["ktLineRms", "线电流"], ["ktPhaseRms", "相电流"]],
    [["emfLineRms", "线 RMS"], ["emfPhaseRms", "相 RMS"], ["emfPhasePeak", "相峰值"]],
  ];
  const groupById = new Map(parameterGroups.flatMap((group) => group.map(([id]) => [id, group])));
  const advancedFieldIds = new Set([
    "saliency", "tauPhase", "tauD", "tauQ", "copperLoss", "voltageUtilization",
    "kePhasePeak", "kePhaseRms", "keLineRms", "kv", "emfPhasePeak", "emfPhaseRms", "emfLineRms",
  ]);
  const positiveOnlyIds = new Set([
    "polePairs", "maxSpeedRpm", "inertia", "maxTorque", "ratedTorque", "powerKw", "rPhase", "rLine", "lPhase", "lLine", "ld", "lq", "saliency",
    "tauPhase", "tauD", "tauQ", "psiFlux", "kePhasePeak", "kePhaseRms", "keLineRms",
    "keLineKrpm", "kv", "ktIqPeak", "ktPhaseRms", "ktLineRms", "vBus", "vLine", "vPhase",
    "ratedCurrent", "iPhase", "maxPhasePeak", "copperLoss", "voltageUtilization",
  ]);
  const integerIds = new Set(["polePairs"]);
  const tableBody = document.getElementById("motorParameterRows");
  const advancedTableBody = document.getElementById("motorAdvancedParameterRows");
  const advancedPanel = document.getElementById("motorAdvancedParameters");
  const advancedToggle = document.getElementById("motorAdvancedToggle");
  const advancedState = document.getElementById("motorAdvancedState");
  const advancedSummary = document.getElementById("motorAdvancedSummary");
  const advancedDescription = advancedSummary.textContent;
  const topologySelect = document.getElementById("motorTopology");
  const connectionSelect = document.getElementById("motorConnection");
  const calculateButton = document.getElementById("motorCalculateButton");
  const clearButton = document.getElementById("motorClearButton");
  const messagePanel = document.getElementById("motorMessagePanel");
  const inputById = new Map();
  const statusById = new Map();
  const viewsById = new Map();
  const variantButtonById = new Map();

  function createParameterTable() {
    const renderedIds = new Set();
    [false, true].forEach((advanced) => {
      const fragment = document.createDocumentFragment();
      categories.forEach((category) => {
        const categoryFields = category.fields.filter(([id]) => advancedFieldIds.has(id) === advanced);
        if (!categoryFields.length) return;

        const categoryRow = document.createElement("tr");
        categoryRow.className = "motor-category-row";
        const categoryCell = document.createElement("th");
        categoryCell.colSpan = 5;
        categoryCell.textContent = advanced ? category.advancedTitle || category.title : category.title;
        categoryRow.append(categoryCell);
        fragment.append(categoryRow);

        categoryFields.forEach(([id]) => {
          if (renderedIds.has(id)) return;
          const group = groupById.get(id) || [[id, ""]];
          fragment.append(createParameterRow(group));
          group.forEach(([fieldId]) => renderedIds.add(fieldId));
        });
      });
      (advanced ? advancedTableBody : tableBody).append(fragment);
    });
  }

  function createParameterRow(group) {
    const row = document.createElement("tr");
    row.className = "motor-parameter-row";
    const nameCell = document.createElement("th");
    nameCell.scope = "row";
    const nameLabel = document.createElement("div");
    nameCell.append(nameLabel);
    const symbolCell = document.createElement("td");
    symbolCell.className = "motor-symbol-cell";
    const valueCell = document.createElement("td");
    const unitCell = document.createElement("td");
    unitCell.className = "motor-unit-cell";
    const statusCell = document.createElement("td");
    statusCell.className = "motor-status-cell";
    row.append(nameCell, symbolCell, valueCell, unitCell, statusCell);

    const switcher = document.createElement("div");
    switcher.className = "motor-parameter-switch";
    switcher.setAttribute("role", "group");
    switcher.setAttribute("aria-label", `${group.map(([id]) => fieldById.get(id).name).join(" / ")}切换`);

    group.forEach(([id, buttonLabel]) => {
      const field = fieldById.get(id);
      const name = document.createElement("span");
      name.textContent = field.name;
      const symbol = document.createElement("span");
      symbol.textContent = field.symbol;
      const unit = document.createElement("span");
      unit.textContent = field.unit;
      const status = document.createElement("span");
      const input = document.createElement("input");
      input.id = `motor-${id}`;
      input.type = "text";
      input.inputMode = "decimal";
      input.autocomplete = "off";
      input.setAttribute("aria-label", `${field.name} ${field.unit}`);
      window.YMBOXNumberFormat.bindInput(input);
      input.addEventListener("input", () => {
        // A row is one editable quantity; the last edited form owns its input.
        group.forEach(([otherId]) => {
          const otherInput = inputById.get(otherId);
          if (otherId !== id) window.YMBOXNumberFormat.writeInput(otherInput, "");
          otherInput.dataset.generated = "false";
          otherInput.classList.remove("is-generated", "has-conflict");
          const otherStatus = statusById.get(otherId);
          otherStatus.textContent = otherId === id && input.value.trim() ? "已修改，等待计算" : "";
          otherStatus.className = "";
        });
        updateParameterIndicators();
      });
      input.addEventListener("keydown", (event) => {
        if (event.key === "Enter") calculateAll();
      });

      nameLabel.append(name);
      symbolCell.append(symbol);
      valueCell.append(input);
      unitCell.append(unit);
      statusCell.append(status);
      inputById.set(id, input);
      statusById.set(id, status);
      viewsById.set(id, [name, symbol, input, unit, status]);

      if (group.length > 1) {
        const button = document.createElement("button");
        button.type = "button";
        button.textContent = buttonLabel;
        button.title = field.name;
        button.dataset.parameterId = id;
        button.setAttribute("aria-controls", input.id);
        button.addEventListener("click", () => {
          if (button.getAttribute("aria-pressed") === "true") return;
          selectParameterVariant(id);
          if ([...inputById.values()].some((item) => item.value.trim())) calculateAll();
        });
        variantButtonById.set(id, button);
        switcher.append(button);
      }
    });

    if (group.length > 1) nameCell.append(switcher);
    selectParameterVariant(group[0][0]);
    return row;
  }

  function selectParameterVariant(id) {
    const group = groupById.get(id) || [[id, ""]];
    group.forEach(([fieldId]) => {
      const selected = fieldId === id;
      viewsById.get(fieldId).forEach((element) => { element.hidden = !selected; });
      variantButtonById.get(fieldId)?.setAttribute("aria-pressed", String(selected));
    });
    inputById.get(id).closest("tr").dataset.parameterId = id;
  }

  function setAdvancedExpanded(expanded) {
    advancedPanel.hidden = !expanded;
    advancedToggle.setAttribute("aria-expanded", String(expanded));
    advancedState.textContent = expanded ? "收起" : "展开";
  }

  function updateParameterIndicators() {
    variantButtonById.forEach((button, id) => {
      button.classList.toggle("has-conflict", inputById.get(id).classList.contains("has-conflict"));
      button.title = `${fieldById.get(id).name}：${statusById.get(id).textContent || "尚未输入"}`;
    });
    const manualCount = [...advancedFieldIds].filter((id) => {
      const input = inputById.get(id);
      return !input.disabled && input.value.trim() && input.dataset.generated !== "true";
    }).length;
    const errorCount = [...advancedFieldIds].filter((id) => inputById.get(id).classList.contains("has-conflict")).length;
    advancedToggle.classList.toggle("has-conflict", errorCount > 0);
    advancedSummary.textContent = [
      advancedDescription,
      manualCount ? `已填写 ${manualCount} 项高级参数。` : "",
      errorCount ? `${errorCount} 项需要检查，请展开查看。` : "",
    ].filter(Boolean).join(" ");
  }

  function updateTopologyRows() {
    const isSpm = topologySelect.value === "spm";
    const spmOnlyIds = new Set(["lLine", "lPhase", "tauPhase"]);
    const spmOutputIds = new Set(["ld", "lq", "saliency", "tauD", "tauQ"]);

    inputById.forEach((input, id) => {
      const row = input.closest("tr");
      row.hidden = !isSpm && spmOnlyIds.has(id);
      input.disabled = isSpm ? spmOutputIds.has(id) : spmOnlyIds.has(id);
    });
  }

  function parseNumber(text) {
    const normalized = text.trim().replace(",", ".");
    if (!normalized) return NaN;
    return Number(normalized);
  }

  function formatNumber(value) {
    return window.YMBOXNumberFormat.format(value);
  }

  function valuesDiffer(a, b) {
    const scale = Math.max(1, Math.abs(a), Math.abs(b));
    return Math.abs(a - b) / scale > 0.002;
  }

  function clearGeneratedValues() {
    inputById.forEach((input) => {
      if (input.dataset.generated === "true") {
        window.YMBOXNumberFormat.writeInput(input, "");
      }
      input.dataset.generated = "false";
      input.classList.remove("is-generated", "has-conflict");
    });
    statusById.forEach((status) => {
      status.textContent = "";
      status.className = "";
    });
  }

  function createState(rawValues = null) {
    const values = new Map();
    const sources = new Map();
    const manual = new Set();
    const invalidInputs = [];

    const entries = rawValues
      ? Object.entries(rawValues)
      : [...inputById.entries()].filter(([, input]) => !input.disabled).map(([id, input]) => [id, window.YMBOXNumberFormat.readInput(input)]);

    entries.forEach(([id, rawValue]) => {
      if (!fieldById.has(id)) return;
      const text = String(rawValue ?? "");
      if (!text.trim()) return;
      const value = parseNumber(text);
      let reason = "";

      if (!Number.isFinite(value)) reason = "请输入有效数字";
      else if (positiveOnlyIds.has(id) && value <= 0) reason = "该参数必须大于 0";
      else if (id === "viscousFriction" && value < 0) reason = "黏性摩擦系数不能小于 0";
      else if (integerIds.has(id) && !Number.isInteger(value)) reason = "极对数必须为整数";

      if (reason) {
        invalidInputs.push({ id, reason });
        return;
      }

      values.set(id, value);
      sources.set(id, "手动输入");
      manual.add(id);
    });

    return {
      values,
      sources,
      manual,
      conflicts: [],
      conflictKeys: new Set(),
      alternatives: new Map(),
      invalidInputs,
      changes: 0,
    };
  }

  function addConflict(state, id, existing, candidate, source) {
    const key = `${id}:${source}`;
    if (state.conflictKeys.has(key)) return;
    state.conflictKeys.add(key);
    state.conflicts.push({ id, existing, candidate, source });
  }

  function derive(state, id, value, source) {
    if (!Number.isFinite(value)) return false;
    const existing = state.values.get(id);

    if (Number.isFinite(existing)) {
      if (valuesDiffer(existing, value)) {
        addConflict(state, id, existing, value, source);
      }
      return false;
    }

    state.values.set(id, value);
    state.sources.set(id, source);
    state.changes += 1;
    return true;
  }

  function valueOf(state, id) {
    return state.values.get(id);
  }

  function hasValue(state, id) {
    return Number.isFinite(valueOf(state, id));
  }

  function deriveBidirectional(state, a, b, forward, reverse, sourceForward, sourceReverse) {
    if (hasValue(state, a)) derive(state, b, forward(valueOf(state, a)), sourceForward);
    if (hasValue(state, b)) derive(state, a, reverse(valueOf(state, b)), sourceReverse);
  }

  function propagate(state, connection = connectionSelect.value, topology = topologySelect.value) {

    for (let pass = 0; pass < 14; pass += 1) {
      const changesBefore = state.changes;

      deriveBidirectional(state, "speedRpm", "omegaM", (rpm) => (rpm * TAU) / 60, (omega) => (omega * 60) / TAU, "ωm = 2πn/60", "n = 60ωm/2π");

      if (hasValue(state, "ratedTorque") && hasValue(state, "omegaM")) {
        derive(state, "powerKw", (valueOf(state, "ratedTorque") * valueOf(state, "omegaM")) / 1000, "Prated(kW) = Trated·ωm/1000");
      }
      if (hasValue(state, "powerKw") && hasValue(state, "omegaM") && valueOf(state, "omegaM") !== 0) {
        derive(state, "ratedTorque", (1000 * valueOf(state, "powerKw")) / valueOf(state, "omegaM"), "Trated = 1000Prated/ωm");
      }
      if (hasValue(state, "powerKw") && hasValue(state, "ratedTorque") && valueOf(state, "ratedTorque") !== 0) {
        derive(state, "omegaM", (1000 * valueOf(state, "powerKw")) / valueOf(state, "ratedTorque"), "ωm = 1000Prated/Trated");
      }

      deriveBidirectional(state, "vBus", "vLine", (v) => v / SQRT2, (v) => SQRT2 * v, "SVPWM：Vline,rms = Vdc/√2", "Vdc = √2Vline,rms");

      if (connection === "star") {
        deriveBidirectional(state, "rPhase", "rLine", (v) => 2 * v, (v) => v / 2, "Y：Rll = 2Rph", "Y：Rph = Rll/2");
        if (topology === "spm") deriveBidirectional(state, "lPhase", "lLine", (v) => 2 * v, (v) => v / 2, "SPM/Y：Lline = 2Lphase", "SPM/Y：Lphase = Lline/2");
        deriveBidirectional(state, "vPhase", "vLine", (v) => SQRT3 * v, (v) => v / SQRT3, "Y：Vll = √3Vph", "Y：Vph = Vll/√3");
        deriveBidirectional(state, "iPhase", "ratedCurrent", (v) => v, (v) => v, "Y：Irated = Iphase", "Y：Iphase = Irated");
      } else if (connection === "delta") {
        deriveBidirectional(state, "rPhase", "rLine", (v) => (2 * v) / 3, (v) => (3 * v) / 2, "Δ：Rll = 2Rph/3", "Δ：Rph = 3Rll/2");
        if (topology === "spm") deriveBidirectional(state, "lPhase", "lLine", (v) => (2 * v) / 3, (v) => (3 * v) / 2, "SPM/Δ：Lline = 2Lphase/3", "SPM/Δ：Lphase = 3Lline/2");
        deriveBidirectional(state, "vPhase", "vLine", (v) => v, (v) => v, "Δ：Vll = Vph", "Δ：Vph = Vll");
        deriveBidirectional(state, "iPhase", "ratedCurrent", (v) => SQRT3 * v, (v) => v / SQRT3, "Δ：Irated = √3Iphase", "Δ：Iphase = Irated/√3");
      }

      deriveBidirectional(state, "kePhasePeak", "kePhaseRms", (v) => v / SQRT2, (v) => v * SQRT2, "Ke,ph,rms = Ke,ph,pk/√2", "Ke,ph,pk = √2Ke,ph,rms");
      deriveBidirectional(state, "kePhaseRms", "keLineRms", (v) => SQRT3 * v, (v) => v / SQRT3, "Ke,ll,rms = √3Ke,ph,rms", "Ke,ph,rms = Ke,ll,rms/√3");
      deriveBidirectional(state, "keLineRms", "keLineKrpm", (v) => v * OMEGA_AT_1000_RPM, (v) => v / OMEGA_AT_1000_RPM, "Ke(V/krpm) = Ke·104.72", "Ke(V/(rad/s)) = Ke(V/krpm)/104.72");

      if (hasValue(state, "keLineKrpm") && valueOf(state, "keLineKrpm") !== 0) {
        derive(state, "kv", 1000 / valueOf(state, "keLineKrpm"), "Kv = 1000/Ke(V/krpm)");
      }
      if (hasValue(state, "kv") && valueOf(state, "kv") !== 0) {
        derive(state, "keLineKrpm", 1000 / valueOf(state, "kv"), "Ke(V/krpm) = 1000/Kv");
      }

      if (hasValue(state, "polePairs") && hasValue(state, "psiFlux")) {
        const pPsi = valueOf(state, "polePairs") * valueOf(state, "psiFlux");
        derive(state, "kePhasePeak", pPsi, "Ke,ph,pk = pψf");
        derive(state, "ktIqPeak", 1.5 * pPsi, "Kt,iq,pk = 1.5pψf");
        derive(state, "ktPhaseRms", 1.5 * SQRT2 * pPsi, "Kt,ph,rms = 1.5√2pψf");
      }
      if (hasValue(state, "polePairs") && valueOf(state, "polePairs") !== 0) {
        const p = valueOf(state, "polePairs");
        if (hasValue(state, "kePhasePeak")) derive(state, "psiFlux", valueOf(state, "kePhasePeak") / p, "ψf = Ke,ph,pk/p");
        if (hasValue(state, "ktIqPeak")) derive(state, "psiFlux", valueOf(state, "ktIqPeak") / (1.5 * p), "ψf = Kt,iq,pk/(1.5p)");
        if (hasValue(state, "ktPhaseRms")) derive(state, "psiFlux", valueOf(state, "ktPhaseRms") / (1.5 * SQRT2 * p), "ψf = Kt,ph,rms/(1.5√2p)");
      }

      deriveBidirectional(state, "ktIqPeak", "ktPhaseRms", (v) => SQRT2 * v, (v) => v / SQRT2, "Kt,ph,rms = √2Kt,iq,pk", "Kt,iq,pk = Kt,ph,rms/√2");
      deriveBidirectional(state, "keLineRms", "ktPhaseRms", (v) => SQRT3 * v, (v) => v / SQRT3, "Kt,ph,rms = √3Ke,ll,rms", "Ke,ll,rms = Kt,ph,rms/√3");

      if (connection === "star") {
        deriveBidirectional(state, "ktPhaseRms", "ktLineRms", (v) => v, (v) => v, "Y：Kt,ll,rms = Kt,ph,rms", "Y：Kt,ph,rms = Kt,ll,rms");
      } else if (connection === "delta") {
        deriveBidirectional(state, "ktPhaseRms", "ktLineRms", (v) => v / SQRT3, (v) => v * SQRT3, "Δ：Kt,ll,rms = Kt,ph,rms/√3", "Δ：Kt,ph,rms = √3Kt,ll,rms");
      }

      if (hasValue(state, "ktLineRms") && hasValue(state, "ratedCurrent")) {
        derive(state, "ratedTorque", valueOf(state, "ktLineRms") * valueOf(state, "ratedCurrent"), "Trated = Kt,ll,rms·Irated");
      }
      if (hasValue(state, "ratedTorque") && hasValue(state, "ktLineRms") && valueOf(state, "ktLineRms") !== 0) {
        derive(state, "ratedCurrent", valueOf(state, "ratedTorque") / valueOf(state, "ktLineRms"), "Irated = Trated/Kt,ll,rms");
      }

      if (topology === "spm") {
        derive(state, "saliency", 1, "SPM：Ld = Lq，凸极比 = 1");
        if (hasValue(state, "lPhase")) {
          derive(state, "ld", valueOf(state, "lPhase"), "SPM：Ld = Lphase");
          derive(state, "lq", valueOf(state, "lPhase"), "SPM：Lq = Lphase");
        }
      } else {
        if (hasValue(state, "ld") && hasValue(state, "lq") && valueOf(state, "ld") !== 0) {
          derive(state, "saliency", valueOf(state, "lq") / valueOf(state, "ld"), "IPM：凸极比 = Lq/Ld");
        }
        if (hasValue(state, "ld") && hasValue(state, "saliency")) derive(state, "lq", valueOf(state, "ld") * valueOf(state, "saliency"), "IPM：Lq = Ld·凸极比");
        if (hasValue(state, "lq") && hasValue(state, "saliency") && valueOf(state, "saliency") !== 0) derive(state, "ld", valueOf(state, "lq") / valueOf(state, "saliency"), "IPM：Ld = Lq/凸极比");
      }

      if (hasValue(state, "rPhase") && valueOf(state, "rPhase") !== 0) {
        const resistance = valueOf(state, "rPhase");
        if (topology === "spm" && hasValue(state, "lPhase")) derive(state, "tauPhase", valueOf(state, "lPhase") / resistance, "SPM：τphase = Lphase/Rphase");
        if (hasValue(state, "ld")) derive(state, "tauD", valueOf(state, "ld") / resistance, "τd(ms) = Ld(mH)/Rphase");
        if (hasValue(state, "lq")) derive(state, "tauQ", valueOf(state, "lq") / resistance, "τq(ms) = Lq(mH)/Rphase");
      }
      if (hasValue(state, "rPhase")) {
        const resistance = valueOf(state, "rPhase");
        if (topology === "spm" && hasValue(state, "tauPhase")) derive(state, "lPhase", valueOf(state, "tauPhase") * resistance, "SPM：Lphase = τphase·Rphase");
        if (topology === "ipm" && hasValue(state, "tauD")) derive(state, "ld", valueOf(state, "tauD") * resistance, "IPM：Ld = τd·Rphase");
        if (topology === "ipm" && hasValue(state, "tauQ")) derive(state, "lq", valueOf(state, "tauQ") * resistance, "IPM：Lq = τq·Rphase");
      }
      if (topology === "spm" && hasValue(state, "lPhase") && hasValue(state, "tauPhase") && valueOf(state, "tauPhase") !== 0) derive(state, "rPhase", valueOf(state, "lPhase") / valueOf(state, "tauPhase"), "Rphase = Lphase/τphase");
      if (topology === "ipm" && hasValue(state, "ld") && hasValue(state, "tauD") && valueOf(state, "tauD") !== 0) derive(state, "rPhase", valueOf(state, "ld") / valueOf(state, "tauD"), "Rphase = Ld/τd");
      if (topology === "ipm" && hasValue(state, "lq") && hasValue(state, "tauQ") && valueOf(state, "tauQ") !== 0) derive(state, "rPhase", valueOf(state, "lq") / valueOf(state, "tauQ"), "Rphase = Lq/τq");

      if (hasValue(state, "rPhase") && hasValue(state, "iPhase")) {
        derive(state, "copperLoss", 3 * valueOf(state, "rPhase") * valueOf(state, "iPhase") ** 2, "Pcu = 3Iph²Rph");
      }
      if (hasValue(state, "copperLoss") && hasValue(state, "rPhase") && valueOf(state, "rPhase") > 0) {
        derive(state, "iPhase", Math.sqrt(valueOf(state, "copperLoss") / (3 * valueOf(state, "rPhase"))), "Iph = √(Pcu/3Rph)");
      }

      if (hasValue(state, "omegaM")) {
        const omega = valueOf(state, "omegaM");
        if (hasValue(state, "kePhasePeak")) derive(state, "emfPhasePeak", valueOf(state, "kePhasePeak") * omega, "Eph,pk = Ke,ph,pk·ωm");
        if (hasValue(state, "kePhaseRms")) derive(state, "emfPhaseRms", valueOf(state, "kePhaseRms") * omega, "Eph,rms = Ke,ph,rms·ωm");
        if (hasValue(state, "keLineRms")) derive(state, "emfLineRms", valueOf(state, "keLineRms") * omega, "Ell,rms = Ke,ll,rms·ωm");
      }
      if (hasValue(state, "omegaM") && valueOf(state, "omegaM") !== 0) {
        if (hasValue(state, "emfPhasePeak")) derive(state, "kePhasePeak", valueOf(state, "emfPhasePeak") / valueOf(state, "omegaM"), "Ke,ph,pk = Eph,pk/ωm");
        if (hasValue(state, "emfPhaseRms")) derive(state, "kePhaseRms", valueOf(state, "emfPhaseRms") / valueOf(state, "omegaM"), "Ke,ph,rms = Eph,rms/ωm");
        if (hasValue(state, "emfLineRms")) derive(state, "keLineRms", valueOf(state, "emfLineRms") / valueOf(state, "omegaM"), "Ke,ll,rms = Ell,rms/ωm");
      }

      if (hasValue(state, "emfLineRms") && hasValue(state, "vLine") && valueOf(state, "vLine") !== 0) {
        derive(state, "voltageUtilization", (100 * valueOf(state, "emfLineRms")) / valueOf(state, "vLine"), "电压利用率 = Ell,rms/Vline,rms × 100%");
      }

      if (state.changes === changesBefore) break;
    }
  }

  function addAlternative(state, id, label, value, source) {
    if (!Number.isFinite(value) || hasValue(state, id)) return;
    const list = state.alternatives.get(id) || [];
    list.push({ label, value, source });
    state.alternatives.set(id, list);
  }

  function buildUnknownConnectionAlternatives(state, topology = topologySelect.value) {
    if (connectionSelect.value !== "unknown") return;

    if (hasValue(state, "rPhase")) {
      addAlternative(state, "rLine", "Y", 2 * valueOf(state, "rPhase"), "Rll = 2Rph");
      addAlternative(state, "rLine", "Δ", (2 * valueOf(state, "rPhase")) / 3, "Rll = 2Rph/3");
    }
    if (hasValue(state, "rLine")) {
      addAlternative(state, "rPhase", "Y", valueOf(state, "rLine") / 2, "Rph = Rll/2");
      addAlternative(state, "rPhase", "Δ", (3 * valueOf(state, "rLine")) / 2, "Rph = 3Rll/2");
    }
    if (topology === "spm" && hasValue(state, "lPhase")) {
      addAlternative(state, "lLine", "Y", 2 * valueOf(state, "lPhase"), "Lll = 2Lph");
      addAlternative(state, "lLine", "Δ", (2 * valueOf(state, "lPhase")) / 3, "Lll = 2Lph/3");
    }
    if (topology === "spm" && hasValue(state, "lLine")) {
      addAlternative(state, "lPhase", "Y", valueOf(state, "lLine") / 2, "Lph = Lll/2");
      addAlternative(state, "lPhase", "Δ", (3 * valueOf(state, "lLine")) / 2, "Lph = 3Lll/2");
    }
    if (hasValue(state, "vPhase")) {
      addAlternative(state, "vLine", "Y", SQRT3 * valueOf(state, "vPhase"), "Vll = √3Vph");
      addAlternative(state, "vLine", "Δ", valueOf(state, "vPhase"), "Vll = Vph");
    }
    if (hasValue(state, "vLine")) {
      addAlternative(state, "vPhase", "Y", valueOf(state, "vLine") / SQRT3, "Vph = Vll/√3");
      addAlternative(state, "vPhase", "Δ", valueOf(state, "vLine"), "Vph = Vll");
    }
    if (hasValue(state, "iPhase")) {
      addAlternative(state, "ratedCurrent", "Y", valueOf(state, "iPhase"), "Irated = Iphase");
      addAlternative(state, "ratedCurrent", "Δ", SQRT3 * valueOf(state, "iPhase"), "Irated = √3Iphase");
    }
    if (hasValue(state, "ratedCurrent")) {
      addAlternative(state, "iPhase", "Y", valueOf(state, "ratedCurrent"), "Iphase = Irated");
      addAlternative(state, "iPhase", "Δ", valueOf(state, "ratedCurrent") / SQRT3, "Iphase = Irated/√3");
    }
    if (hasValue(state, "ktPhaseRms")) {
      addAlternative(state, "ktLineRms", "Y", valueOf(state, "ktPhaseRms"), "Kt,ll = Kt,ph");
      addAlternative(state, "ktLineRms", "Δ", valueOf(state, "ktPhaseRms") / SQRT3, "Kt,ll = Kt,ph/√3");
    }
    if (hasValue(state, "ktLineRms")) {
      addAlternative(state, "ktPhaseRms", "Y", valueOf(state, "ktLineRms"), "Kt,ph = Kt,ll");
      addAlternative(state, "ktPhaseRms", "Δ", valueOf(state, "ktLineRms") * SQRT3, "Kt,ph = √3Kt,ll");
    }
    if (hasValue(state, "ktPhaseRms") && hasValue(state, "ratedCurrent")) {
      addAlternative(state, "ratedTorque", "Y", valueOf(state, "ktPhaseRms") * valueOf(state, "ratedCurrent"), "Trated = Kt,ph·Irated");
      addAlternative(state, "ratedTorque", "Δ", (valueOf(state, "ktPhaseRms") / SQRT3) * valueOf(state, "ratedCurrent"), "Trated = Kt,ph·Irated/√3");
    }
  }

  function renderState(state) {
    let calculatedCount = 0;
    let unresolvedCount = 0;
    const invalidIds = new Set(state.invalidInputs.map(({ id }) => id));

    fields.forEach((field) => {
      const input = inputById.get(field.id);
      const status = statusById.get(field.id);
      const value = valueOf(state, field.id);

      if (input.closest("tr").hidden) {
        status.textContent = "";
        return;
      }
      // Keep invalid user text available for correction, even if another field can derive a value.
      if (invalidIds.has(field.id)) return;

      if (Number.isFinite(value)) {
        if (state.manual.has(field.id)) {
          status.textContent = "手动输入";
          status.className = "is-manual";
        } else {
          window.YMBOXNumberFormat.writeInput(input, value);
          input.dataset.generated = "true";
          input.classList.add("is-generated");
          status.textContent = `计算：${state.sources.get(field.id)}`;
          status.className = "is-calculated";
          calculatedCount += 1;
        }
      } else if (state.alternatives.has(field.id)) {
        const alternatives = state.alternatives.get(field.id);
        status.textContent = alternatives.map((item) => `${item.label}：${formatNumber(item.value)} ${field.unit}`).join(" ｜ ");
        status.className = "has-alternatives";
      } else {
        status.textContent = `至少需要：${field.requirement}`;
        status.className = "is-missing";
        unresolvedCount += 1;
      }
    });

    state.conflicts.forEach((conflict) => {
      const input = inputById.get(conflict.id);
      const status = statusById.get(conflict.id);
      input.classList.add("has-conflict");
      status.className = "has-conflict";
      status.textContent = `冲突：现值 ${formatNumber(conflict.existing)}；${conflict.source} 得 ${formatNumber(conflict.candidate)}`;
    });

    state.invalidInputs.forEach((invalid) => {
      const input = inputById.get(invalid.id);
      const status = statusById.get(invalid.id);
      input.classList.add("has-conflict");
      status.className = "has-conflict";
      status.textContent = `无效输入：${invalid.reason}`;
    });

    updateParameterIndicators();
    renderSummary(state, calculatedCount, unresolvedCount);
  }

  function renderSummary(state, calculatedCount, unresolvedCount) {
    messagePanel.replaceChildren();
    messagePanel.hidden = false;

    const heading = document.createElement("strong");
    const detail = document.createElement("span");
    const manualCount = state.manual.size;

    if (state.conflicts.length > 0 || state.invalidInputs.length > 0) {
      messagePanel.className = "motor-message-panel is-error";
      heading.textContent = `发现 ${state.conflicts.length} 组冲突、${state.invalidInputs.length} 项无效输入`;
      detail.textContent = `已推导 ${calculatedCount} 项。红色输入框或切换按钮标出具体问题；高级区中的问题可展开查看。`;
    } else if (manualCount === 0) {
      messagePanel.className = "motor-message-panel is-warning";
      heading.textContent = "尚未输入有效参数";
      detail.textContent = "最小组合示例：极对数 + 磁链/Ke/Kt；SPM 接法 + 线/相电感；IPM 的 Ld/Lq/凸极比任意两项；转速 + 额定功率/转矩；母线电压 + 额定线电流。";
    } else {
      messagePanel.className = "motor-message-panel is-success";
      heading.textContent = `已从 ${manualCount} 项输入推导 ${calculatedCount} 项参数`;
      detail.textContent = unresolvedCount > 0
        ? `仍有 ${unresolvedCount} 项缺少条件；每一行均列出了最小输入要求。`
        : "全部可确定参数已完成计算。";
    }

    messagePanel.append(heading, detail);
  }

  function collectProfileData() {
    const values = {};
    inputById.forEach((input, id) => {
      if (!input.disabled && input.value.trim() && input.dataset.generated !== "true") {
        values[id] = window.YMBOXNumberFormat.readInput(input).trim();
      }
    });
    return {
      schemaVersion: 1,
      topology: topologySelect.value,
      connection: connectionSelect.value,
      values,
    };
  }

  function profileTopology(profileData) {
    if (["spm", "ipm"].includes(profileData?.topology)) return profileData.topology;
    const values = profileData?.values || {};
    return values.ld || values.lq || values.saliency ? "ipm" : "spm";
  }

  function resolveProfileData(profileData) {
    const connection = ["unknown", "star", "delta"].includes(profileData?.connection)
      ? profileData.connection
      : "unknown";
    const topology = profileTopology(profileData);
    const state = createState(profileData?.values || {});
    propagate(state, connection, topology);
    return {
      values: Object.fromEntries(state.values),
      conflicts: state.conflicts.slice(),
      invalidInputs: state.invalidInputs.slice(),
      connection,
      topology,
    };
  }

  function applyProfileData(profileData) {
    clearAll();
    topologySelect.value = profileTopology(profileData);
    connectionSelect.value = ["unknown", "star", "delta"].includes(profileData?.connection)
      ? profileData.connection
      : "unknown";
    Object.entries(profileData?.values || {}).forEach(([id, value]) => {
      const input = inputById.get(id);
      if (!input) return;
      window.YMBOXNumberFormat.writeInput(input, value);
      input.dataset.generated = "false";
    });
    parameterGroups.forEach((group) => {
      const manualVariant = group.find(([id]) => inputById.get(id).value.trim());
      if (manualVariant) selectParameterVariant(manualVariant[0]);
    });
    setAdvancedExpanded([...advancedFieldIds].some((id) => inputById.get(id).value.trim()));
    updateTopologyRows();
    calculateAll();
  }

  const profileElements = {
    name: document.getElementById("motorProfileName"),
    select: document.getElementById("motorProfileSelect"),
    save: document.getElementById("motorProfileSave"),
    status: document.getElementById("motorProfileStatus"),
    path: document.getElementById("motorStoragePath"),
  };

  function setProfileStatus(text, type = "") {
    profileElements.status.textContent = text;
    profileElements.status.className = type;
  }

  async function refreshMotorProfiles(preferredName = "") {
    const result = await window.YMBOXProfiles.list("motor");
    if (!result.ok) {
      setProfileStatus(`读取失败：${result.error}`, "is-error");
      return;
    }

    const selectedName = preferredName || profileElements.select.value;
    profileElements.select.replaceChildren(new Option("选择方案", ""));
    result.profiles.forEach((profile) => {
      profileElements.select.append(new Option(profile.name, profile.name));
    });
    if (result.profiles.some((profile) => profile.name === selectedName)) {
      profileElements.select.value = selectedName;
    }
    profileElements.path.textContent = `保存目录：${result.directory}`;
  }

  async function saveMotorProfile() {
    const name = profileElements.name.value.trim();
    const data = collectProfileData();
    if (!name) {
      setProfileStatus("请先填写电机方案名称", "is-error");
      profileElements.name.focus();
      return;
    }
    if (Object.keys(data.values).length === 0) {
      setProfileStatus("至少填写一个电机参数后再保存", "is-error");
      return;
    }

    const result = await window.YMBOXProfiles.save("motor", name, data);
    if (!result.ok) {
      setProfileStatus(`保存失败：${result.error}`, "is-error");
      return;
    }

    profileElements.name.value = result.name;
    setProfileStatus(`已保存：${result.name}`, "is-success");
    await refreshMotorProfiles(result.name);
  }

  async function loadMotorProfile(name) {
    if (!name) return;
    const result = await window.YMBOXProfiles.load("motor", name);
    if (!result.ok) {
      setProfileStatus(`加载失败：${result.error}`, "is-error");
      return;
    }

    applyProfileData(result.data);
    profileElements.name.value = result.name;
    setProfileStatus(`当前方案：${result.name}`, "is-success");
  }

  function calculateAll() {
    clearGeneratedValues();
    const state = createState();
    propagate(state);
    buildUnknownConnectionAlternatives(state);
    renderState(state);
  }

  function clearAll() {
    inputById.forEach((input) => {
      window.YMBOXNumberFormat.writeInput(input, "");
      input.dataset.generated = "false";
      input.classList.remove("is-generated", "has-conflict");
    });
    statusById.forEach((status) => {
      status.textContent = "";
      status.className = "";
    });
    topologySelect.value = "spm";
    connectionSelect.value = "unknown";
    parameterGroups.forEach((group) => selectParameterVariant(group[0][0]));
    setAdvancedExpanded(false);
    updateTopologyRows();
    updateParameterIndicators();
    messagePanel.hidden = true;
    messagePanel.replaceChildren();
  }

  createParameterTable();
  updateTopologyRows();
  advancedToggle.addEventListener("click", () => setAdvancedExpanded(advancedPanel.hidden));
  calculateButton.addEventListener("click", calculateAll);
  clearButton.addEventListener("click", clearAll);
  connectionSelect.addEventListener("change", () => {
    if ([...inputById.values()].some((input) => input.value.trim())) calculateAll();
  });
  topologySelect.addEventListener("change", () => {
    ["lLine", "lPhase", "ld", "lq", "saliency", "tauPhase", "tauD", "tauQ"].forEach((id) => {
      const input = inputById.get(id);
      window.YMBOXNumberFormat.writeInput(input, "");
      input.dataset.generated = "false";
      input.classList.remove("is-generated", "has-conflict");
      statusById.get(id).textContent = "";
    });
    updateTopologyRows();
    updateParameterIndicators();
    if ([...inputById.values()].some((input) => input.value.trim())) calculateAll();
  });
  profileElements.save.addEventListener("click", saveMotorProfile);
  profileElements.name.addEventListener("keydown", (event) => {
    if (event.key === "Enter") saveMotorProfile();
  });
  profileElements.select.addEventListener("change", () => loadMotorProfile(profileElements.select.value));
  window.addEventListener("ymbox:profile-saved", (event) => {
    if (event.detail?.kind === "motor") refreshMotorProfiles(event.detail.name);
  });
  // Form-button tooltips are assembled from the rendered status text; rebuild them after a language switch.
  window.addEventListener("ymbox:language-changed", updateParameterIndicators);

  window.YMBOXMotorCalculator = Object.freeze({
    collectProfileData,
    applyProfileData,
    resolveProfileData,
    refreshProfiles: refreshMotorProfiles,
  });

  refreshMotorProfiles();
})();
