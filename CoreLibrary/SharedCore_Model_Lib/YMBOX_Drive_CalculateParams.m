function prm = YMBOX_Drive_CalculateParams(cfg, sampleTime_s, options)
%YMBOX_DRIVE_CALCULATEPARAMS Derive control and observer calibrations.
%   PRM explicitly separates continuous gains, per-step gains, limits, and
%   compatibility values used by the current generated-code model.

arguments
    cfg (1,1) struct
    sampleTime_s (1,1) double {mustBeFinite, mustBePositive}
    options.AllowUnreleasedControlFrequency (1,1) logical = false
end

m = cfg.Motor;
inv = cfg.Inverter;
targets = cfg.ControlTargets;
limits = cfg.Limits;
fw = cfg.FieldWeakening;
currentReference = cfg.CurrentReference;
simulation = cfg.Simulation;

prm.Meta = cfg.Meta;
if isfinite(inv.PwmFrequencyOverride_Hz)
    pwmFrequency_Hz = inv.PwmFrequencyOverride_Hz;
else
    pwmFrequency_Hz = NaN;
end
prm.Timing = YMBOX_Timing_Resolve( ...
    1/sampleTime_s, cfg.Timing, pwmFrequency_Hz, ...
    AllowUnreleasedControlFrequency= ...
    options.AllowUnreleasedControlFrequency);
sampleTime_s = prm.Timing.ControlPeriod_s;
prm.SampleTime_s = sampleTime_s;
prm.PwmFrequency_Hz = prm.Timing.PwmFrequency_Hz;
prm.PwmPeriod_s = prm.Timing.PwmPeriod_s;

% Switching-plant timing.  An integer delay is required by the discrete
% gate-interlock model.  Ceil preserves the requested minimum dead time
% when the value is not an exact multiple of the plant simulation step.
requestedDeadTimeSteps = ...
    max(0, inv.DeadTime_s/simulation.PowerStageStep_s);
deadTimeStepTolerance = ...
    100*eps(max(1, requestedDeadTimeSteps));
prm.Simulation.PowerStageStep_s = simulation.PowerStageStep_s;
idealPwmPeriodSteps = prm.PwmPeriod_s/simulation.PowerStageStep_s;
nearestPwmPeriodSteps = round(idealPwmPeriodSteps);
pwmPeriodStepError = abs(idealPwmPeriodSteps-nearestPwmPeriodSteps);
prm.Simulation.PwmPeriodIdealSteps_NULL = idealPwmPeriodSteps;
prm.Simulation.PwmPeriodNearestSteps_NULL = uint32(nearestPwmPeriodSteps);
prm.Simulation.PwmPeriodExactlyRepresentable_flg = ...
    pwmPeriodStepError <= 100*eps(max(1, idealPwmPeriodSteps));
prm.Simulation.PwmPeriodNearest_s = ...
    nearestPwmPeriodSteps*simulation.PowerStageStep_s;
prm.Simulation.PwmPeriodQuantizationError_s = ...
    prm.Simulation.PwmPeriodNearest_s-prm.PwmPeriod_s;
prm.Simulation.PwmDeadTimeRequested_s = inv.DeadTime_s;
prm.Simulation.PwmDeadTimeSteps_NULL = ...
    ceil(requestedDeadTimeSteps-deadTimeStepTolerance);
prm.Simulation.PwmDeadTimeEffective_s = ...
    prm.Simulation.PwmDeadTimeSteps_NULL * ...
    prm.Simulation.PowerStageStep_s;
prm.Simulation.PwmDeadTimeQuantizationError_s = ...
    prm.Simulation.PwmDeadTimeEffective_s - ...
    prm.Simulation.PwmDeadTimeRequested_s;

% Operating motor model and torque conversion.
prm.Motor.PolePairs = m.PolePairs;
prm.Motor.Rs_Ohm = m.StatorResistance_Ohm;
prm.Motor.Ld_H = m.Ld_H;
prm.Motor.Lq_H = m.Lq_H;
prm.Motor.PmFlux_Wb = m.PmFlux_Wb;
prm.Motor.TorqueConstant_NmPerA = 1.5*m.PolePairs*m.PmFlux_Wb;
prm.Motor.TorqueToIq_AperNm = 1/prm.Motor.TorqueConstant_NmPerA;
prm.Motor.SaliencyRatio_NULL = abs(m.Lq_H-m.Ld_H) / ...
    max(0.5*(m.Ld_H+m.Lq_H), eps);
