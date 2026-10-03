% Range validation belongs to the configuration calculator and import checks.
% Leave data-object Min/Max unspecified; runtime limits use configured values.
VMIN_Dir_DCBusVolt_V = Simulink.Signal;
VMIN_Dir_DCBusVolt_V.RTWInfo.StorageClass = 'ExportedGlobal';
VMIN_Dir_DCBusVolt_V.DataType = 'single';
% The board adapter supplies calibrated engineering units. Keep the raw
% voltage range open so generated code retains the sensor-range checks.
VMIN_Dir_DCBusVolt_V.DocUnits = 'V';
VMIN_Dir_DCBusVolt_V.InitialValue = '0';

VMIN_Dir_DCBusCur_A = Simulink.Signal;
VMIN_Dir_DCBusCur_A.RTWInfo.StorageClass = 'ExportedGlobal';
VMIN_Dir_DCBusCur_A.DataType = 'single';
VMIN_Dir_DCBusCur_A.DocUnits = 'A';
VMIN_Dir_DCBusCur_A.InitialValue = '0';

VMIN_Dir_ResolverPosition_NULL = Simulink.Signal;
VMIN_Dir_ResolverPosition_NULL.RTWInfo.StorageClass = 'ExportedGlobal';
VMIN_Dir_ResolverPosition_NULL.DataType = 'uint32';
VMIN_Dir_ResolverPosition_NULL.DocUnits = 'NULL';
VMIN_Dir_ResolverPosition_NULL.InitialValue = '0';

VMIN_Dir_TestUaUdId_NULL = Simulink.Signal;
VMIN_Dir_TestUaUdId_NULL.RTWInfo.StorageClass = 'ExportedGlobal';
VMIN_Dir_TestUaUdId_NULL.DataType = 'single';
% Mode-dependent test command: volts in modes 1/2, amps in mode 3.
VMIN_Dir_TestUaUdId_NULL.DocUnits = '';
VMIN_Dir_TestUaUdId_NULL.InitialValue = '0';

VMIN_Dir_TestUbUqIq_NULL = Simulink.Signal;
VMIN_Dir_TestUbUqIq_NULL.RTWInfo.StorageClass = 'ExportedGlobal';
VMIN_Dir_TestUbUqIq_NULL.DataType = 'single';
VMIN_Dir_TestUbUqIq_NULL.DocUnits = '';
VMIN_Dir_TestUbUqIq_NULL.InitialValue = '0';

VMIN_Dir_UCurSenrCurDet_A = Simulink.Signal;
VMIN_Dir_UCurSenrCurDet_A.RTWInfo.StorageClass = 'ExportedGlobal';
VMIN_Dir_UCurSenrCurDet_A.DataType = 'single';
VMIN_Dir_UCurSenrCurDet_A.DocUnits = 'A';
VMIN_Dir_UCurSenrCurDet_A.InitialValue = '0';

VMIN_Dir_VCurSenrCurDet_A = Simulink.Signal;
VMIN_Dir_VCurSenrCurDet_A.RTWInfo.StorageClass = 'ExportedGlobal';
VMIN_Dir_VCurSenrCurDet_A.DataType = 'single';
VMIN_Dir_VCurSenrCurDet_A.DocUnits = 'A';
VMIN_Dir_VCurSenrCurDet_A.InitialValue = '0';

VMIN_Dir_WCurSenrCurDet_A = Simulink.Signal;
VMIN_Dir_WCurSenrCurDet_A.RTWInfo.StorageClass = 'ExportedGlobal';
VMIN_Dir_WCurSenrCurDet_A.DataType = 'single';
VMIN_Dir_WCurSenrCurDet_A.DocUnits = 'A';
VMIN_Dir_WCurSenrCurDet_A.InitialValue = '0';

