% Range validation belongs to the configuration calculator and import checks.
% Leave data-object Min/Max unspecified; runtime limits use configured values.
% Consume the single context published by YMBOX_InitializeModel.
assert(exist('YMBOX_Drive_Config','var') && ...
    isstruct(YMBOX_Drive_Config) && ...
    exist('YMBOX_Drive_Derived','var') && ...
    isstruct(YMBOX_Drive_Derived), ...
    'YMBOX:Initialization:MissingDriveContext', ...
    'Run YMBOX_InitializeModel before MDTM_Model_Library.');
assert(exist('YMBOX_SMO_Derived','var') && ...
    isstruct(YMBOX_SMO_Derived), ...
    'YMBOX:Initialization:MissingSmoDerived', ...
    'Run YMBOX_InitializeModel before MDTM_Model_Library.');
assert(exist('Cf_CONTROL_TASK_TIME_S','var'), ...
    'YMBOX:Initialization:MissingControlPeriod', ...
    'Run YMBOX_InitializeModel before MDTM_Model_Library.');
YMBOX_ControlPeriod_s = double(Cf_CONTROL_TASK_TIME_S);

KuMDTM_TaskDivider_NULL = mpt.Parameter;
KuMDTM_TaskDivider_NULL.Value = uint16( ...
    YMBOX_Drive_Config.Timing.MDTMTaskDivider_NULL);
KuMDTM_TaskDivider_NULL.DataType = 'uint16';
KuMDTM_TaskDivider_NULL.StorageClass = 'Const (Custom)';
KuMDTM_TaskDivider_NULL.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KuMDTM_TaskDivider_NULL.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KuMDTM_TaskDivider_NULL.DocUnits = 'NULL';

KfMDTM_KpValueSpdPI_NULL = mpt.Parameter;
KfMDTM_KpValueSpdPI_NULL.Value = ...
    YMBOX_Drive_Derived.SpeedLoop.Kp_AperRpm;
KfMDTM_KpValueSpdPI_NULL.DataType = 'single';
KfMDTM_KpValueSpdPI_NULL.StorageClass = 'Const (Custom)';
KfMDTM_KpValueSpdPI_NULL.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDTM_KpValueSpdPI_NULL.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDTM_KpValueSpdPI_NULL.DocUnits = 'NULL';

KfMDTM_KiValueSpdPI_NULL = mpt.Parameter;
KfMDTM_KiValueSpdPI_NULL.Value = ...
    YMBOX_Drive_Derived.SpeedLoop.KiSeriesPerStep_NULL;
KfMDTM_KiValueSpdPI_NULL.DataType = 'single';
KfMDTM_KiValueSpdPI_NULL.StorageClass = 'Const (Custom)';
KfMDTM_KiValueSpdPI_NULL.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDTM_KiValueSpdPI_NULL.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDTM_KiValueSpdPI_NULL.DocUnits = 'NULL';

KfMDTM_KcValueSpdPI_NULL = mpt.Parameter;
KfMDTM_KcValueSpdPI_NULL.Value = ...
    YMBOX_Drive_Derived.SpeedLoop.KcSeriesPerStep_NULL;
KfMDTM_KcValueSpdPI_NULL.DataType = 'single';
KfMDTM_KcValueSpdPI_NULL.StorageClass = 'Const (Custom)';
KfMDTM_KcValueSpdPI_NULL.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDTM_KcValueSpdPI_NULL.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDTM_KcValueSpdPI_NULL.DocUnits = 'NULL';

KfMDTM_IqCmdMax_A = mpt.Parameter;
KfMDTM_IqCmdMax_A.Value = ...
    YMBOX_Drive_Derived.CurrentReference.EquivalentIqMax_A;
KfMDTM_IqCmdMax_A.DataType = 'single';
KfMDTM_IqCmdMax_A.StorageClass = 'Const (Custom)';
KfMDTM_IqCmdMax_A.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDTM_IqCmdMax_A.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDTM_IqCmdMax_A.DocUnits = 'A';

KfMDTM_IqCmdMin_A = mpt.Parameter;
KfMDTM_IqCmdMin_A.Value = ...
    -YMBOX_Drive_Derived.CurrentReference.EquivalentIqMax_A;
KfMDTM_IqCmdMin_A.DataType = 'single';
KfMDTM_IqCmdMin_A.StorageClass = 'Const (Custom)';
KfMDTM_IqCmdMin_A.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDTM_IqCmdMin_A.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDTM_IqCmdMin_A.DocUnits = 'A';