motorClass = upper(string(cfg.Meta.MotorClass));
prm.Motor.Class = char(motorClass);
prm.Motor.IsSurfacePmsm = motorClass == "SPMSM";
prm.Motor.IsInteriorPmsm = motorClass == "IPMSM";

% Motor-current reference allocation.  Tables are generated offline from
% current magnitude, so the generated controller has no iterative solver.
prm.CurrentReference = calculateCurrentReference( ...
    m, min(limits.CurrentCommandMax_A, m.MaxCurrent_A), ...
    currentReference, motorClass);

% Direct manual current PI calibrations.  The existing model implements
% Kp*(1 + Ki/s), so Ki remains the series zero in 1/s.
prm.CurrentLoop.KpD_VperA = targets.CurrentLoopKpD_VperA;
prm.CurrentLoop.KpQ_VperA = targets.CurrentLoopKpQ_VperA;
prm.CurrentLoop.KiSeriesD_perS = targets.CurrentLoopKiSeriesD_perS;
prm.CurrentLoop.KiSeriesQ_perS = targets.CurrentLoopKiSeriesQ_perS;
prm.CurrentLoop.Kc_perS = targets.CurrentLoopKc_perS;

% Direct manual speed PI calibrations in the exact units consumed by the
% discrete controller.
prm.SpeedLoop.Kp_AperRpm = targets.SpeedLoopKp_AperRpm;
prm.SpeedLoop.KiSeriesPerStep_NULL = ...
    targets.SpeedLoopKiSeriesPerStep_NULL;
prm.SpeedLoop.KcSeriesPerStep_NULL = ...
    targets.SpeedLoopKcSeriesPerStep_NULL;
prm.SpeedLoop.CommandSlewPerStep_rpm = ...
    targets.SpeedCommandSlew_rpms*sampleTime_s;

% Central constraint policy.
prm.Constraint.CurrentMax_A = min( ...
    limits.CurrentCommandMax_A, m.MaxCurrent_A);
prm.Constraint.CurrentMin_A = -prm.Constraint.CurrentMax_A;
prm.Constraint.SoftwareOverCurrent_A = ...
    limits.SoftwareOverCurrent_A;
prm.Constraint.SoftwareOverCurrentConfirmCount = uint8(min( ...
    double(intmax('uint8')), max(1, round( ...
    limits.SoftwareOverCurrentConfirm_s/sampleTime_s))));
prm.Constraint.VoltageMargin_NULL = limits.VoltageMargin_NULL;
prm.Constraint.LinearModulationUtilization_NULL = ...
    inv.LinearModulationUtilization_NULL;
prm.Constraint.VdqMaxPerDcBus_NULL = ...
    limits.VoltageMargin_NULL * ...
    inv.LinearModulationUtilization_NULL/sqrt(3);
prm.Constraint.NominalVdqMax_V = ...
    inv.NominalDcBus_V*prm.Constraint.VdqMaxPerDcBus_NULL;
prm.Constraint.TorquePriorityBelowBaseSpeed = double(logical( ...
    limits.TorquePriorityBelowBaseSpeed));
prm.Constraint.DAxisPriorityInFieldWeakening = double(logical( ...
    limits.DAxisPriorityInFieldWeakening));

% Position/speed adapter scalers.
pos = cfg.PositionSensor;
nativeCounts = double(pos.NativeCountsPerMechanicalRev);
prm.Position.NativeCountToMechRad = ...
    pos.Direction*2*pi/nativeCounts;
prm.Position.NativeCountsPerMechanicalRev = nativeCounts;
prm.Position.NativePositionBits = log2(nativeCounts);
prm.Position.NativeHalfCount = nativeCounts/2;
prm.Position.ControlCountToElecRad = ...
    2*pi/pos.ControlAngleCounts;
prm.Position.ElecRadToControlCount = ...
    pos.ControlAngleCounts/(2*pi);
prm.Position.ControlAngleCounts = pos.ControlAngleCounts;
prm.Position.NativeToControlCount = ...
    pos.ControlAngleCounts/nativeCounts;
prm.Position.SignedNativeToControlCount = ...
    pos.Direction*prm.Position.NativeToControlCount;
