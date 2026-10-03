function cfg = YMBOX_Drive_Parameters()
%YMBOX_DRIVE_PARAMETERS Define the editable application-layer drive profile.
%   This function is the single source of truth for the production control
%   path.  Values are grouped by ownership; sample-time-dependent equations
%   belong in YMBOX_Drive_CalculateParams.
%
%   This catalog supplies the calculator defaults and MATLAB data types.
%   Runtime settings come from the complete calculator configuration.
%   An absent calculator file must not select this catalog as a fallback.

cfg.Meta.ProfileName = 'CRD300DA_YMBOX_SPMSM';
% User-maintained revision labels, independent of the configuration format.
cfg.Meta.ProfileVersion = 1.0;
cfg.Meta.SchemaVersion = 1.0;
cfg.Meta.MotorClass = 'SPMSM';
cfg.Meta.ControlAngleConvention = 'electrical_positive_q';
cfg.Meta.Description = ...
    'Unified SPMSM/IPMSM control profile with motor-current allocation';

% Application timing.  YMBOX_Timing_Resolve is the only authority that
% converts a requested frequency into the integer-tick period used by the
% controller, simulation shell, and generated-code shell.
cfg.Timing = YMBOX_Timing_Parameters();

% Motor nameplate and physical values.
cfg.Motor.PolePairs = 5;
% Phase resistance at the selected operating condition; used directly.
cfg.Motor.StatorResistance_Ohm = 0.007;
cfg.Motor.Ld_H = 31.5e-6;
cfg.Motor.Lq_H = 31.5e-6;
cfg.Motor.PmFlux_Wb = 0.0144;
cfg.Motor.RatedCurrent_A = 100;
cfg.Motor.MaxCurrent_A = 200;
cfg.Motor.MaxMechSpeed_rpm = 6300/cfg.Motor.PolePairs*60/(2*pi);
cfg.Motor.Inertia_kgm2 = 0.00148;
cfg.Motor.ViscousFriction_Nms = 0;
cfg.Motor.LoadTorque_Nm = 0;

% Motor-current reference allocation.  The speed PI remains in the
% equivalent PM-torque current domain.  An IPMSM profile uses an offline
% generated MTPA table only in closed-loop torque-producing modes.
mode = YMBOX_DriveModeDefinitions();
cfg.CurrentReference.MtpaTableSize = 65;
cfg.CurrentReference.MinimumIpmsmSaliencyRatio_NULL = 0.10;
cfg.CurrentReference.AllocationModes_enum = uint16([ ...
    mode.SensoredSpeedLoop ...
    mode.TorqueControl ...
    mode.SmoClosedLoopInternal]);
clear mode;

% Inverter, PWM, and nonlinear voltage model.
cfg.Inverter.NominalDcBus_V = 48;
cfg.Inverter.MinValidDcBus_V = 12;
cfg.Inverter.MaxDcBus_V = 350;
cfg.Inverter.PwmFrequencyOverride_Hz = NaN;
% This is the single editable dead-time value for both the switching plant
% and the controller-side inverter-voltage model.
cfg.Inverter.DeadTime_s = 250e-9;
cfg.Inverter.MaximumDeadTimeDuty_NULL = 0.10;
cfg.Inverter.HighSideVoltageDrop_V = 0;
cfg.Inverter.LowSideVoltageDrop_V = 0;
cfg.Inverter.DeadTimePolarity = 1;
cfg.Inverter.PassiveVoltageReconstructionEnable = true;
cfg.Inverter.ActiveNonlinearityCompensationEnable = false;
cfg.Inverter.NonlinearityCompensationGain = 1;
cfg.Inverter.NonlinearityCompensationMax_V = cfg.Inverter.NominalDcBus_V/20;
cfg.Inverter.CurrentSignBoundaryMin_A = 0.5;
cfg.Inverter.CurrentSignNoiseMultiplier = 4;
cfg.Inverter.CurrentSignHold_s = 1.0e-3;
cfg.Inverter.VoltageErrorBudget_V = 1.0;
cfg.Inverter.CurrentSlew_Aps = 2.0e5;
cfg.Inverter.SamplingDelay_s = 0;
cfg.Inverter.MinDuty_NULL = 0.02;
cfg.Inverter.MaxDuty_NULL = 0.98;
cfg.Inverter.LinearModulationUtilization_NULL = 0.95;