% Sensored-only speed-command increment.  The period scale preserves the
% configured physical rpm/s slope at every released control rate.
KfMDTM_SpdCmdRamp_rpm = mpt.Parameter;
KfMDTM_SpdCmdRamp_rpm.Value = ...
    YMBOX_Drive_Derived.SpeedLoop.CommandSlewPerStep_rpm;
KfMDTM_SpdCmdRamp_rpm.DataType = 'single';
KfMDTM_SpdCmdRamp_rpm.StorageClass = 'Const (Custom)';
KfMDTM_SpdCmdRamp_rpm.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDTM_SpdCmdRamp_rpm.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDTM_SpdCmdRamp_rpm.DocUnits = 'rpm';

% The sensorless observer speed-loop command ramp intentionally has no
% independent calibration.  Its per-call increment is calculated in the
% full sensorless choice as KfMDAS_IfAccel_rpms * Cf_CONTROL_TASK_TIME_S,
% so I/F startup and the observer speed command share one acceleration.

KfMDTM_Trq2Iq_NULL = mpt.Parameter;
KfMDTM_Trq2Iq_NULL.Value = ...
    YMBOX_Drive_Derived.Motor.TorqueToIq_AperNm;
KfMDTM_Trq2Iq_NULL.DataType = 'single';
KfMDTM_Trq2Iq_NULL.StorageClass = 'Const (Custom)';
KfMDTM_Trq2Iq_NULL.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDTM_Trq2Iq_NULL.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDTM_Trq2Iq_NULL.DocUnits = 'NULL';

% Compile-time motor-current reference allocation choice:
%   0 = SPMSM direct pass-through
%   1 = IPMSM offline MTPA lookup
KuMDTM_MotorCurrentReferenceVariant = Simulink.Parameter;
KuMDTM_MotorCurrentReferenceVariant.Value = uint8( ...
    YMBOX_Drive_Derived.CurrentReference.Variant);
KuMDTM_MotorCurrentReferenceVariant.DataType = 'uint8';
KuMDTM_MotorCurrentReferenceVariant.CoderInfo.StorageClass = 'Auto';
KuMDTM_MotorCurrentReferenceVariant.Description = ...
    'MotorCurrentReferenceGenerator Variant: 0=SPMSM, 1=IPMSM MTPA';

KfMDTM_TorqueConstant_NmPerA = mpt.Parameter;
KfMDTM_TorqueConstant_NmPerA.Value = YMBOX_Drive_Derived.Motor.TorqueConstant_NmPerA;
KfMDTM_TorqueConstant_NmPerA.DataType = 'single';
KfMDTM_TorqueConstant_NmPerA.StorageClass = 'Const (Custom)';
KfMDTM_TorqueConstant_NmPerA.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDTM_TorqueConstant_NmPerA.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDTM_TorqueConstant_NmPerA.DocUnits = 'NULL';

KfMDTM_MTPAEquivalentIqBreakpoints_A = mpt.Parameter;
KfMDTM_MTPAEquivalentIqBreakpoints_A.Value = ...
    single(YMBOX_Drive_Derived.CurrentReference.EquivalentIqBreakpoints_A);
% This torque/Kt axis includes reluctance torque and can exceed the physical
% phase-current limit; the calculator validates the generated table.
KfMDTM_MTPAEquivalentIqBreakpoints_A.DataType = 'single';
KfMDTM_MTPAEquivalentIqBreakpoints_A.StorageClass = 'Const (Custom)';
KfMDTM_MTPAEquivalentIqBreakpoints_A.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDTM_MTPAEquivalentIqBreakpoints_A.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDTM_MTPAEquivalentIqBreakpoints_A.DocUnits = 'A';

KfMDTM_MTPAIdTable_A = mpt.Parameter;
KfMDTM_MTPAIdTable_A.Value = single(YMBOX_Drive_Derived.CurrentReference.IdTable_A);
KfMDTM_MTPAIdTable_A.DataType = 'single';
KfMDTM_MTPAIdTable_A.StorageClass = 'Const (Custom)';
KfMDTM_MTPAIdTable_A.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDTM_MTPAIdTable_A.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDTM_MTPAIdTable_A.DocUnits = 'A';