prm.Position.PllBandwidth_rads = pos.PllBandwidth_rads;

% Inverter nonlinear voltage model.  The applied phase-error sign is held
% through the zero-current boundary in the model implementation.
prm.Inverter.MaximumDeadTimeDuty_NULL = ...
    inv.MaximumDeadTimeDuty_NULL;
prm.Inverter.DeadTimeDutyFraction = min( ...
    prm.Inverter.MaximumDeadTimeDuty_NULL, max(0, ...
    inv.DeadTime_s*prm.PwmFrequency_Hz));
prm.Inverter.CurrentSignBoundary_A = max( ...
    inv.CurrentSignBoundaryMin_A, ...
    inv.CurrentSignNoiseMultiplier*cfg.CurrentSensor.NoiseStd_A);
prm.Inverter.CurrentSignHoldCount = uint16(min( ...
    double(intmax('uint16')), max(1, round( ...
    inv.CurrentSignHold_s/sampleTime_s))));
prm.Inverter.AverageDeviceDrop_V = 0.5*( ...
    inv.HighSideVoltageDrop_V+inv.LowSideVoltageDrop_V);
prm.Inverter.NominalPhaseError_V = ...
    inv.NominalDcBus_V*prm.Inverter.DeadTimeDutyFraction + ...
    prm.Inverter.AverageDeviceDrop_V;
prm.Inverter.CompensationGain = inv.NonlinearityCompensationGain;
prm.Inverter.CompensationMax_V = ...
    inv.NonlinearityCompensationMax_V;
prm.Inverter.ActiveCompensationEnable = double(logical( ...
    cfg.Features.ActiveInverterCompensationEnable));
prm.Inverter.PassiveReconstructionEnable = double(logical( ...
    inv.PassiveVoltageReconstructionEnable));
prm.Inverter.DeadTimePolarity = sign(inv.DeadTimePolarity);
if prm.Inverter.DeadTimePolarity == 0
    prm.Inverter.DeadTimePolarity = 1;
end

% Sensored PMSM weak-field design.  For IPMSM, MTPA Id is the below-base
% request and this manager can add further negative Id above base speed.
nominalBaseElec_rads = ...
    prm.Constraint.NominalVdqMax_V/max(m.PmFlux_Wb, eps);
prm.FieldWeakening.NominalBaseSpeed_rpm = ...
    nominalBaseElec_rads/m.PolePairs*60/(2*pi);
if isfinite(fw.EntrySpeedOverride_rpm)
    prm.FieldWeakening.EntrySpeed_rpm = fw.EntrySpeedOverride_rpm;
else
    prm.FieldWeakening.EntrySpeed_rpm = ...
        0.98*prm.FieldWeakening.NominalBaseSpeed_rpm;
end
prm.FieldWeakening.Enable = double(logical( ...
    cfg.Features.SensoredFieldWeakeningEnable));
prm.FieldWeakening.SensorlessEnable = double(logical( ...
    cfg.Features.SensorlessFieldWeakeningEnable));
prm.FieldWeakening.EntryUtilization_NULL = ...
    fw.EntryUtilization_NULL;
prm.FieldWeakening.ExitUtilization_NULL = ...
    fw.ExitUtilization_NULL;
prm.FieldWeakening.IdMin_A = max( ...
    fw.IdMin_A, limits.DemagnetizationCurrentMin_A);
prm.FieldWeakening.Kp_AperUnit = fw.VoltageLoopKp_AperUnit;
prm.FieldWeakening.KiTs_AperUnit = ...
    fw.VoltageLoopKi_AperUnitPerS*sampleTime_s;
prm.FieldWeakening.IdSlewPerStep_A = ...
    fw.IdSlew_Aps*sampleTime_s;

prm.Features = cfg.Features;

% Existing eSMO consumers receive the same flat derived structure.
legacyCfg = YMBOX_Drive_ToLegacySmoConfig(cfg);
prm.Observer = YMBOX_SMO_CalculateParams(legacyCfg, sampleTime_s);

prm.Trace.CurrentPI = ...
    'Manual KpD/KpQ, KiSeriesD/KiSeriesQ and Kc calibrations';
prm.Trace.SpeedPI = ...
    'Manual Kp, KiStep and KcStep calibrations with rpm feedback';
