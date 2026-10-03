(function (global, factory) {
  if (typeof module === "object" && module.exports) module.exports = factory(require("./ymbox-config-schema.json"), require("./ymbox-config-auto.js"), require("./position-pll-calculator.js"));
  else global.YMBOXConfig = factory(global.YMBOXSchema, global.YMBOXAuto, global.YMBOXPositionPll);
})(typeof window === "object" ? window : globalThis, function (schema, automatic, positionPll) {
  "use strict";
  const recalculationRevision = "YMBOXConfigEngine/recalculate-v1";
  const fields = schema.fields;
  const byPath = new Map(fields.map(field => [field.path, field]));
  const retiredPaths = new Set(schema.retiredFields);
  const clone = value => JSON.parse(JSON.stringify(value));
  const emptyValue = value => value === undefined || value === "" || (typeof value === "string" && !value.trim());
  const raw = value => value === null ? "auto" : typeof value === "object" ? JSON.stringify(value) : String(value);
  const pwmPath = "Inverter.PwmFrequencyOverride_Hz";
  const controlFrequencyPath = "Timing.ControlFrequency_Hz";
  const controlSamplesPerElectricalCycle = 10;
  const controlFrequencyQuantum_Hz = 1000;
  const isTimingConstraint = field => field.readOnly && field.path.startsWith("Timing.");
  const isDefaultedDivider = field => field.path === "Timing.MDTMTaskDivider_NULL";
  const isVersion = field => ["Meta.ProfileVersion", "Meta.SchemaVersion"].includes(field.path);
  const versionDefault = field => Number.isInteger(field.defaultValue) ? field.defaultValue.toFixed(1) : raw(field.defaultValue);
  const empty = () => Object.fromEntries(fields.map(field => [field.path, isVersion(field) ? versionDefault(field) : isTimingConstraint(field) || isDefaultedDivider(field) ? raw(field.defaultValue) : ""]));
  const motorPaths = new Set(["Meta.ProfileName", "Meta.MotorClass", "Motor.PolePairs", "Motor.StatorResistance_Ohm", "Motor.PmFlux_Wb", "Motor.Inertia_kgm2", "Motor.ViscousFriction_Nms", "Motor.MaxMechSpeed_rpm", "Inverter.NominalDcBus_V", "Motor.Ld_H", "Motor.Lq_H", "Motor.RatedCurrent_A", "Motor.MaxCurrent_A", "Execution.TargetSpeed_rpm", "Execution.TargetTorque_Nm"]);
  const motorReasons = new Set(["导入电机参数", "导入电机方案名称", "导入转子结构", "相电感 mH → H", "绕组相电流 RMS × √2 → 相电流峰值", "最大转矩 / dq 峰值电流转矩系数"]);
  const isMotorSource = reason => reason === "电机参数导入" || reason.startsWith("电机参数导入：");
  function describeMotorSource(reason) {
    if (isMotorSource(reason)) return reason;
    if (reason === "导入电机参数") return "电机参数导入";
    // Older converted values did not record a filename; retain their formula
    // without inferring a file from an editable profile name or equal values.
    return `电机参数导入：${reason.replace(/^电机方案：/, "方案：").replace(/^导入/, "")}`;
  }
  // MATLAB JSON decoding converts dots in object keys to underscores.
  const metadataAt = (metadata, path) => metadata?.[path] ?? metadata?.[path.replaceAll(".", "_")];

  // Provenance of the exported default snapshot, not a new tuning algorithm.
  // ApplicationParameters/YMBOX_Drive_Parameters.m contains both expressions
  // and previously tuned finite settings; Runtime/YMBOX_Configuration_ResolveAuto.m
  // materializes its NaN defaults before the UI schema is exported.
  const initializedSources = {
    "Motor.MaxMechSpeed_rpm": `模型初始化计算：6300 ÷ ${schema.defaults.Motor.PolePairs} × 60 ÷ (2π)`,
    "Timing.ControlFrequency_Hz": "待更新：按最大机械转速、极对数和每电角周期10个控制样本推荐最低控制频率",
    "Timing.InputTaskFrequencyOverride_Hz": "模型初始化计算：跟随当时的控制频率",
    "Inverter.PwmFrequencyOverride_Hz": "模型初始化计算：跟随当时的控制频率",
    "Inverter.NonlinearityCompensationMax_V": "模型初始化计算：额定母线电压 / 20",
    "Protection.DcBusOverVoltage_V": "模型初始化计算：min(最高母线电压, 1.2 × 额定母线电压)",
    "Protection.DcBusUnderVoltage_V": "模型初始化计算：0.5 × 额定母线电压",
    "Protection.VoltageViolationArea_Vs": "模型初始化计算：0.0005 × 过压阈值",
    "FieldWeakening.EntrySpeedOverride_rpm": "模型初始化计算：0.98 × 额定电压下的基速",
    "Limits.CurrentCommandMax_A": "模型初始化关联：当时的电机最大相电流峰值",
    "Limits.SpeedCommandAbsMax_rpm": "模型初始化关联：当时的最大机械转速",
    "Features.ActiveInverterCompensationEnable": "模型初始化关联：逆变器非线性补偿开关",
    "Features.SensoredFieldWeakeningEnable": "模型初始化关联：有感弱磁开关"
  };
  function defaultSource(field, value) {
    if (field.readOnly) return "当前模型固定约束";
    const matchesDefault = typeof field.defaultValue === "number"
      ? Number(value) === field.defaultValue : raw(value) === raw(field.defaultValue);
    // Old automatic values with missing provenance must not be presented as
    // a calculation merely because this parameter has a calculation method.
    if (!matchesDefault) return "已有自动值（来源未记录）";
    if (initializedSources[field.path]) return initializedSources[field.path];
    if (field.autoResolvedDefault) return "模型初始化计算值";
    if (/^ControlTargets\.(CurrentLoop|SpeedLoop)/.test(field.path)) return "已有 PI 整定值";
    if (field.path === "PositionSensor.PllBandwidth_rads") return "已有有感 PLL 整定值";
    if (/^FieldWeakening\.VoltageLoopK[pi]_/.test(field.path)) return "已有弱磁 PI 整定值";
    if (/^Observer\.(SlideGain.*Override_V|ErrBoundary.*Override_A|EmfLpfPole_rads|PllBandwidth_rads|PllDamping|ReadySpeedErrorOverride_rads|TotalDelay_s)$/.test(field.path)) return "已有 SMO 整定值";
    if (field.path === "StartupSupervisor.DirectAccelIqSeedOverride_A") return "已有启动电流整定值";
    return "模型预设值";
  }

  function recommendControlFrequency({maxMechSpeed_rpm, polePairs, baseTick_s, minimum_Hz, maximum_Hz, exactMatchTolerance_ppm = 0.1}) {
    const inputs = {maxMechSpeed_rpm, polePairs, baseTick_s, minimum_Hz, maximum_Hz, exactMatchTolerance_ppm};
    if (!Object.values(inputs).every(value => Number.isFinite(Number(value)) && Number(value) > 0))
      throw new Error("推荐控制频率需要有效且大于0的最大机械转速、极对数和时序约束");
    const tick_s = Number(baseTick_s), minimum = Number(minimum_Hz), maximum = Number(maximum_Hz);
    const electricalFrequency_Hz = Math.abs(Number(maxMechSpeed_rpm)) * Number(polePairs) / 60;
    const speedMinimum_Hz = controlSamplesPerElectricalCycle * electricalFrequency_Hz;
    const unconstrainedMinimum_Hz = Math.max(minimum, speedMinimum_Hz);
    const integerKilohertzTarget_Hz = Math.round(unconstrainedMinimum_Hz / controlFrequencyQuantum_Hz) * controlFrequencyQuantum_Hz;
    const supported = [];
    const firstMultiple = Math.ceil(minimum / controlFrequencyQuantum_Hz - 1e-12);
    const lastMultiple = Math.floor(maximum / controlFrequencyQuantum_Hz + 1e-12);
    for (let multiple = firstMultiple; multiple <= lastMultiple; multiple += 1) {
      const frequency_Hz = multiple * controlFrequencyQuantum_Hz;
      const ticks = Math.round(1 / (frequency_Hz * tick_s));
      const actualFrequency_Hz = ticks > 0 ? 1 / (ticks * tick_s) : Infinity;
      const error_ppm = 1e6 * Math.abs(actualFrequency_Hz - frequency_Hz) / frequency_Hz;
      if (ticks > 0 && error_ppm <= Number(exactMatchTolerance_ppm)) supported.push({frequency_Hz, ticks});
    }
    if (!supported.length) throw new Error("当前控制频率范围内没有可由基础 tick 精确实现的整 kHz 档位");
    const limitedByMaximum = unconstrainedMinimum_Hz > maximum * (1 + 1e-12);
    const target_Hz = Math.max(minimum, Math.min(maximum, integerKilohertzTarget_Hz));
    const selected = supported.find(candidate => candidate.frequency_Hz >= target_Hz - 1e-9) || supported.at(-1);
    return Object.freeze({
      frequency_Hz: selected.frequency_Hz, ticks: selected.ticks,
      electricalFrequency_Hz, speedMinimum_Hz, unconstrainedMinimum_Hz,
      integerKilohertzTarget_Hz, limitedByMaximum, baseTick_s: tick_s,
      supportedFrequencies_Hz: Object.freeze(supported.map(candidate => candidate.frequency_Hz)),
      samplesPerElectricalCycle: selected.frequency_Hz / electricalFrequency_Hz
    });
  }

  function controlFrequencySource(recommendation) {
    const exact = `最大电角频率 ${recommendation.electricalFrequency_Hz.toPrecision(7)} Hz × ${controlSamplesPerElectricalCycle}（每电角周期${controlSamplesPerElectricalCycle}个控制样本），理论目标 ${recommendation.unconstrainedMinimum_Hz.toPrecision(7)} Hz；先四舍五入到整 kHz ${recommendation.integerKilohertzTarget_Hz.toPrecision(7)} Hz，再选择可由 ${Number(recommendation.baseTick_s * 1e6).toPrecision(7)} μs 基础 tick 精确实现的整 kHz 档位`;
    return recommendation.limitedByMaximum
      ? `推荐：${exact}；理论需求超过模型上限，暂限为 ${recommendation.frequency_Hz.toPrecision(7)} Hz，需降低最高转速或扩展时序上限后验证`
      : `推荐：${exact}；结果 ${recommendation.frequency_Hz.toPrecision(7)} Hz`;
  }

  function restoreVersionDefaults(values, sources = {}, origins = {}) {
    const restored = {...values};
    for (const field of fields.filter(isVersion)) {
      const path = field.path, origin = metadataAt(origins, path), reason = metadataAt(sources, path);
      const legacyDefault = Number(values[path]) === 4 && origin !== "manual" &&
        (origin === "automatic" || ["当前模型基准值", "模型预设值", "当前模型固定约束", "模型固定约束"].includes(reason));
      if (emptyValue(values[path]) || legacyDefault) restored[path] = versionDefault(field);
    }
    return restored;
  }

  function restoreAutoValues(values) {
    const paths = fields.filter(field => field.canResolveAuto && automatic.isLegacy(values[field.path])).map(field => field.path);
    return {...values, ...(paths.length ? automatic.resolve(values, paths) : {})};
  }

  function normalizeState(values, sources = {}, origins = {}) {
    const normalizedSources = {}, normalizedOrigins = {};
    for (const field of fields) {
      const path = field.path;
      if (emptyValue(values[path])) continue;
      const source = metadataAt(sources, path);
      const reason = typeof source === "string" ? source : "";
      let origin = metadataAt(origins, path);
      const legacyAuto = field.canResolveAuto && automatic.isLegacy(values[path]);
      if (legacyAuto) origin = "automatic";
      else if (isVersion(field)) origin = "manual";
      else if (field.readOnly) origin = "automatic";
      else if (!["manual", "automatic", "motor"].includes(origin) || (origin === "motor" && !motorPaths.has(path))) {
        if (!reason || reason.startsWith("手动设置") || reason.startsWith("配置文件：") || reason === "已应用配置") origin = "manual";
        else if (motorPaths.has(path) && (isMotorSource(reason) || reason.startsWith("电机方案：") || motorReasons.has(reason))) origin = "motor";
        else origin = "automatic";
      }
      normalizedOrigins[path] = origin;
      const defaultReason = !reason || ["当前模型基准值", "模型预设值"].includes(reason);
      normalizedSources[path] = legacyAuto ? automatic.source : isVersion(field) ? "手动设置" : defaultReason
        ? origin === "manual" ? "手动设置" : origin === "motor" ? "导入电机参数" : defaultSource(field, values[path])
        : reason;
      if (origin === "motor") normalizedSources[path] = describeMotorSource(normalizedSources[path]);
    }
    return {sources: normalizedSources, origins: normalizedOrigins};
  }

  function flatten(drive) {
    const result = empty();
    function visit(value, prefix) {
      if (!value || typeof value !== "object" || Array.isArray(value)) throw new Error(`${prefix || "配置"}应为参数分组`);
      for (const [name, item] of Object.entries(value)) {
        const path = prefix ? `${prefix}.${name}` : name;
        if (["__proto__", "constructor", "prototype"].includes(name)) throw new Error("非法参数名");
        // Older configurations may contain this removed, unused parameter.
        if (retiredPaths.has(path)) continue;
        if (byPath.has(path)) {
          const field = byPath.get(path);
          if (isTimingConstraint(field) && parse(field, raw(item)) !== field.defaultValue) throw new Error(`${path} 是固定约束，必须为 ${field.defaultValue}`);
          result[path] = isVersion(field) && Number.isInteger(item) ? item.toFixed(1) : raw(item);
        }
        else if (fields.some(field => field.path.startsWith(`${path}.`))) visit(item, path);
        else throw new Error(`当前模型不包含参数：${path}`);
      }
    }
    // An old document with only the former PLL name keeps its actual value.
    const position = drive?.PositionSensor;
    if (position && !Object.hasOwn(position, "PllBandwidth_rads") && Object.hasOwn(position, "ResolverPllBandwidth_rads")) {
      drive = {...drive, PositionSensor: {...position, PllBandwidth_rads: position.ResolverPllBandwidth_rads}};
    }
    visit(drive, "");
    return result;
  }

  function parse(field, value) {
    if (emptyValue(value)) throw new Error("尚未填写");
    const text = String(value).trim();
    if (field.type === "char") return text;
    if (field.type === "logical") {
      if (!["true", "false", "1", "0"].includes(text)) throw new Error("请选择启用或禁用");
      return text === "true" || text === "1";
    }
    if (field.shape.reduce((a, b) => a * b, 1) > 1) {
      let values;
      try { values = JSON.parse(text); } catch { throw new Error("请输入 JSON 数组，例如 [4,5,17]"); }
      if (!Array.isArray(values) || values.length !== field.shape.reduce((a, b) => a * b, 1) || !values.every(Number.isFinite)) throw new Error("数组长度或数值不正确");
      return values;
    }
    const number = Number(text);
    if (!Number.isFinite(number)) throw new Error("请输入有限数值");
    if (field.type === "single" && (!Number.isFinite(Math.fround(number)) || (number !== 0 && Math.fround(number) === 0)))
      throw new Error("数值无法由模型的 single 类型表示");
    if (/^u?int/.test(field.type)) {
      const bits = Number(field.type.replace(/\D/g, ""));
      const unsigned = field.type.startsWith("u");
      if (!Number.isInteger(number) || number < (unsigned ? 0 : -(2 ** (bits - 1))) || number > (unsigned ? 2 ** bits - 1 : 2 ** (bits - 1) - 1)) throw new Error(`必须在 ${field.type} 整数范围内`);
    }
    return number;
  }

  function assemble(values) {
    const drive = {}, issues = [];
    for (const field of fields) {
      try {
        const value = parse(field, values[field.path]);
        if (field.readOnly && JSON.stringify(value) !== JSON.stringify(field.defaultValue)) throw new Error("这是当前模型的固定约束");
        const parts = field.path.split(".");
        let group = drive;
        for (const name of parts.slice(0, -1)) group = group[name] ||= {};
        group[parts.at(-1)] = value;
      } catch (error) { issues.push({path: field.path, message: error.message}); }
    }
    return {drive, issues};
  }

  function speedLoopTargets(v, targets, hz) {
    const currentHz = Number(targets.currentBandwidthHz ?? 300);
    const phaseMargin = Number(targets.phaseMarginDeg ?? 55);
    const speedError = Math.max(20, 0.05 * Math.abs(v("Execution.TargetSpeed_rpm")));
    const loadBandwidthHz = Math.abs(v("Motor.LoadTorque_Nm")) * Math.sqrt(1 + Math.tan((90 - phaseMargin) * Math.PI / 180) ** 2) /
      (2 * Math.PI * v("Motor.Inertia_kgm2") * (2 * Math.PI / 60) * speedError);
    const speedHz = Number(targets.speedBandwidthHz ?? Math.max(5, Math.min(currentHz / 10, loadBandwidthHz)));
    if (!(currentHz > 0 && currentHz < hz / 2 && speedHz > 0 && phaseMargin > 0 && phaseMargin < 90))
      throw new Error("推荐带宽须为正、低于采样 Nyquist 频率，相位裕度须在 0–90° 内");
    return {currentHz, speedHz, phaseMargin};
  }

  // Local current/EMF error dynamics of the actual filtered-injection SMO:
  // iNext = a*iPrevious - b*ePrevious; eNext = c*ePrevious + h*iNext.
  // This frozen-gain check does not prove PLL/handover or IPMSM stability.
  function smoDiscreteModel(values) {
    const v = path => Number(values[path]);
    const resistance = v("Motor.StatorResistance_Ohm") * v("Observer.EffectiveResistanceScale");
    const inductance = values["Meta.MotorClass"] === "IPMSM" ? v("Motor.Ld_H") : v("Observer.EffectiveInductance_H");
    const hz = v("Timing.ControlFrequency_Hz"), pole = v("Observer.EmfLpfPole_rads");
    if (![resistance, inductance, hz, pole].every(x => Number.isFinite(x) && x > 0)) return {valid: false};
    const a = Math.exp(-resistance / inductance / hz), b = (1 - a) / resistance, c = Math.exp(-pole / hz);
    // det(A)=a*c fixes the pole radius. Choose a continuous-equivalent damping
    // ratio of 1/sqrt(2); cap the discrete pole angle at pi/2 for fast plants.
    const sigma = (resistance / inductance + pole) / (2 * hz), angle = Math.min(sigma, Math.PI / 2);
    const traceTarget = 2 * Math.exp(-sigma) * Math.cos(angle);
    const slopeTarget = (a + c - traceTarget) / ((1 - c) * b);
    return {valid: Number.isFinite(slopeTarget) && slopeTarget > 0, a, b, c, slopeTarget};
  }

  function smoDiscreteCheck(values) {
    const v = path => Number(values[path]);
    const adaptive = String(values["Observer.AdaptiveInjectionEnable"]) === "true";
    const model = smoDiscreteModel(values);
    const gain = adaptive ? Math.max(v("Observer.SlideGainMinOverride_V"), v("Observer.SlideGainMaxOverride_V")) : v("Observer.SlideGainOverride_V");
    const boundary = adaptive ? Math.min(v("Observer.ErrBoundaryMinOverride_A"), v("Observer.ErrBoundaryMaxOverride_A")) : v("Observer.ErrBoundaryOverride_A");
    if (!model.valid || ![gain, boundary].every(x => Number.isFinite(x) && x > 0)) return {valid: false, stable: false};
    const {a, b, c, slopeTarget} = model;
    const loopGain = (1 - c) * b * gain / boundary, upper = (1 + a) * (1 + c);
    return {valid: true, stable: loopGain < upper, loopGain, upper, minimumBoundary_A: (1 - c) * b * gain / upper, targetSlope_VperA: slopeTarget};
  }

  // Local small-signal phase of the sampled current/EMF observer. The motor
  // voltage is held over the previous interval; a rotating EMF is integrated
  // exactly over that interval. This does not identify external transport delay.
  function smoPhaseFit(values) {
    const v = path => Number(values[path]), model = smoDiscreteModel(values);
    if (!model.valid || !smoDiscreteCheck(values).stable) return {valid: false};
    const hz = v("Timing.ControlFrequency_Hz"), pole = v("Observer.EmfLpfPole_rads");
    const resistance = v("Motor.StatorResistance_Ohm") * v("Observer.EffectiveResistanceScale");
    const inductance = values["Meta.MotorClass"] === "IPMSM" ? v("Motor.Ld_H") : v("Observer.EffectiveInductance_H");
    const rate = resistance / inductance;
    const adaptive = String(values["Observer.AdaptiveInjectionEnable"]) === "true";
    const fixedSlope = v("Observer.SlideGainOverride_V") / v("Observer.ErrBoundaryOverride_A");
    const emfLow = v("Observer.GainScheduleEmfLowOverride_V"), emfHigh = v("Observer.GainScheduleEmfHighOverride_V");
    const flux = v("Motor.PmFlux_Wb");
    if (adaptive && !(emfHigh > emfLow && flux > 0)) return {valid: false};
    const designOmega = Math.abs(v("Observer.DesignMechSpeed_rpm")) * 2 * Math.PI / 60 * v("Motor.PolePairs");
    const fitOmega = Math.min(designOmega, 0.8 * Math.PI * hz);
    if (!(Number.isFinite(fitOmega) && fitOmega > 0)) return {valid: false};
    const {a, b, c} = model, determinant = a * c;
    const samples = [];
    let numerator = 0, denominator = 0;
    for (let index = 1; index <= 32; index++) {
      const omega = fitOmega * index / 32, angle = omega / hz;
      const integralReal = 1 - a * Math.cos(angle), integralImag = a * Math.sin(angle);
      const emfIntegralPhase = Math.atan2(integralImag, integralReal) - Math.atan2(omega, rate);
      const response = rho => {
        const slope = adaptive
          ? (v("Observer.SlideGainMinOverride_V") + rho * (v("Observer.SlideGainMaxOverride_V") - v("Observer.SlideGainMinOverride_V"))) /
            (v("Observer.ErrBoundaryMaxOverride_A") - rho * (v("Observer.ErrBoundaryMaxOverride_A") - v("Observer.ErrBoundaryMinOverride_A")))
          : fixedSlope;
        const trace = a + c - (1 - c) * b * slope;
        const real = 1 - trace * Math.cos(angle) + determinant * Math.cos(2 * angle);
        const imag = trace * Math.sin(angle) - determinant * Math.sin(2 * angle);
        return {phase: Math.atan2(imag, real) - emfIntegralPhase,
          amplitude: (1 - c) * slope / inductance * Math.hypot(integralReal, integralImag) /
            Math.hypot(rate, omega) / Math.hypot(real, imag)};
      };
      let rho = 0;
      if (adaptive) {
        // At constant speed the scheduler sees the attenuated estimated EMF,
        // not the ideal PM EMF. Solve this steady scheduling feedback first.
        let lower = 0, upper = 1;
        for (let iteration = 0; iteration < 48; iteration++) {
          rho = (lower + upper) / 2;
          const estimatedEmf = response(rho).amplitude * omega * flux;
          const scheduled = Math.max(0, Math.min(1, (estimatedEmf - emfLow) / (emfHigh - emfLow)));
          if (scheduled > rho) lower = rho; else upper = rho;
        }
        rho = (lower + upper) / 2;
      }
      const residual = response(rho).phase - Math.atan(omega / pole);
      numerator += omega * residual; denominator += omega * omega;
      samples.push({omega, residual, rho});
    }
    const leastSquaresDelay_s = numerator / denominator;
    let delay_s = Math.max(0, leastSquaresDelay_s);
    if (adaptive) {
      // One constant delay cannot cancel the whole gain schedule. Minimize
      // the worst phase residual instead of fitting only its high-gain end.
      const delayInterval = error => [Math.max(0, ...samples.map(p => (p.residual - error) / p.omega)),
        Math.min(...samples.map(p => (p.residual + error) / p.omega))];
      let lowerError = 0, upperError = Math.max(...samples.map(p => Math.abs(p.residual)));
      for (let iteration = 0; iteration < 60; iteration++) {
        const error = (lowerError + upperError) / 2, [lower, upper] = delayInterval(error);
        if (lower <= upper) upperError = error; else lowerError = error;
      }
      const [lower, upper] = delayInterval(upperError);
      delay_s = (lower + upper) / 2;
    }
    const residuals = samples.map(point => point.residual - point.omega * delay_s);
    return {valid: Number.isFinite(delay_s), delay_s, unconstrainedDelay_s: leastSquaresDelay_s,
      method: adaptive ? "steady-schedule-minimax" : "fixed-gain-least-squares", fitOmega_rads: fitOmega,
      scheduleRhoMin: Math.min(...samples.map(p => p.rho)), scheduleRhoMax: Math.max(...samples.map(p => p.rho)),
      residualMax_deg: Math.max(...residuals.map(Math.abs)) * 180 / Math.PI,
      residualRmse_deg: Math.sqrt(residuals.reduce((sum, value) => sum + value * value, 0) / residuals.length) * 180 / Math.PI};
  }

  function observerDesignSpeed(v) {
    const base = v("Inverter.NominalDcBus_V") * v("Limits.VoltageMargin_NULL") * v("Inverter.LinearModulationUtilization_NULL") /
      (Math.sqrt(3) * v("Motor.PolePairs") * v("Motor.PmFlux_Wb")) * 60 / (2 * Math.PI);
    return Math.min(base, v("Motor.MaxMechSpeed_rpm"), v("Limits.SpeedCommandAbsMax_rpm"));
  }

  function inverterVoltageError(v) {
    const drop = (v("Inverter.HighSideVoltageDrop_V") + v("Inverter.LowSideVoltageDrop_V")) / 2;
    return 4 / 3 * (v("Inverter.NominalDcBus_V") * v("Inverter.DeadTime_s") * v("Inverter.PwmFrequencyOverride_Hz") + drop) + 0.01 * v("Inverter.NominalDcBus_V");
  }

  function tuningWriter(result, seed, sources) {
    return (path, value, reason, kind = "理论初值") => {
      if (emptyValue(seed[path]) || automatic.isLegacy(seed[path])) {
        if (!Number.isFinite(value)) throw new Error(`${path} 无法整定，请检查依赖参数`);
        result[path] = raw(value); sources[path] = `${kind}：${reason}`;
      }
      return Number(result[path]);
    };
  }

  // Establish startup acceleration before tuning the SMO PLL. Use only this
  // update's explicit inputs, never the previous automatic recommendations.
  function applyStartupMotor(result, seed, sources, switchFloor = 0) {
    const v = path => Number(result[path]), put = tuningWriter(result, seed, sources);
    const selected = (path, calculated) => emptyValue(seed[path]) || automatic.isLegacy(seed[path]) ? calculated : v(path);
    const p = v("Motor.PolePairs"), flux = v("Motor.PmFlux_Wb"), inertia = v("Motor.Inertia_kgm2");
    const kt = 1.5 * p * flux, rated = v("Motor.RatedCurrent_A");
    const cap = Math.min(rated, v("Motor.MaxCurrent_A"), v("Limits.CurrentCommandMax_A"));
    if (![p, flux, inertia, kt, cap].every(x => Number.isFinite(x) && x > 0))
      throw new Error("启动整定需要正的极对数、磁链、惯量和电流能力");
    const design = selected("Observer.DesignMechSpeed_rpm", observerDesignSpeed(v));
    const budget = selected("Inverter.VoltageErrorBudget_V", inverterVoltageError(v));
    const noiseL = Math.max(v("Motor.Ld_H"), v("Motor.Lq_H")) * v("Timing.ControlFrequency_Hz");
    const noiseVoltage = 3 * v("CurrentSensor.NoiseStd_A") * Math.hypot(v("Motor.StatorResistance_Ohm") + noiseL, noiseL);
    const emf = put("Observer.MinEmf_V", Math.max(1e-3, 5 * budget, noiseVoltage),
      "max(5 × 电压误差预算, 3σI × √((Rs + Lfc)² + (Lfc)²), 0.001 V)，L=max(Ld,Lq)；按相邻采样噪声独立估计，5倍信噪比与3σ为工程目标，须验证低速可观测性");
    const margin = put("Observer.EmfObservabilityMargin", 1.1, "最小反电势再留10%接管裕量，可手动调整", "工程初值");
    const minimum = put("Observer.MinSwitchSpeed_rpm", 0.2 * design,
      "0.2 × 无感设计机械转速；20%为保守工程起点，并与最小可观测反电势联合取较大值");
    const speed = put("Observer.SwitchSpeedOverride_rpm", Math.max(switchFloor, minimum, margin * emf / (p * flux) * 60 / (2 * Math.PI)),
      "同时满足最低切换转速、接管反电势裕量及退出转速处的最小反电势；纳入离散SMO衰减，自适应按最小增益/最大边界保守计算，使接管与退出门限一致");
    const errorFraction = put("Observer.ReadySpeedErrorFraction", 1 / 6, "允许接管电角速度的1/6误差，作为就绪窗口起点", "工程初值");
    put("Observer.ReadySpeedErrorOverride_rads", Math.max(1, errorFraction * speed * p * 2 * Math.PI / 60),
      "max(1 rad/s, 就绪误差比例 × 接管机械转速 × 极对数 × 2π/60)；这里是电角速度误差");
    put("Observer.ReadyPllError", 0.5, "归一化PLL误差阈值取sin30° = 0.5；只适用于正常锁定附近，并非独立角度锁定证明", "工程初值");
    put("StartupSupervisor.IfSwitchSpeed_rpm", speed,
      "跟随SMO接管转速；当前无感模式6实际使用SMO接管转速，本项保留为通用路由兼容值", "关联值");
    const load = Math.abs(v("Motor.LoadTorque_Nm")) + v("Motor.ViscousFriction_Nms") * speed * 2 * Math.PI / 60;
    const currentBudget = selected("StartupSupervisor.IfStartIqOverride_A", cap);
    const available = (kt * Math.min(cap, currentBudget) / 2 - load) / inertia * 60 / (2 * Math.PI);
    if (!(available > 0) && emptyValue(seed["StartupSupervisor.IfAccel_rpms"]))
      throw new Error("启动电流不足以在当前负载下保留2倍转矩裕量；请核对负载、启动电流及电流限值");
    const accel = put("StartupSupervisor.IfAccel_rpms", Math.min(Math.abs(v("ControlTargets.SpeedCommandSlew_rpms")), available),
      "min(转速指令斜率, (Kt × 启动电流预算 / 2 − |负载转矩| − B × 接管机械角速度) / J × 60/(2π))；自动电流预算不超过额定电流与指令限值，2倍为I/F转矩裕量");
    const required = (inertia * accel * 2 * Math.PI / 60 + load) / kt;
    put("StartupSupervisor.IfStartIqOverride_A", Math.min(cap, Math.max(0.05 * rated, 2 * required)),
      "min(额定/最大/指令电流上限, max(0.05 × 额定相电流, 2 × (Jα + Bω接管 + |负载转矩|) / Kt))；5%电流下限和2倍转矩裕量为工程目标");
    put("StartupSupervisor.IfAlignIdOverride_A", Math.min(cap, Math.max(0.15 * rated, 2 * Math.abs(v("Motor.LoadTorque_Nm")) / kt)),
      "min(额定/最大/指令电流上限, max(0.15 × 额定相电流, 2 × |负载转矩| / Kt))；仅为预定位初值，15%与2倍为工程目标");
    put("StartupSupervisor.DirectAccelIqSeedOverride_A", Math.min(required, cap),
      "(Jα + Bω接管 + |负载转矩|) / Kt，并受额定/最大/指令电流限值约束；被限制时须降低启动负载或加速度");
    put("StartupSupervisor.ObserverExitRatio", 0.75, "退出转速取接管转速的75%，形成速度滞回", "工程初值");
  }

  function startupEstimatedEmf(values, speedRpm) {
    const v = path => Number(values[path]), model = smoDiscreteModel(values);
    if (!model.valid) return NaN;
    const adaptive = String(values["Observer.AdaptiveInjectionEnable"]) === "true";
    const slope = adaptive ? v("Observer.SlideGainMinOverride_V") / v("Observer.ErrBoundaryMaxOverride_A")
      : v("Observer.SlideGainOverride_V") / v("Observer.ErrBoundaryOverride_A");
    const inductance = values["Meta.MotorClass"] === "IPMSM" ? v("Motor.Ld_H") : v("Observer.EffectiveInductance_H");
    const rate = v("Motor.StatorResistance_Ohm") * v("Observer.EffectiveResistanceScale") / inductance;
    const omega = speedRpm * 2 * Math.PI / 60 * v("Motor.PolePairs"), angle = omega / v("Timing.ControlFrequency_Hz");
    const {a,b,c} = model, trace = a + c - (1-c)*b*slope, determinant = a*c;
    const real = 1-trace*Math.cos(angle)+determinant*Math.cos(2*angle);
    const imag = trace*Math.sin(angle)-determinant*Math.sin(2*angle);
    const magnitude = (1-c)*slope/inductance * Math.hypot(1-a*Math.cos(angle),a*Math.sin(angle)) /
      Math.hypot(rate,omega) / Math.hypot(real,imag);
    return magnitude * omega * v("Motor.PmFlux_Wb");
  }

  function startupObservableEmf(values, speedRpm) {
    return Math.min(startupEstimatedEmf(values,speedRpm) / Number(values["Observer.EmfObservabilityMargin"]),
      startupEstimatedEmf(values,Math.max(50,Number(values["StartupSupervisor.ObserverExitRatio"])*speedRpm)));
  }

  function applyStartupTiming(result, seed, sources) {
    const v = path => Number(result[path]), put = tuningWriter(result, seed, sources);
    const hz = v("Timing.ControlFrequency_Hz"), divider = v("Timing.MDTMTaskDivider_NULL"), slowTs = divider / hz;
    const tickUp = (t, tick = slowTs) => Math.ceil(t / tick - 1e-10) * tick;
    const kt = 1.5 * v("Motor.PolePairs") * v("Motor.PmFlux_Wb");
    const currentSettle = 4 / Math.min(v("ControlTargets.CurrentLoopKpD_VperA") / v("Motor.Ld_H"), v("ControlTargets.CurrentLoopKpQ_VperA") / v("Motor.Lq_H"));
    const mechanicalSettle = current => 4 / (Math.SQRT1_2 * Math.sqrt(v("Motor.PolePairs") * kt * current / v("Motor.Inertia_kgm2")));
    const alignSettle = mechanicalSettle(v("StartupSupervisor.IfAlignIdOverride_A"));
    const runSettle = mechanicalSettle(v("StartupSupervisor.IfStartIqOverride_A"));
    const smooth = put("StartupSupervisor.IfAccelBlendTime_s", tickUp(Math.max(0.12, runSettle, currentSettle, 10 * slowTs)),
      "max(0.12 s, 4/(0.7071068 × √(pKtI启动/J)), 电流环4时间常数, 10个慢任务周期)，按慢周期向上取整；机械阻尼与0.12 s下限为工程目标");
    const align = put("StartupSupervisor.IfAlignTime_s", tickUp(Math.max(0.1, alignSettle, currentSettle, 10 * slowTs)),
      "max(0.1 s, 4/(0.7071068 × √(pKtI对齐/J)), 电流环4时间常数, 10个慢任务周期)，按慢周期向上取整；小角度等效刚度估算，需验证初始转角和静摩擦");
    const blend = put("StartupSupervisor.IfBlendTime_s", tickUp(Math.max(0.1, runSettle, currentSettle, 10 * slowTs)),
      "max(0.1 s, 启动电流对应的机械整定时间, 电流环4时间常数, 10个慢任务周期)，按慢周期向上取整；模型在此期间将对齐电流平滑旋转到q轴");
    put("StartupSupervisor.IfIqSlewOverride_Aps", v("StartupSupervisor.IfStartIqOverride_A") / Math.max(currentSettle, 10 * slowTs),
      "启动电流 / max(电流环4时间常数, 10个慢任务周期)；实际限制I/F电流混合结束后的Iq变化");
    const pllSettle = 4 / (v("Observer.PllDamping") * v("Observer.PllBandwidth_rads"));
    const period = 60 / (v("Motor.PolePairs") * v("Observer.SwitchSpeedOverride_rpm"));
    const ready = put("StartupSupervisor.SmoReadyConfirmTime_s", tickUp(Math.max(0.1, pllSettle, 2 * period), 1 / hz),
      "max(0.1 s, 4/(ζ × PLL带宽), 2个接管电周期)，按控制周期向上取整；连续满足就绪条件才开始接管");
    const handover = put("StartupSupervisor.DirectHandoverTime_s", tickUp(Math.max(0.1, pllSettle, 10 * slowTs)),
      "max(0.1 s, 4/(ζ × PLL带宽), 10个慢任务周期)；平滑交接工程时间预算");
    const storedTau = put("StartupSupervisor.HandoverCurrentLpfTau_s", Math.max(slowTs, handover / 2) / divider,
      "实际滤波时间常数取max(1个慢周期, 交接时间/2)，填写值 = 实际时间常数 / MDTM分频；现有模型用快周期生成系数、在慢任务执行，已补偿分频");
    const lossConfirm = put("StartupSupervisor.ObserverLossConfirmTime_s", tickUp(Math.max(0.02, period, pllSettle / 4), 1 / hz),
      "max(0.02 s, 1个接管电周期, 1/(ζ × PLL带宽))，按控制周期向上取整；接管期间及接管后均须连续失效达到此时间才退出，恢复就绪即清零失效计时");
    put("StartupSupervisor.DirectHandoverDwellTime_s", tickUp(Math.max(handover, 2 * storedTau * divider, lossConfirm), 1 / hz),
      "max(交接时间, 2 × 实际交接电流滤波时间常数, 连续失效确认时间)，按控制周期向上取整；从每次I/F转入SMO起计时，短时失锁恢复不重启窗口；确认失效时仍在窗口内则连续退回I/F，窗口外停机，低速退出另按退出比例处理");
    const uniformRamp = v("Observer.SwitchSpeedOverride_rpm") / v("StartupSupervisor.IfAccel_rpms");
    // Integral of smoothstep acceleration is T*(x^3-x^4/2) for x in [0,1].
    // It contributes half of the full acceleration over the smoothing stage.
    let ramp = uniformRamp + smooth / 2;
    if (uniformRamp < smooth / 2) {
      let lo = 0, hi = 1;
      for (let i = 0; i < 48; i++) {
        const x = (lo + hi) / 2;
        if (smooth * (x ** 3 - x ** 4 / 2) < uniformRamp) lo = x; else hi = x;
      }
      ramp = smooth * (lo + hi) / 2;
    }
    const margin = put("StartupSupervisor.StartupTimeoutMargin_s", tickUp(Math.max(0.5, 0.25 * ramp, 2 * pllSettle, 2 * slowTs), 1 / hz),
      "max(0.5 s, 理论升速时间的25%, 2个PLL整定时间, 2个慢任务周期)，为初始转角、同步振荡与就绪重置留裕量", "工程初值");
    put("StartupSupervisor.StartupTimeoutOverride_s", tickUp(align + blend + ramp + ready + margin, 1 / hz),
      "对齐时间 + I/F电流混合时间 + 含smoothstep加速度段的升速时间 + 就绪确认时间 + 超时裕量；按控制周期向上取整，接管后驻留不计入启动超时");
  }

  function applySmoTheoretical(result, seed, sources) {
    const v = path => Number(result[path]);
    const put = (path, value, reason, kind = "理论初值") => {
      if (emptyValue(seed[path]) || automatic.isLegacy(seed[path])) {
        if (!Number.isFinite(value)) throw new Error(`${path} 无法计算理论初值，请检查依赖参数`);
        result[path] = raw(value); sources[path] = `${kind}：${reason}`;
      }
      return v(path);
    };
    const ldc = v("Motor.Ld_H"), lqc = v("Motor.Lq_H"), rs = v("Motor.StatorResistance_Ohm");
    const flux = v("Motor.PmFlux_Wb"), pairs = v("Motor.PolePairs"), imax = v("Motor.MaxCurrent_A");
    const bus = v("Inverter.NominalDcBus_V"), pwm = v("Inverter.PwmFrequencyOverride_Hz");
    const vmax = bus * v("Limits.VoltageMargin_NULL") * v("Inverter.LinearModulationUtilization_NULL") / Math.sqrt(3);
    const ipmsm = result["Meta.MotorClass"] === "IPMSM";
    const modelR = rs * v("Observer.EffectiveResistanceScale"), modelL = ipmsm ? ldc : v("Observer.EffectiveInductance_H");
    if (![ldc, lqc, rs, flux, pairs, imax, bus, pwm, vmax, modelR, modelL].every(x => Number.isFinite(x) && x > 0))
      throw new Error("SMO 理论初值需要有效且大于 0 的电机参数、母线电压、PWM 频率和观测器等效参数");
    const designSpeed = put("Observer.DesignMechSpeed_rpm", observerDesignSpeed(v),
      "min(额定母线基速, 电机最大机械转速, 转速指令上限)；按无感无弱磁范围估计，实际无感最高转速可手动覆盖");
    const omega = Math.abs(designSpeed) * 2 * Math.PI / 60 * pairs, emf = omega * flux;
    put("Observer.EmfLpfPole_rads", Math.max(omega / Math.tan(15 * Math.PI / 180), 5 * v("Observer.PllBandwidth_rads")),
      "max(设计电角速度 / tan15°, 5 × PLL带宽)；15°相位预算和5倍带宽间隔为工程目标，随后联动误差边界与延迟拟合");
    const voltageError = put("Inverter.VoltageErrorBudget_V", inverterVoltageError(v),
      "4/3 × (Udc × 死区时间 × PWM频率 + 上下桥臂平均压降) + 1% × Udc；残差未测时按完整误差包络留裕量，1% 为工程预算，可用实测覆盖");
    const saliency = ipmsm ? Math.abs(ldc - lqc) : 0;
    const currentSlew = put("Inverter.CurrentSlew_Aps", (vmax + rs * imax + emf + omega * saliency * imax) / Math.min(ldc, lqc),
      ipmsm ? "(dq电压上限 + Rs×Imax + ωe×ψ + ωe×|Ld−Lq|×Imax) / min(Ld,Lq)；平均电压模型下的 αβ 电流变化率保守包络"
        : "(dq电压上限 + Rs×Imax + ωe×ψ) / Ls；平均电压模型下的 αβ 电流变化率保守包络");
    // IPMSM: Eext = omega*(psi + (Ld-Lq)*Id) - (Ld-Lq)*dIq/dt.
    // Bound dIq/dt independently with the physical q-axis voltage equation.
    const iqSlew = (vmax + rs * imax + omega * (ldc * imax + flux)) / lqc;
    const extendedEmf = emf + saliency * (omega * imax + iqSlew);
    const calculatedGain = v("Observer.SlideGainMargin") * (extendedEmf +
      v("Observer.ResistanceUncertaintyFraction") * modelR * imax +
      v("Observer.InductanceUncertaintyFraction") * modelL * currentSlew + voltageError);
    const gain = put("Observer.SlideGainOverride_V", calculatedGain,
      `裕量 × (${ipmsm ? "扩展反电势上界" : "设计反电势"} + δR×Rmodel×Imax + δL×Lmodel×电流变化率 + 电压误差预算)；须结合误差边界、采样周期及无感工况验证`);
    const discrete = smoDiscreteModel(result);
    if (!discrete.valid) throw new Error("SMO 边界整定需要有效的等效 R/L、控制频率和反电势低通极点");
    const noiseFloor = Math.max(v("Inverter.CurrentSignNoiseMultiplier") * v("CurrentSensor.NoiseStd_A"),
      v("Observer.ErrBoundaryRatedFraction") * v("Motor.RatedCurrent_A"), 1e-3);
    const boundary = put("Observer.ErrBoundaryOverride_A", Math.max(noiseFloor, gain / discrete.slopeTarget),
      "max(噪声/额定电流下限, 滑模增益 ÷ 目标注入斜率)；目标斜率由当前离散电流/反电势模型按阻尼约 0.7071068 联合整定");

    const emfLow = put("Observer.GainScheduleEmfLowOverride_V", Math.max(v("Observer.MinEmf_V"),
      0.4 * Math.abs(v("Observer.SwitchSpeedOverride_rpm")) * 2 * Math.PI / 60 * pairs * flux),
      "max(最小反电势, 0.4 × 接管转速对应的永磁反电势)；0.4 为沿用的工程比例，启用自适应时使用");
    const emfHigh = put("Observer.GainScheduleEmfHighOverride_V", Math.max(emfLow + v("Observer.MinEmf_V"), emf),
      "max(低反电势阈值 + 最小反电势, 设计转速对应的永磁反电势)；IPMSM 仍需按实际扩展反电势验证调度区间");
    const manualSlew = !emptyValue(seed["Inverter.CurrentSlew_Aps"]) && !automatic.isLegacy(seed["Inverter.CurrentSlew_Aps"]);
    const gainAtEmf = pmEmf => {
      const w = pmEmf / flux;
      const slew = manualSlew ? currentSlew : (vmax + rs * imax + pmEmf + w * saliency * imax) / Math.min(ldc, lqc);
      const qSlew = (vmax + rs * imax + w * (ldc * imax + flux)) / lqc;
      const extended = pmEmf + saliency * (w * imax + qSlew);
      return v("Observer.SlideGainMargin") * (extended + v("Observer.ResistanceUncertaintyFraction") * modelR * imax +
        v("Observer.InductanceUncertaintyFraction") * modelL * slew + voltageError);
    };
    // Prepare useful ranges even while adaptation is disabled. The MATLAB
    // resolver still applies the fixed main gain/boundary in that mode.
    const minGain = put("Observer.SlideGainMinOverride_V", gainAtEmf(emfLow),
      "按低反电势阈值对应工况计算反电势与 R/L/电压误差预算；仅启用自适应时使用");
    const maxGain = put("Observer.SlideGainMaxOverride_V", Math.max(gain, minGain, calculatedGain, gainAtEmf(emfHigh)),
      "覆盖设计工况、高反电势阈值工况、固定滑模增益及增益下限；仅启用自适应时使用");
    const minBoundary = put("Observer.ErrBoundaryMinOverride_A", Math.max(noiseFloor, maxGain / discrete.slopeTarget),
      "max(噪声/额定电流下限, 滑模增益上限 ÷ 目标注入斜率)；联合校核最大增益与最小边界");
    put("Observer.ErrBoundaryMaxOverride_A", Math.max(boundary, minBoundary / 0.7),
      "max(固定电流误差边界, 误差边界下限 ÷ 0.7)；沿用 0.7 工程比例，使低反电势区的修正较平缓");
    put("Observer.GainScheduleTimeConstant_s", 0.02,
      "20 ms，用于平滑反电势调度；需结合加减速、噪声及接管过程验证，手动值保留", "工程初值");
    put("Observer.StaticAngleOffset_rad", 0,
      "无已知固定角偏差时取0 rad；有实测偏差请手动填写", "工程初值");
    put("Inverter.SamplingDelay_s", 0,
      "未识别的额外板级延迟先取0 s；仅填写尚未计入相电流采样延迟的部分，需实测确认", "工程初值");
    if (emptyValue(seed["Observer.TotalDelay_s"]) || automatic.isLegacy(seed["Observer.TotalDelay_s"])) {
      const fit = smoPhaseFit(result);
      if (!fit.valid) throw new Error("观测器延迟拟合需要有效且通过局部离散校核的增益、误差边界和设计转速");
      put("Observer.TotalDelay_s", fit.delay_s,
        "在设计电角速度范围内，按离散电流/反电势模型扣除atan低通补偿；" +
        (String(result["Observer.AdaptiveInjectionEnable"]) === "true" ? "自适应按各转速的预计稳态调度，最小化最大相位残差；" : "固定注入作非负最小二乘相位拟合；") +
        "不包含逆变器或相电流采样延迟，局部拟合最大残差约" + fit.residualMax_deg.toPrecision(7) + "°");
    }
  }

  function simulationStepCandidate(pwmHz, deadTime) {
    if (!(Number.isFinite(pwmHz) && pwmHz > 0 && Number.isFinite(deadTime) && deadTime >= 0))
      throw new Error("推荐仿真步长需要正的PWM频率和非负死区时间");
    // An even number of steps resolves both halves of the triangle carrier.
    const required = Math.max(200, deadTime > 0 ? 4 / (pwmHz * deadTime) : 0);
    const pwmSteps = 2 * Math.ceil(required / 2 - 1e-10);
    if (!Number.isSafeInteger(pwmSteps) || pwmSteps > 4294967295)
      throw new Error("死区时间过小，推荐PWM步数超过模型uint32计数容量");
    return 1 / (pwmHz * pwmSteps);
  }

  function validate(values, options = {}) {
    const directCodegen = options?.mode === "direct-codegen";
    const {drive: c, issues} = assemble(values);
    if (issues.length) return {ok: false, issues, warnings: [], drive: c};
    const add = (path, condition, message) => { if (!condition) issues.push({path, message}); };
    for (const field of fields.filter(isVersion)) add(field.path, Number(values[field.path]) >= 0, "版本号须为非负数，例如 1.0、1.1");
    const positive = ["Timing.BaseTick_s", "Timing.ControlFrequency_Hz", "Motor.StatorResistance_Ohm", "Motor.Ld_H", "Motor.Lq_H", "Motor.PmFlux_Wb", "Motor.Inertia_kgm2", "Motor.RatedCurrent_A", "Motor.MaxCurrent_A", "Motor.MaxMechSpeed_rpm", "PositionSensor.PllBandwidth_rads", "Simulation.PowerStageStep_s", "Execution.StopTime_s"];
    for (const path of positive) add(path, Number(values[path]) > 0, "必须大于 0");
    // Physical domains and storage capacity are checked here, not through
    // arbitrary Min/Max declarations on generated calibration objects.
    for (const path of ["Limits.SoftwareOverCurrent_A", "Limits.SoftwareOverCurrentConfirm_s", "Limits.SpeedCommandAbsMax_rpm", "Observer.EffectiveResistanceScale", "Observer.EffectiveInductance_H", "Inverter.CurrentSignBoundaryMin_A"])
      add(path, Number(values[path]) > 0, "必须大于 0");
    for (const path of ["Motor.ViscousFriction_Nms", "CurrentSensor.NoiseStd_A", "Inverter.HighSideVoltageDrop_V", "Inverter.LowSideVoltageDrop_V", "Inverter.CurrentSignNoiseMultiplier", "Inverter.CurrentSignHold_s", "Inverter.NonlinearityCompensationGain", "Inverter.NonlinearityCompensationMax_V", "ControlTargets.SpeedCommandSlew_rpms", "FieldWeakening.EntrySpeedOverride_rpm", "FieldWeakening.VoltageLoopKp_AperUnit", "FieldWeakening.VoltageLoopKi_AperUnitPerS", "FieldWeakening.IdSlew_Aps"])
      add(path, Number(values[path]) >= 0, "必须为非负数");
    const hz = c.Timing.ControlFrequency_Hz;
    for (const path of ["Limits.CurrentCommandMax_A", "Limits.SoftwareOverCurrent_A"]) {
      const current = Math.fround(Number(values[path])), squared = Math.fround(current * current);
      add(path, Number.isFinite(squared) && squared > 0, "该电流限值的平方必须能由模型的 single 类型表示");
    }
    add("Limits.SoftwareOverCurrentConfirm_s", Math.round(c.Limits.SoftwareOverCurrentConfirm_s * hz) <= 255, "过流确认时间对应的计数不能超过 uint8 的 255");
    add("Inverter.CurrentSignHold_s", Math.round(c.Inverter.CurrentSignHold_s * hz) <= 65535, "极性保持时间对应的计数不能超过 uint16 的 65535");
    add("Inverter.MaximumDeadTimeDuty_NULL", c.Inverter.MaximumDeadTimeDuty_NULL > 0 && c.Inverter.MaximumDeadTimeDuty_NULL < 0.5, "最大死区占比须在 (0,0.5) 内");
    add("Inverter.DeadTimePolarity", [-1,1].includes(c.Inverter.DeadTimePolarity), "死区极性须为 +1 或 -1");
    for (const path of ["Limits.VoltageMargin_NULL", "Inverter.LinearModulationUtilization_NULL"])
      add(path, Number(values[path]) > 0 && Number(values[path]) <= 1, "电压利用率须在 (0,1] 内");
    // Jury stability limit of the model's predictor/corrector position PLL.
    add("PositionSensor.PllBandwidth_rads", c.PositionSensor.PllBandwidth_rads / hz < Math.sqrt(8) - 2, `当前离散 PLL 要求带宽小于 ${((Math.sqrt(8)-2)*hz).toPrecision(7)} rad/s；可放宽误差目标、采用转速斜坡或提高控制频率`);
    const ticks = Math.round(1 / (hz * c.Timing.BaseTick_s));
    const wholeKilohertz = Math.abs(hz / controlFrequencyQuantum_Hz - Math.round(hz / controlFrequencyQuantum_Hz)) <= 1e-9;
    const ticksFitUint32 = Number.isSafeInteger(ticks) && ticks > 0 && ticks <= 4294967295;
    const exactlyRealizable = ticksFitUint32 && Math.abs(1 / (ticks * c.Timing.BaseTick_s) - hz) / hz * 1e6 <= c.Timing.ExactMatchTolerance_ppm;
    add("Timing.ControlFrequency_Hz",
      directCodegen ? hz > 0 && exactlyRealizable : hz >= 4000 && hz <= 20000 && wholeKilohertz && exactlyRealizable,
      directCodegen ? "控制频率须大于 0，并由基础时钟整数分频精确实现" : "控制频率须在 4–20 kHz 内、为整数 kHz，并由基础时钟整数分频精确实现");
    const pwm = c.Inverter.PwmFrequencyOverride_Hz;
    add("Inverter.PwmFrequencyOverride_Hz", pwm > 0 && Math.abs(pwm / hz - Math.round(pwm / hz)) <= 1e-6 && pwm >= hz, "PWM 频率必须为控制频率的正整数倍");
    const pwmSteps = 1 / (pwm * c.Simulation.PowerStageStep_s);
    const controlSteps = 1 / (hz * c.Simulation.PowerStageStep_s);
    const integerSteps = n => Number.isFinite(n) && n >= 1 && n <= 4294967295 && Math.abs(n - Math.round(n)) <= 1e-8 * Math.max(1, n);
    add("Simulation.PowerStageStep_s", integerSteps(pwmSteps) && integerSteps(controlSteps), "功率级步长须将PWM周期与控制周期划分为整数步，PWM步数须可由uint32表示");
    add("Timing.InputTaskFrequencyOverride_Hz", Math.abs(c.Timing.InputTaskFrequencyOverride_Hz / hz - 1) < 1e-7, "当前输入任务必须与控制任务同频");
    add("Timing.MDTMTaskDivider_NULL", Number.isInteger(c.Timing.MDTMTaskDivider_NULL) && c.Timing.MDTMTaskDivider_NULL >= 1 && c.Timing.MDTMTaskDivider_NULL <= 65535, "MDTM 分频须为 uint16 可表示的正整数");
    add("Meta.MotorClass", ["SPMSM", "IPMSM"].includes(c.Meta.MotorClass), "请选择 SPMSM 或 IPMSM");
    const saliency = Math.abs(c.Motor.Lq_H - c.Motor.Ld_H) / (0.5 * (c.Motor.Ld_H + c.Motor.Lq_H));
    add("Motor.Lq_H", c.Meta.MotorClass === "IPMSM" ? c.Motor.Lq_H > c.Motor.Ld_H && saliency > c.CurrentReference.MinimumIpmsmSaliencyRatio_NULL : saliency <= c.CurrentReference.MinimumIpmsmSaliencyRatio_NULL, "Ld/Lq 与电机类型或凸极比门限不一致");
    add("Motor.PolePairs", Number.isInteger(c.Motor.PolePairs) && c.Motor.PolePairs > 0 && c.Motor.PolePairs <= 65535, "极对数须为 uint16 可表示的正整数");
    add("Motor.RatedCurrent_A", c.Motor.RatedCurrent_A <= c.Motor.MaxCurrent_A, "额定峰值电流不能大于最大峰值电流");
    add("Limits.CurrentCommandMax_A", c.Limits.CurrentCommandMax_A > 0 && c.Limits.CurrentCommandMax_A <= c.Motor.MaxCurrent_A, "指令电流限值须在电机最大电流以内");
    add("Inverter.NominalDcBus_V", 0 < c.Inverter.MinValidDcBus_V && c.Inverter.MinValidDcBus_V < c.Inverter.NominalDcBus_V && c.Inverter.NominalDcBus_V < c.Inverter.MaxDcBus_V, "须满足 0 < 最低电压 < 额定电压 < 最高电压");
    add("Inverter.MinDuty_NULL", c.Inverter.MinDuty_NULL >= 0 && c.Inverter.MinDuty_NULL < c.Inverter.MaxDuty_NULL && c.Inverter.MaxDuty_NULL <= 1, "占空比须满足 0 ≤ 最小值 < 最大值 ≤ 1");
    add("Inverter.DeadTime_s", c.Inverter.DeadTime_s >= 0 && c.Inverter.DeadTime_s * pwm <= c.Inverter.MaximumDeadTimeDuty_NULL, "死区必须非负且不超过 PWM 死区占比上限");
    add("CurrentReference.MtpaTableSize", Number.isInteger(c.CurrentReference.MtpaTableSize) && c.CurrentReference.MtpaTableSize >= 17 && c.CurrentReference.MtpaTableSize <= 257, "MTPA 表长须为 17–257 的整数");
    for (const key of ["VoltageControlFilterAlpha_NULL", "VoltageReportFilterAlpha_NULL"]) add(`DcBusMeasurement.${key}`, c.DcBusMeasurement[key] > 0 && c.DcBusMeasurement[key] <= 1, "滤波系数须在 (0,1] 内");
    const busCurrent = c.DcBusMeasurement;
    add("DcBusMeasurement.CurrentHardMax_A", busCurrent.CurrentHardMax_A > 0, "母线电流硬保护上限须大于 0");
    add("DcBusMeasurement.CurrentHardMin_A", busCurrent.CurrentHardMin_A < 0, "母线电流硬保护下限须小于 0（回馈方向）");
    add("DcBusMeasurement.CurrentPlausibleMax_A", busCurrent.CurrentPlausibleMax_A > 0 && busCurrent.CurrentPlausibleMax_A >= Math.max(Math.abs(busCurrent.CurrentHardMax_A), Math.abs(busCurrent.CurrentHardMin_A)), "合理范围上限须为正，且覆盖正反方向硬保护限值的绝对值");
    for (const path of ["FieldWeakening.IdMin_A", "Limits.DemagnetizationCurrentMin_A"]) add(path, Number(values[path]) <= 0, "负 d 轴电流下限须小于或等于 0");
    add("DcBusMeasurement.VoltageReportFilterAlpha_NULL", c.DcBusMeasurement.VoltageReportFilterAlpha_NULL <= c.DcBusMeasurement.VoltageControlFilterAlpha_NULL, "上报滤波系数不能大于控制滤波系数");
    add("DcBusMeasurement.CurrentInputMovingAverageWindowSamples", Number.isInteger(c.DcBusMeasurement.CurrentInputMovingAverageWindowSamples) && c.DcBusMeasurement.CurrentInputMovingAverageWindowSamples >= 1 && c.DcBusMeasurement.CurrentInputMovingAverageWindowSamples <= 64, "滑动窗口须为 1–64 的整数");
    add("DcBusMeasurement.CurrentSource_enum", [0, 1].includes(c.DcBusMeasurement.CurrentSource_enum), "电流来源须为 0 或 1");
    const bits = Math.log2(c.PositionSensor.NativeCountsPerMechanicalRev);
    add("PositionSensor.NativeCountsPerMechanicalRev", Number.isInteger(bits) && bits >= 12 && bits <= 24, "原生位置分辨率须为 2^12 至 2^24");
    add("PositionSensor.ControlAngleCounts", [4096, 8192].includes(c.PositionSensor.ControlAngleCounts), "控制角度计数须为 4096 或 8192，Sin/Cos LUT 全周分段数同步设置");
    add("PositionSensor.Direction", [-1, 1].includes(c.PositionSensor.Direction), "方向须为 +1 或 -1");
    const trigBackends = ["LUT", "GENERIC", "TRICORE", "TI_TMU", "STM32_CORDIC"];
    for (const key of ["SinCosBackend", "AtanBackend"]) add(`PlatformMath.${key}`, trigBackends.includes(c.PlatformMath[key]), "请选择已有的三角函数实现");
    add("PlatformMath.SqrtBackend", ["GENERIC", "TI_TMU", "STM32_FPU"].includes(c.PlatformMath.SqrtBackend), "请选择已有的平方根实现");
    const mathBackends = Object.values(c.PlatformMath);
    const families = [mathBackends.some(x => x.startsWith("STM32_")), mathBackends.includes("TI_TMU"), mathBackends.includes("TRICORE")];
    for (const key of Object.keys(c.PlatformMath)) add(`PlatformMath.${key}`, families.filter(Boolean).length <= 1, "同一目标板不能混用 STM32、TI 和 TriCore 硬件实现");
    for (const [key, value] of Object.entries(c.ControlTargets)) if (key.includes("Loop")) add(`ControlTargets.${key}`, value > 0, "PI 系数须为有限正数");
    add("FieldWeakening.ExitUtilization_NULL", c.FieldWeakening.ExitUtilization_NULL >= 0 && c.FieldWeakening.ExitUtilization_NULL < c.FieldWeakening.EntryUtilization_NULL, "退出利用率须非负且低于进入利用率");
    add("FieldWeakening.EntryUtilization_NULL", c.FieldWeakening.EntryUtilization_NULL > 0 && c.FieldWeakening.EntryUtilization_NULL <= 1, "弱磁进入利用率须在 (0,1] 内");
    add("Features.ActiveInverterCompensationEnable", c.Features.ActiveInverterCompensationEnable === c.Inverter.ActiveNonlinearityCompensationEnable, "功能开关与逆变器补偿开关须一致");
    add("Features.SensoredFieldWeakeningEnable", c.Features.SensoredFieldWeakeningEnable === c.FieldWeakening.Enable, "功能开关与有感弱磁开关须一致");
    add("Execution.ObserverBuildVariant", [0, 1].includes(c.Execution.ObserverBuildVariant), "观测器构建选择须为 0 或 1");
    add("Execution.WorkMode_enum", Number.isInteger(c.Execution.WorkMode_enum) && c.Execution.WorkMode_enum >= 0 && c.Execution.WorkMode_enum <= 6 && (c.Execution.ObserverBuildVariant === 1 || c.Execution.WorkMode_enum !== 6), "无感模式 6 需要 SMO 构建，其余模式须为 0–5");
    add("Execution.TargetSpeed_rpm", Math.abs(c.Execution.TargetSpeed_rpm) <= c.Limits.SpeedCommandAbsMax_rpm, "仿真目标转速超出指令限值");
    const ov = c.Protection.DcBusOverVoltage_V;
    const uv = c.Protection.DcBusUnderVoltage_V;
    add("Protection.DcBusOverVoltage_V", ov > c.Inverter.NominalDcBus_V && ov <= c.Inverter.MaxDcBus_V, "过压阈值须高于额定电压且不超过最高电压");
    add("Protection.DcBusUnderVoltage_V", uv >= 0 && uv < c.Inverter.NominalDcBus_V, "欠压阈值须非负且低于额定电压");
    add("Protection.VoltageViolationArea_Vs", c.Protection.VoltageViolationArea_Vs > 0, "越限积分阈值须为正数");
    for (const [key, min, max] of [["VoltageRecoveryRate_V",0,100],["FaultClearHold_s",0,60],["CommandTimeout_s",0.001,10]]) add(`Protection.${key}`, c.Protection[key] >= min && c.Protection[key] <= max, `须在 ${min}–${max} 内`);
    add("Feedforward.VoltageMode_enum", [0,1,2,3].includes(c.Feedforward.VoltageMode_enum), "请选择关闭、双轴、仅 d 轴或仅 q 轴");
    for (const [key, max] of [["DAxisScale_NULL",1],["QAxisScale_NULL",1],["ElectricalAngleCompScale_NULL",1.5]]) add(`Feedforward.${key}`, c.Feedforward[key] >= 0 && c.Feedforward[key] <= max, `须在 0–${max} 内`);
    const warnings = [];
    if (c.Motor.MaxMechSpeed_rpm > 0 && c.Motor.PolePairs > 0) {
      const recommendation = recommendControlFrequency({
        maxMechSpeed_rpm: c.Motor.MaxMechSpeed_rpm,
        polePairs: c.Motor.PolePairs,
        baseTick_s: c.Timing.BaseTick_s,
        minimum_Hz: c.Timing.MinimumControlFrequency_Hz,
        maximum_Hz: c.Timing.MaximumControlFrequency_Hz,
        exactMatchTolerance_ppm: c.Timing.ExactMatchTolerance_ppm
      });
      if (recommendation.limitedByMaximum) warnings.push(
        `按最高转速和极对数，每电角周期${controlSamplesPerElectricalCycle}个样本需要 ${recommendation.unconstrainedMinimum_Hz.toPrecision(7)} Hz，超过当前模型 ${c.Timing.MaximumControlFrequency_Hz.toPrecision(7)} Hz 上限；需降低最高转速或扩展时序上限后验证。`);
      else if (hz < recommendation.frequency_Hz * (1 - 1e-12)) warnings.push(
        `当前控制频率低于按最高转速计算的 ${recommendation.frequency_Hz.toPrecision(7)} Hz 最低推荐（每电角周期至少${controlSamplesPerElectricalCycle}个样本）。`);
    }
    for (const path of ["Observer.EmfLpfPole_rads", "Observer.PllBandwidth_rads", "Observer.PllDamping"])
      add(path, Number(values[path]) > 0, "滤波极点、PLL带宽和阻尼须大于0");
    for (const path of ["Observer.TotalDelay_s", "Inverter.SamplingDelay_s"])
      add(path, Number(values[path]) >= 0 && Number(values[path]) <= 0.01, "延迟须在0～0.01 s内");
    const pllLimit = 2 * hz / (Math.hypot(c.Observer.PllDamping, 1) + c.Observer.PllDamping);
    add("Observer.PllBandwidth_rads", c.Observer.PllBandwidth_rads < pllLimit,
      "当前离散PLL要求带宽小于" + pllLimit.toPrecision(7) + " rad/s");
    if (c.Observer.PllBandwidth_rads >= 0.5 * pllLimit * (1 - 1e-12))
      warnings.push("SMO PLL带宽已达到或超过建议采样上限；自动值可能无法满足相位误差或带宽间隔目标，需核对动态要求。");
    const designOmega = Math.abs(c.Observer.DesignMechSpeed_rpm) * 2 * Math.PI / 60 * c.Motor.PolePairs;
    if (designOmega >= 0.8 * Math.PI * hz) warnings.push("SMO设计电角频率接近或超过采样Nyquist频率；延迟拟合仅覆盖至0.8倍Nyquist，需提高控制频率或降低设计转速。");
    for (const path of ["Observer.DesignMechSpeed_rpm", "Observer.SlideGainOverride_V", "Observer.SlideGainMinOverride_V", "Observer.SlideGainMaxOverride_V", "Observer.SlideGainMargin", "Inverter.CurrentSlew_Aps", "Observer.ErrBoundaryOverride_A", "Observer.ErrBoundaryMinOverride_A", "Observer.ErrBoundaryMaxOverride_A", "Observer.GainScheduleEmfLowOverride_V", "Observer.GainScheduleEmfHighOverride_V", "Observer.GainScheduleTimeConstant_s"])
      add(path, Number(values[path]) > 0, "SMO 整定参数须大于 0");
    for (const path of ["Inverter.VoltageErrorBudget_V", "Observer.ResistanceUncertaintyFraction", "Observer.InductanceUncertaintyFraction", "Observer.ErrBoundaryRatedFraction"])
      add(path, Number(values[path]) >= 0, "误差预算或不确定度须非负");
    add("Observer.SlideGainMaxOverride_V", c.Observer.SlideGainMaxOverride_V >= c.Observer.SlideGainMinOverride_V, "滑模增益上限须不小于下限");
    add("Observer.ErrBoundaryMaxOverride_A", c.Observer.ErrBoundaryMaxOverride_A >= c.Observer.ErrBoundaryMinOverride_A, "误差边界上限须不小于下限");
    add("Observer.GainScheduleEmfHighOverride_V", c.Observer.GainScheduleEmfHighOverride_V > c.Observer.GainScheduleEmfLowOverride_V, "调度高反电势须大于低反电势");
    const startup = c.StartupSupervisor, observer = c.Observer;
    for (const key of ["IfAccel_rpms", "IfSwitchSpeed_rpm", "SmoReadyConfirmTime_s", "ObserverLossConfirmTime_s", "DirectHandoverDwellTime_s", "StartupTimeoutOverride_s", "IfStartIqOverride_A", "IfIqSlewOverride_Aps", "HandoverCurrentLpfTau_s"])
      add(`StartupSupervisor.${key}`, startup[key] > 0, "启动整定参数须大于0");
    for (const key of ["IfAccelBlendTime_s", "IfAlignTime_s", "IfBlendTime_s", "StartupTimeoutMargin_s", "IfAlignIdOverride_A", "DirectAccelIqSeedOverride_A"])
      add(`StartupSupervisor.${key}`, startup[key] >= 0, "启动参数须非负");
    for (const key of ["MinEmf_V", "EmfObservabilityMargin", "MinSwitchSpeed_rpm", "SwitchSpeedOverride_rpm", "ReadySpeedErrorFraction", "ReadySpeedErrorOverride_rads", "ReadyPllError"])
      add(`Observer.${key}`, observer[key] > 0, "可观测性和就绪参数须大于0");
    add("Observer.ReadyPllError", observer.ReadyPllError <= 1, "归一化PLL就绪误差须在(0,1]内");
    add("StartupSupervisor.ObserverExitRatio", startup.ObserverExitRatio >= 0.1 && startup.ObserverExitRatio <= 0.95, "退出比例须在模型实际使用范围0.1～0.95内");
    add("StartupSupervisor.DirectHandoverTime_s", startup.DirectHandoverTime_s > 0, "交接时间须大于 0");
    for (const key of ["IfStartIqOverride_A", "IfAlignIdOverride_A"])
      add(`StartupSupervisor.${key}`, startup[key] <= Math.min(c.Limits.CurrentCommandMax_A, c.Motor.MaxCurrent_A), "启动电流须在电机最大电流与指令限值以内");
    add("StartupSupervisor.DirectAccelIqSeedOverride_A", startup.DirectAccelIqSeedOverride_A <= Math.min(c.Motor.MaxCurrent_A, c.Limits.CurrentCommandMax_A), "交接加速电流须在电机最大电流与指令限值以内");
    add("StartupSupervisor.SmoReadyConfirmTime_s", Math.round(startup.SmoReadyConfirmTime_s * hz) <= 65535, "就绪确认计数不能超过uint16的65535");
    for (const key of ["ObserverLossConfirmTime_s", "DirectHandoverDwellTime_s", "StartupTimeoutOverride_s"])
      add(`StartupSupervisor.${key}`, Math.round(startup[key] * hz) <= 4294967295, "时序计数不能超过uint32范围");
    const startupKt = 1.5 * c.Motor.PolePairs * c.Motor.PmFlux_Wb;
    const neededIq = (c.Motor.Inertia_kgm2 * startup.IfAccel_rpms * 2 * Math.PI / 60 + Math.abs(c.Motor.LoadTorque_Nm) + c.Motor.ViscousFriction_Nms * observer.SwitchSpeedOverride_rpm * 2 * Math.PI / 60) / startupKt;
    if (startup.IfStartIqOverride_A < 2 * neededIq * (1 - 1e-10)) warnings.push("I/F启动电流无法覆盖当前加速度与负载的2倍转矩裕量；需降低加速度、核对负载或增加允许电流。");
    if (startup.DirectAccelIqSeedOverride_A < neededIq * (1 - 1e-10)) warnings.push("交接加速电流低于当前惯量、加速度与负载的理论需求，请核对电流限值、负载或加速度。");
    if (c.Execution.WorkMode_enum === 6 && Math.abs(c.Execution.TargetSpeed_rpm) < observer.SwitchSpeedOverride_rpm)
      warnings.push("目标转速低于SMO接管转速，当前模式将保持I/F低速运行。");
    if (observer.SwitchSpeedOverride_rpm > observer.DesignMechSpeed_rpm)
      warnings.push("SMO接管转速超过无感设计转速；请核对电压误差预算、磁链、可观测性目标及可用速度范围。");
    if (startupObservableEmf(values, observer.SwitchSpeedOverride_rpm) < observer.MinEmf_V * (1-1e-8))
      warnings.push("计入SMO衰减后，当前转速未同时满足接管反电势裕量和退出转速处的最小反电势；自动转速会联动上调，手动转速需自行核对。");
    if (startup.StartupTimeoutOverride_s < startup.IfAlignTime_s + startup.IfBlendTime_s + observer.SwitchSpeedOverride_rpm / startup.IfAccel_rpms + startup.SmoReadyConfirmTime_s)
      warnings.push("启动超时小于未计平滑延迟的最短启动预算，可能提前退出。");
    const discrete = smoDiscreteCheck(values);
    if (!discrete.valid) warnings.push("SMO 局部离散校核需要正的增益、误差边界、等效电阻、电感及反电势低通极点。");
    else if (!discrete.stable) warnings.push(`SMO 局部离散校核未通过：按当前增益，误差边界须大于 ${discrete.minimumBoundary_A.toPrecision(7)} A；需联合调整增益、误差边界或控制频率后验证。`);
    if (c.Execution.ObserverBuildVariant === 1 && c.Meta.MotorClass === "IPMSM") warnings.push("IPMSM 扩展反电势观测器已有特定 4 kHz 工况验证；新配置仍需单独验证闭环表现。");
    if (c.Limits.SoftwareOverCurrent_A < c.Limits.CurrentCommandMax_A) warnings.push("软件过流阈值低于电流指令限值，模型可能提前触发保护。");
    return {ok: issues.length === 0, issues, warnings, drive: c};
  }

  function recommend(values, targets = {}, startupSearch = {minimum:0, iteration:0}) {
    const result = {...values};
    const baseline = flatten(schema.defaults);
    const combined = {...baseline, ...Object.fromEntries(Object.entries(values).filter(([, value]) => !emptyValue(value)))};
    const v = path => Number(combined[path]);
    const customMotor = ["PolePairs", "StatorResistance_Ohm", "Ld_H", "Lq_H", "PmFlux_Wb", "Inertia_kgm2"].some(key => v(`Motor.${key}`) !== Number(baseline[`Motor.${key}`]));
    const proposed = {...baseline}, sources = {};
    const put = (path, value, reason) => { proposed[path] = raw(value); sources[path] = reason; };
    const frequencyRecommendation = recommendControlFrequency({
      maxMechSpeed_rpm: v("Motor.MaxMechSpeed_rpm"),
      polePairs: v("Motor.PolePairs"),
      baseTick_s: v("Timing.BaseTick_s"),
      minimum_Hz: v("Timing.MinimumControlFrequency_Hz"),
      maximum_Hz: v("Timing.MaximumControlFrequency_Hz"),
      exactMatchTolerance_ppm: v("Timing.ExactMatchTolerance_ppm")
    });
    if (emptyValue(values[controlFrequencyPath])) {
      put(controlFrequencyPath, frequencyRecommendation.frequency_Hz, controlFrequencySource(frequencyRecommendation));
      combined[controlFrequencyPath] = proposed[controlFrequencyPath];
    }
    const hz = v(controlFrequencyPath);
    put(pwmPath, hz, "跟随控制频率");
    if (customMotor) {
      put("Execution.ObserverBuildVariant", 0, "新电机先采用有感构建，便于独立整定与验证");
      put("Execution.WorkMode_enum", 4, "有感转速闭环验证起点");
      put("Observer.EffectiveInductance_H", v("Motor.Ld_H"), "与新电机 d 轴电感一致");
    }
    const maxCurrent = v("Motor.MaxCurrent_A");
    const commandCurrent = emptyValue(values["Limits.CurrentCommandMax_A"]) ? maxCurrent : v("Limits.CurrentCommandMax_A");
    if (customMotor || maxCurrent !== Number(baseline["Motor.MaxCurrent_A"]) || commandCurrent !== Number(baseline["Limits.CurrentCommandMax_A"])) {
      put("Limits.CurrentCommandMax_A", maxCurrent, "跟随电机最大峰值电流");
      put("Limits.SoftwareOverCurrent_A", 1.1 * commandCurrent, "模型设计起点：最大指令电流的 1.1 倍");
    }
    // Use the peak phase-current envelope, valid for both the sampled and
    // duty-weighted bus-current paths; these are motor-based initial limits.
    const busHardCurrent = maxCurrent * 11 / 10;
    put("DcBusMeasurement.CurrentHardMax_A", busHardCurrent, "电机参数计算初值：1.1 × 电机最大相电流峰值；正向母线电流上限");
    put("DcBusMeasurement.CurrentHardMin_A", -busHardCurrent, "电机参数计算初值：−1.1 × 电机最大相电流峰值；回馈电流下限，电源能力较小时需手动收紧");
    const effectiveHardCurrent = Math.max(...["CurrentHardMax_A", "CurrentHardMin_A"].map(key => {
      const path = `DcBusMeasurement.${key}`;
      return Math.abs(Number(emptyValue(values[path]) ? proposed[path] : values[path]));
    }));
    put("DcBusMeasurement.CurrentPlausibleMax_A", Math.max(1.5 * maxCurrent, effectiveHardCurrent * 11 / 10), "电机参数计算初值：max(1.5 × 电机最大相电流峰值, 1.1 × 正反向硬保护绝对限值)，为采样合理性检查保留裕量");
    const demagPath = "Limits.DemagnetizationCurrentMin_A";
    if (emptyValue(values[demagPath])) {
      const characteristicCurrent = v("Motor.PmFlux_Wb") / v("Motor.Ld_H");
      if (!(Number.isFinite(commandCurrent) && commandCurrent > 0 && Number.isFinite(characteristicCurrent) && characteristicCurrent > 0))
        throw new Error("估算负 d 轴电流下限需要有效且大于 0 的指令电流上限、磁链和 Ld");
      // Retain the existing 80/200 current-budget ratio, additionally bounding
      // linear flux cancellation. This is not a magnet demagnetization model.
      put(demagPath, -Math.min(0.4 * commandCurrent, 0.2 * characteristicCurrent), "工程估算初值：−min(0.4 × 指令电流上限, 0.2 × 磁链/Ld)；不代表厂家退磁极限，厂家数据可手动覆盖");
    }
    const effectiveDemagMin = Number(emptyValue(values[demagPath]) ? proposed[demagPath] : values[demagPath]);
    put("FieldWeakening.IdMin_A", Math.max(-commandCurrent, effectiveDemagMin), "计算值：max(−指令电流上限, 退磁电流下限)，限制弱磁负 Id；跟随已填写或本次估算的退磁下限");
    const bus = v("Inverter.NominalDcBus_V");
    put("Observer.MaxElecSpeedOverride_rads", v("Motor.MaxMechSpeed_rpm") * v("Motor.PolePairs") * 2 * Math.PI / 60,
      "整定值：电机最高机械转速 × 极对数 × 2π/60；限制 SMO 电角速度，手动值保留");
    put("Inverter.NonlinearityCompensationMax_V", bus / 20, "预设整定：额定母线电压 / 20；限制补偿 dq 矢量模长，手动值保留");
    if (customMotor || bus !== Number(baseline["Inverter.NominalDcBus_V"])) {
      put("Inverter.MinValidDcBus_V", bus * 0.25, "模型设计起点：额定母线电压的 25%");
      put("Inverter.MaxDcBus_V", Math.max(bus * 1.2, bus + 20), "模型设计起点：额定电压上方保留裕量");
    }
    const observerVariant = emptyValue(values["Execution.ObserverBuildVariant"]) ? (customMotor ? 0 : Number(baseline["Execution.ObserverBuildVariant"])) : v("Execution.ObserverBuildVariant");
    const positionPllPath = "PositionSensor.PllBandwidth_rads";
    if (emptyValue(values[positionPllPath])) {
      const kt = 1.5 * v("Motor.PolePairs") * v("Motor.PmFlux_Wb");
      const availableTorque = kt * commandCurrent - Math.abs(v("Motor.LoadTorque_Nm"));
      const useRamp = targets.positionPllUseSpeedRamp === true;
      const accelerationRads2 = useRamp
        ? v("ControlTargets.SpeedCommandSlew_rpms") * 2 * Math.PI / 60
        : availableTorque / v("Motor.Inertia_kgm2");
      const recommendation = positionPll.recommend({
        polePairs: v("Motor.PolePairs"), accelerationRads2,
        angleErrorDeg: Number(targets.positionPllAngleErrorDeg ?? 3),
        speedLagRads: targets.positionPllSpeedLagRads === undefined ? undefined : Number(targets.positionPllSpeedLagRads)
      });
      put(positionPllPath, recommendation.bandwidthRads, `与 PI 参数计算器共用算法：${useRamp ? "按转速指令斜坡计算加速度" : "按指令电流能力与负载估算加速度"}；α = ${accelerationRads2.toPrecision(7)} rad/s²；B = max(√(pα/允许电角度误差), 2α/允许转速滞后)，未填写的滞后约束不参与计算`);
      // The speed PI must use the freshly calculated PLL in this update.
      combined[positionPllPath] = proposed[positionPllPath];
    }
    const startupValues = {...proposed, ...Object.fromEntries(Object.entries(values).filter(([, value]) => !emptyValue(value) && !automatic.isLegacy(value)))};
    if (!emptyValue(values["Motor.MaxMechSpeed_rpm"]) && emptyValue(values["Limits.SpeedCommandAbsMax_rpm"]))
      startupValues["Limits.SpeedCommandAbsMax_rpm"] = values["Motor.MaxMechSpeed_rpm"];
    const startupSources = {};
    applyStartupMotor(startupValues, values, startupSources, startupSearch.minimum);
    for (const path of Object.keys(startupSources)) {
      put(path, startupValues[path], startupSources[path]);
      combined[path] = startupValues[path];
    }
    const loopTargets = speedLoopTargets(v, targets, hz);
    const dampingPath = "Observer.PllDamping", smoPllPath = "Observer.PllBandwidth_rads";
    if (emptyValue(values[dampingPath])) {
      put(dampingPath, Math.SQRT1_2, "工程初值：阻尼取1/√2，兼顾响应与超调；实测后可手动覆盖");
      combined[dampingPath] = proposed[dampingPath];
    }
    if (emptyValue(values[smoPllPath])) {
      const damping = v(dampingPath);
      const ramp = Math.max(Math.abs(v("ControlTargets.SpeedCommandSlew_rpms")), Math.abs(v("StartupSupervisor.IfAccel_rpms")));
      const electricalAcceleration = ramp * 2 * Math.PI / 60 * v("Motor.PolePairs");
      const trackingBandwidth = Math.sqrt(electricalAcceleration / Math.sin(3 * Math.PI / 180));
      const separationBandwidth = 2 * damping * 5 * 2 * Math.PI * loopTargets.speedHz;
      const requested = Math.max(trackingBandwidth, separationBandwidth);
      const limit = hz / (Math.hypot(damping, 1) + damping);
      if (!(Number.isFinite(requested) && requested > 0 && damping > 0 && Number.isFinite(limit) && limit > 0))
        throw new Error("SMO PLL整定需要正的阻尼、转速环目标及有效的加速度");
      put(smoPllPath, Math.min(requested, limit),
        "理论初值：max(√(极对数 × 机械斜坡角加速度 / sin3°), 2ζ × 5 × 转速环目标角频率)；" +
        "加速度取I/F和转速指令斜坡较大者，3°与5倍间隔为工程目标；" +
        (requested > limit ? "受采样约束限制为" + limit.toPrecision(7) + " rad/s，不能同时满足上述目标，需降低目标动态或提高控制频率" :
          "采用当前离散PLL稳定上界的一半作为推荐上限"));
      // Speed PI tuning below must consume this update's effective SMO PLL.
      combined[smoPllPath] = proposed[smoPllPath];
    }
    const pllPath = observerVariant === 0 ? "PositionSensor.PllBandwidth_rads" : smoPllPath;
    const retune = customMotor || hz !== Number(baseline["Timing.ControlFrequency_Hz"]) || v("Motor.LoadTorque_Nm") !== Number(baseline["Motor.LoadTorque_Nm"]) || v(pllPath) !== Number(baseline[pllPath]) || observerVariant !== Number(baseline["Execution.ObserverBuildVariant"]) || ["currentBandwidthHz", "speedBandwidthHz", "phaseMarginDeg"].some(key => targets[key] !== undefined);
    if (retune) {
      const {currentHz, speedHz, phaseMargin} = loopTargets;
      for (const axis of ["D", "Q"]) {
        const inductance = v(axis === "D" ? "Motor.Ld_H" : "Motor.Lq_H");
        put(`ControlTargets.CurrentLoopKp${axis}_VperA`, 2 * Math.PI * currentHz * inductance, "Kp = 2π × 电流环带宽 × 轴电感");
        put(`ControlTargets.CurrentLoopKiSeries${axis}_perS`, v("Motor.StatorResistance_Ohm") / inductance, "串联 Ki = Rs / 轴电感");
      }
      const omega = 2 * Math.PI * speedHz;
      const pll = v(pllPath);
      const ratio = Math.tan(Math.PI / 2 - phaseMargin * Math.PI / 180 - Math.atan(speedHz / currentHz) - Math.atan(omega / pll));
      if (!(ratio > 0 && Number.isFinite(ratio))) throw new Error("带宽和相位裕度组合无法得到正的 PI 零点");
      const kt = 1.5 * v("Motor.PolePairs") * v("Motor.PmFlux_Wb");
      put("ControlTargets.SpeedLoopKp_AperRpm", v("Motor.Inertia_kgm2") * omega / (kt * Math.sqrt(1 + ratio * ratio)) * (2 * Math.PI / 60), `按惯量、dq 峰值 Kt、${speedHz.toPrecision(4)} Hz 带宽和相位裕度计算${Math.abs(v("Motor.LoadTorque_Nm")) > 0 ? "；自动目标考虑带载启动转速偏差" : ""}`);
      put("ControlTargets.SpeedLoopKiSeriesPerStep_NULL", ratio * omega / hz, "串联 KiStep = PI 零点角频率 / 控制频率");
      put("ControlTargets.SpeedLoopKcSeriesPerStep_NULL", ratio * omega / hz, "串联 KcStep 与 KiStep 采用相同起点");
    }
    if (emptyValue(values["ControlTargets.CurrentLoopKc_perS"])) {
      // Track the slower axis using its effective Kp, including manual gains.
      // The anti-windup loop runs at the control rate, independently of PWM.
      const bandwidths = ["D", "Q"].map(axis => {
        const path = `ControlTargets.CurrentLoopKp${axis}_VperA`;
        const kp = Number(emptyValue(values[path]) ? proposed[path] : values[path]);
        const inductance = v(axis === "D" ? "Motor.Ld_H" : "Motor.Lq_H");
        if (!(Number.isFinite(kp) && kp > 0 && Number.isFinite(inductance) && inductance > 0))
          throw new Error("整定电流环 Kc 需要有效且大于 0 的 d/q 轴 Kp 和相电感");
        return kp / inductance;
      });
      if (!(Number.isFinite(hz) && hz > 0)) throw new Error("整定电流环 Kc 需要有效且大于 0 的控制频率");
      put("ControlTargets.CurrentLoopKc_perS", Math.min(0.5 * Math.min(...bandwidths), 0.2 * hz),
        "抗饱和整定初值：Kc = min(0.5 × min(Kp,d/Ld, Kp,q/Lq), 0.2 × 控制频率)；d/q 共用，未预除频率");
    }
    if (hz !== 4000) {
      for (const key of ["VoltageControlFilterAlpha_NULL", "VoltageReportFilterAlpha_NULL"]) put(`DcBusMeasurement.${key}`, 1 - (1 - Number(baseline[`DcBusMeasurement.${key}`])) ** (4000 / hz), "按控制频率保持基准电压滤波器的等效极点");
      put("DcBusMeasurement.CurrentInputMovingAverageWindowSamples", Math.min(64, Math.max(1, Math.round(hz / 1000))), "保持母线电流平均窗口约 1 ms");
    }
    if (!emptyValue(values["Motor.MaxMechSpeed_rpm"])) put("Limits.SpeedCommandAbsMax_rpm", v("Motor.MaxMechSpeed_rpm"), "跟随已填写的电机最大机械转速");
    put("Features.ActiveInverterCompensationEnable", combined["Inverter.ActiveNonlinearityCompensationEnable"] === "true", "与所属逆变器补偿开关一致");
    put("Features.SensoredFieldWeakeningEnable", combined["FieldWeakening.Enable"] === "true", "与所属有感弱磁开关一致");
    if (!emptyValue(values["Execution.ObserverBuildVariant"])) put("Execution.WorkMode_enum", v("Execution.ObserverBuildVariant") === 0 ? 4 : 6, "跟随所选构建的转速闭环模式");
    const applied = {};
    for (const field of fields) if (emptyValue(result[field.path])) {
      result[field.path] = proposed[field.path];
      applied[field.path] = sources[field.path] || defaultSource(field, proposed[field.path]);
    }
    const filledCount = Object.keys(applied).length;
    const paths = fields.filter(field => field.canResolveAuto && (automatic.isLegacy(values[field.path]) || (emptyValue(values[field.path]) && field.autoResolvedDefault))).map(field => field.path);
    if (paths.length) {
      Object.assign(result, automatic.resolve(result, paths));
      for (const path of paths) applied[path] = automatic.source;
    }
    if (emptyValue(values["Simulation.PowerStageStep_s"])) {
      result["Simulation.PowerStageStep_s"] = raw(simulationStepCandidate(
        Number(result["Inverter.PwmFrequencyOverride_Hz"]), Number(result["Inverter.DeadTime_s"])));
      applied["Simulation.PowerStageStep_s"] = "仿真候选初值：h ≤ min(1/(200 × PWM频率), 死区时间/4)，死区为0时忽略死区项；按每PWM周期偶数步向下对齐，使PWM和控制周期均为整数步；闭环稳定不代表转矩、电流纹波已收敛，定量比较前须做步长减半验证";
    }
    // The delivered weakening PI reads pre-weakening current requests.
    // Use its proportional branch as a local static inverse-voltage map;
    // do not recommend integral accumulation without voltage feedback.
    const fwKpPath = "FieldWeakening.VoltageLoopKp_AperUnit";
    const fwKiPath = "FieldWeakening.VoltageLoopKi_AperUnitPerS";
    if (emptyValue(values[fwKpPath])) {
      const at = path => Number(result[path]);
      const vmax = at("Inverter.NominalDcBus_V") * at("Limits.VoltageMargin_NULL") * at("Inverter.LinearModulationUtilization_NULL") / Math.sqrt(3);
      const omega = at("FieldWeakening.EntrySpeedOverride_rpm") * (2 * Math.PI / 60) * at("Motor.PolePairs");
      const sensitivity = omega * at("Motor.Ld_H") / vmax;
      if (![vmax, omega, at("Motor.Ld_H"), sensitivity].every(value => Number.isFinite(value) && value > 0)) {
        throw new Error("推荐弱磁 Kp 需要正的进入转速、极对数、Ld 和额定 dq 电压上限；进入转速为 0 时请手动设置 Kp");
      }
      result[fwKpPath] = raw(1 / sensitivity);
      applied[fwKpPath] = "Kp = 额定 dq 电压上限 / (进入电角速度 × Ld)，近基速轻载静态估算";
    }
    if (emptyValue(values[fwKiPath])) {
      result[fwKiPath] = "0";
      applied[fwKiPath] = "现有模型采用前馈与静态比例补偿，推荐关闭积分";
    }
    // Replace any legacy initialization results with this update's startup
    // tuning before the observer schedule and phase-fit consume switch speed.
    for (const path of Object.keys(startupSources)) { result[path] = startupValues[path]; applied[path] = startupSources[path]; }
    applyStartupTiming(result, values, applied);
    applySmoTheoretical(result, values, applied);
    const switchPath = "Observer.SwitchSpeedOverride_rpm";
    if (emptyValue(values[switchPath]) || automatic.isLegacy(values[switchPath])) {
      const requiredEmf = Number(result["Observer.MinEmf_V"]);
      const currentSpeed = Number(result[switchPath]);
      if (startupObservableEmf(result, currentSpeed) < requiredEmf * (1-1e-8)) {
        const upperSpeed = Math.min(Number(result["Observer.DesignMechSpeed_rpm"]),
          0.8*Math.PI*hz / Number(result["Motor.PolePairs"]) * 60/(2*Math.PI));
        // Locate the first crossing, without assuming the sampled observer's
        // gain is monotone over its whole frequency range.
        let lo = currentSpeed, hi = NaN;
        for (let i=1; i<=128; i++) {
          const candidate = currentSpeed + (upperSpeed-currentSpeed)*i/128;
          if (candidate>currentSpeed && startupObservableEmf(result,candidate)>=requiredEmf) { hi=candidate; break; }
          lo=candidate;
        }
        if (!Number.isFinite(hi) || startupSearch.iteration>=8)
          throw new Error("当前SMO增益、误差边界与电压误差预算无法在无感设计转速内满足接管可观测性；请联合调整后验证");
        for (let i=0; i<48; i++) {
          const mid=(lo+hi)/2;
          if (startupObservableEmf(result,mid)<requiredEmf) lo=mid; else hi=mid;
        }
        // Recompute dependent acceleration, PLL, scheduling and timeout from
        // original explicit inputs. This is one user update, not a new click.
        return recommend(values,targets,{minimum:hi,iteration:startupSearch.iteration+1});
      }
    }
    return {values: result, sources: applied, filledCount};
  }

  function update(values, {sources = {}, origins = {}, targets = {}} = {}) {
    const state = normalizeState(values, sources, origins), seed = empty();
    // Recalculate from explicit inputs and imported motor facts, so an old
    // recommendation cannot become an input to the next recommendation.
    for (const field of fields) if (["manual", "motor"].includes(state.origins[field.path])) seed[field.path] = values[field.path];
    for (const field of fields) if (field.canResolveAuto && state.origins[field.path] === "automatic" && state.sources[field.path] === automatic.source) seed[field.path] = "auto";
    const dividerField = byPath.get("Timing.MDTMTaskDivider_NULL");
    const preserveLegacyDivider = state.origins[dividerField.path] === "automatic" &&
      !emptyValue(values[dividerField.path]) && Number(values[dividerField.path]) !== dividerField.defaultValue;
    if (preserveLegacyDivider) seed[dividerField.path] = values[dividerField.path];
    const derivedInputs = {};
    for (const [feature, owner] of [["Features.ActiveInverterCompensationEnable", "Inverter.ActiveNonlinearityCompensationEnable"], ["Features.SensoredFieldWeakeningEnable", "FieldWeakening.Enable"]]) {
      if (state.origins[feature] === "manual" && state.origins[owner] !== "manual") {
        seed[owner] = values[feature];
        derivedInputs[owner] = "跟随手动设置的功能开关";
      }
    }
    if (state.origins["Execution.WorkMode_enum"] === "manual" && Number(values["Execution.WorkMode_enum"]) === 6 && state.origins["Execution.ObserverBuildVariant"] !== "manual") {
      seed["Execution.ObserverBuildVariant"] = "1";
      derivedInputs["Execution.ObserverBuildVariant"] = "无感工作模式需要 SMO 构建";
    }
    const recommended = recommend(seed, targets);
    const nextSources = {...state.sources, ...derivedInputs, ...recommended.sources};
    const nextOrigins = Object.fromEntries(fields.map(field => [field.path, isVersion(field) ? "manual" : state.origins[field.path] === "manual" || state.origins[field.path] === "motor" ? state.origins[field.path] : "automatic"]));
    if (preserveLegacyDivider) {
      nextSources[dividerField.path] = "保留旧方案值";
      nextOrigins[dividerField.path] = "manual";
    }
    const automaticFields = fields.filter(field => !field.readOnly && nextOrigins[field.path] !== "manual");
    return {
      values: recommended.values, sources: nextSources, origins: nextOrigins,
      updatedCount: automaticFields.length,
      changedCount: automaticFields.filter(field => values[field.path] !== recommended.values[field.path]).length,
      manualCount: fields.filter(field => nextOrigins[field.path] === "manual").length
    };
  }

  function importMotor(values, profile, resolved, name, sourceName = `方案：${name}`, origins = {}) {
    if (resolved.invalidInputs.length || resolved.conflicts.length) throw new Error("电机方案存在冲突或无效输入，请先在电机计算器中处理");
    const result = {...values}, applied = {};
    const map = {polePairs: "Motor.PolePairs", rPhase: "Motor.StatorResistance_Ohm", psiFlux: "Motor.PmFlux_Wb", inertia: "Motor.Inertia_kgm2", viscousFriction: "Motor.ViscousFriction_Nms", maxSpeedRpm: "Motor.MaxMechSpeed_rpm", vBus: "Inverter.NominalDcBus_V"};
    const put = (path, value, description) => { if (Number.isFinite(value) || typeof value === "string") { result[path] = raw(value); applied[path] = `电机参数导入：${sourceName}${description ? `；${description}` : ""}`; } };
    put("Meta.ProfileName", name, "方案名称");
    put("Meta.MotorClass", resolved.topology === "ipm" ? "IPMSM" : "SPMSM", "转子结构");
    for (const [from, to] of Object.entries(map)) put(to, resolved.values[from]);
    // Rated test commands follow the imported motor; explicit commands win.
    if (metadataAt(origins, "Execution.TargetSpeed_rpm") !== "manual" &&
        Number.isFinite(resolved.values.speedRpm) && resolved.values.speedRpm > 0) {
      put("Execution.TargetSpeed_rpm", resolved.values.speedRpm, "默认测试转速跟随电机额定转速");
    }
    if (metadataAt(origins, "Execution.TargetTorque_Nm") !== "manual" &&
        Number.isFinite(resolved.values.ratedTorque) && resolved.values.ratedTorque > 0) {
      put("Execution.TargetTorque_Nm", resolved.values.ratedTorque, "默认测试转矩跟随电机额定转矩");
    }
    put("Motor.Ld_H", resolved.values.ld * 1e-3, "相电感 mH → H");
    put("Motor.Lq_H", resolved.values.lq * 1e-3, "相电感 mH → H");
    put("Motor.RatedCurrent_A", resolved.values.iPhase * Math.SQRT2, "绕组相电流 RMS × √2 → 相电流峰值");
    if (Number.isFinite(resolved.values.maxPhasePeak)) {
      put("Motor.MaxCurrent_A", resolved.values.maxPhasePeak, "电机方案直接给定的最大相电流峰值");
    } else {
      put("Motor.MaxCurrent_A", resolved.values.maxTorque / resolved.values.ktIqPeak, "最大转矩 / dq 峰值电流转矩系数");
    }
    return {values: result, sources: applied, origins: Object.fromEntries(Object.keys(applied).map(path => [path, "motor"])), filledCount: Object.keys(applied).length};
  }

  function exportDocument(values, sources = {}, origins = {}, targets = {}, options = {}) {
    const checked = validate(values, options);
    if (!checked.ok) throw new Error(`${checked.issues.length} 项参数未通过校验：${checked.issues[0].path} ${checked.issues[0].message}`);
    const state = normalizeState(values, sources, origins);
    return {schemaVersion: 1, kind: "YMBOXConfiguration", model: schema.model, fieldCount: fields.length, drive: checked.drive, parameterSources: state.sources, parameterOrigins: state.origins, recommendationTargets: clone(targets)};
  }
  function readDocumentValues(document) {
    if (document.drive && (document.schemaVersion !== 1 || document.kind !== "YMBOXConfiguration")) throw new Error("配置文件版本或类型不受支持");
    const drive = document.drive || document;
    const values = flatten(drive);
    if (!Object.hasOwn(drive, "PlatformMath")) {
      for (const field of fields.filter(field => field.path.startsWith("PlatformMath."))) values[field.path] = raw(field.defaultValue);
    }
    for (const key of ["VoltageMode_enum", "ElectricalAngleCompEnable"]) {
      if (drive.Feedforward && !Object.hasOwn(drive.Feedforward, key)) values[`Feedforward.${key}`] = raw(byPath.get(`Feedforward.${key}`).defaultValue);
    }
    return values;
  }
  function importDocument(document) {
    return restoreAutoValues(readDocumentValues(document));
  }
  function importState(document, fallback = "配置文件：导入设置") {
    let values = readDocumentValues(document);
    const sources = Object.fromEntries(fields.map(field => [field.path, metadataAt(document.parameterSources, field.path) || fallback]));
    if (!Object.hasOwn(document.drive || document, "PlatformMath")) {
      for (const field of fields.filter(field => field.path.startsWith("PlatformMath."))) sources[field.path] = "新增数学实现默认值";
    }
    for (const key of ["VoltageMode_enum", "ElectricalAngleCompEnable"]) {
      const feedforward = (document.drive || document).Feedforward;
      if (feedforward && !Object.hasOwn(feedforward, key)) sources[`Feedforward.${key}`] = "新增前馈开关 · 保持原配置行为";
    }
    values = restoreVersionDefaults(values, sources, document.parameterOrigins);
    const targets = Object.fromEntries(["currentBandwidthHz", "speedBandwidthHz", "phaseMarginDeg", "positionPllAngleErrorDeg", "positionPllSpeedLagRads", "positionPllUseSpeedRamp"].filter(key => document.recommendationTargets?.[key] !== undefined).map(key => [key, document.recommendationTargets[key]]));
    const state = normalizeState(values, sources, document.parameterOrigins);
    return {values: restoreAutoValues(values), ...state, targets};
  }
  function toMathCmake(document) {
    const checked = validate(importDocument(document));
    if (!checked.ok) throw new Error("请先完成配置校验，再导出板级数学配置");
    const math = checked.drive.PlatformMath;
    return `# Generated by YMBOX configuration tool.\n# Include Platform/SharedMath/ymbox_math_backend.cmake first.\n# Then include this file and call ymbox_link_selected_math(your_firmware_target).\n# Reconfigure and rebuild the board firmware after changing selections.\nfunction(ymbox_link_selected_math target)\n    ymbox_link_shared_math(\${target}\n        CONTROL_ANGLE_COUNTS ${checked.drive.PositionSensor.ControlAngleCounts}\n        SINCOS ${math.SinCosBackend}\n        ATAN ${math.AtanBackend}\n        SQRT ${math.SqrtBackend})\nendfunction()\n`;
  }
  return Object.freeze({schema, fields, recalculationRevision, empty, flatten, recommend, update, normalizeState, restoreVersionDefaults, restoreAutoValues, recommendControlFrequency, controlSamplesPerElectricalCycle, smoDiscreteCheck, smoPhaseFit, isVersion, importMotor, validate, exportDocument, importDocument, importState, toMathCmake, raw, clone});
});