KfMDTM_MTPAIqTable_A = mpt.Parameter;
KfMDTM_MTPAIqTable_A.Value = single(YMBOX_Drive_Derived.CurrentReference.IqTable_A);
KfMDTM_MTPAIqTable_A.DataType = 'single';
KfMDTM_MTPAIqTable_A.StorageClass = 'Const (Custom)';
KfMDTM_MTPAIqTable_A.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDTM_MTPAIqTable_A.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDTM_MTPAIqTable_A.DocUnits = 'A';

KfMDTM_IfStartIq_A = mpt.Parameter;
KfMDTM_IfStartIq_A.Value = YMBOX_SMO_Derived.IfStartIq_A;
KfMDTM_IfStartIq_A.DataType = 'single';
KfMDTM_IfStartIq_A.StorageClass = 'Const (Custom)';
KfMDTM_IfStartIq_A.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDTM_IfStartIq_A.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDTM_IfStartIq_A.DocUnits = 'A';

% Minimum drive-direction speed-PI seed used only for direct I/F -> observer
% pickup.  The 1.2-A default is the no-load acceleration feedforward for the
% simulation plant: J=0.00148 kg*m^2, 800 rpm/s, Kt=0.106 N*m/A.  Hardware
% calibration should add the measured load/friction torque allowance.
YMBOX_DirectAccelIqSeed_A = YMBOX_SMO_Derived.DirectAccelIqSeed_A;
if exist('YMBOX_DirectAccelIqSeedOverride_A','var') && ...
        isfinite(YMBOX_DirectAccelIqSeedOverride_A)
    YMBOX_DirectAccelIqSeed_A = min(30,max(0,double(YMBOX_DirectAccelIqSeedOverride_A)));
end
KfMDTM_DirectAccelIqSeed_A = mpt.Parameter;
KfMDTM_DirectAccelIqSeed_A.Value = YMBOX_DirectAccelIqSeed_A;
KfMDTM_DirectAccelIqSeed_A.DataType = 'single';
KfMDTM_DirectAccelIqSeed_A.StorageClass = 'Const (Custom)';
KfMDTM_DirectAccelIqSeed_A.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDTM_DirectAccelIqSeed_A.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDTM_DirectAccelIqSeed_A.DocUnits = 'A';
clear YMBOX_DirectAccelIqSeed_A;

% Real-current handover estimator.  The filter operates on observer-frame
% dq current, so its time constant is independent of electrical frequency.
KfMDTM_HandoverCurrentLpfAlpha_NULL = mpt.Parameter;
KfMDTM_HandoverCurrentLpfAlpha_NULL.Value = ...
    YMBOX_SMO_Derived.HandoverCurrentLpfAlpha;
KfMDTM_HandoverCurrentLpfAlpha_NULL.DataType = 'single';
KfMDTM_HandoverCurrentLpfAlpha_NULL.StorageClass = 'Const (Custom)';
KfMDTM_HandoverCurrentLpfAlpha_NULL.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDTM_HandoverCurrentLpfAlpha_NULL.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDTM_HandoverCurrentLpfAlpha_NULL.DocUnits = 'NULL';

KfMDTM_IfAlignId_A = mpt.Parameter;
KfMDTM_IfAlignId_A.Value = YMBOX_SMO_Derived.IfAlignId_A;
KfMDTM_IfAlignId_A.DataType = 'single';
KfMDTM_IfAlignId_A.StorageClass = 'Const (Custom)';
KfMDTM_IfAlignId_A.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDTM_IfAlignId_A.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDTM_IfAlignId_A.DocUnits = 'A';

KfMDTM_IfIqSlew_Aps = mpt.Parameter;
KfMDTM_IfIqSlew_Aps.Value = YMBOX_SMO_Derived.IfIqSlew_Aps;
KfMDTM_IfIqSlew_Aps.DataType = 'single';
KfMDTM_IfIqSlew_Aps.StorageClass = 'Const (Custom)';
KfMDTM_IfIqSlew_Aps.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDTM_IfIqSlew_Aps.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDTM_IfIqSlew_Aps.DocUnits = 'Aps';

% Unified command constraints, final-limit anti-windup, and sensored SPMSM
% field weakening.  Each switch is a generated-code rollback calibration.
KfMDTM_ControlPeriod_s = mpt.Parameter;
KfMDTM_ControlPeriod_s.Value = YMBOX_ControlPeriod_s;
KfMDTM_ControlPeriod_s.DataType = 'single';
KfMDTM_ControlPeriod_s.StorageClass = 'Const (Custom)';
KfMDTM_ControlPeriod_s.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDTM_ControlPeriod_s.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDTM_ControlPeriod_s.DocUnits = 's';

