% Range validation belongs to the configuration calculator and import checks.
% Leave data-object Min/Max unspecified; runtime limits use configured values.
% Consume the resolved drive context published by YMBOX_InitializeModel.
assert(exist('YMBOX_Drive_Config','var') && isstruct(YMBOX_Drive_Config), ...
    'YMBOX:Initialization:MissingDriveConfig', ...
    'Run YMBOX_InitializeModel before MDFM_Model_Library.');
assert(exist('YMBOX_Drive_Derived','var') && isstruct(YMBOX_Drive_Derived), ...
    'YMBOX:Initialization:MissingDriveDerived', ...
    'Run YMBOX_InitializeModel before MDFM_Model_Library.');

% MDFM owns DC-bus hard-current thresholds and diagnostic publication.
KfMDFM_DCBusCurrentHardMax_A = mpt.Parameter;
KfMDFM_DCBusCurrentHardMax_A.Value = single( ...
    YMBOX_Drive_Config.DcBusMeasurement.CurrentHardMax_A);
KfMDFM_DCBusCurrentHardMax_A.DataType = 'single';
KfMDFM_DCBusCurrentHardMax_A.StorageClass = 'Const (Custom)';
KfMDFM_DCBusCurrentHardMax_A.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDFM_DCBusCurrentHardMax_A.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDFM_DCBusCurrentHardMax_A.DocUnits = 'A';

KfMDFM_DCBusCurrentHardMin_A = mpt.Parameter;
KfMDFM_DCBusCurrentHardMin_A.Value = single( ...
    YMBOX_Drive_Config.DcBusMeasurement.CurrentHardMin_A);
KfMDFM_DCBusCurrentHardMin_A.DataType = 'single';
KfMDFM_DCBusCurrentHardMin_A.StorageClass = 'Const (Custom)';
KfMDFM_DCBusCurrentHardMin_A.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDFM_DCBusCurrentHardMin_A.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDFM_DCBusCurrentHardMin_A.DocUnits = 'A';

% Voltage limits remain target-profile calibrations. The under-voltage
% default is intentionally conservative for the first board-independent
% release and can be overridden after hardware characterization.
KfMDFM_DcBusOverVoltage_V = mpt.Parameter;
KfMDFM_DcBusOverVoltage_V.Value = ...
    single(min(YMBOX_Drive_Config.Inverter.MaxDcBus_V, ...
    1.2 * YMBOX_Drive_Config.Inverter.NominalDcBus_V));
if isfinite(YMBOX_Drive_Config.Protection.DcBusOverVoltage_V)
    KfMDFM_DcBusOverVoltage_V.Value = single(YMBOX_Drive_Config.Protection.DcBusOverVoltage_V);
end
KfMDFM_DcBusOverVoltage_V.DataType = 'single';
KfMDFM_DcBusOverVoltage_V.StorageClass = 'Const (Custom)';
KfMDFM_DcBusOverVoltage_V.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDFM_DcBusOverVoltage_V.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDFM_DcBusOverVoltage_V.DocUnits = 'V';

KfMDFM_DcBusUnderVoltage_V = mpt.Parameter;
KfMDFM_DcBusUnderVoltage_V.Value = ...
    single(0.5 * YMBOX_Drive_Config.Inverter.NominalDcBus_V);
if isfinite(YMBOX_Drive_Config.Protection.DcBusUnderVoltage_V)
    KfMDFM_DcBusUnderVoltage_V.Value = single(YMBOX_Drive_Config.Protection.DcBusUnderVoltage_V);
end
KfMDFM_DcBusUnderVoltage_V.DataType = 'single';
KfMDFM_DcBusUnderVoltage_V.StorageClass = 'Const (Custom)';
KfMDFM_DcBusUnderVoltage_V.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDFM_DcBusUnderVoltage_V.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDFM_DcBusUnderVoltage_V.DocUnits = 'V';

% MDFM publishes the instantaneous voltage envelope used by modulation.
% This is deliberately separate from the qualified and latched over/under
% voltage fault policy below.
KfMDFM_DcBusOperationalMin_V = mpt.Parameter;
KfMDFM_DcBusOperationalMin_V.Value = single( ...
    YMBOX_Drive_Config.Inverter.MinValidDcBus_V);