% Switching-plant simulation resolution.  The requested dead time is
% quantized upward to this step so that the simulated interlock is never
% shorter than cfg.Inverter.DeadTime_s.
cfg.Simulation.PowerStageStep_s = 1.0e-6;

% Product build and simulation commands. Runtime board commands still enter
% through the published Command bus; these values configure the MIL shell.
cfg.Execution.ObserverBuildVariant = uint8(1);
cfg.Execution.WorkMode_enum = uint16(6);
cfg.Execution.Enable = true;
cfg.Execution.TargetSpeed_rpm = 1000;
cfg.Execution.TargetTorque_Nm = 1.5 * double(cfg.Motor.PolePairs) * ...
    cfg.Motor.PmFlux_Wb * cfg.Motor.RatedCurrent_A;
cfg.Execution.TestD = 0;
cfg.Execution.TestQ = 0;
cfg.Execution.StopTime_s = 10;

% NaN keeps voltage thresholds tied to the selected inverter. Explicit
% thresholds are optional; qualification times are converted to counts.
cfg.Protection.DcBusOverVoltage_V = NaN;
cfg.Protection.DcBusUnderVoltage_V = NaN;
cfg.Protection.VoltageViolationArea_Vs = NaN;
cfg.Protection.VoltageRecoveryRate_V = 1;
cfg.Protection.FaultClearHold_s = 0.5;
cfg.Protection.CommandTimeout_s = 0.1;
cfg.Feedforward.VoltageMode_enum = uint8(0); % 0 off, 1 dq, 2 d only, 3 q only
cfg.Feedforward.DAxisScale_NULL = 1;
cfg.Feedforward.QAxisScale_NULL = 1;
cfg.Feedforward.ElectricalAngleCompEnable = true;
cfg.Feedforward.ElectricalAngleCompScale_NULL = 1;

% Current measurement chain.
cfg.CurrentSensor.NoiseStd_A = 0.25;
cfg.CurrentSensor.SampleDelay_s = 0;

% DC-bus measurement contract. The board adapter always publishes raw
% engineering-unit signals. Application-layer conditioning and source
% selection remain configurable here so a new board does not have to
% reproduce controller-specific filtering in its driver.
%
% These are direct discrete first-order filter coefficients for
% y[k] = y[k-1] + Alpha*(x[k] - y[k-1]). Keeping the released Alpha values
% explicit avoids evaluating expf() in every control step. At the default
% 4-kHz control rate, 0.5 and 0.03 correspond to approximately 441 Hz and
% 19.4 Hz respectively. Keep the source values single so the configuration,
% published calibration, model arithmetic, and generated code share one
% floating-point contract. Re-tune them if the realized control rate changes.
cfg.DcBusMeasurement.VoltageControlFilterAlpha_NULL = single(0.5);
cfg.DcBusMeasurement.VoltageReportFilterAlpha_NULL = single(0.03);
cfg.DcBusMeasurement.VoltageReportFilterEnable = true;
% Zero volts remains a plausible physical measurement. The voltage filter
% states are initialized only after the bus reaches Inverter.MinValidDcBus_V;
% after initialization they continue tracking the full plausible range down
% to zero instead of freezing at the operating-voltage threshold.
cfg.DcBusMeasurement.VoltagePlausibleMin_V = single(0);
cfg.DcBusMeasurement.VoltagePlausibleMaxFactor_NULL = single(1.2);
% Compile-time window for the MDSP physical DC-bus-current compatibility
% output. N=4 at 4 kHz spans 1 ms and has 0.375 ms group delay. Changing N
% changes filter state size and therefore requires model update/code rebuild;
% the unfiltered Raw path remains authoritative for hard-fault protection.
cfg.DcBusMeasurement.CurrentInputMovingAverageWindowSamples = single(4);
% 0 = physical DC-bus current sensor, 1 = FOC duty/current estimate.
cfg.DcBusMeasurement.CurrentSource_enum = uint8(1);
cfg.DcBusMeasurement.CurrentPlausibleMax_A = 300;
cfg.DcBusMeasurement.CurrentHardMax_A = 220;
cfg.DcBusMeasurement.CurrentHardMin_A = -220;

