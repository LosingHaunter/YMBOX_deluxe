% Range validation belongs to the configuration calculator and import checks.
% Leave data-object Min/Max unspecified; runtime limits use configured values.
% Sensorless supervisor counts are calculated once by the centralized eSMO
% profile and consumed here without fallback re-resolution.
assert(exist('YMBOX_SMO_Derived','var') && ...
    isstruct(YMBOX_SMO_Derived), ...
    'YMBOX:Initialization:MissingSmoDerived', ...
    'Run YMBOX_InitializeModel before MDSM_Model_Library.');

KuMDSM_ObserverLossConfirmCnt = mpt.Parameter;
KuMDSM_ObserverLossConfirmCnt.Value = ...
    YMBOX_SMO_Derived.ObserverLossConfirmCount;
KuMDSM_ObserverLossConfirmCnt.DataType = 'uint32';
KuMDSM_ObserverLossConfirmCnt.StorageClass = 'Const (Custom)';
KuMDSM_ObserverLossConfirmCnt.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KuMDSM_ObserverLossConfirmCnt.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KuMDSM_ObserverLossConfirmCnt.DocUnits = 'cnt';

% Acquisition-state dwell after direct observer pickup.  Speed PI reset is
% only one tick for bumpless command-ramp seeding.  The current PI is kept
% active because the V7 angle and physical-current-vector paths are continuous.
KuMDSM_DirectHandoverCnt = mpt.Parameter;
KuMDSM_DirectHandoverCnt.Value = ...
    YMBOX_SMO_Derived.DirectHandoverDwellCount;
KuMDSM_DirectHandoverCnt.DataType = 'uint32';
KuMDSM_DirectHandoverCnt.StorageClass = 'Const (Custom)';
KuMDSM_DirectHandoverCnt.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KuMDSM_DirectHandoverCnt.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KuMDSM_DirectHandoverCnt.DocUnits = 'cnt';

% Covers alignment, the 1200-rpm/s I/F ramp to the highest 2000-rpm
% observer acquisition threshold, and the 100-ms qualification window.
% The former 3-s value expired before a direct SMO/BEMF/LEO route could
% physically reach its acquisition speed.
KuMDSM_IFStartupTimeoutCnt = mpt.Parameter;
KuMDSM_IFStartupTimeoutCnt.Value = YMBOX_SMO_Derived.StartupTimeoutCount;
KuMDSM_IFStartupTimeoutCnt.DataType = 'uint32';
KuMDSM_IFStartupTimeoutCnt.StorageClass = 'Const (Custom)';
KuMDSM_IFStartupTimeoutCnt.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KuMDSM_IFStartupTimeoutCnt.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KuMDSM_IFStartupTimeoutCnt.DocUnits = 'cnt';

VeMDSM_DrvModeCmd_enum = Simulink.Signal;
VeMDSM_DrvModeCmd_enum.RTWInfo.StorageClass = 'ExportedGlobal';
VeMDSM_DrvModeCmd_enum.DataType = 'uint16';
VeMDSM_DrvModeCmd_enum.DocUnits = 'enum';
VeMDSM_DrvModeCmd_enum.Description = ...
    'Internal MDSM command: public 0..5 or sensorless stage 16..17';

VeMDSM_DrvModeReq_enum = Simulink.Signal;
VeMDSM_DrvModeReq_enum.RTWInfo.StorageClass = 'ExportedGlobal';
VeMDSM_DrvModeReq_enum.DataType = 'uint16';
VeMDSM_DrvModeReq_enum.DocUnits = 'enum';
VeMDSM_DrvModeReq_enum.Description = ...
    'Public drive-mode request interface, 0..10; values 7..10 reserved';

VbMDTM_PiReset_flg = Simulink.Signal;
VbMDTM_PiReset_flg.RTWInfo.StorageClass = 'ExportedGlobal';
VbMDTM_PiReset_flg.DataType = 'boolean';
VbMDTM_PiReset_flg.DocUnits = 'flg';

VbMDCC_PiReset_flg = Simulink.Signal;
VbMDCC_PiReset_flg.RTWInfo.StorageClass = 'ExportedGlobal';
VbMDCC_PiReset_flg.DataType = 'boolean';
VbMDCC_PiReset_flg.DocUnits = 'flg';

VeMDFM_FFEnable_enum = Simulink.Signal;
VeMDFM_FFEnable_enum.RTWInfo.StorageClass = 'ExportedGlobal';
VeMDFM_FFEnable_enum.DataType = 'uint8';
VeMDFM_FFEnable_enum.DocUnits = 'enum';

VfMDSM_TestUaUdId_NULL = Simulink.Signal;
VfMDSM_TestUaUdId_NULL.RTWInfo.StorageClass = 'ExportedGlobal';
VfMDSM_TestUaUdId_NULL.DataType = 'single';
VfMDSM_TestUaUdId_NULL.DocUnits = 'NULL';

VfMDSM_TestUbUqIq_NULL = Simulink.Signal;
VfMDSM_TestUbUqIq_NULL.RTWInfo.StorageClass = 'ExportedGlobal';
VfMDSM_TestUbUqIq_NULL.DataType = 'single';
VfMDSM_TestUbUqIq_NULL.DocUnits = 'NULL';

VfMDSM_TrgtTq_Nm = Simulink.Signal;
VfMDSM_TrgtTq_Nm.RTWInfo.StorageClass = 'ExportedGlobal';
VfMDSM_TrgtTq_Nm.DataType = 'single';
VfMDSM_TrgtTq_Nm.DocUnits = 'Nm';

VfMDSM_TrgtSpd_rpm = Simulink.Signal;
VfMDSM_TrgtSpd_rpm.RTWInfo.StorageClass = 'ExportedGlobal';
VfMDSM_TrgtSpd_rpm.DataType = 'single';
VfMDSM_TrgtSpd_rpm.DocUnits = 'rpm';