prm.Trace.MotorCurrentReference = ...
    ['Treq=KtPM*IqLegacy; IPMSM uses offline MTPA LUT; ' ...
    'SPMSM and modes 3/16 are direct pass-through'];
prm.Trace.CurrentCircle = ...
    'IqMax=sqrt(max(Imax^2-Id^2,0))';
prm.Trace.VoltageCircle = ...
    'VdqMax=Vdc*margin*linearUtilization/sqrt(3)';
prm.Trace.FieldWeakening = ...
    'Id=min(0,(VqAvailable/abs(we)-psiPM)/Ld)+voltagePI';
prm.Trace.InverterCompensation = ...
    'VerrPhase=(Vdc*Tdead*Fpwm+Vdrop)*heldSign(Iphase)';
end

function result = calculateCurrentReference( ...
        motor, currentMax_A, settings, motorClass)
tableSize = double(settings.MtpaTableSize);
current_A = linspace(0, currentMax_A, tableSize);
deltaL_H = motor.Lq_H-motor.Ld_H;

if motorClass == "IPMSM" && deltaL_H > 0
    id_A = (motor.PmFlux_Wb - sqrt(motor.PmFlux_Wb^2 + ...
        8*deltaL_H^2*current_A.^2))/(4*deltaL_H);
else
    id_A = zeros(size(current_A));
end
iq_A = sqrt(max(current_A.^2-id_A.^2, 0));
torque_Nm = 1.5*motor.PolePairs*(motor.PmFlux_Wb*iq_A + ...
    (motor.Ld_H-motor.Lq_H).*id_A.*iq_A);

% Make the physical endpoints exact and retain a monotonically increasing
% breakpoint vector for deterministic one-dimensional lookup.
current_A(1) = 0;
id_A(1) = 0;
iq_A(1) = 0;
torque_Nm(1) = 0;

ktPm_NmPerA = 1.5*motor.PolePairs*motor.PmFlux_Wb;
equivalentIqMax_A = torque_Nm(end)/ktPm_NmPerA;
equivalentIqBreakpoints_A = linspace( ...
    0, equivalentIqMax_A, tableSize);
torqueBreakpoints_Nm = ...
    ktPm_NmPerA*equivalentIqBreakpoints_A;
currentLookup_A = interp1( ...
    torque_Nm, current_A, torqueBreakpoints_Nm, 'linear');
idLookup_A = interp1(current_A, id_A, currentLookup_A, 'linear');
iqLookup_A = interp1(current_A, iq_A, currentLookup_A, 'linear');
currentLookup_A(1) = 0;
idLookup_A(1) = 0;
iqLookup_A(1) = 0;
currentLookup_A(end) = current_A(end);
idLookup_A(end) = id_A(end);
iqLookup_A(end) = iq_A(end);

ratedCurrent_A = min([motor.RatedCurrent_A, currentMax_A]);
baselineTorque_Nm = ktPm_NmPerA*ratedCurrent_A;
targetTorque_Nm = min(baselineTorque_Nm, torque_Nm(end));
if targetTorque_Nm > 0
    mtpaCurrentAtTarget_A = interp1( ...
        torque_Nm, current_A, targetTorque_Nm, 'linear');
    ratedReduction = max(0, ...
        1-mtpaCurrentAtTarget_A/max(ratedCurrent_A, eps));
else
    mtpaCurrentAtTarget_A = 0;
    ratedReduction = 0;
end

result.Variant = uint8(motorClass == "IPMSM");
result.Strategy = char("MTPA_1D_LUT");
result.AllocationModes_enum = uint16( ...
    settings.AllocationModes_enum(:).');
result.TableSize = uint16(tableSize);
result.EquivalentIqBreakpoints_A = equivalentIqBreakpoints_A;
result.EquivalentIqMax_A = equivalentIqMax_A;
result.TorqueBreakpoints_Nm = torqueBreakpoints_Nm;
result.IdTable_A = idLookup_A;
result.IqTable_A = iqLookup_A;
result.CurrentMagnitude_A = currentLookup_A;
result.MaximumCurrent_A = currentMax_A;
result.MaximumTorque_Nm = torque_Nm(end);
result.TorqueRequestGain_NmPerA = ktPm_NmPerA;
result.MtpaCurrentAtPmRatedTorque_A = mtpaCurrentAtTarget_A;
result.RatedTorqueCurrentReduction_NULL = ratedReduction;
end