% Generic position/speed source contract.  The legacy resolver adapter
% converts this native representation to the selected 4096/8192-count angle.
cfg.PositionSensor.NativeCountsPerMechanicalRev = 4096;
cfg.PositionSensor.ControlAngleCounts = 4096;
cfg.PositionSensor.Direction = 1;
cfg.PositionSensor.PllBandwidth_rads = 1200;

% Board-build math services. Normal simulation keeps the portable GENERIC
% implementations; Platform/SharedMath/ymbox_math_backend.cmake consumes these
% selections from the activated/exported configuration at target build time.
cfg.PlatformMath.SinCosBackend = 'LUT';
cfg.PlatformMath.AtanBackend = 'LUT';
cfg.PlatformMath.SqrtBackend = 'GENERIC';

% Direct manual PI calibrations.  Runtime initialization does not synthesize
% controller gains from motor data or target bandwidths.
cfg.ControlTargets.CurrentLoopKpD_VperA = 0.05938;
cfg.ControlTargets.CurrentLoopKpQ_VperA = 0.05938;
cfg.ControlTargets.CurrentLoopKiSeriesD_perS = 222.2;
cfg.ControlTargets.CurrentLoopKiSeriesQ_perS = 222.2;
cfg.ControlTargets.CurrentLoopKc_perS = 2500;
cfg.ControlTargets.SpeedLoopKp_AperRpm = 0.04377;
cfg.ControlTargets.SpeedLoopKiSeriesPerStep_NULL = 0.002483;
cfg.ControlTargets.SpeedLoopKcSeriesPerStep_NULL = 0.002483;
cfg.ControlTargets.SpeedCommandSlew_rpms = 800;

% Central limits and priority policy.
cfg.Limits.CurrentCommandMax_A = cfg.Motor.MaxCurrent_A;
cfg.Limits.SoftwareOverCurrent_A = 220;
cfg.Limits.SoftwareOverCurrentConfirm_s = 0.75e-3;
cfg.Limits.VoltageMargin_NULL = 0.92;
cfg.Limits.TorquePriorityBelowBaseSpeed = true;
cfg.Limits.DAxisPriorityInFieldWeakening = true;
cfg.Limits.SpeedCommandAbsMax_rpm = cfg.Motor.MaxMechSpeed_rpm;
cfg.Limits.DemagnetizationCurrentMin_A = -80;

% Manual eSMO results calculated in Notion for the current 4-kHz,
% 48-V, 850--3000-rpm SPMSM example. No new tuning algorithm is executed
% here. See https://app.notion.com/p/3d277ff23ca5811dbd95c85635a686e5
% The existing initialization maps/discretizes these finite settings.
% Recalculate for another motor, control rate, sensing chain or envelope.
cfg.Observer.EffectiveResistanceScale = 1;
cfg.Observer.EffectiveInductance_H = 31.5e-6;
cfg.Observer.ResistanceUncertaintyFraction = 0.20;
cfg.Observer.InductanceUncertaintyFraction = 0.25;
cfg.Observer.DesignMechSpeed_rpm = 3000;
cfg.Observer.SlideGainMargin = 1.3;
cfg.Observer.SlideGainOverride_V = 33;
cfg.Observer.ErrBoundaryRatedFraction = 0.05;
% This is an observer current-error boundary, not the motor current limit.
cfg.Observer.ErrBoundaryOverride_A = 363.38534918575056;
cfg.Observer.AdaptiveInjectionEnable = false;
cfg.Observer.SlideGainMinOverride_V = 33;
cfg.Observer.SlideGainMaxOverride_V = 33;
cfg.Observer.ErrBoundaryMinOverride_A = 363.38534918575056;
cfg.Observer.ErrBoundaryMaxOverride_A = 363.38534918575056;
% Compatibility schedule inputs: K/phi spans and phase scheduling are zero.
cfg.Observer.GainScheduleEmfLowOverride_V = 2;
cfg.Observer.GainScheduleEmfHighOverride_V = 18;
cfg.Observer.GainScheduleTimeConstant_s = 0.020;
cfg.Observer.GainScheduleAngleComp_rad = 0;
cfg.Observer.EmfLpfPole_rads = 6441.095796041728;
cfg.Observer.PllBandwidth_rads = 200;
cfg.Observer.PllDamping = 0.707;
cfg.Observer.MinEmf_V = 3.7;
cfg.Observer.EmfObservabilityMargin = 1.1;
cfg.Observer.MinSwitchSpeed_rpm = 850;
cfg.Observer.SwitchSpeedOverride_rpm = 850;
cfg.Observer.ReadySpeedErrorFraction = 0.16666666666666666;
cfg.Observer.ReadySpeedErrorOverride_rads = 52.35987755982989;
cfg.Observer.ReadyPllError = 0.5;
cfg.Observer.StaticAngleOffset_rad = 0;
% Effective analytic phase-fit coefficient for the present sampled model;
% not an identified hardware transport delay. External sampling delays
% remain separately owned by Inverter and CurrentSensor.
cfg.Observer.TotalDelay_s = 0.00006239110456059612;
cfg.Observer.MaxElecSpeedOverride_rads = 6300;

