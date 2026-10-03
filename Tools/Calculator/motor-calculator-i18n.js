(function registerMotorCalculatorTranslations(global) {
  "use strict";

  // English text for the motor parameter calculator. The page keeps its Chinese
  // source strings; YMBOXI18n replaces them when the locale is English.
  // This file must load before ymbox-config-i18n.js: its rules have to run ahead
  // of the generic fallback rules registered there. Names that also appear on the
  // YMBOX page (极对数, d 轴相电感, ...) use the same wording as that page, which
  // owns them.
  const i18n = global.YMBOXI18n;

  // [name, English name, minimum inputs, English minimum inputs]
  const parameters = [
    ["极对数", "Pole Pairs", "极数，或磁链 + 任一 Ke/Kt", "pole count, or flux linkage + any Ke/Kt"],
    ["机械转速", "Mechanical Speed", "机械角速度", "mechanical angular speed"],
    ["机械角速度", "Mechanical Angular Speed", "机械转速", "mechanical speed"],
    ["最大机械转速", "Maximum Mechanical Speed", "厂家机械转速上限，与当前计算转速分开填写", "the manufacturer's mechanical speed limit, entered separately from the current calculation speed"],
    ["转动惯量", "Rotor Inertia", "手动输入或电机辨识结果", "manual input or a motor identification result"],
    ["黏性摩擦系数", "Viscous Friction Coefficient", "厂家或辨识数据；N·m/krpm 除以 (1000 × 2π/60)", "manufacturer or identification data; divide N·m/krpm by (1000 × 2π/60)"],
    ["最大转矩", "Maximum Torque", "手动输入最大转矩", "manual entry of the maximum torque"],
    ["额定转矩", "Rated Torque", "额定线电流 + 线电流 RMS Kt，或功率 + 转速", "rated line current + line-current RMS Kt, or power + speed"],
    ["额定机械功率", "Rated Mechanical Power", "额定转矩 + 转速", "rated torque + speed"],
    ["线电阻", "Line Resistance", "相电阻 + 绕组接法", "phase resistance + winding connection"],
    ["相电阻", "Phase Resistance", "线电阻 + 绕组接法", "line resistance + winding connection"],
    ["线电感（SPM）", "Line Inductance (SPM)", "SPM：相电感 + 绕组接法", "SPM: phase inductance + winding connection"],
    ["相电感（SPM）", "Phase Inductance (SPM)", "SPM：线电感 + 绕组接法", "SPM: line inductance + winding connection"],
    ["d 轴相电感", "Ld", "SPM：相/线电感；IPM：Lq + 凸极比", "SPM: phase/line inductance; IPM: Lq + saliency ratio"],
    ["q 轴相电感", "Lq", "SPM：相/线电感；IPM：Ld + 凸极比", "SPM: phase/line inductance; IPM: Ld + saliency ratio"],
    ["凸极比", "Saliency Ratio", "IPM：Ld + Lq；SPM 默认为 1", "IPM: Ld + Lq; defaults to 1 for SPM"],
    ["相电气时间常数（SPM）", "Phase Electrical Time Constant (SPM)", "SPM：相电感 + 相电阻", "SPM: phase inductance + phase resistance"],
    ["d 轴时间常数", "d-Axis Time Constant", "Ld + 相电阻", "Ld + phase resistance"],
    ["q 轴时间常数", "q-Axis Time Constant", "Lq + 相电阻", "Lq + phase resistance"],
    ["母线电压", "DC-Bus Voltage", "手动输入直流母线电压", "manual entry of the DC-bus voltage"],
    ["SVPWM 最大线电压 RMS", "Maximum SVPWM Line Voltage (RMS)", "母线电压", "DC-bus voltage"],
    ["最大绕组相电压 RMS", "Maximum Winding Phase Voltage (RMS)", "母线电压 + 绕组接法", "DC-bus voltage + winding connection"],
    ["额定线电流 RMS", "Rated Line Current (RMS)", "手动输入额定电流", "manual entry of the rated current"],
    ["额定相电流 RMS", "Rated Phase Current (RMS)", "额定线电流 + 绕组接法", "rated line current + winding connection"],
    ["最大相电流峰值", "Maximum Peak Phase Current", "已知电流上限时直接导入；优先于最大转矩反推电流", "a known current limit, entered directly; it takes precedence over the current back-calculated from the maximum torque"],
    ["额定三相铜耗", "Rated Three-Phase Copper Loss", "相电阻 + 额定相电流", "phase resistance + rated phase current"],
    ["反电势电压利用率", "Back-EMF Voltage Utilization", "线反电势 + 母线电压", "line back-EMF + DC-bus voltage"],
    ["永磁体每相峰值磁链", "Permanent-Magnet Flux Linkage (Per-Phase Peak)", "极对数 + 任一 Ke/Kt", "pole pairs + any Ke/Kt"],
    ["相反电势峰值常数", "Phase Back-EMF Constant (Peak)", "ψf + 极对数", "ψf + pole pairs"],
    ["相反电势 RMS 常数", "Phase Back-EMF Constant (RMS)", "任一 Ke", "any Ke"],
    ["线反电势 RMS 常数", "Line Back-EMF Constant (RMS)", "任一 Ke/Kt", "any Ke/Kt"],
    ["线反电势 RMS 常数", "Line Back-EMF Constant (RMS)", "任一 Ke，或 Kv", "any Ke, or Kv"],
    ["转速常数", "Speed Constant", "线反电势 V/krpm", "line back-EMF in V/krpm"],
    ["dq 峰值电流转矩系数", "Torque Constant (dq Peak Current)", "ψf + 极对数", "ψf + pole pairs"],
    ["相电流 RMS 转矩系数", "Torque Constant (Phase-Current RMS)", "任一 Kt/Ke", "any Kt/Ke"],
    ["线电流 RMS 转矩系数", "Torque Constant (Line-Current RMS)", "相 RMS Kt + 绕组接法", "phase-RMS Kt + winding connection"],
    ["相反电势峰值", "Phase Back-EMF (Peak)", "相峰值 Ke + 机械转速", "phase-peak Ke + mechanical speed"],
    ["相反电势 RMS", "Phase Back-EMF (RMS)", "相 RMS Ke + 机械转速", "phase-RMS Ke + mechanical speed"],
    ["线反电势 RMS", "Line Back-EMF (RMS)", "线 RMS Ke + 机械转速", "line-RMS Ke + mechanical speed"]
  ];

  const units = ["-", "rpm", "rad/s", "kg·m²", "N·m·s", "N·m", "kW", "Ω", "mH", "ms", "V", "A", "W", "%", "Wb",
    "V/(rad/s)", "V/krpm", "rpm/V", "N·m/Apeak", "N·m/Arms", "N·m/Aline"];

  const english = {
    // Page chrome
    "电机全参数超级计算器": "Motor Parameter Calculator",
    "电机方案名称": "Motor Profile Name",
    "例如：80 系列样机 A": "e.g. 80-series prototype A",
    "已保存电机方案": "Saved Motor Profiles",
    "绕组接法": "Winding connection",
    "表贴式 SPM": "Surface-mounted SPM",
    "内嵌式 IPM": "Interior IPM",
    "未知，同时给出 Y / Δ": "Unknown: show both Y and Δ",
    "Y 星形": "Y (star)",
    "Δ 三角形": "Δ (delta)",
    "清空全部": "Clear All",
    "计算剩余参数": "Calculate Remaining Parameters",
    "计算约定": "Calculation conventions",
    "正弦 PMSM": "Sinusoidal PMSM",
    "ψf 为每相峰值磁链": "ψf is the per-phase peak flux linkage",
    "dq 电流采用峰值": "dq currents are peak values",
    "线阻抗为端子间等效值": "Line impedances are terminal-to-terminal values",
    "SVPWM 线性区最大基波": "Maximum fundamental in the SVPWM linear region",
    "额定电流为线电流 RMS": "Rated current is the line-current RMS",
    "常用参数": "Common Parameters",
    "手动值优先，计算值以绿色标记": "Manual values take priority; calculated values are marked in green",
    "同行按钮切换参数形式；修改后以当前形式的输入为准。接法未知时，线／相换算同时列出 Y、Δ 两种结果。": "Buttons in a row switch the form of the parameter; after an edit, the input in the current form takes precedence. When the connection is unknown, line/phase conversions list both the Y and the Δ result.",
    "参数": "Parameter",
    "符号": "Symbol",
    "数值": "Value",
    "单位": "Unit",
    "状态 / 推导来源": "Status / Derivation",
    "高级参数": "Advanced Parameters",
    "展开": "Expand",
    "收起": "Collapse",

    // Parameter groups
    "电机基本参数与转速": "Basic Motor Data and Speed",
    "机械功率与转矩": "Mechanical Power and Torque",
    "电阻与电感": "Resistance and Inductance",
    "凸极比与时间常数": "Saliency Ratio and Time Constants",
    "相 / 线电压电流": "Phase / Line Voltages and Currents",
    "铜耗与电压利用率": "Copper Loss and Voltage Utilization",
    "磁链、反电势常数与转矩系数": "Flux Linkage, Back-EMF Constants and Torque Constants",
    "反电势常数与转速常数": "Back-EMF Constants and Speed Constant",
    "指定转速下的反电势": "Back-EMF at the Specified Speed",

    // Form switches of one quantity
    "线电感": "Line Inductance",
    "相电感": "Phase Inductance",
    "线电压": "Line Voltage",
    "相电压": "Phase Voltage",
    "线电流": "Line Current",
    "相电流": "Phase Current",
    "线 RMS": "Line RMS",
    "相 RMS": "Phase RMS",
    "相峰值": "Phase Peak",

    // Row status
    "手动输入": "Manual input",
    "已修改，等待计算": "Modified; waiting for calculation",
    "尚未输入": "Not entered yet",

    // Result summary
    "尚未输入有效参数": "No valid parameters entered yet",
    "最小组合示例：极对数 + 磁链/Ke/Kt；SPM 接法 + 线/相电感；IPM 的 Ld/Lq/凸极比任意两项；转速 + 额定功率/转矩；母线电压 + 额定线电流。": "Minimal combinations, for example: pole pairs + flux linkage/Ke/Kt; SPM connection + line/phase inductance; any two of Ld/Lq/saliency ratio for an IPM; speed + rated power/torque; DC-bus voltage + rated line current.",
    "全部可确定参数已完成计算。": "All determinable parameters have been calculated.",

    // Profile storage
    "请先填写电机方案名称": "Enter a motor profile name first",
    "至少填写一个电机参数后再保存": "Enter at least one motor parameter before saving",
    "方案服务请求失败": "The profile service request failed"
  };

  const requirements = new Map();
  const invalidReasons = new Map([
    ["请输入有效数字", "enter a valid number"],
    ["该参数必须大于 0", "this parameter must be greater than 0"],
    ["黏性摩擦系数不能小于 0", "the viscous friction coefficient cannot be negative"],
    ["极对数必须为整数", "the number of pole pairs must be an integer"]
  ]);
  for (const [name, englishName, requirement, englishRequirement] of parameters) {
    english[name] = englishName;
    requirements.set(requirement, englishRequirement);
  }

  const escapeRegExp = value => value.replace(/[.*+?^${}()|[\]\\\/]/g, "\\$&");
  const alternation = values => [...new Set(values)].sort((a, b) => b.length - a.length).map(escapeRegExp).join("|");
  const names = alternation(parameters.map(([name]) => name));
  const plural = (count, singular, pluralForm = `${singular}s`) => `${count} ${Number(count) === 1 ? singular : pluralForm}`;

  // Derivation notes are formulas with a few Chinese words and full-width punctuation.
  const formula = source => source
    .replace(/电压利用率/g, "Voltage utilization")
    .replace(/凸极比/g, "saliency ratio")
    .replace(/：/g, ": ")
    .replace(/，/g, ", ");

  const advancedDescription = "凸极比、时间常数、铜耗、电压利用率及更多反电势换算。折叠后仍参与计算和方案保存。";

  i18n.registerTextMap("en", english);
  i18n.registerTextRules("en", [
    // Row status
    {pattern: /^计算：([\s\S]+)$/, replace: (value, source) => `Calculated: ${formula(source)}`},
    {pattern: /^至少需要：([\s\S]+)$/, replace: (value, requirement) => `Needs at least: ${requirements.get(requirement) ?? i18n.text(requirement)}`},
    {pattern: /^冲突：现值 (.+?)；([\s\S]+) 得 (.+)$/, replace: (value, existing, source, candidate) => `Conflict: current value ${existing}; ${formula(source)} gives ${candidate}`},
    {pattern: /^无效输入：([\s\S]+)$/, replace: (value, reason) => `Invalid input: ${invalidReasons.get(reason) ?? i18n.text(reason)}`},
    {pattern: /^Y：(.+?) ｜ Δ：(.+)$/, replace: "Y: $1 | Δ: $2"},

    // Tooltips and accessibility labels built from parameter names
    {pattern: new RegExp(`^(${names})：([\\s\\S]*)$`), replace: (value, name, status) => `${i18n.text(name)}: ${i18n.text(status)}`},
    {pattern: new RegExp(`^((?:${names})(?: \\/ (?:${names}))*)切换$`), replace: (value, group) => `Switch form: ${group.split(" / ").map(name => i18n.text(name)).join(" / ")}`},
    {pattern: new RegExp(`^(${names}) (${alternation(units)})$`), replace: (value, name, unit) => `${i18n.text(name)} ${unit}`},

    // Result summary
    {pattern: /^发现 (\d+) 组冲突、(\d+) 项无效输入$/, replace: (value, conflicts, invalid) => `Found ${plural(conflicts, "conflict")} and ${plural(invalid, "invalid input")}`},
    {pattern: /^已推导 (\d+) 项。红色输入框或切换按钮标出具体问题；高级区中的问题可展开查看。$/, replace: (value, count) => `Derived ${plural(count, "parameter")}. Red input boxes and form buttons mark the specific problems; expand the advanced section to see problems there.`},
    {pattern: /^已从 (\d+) 项输入推导 (\d+) 项参数$/, replace: (value, inputs, derived) => `Derived ${plural(derived, "parameter")} from ${plural(inputs, "input")}`},
    {pattern: /^仍有 (\d+) 项缺少条件；每一行均列出了最小输入要求。$/, replace: (value, count) => `${plural(count, "parameter still lacks", "parameters still lack")} inputs; each row lists its minimum required inputs.`},
    {pattern: new RegExp(`^${escapeRegExp(advancedDescription)}(?: 已填写 (\\d+) 项高级参数。)?(?: (\\d+) 项需要检查，请展开查看。)?$`), replace: (value, filled, errors) => [
      "Saliency ratio, time constants, copper loss, voltage utilization and further back-EMF conversions. They still take part in calculation and profile saving when collapsed.",
      filled ? `${plural(filled, "advanced parameter")} entered.` : "",
      errors ? `${plural(errors, "item needs", "items need")} checking; expand to view.` : ""
    ].filter(Boolean).join(" ")},

    // Profile storage
    {pattern: /^读取失败：([\s\S]*)$/, replace: (value, message) => `Read failed: ${i18n.text(message)}`},
    {pattern: /^加载失败：([\s\S]*)$/, replace: (value, message) => `Load failed: ${i18n.text(message)}`},
    {pattern: /^方案服务不可用：([\s\S]*)$/, replace: "The profile service is unavailable: $1"}
  ]);
})(window);
