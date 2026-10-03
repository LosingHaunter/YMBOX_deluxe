% Range validation belongs to the configuration calculator and import checks.
% Leave data-object Min/Max unspecified; runtime limits use configured values.
% Consume the resolved drive context published by YMBOX_InitializeModel.
assert(exist('YMBOX_Drive_Config','var') && isstruct(YMBOX_Drive_Config), ...
    'YMBOX:Initialization:MissingDriveConfig', ...
    'Run YMBOX_InitializeModel before MDSP_Model_Library.');

dcBusCfg = YMBOX_Drive_Config.DcBusMeasurement;

% Compile-time source selection for the MDSP DC-bus current path:
%   0 = board-provided physical sensor
%   1 = estimate from final PWM duties and measured phase currents
KuMDSP_DCBusCurSource_enum = Simulink.Parameter;
KuMDSP_DCBusCurSource_enum.Value = uint8(dcBusCfg.CurrentSource_enum);
KuMDSP_DCBusCurSource_enum.DataType = 'uint8';
KuMDSP_DCBusCurSource_enum.CoderInfo.StorageClass = 'Auto';
KuMDSP_DCBusCurSource_enum.Description = ...
    'MDSP DC-bus current source Variant: 0=physical sensor, 1=duty/current estimate';

KfMDSP_DCBusCurPlausibleMax_A = mpt.Parameter;
KfMDSP_DCBusCurPlausibleMax_A.Value = single( ...
    dcBusCfg.CurrentPlausibleMax_A);
KfMDSP_DCBusCurPlausibleMax_A.DataType = 'single';
KfMDSP_DCBusCurPlausibleMax_A.StorageClass = 'Const (Custom)';
KfMDSP_DCBusCurPlausibleMax_A.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDSP_DCBusCurPlausibleMax_A.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDSP_DCBusCurPlausibleMax_A.DocUnits = 'A';

KfMDSP_DCBusVoltControlFilterAlpha_NULL = mpt.Parameter;
KfMDSP_DCBusVoltControlFilterAlpha_NULL.Value = ...
    single(dcBusCfg.VoltageControlFilterAlpha_NULL);
KfMDSP_DCBusVoltControlFilterAlpha_NULL.DataType = 'single';
KfMDSP_DCBusVoltControlFilterAlpha_NULL.StorageClass = 'Const (Custom)';
KfMDSP_DCBusVoltControlFilterAlpha_NULL.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDSP_DCBusVoltControlFilterAlpha_NULL.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDSP_DCBusVoltControlFilterAlpha_NULL.DocUnits = '1';

KfMDSP_DCBusVoltReportFilterAlpha_NULL = mpt.Parameter;
KfMDSP_DCBusVoltReportFilterAlpha_NULL.Value = ...
    single(dcBusCfg.VoltageReportFilterAlpha_NULL);
KfMDSP_DCBusVoltReportFilterAlpha_NULL.DataType = 'single';
KfMDSP_DCBusVoltReportFilterAlpha_NULL.StorageClass = 'Const (Custom)';
KfMDSP_DCBusVoltReportFilterAlpha_NULL.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDSP_DCBusVoltReportFilterAlpha_NULL.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDSP_DCBusVoltReportFilterAlpha_NULL.DocUnits = '1';

KbMDSP_DCBusVoltReportFilterEnable_flg = mpt.Parameter;
KbMDSP_DCBusVoltReportFilterEnable_flg.Value = ...
    logical(dcBusCfg.VoltageReportFilterEnable);
KbMDSP_DCBusVoltReportFilterEnable_flg.DataType = 'boolean';
KbMDSP_DCBusVoltReportFilterEnable_flg.StorageClass = 'Const (Custom)';
KbMDSP_DCBusVoltReportFilterEnable_flg.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KbMDSP_DCBusVoltReportFilterEnable_flg.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KbMDSP_DCBusVoltReportFilterEnable_flg.DocUnits = 'flg';

KfMDSP_DCBusVoltPlausibleMin_V = mpt.Parameter;
KfMDSP_DCBusVoltPlausibleMin_V.Value = ...
    single(dcBusCfg.VoltagePlausibleMin_V);
KfMDSP_DCBusVoltPlausibleMin_V.DataType = 'single';
KfMDSP_DCBusVoltPlausibleMin_V.StorageClass = 'Const (Custom)';
KfMDSP_DCBusVoltPlausibleMin_V.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDSP_DCBusVoltPlausibleMin_V.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDSP_DCBusVoltPlausibleMin_V.DocUnits = 'V';

KfMDSP_DCBusVoltInitMin_V = mpt.Parameter;
KfMDSP_DCBusVoltInitMin_V.Value = ...
    single(YMBOX_Drive_Config.Inverter.MinValidDcBus_V);
KfMDSP_DCBusVoltInitMin_V.DataType = 'single';
KfMDSP_DCBusVoltInitMin_V.StorageClass = 'Const (Custom)';
KfMDSP_DCBusVoltInitMin_V.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDSP_DCBusVoltInitMin_V.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDSP_DCBusVoltInitMin_V.DocUnits = 'V';

KfMDSP_DCBusVoltPlausibleMax_V = mpt.Parameter;
KfMDSP_DCBusVoltPlausibleMax_V.Value = ...
    single(dcBusCfg.VoltagePlausibleMaxFactor_NULL) * ...
    single(YMBOX_Drive_Config.Inverter.MaxDcBus_V);
KfMDSP_DCBusVoltPlausibleMax_V.DataType = 'single';
KfMDSP_DCBusVoltPlausibleMax_V.StorageClass = 'Const (Custom)';
KfMDSP_DCBusVoltPlausibleMax_V.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDSP_DCBusVoltPlausibleMax_V.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDSP_DCBusVoltPlausibleMax_V.DocUnits = 'V';