KbMDTM_UnifiedConstraintEnable_flg = mpt.Parameter;
KbMDTM_UnifiedConstraintEnable_flg.Value = logical( ...
    YMBOX_Drive_Derived.Features.UnifiedConstraintManagerEnable);
KbMDTM_UnifiedConstraintEnable_flg.DataType = 'boolean';
KbMDTM_UnifiedConstraintEnable_flg.StorageClass = 'Const (Custom)';
KbMDTM_UnifiedConstraintEnable_flg.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KbMDTM_UnifiedConstraintEnable_flg.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KbMDTM_UnifiedConstraintEnable_flg.DocUnits = 'flg';

KbMDTM_FinalIqAntiWindupEnable_flg = mpt.Parameter;
KbMDTM_FinalIqAntiWindupEnable_flg.Value = logical( ...
    YMBOX_Drive_Derived.Features.FinalIqAntiWindupEnable);
KbMDTM_FinalIqAntiWindupEnable_flg.DataType = 'boolean';
KbMDTM_FinalIqAntiWindupEnable_flg.StorageClass = 'Const (Custom)';
KbMDTM_FinalIqAntiWindupEnable_flg.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KbMDTM_FinalIqAntiWindupEnable_flg.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KbMDTM_FinalIqAntiWindupEnable_flg.DocUnits = 'flg';

KfMDTM_CurrentVectorMax_A = mpt.Parameter;
KfMDTM_CurrentVectorMax_A.Value = YMBOX_Drive_Derived.Constraint.CurrentMax_A;
KfMDTM_CurrentVectorMax_A.DataType = 'single';
KfMDTM_CurrentVectorMax_A.StorageClass = 'Const (Custom)';
KfMDTM_CurrentVectorMax_A.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDTM_CurrentVectorMax_A.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDTM_CurrentVectorMax_A.DocUnits = 'A';

KfMDTM_VdqMaxPerDcBus_NULL = mpt.Parameter;
KfMDTM_VdqMaxPerDcBus_NULL.Value = YMBOX_Drive_Derived.Constraint.VdqMaxPerDcBus_NULL;
KfMDTM_VdqMaxPerDcBus_NULL.DataType = 'single';
KfMDTM_VdqMaxPerDcBus_NULL.StorageClass = 'Const (Custom)';
KfMDTM_VdqMaxPerDcBus_NULL.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDTM_VdqMaxPerDcBus_NULL.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDTM_VdqMaxPerDcBus_NULL.DocUnits = 'NULL';

KfMDTM_MinValidDcBus_V = mpt.Parameter;
KfMDTM_MinValidDcBus_V.Value = YMBOX_Drive_Config.Inverter.MinValidDcBus_V;
KfMDTM_MinValidDcBus_V.DataType = 'single';
KfMDTM_MinValidDcBus_V.StorageClass = 'Const (Custom)';
KfMDTM_MinValidDcBus_V.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDTM_MinValidDcBus_V.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDTM_MinValidDcBus_V.DocUnits = 'V';

KfMDTM_OperatingRs_Ohm = mpt.Parameter;
KfMDTM_OperatingRs_Ohm.Value = YMBOX_Drive_Derived.Motor.Rs_Ohm;
KfMDTM_OperatingRs_Ohm.DataType = 'single';
KfMDTM_OperatingRs_Ohm.StorageClass = 'Const (Custom)';
KfMDTM_OperatingRs_Ohm.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDTM_OperatingRs_Ohm.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDTM_OperatingRs_Ohm.DocUnits = 'Ohm';

KfMDTM_Ld_H = mpt.Parameter;
KfMDTM_Ld_H.Value = YMBOX_Drive_Derived.Motor.Ld_H;
KfMDTM_Ld_H.DataType = 'single';
KfMDTM_Ld_H.StorageClass = 'Const (Custom)';
KfMDTM_Ld_H.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDTM_Ld_H.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDTM_Ld_H.DocUnits = 'H';

KfMDTM_Lq_H = mpt.Parameter;
KfMDTM_Lq_H.Value = YMBOX_Drive_Derived.Motor.Lq_H;
KfMDTM_Lq_H.DataType = 'single';
KfMDTM_Lq_H.StorageClass = 'Const (Custom)';
KfMDTM_Lq_H.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDTM_Lq_H.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDTM_Lq_H.DocUnits = 'H';