VMIN_Dir_UCurSenrCurErr_NULL = Simulink.Signal;
VMIN_Dir_UCurSenrCurErr_NULL.RTWInfo.StorageClass = 'ExportedGlobal';
VMIN_Dir_UCurSenrCurErr_NULL.DataType = 'boolean';
VMIN_Dir_UCurSenrCurErr_NULL.DocUnits = 'NULL';
VMIN_Dir_UCurSenrCurErr_NULL.InitialValue = '0';

VMIN_Dir_VCurSenrCurErr_NULL = Simulink.Signal;
VMIN_Dir_VCurSenrCurErr_NULL.RTWInfo.StorageClass = 'ExportedGlobal';
VMIN_Dir_VCurSenrCurErr_NULL.DataType = 'boolean';
VMIN_Dir_VCurSenrCurErr_NULL.DocUnits = 'NULL';
VMIN_Dir_VCurSenrCurErr_NULL.InitialValue = '0';

VMIN_Dir_WCurSenrCurErr_NULL = Simulink.Signal;
VMIN_Dir_WCurSenrCurErr_NULL.RTWInfo.StorageClass = 'ExportedGlobal';
VMIN_Dir_WCurSenrCurErr_NULL.DataType = 'boolean';
VMIN_Dir_WCurSenrCurErr_NULL.DocUnits = 'NULL';
VMIN_Dir_WCurSenrCurErr_NULL.InitialValue = '0';

% Board adapter fault contract. The platform layer must still perform any
% asynchronous hardware shutdown; these signals report the latched hardware
% condition to the board-independent application fault manager.
VMIN_Dir_HwFaultActive_flg = Simulink.Signal;
VMIN_Dir_HwFaultActive_flg.RTWInfo.StorageClass = 'ExportedGlobal';
VMIN_Dir_HwFaultActive_flg.DataType = 'boolean';
VMIN_Dir_HwFaultActive_flg.DocUnits = 'flg';
VMIN_Dir_HwFaultActive_flg.InitialValue = '0';

VMIN_Dir_HwFaultCode_enum = Simulink.Signal;
VMIN_Dir_HwFaultCode_enum.RTWInfo.StorageClass = 'ExportedGlobal';
VMIN_Dir_HwFaultCode_enum.DataType = 'uint16';
VMIN_Dir_HwFaultCode_enum.DocUnits = 'enum';
VMIN_Dir_HwFaultCode_enum.InitialValue = '0';

% Extensible platform-diagnostic contract. The board adapter maps concrete
% gate-driver, thermal, power-supply, watchdog, and sensor conditions into
% these detail masks. MDFM keeps the board-specific bits for diagnostics and
% applies one stable application-level fault/action policy.
VMIN_Dir_PlatformFaultMask_u32 = Simulink.Signal;
VMIN_Dir_PlatformFaultMask_u32.RTWInfo.StorageClass = 'ExportedGlobal';
VMIN_Dir_PlatformFaultMask_u32.DataType = 'uint32';
VMIN_Dir_PlatformFaultMask_u32.DocUnits = 'NULL';
VMIN_Dir_PlatformFaultMask_u32.InitialValue = '0';

VMIN_Dir_PlatformWarningMask_u32 = Simulink.Signal;
VMIN_Dir_PlatformWarningMask_u32.RTWInfo.StorageClass = 'ExportedGlobal';
VMIN_Dir_PlatformWarningMask_u32.DataType = 'uint32';
VMIN_Dir_PlatformWarningMask_u32.DocUnits = 'NULL';
VMIN_Dir_PlatformWarningMask_u32.InitialValue = '0';

VMIN_Dir_PlatformTorqueLimitFactor_NULL = Simulink.Signal;
VMIN_Dir_PlatformTorqueLimitFactor_NULL.RTWInfo.StorageClass = ...
    'ExportedGlobal';
VMIN_Dir_PlatformTorqueLimitFactor_NULL.DataType = 'single';
VMIN_Dir_PlatformTorqueLimitFactor_NULL.DocUnits = 'NULL';
VMIN_Dir_PlatformTorqueLimitFactor_NULL.InitialValue = '1';
