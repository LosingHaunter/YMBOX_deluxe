(function (global, factory) {
  if (typeof module === "object" && module.exports) module.exports = factory(require("./ymbox-config-schema.json"));
  else global.YMBOXAuto = factory(global.YMBOXSchema);
})(typeof window === "object" ? window : globalThis, function (schema) {
  "use strict";
  const source = "模型自动计算";
  const isLegacy = value => value === null || /^(auto|自动|null|nan)$/i.test(String(value).trim());

  // Mirrors YMBOX_SMO_CalculateParams, YMBOX_Drive_CalculateParams and MDFM.
  // Keep numeric settings intact; only requested legacy/default automatic
  // fields are materialized. Cross-language fixtures guard these formulas.
  function resolve(values, paths) {
    const requested = new Set(paths), cfg = JSON.parse(JSON.stringify(schema.defaults));
    for (const field of schema.fields) {
      const [group, key] = field.path.split("."), value = values[field.path];
      if (requested.has(field.path) || isLegacy(value)) cfg[group][key] = NaN;
      else if (value !== undefined && String(value).trim() !== "") {
        cfg[group][key] = field.type === "char" ? String(value) : field.type === "logical" ? [true, "true", 1, "1"].includes(value) : Number(value);
      }
    }
    const result = {};
    const put = (path, calculated) => {
      const [group, key] = path.split("."), value = cfg[group][key];
      if (requested.has(path)) {
        if (!Number.isFinite(calculated)) throw new Error(`${path} 无法计算，请先检查相关输入数值`);
        cfg[group][key] = calculated;
        result[path] = String(calculated);
      }
      return requested.has(path) ? calculated : value;
    };
    const m = cfg.Motor, inv = cfg.Inverter, o = cfg.Observer, s = cfg.StartupSupervisor;
    put("Timing.InputTaskFrequencyOverride_Hz", cfg.Timing.ControlFrequency_Hz);
    put("Inverter.PwmFrequencyOverride_Hz", cfg.Timing.ControlFrequency_Hz);
    // A rounded single can lie slightly above the explicit double-precision
    // limit (e.g. 1.2 * 311 V). Keep the exported configuration within it;
    // both values still publish to the same single in the model.
    const overVoltage = put("Protection.DcBusOverVoltage_V", Math.min(inv.MaxDcBus_V, Math.fround(Math.min(inv.MaxDcBus_V, 1.2 * inv.NominalDcBus_V))));
    put("Protection.DcBusUnderVoltage_V", Math.fround(0.5 * inv.NominalDcBus_V));
    put("Protection.VoltageViolationArea_Vs", Math.fround(5e-4 * Math.fround(overVoltage)));

    const inductance = cfg.Meta.MotorClass.toUpperCase() === "IPMSM" ? m.Ld_H : Number.isFinite(o.EffectiveInductance_H) ? o.EffectiveInductance_H : 0.5 * (m.Ld_H + m.Lq_H);
    put("Observer.EffectiveInductance_H", inductance);
    const resistance = m.StatorResistance_Ohm * o.EffectiveResistanceScale;
    const kt = 1.5 * m.PolePairs * m.PmFlux_Wb;
    put("Observer.MaxElecSpeedOverride_rads", m.MaxMechSpeed_rpm * (2 * Math.PI / 60) * m.PolePairs);
    const designEmf = o.DesignMechSpeed_rpm * (2 * Math.PI / 60) * m.PolePairs * m.PmFlux_Wb;
    const slideCalculated = o.SlideGainMargin * (designEmf + o.ResistanceUncertaintyFraction * resistance * m.MaxCurrent_A + o.InductanceUncertaintyFraction * inductance * inv.CurrentSlew_Aps + inv.VoltageErrorBudget_V);
    const slide = put("Observer.SlideGainOverride_V", slideCalculated);
    const boundaryCalculated = Math.max(inv.CurrentSignNoiseMultiplier * cfg.CurrentSensor.NoiseStd_A, o.ErrBoundaryRatedFraction * m.RatedCurrent_A, 1e-3);
    const boundary = put("Observer.ErrBoundaryOverride_A", boundaryCalculated);
    const observableSpeed = 60 / (2 * Math.PI * m.PolePairs) * (o.EmfObservabilityMargin * o.MinEmf_V / m.PmFlux_Wb);
    const switchSpeed = put("Observer.SwitchSpeedOverride_rpm", Math.max(o.MinSwitchSpeed_rpm, observableSpeed));
    const switchElecSpeed = switchSpeed * (2 * Math.PI / 60) * m.PolePairs;
    const emfLowCalculated = Math.max(o.MinEmf_V, 0.40 * switchElecSpeed * m.PmFlux_Wb);
    put("Observer.SlideGainMinOverride_V", slide);
    put("Observer.SlideGainMaxOverride_V", o.AdaptiveInjectionEnable ? Math.max(slideCalculated, slide) : slide);
    put("Observer.ErrBoundaryMinOverride_A", o.AdaptiveInjectionEnable ? Math.max(boundaryCalculated, 0.70 * boundary) : boundary);
    put("Observer.ErrBoundaryMaxOverride_A", boundary);
    put("Observer.GainScheduleEmfLowOverride_V", emfLowCalculated);
    put("Observer.GainScheduleEmfHighOverride_V", Math.max(emfLowCalculated + o.MinEmf_V, designEmf));
    put("Observer.ReadySpeedErrorOverride_rads", Math.max(1, o.ReadySpeedErrorFraction * switchElecSpeed));

    const acceleration = s.IfAccel_rpms * 2 * Math.PI / 60, switchMechSpeed = switchSpeed * 2 * Math.PI / 60;
    const seedCalculated = (m.Inertia_kgm2 * acceleration + m.ViscousFriction_Nms * switchMechSpeed + Math.abs(m.LoadTorque_Nm)) / Math.max(kt, Number.EPSILON);
    put("StartupSupervisor.DirectAccelIqSeedOverride_A", seedCalculated);
    const startIq = put("StartupSupervisor.IfStartIqOverride_A", Math.max(seedCalculated, Math.abs(m.LoadTorque_Nm) / Math.max(kt, Number.EPSILON)));
    put("StartupSupervisor.IfAlignIdOverride_A", Math.min(0.15 * m.RatedCurrent_A, m.MaxCurrent_A));
    put("StartupSupervisor.IfIqSlewOverride_Aps", 10 * startIq);
    put("StartupSupervisor.StartupTimeoutOverride_s", s.IfAlignTime_s + s.IfBlendTime_s + switchSpeed / s.IfAccel_rpms + s.SmoReadyConfirmTime_s + s.StartupTimeoutMargin_s);
    const nominalVdq = inv.NominalDcBus_V * (cfg.Limits.VoltageMargin_NULL * inv.LinearModulationUtilization_NULL / Math.sqrt(3));
    const baseSpeed = nominalVdq / Math.max(m.PmFlux_Wb, Number.EPSILON) / m.PolePairs * 60 / (2 * Math.PI);
    put("FieldWeakening.EntrySpeedOverride_rpm", 0.98 * baseSpeed);
    return result;
  }
  return Object.freeze({source, isLegacy, resolve});
});
