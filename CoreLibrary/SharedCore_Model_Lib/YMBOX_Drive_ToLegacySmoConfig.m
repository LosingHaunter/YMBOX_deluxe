function legacy = YMBOX_Drive_ToLegacySmoConfig(cfg)
%YMBOX_DRIVE_TOLEGACYSMOCONFIG Adapt the unified drive profile to eSMO API.
%   This compatibility view keeps existing observer scripts and generated
%   calibration names stable.  Editable values remain owned by
%   YMBOX_Drive_Parameters.

legacy.ProfileName = cfg.Meta.ProfileName;
legacy.MotorClass = cfg.Meta.MotorClass;
legacy.ProfileVersion = double(cfg.Meta.ProfileVersion);

legacy.MotorPhysical.PolePairs = cfg.Motor.PolePairs;
legacy.MotorPhysical.StatorResistance_Ohm = ...
    cfg.Motor.StatorResistance_Ohm;
legacy.MotorPhysical.Ld_H = cfg.Motor.Ld_H;
legacy.MotorPhysical.Lq_H = cfg.Motor.Lq_H;
legacy.MotorPhysical.PmFlux_Wb = cfg.Motor.PmFlux_Wb;
legacy.MotorPhysical.RatedCurrent_A = cfg.Motor.RatedCurrent_A;
legacy.MotorPhysical.MaxCurrent_A = cfg.Motor.MaxCurrent_A;
legacy.MotorPhysical.MaxMechSpeed_rpm = cfg.Motor.MaxMechSpeed_rpm;
legacy.MotorPhysical.Inertia_kgm2 = cfg.Motor.Inertia_kgm2;
legacy.MotorPhysical.ViscousFriction_Nms = ...
    cfg.Motor.ViscousFriction_Nms;
legacy.MotorPhysical.LoadTorque_Nm = cfg.Motor.LoadTorque_Nm;

legacy.InverterAndSensing.NominalDcBus_V = ...
    cfg.Inverter.NominalDcBus_V;
legacy.InverterAndSensing.MinValidDcBus_V = ...
    cfg.Inverter.MinValidDcBus_V;
legacy.InverterAndSensing.MaxDcBus_V = cfg.Inverter.MaxDcBus_V;
legacy.InverterAndSensing.PwmFrequencyOverride_Hz = ...
    cfg.Inverter.PwmFrequencyOverride_Hz;
legacy.InverterAndSensing.DeadTime_s = cfg.Inverter.DeadTime_s;
legacy.InverterAndSensing.DeviceVoltageDrop_V = 0.5*( ...
    cfg.Inverter.HighSideVoltageDrop_V + ...
    cfg.Inverter.LowSideVoltageDrop_V);
legacy.InverterAndSensing.DeadTimeCompEnable = ...
    cfg.Inverter.PassiveVoltageReconstructionEnable;
legacy.InverterAndSensing.DeadTimePolarity = ...
    cfg.Inverter.DeadTimePolarity;
legacy.InverterAndSensing.CurrentNoiseStd_A = ...
    cfg.CurrentSensor.NoiseStd_A;
legacy.InverterAndSensing.CurrentSignBoundaryMin_A = ...
    cfg.Inverter.CurrentSignBoundaryMin_A;
legacy.InverterAndSensing.CurrentSignNoiseMultiplier = ...
    cfg.Inverter.CurrentSignNoiseMultiplier;
legacy.InverterAndSensing.VoltageErrorBudget_V = ...
    cfg.Inverter.VoltageErrorBudget_V;
legacy.InverterAndSensing.CurrentSlew_Aps = ...
    cfg.Inverter.CurrentSlew_Aps;
legacy.InverterAndSensing.SamplingDelay_s = ...
    cfg.Inverter.SamplingDelay_s + cfg.CurrentSensor.SampleDelay_s;

legacy.SmoIdentified = cfg.Observer;
legacy.Supervisor = cfg.StartupSupervisor;
end