KfMDFM_DcBusOperationalMin_V.DataType = 'single';
KfMDFM_DcBusOperationalMin_V.StorageClass = 'Const (Custom)';
KfMDFM_DcBusOperationalMin_V.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDFM_DcBusOperationalMin_V.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDFM_DcBusOperationalMin_V.DocUnits = 'V';

KfMDFM_DcBusOperationalMax_V = mpt.Parameter;
KfMDFM_DcBusOperationalMax_V.Value = single( ...
    YMBOX_Drive_Config.Inverter.MaxDcBus_V);
KfMDFM_DcBusOperationalMax_V.DataType = 'single';
KfMDFM_DcBusOperationalMax_V.StorageClass = 'Const (Custom)';
KfMDFM_DcBusOperationalMax_V.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDFM_DcBusOperationalMax_V.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDFM_DcBusOperationalMax_V.DocUnits = 'V';

% Time-normalized form of VESC's excess-voltage accumulator. For the
% reference 10-ms monitor, 5 percent of the over-voltage threshold becomes
% 0.0005 * threshold V*s (28.8 ms for a continuous 1-V violation at the
% default 57.6-V over-voltage threshold).
KfMDFM_VoltageViolationArea_Vs = mpt.Parameter;
KfMDFM_VoltageViolationArea_Vs.Value = ...
    single(5.0e-4 * double(KfMDFM_DcBusOverVoltage_V.Value));
if isfinite(YMBOX_Drive_Config.Protection.VoltageViolationArea_Vs)
    KfMDFM_VoltageViolationArea_Vs.Value = single(YMBOX_Drive_Config.Protection.VoltageViolationArea_Vs);
end
KfMDFM_VoltageViolationArea_Vs.DataType = 'single';
KfMDFM_VoltageViolationArea_Vs.StorageClass = 'Const (Custom)';
KfMDFM_VoltageViolationArea_Vs.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDFM_VoltageViolationArea_Vs.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDFM_VoltageViolationArea_Vs.DocUnits = 'V*s';

KfMDFM_VoltageRecoveryRate_V = mpt.Parameter;
KfMDFM_VoltageRecoveryRate_V.Value = single(YMBOX_Drive_Config.Protection.VoltageRecoveryRate_V);
KfMDFM_VoltageRecoveryRate_V.DataType = 'single';
KfMDFM_VoltageRecoveryRate_V.StorageClass = 'Const (Custom)';
KfMDFM_VoltageRecoveryRate_V.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDFM_VoltageRecoveryRate_V.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDFM_VoltageRecoveryRate_V.DocUnits = 'V';

KfMDFM_PhaseSoftwareOverCurrent_A = mpt.Parameter;
KfMDFM_PhaseSoftwareOverCurrent_A.Value = single( ...
    YMBOX_Drive_Derived.Constraint.SoftwareOverCurrent_A);
KfMDFM_PhaseSoftwareOverCurrent_A.DataType = 'single';
KfMDFM_PhaseSoftwareOverCurrent_A.StorageClass = 'Const (Custom)';
KfMDFM_PhaseSoftwareOverCurrent_A.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDFM_PhaseSoftwareOverCurrent_A.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDFM_PhaseSoftwareOverCurrent_A.DocUnits = 'A';

KuMDFM_PhaseSoftwareOverCurrentConfirm_cnt = mpt.Parameter;
KuMDFM_PhaseSoftwareOverCurrentConfirm_cnt.Value = uint16( ...
    YMBOX_Drive_Derived.Constraint.SoftwareOverCurrentConfirmCount);
KuMDFM_PhaseSoftwareOverCurrentConfirm_cnt.DataType = 'uint16';
KuMDFM_PhaseSoftwareOverCurrentConfirm_cnt.StorageClass = 'Const (Custom)';
KuMDFM_PhaseSoftwareOverCurrentConfirm_cnt.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KuMDFM_PhaseSoftwareOverCurrentConfirm_cnt.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KuMDFM_PhaseSoftwareOverCurrentConfirm_cnt.DocUnits = 'cnt';

KfMDFM_ClearHold_s = mpt.Parameter;
KfMDFM_ClearHold_s.Value = single(YMBOX_Drive_Config.Protection.FaultClearHold_s);
KfMDFM_ClearHold_s.DataType = 'single';
KfMDFM_ClearHold_s.StorageClass = 'Const (Custom)';
KfMDFM_ClearHold_s.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDFM_ClearHold_s.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDFM_ClearHold_s.DocUnits = 's';