KfMDTM_PmFlux_Wb = mpt.Parameter;
KfMDTM_PmFlux_Wb.Value = YMBOX_Drive_Derived.Motor.PmFlux_Wb;
KfMDTM_PmFlux_Wb.DataType = 'single';
KfMDTM_PmFlux_Wb.StorageClass = 'Const (Custom)';
KfMDTM_PmFlux_Wb.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDTM_PmFlux_Wb.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDTM_PmFlux_Wb.DocUnits = 'Wb';

KuMDTM_PolePairs_NULL = mpt.Parameter;
KuMDTM_PolePairs_NULL.Value = uint16(YMBOX_Drive_Derived.Motor.PolePairs);
KuMDTM_PolePairs_NULL.DataType = 'uint16';
KuMDTM_PolePairs_NULL.StorageClass = 'Const (Custom)';
KuMDTM_PolePairs_NULL.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KuMDTM_PolePairs_NULL.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KuMDTM_PolePairs_NULL.DocUnits = 'NULL';

KbMDTM_FieldWeakeningEnable_flg = mpt.Parameter;
KbMDTM_FieldWeakeningEnable_flg.Value = logical( ...
    YMBOX_Drive_Derived.FieldWeakening.Enable);
KbMDTM_FieldWeakeningEnable_flg.DataType = 'boolean';
KbMDTM_FieldWeakeningEnable_flg.StorageClass = 'Const (Custom)';
KbMDTM_FieldWeakeningEnable_flg.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KbMDTM_FieldWeakeningEnable_flg.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KbMDTM_FieldWeakeningEnable_flg.DocUnits = 'flg';

KbMDTM_SensorlessFieldWeakeningEnable_flg = mpt.Parameter;
KbMDTM_SensorlessFieldWeakeningEnable_flg.Value = logical( ...
    YMBOX_Drive_Derived.FieldWeakening.SensorlessEnable);
KbMDTM_SensorlessFieldWeakeningEnable_flg.DataType = 'boolean';
KbMDTM_SensorlessFieldWeakeningEnable_flg.StorageClass = 'Const (Custom)';
KbMDTM_SensorlessFieldWeakeningEnable_flg.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KbMDTM_SensorlessFieldWeakeningEnable_flg.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KbMDTM_SensorlessFieldWeakeningEnable_flg.DocUnits = 'flg';

KfMDTM_FWEntryUtilization_NULL = mpt.Parameter;
KfMDTM_FWEntryUtilization_NULL.Value = YMBOX_Drive_Derived.FieldWeakening.EntryUtilization_NULL;
KfMDTM_FWEntryUtilization_NULL.DataType = 'single';
KfMDTM_FWEntryUtilization_NULL.StorageClass = 'Const (Custom)';
KfMDTM_FWEntryUtilization_NULL.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDTM_FWEntryUtilization_NULL.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDTM_FWEntryUtilization_NULL.DocUnits = 'NULL';

KfMDTM_FWExitUtilization_NULL = mpt.Parameter;
KfMDTM_FWExitUtilization_NULL.Value = YMBOX_Drive_Derived.FieldWeakening.ExitUtilization_NULL;
KfMDTM_FWExitUtilization_NULL.DataType = 'single';
KfMDTM_FWExitUtilization_NULL.StorageClass = 'Const (Custom)';
KfMDTM_FWExitUtilization_NULL.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDTM_FWExitUtilization_NULL.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDTM_FWExitUtilization_NULL.DocUnits = 'NULL';

KfMDTM_FWEntrySpeed_rpm = mpt.Parameter;
KfMDTM_FWEntrySpeed_rpm.Value = YMBOX_Drive_Derived.FieldWeakening.EntrySpeed_rpm;
KfMDTM_FWEntrySpeed_rpm.DataType = 'single';
KfMDTM_FWEntrySpeed_rpm.StorageClass = 'Const (Custom)';
KfMDTM_FWEntrySpeed_rpm.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDTM_FWEntrySpeed_rpm.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDTM_FWEntrySpeed_rpm.DocUnits = 'rpm';

KfMDTM_FWIdMin_A = mpt.Parameter;
KfMDTM_FWIdMin_A.Value = YMBOX_Drive_Derived.FieldWeakening.IdMin_A;
KfMDTM_FWIdMin_A.DataType = 'single';
KfMDTM_FWIdMin_A.StorageClass = 'Const (Custom)';
KfMDTM_FWIdMin_A.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDTM_FWIdMin_A.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDTM_FWIdMin_A.DocUnits = 'A';