% I/F startup, qualification, handover, and loss supervision.
cfg.StartupSupervisor.IfAccel_rpms = 800;
cfg.StartupSupervisor.IfAccelBlendTime_s = 0.12;
cfg.StartupSupervisor.IfAlignTime_s = 0.10;
cfg.StartupSupervisor.IfBlendTime_s = 0.10;
cfg.StartupSupervisor.IfSwitchSpeed_rpm = 850;
cfg.StartupSupervisor.DirectHandoverTime_s = 0.10;
cfg.StartupSupervisor.SmoReadyConfirmTime_s = 0.10;
cfg.StartupSupervisor.ObserverExitRatio = 0.75;
cfg.StartupSupervisor.ObserverLossConfirmTime_s = 0.020;
cfg.StartupSupervisor.DirectHandoverDwellTime_s = 0.100;
cfg.StartupSupervisor.StartupTimeoutMargin_s = 0.50;
cfg.StartupSupervisor.StartupTimeoutOverride_s = 6.0;
cfg.StartupSupervisor.IfStartIqOverride_A = 5;
cfg.StartupSupervisor.IfAlignIdOverride_A = 15;
cfg.StartupSupervisor.IfIqSlewOverride_Aps = 200;
cfg.StartupSupervisor.DirectAccelIqSeedOverride_A = 1.1480387968673813;
% Compatibility input uses the fast period, but MDTM filters at the slow
% period. With divider 10, this 5-ms input yields 50-ms actual filtering.
% See the Notion tuning page for the execution-period conversion.
cfg.StartupSupervisor.HandoverCurrentLpfTau_s = 0.005;

% Sensored SPMSM field weakening.  Sensorless field weakening is a separate
% release gate because the back-EMF observer has not yet been bench-qualified
% above base speed.
cfg.FieldWeakening.Enable = true;
cfg.FieldWeakening.SensorlessEnable = false;
cfg.FieldWeakening.EntryUtilization_NULL = 0.93;
cfg.FieldWeakening.ExitUtilization_NULL = 0.88;
cfg.FieldWeakening.EntrySpeedOverride_rpm = NaN;
cfg.FieldWeakening.IdMin_A = -80;
cfg.FieldWeakening.VoltageLoopKp_AperUnit = 25;
cfg.FieldWeakening.VoltageLoopKi_AperUnitPerS = 500;
cfg.FieldWeakening.IdSlew_Aps = 800;

% Independent rollback switches.  A disabled feature must reproduce the
% previously validated route without changing port types or task timing.
cfg.Features.UnifiedConstraintManagerEnable = true;
cfg.Features.FinalIqAntiWindupEnable = true;
cfg.Features.ActiveInverterCompensationEnable = ...
    cfg.Inverter.ActiveNonlinearityCompensationEnable;
cfg.Features.SensoredFieldWeakeningEnable = cfg.FieldWeakening.Enable;
cfg.Features.SensorlessFieldWeakeningEnable = ...
    cfg.FieldWeakening.SensorlessEnable;
end