KuMDFM_ClearHold_cnt = mpt.Parameter;
KuMDFM_ClearHold_cnt.Value = uint32(max(1, ceil( ...
    double(KfMDFM_ClearHold_s.Value) / double(Cf_CONTROL_TASK_TIME_S))));
KuMDFM_ClearHold_cnt.DataType = 'uint32';
KuMDFM_ClearHold_cnt.StorageClass = 'Const (Custom)';
KuMDFM_ClearHold_cnt.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KuMDFM_ClearHold_cnt.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KuMDFM_ClearHold_cnt.DocUnits = 'cnt';

% The communication adapter increments a uint16 alive counter for every
% accepted command frame. While MCU enable is active, MDFM supervises the
% counter immediately and qualifies an unchanged value as a timeout in
% control-task time, independent of bus bit rate.
KfMDFM_CommandTimeout_s = mpt.Parameter;
KfMDFM_CommandTimeout_s.Value = single(YMBOX_Drive_Config.Protection.CommandTimeout_s);
KfMDFM_CommandTimeout_s.DataType = 'single';
KfMDFM_CommandTimeout_s.StorageClass = 'Const (Custom)';
KfMDFM_CommandTimeout_s.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDFM_CommandTimeout_s.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDFM_CommandTimeout_s.DocUnits = 's';

KuMDFM_CommandTimeout_cnt = mpt.Parameter;
KuMDFM_CommandTimeout_cnt.Value = uint32(max(1, round( ...
    double(KfMDFM_CommandTimeout_s.Value) / ...
    double(Cf_CONTROL_TASK_TIME_S))));
KuMDFM_CommandTimeout_cnt.DataType = 'uint32';
KuMDFM_CommandTimeout_cnt.StorageClass = 'Const (Custom)';
KuMDFM_CommandTimeout_cnt.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KuMDFM_CommandTimeout_cnt.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KuMDFM_CommandTimeout_cnt.DocUnits = 'cnt';

% Reserved internal hardware-detail codes. Incoming board codes retain
% priority; these codes identify application-layer signal qualification.
KuMDFM_DcBusVoltageInvalidDetail_code = mpt.Parameter;
KuMDFM_DcBusVoltageInvalidDetail_code.Value = uint16(61441); % 0xF001
KuMDFM_DcBusVoltageInvalidDetail_code.DataType = 'uint16';
KuMDFM_DcBusVoltageInvalidDetail_code.StorageClass = 'Const (Custom)';
KuMDFM_DcBusVoltageInvalidDetail_code.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KuMDFM_DcBusVoltageInvalidDetail_code.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KuMDFM_DcBusVoltageInvalidDetail_code.DocUnits = '';

KuMDFM_DcBusCurrentInvalidDetail_code = mpt.Parameter;
KuMDFM_DcBusCurrentInvalidDetail_code.Value = uint16(61442); % 0xF002
KuMDFM_DcBusCurrentInvalidDetail_code.DataType = 'uint16';
KuMDFM_DcBusCurrentInvalidDetail_code.StorageClass = 'Const (Custom)';
KuMDFM_DcBusCurrentInvalidDetail_code.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KuMDFM_DcBusCurrentInvalidDetail_code.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KuMDFM_DcBusCurrentInvalidDetail_code.DocUnits = '';

KuMDFM_DcBusCurrentHardDetail_code = mpt.Parameter;
KuMDFM_DcBusCurrentHardDetail_code.Value = uint16(61443); % 0xF003
KuMDFM_DcBusCurrentHardDetail_code.DataType = 'uint16';
KuMDFM_DcBusCurrentHardDetail_code.StorageClass = 'Const (Custom)';
KuMDFM_DcBusCurrentHardDetail_code.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KuMDFM_DcBusCurrentHardDetail_code.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KuMDFM_DcBusCurrentHardDetail_code.DocUnits = '';

VfMDFM_DCBusCurrentRaw_A = Simulink.Signal;
VfMDFM_DCBusCurrentRaw_A.RTWInfo.StorageClass = 'ExportedGlobal';
VfMDFM_DCBusCurrentRaw_A.DataType = 'single';
VfMDFM_DCBusCurrentRaw_A.Description = ...
    'Selected unfiltered DC-bus current for diagnostics and hard-limit checks';