KfMDTM_FWKp_AperUnit = mpt.Parameter;
KfMDTM_FWKp_AperUnit.Value = YMBOX_Drive_Derived.FieldWeakening.Kp_AperUnit;
KfMDTM_FWKp_AperUnit.DataType = 'single';
KfMDTM_FWKp_AperUnit.StorageClass = 'Const (Custom)';
KfMDTM_FWKp_AperUnit.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDTM_FWKp_AperUnit.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDTM_FWKp_AperUnit.DocUnits = 'A';

KfMDTM_FWKiTs_AperUnit = mpt.Parameter;
KfMDTM_FWKiTs_AperUnit.Value = YMBOX_Drive_Derived.FieldWeakening.KiTs_AperUnit;
KfMDTM_FWKiTs_AperUnit.DataType = 'single';
KfMDTM_FWKiTs_AperUnit.StorageClass = 'Const (Custom)';
KfMDTM_FWKiTs_AperUnit.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDTM_FWKiTs_AperUnit.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDTM_FWKiTs_AperUnit.DocUnits = 'A';

KfMDTM_FWIdSlewPerStep_A = mpt.Parameter;
KfMDTM_FWIdSlewPerStep_A.Value = YMBOX_Drive_Derived.FieldWeakening.IdSlewPerStep_A;
KfMDTM_FWIdSlewPerStep_A.DataType = 'single';
KfMDTM_FWIdSlewPerStep_A.StorageClass = 'Const (Custom)';
KfMDTM_FWIdSlewPerStep_A.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDTM_FWIdSlewPerStep_A.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDTM_FWIdSlewPerStep_A.DocUnits = 'A';

KbMDTM_TorquePriorityBelowBase_flg = mpt.Parameter;
KbMDTM_TorquePriorityBelowBase_flg.Value = logical( ...
    YMBOX_Drive_Derived.Constraint.TorquePriorityBelowBaseSpeed);
KbMDTM_TorquePriorityBelowBase_flg.DataType = 'boolean';
KbMDTM_TorquePriorityBelowBase_flg.StorageClass = 'Const (Custom)';
KbMDTM_TorquePriorityBelowBase_flg.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KbMDTM_TorquePriorityBelowBase_flg.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KbMDTM_TorquePriorityBelowBase_flg.DocUnits = 'flg';

KbMDTM_DAxisPriorityInFW_flg = mpt.Parameter;
KbMDTM_DAxisPriorityInFW_flg.Value = logical( ...
    YMBOX_Drive_Derived.Constraint.DAxisPriorityInFieldWeakening);
KbMDTM_DAxisPriorityInFW_flg.DataType = 'boolean';
KbMDTM_DAxisPriorityInFW_flg.StorageClass = 'Const (Custom)';
KbMDTM_DAxisPriorityInFW_flg.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KbMDTM_DAxisPriorityInFW_flg.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KbMDTM_DAxisPriorityInFW_flg.DocUnits = 'flg';

KfMDTM_PositionQualityMin_NULL = mpt.Parameter;
% Fixed internal status threshold; not a user sensor-quality setting.
KfMDTM_PositionQualityMin_NULL.Value = 0.5;
KfMDTM_PositionQualityMin_NULL.DataType = 'single';
KfMDTM_PositionQualityMin_NULL.StorageClass = 'Const (Custom)';
KfMDTM_PositionQualityMin_NULL.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDTM_PositionQualityMin_NULL.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDTM_PositionQualityMin_NULL.DocUnits = 'NULL';

VfMDTM_IqCmd_A = Simulink.Signal;
VfMDTM_IqCmd_A.RTWInfo.StorageClass = 'ExportedGlobal';
VfMDTM_IqCmd_A.DataType = 'single';
VfMDTM_IqCmd_A.Description = '';
VfMDTM_IqCmd_A.DocUnits = 'A';

VfMDTM_IdCmd_A = Simulink.Signal;
VfMDTM_IdCmd_A.RTWInfo.StorageClass = 'ExportedGlobal';
VfMDTM_IdCmd_A.DataType = 'single';
VfMDTM_IdCmd_A.Description = '';
VfMDTM_IdCmd_A.DocUnits = 'A';

clear YMBOX_ControlPeriod_s;