% Structural parameter for the Sliding Window Moving Average block. Keep it
% Auto/inlined because it sizes generated filter state and is not run-time
% tunable. The application-layer source of truth remains YMBOX_Drive_Config.
KfMDSP_DCBusCurAvgWindow_cnt = Simulink.Parameter;
KfMDSP_DCBusCurAvgWindow_cnt.Value = single( ...
    dcBusCfg.CurrentInputMovingAverageWindowSamples);
KfMDSP_DCBusCurAvgWindow_cnt.DataType = 'single';
KfMDSP_DCBusCurAvgWindow_cnt.CoderInfo.StorageClass = 'Auto';
KfMDSP_DCBusCurAvgWindow_cnt.Description = ...
    'Compile-time MDSP selected DC-bus-current moving-average window';

% MDSP-owned published signals. Signal labels in YMBOX_Control_Core.slx use
% these objects so generated interfaces retain the same type/unit contract as
% the MDSP_output and Resolver_Output bus elements.
VuMDSP_MotEAngle_NULL = Simulink.Signal;
VuMDSP_MotEAngle_NULL.RTWInfo.StorageClass = 'ExportedGlobal';
VuMDSP_MotEAngle_NULL.DataType = 'uint16';
VuMDSP_MotEAngle_NULL.Description = ...
    'Wrapped electrical rotor position in the control-angle count domain';
VuMDSP_MotEAngle_NULL.DocUnits = 'NULL';

VuMDSP_MotMechAngleRaw_NULL = Simulink.Signal;
VuMDSP_MotMechAngleRaw_NULL.RTWInfo.StorageClass = 'ExportedGlobal';
VuMDSP_MotMechAngleRaw_NULL.DataType = 'uint32';
VuMDSP_MotMechAngleRaw_NULL.Description = ...
    'Unmodified native mechanical resolver-position count';
VuMDSP_MotMechAngleRaw_NULL.DocUnits = 'NULL';

VfMDSP_DCBusCur_Filtered_A = Simulink.Signal;
VfMDSP_DCBusCur_Filtered_A.RTWInfo.StorageClass = 'ExportedGlobal';
VfMDSP_DCBusCur_Filtered_A.DataType = 'single';
VfMDSP_DCBusCur_Filtered_A.Description = ...
    'Validity-qualified moving-average DC-bus current';
VfMDSP_DCBusCur_Filtered_A.DocUnits = 'A';

VfMDSP_DCBusVoltCtrl_V = Simulink.Signal;
VfMDSP_DCBusVoltCtrl_V.RTWInfo.StorageClass = 'ExportedGlobal';
VfMDSP_DCBusVoltCtrl_V.DataType = 'single';
VfMDSP_DCBusVoltCtrl_V.Description = ...
    'Validity-qualified filtered DC-bus voltage for control algorithms';
VfMDSP_DCBusVoltCtrl_V.DocUnits = 'V';

VfMDSP_DCBusVoltRaw_V = Simulink.Signal;
VfMDSP_DCBusVoltRaw_V.RTWInfo.StorageClass = 'ExportedGlobal';
VfMDSP_DCBusVoltRaw_V.DataType = 'single';
VfMDSP_DCBusVoltRaw_V.Description = ...
    'Unfiltered and unclamped DC-bus voltage';
VfMDSP_DCBusVoltRaw_V.DocUnits = 'V';

VfMDSP_DCBusVoltReport_V = Simulink.Signal;
VfMDSP_DCBusVoltReport_V.RTWInfo.StorageClass = 'ExportedGlobal';
VfMDSP_DCBusVoltReport_V.DataType = 'single';
VfMDSP_DCBusVoltReport_V.Description = ...
    'Report-path filtered DC-bus voltage';
VfMDSP_DCBusVoltReport_V.DocUnits = 'V';

VbMDSP_DCBusVoltValid_flg = Simulink.Signal;
VbMDSP_DCBusVoltValid_flg.RTWInfo.StorageClass = 'ExportedGlobal';
VbMDSP_DCBusVoltValid_flg.DataType = 'boolean';
VbMDSP_DCBusVoltValid_flg.Description = ...
    'Raw DC-bus voltage is inside the configured plausibility range';
VbMDSP_DCBusVoltValid_flg.DocUnits = 'flg';

VfMDSP_DCBusCurRaw_A = Simulink.Signal;
VfMDSP_DCBusCurRaw_A.RTWInfo.StorageClass = 'ExportedGlobal';
VfMDSP_DCBusCurRaw_A.DataType = 'single';
VfMDSP_DCBusCurRaw_A.Description = ...
    'Selected unfiltered DC-bus current before validity hold and averaging';
VfMDSP_DCBusCurRaw_A.DocUnits = 'A';

VbMDSP_DCBusCurValid_flg = Simulink.Signal;
VbMDSP_DCBusCurValid_flg.RTWInfo.StorageClass = 'ExportedGlobal';
VbMDSP_DCBusCurValid_flg.DataType = 'boolean';
VbMDSP_DCBusCurValid_flg.Description = ...
    'Selected DC-bus current source is valid and plausible';
VbMDSP_DCBusCurValid_flg.DocUnits = 'flg';

VuMDSP_DCBusCurSource_enum = Simulink.Signal;
VuMDSP_DCBusCurSource_enum.RTWInfo.StorageClass = 'ExportedGlobal';
VuMDSP_DCBusCurSource_enum.DataType = 'uint8';
VuMDSP_DCBusCurSource_enum.Description = ...
    'Active DC-bus current source: 0=physical sensor, 1=FOC estimate';
VuMDSP_DCBusCurSource_enum.DocUnits = 'enum';

clear dcBusCfg;
