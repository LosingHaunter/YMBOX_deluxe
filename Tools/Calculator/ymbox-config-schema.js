window.YMBOXSchema = {
  "schemaVersion": 1,
  "model": "YMBOX_Control_Core",
  "defaults": {
    "Meta": {
      "ProfileName": "CRD300DA_YMBOX_SPMSM",
      "ProfileVersion": 1,
      "SchemaVersion": 1,
      "MotorClass": "SPMSM",
      "ControlAngleConvention": "electrical_positive_q",
      "Description": "Unified SPMSM/IPMSM control profile with motor-current allocation"
    },
    "Timing": {
      "BaseTick_s": 1E-6,
      "ControlFrequency_Hz": 4000,
      "MinimumControlFrequency_Hz": 4000,
      "MaximumControlFrequency_Hz": 20000,
      "MDTMTaskDivider_NULL": 10,
      "InputTaskFrequencyOverride_Hz": 4000,
      "ExactMatchTolerance_ppm": 0.1
    },
    "Motor": {
      "PolePairs": 5,
      "StatorResistance_Ohm": 0.007,
      "Ld_H": 3.15E-5,
      "Lq_H": 3.15E-5,
      "PmFlux_Wb": 0.0144,
      "RatedCurrent_A": 100,
      "MaxCurrent_A": 200,
      "MaxMechSpeed_rpm": 12032.113697747287,
      "Inertia_kgm2": 0.00148,
      "ViscousFriction_Nms": 0,
      "LoadTorque_Nm": 0
    },
    "CurrentReference": {
      "MtpaTableSize": 65,
      "MinimumIpmsmSaliencyRatio_NULL": 0.1,
      "AllocationModes_enum": [
        4,
        5,
        17
      ]
    },
    "Inverter": {
      "NominalDcBus_V": 48,
      "MinValidDcBus_V": 12,
      "MaxDcBus_V": 350,
      "PwmFrequencyOverride_Hz": 4000,
      "DeadTime_s": 2.5E-7,
      "MaximumDeadTimeDuty_NULL": 0.1,
      "HighSideVoltageDrop_V": 0,
      "LowSideVoltageDrop_V": 0,
      "DeadTimePolarity": 1,
      "PassiveVoltageReconstructionEnable": true,
      "ActiveNonlinearityCompensationEnable": false,
      "NonlinearityCompensationGain": 1,
      "NonlinearityCompensationMax_V": 2.4,
      "CurrentSignBoundaryMin_A": 0.5,
      "CurrentSignNoiseMultiplier": 4,
      "CurrentSignHold_s": 0.001,
      "VoltageErrorBudget_V": 1,
      "CurrentSlew_Aps": 200000,
      "SamplingDelay_s": 0,
      "MinDuty_NULL": 0.02,
      "MaxDuty_NULL": 0.98,
      "LinearModulationUtilization_NULL": 0.95
    },
    "Simulation": {
      "PowerStageStep_s": 1E-6
    },
    "Execution": {
      "ObserverBuildVariant": 1,
      "WorkMode_enum": 6,
      "Enable": true,
      "TargetSpeed_rpm": 1000,
      "TargetTorque_Nm": 10.8,
      "TestD": 0,
      "TestQ": 0,
      "StopTime_s": 10
    },
    "Protection": {
      "DcBusOverVoltage_V": 57.599998474121094,
      "DcBusUnderVoltage_V": 24,
      "VoltageViolationArea_Vs": 0.028799999505281448,
      "VoltageRecoveryRate_V": 1,
      "FaultClearHold_s": 0.5,
      "CommandTimeout_s": 0.1
    },
    "Feedforward": {
      "VoltageMode_enum": 0,
      "DAxisScale_NULL": 1,
      "QAxisScale_NULL": 1,
      "ElectricalAngleCompEnable": true,
      "ElectricalAngleCompScale_NULL": 1
    },
    "CurrentSensor": {
      "NoiseStd_A": 0.25,
      "SampleDelay_s": 0
    },
    "DcBusMeasurement": {
      "VoltageControlFilterAlpha_NULL": 0.5,
      "VoltageReportFilterAlpha_NULL": 0.03,
      "VoltageReportFilterEnable": true,
      "VoltagePlausibleMin_V": 0,
      "VoltagePlausibleMaxFactor_NULL": 1.2,
      "CurrentInputMovingAverageWindowSamples": 4,
      "CurrentSource_enum": 1,
      "CurrentPlausibleMax_A": 300,
      "CurrentHardMax_A": 220,
      "CurrentHardMin_A": -220
    },
    "PositionSensor": {
      "NativeCountsPerMechanicalRev": 4096,
      "ControlAngleCounts": 4096,
      "Direction": 1,
      "PllBandwidth_rads": 1200
    },
    "PlatformMath": {
      "SinCosBackend": "LUT",
      "AtanBackend": "LUT",
      "SqrtBackend": "GENERIC"
    },
    "ControlTargets": {
      "CurrentLoopKpD_VperA": 0.05938,
      "CurrentLoopKpQ_VperA": 0.05938,
      "CurrentLoopKiSeriesD_perS": 222.2,
      "CurrentLoopKiSeriesQ_perS": 222.2,
      "CurrentLoopKc_perS": 2500,
      "SpeedLoopKp_AperRpm": 0.04377,
      "SpeedLoopKiSeriesPerStep_NULL": 0.002483,
      "SpeedLoopKcSeriesPerStep_NULL": 0.002483,
      "SpeedCommandSlew_rpms": 800
    },
    "Limits": {
      "CurrentCommandMax_A": 200,
      "SoftwareOverCurrent_A": 220,
      "SoftwareOverCurrentConfirm_s": 0.00075,
      "VoltageMargin_NULL": 0.92,
      "TorquePriorityBelowBaseSpeed": true,
      "DAxisPriorityInFieldWeakening": true,
      "SpeedCommandAbsMax_rpm": 12032.113697747287,
      "DemagnetizationCurrentMin_A": -80
    },
    "Observer": {
      "EffectiveResistanceScale": 1,
      "EffectiveInductance_H": 3.15E-5,
      "ResistanceUncertaintyFraction": 0.2,
      "InductanceUncertaintyFraction": 0.25,
      "DesignMechSpeed_rpm": 3000,
      "SlideGainMargin": 1.3,
      "SlideGainOverride_V": 33,
      "ErrBoundaryRatedFraction": 0.05,
      "ErrBoundaryOverride_A": 363.38534918575056,
      "AdaptiveInjectionEnable": false,
      "SlideGainMinOverride_V": 33,
      "SlideGainMaxOverride_V": 33,
      "ErrBoundaryMinOverride_A": 363.38534918575056,
      "ErrBoundaryMaxOverride_A": 363.38534918575056,
      "GainScheduleEmfLowOverride_V": 2,
      "GainScheduleEmfHighOverride_V": 18,
      "GainScheduleTimeConstant_s": 0.02,
      "GainScheduleAngleComp_rad": 0,
      "EmfLpfPole_rads": 6441.0957960417281,
      "PllBandwidth_rads": 200,
      "PllDamping": 0.707,
      "MinEmf_V": 3.7,
      "EmfObservabilityMargin": 1.1,
      "MinSwitchSpeed_rpm": 850,
      "SwitchSpeedOverride_rpm": 850,
      "ReadySpeedErrorFraction": 0.16666666666666666,
      "ReadySpeedErrorOverride_rads": 52.35987755982989,
      "ReadyPllError": 0.5,
      "StaticAngleOffset_rad": 0,
      "TotalDelay_s": 6.2391104560596122E-5,
      "MaxElecSpeedOverride_rads": 6300
    },
    "StartupSupervisor": {
      "IfAccel_rpms": 800,
      "IfAccelBlendTime_s": 0.12,
      "IfAlignTime_s": 0.1,
      "IfBlendTime_s": 0.1,
      "IfSwitchSpeed_rpm": 850,
      "DirectHandoverTime_s": 0.1,
      "SmoReadyConfirmTime_s": 0.1,
      "ObserverExitRatio": 0.75,
      "ObserverLossConfirmTime_s": 0.02,
      "DirectHandoverDwellTime_s": 0.1,
      "StartupTimeoutMargin_s": 0.5,
      "StartupTimeoutOverride_s": 6,
      "IfStartIqOverride_A": 5,
      "IfAlignIdOverride_A": 15,
      "IfIqSlewOverride_Aps": 200,
      "DirectAccelIqSeedOverride_A": 1.1480387968673813,
      "HandoverCurrentLpfTau_s": 0.005
    },
    "FieldWeakening": {
      "Enable": true,
      "SensorlessEnable": false,
      "EntryUtilization_NULL": 0.93,
      "ExitUtilization_NULL": 0.88,
      "EntrySpeedOverride_rpm": 3148.1615033778226,
      "IdMin_A": -80,
      "VoltageLoopKp_AperUnit": 25,
      "VoltageLoopKi_AperUnitPerS": 500,
      "IdSlew_Aps": 800
    },
    "Features": {
      "UnifiedConstraintManagerEnable": true,
      "FinalIqAntiWindupEnable": true,
      "ActiveInverterCompensationEnable": false,
      "SensoredFieldWeakeningEnable": true,
      "SensorlessFieldWeakeningEnable": false
    }
  },
  "fields": [
    {
      "path": "Meta.ProfileName",
      "defaultValue": "CRD300DA_YMBOX_SPMSM",
      "type": "char",
      "shape": [
        1,
        20
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Meta.ProfileVersion",
      "defaultValue": 1,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Meta.SchemaVersion",
      "defaultValue": 1,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Meta.MotorClass",
      "defaultValue": "SPMSM",
      "type": "char",
      "shape": [
        1,
        5
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Meta.ControlAngleConvention",
      "defaultValue": "electrical_positive_q",
      "type": "char",
      "shape": [
        1,
        21
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": true
    },
    {
      "path": "Meta.Description",
      "defaultValue": "Unified SPMSM/IPMSM control profile with motor-current allocation",
      "type": "char",
      "shape": [
        1,
        65
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Timing.BaseTick_s",
      "defaultValue": 1E-6,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": true
    },
    {
      "path": "Timing.ControlFrequency_Hz",
      "defaultValue": 4000,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Timing.MinimumControlFrequency_Hz",
      "defaultValue": 4000,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": true
    },
    {
      "path": "Timing.MaximumControlFrequency_Hz",
      "defaultValue": 20000,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": true
    },
    {
      "path": "Timing.MDTMTaskDivider_NULL",
      "defaultValue": 10,
      "type": "uint16",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Timing.InputTaskFrequencyOverride_Hz",
      "defaultValue": 4000,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": true,
      "autoResolvedDefault": true,
      "readOnly": false
    },
    {
      "path": "Timing.ExactMatchTolerance_ppm",
      "defaultValue": 0.1,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": true
    },
    {
      "path": "Motor.PolePairs",
      "defaultValue": 5,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Motor.StatorResistance_Ohm",
      "defaultValue": 0.007,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Motor.Ld_H",
      "defaultValue": 3.15E-5,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Motor.Lq_H",
      "defaultValue": 3.15E-5,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Motor.PmFlux_Wb",
      "defaultValue": 0.0144,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Motor.RatedCurrent_A",
      "defaultValue": 100,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Motor.MaxCurrent_A",
      "defaultValue": 200,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Motor.MaxMechSpeed_rpm",
      "defaultValue": 12032.113697747287,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Motor.Inertia_kgm2",
      "defaultValue": 0.00148,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Motor.ViscousFriction_Nms",
      "defaultValue": 0,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Motor.LoadTorque_Nm",
      "defaultValue": 0,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "CurrentReference.MtpaTableSize",
      "defaultValue": 65,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "CurrentReference.MinimumIpmsmSaliencyRatio_NULL",
      "defaultValue": 0.1,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "CurrentReference.AllocationModes_enum",
      "defaultValue": [
        4,
        5,
        17
      ],
      "type": "uint16",
      "shape": [
        1,
        3
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": true
    },
    {
      "path": "Inverter.NominalDcBus_V",
      "defaultValue": 48,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Inverter.MinValidDcBus_V",
      "defaultValue": 12,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Inverter.MaxDcBus_V",
      "defaultValue": 350,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Inverter.PwmFrequencyOverride_Hz",
      "defaultValue": 4000,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": true,
      "autoResolvedDefault": true,
      "readOnly": false
    },
    {
      "path": "Inverter.DeadTime_s",
      "defaultValue": 2.5E-7,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Inverter.MaximumDeadTimeDuty_NULL",
      "defaultValue": 0.1,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Inverter.HighSideVoltageDrop_V",
      "defaultValue": 0,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Inverter.LowSideVoltageDrop_V",
      "defaultValue": 0,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Inverter.DeadTimePolarity",
      "defaultValue": 1,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Inverter.PassiveVoltageReconstructionEnable",
      "defaultValue": true,
      "type": "logical",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Inverter.ActiveNonlinearityCompensationEnable",
      "defaultValue": false,
      "type": "logical",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Inverter.NonlinearityCompensationGain",
      "defaultValue": 1,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Inverter.NonlinearityCompensationMax_V",
      "defaultValue": 2.4,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Inverter.CurrentSignBoundaryMin_A",
      "defaultValue": 0.5,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Inverter.CurrentSignNoiseMultiplier",
      "defaultValue": 4,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Inverter.CurrentSignHold_s",
      "defaultValue": 0.001,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Inverter.VoltageErrorBudget_V",
      "defaultValue": 1,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Inverter.CurrentSlew_Aps",
      "defaultValue": 200000,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Inverter.SamplingDelay_s",
      "defaultValue": 0,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Inverter.MinDuty_NULL",
      "defaultValue": 0.02,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Inverter.MaxDuty_NULL",
      "defaultValue": 0.98,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Inverter.LinearModulationUtilization_NULL",
      "defaultValue": 0.95,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Simulation.PowerStageStep_s",
      "defaultValue": 1E-6,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Execution.ObserverBuildVariant",
      "defaultValue": 1,
      "type": "uint8",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Execution.WorkMode_enum",
      "defaultValue": 6,
      "type": "uint16",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Execution.Enable",
      "defaultValue": true,
      "type": "logical",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Execution.TargetSpeed_rpm",
      "defaultValue": 1000,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Execution.TargetTorque_Nm",
      "defaultValue": 10.8,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Execution.TestD",
      "defaultValue": 0,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Execution.TestQ",
      "defaultValue": 0,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Execution.StopTime_s",
      "defaultValue": 10,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Protection.DcBusOverVoltage_V",
      "defaultValue": 57.599998474121094,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": true,
      "autoResolvedDefault": true,
      "readOnly": false
    },
    {
      "path": "Protection.DcBusUnderVoltage_V",
      "defaultValue": 24,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": true,
      "autoResolvedDefault": true,
      "readOnly": false
    },
    {
      "path": "Protection.VoltageViolationArea_Vs",
      "defaultValue": 0.028799999505281448,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": true,
      "autoResolvedDefault": true,
      "readOnly": false
    },
    {
      "path": "Protection.VoltageRecoveryRate_V",
      "defaultValue": 1,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Protection.FaultClearHold_s",
      "defaultValue": 0.5,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Protection.CommandTimeout_s",
      "defaultValue": 0.1,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Feedforward.VoltageMode_enum",
      "defaultValue": 0,
      "type": "uint8",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Feedforward.DAxisScale_NULL",
      "defaultValue": 1,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Feedforward.QAxisScale_NULL",
      "defaultValue": 1,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Feedforward.ElectricalAngleCompEnable",
      "defaultValue": true,
      "type": "logical",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Feedforward.ElectricalAngleCompScale_NULL",
      "defaultValue": 1,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "CurrentSensor.NoiseStd_A",
      "defaultValue": 0.25,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "CurrentSensor.SampleDelay_s",
      "defaultValue": 0,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "DcBusMeasurement.VoltageControlFilterAlpha_NULL",
      "defaultValue": 0.5,
      "type": "single",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "DcBusMeasurement.VoltageReportFilterAlpha_NULL",
      "defaultValue": 0.03,
      "type": "single",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "DcBusMeasurement.VoltageReportFilterEnable",
      "defaultValue": true,
      "type": "logical",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "DcBusMeasurement.VoltagePlausibleMin_V",
      "defaultValue": 0,
      "type": "single",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "DcBusMeasurement.VoltagePlausibleMaxFactor_NULL",
      "defaultValue": 1.2,
      "type": "single",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "DcBusMeasurement.CurrentInputMovingAverageWindowSamples",
      "defaultValue": 4,
      "type": "single",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "DcBusMeasurement.CurrentSource_enum",
      "defaultValue": 1,
      "type": "uint8",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "DcBusMeasurement.CurrentPlausibleMax_A",
      "defaultValue": 300,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "DcBusMeasurement.CurrentHardMax_A",
      "defaultValue": 220,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "DcBusMeasurement.CurrentHardMin_A",
      "defaultValue": -220,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "PositionSensor.NativeCountsPerMechanicalRev",
      "defaultValue": 4096,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "PositionSensor.ControlAngleCounts",
      "defaultValue": 4096,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "PositionSensor.Direction",
      "defaultValue": 1,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "PositionSensor.PllBandwidth_rads",
      "defaultValue": 1200,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "PlatformMath.SinCosBackend",
      "defaultValue": "LUT",
      "type": "char",
      "shape": [
        1,
        3
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "PlatformMath.AtanBackend",
      "defaultValue": "LUT",
      "type": "char",
      "shape": [
        1,
        3
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "PlatformMath.SqrtBackend",
      "defaultValue": "GENERIC",
      "type": "char",
      "shape": [
        1,
        7
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "ControlTargets.CurrentLoopKpD_VperA",
      "defaultValue": 0.05938,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "ControlTargets.CurrentLoopKpQ_VperA",
      "defaultValue": 0.05938,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "ControlTargets.CurrentLoopKiSeriesD_perS",
      "defaultValue": 222.2,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "ControlTargets.CurrentLoopKiSeriesQ_perS",
      "defaultValue": 222.2,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "ControlTargets.CurrentLoopKc_perS",
      "defaultValue": 2500,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "ControlTargets.SpeedLoopKp_AperRpm",
      "defaultValue": 0.04377,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "ControlTargets.SpeedLoopKiSeriesPerStep_NULL",
      "defaultValue": 0.002483,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "ControlTargets.SpeedLoopKcSeriesPerStep_NULL",
      "defaultValue": 0.002483,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "ControlTargets.SpeedCommandSlew_rpms",
      "defaultValue": 800,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Limits.CurrentCommandMax_A",
      "defaultValue": 200,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Limits.SoftwareOverCurrent_A",
      "defaultValue": 220,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Limits.SoftwareOverCurrentConfirm_s",
      "defaultValue": 0.00075,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Limits.VoltageMargin_NULL",
      "defaultValue": 0.92,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Limits.TorquePriorityBelowBaseSpeed",
      "defaultValue": true,
      "type": "logical",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Limits.DAxisPriorityInFieldWeakening",
      "defaultValue": true,
      "type": "logical",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Limits.SpeedCommandAbsMax_rpm",
      "defaultValue": 12032.113697747287,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Limits.DemagnetizationCurrentMin_A",
      "defaultValue": -80,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Observer.EffectiveResistanceScale",
      "defaultValue": 1,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Observer.EffectiveInductance_H",
      "defaultValue": 3.15E-5,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": true,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Observer.ResistanceUncertaintyFraction",
      "defaultValue": 0.2,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Observer.InductanceUncertaintyFraction",
      "defaultValue": 0.25,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Observer.DesignMechSpeed_rpm",
      "defaultValue": 3000,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Observer.SlideGainMargin",
      "defaultValue": 1.3,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Observer.SlideGainOverride_V",
      "defaultValue": 33,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": true,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Observer.ErrBoundaryRatedFraction",
      "defaultValue": 0.05,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Observer.ErrBoundaryOverride_A",
      "defaultValue": 363.38534918575056,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": true,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Observer.AdaptiveInjectionEnable",
      "defaultValue": false,
      "type": "logical",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Observer.SlideGainMinOverride_V",
      "defaultValue": 33,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": true,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Observer.SlideGainMaxOverride_V",
      "defaultValue": 33,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": true,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Observer.ErrBoundaryMinOverride_A",
      "defaultValue": 363.38534918575056,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": true,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Observer.ErrBoundaryMaxOverride_A",
      "defaultValue": 363.38534918575056,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": true,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Observer.GainScheduleEmfLowOverride_V",
      "defaultValue": 2,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": true,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Observer.GainScheduleEmfHighOverride_V",
      "defaultValue": 18,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": true,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Observer.GainScheduleTimeConstant_s",
      "defaultValue": 0.02,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Observer.GainScheduleAngleComp_rad",
      "defaultValue": 0,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Observer.EmfLpfPole_rads",
      "defaultValue": 6441.0957960417281,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Observer.PllBandwidth_rads",
      "defaultValue": 200,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Observer.PllDamping",
      "defaultValue": 0.707,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Observer.MinEmf_V",
      "defaultValue": 3.7,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Observer.EmfObservabilityMargin",
      "defaultValue": 1.1,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Observer.MinSwitchSpeed_rpm",
      "defaultValue": 850,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Observer.SwitchSpeedOverride_rpm",
      "defaultValue": 850,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": true,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Observer.ReadySpeedErrorFraction",
      "defaultValue": 0.16666666666666666,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Observer.ReadySpeedErrorOverride_rads",
      "defaultValue": 52.35987755982989,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": true,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Observer.ReadyPllError",
      "defaultValue": 0.5,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Observer.StaticAngleOffset_rad",
      "defaultValue": 0,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Observer.TotalDelay_s",
      "defaultValue": 6.2391104560596122E-5,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Observer.MaxElecSpeedOverride_rads",
      "defaultValue": 6300,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": true,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "StartupSupervisor.IfAccel_rpms",
      "defaultValue": 800,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "StartupSupervisor.IfAccelBlendTime_s",
      "defaultValue": 0.12,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "StartupSupervisor.IfAlignTime_s",
      "defaultValue": 0.1,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "StartupSupervisor.IfBlendTime_s",
      "defaultValue": 0.1,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "StartupSupervisor.IfSwitchSpeed_rpm",
      "defaultValue": 850,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "StartupSupervisor.DirectHandoverTime_s",
      "defaultValue": 0.1,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "StartupSupervisor.SmoReadyConfirmTime_s",
      "defaultValue": 0.1,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "StartupSupervisor.ObserverExitRatio",
      "defaultValue": 0.75,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "StartupSupervisor.ObserverLossConfirmTime_s",
      "defaultValue": 0.02,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "StartupSupervisor.DirectHandoverDwellTime_s",
      "defaultValue": 0.1,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "StartupSupervisor.StartupTimeoutMargin_s",
      "defaultValue": 0.5,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "StartupSupervisor.StartupTimeoutOverride_s",
      "defaultValue": 6,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": true,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "StartupSupervisor.IfStartIqOverride_A",
      "defaultValue": 5,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": true,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "StartupSupervisor.IfAlignIdOverride_A",
      "defaultValue": 15,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": true,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "StartupSupervisor.IfIqSlewOverride_Aps",
      "defaultValue": 200,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": true,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "StartupSupervisor.DirectAccelIqSeedOverride_A",
      "defaultValue": 1.1480387968673813,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": true,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "StartupSupervisor.HandoverCurrentLpfTau_s",
      "defaultValue": 0.005,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "FieldWeakening.Enable",
      "defaultValue": true,
      "type": "logical",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "FieldWeakening.SensorlessEnable",
      "defaultValue": false,
      "type": "logical",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": true
    },
    {
      "path": "FieldWeakening.EntryUtilization_NULL",
      "defaultValue": 0.93,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "FieldWeakening.ExitUtilization_NULL",
      "defaultValue": 0.88,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "FieldWeakening.EntrySpeedOverride_rpm",
      "defaultValue": 3148.1615033778226,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": true,
      "autoResolvedDefault": true,
      "readOnly": false
    },
    {
      "path": "FieldWeakening.IdMin_A",
      "defaultValue": -80,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "FieldWeakening.VoltageLoopKp_AperUnit",
      "defaultValue": 25,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "FieldWeakening.VoltageLoopKi_AperUnitPerS",
      "defaultValue": 500,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "FieldWeakening.IdSlew_Aps",
      "defaultValue": 800,
      "type": "double",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Features.UnifiedConstraintManagerEnable",
      "defaultValue": true,
      "type": "logical",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Features.FinalIqAntiWindupEnable",
      "defaultValue": true,
      "type": "logical",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Features.ActiveInverterCompensationEnable",
      "defaultValue": false,
      "type": "logical",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Features.SensoredFieldWeakeningEnable",
      "defaultValue": true,
      "type": "logical",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": false
    },
    {
      "path": "Features.SensorlessFieldWeakeningEnable",
      "defaultValue": false,
      "type": "logical",
      "shape": [
        1,
        1
      ],
      "allowsAuto": false,
      "canResolveAuto": false,
      "autoResolvedDefault": false,
      "readOnly": true
    }
  ],
  "fieldCount": 167,
  "retiredFields": [
    "Inverter.DiodeVoltageDrop_V",
    "CurrentSensor.OffsetUncertainty_A",
    "CurrentSensor.FullScale_A",
    "PositionSensor.Type",
    "PositionSensor.ElectricalOffset_rad",
    "PositionSensor.ResolverPllBandwidth_rads",
    "PositionSensor.MaximumSampleAge_s",
    "PositionSensor.AngleValidDefault",
    "PositionSensor.SpeedValidDefault",
    "PositionSensor.QualityDefault_NULL",
    "PositionSensor.MinimumAcceptedQuality_NULL",
    "PositionSensor.LegacySourceId_enum",
    "PositionSensor.SensorlessSourceId_enum",
    "PositionSensor.IfSourceId_enum",
    "Features.GenericPositionInterfaceEnable",
    "Observer.ReadyAngleError_rad",
    "Observer.TargetSpeedError_rpm",
    "Observer.PhaseAcquireGain_Hz",
    "StartupSupervisor.IfReadySpeedError_rads",
    "StartupSupervisor.IfReadyAngleError_rad",
    "StartupSupervisor.IfSyncGain_Hz",
    "StartupSupervisor.IfReadyConfirmTime_s",
    "StartupSupervisor.ObserverBlendTime_s",
    "StartupSupervisor.DirectTorqueSeedBlend",
    "FieldWeakening.MinimumSpeed_rpm"
  ],
  "source": "ProjectConfiguration/ApplicationParameters/YMBOX_Drive_Parameters.m",
  "generatedAt": "2026-09-20 10:58:45"
};
