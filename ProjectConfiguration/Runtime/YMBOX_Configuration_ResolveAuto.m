function [cfg, resolvedPaths] = YMBOX_Configuration_ResolveAuto(cfg, options)
%YMBOX_CONFIGURATION_RESOLVEAUTO Materialize existing model automatic values.

arguments
    cfg (1,1) struct
    options.AllowUnreleasedControlFrequency (1,1) logical = false
end

resolvedPaths = cell(0,1);
[cfg, resolvedPaths] = put(cfg, resolvedPaths, ...
    'Timing.InputTaskFrequencyOverride_Hz', cfg.Timing.ControlFrequency_Hz);
[cfg, resolvedPaths] = put(cfg, resolvedPaths, ...
    'Inverter.PwmFrequencyOverride_Hz', cfg.Timing.ControlFrequency_Hz);

% Match MDFM's published single and preserve the explicit configuration bound.
% Single rounding may exceed a double limit by less than one ULP (311 V bus).
[cfg, resolvedPaths] = put(cfg, resolvedPaths, ...
    'Protection.DcBusOverVoltage_V', min(cfg.Inverter.MaxDcBus_V, ...
    double(single(min(cfg.Inverter.MaxDcBus_V, ...
    1.2*cfg.Inverter.NominalDcBus_V)))));
[cfg, resolvedPaths] = put(cfg, resolvedPaths, ...
    'Protection.DcBusUnderVoltage_V', double(single(0.5*cfg.Inverter.NominalDcBus_V)));
[cfg, resolvedPaths] = put(cfg, resolvedPaths, ...
    'Protection.VoltageViolationArea_Vs', double(single( ...
    5e-4*double(single(cfg.Protection.DcBusOverVoltage_V)))));

% Reuse the model's existing calculations and preserve every finite override.
prm = YMBOX_Drive_CalculateParams(cfg, ...
    1/cfg.Timing.ControlFrequency_Hz, ...
    AllowUnreleasedControlFrequency= ...
    options.AllowUnreleasedControlFrequency);
mapping = {
    'Observer.EffectiveInductance_H', 'ModelInductance_H';
    'Observer.SlideGainOverride_V', 'SlideGain_V';
    'Observer.ErrBoundaryOverride_A', 'ErrBoundary_A';
    'Observer.SlideGainMinOverride_V', 'SlideGainMin_V';
    'Observer.SlideGainMaxOverride_V', 'SlideGainMax_V';
    'Observer.ErrBoundaryMinOverride_A', 'ErrBoundaryMin_A';
    'Observer.ErrBoundaryMaxOverride_A', 'ErrBoundaryMax_A';
    'Observer.GainScheduleEmfLowOverride_V', 'GainScheduleEmfLow_V';
    'Observer.GainScheduleEmfHighOverride_V', 'GainScheduleEmfHigh_V';
    'Observer.SwitchSpeedOverride_rpm', 'SwitchSpeed_rpm';
    'Observer.ReadySpeedErrorOverride_rads', 'ReadySpeedError_rads';
    'Observer.MaxElecSpeedOverride_rads', 'MaxElecSpeed_rads';
    'StartupSupervisor.StartupTimeoutOverride_s', 'StartupTimeout_s';
    'StartupSupervisor.IfStartIqOverride_A', 'IfStartIq_A';
    'StartupSupervisor.IfAlignIdOverride_A', 'IfAlignId_A';
    'StartupSupervisor.IfIqSlewOverride_Aps', 'IfIqSlew_Aps';
    'StartupSupervisor.DirectAccelIqSeedOverride_A', 'DirectAccelIqSeed_A'};
for index = 1:size(mapping,1)
    [cfg, resolvedPaths] = put(cfg, resolvedPaths, ...
        mapping{index,1}, prm.Observer.(mapping{index,2}));
end
[cfg, resolvedPaths] = put(cfg, resolvedPaths, ...
    'FieldWeakening.EntrySpeedOverride_rpm', prm.FieldWeakening.EntrySpeed_rpm);
end

function [cfg, paths] = put(cfg, paths, path, value)
parts = strsplit(path, '.');
if isnan(cfg.(parts{1}).(parts{2}))
    assert(isfinite(value), 'YMBOX:Configuration:UnresolvedAuto', ...
        'Cannot resolve a finite value for %s.', path);
    cfg.(parts{1}).(parts{2}) = value;
    paths{end+1,1} = path;
end
end