VfMDFM_DCBusCurrentRaw_A.DocUnits = 'A';

VfMDFM_DCBusCurrentSoft_A = Simulink.Signal;
VfMDFM_DCBusCurrentSoft_A.RTWInfo.StorageClass = 'ExportedGlobal';
VfMDFM_DCBusCurrentSoft_A.DataType = 'single';
VfMDFM_DCBusCurrentSoft_A.Description = ...
    'Configured moving average for soft limiting and communication only';
VfMDFM_DCBusCurrentSoft_A.DocUnits = 'A';

VbMDFM_DCBusCurrentValid_flg = Simulink.Signal;
VbMDFM_DCBusCurrentValid_flg.RTWInfo.StorageClass = 'ExportedGlobal';
VbMDFM_DCBusCurrentValid_flg.DataType = 'boolean';
VbMDFM_DCBusCurrentValid_flg.Description = ...
    'Selected DC-bus current source is finite and plausible';
VbMDFM_DCBusCurrentValid_flg.DocUnits = 'flg';

VbMDFM_DCBusCurrentHardFault_flg = Simulink.Signal;
VbMDFM_DCBusCurrentHardFault_flg.RTWInfo.StorageClass = 'ExportedGlobal';
VbMDFM_DCBusCurrentHardFault_flg.DataType = 'boolean';
VbMDFM_DCBusCurrentHardFault_flg.Description = ...
    'Unfiltered selected DC-bus current exceeds the configured software hard limit';
VbMDFM_DCBusCurrentHardFault_flg.DocUnits = 'flg';

VuMDFM_DCBusCurrentSource_enum = Simulink.Signal;
VuMDFM_DCBusCurrentSource_enum.RTWInfo.StorageClass = 'ExportedGlobal';
VuMDFM_DCBusCurrentSource_enum.DataType = 'uint8';
VuMDFM_DCBusCurrentSource_enum.Description = ...
    'Active DC-bus current source: 0=physical, 1=estimated';
VuMDFM_DCBusCurrentSource_enum.DocUnits = 'enum';

VfMDFM_DCBusVoltReport_V = Simulink.Signal;
VfMDFM_DCBusVoltReport_V.RTWInfo.StorageClass = 'ExportedGlobal';
VfMDFM_DCBusVoltReport_V.DataType = 'single';
VfMDFM_DCBusVoltReport_V.Description = ...
    'Slow DC-bus voltage path intended for telemetry and plots';
VfMDFM_DCBusVoltReport_V.DocUnits = 'V';

VbMDFM_VoltageOperationalValid_flg = Simulink.Signal;
VbMDFM_VoltageOperationalValid_flg.RTWInfo.StorageClass = 'ExportedGlobal';
VbMDFM_VoltageOperationalValid_flg.DataType = 'boolean';
VbMDFM_VoltageOperationalValid_flg.Description = ...
    'Instantaneous control-voltage envelope permission for modulation';
VbMDFM_VoltageOperationalValid_flg.DocUnits = 'flg';

VbMDFM_PhaseSoftwareOverCurrent_flg = Simulink.Signal;
VbMDFM_PhaseSoftwareOverCurrent_flg.RTWInfo.StorageClass = 'ExportedGlobal';
VbMDFM_PhaseSoftwareOverCurrent_flg.DataType = 'boolean';
VbMDFM_PhaseSoftwareOverCurrent_flg.Description = ...
    'Qualified maximum absolute U/V/W phase-current fault';
VbMDFM_PhaseSoftwareOverCurrent_flg.DocUnits = 'flg';

VbMDFM_DqSoftwareOverCurrent_flg = Simulink.Signal;
VbMDFM_DqSoftwareOverCurrent_flg.RTWInfo.StorageClass = 'ExportedGlobal';
VbMDFM_DqSoftwareOverCurrent_flg.DataType = 'boolean';
VbMDFM_DqSoftwareOverCurrent_flg.Description = ...
    'MDFM-consumed dq current-magnitude fault from MDCC';
VbMDFM_DqSoftwareOverCurrent_flg.DocUnits = 'flg';
