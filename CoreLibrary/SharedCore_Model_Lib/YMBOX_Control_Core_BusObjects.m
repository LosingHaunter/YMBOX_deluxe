function YMBOX_Control_Core_BusObjects()
% YMBOX_CONTROL_CORE_BUSOBJECTS initializes a set of bus objects in the MATLAB base workspace

modeId = YMBOX_DriveModeDefinitions();

% Bus object: Direct_Output
clear elems;
elems(1) = Simulink.BusElement;
elems(1).Name = 'VMIN_ECAN_MCUEnb_flg';
elems(1).Dimensions = 1;
elems(1).DimensionsMode = 'Fixed';
elems(1).DataType = 'boolean';
elems(1).Complexity = 'real';
elems(1).Min = [];
elems(1).Max = [];
elems(1).DocUnits = '';
elems(1).Description = '';

elems(2) = Simulink.BusElement;
elems(2).Name = 'VMIN_ECAN_MotWrkMd_enum';
elems(2).Dimensions = 1;
elems(2).DimensionsMode = 'Fixed';
elems(2).DataType = 'uint16';
elems(2).Complexity = 'real';
elems(2).Min = double(modeId.PublicMinimum);
elems(2).Max = double(modeId.PublicMaximum);
elems(2).DocUnits = '';
elems(2).Description = ...
    'Public drive-mode request interface, 0..10; values 7..10 reserved';

elems(3) = Simulink.BusElement;
elems(3).Name = 'VMIN_ECAN_MotTrgtSpd_rpm';
elems(3).Dimensions = 1;
elems(3).DimensionsMode = 'Fixed';
elems(3).DataType = 'single';
elems(3).Complexity = 'real';
elems(3).Min = [];
elems(3).Max = [];
elems(3).DocUnits = '';
elems(3).Description = '';

elems(4) = Simulink.BusElement;
elems(4).Name = 'VMIN_ECAN_MotTrgtTq_Nm';
elems(4).Dimensions = 1;
elems(4).DimensionsMode = 'Fixed';
elems(4).DataType = 'single';
elems(4).Complexity = 'real';
elems(4).Min = [];
elems(4).Max = [];
elems(4).DocUnits = '';
elems(4).Description = '';

elems(5) = Simulink.BusElement;
elems(5).Name = 'VMIN_Dir_TestUbUqIq_NULL';
elems(5).Dimensions = 1;
elems(5).DimensionsMode = 'Fixed';
elems(5).DataType = 'single';
elems(5).Complexity = 'real';
elems(5).Min = [];
elems(5).Max = [];
elems(5).DocUnits = sprintf('V');
elems(5).Description = '';

elems(6) = Simulink.BusElement;
elems(6).Name = 'VMIN_Dir_TestUaUdId_NULL';
elems(6).Dimensions = 1;
elems(6).DimensionsMode = 'Fixed';
elems(6).DataType = 'single';
elems(6).Complexity = 'real';
elems(6).Min = [];
elems(6).Max = [];
elems(6).DocUnits = sprintf('V');
elems(6).Description = '';

elems(7) = Simulink.BusElement;
elems(7).Name = 'VMIN_Dir_UCurSenrCurDet_A';
elems(7).Dimensions = 1;
elems(7).DimensionsMode = 'Fixed';
elems(7).DataType = 'single';
elems(7).Complexity = 'real';
elems(7).Min = [];
elems(7).Max = [];
elems(7).DocUnits = '';
elems(7).Description = '';

elems(8) = Simulink.BusElement;
elems(8).Name = 'VMIN_Dir_VCurSenrCurDet_A';
elems(8).Dimensions = 1;
elems(8).DimensionsMode = 'Fixed';
elems(8).DataType = 'single';
elems(8).Complexity = 'real';
elems(8).Min = [];
elems(8).Max = [];
elems(8).DocUnits = '';
elems(8).Description = '';

elems(9) = Simulink.BusElement;
elems(9).Name = 'VMIN_Dir_WCurSenrCurDet_A';
elems(9).Dimensions = 1;
elems(9).DimensionsMode = 'Fixed';
elems(9).DataType = 'single';
elems(9).Complexity = 'real';
elems(9).Min = [];
elems(9).Max = [];
elems(9).DocUnits = '';
elems(9).Description = '';

elems(10) = Simulink.BusElement;
elems(10).Name = 'VMIN_Dir_UCurSenrCurErr_NULL';
elems(10).Dimensions = 1;
elems(10).DimensionsMode = 'Fixed';
elems(10).DataType = 'boolean';
elems(10).Complexity = 'real';
elems(10).Min = [];
elems(10).Max = [];
elems(10).DocUnits = '';
elems(10).Description = '';

elems(11) = Simulink.BusElement;
elems(11).Name = 'VMIN_Dir_VCurSenrCurErr_NULL';
elems(11).Dimensions = 1;
elems(11).DimensionsMode = 'Fixed';
elems(11).DataType = 'boolean';
elems(11).Complexity = 'real';
elems(11).Min = [];
elems(11).Max = [];
elems(11).DocUnits = '';
elems(11).Description = '';

elems(12) = Simulink.BusElement;
elems(12).Name = 'VMIN_Dir_WCurSenrCurErr_NULL';
elems(12).Dimensions = 1;
elems(12).DimensionsMode = 'Fixed';
elems(12).DataType = 'boolean';
elems(12).Complexity = 'real';
elems(12).Min = [];
elems(12).Max = [];
elems(12).DocUnits = '';
elems(12).Description = '';

elems(13) = Simulink.BusElement;
elems(13).Name = 'VMIN_Dir_HwFaultActive_flg';
elems(13).Dimensions = 1;
elems(13).DimensionsMode = 'Fixed';
elems(13).DataType = 'boolean';
elems(13).Complexity = 'real';
elems(13).Min = 0;
elems(13).Max = 1;
elems(13).DocUnits = 'flg';
elems(13).Description = ...
    'Normalized hardware-fault indication from the board adapter';

elems(14) = Simulink.BusElement;
elems(14).Name = 'VMIN_Dir_HwFaultCode_enum';
elems(14).Dimensions = 1;
elems(14).DimensionsMode = 'Fixed';
elems(14).DataType = 'uint16';
elems(14).Complexity = 'real';
elems(14).Min = 0;
elems(14).Max = 65535;
elems(14).DocUnits = 'enum';
elems(14).Description = ...
    'Board-adapter detail code retained in the application fault snapshot';

elems(15) = Simulink.BusElement;
elems(15).Name = 'VMIN_ECAN_CommandAliveCounter_u16';
elems(15).Dimensions = 1;
elems(15).DimensionsMode = 'Fixed';
elems(15).DataType = 'uint16';
elems(15).Complexity = 'real';
elems(15).Min = 0;
elems(15).Max = double(intmax('uint16'));
elems(15).DocUnits = 'cnt';
elems(15).Description = 'Accepted-command rolling counter from communication adapter';

elems(16) = Simulink.BusElement;
elems(16).Name = 'VMIN_ECAN_ClearFaultRequest_flg';
elems(16).Dimensions = 1;
elems(16).DimensionsMode = 'Fixed';
elems(16).DataType = 'boolean';
elems(16).Complexity = 'real';
elems(16).Min = 0;
elems(16).Max = 1;
elems(16).DocUnits = 'flg';
elems(16).Description = 'Explicit service request to clear manual-reset faults';

elems(17) = Simulink.BusElement;
elems(17).Name = 'VMIN_ECAN_FaultHistoryReadIndex_u8';
elems(17).Dimensions = 1;
elems(17).DimensionsMode = 'Fixed';
elems(17).DataType = 'uint8';
elems(17).Complexity = 'real';
elems(17).Min = 0;
elems(17).Max = 7;
elems(17).DocUnits = 'cnt';
elems(17).Description = 'Fault-history age index, zero selects latest event';

elems(18) = Simulink.BusElement;
elems(18).Name = 'VMIN_Dir_PlatformFaultMask_u32';
elems(18).Dimensions = 1;
elems(18).DimensionsMode = 'Fixed';
elems(18).DataType = 'uint32';
elems(18).Complexity = 'real';
elems(18).Min = 0;
elems(18).Max = double(intmax('uint32'));
elems(18).DocUnits = 'NULL';
elems(18).Description = 'Board-specific severe-fault detail mask from HAL';

elems(19) = Simulink.BusElement;
elems(19).Name = 'VMIN_Dir_PlatformWarningMask_u32';
elems(19).Dimensions = 1;
elems(19).DimensionsMode = 'Fixed';
elems(19).DataType = 'uint32';
elems(19).Complexity = 'real';
elems(19).Min = 0;
elems(19).Max = double(intmax('uint32'));
elems(19).DocUnits = 'NULL';
elems(19).Description = 'Board-specific warning or derating detail mask from HAL';

elems(20) = Simulink.BusElement;
elems(20).Name = 'VMIN_Dir_PlatformTorqueLimitFactor_NULL';
elems(20).Dimensions = 1;
elems(20).DimensionsMode = 'Fixed';
elems(20).DataType = 'single';
elems(20).Complexity = 'real';
elems(20).Min = 0;
elems(20).Max = 1;
elems(20).DocUnits = 'NULL';
elems(20).Description = 'HAL-requested current and torque derating factor';

Direct_Output = Simulink.Bus;
Direct_Output.HeaderFile = '';
Direct_Output.Description = '';
Direct_Output.DataScope = 'Auto';
Direct_Output.Alignment = -1;
Direct_Output.PreserveElementDimensions = 0;
Direct_Output.Elements = elems;
clear elems;
assignin('base','Direct_Output', Direct_Output);

% Bus object: MINP_output
% Raw hardware-adapter boundary between the top-level Input_Interface and
% YMBOX_Control_Core.  All signal-processing state belongs to core MDSP.
clear elems;
elems(1) = Simulink.BusElement;
elems(1).Name = 'Direct_Output';
elems(1).Dimensions = 1;
elems(1).DimensionsMode = 'Fixed';
elems(1).DataType = 'Direct_Output';
elems(1).Complexity = 'real';
elems(1).Min = [];
elems(1).Max = [];
elems(1).DocUnits = '';
elems(1).Description = 'Hardware-adapted direct and command inputs';

elems(2) = Simulink.BusElement;
elems(2).Name = 'VuMINP_ResolverPositionRaw_NULL';
elems(2).Dimensions = 1;
elems(2).DimensionsMode = 'Fixed';
elems(2).DataType = 'uint32';
elems(2).Complexity = 'real';
elems(2).Min = 0;
elems(2).Max = double(intmax('uint32'));
elems(2).DocUnits = 'count';
elems(2).Description = 'Unprocessed mechanical resolver count';

elems(3) = Simulink.BusElement;
elems(3).Name = 'VfMINP_DCBusCurPhysical_A';
elems(3).Dimensions = 1;
elems(3).DimensionsMode = 'Fixed';
elems(3).DataType = 'single';
elems(3).Complexity = 'real';
elems(3).Min = [];
elems(3).Max = [];
elems(3).DocUnits = 'A';
elems(3).Description = 'Physical DC-bus current after hardware input adaptation';

elems(4) = Simulink.BusElement;
elems(4).Name = 'VfMINP_DCBusVoltRaw_V';
elems(4).Dimensions = 1;
elems(4).DimensionsMode = 'Fixed';
elems(4).DataType = 'single';
elems(4).Complexity = 'real';
elems(4).Min = [];
elems(4).Max = [];
elems(4).DocUnits = 'V';
elems(4).Description = 'Raw DC-bus voltage after hardware input adaptation';

MINP_output = Simulink.Bus;
MINP_output.HeaderFile = '';
MINP_output.Description = ...
    'Raw hardware-adapter inputs consumed by core MDSP';
MINP_output.DataScope = 'Auto';
MINP_output.Alignment = -1;
MINP_output.PreserveElementDimensions = 0;
MINP_output.Elements = elems;
clear elems;
assignin('base','MINP_output', MINP_output);

% Bus object: MDCC_output
clear elems;
elems(1) = Simulink.BusElement;
elems(1).Name = 'VfMDCC_VoltD_V';
elems(1).Dimensions = 1;
elems(1).DimensionsMode = 'Fixed';
elems(1).DataType = 'single';
elems(1).Complexity = 'real';
elems(1).Min = -1000;
elems(1).Max = 1000;
elems(1).DocUnits = sprintf('V');
elems(1).Description = '';

elems(2) = Simulink.BusElement;
elems(2).Name = 'VfMDCC_VoltQ_V';
elems(2).Dimensions = 1;
elems(2).DimensionsMode = 'Fixed';
elems(2).DataType = 'single';
elems(2).Complexity = 'real';
elems(2).Min = -1000;
elems(2).Max = 1000;
elems(2).DocUnits = sprintf('V');
elems(2).Description = '';

elems(3) = Simulink.BusElement;
elems(3).Name = 'VbMDCC_DqSoftwareOverCurrent_flg';
elems(3).Dimensions = 1;
elems(3).DimensionsMode = 'Fixed';
elems(3).DataType = 'boolean';
elems(3).Complexity = 'real';
elems(3).Min = 0;
elems(3).Max = 1;
elems(3).DocUnits = 'flg';
elems(3).Description = 'Qualified magnitude fault from sqrt(Id^2 + Iq^2)';

elems(4) = Simulink.BusElement;
elems(4).Name = 'VfMDCC_DCur_A';
elems(4).Dimensions = 1;
elems(4).DimensionsMode = 'Fixed';
elems(4).DataType = 'single';
elems(4).Complexity = 'real';
elems(4).Min = [];
elems(4).Max = [];
elems(4).DocUnits = '';
elems(4).Description = '';

elems(5) = Simulink.BusElement;
elems(5).Name = 'VfMDCC_QCur_A';
elems(5).Dimensions = 1;
elems(5).DimensionsMode = 'Fixed';
elems(5).DataType = 'single';
elems(5).Complexity = 'real';
elems(5).Min = [];
elems(5).Max = [];
elems(5).DocUnits = '';
elems(5).Description = '';

elems(6) = Simulink.BusElement;
elems(6).Name = 'VfMDCC_EAngleCos_NULL';
elems(6).Dimensions = 1;
elems(6).DimensionsMode = 'Fixed';
elems(6).DataType = 'single';
elems(6).Complexity = 'real';
elems(6).Min = -1;
elems(6).Max = 1;
elems(6).DocUnits = 'NULL';
elems(6).Description = 'Shared raw electrical-angle cosine';

elems(7) = Simulink.BusElement;
elems(7).Name = 'VfMDCC_EAngleSin_NULL';
elems(7).Dimensions = 1;
elems(7).DimensionsMode = 'Fixed';
elems(7).DataType = 'single';
elems(7).Complexity = 'real';
elems(7).Min = -1;
elems(7).Max = 1;
elems(7).DocUnits = 'NULL';
elems(7).Description = 'Shared raw electrical-angle sine';

MDCC_output = Simulink.Bus;
MDCC_output.HeaderFile = '';
MDCC_output.Description = '';
MDCC_output.DataScope = 'Auto';
MDCC_output.Alignment = -1;
MDCC_output.PreserveElementDimensions = 0;
MDCC_output.Elements = elems;
clear elems;
assignin('base','MDCC_output', MDCC_output);

% Bus object: MDFM_output
clear elems;
elems(1) = Simulink.BusElement;
elems(1).Name = 'VbMDFM_ECAN_PhaseUSampleCycleErr_flg';
elems(1).Dimensions = 1;
elems(1).DimensionsMode = 'Fixed';
elems(1).DataType = 'boolean';
elems(1).Complexity = 'real';
elems(1).Min = [];
elems(1).Max = [];
elems(1).DocUnits = '';
elems(1).Description = '';

elems(2) = Simulink.BusElement;
elems(2).Name = 'VbMDFM_ECAN_PhaseVSampleCycleErr_flg';
elems(2).Dimensions = 1;
elems(2).DimensionsMode = 'Fixed';
elems(2).DataType = 'boolean';
elems(2).Complexity = 'real';
elems(2).Min = [];
elems(2).Max = [];
elems(2).DocUnits = '';
elems(2).Description = '';

elems(3) = Simulink.BusElement;
elems(3).Name = 'VbMDFM_ECAN_PhaseWSampleCycleErr_flg';
elems(3).Dimensions = 1;
elems(3).DimensionsMode = 'Fixed';
elems(3).DataType = 'boolean';
elems(3).Complexity = 'real';
elems(3).Min = [];
elems(3).Max = [];
elems(3).DocUnits = '';
elems(3).Description = '';

elems(4) = Simulink.BusElement;
elems(4).Name = 'VbMDFM_StopRequest_flg';
elems(4).Dimensions = 1;
elems(4).DimensionsMode = 'Fixed';
elems(4).DataType = 'boolean';
elems(4).Complexity = 'real';
elems(4).Min = 0;
elems(4).Max = 1;
elems(4).DocUnits = 'flg';
elems(4).Description = 'Latched application request for MDSM to command gate-off';

elems(5) = Simulink.BusElement;
elems(5).Name = 'VbMDFM_FaultLatched_flg';
elems(5).Dimensions = 1;
elems(5).DimensionsMode = 'Fixed';
elems(5).DataType = 'boolean';
elems(5).Complexity = 'real';
elems(5).Min = 0;
elems(5).Max = 1;
elems(5).DocUnits = 'flg';
elems(5).Description = 'Application fault latch state';

elems(6) = Simulink.BusElement;
elems(6).Name = 'VuMDFM_ActiveFaultCode_enum';
elems(6).Dimensions = 1;
elems(6).DimensionsMode = 'Fixed';
elems(6).DataType = 'uint16';
elems(6).Complexity = 'real';
elems(6).Min = 0;
elems(6).Max = 65535;
elems(6).DocUnits = 'enum';
elems(6).Description = 'Highest-priority active code from the latched trip mask';

elems(7) = Simulink.BusElement;
elems(7).Name = 'VuMDFM_RawFaultMask_u32';
elems(7).Dimensions = 1;
elems(7).DimensionsMode = 'Fixed';
elems(7).DataType = 'uint32';
elems(7).Complexity = 'real';
elems(7).Min = 0;
elems(7).Max = double(intmax('uint32'));
elems(7).DocUnits = 'NULL';
elems(7).Description = 'Current qualified trips plus non-latched warning bit';

elems(8) = Simulink.BusElement;
elems(8).Name = 'VuMDFM_LatchedFaultMask_u32';
elems(8).Dimensions = 1;
elems(8).DimensionsMode = 'Fixed';
elems(8).DataType = 'uint32';
elems(8).Complexity = 'real';
elems(8).Min = 0;
elems(8).Max = double(intmax('uint32'));
elems(8).DocUnits = 'NULL';
elems(8).Description = 'Accumulated fault conditions during the current event';

elems(9) = Simulink.BusElement;
elems(9).Name = 'VuMDFM_LastHwFaultCode_enum';
elems(9).Dimensions = 1;
elems(9).DimensionsMode = 'Fixed';
elems(9).DataType = 'uint16';
elems(9).Complexity = 'real';
elems(9).Min = 0;
elems(9).Max = 65535;
elems(9).DocUnits = 'enum';
elems(9).Description = 'Last board-adapter hardware detail code';

elems(10) = Simulink.BusElement;
elems(10).Name = 'VuMDFM_FaultOccurrence_cnt';
elems(10).Dimensions = 1;
elems(10).DimensionsMode = 'Fixed';
elems(10).DataType = 'uint32';
elems(10).Complexity = 'real';
elems(10).Min = 0;
elems(10).Max = double(intmax('uint32'));
elems(10).DocUnits = 'cnt';
elems(10).Description = 'Saturating count of recorded trip and warning events';

elems(11) = Simulink.BusElement;
elems(11).Name = 'VfMDFM_SnapshotDCBusVolt_V';
elems(11).Dimensions = 1;
elems(11).DimensionsMode = 'Fixed';
elems(11).DataType = 'single';
elems(11).Complexity = 'real';
elems(11).Min = 0;
elems(11).Max = 1000;
elems(11).DocUnits = 'V';
elems(11).Description = 'DC-bus voltage captured on the first fault edge';

elems(12) = Simulink.BusElement;
elems(12).Name = 'VfMDFM_SnapshotPhaseUCur_A';
elems(12).Dimensions = 1;
elems(12).DimensionsMode = 'Fixed';
elems(12).DataType = 'single';
elems(12).Complexity = 'real';
elems(12).Min = [];
elems(12).Max = [];
elems(12).DocUnits = 'A';
elems(12).Description = 'Phase-U current captured on the first fault edge';

elems(13) = Simulink.BusElement;
elems(13).Name = 'VfMDFM_SnapshotPhaseVCur_A';
elems(13).Dimensions = 1;
elems(13).DimensionsMode = 'Fixed';
elems(13).DataType = 'single';
elems(13).Complexity = 'real';
elems(13).Min = [];
elems(13).Max = [];
elems(13).DocUnits = 'A';
elems(13).Description = 'Phase-V current captured on the first fault edge';

elems(14) = Simulink.BusElement;
elems(14).Name = 'VfMDFM_SnapshotPhaseWCur_A';
elems(14).Dimensions = 1;
elems(14).DimensionsMode = 'Fixed';
elems(14).DataType = 'single';
elems(14).Complexity = 'real';
elems(14).Min = [];
elems(14).Max = [];
elems(14).DocUnits = 'A';
elems(14).Description = 'Phase-W current captured on the first fault edge';

elems(15) = Simulink.BusElement;
elems(15).Name = 'VuMDFM_SnapshotModeReq_enum';
elems(15).Dimensions = 1;
elems(15).DimensionsMode = 'Fixed';
elems(15).DataType = 'uint16';
elems(15).Complexity = 'real';
elems(15).Min = 0;
elems(15).Max = double(modeId.PublicMaximum);
elems(15).DocUnits = 'enum';
elems(15).Description = 'Requested drive mode captured on the first fault edge';

elems(16) = Simulink.BusElement;
elems(16).Name = 'VfMDFM_SnapshotSpdCmd_rpm';
elems(16).Dimensions = 1;
elems(16).DimensionsMode = 'Fixed';
elems(16).DataType = 'single';
elems(16).Complexity = 'real';
elems(16).Min = -100000;
elems(16).Max = 100000;
elems(16).DocUnits = 'rpm';
elems(16).Description = 'Speed command captured on the first fault edge';

elems(17) = Simulink.BusElement;
elems(17).Name = 'VfMDFM_SnapshotTrqCmd_Nm';
elems(17).Dimensions = 1;
elems(17).DimensionsMode = 'Fixed';
elems(17).DataType = 'single';
elems(17).Complexity = 'real';
elems(17).Min = -100000;
elems(17).Max = 100000;
elems(17).DocUnits = 'N*m';
elems(17).Description = 'Torque command captured on the first fault edge';

elems(18) = Simulink.BusElement;
elems(18).Name = 'VbMDFM_ClearReady_flg';
elems(18).Dimensions = 1;
elems(18).DimensionsMode = 'Fixed';
elems(18).DataType = 'boolean';
elems(18).Complexity = 'real';
elems(18).Min = 0;
elems(18).Max = 1;
elems(18).DocUnits = 'flg';
elems(18).Description = ...
    'Clear qualification hold is active: disabled, raw trip free, and policy authorized';

elems(19) = Simulink.BusElement;
elems(19).Name = 'VbMDFM_PWMDisableRequest_flg';
elems(19).Dimensions = 1;
elems(19).DimensionsMode = 'Fixed';
elems(19).DataType = 'boolean';
elems(19).Complexity = 'real';
elems(19).Min = 0;
elems(19).Max = 1;
elems(19).DocUnits = 'flg';
elems(19).Description = 'Synchronous PWM-inhibit request; HAL trips remain asynchronous';

elems(20) = Simulink.BusElement;
elems(20).Name = 'VbMDFM_PIResetRequest_flg';
elems(20).Dimensions = 1;
elems(20).DimensionsMode = 'Fixed';
elems(20).DataType = 'boolean';
elems(20).Complexity = 'real';
elems(20).Min = 0;
elems(20).Max = 1;
elems(20).DocUnits = 'flg';
elems(20).Description = 'Request to reset current and speed controller states';

elems(21) = Simulink.BusElement;
elems(21).Name = 'VfMDFM_TorqueLimitFactor_NULL';
elems(21).Dimensions = 1;
elems(21).DimensionsMode = 'Fixed';
elems(21).DataType = 'single';
elems(21).Complexity = 'real';
elems(21).Min = 0;
elems(21).Max = 1;
elems(21).DocUnits = 'NULL';
elems(21).Description = 'Effective current and torque limit factor after fault arbitration';

elems(22) = Simulink.BusElement;
elems(22).Name = 'VbMDFM_WarningActive_flg';
elems(22).Dimensions = 1;
elems(22).DimensionsMode = 'Fixed';
elems(22).DataType = 'boolean';
elems(22).Complexity = 'real';
elems(22).Min = 0;
elems(22).Max = 1;
elems(22).DocUnits = 'flg';
elems(22).Description = 'At least one non-latched platform warning is active';

elems(23) = Simulink.BusElement;
elems(23).Name = 'VuMDFM_FaultAction_enum';
elems(23).Dimensions = 1;
elems(23).DimensionsMode = 'Fixed';
elems(23).DataType = 'uint8';
elems(23).Complexity = 'real';
elems(23).Min = 0;
elems(23).Max = 4;
elems(23).DocUnits = 'enum';
elems(23).Description = '0 none, 2 derate, 3 controlled stop, 4 immediate stop';

elems(24) = Simulink.BusElement;
elems(24).Name = 'VuMDFM_FirstFaultCode_enum';
elems(24).Dimensions = 1;
elems(24).DimensionsMode = 'Fixed';
elems(24).DataType = 'uint16';
elems(24).Complexity = 'real';
elems(24).Min = 0;
elems(24).Max = 65535;
elems(24).DocUnits = 'enum';
elems(24).Description = 'First trip code retained for root-cause diagnosis until clear';

elems(25) = Simulink.BusElement;
elems(25).Name = 'VuMDFM_ActivePlatformFaultMask_u32';
elems(25).Dimensions = 1;
elems(25).DimensionsMode = 'Fixed';
elems(25).DataType = 'uint32';
elems(25).Complexity = 'real';
elems(25).Min = 0;
elems(25).Max = double(intmax('uint32'));
elems(25).DocUnits = 'NULL';
elems(25).Description = 'Current HAL severe-fault detail mask';

elems(26) = Simulink.BusElement;
elems(26).Name = 'VuMDFM_ActivePlatformWarningMask_u32';
elems(26).Dimensions = 1;
elems(26).DimensionsMode = 'Fixed';
elems(26).DataType = 'uint32';
elems(26).Complexity = 'real';
elems(26).Min = 0;
elems(26).Max = double(intmax('uint32'));
elems(26).DocUnits = 'NULL';
elems(26).Description = 'Current HAL warning and derating detail mask';

elems(27) = Simulink.BusElement;
elems(27).Name = 'VbMDFM_ClearRequestRequired_flg';
elems(27).Dimensions = 1;
elems(27).DimensionsMode = 'Fixed';
elems(27).DataType = 'boolean';
elems(27).Complexity = 'real';
elems(27).Min = 0;
elems(27).Max = 1;
elems(27).DocUnits = 'flg';
elems(27).Description = 'Current latch contains a manual-reset fault class';

elems(28) = Simulink.BusElement;
elems(28).Name = 'VbMDFM_ClearRejected_flg';
elems(28).Dimensions = 1;
elems(28).DimensionsMode = 'Fixed';
elems(28).DataType = 'boolean';
elems(28).Complexity = 'real';
elems(28).Min = 0;
elems(28).Max = 1;
elems(28).DocUnits = 'flg';
elems(28).Description = 'Clear request arrived while enable or a raw trip was active';

elems(29) = Simulink.BusElement;
elems(29).Name = 'VuMDFM_FaultHistoryCount_cnt';
elems(29).Dimensions = 1;
elems(29).DimensionsMode = 'Fixed';
elems(29).DataType = 'uint8';
elems(29).Complexity = 'real';
elems(29).Min = 0;
elems(29).Max = 8;
elems(29).DocUnits = 'cnt';
elems(29).Description = 'Number of valid records in the fixed-depth event ring';

elems(30) = Simulink.BusElement;
elems(30).Name = 'VuMDFM_FaultHistoryWriteIndex_u8';
elems(30).Dimensions = 1;
elems(30).DimensionsMode = 'Fixed';
elems(30).DataType = 'uint8';
elems(30).Complexity = 'real';
elems(30).Min = 0;
elems(30).Max = 7;
elems(30).DocUnits = 'cnt';
elems(30).Description = 'Next physical event-ring slot, zero based';

elems(31) = Simulink.BusElement;
elems(31).Name = 'VbMDFM_FaultHistoryReadValid_flg';
elems(31).Dimensions = 1;
elems(31).DimensionsMode = 'Fixed';
elems(31).DataType = 'boolean';
elems(31).Complexity = 'real';
elems(31).Min = 0;
elems(31).Max = 1;
elems(31).DocUnits = 'flg';
elems(31).Description = 'Requested logical history age exists';

elems(32) = Simulink.BusElement;
elems(32).Name = 'VuMDFM_FaultHistoryCode_enum';
elems(32).Dimensions = 1;
elems(32).DimensionsMode = 'Fixed';
elems(32).DataType = 'uint16';
elems(32).Complexity = 'real';
elems(32).Min = 0;
elems(32).Max = 65535;
elems(32).DocUnits = 'enum';
elems(32).Description = 'Selected event code';

elems(33) = Simulink.BusElement;
elems(33).Name = 'VuMDFM_FaultHistoryAction_enum';
elems(33).Dimensions = 1;
elems(33).DimensionsMode = 'Fixed';
elems(33).DataType = 'uint8';
elems(33).Complexity = 'real';
elems(33).Min = 0;
elems(33).Max = 4;
elems(33).DocUnits = 'enum';
elems(33).Description = 'Selected event action';

elems(34) = Simulink.BusElement;
elems(34).Name = 'VuMDFM_FaultHistoryMask_u32';
elems(34).Dimensions = 1;
elems(34).DimensionsMode = 'Fixed';
elems(34).DataType = 'uint32';
elems(34).Complexity = 'real';
elems(34).Min = 0;
elems(34).Max = double(intmax('uint32'));
elems(34).DocUnits = 'NULL';
elems(34).Description = 'Selected standardized event mask';

elems(35) = Simulink.BusElement;
elems(35).Name = 'VuMDFM_FaultHistoryPlatformMask_u32';
elems(35).Dimensions = 1;
elems(35).DimensionsMode = 'Fixed';
elems(35).DataType = 'uint32';
elems(35).Complexity = 'real';
elems(35).Min = 0;
elems(35).Max = double(intmax('uint32'));
elems(35).DocUnits = 'NULL';
elems(35).Description = 'Selected board-specific fault or warning detail mask';

elems(36) = Simulink.BusElement;
elems(36).Name = 'VfMDFM_FaultHistoryDCBusVolt_V';
elems(36).Dimensions = 1;
elems(36).DimensionsMode = 'Fixed';
elems(36).DataType = 'single';
elems(36).Complexity = 'real';
elems(36).Min = 0;
elems(36).Max = 1000;
elems(36).DocUnits = 'V';
elems(36).Description = 'Selected event DC-bus voltage';

elems(37) = Simulink.BusElement;
elems(37).Name = 'VfMDFM_FaultHistoryMaxPhaseCur_A';
elems(37).Dimensions = 1;
elems(37).DimensionsMode = 'Fixed';
elems(37).DataType = 'single';
elems(37).Complexity = 'real';
elems(37).Min = 0;
elems(37).Max = [];
elems(37).DocUnits = 'A';
elems(37).Description = 'Selected event maximum absolute phase current';

elems(38) = Simulink.BusElement;
elems(38).Name = 'VuMDFM_FaultHistoryModeReq_enum';
elems(38).Dimensions = 1;
elems(38).DimensionsMode = 'Fixed';
elems(38).DataType = 'uint16';
elems(38).Complexity = 'real';
elems(38).Min = 0;
elems(38).Max = double(modeId.PublicMaximum);
elems(38).DocUnits = 'enum';
elems(38).Description = 'Selected event requested drive mode';

elems(39) = Simulink.BusElement;
elems(39).Name = 'VfMDFM_FaultHistorySpdCmd_rpm';
elems(39).Dimensions = 1;
elems(39).DimensionsMode = 'Fixed';
elems(39).DataType = 'single';
elems(39).Complexity = 'real';
elems(39).Min = -100000;
elems(39).Max = 100000;
elems(39).DocUnits = 'rpm';
elems(39).Description = 'Selected event speed command';

elems(40) = Simulink.BusElement;
elems(40).Name = 'VfMDFM_FaultHistoryTrqCmd_Nm';
elems(40).Dimensions = 1;
elems(40).DimensionsMode = 'Fixed';
elems(40).DataType = 'single';
elems(40).Complexity = 'real';
elems(40).Min = -100000;
elems(40).Max = 100000;
elems(40).DocUnits = 'N*m';
elems(40).Description = 'Selected event torque command';

elems(41) = Simulink.BusElement;
elems(41).Name = 'VfMDFM_DCBusCurrentRaw_A';
elems(41).Dimensions = 1;
elems(41).DimensionsMode = 'Fixed';
elems(41).DataType = 'single';
elems(41).Complexity = 'real';
elems(41).Min = -10000;
elems(41).Max = 10000;
elems(41).DocUnits = 'A';
elems(41).Description = 'Selected unfiltered DC-bus current';

elems(42) = Simulink.BusElement;
elems(42).Name = 'VfMDFM_DCBusCurrentSoft_A';
elems(42).Dimensions = 1;
elems(42).DimensionsMode = 'Fixed';
elems(42).DataType = 'single';
elems(42).Complexity = 'real';
elems(42).Min = -10000;
elems(42).Max = 10000;
elems(42).DocUnits = 'A';
elems(42).Description = 'Configured current average for soft limiting and telemetry';

elems(43) = Simulink.BusElement;
elems(43).Name = 'VbMDFM_DCBusCurrentValid_flg';
elems(43).Dimensions = 1;
elems(43).DimensionsMode = 'Fixed';
elems(43).DataType = 'boolean';
elems(43).Complexity = 'real';
elems(43).Min = 0;
elems(43).Max = 1;
elems(43).DocUnits = 'flg';
elems(43).Description = 'Selected DC-bus current source validity';

elems(44) = Simulink.BusElement;
elems(44).Name = 'VbMDFM_DCBusCurrentHardFault_flg';
elems(44).Dimensions = 1;
elems(44).DimensionsMode = 'Fixed';
elems(44).DataType = 'boolean';
elems(44).Complexity = 'real';
elems(44).Min = 0;
elems(44).Max = 1;
elems(44).DocUnits = 'flg';
elems(44).Description = 'Unfiltered software hard-current threshold exceeded';

elems(45) = Simulink.BusElement;
elems(45).Name = 'VuMDFM_DCBusCurrentSource_enum';
elems(45).Dimensions = 1;
elems(45).DimensionsMode = 'Fixed';
elems(45).DataType = 'uint8';
elems(45).Complexity = 'real';
elems(45).Min = 0;
elems(45).Max = 1;
elems(45).DocUnits = 'enum';
elems(45).Description = '0=physical sensor, 1=duty/current estimate';

elems(46) = Simulink.BusElement;
elems(46).Name = 'VfMDFM_DCBusVoltReport_V';
elems(46).Dimensions = 1;
elems(46).DimensionsMode = 'Fixed';
elems(46).DataType = 'single';
elems(46).Complexity = 'real';
elems(46).Min = -1000;
elems(46).Max = 2000;
elems(46).DocUnits = 'V';
elems(46).Description = 'Slow DC-bus voltage path for telemetry';

elems(47) = Simulink.BusElement;
elems(47).Name = 'VbMDFM_VoltageOperationalValid_flg';
elems(47).Dimensions = 1;
elems(47).DimensionsMode = 'Fixed';
elems(47).DataType = 'boolean';
elems(47).Complexity = 'real';
elems(47).Min = 0;
elems(47).Max = 1;
elems(47).DocUnits = 'flg';
elems(47).Description = ...
    'Immediate MDFM voltage-envelope permission consumed by MDSA';

elems(48) = Simulink.BusElement;
elems(48).Name = 'VbMDFM_PhaseSoftwareOverCurrent_flg';
elems(48).Dimensions = 1;
elems(48).DimensionsMode = 'Fixed';
elems(48).DataType = 'boolean';
elems(48).Complexity = 'real';
elems(48).Min = 0;
elems(48).Max = 1;
elems(48).DocUnits = 'flg';
elems(48).Description = ...
    'Qualified maximum absolute U/V/W phase-current fault';

elems(49) = Simulink.BusElement;
elems(49).Name = 'VbMDFM_DqSoftwareOverCurrent_flg';
elems(49).Dimensions = 1;
elems(49).DimensionsMode = 'Fixed';
elems(49).DataType = 'boolean';
elems(49).Complexity = 'real';
elems(49).Min = 0;
elems(49).Max = 1;
elems(49).DocUnits = 'flg';
elems(49).Description = ...
    'MDFM-consumed dq current-magnitude fault from MDCC';

MDFM_output = Simulink.Bus;
MDFM_output.HeaderFile = '';
MDFM_output.Description = '';
MDFM_output.DataScope = 'Auto';
MDFM_output.Alignment = -1;
MDFM_output.PreserveElementDimensions = 0;
MDFM_output.Elements = elems;
clear elems;
assignin('base','MDFM_output', MDFM_output);

% Bus object: MDSA_output
clear elems;
elems(1) = Simulink.BusElement;
elems(1).Name = 'VfMDSA_PwmDutyCyclePhaseU_NULL';
elems(1).Dimensions = 1;
elems(1).DimensionsMode = 'Fixed';
elems(1).DataType = 'single';
elems(1).Complexity = 'real';
elems(1).Min = 0;
elems(1).Max = 1;
elems(1).DocUnits = sprintf('NULL');
elems(1).Description = '';

elems(2) = Simulink.BusElement;
elems(2).Name = 'VfMDSA_PwmDutyCyclePhaseV_NULL';
elems(2).Dimensions = 1;
elems(2).DimensionsMode = 'Fixed';
elems(2).DataType = 'single';
elems(2).Complexity = 'real';
elems(2).Min = 0;
elems(2).Max = 1;
elems(2).DocUnits = sprintf('NULL');
elems(2).Description = '';

elems(3) = Simulink.BusElement;
elems(3).Name = 'VfMDSA_PwmDutyCyclePhaseW_NULL';
elems(3).Dimensions = 1;
elems(3).DimensionsMode = 'Fixed';
elems(3).DataType = 'single';
elems(3).Complexity = 'real';
elems(3).Min = 0;
elems(3).Max = 1;
elems(3).DocUnits = sprintf('NULL');
elems(3).Description = '';

elems(4) = Simulink.BusElement;
elems(4).Name = 'VfMDSA_k_svm_NULL';
elems(4).Dimensions = 1;
elems(4).DimensionsMode = 'Fixed';
elems(4).DataType = 'single';
elems(4).Complexity = 'real';
elems(4).Min = 0;
elems(4).Max = 1;
elems(4).DocUnits = sprintf('NULL');
elems(4).Description = 'Raw SVM saturation scale';

elems(5) = Simulink.BusElement;
elems(5).Name = 'VfMDSA_ManagedVoltAlpha_V';
elems(5).Dimensions = 1;
elems(5).DimensionsMode = 'Fixed';
elems(5).DataType = 'single';
elems(5).Complexity = 'real';
elems(5).Min = [];
elems(5).Max = [];
elems(5).DocUnits = 'V';
elems(5).Description = 'Manager output alpha voltage before hard bypass, angle advance, and SVM';

elems(6) = Simulink.BusElement;
elems(6).Name = 'VfMDSA_ManagedVoltBeta_V';
elems(6).Dimensions = 1;
elems(6).DimensionsMode = 'Fixed';
elems(6).DataType = 'single';
elems(6).Complexity = 'real';
elems(6).Min = [];
elems(6).Max = [];
elems(6).DocUnits = 'V';
elems(6).Description = 'Manager output beta voltage before hard bypass, angle advance, and SVM';

elems(7) = Simulink.BusElement;
elems(7).Name = 'VfMDSA_VoltageUtilization_NULL';
elems(7).Dimensions = 1;
elems(7).DimensionsMode = 'Fixed';
elems(7).DataType = 'single';
elems(7).Complexity = 'real';
elems(7).Min = 0;
elems(7).Max = [];
elems(7).DocUnits = 'NULL';
elems(7).Description = 'Requested magnitude divided by managed voltage limit';

elems(8) = Simulink.BusElement;
elems(8).Name = 'VbMDSA_VoltageLimited_flg';
elems(8).Dimensions = 1;
elems(8).DimensionsMode = 'Fixed';
elems(8).DataType = 'boolean';
elems(8).Complexity = 'real';
elems(8).Min = [];
elems(8).Max = [];
elems(8).DocUnits = 'flg';
elems(8).Description = 'Unified voltage-circle limiter active';

elems(9) = Simulink.BusElement;
elems(9).Name = 'VbMDSA_InverterCompActive_flg';
elems(9).Dimensions = 1;
elems(9).DimensionsMode = 'Fixed';
elems(9).DataType = 'boolean';
elems(9).Complexity = 'real';
elems(9).Min = [];
elems(9).Max = [];
elems(9).DocUnits = 'flg';
elems(9).Description = 'Active inverter nonlinear compensation applied';

elems(10) = Simulink.BusElement;
elems(10).Name = 'VfMDSA_InverterCompD_V';
elems(10).Dimensions = 1;
elems(10).DimensionsMode = 'Fixed';
elems(10).DataType = 'single';
elems(10).Complexity = 'real';
elems(10).Min = [];
elems(10).Max = [];
elems(10).DocUnits = 'V';
elems(10).Description = 'Applied d-axis nonlinear compensation';

elems(11) = Simulink.BusElement;
elems(11).Name = 'VfMDSA_InverterCompQ_V';
elems(11).Dimensions = 1;
elems(11).DimensionsMode = 'Fixed';
elems(11).DataType = 'single';
elems(11).Complexity = 'real';
elems(11).Min = [];
elems(11).Max = [];
elems(11).DocUnits = 'V';
elems(11).Description = 'Applied q-axis nonlinear compensation';

elems(12) = Simulink.BusElement;
elems(12).Name = 'VfMDSA_k_mgr_NULL';
elems(12).Dimensions = 1;
elems(12).DimensionsMode = 'Fixed';
elems(12).DataType = 'single';
elems(12).Complexity = 'real';
elems(12).Min = 0;
elems(12).Max = 1;
elems(12).DocUnits = 'NULL';
elems(12).Description = 'Manager voltage-vector saturation scale after hard-bypass selection';

elems(13) = Simulink.BusElement;
elems(13).Name = 'VfMDSA_k_effective_NULL';
elems(13).Dimensions = 1;
elems(13).DimensionsMode = 'Fixed';
elems(13).DataType = 'single';
elems(13).Complexity = 'real';
elems(13).Min = 0;
elems(13).Max = 1;
elems(13).DocUnits = 'NULL';
elems(13).Description = 'Effective anti-windup scale equal to k_mgr multiplied by k_svm';

MDSA_output = Simulink.Bus;
MDSA_output.HeaderFile = '';
MDSA_output.Description = '';
MDSA_output.DataScope = 'Auto';
MDSA_output.Alignment = -1;
MDSA_output.PreserveElementDimensions = 0;
MDSA_output.Elements = elems;
clear elems;
assignin('base','MDSA_output', MDSA_output);

% Bus object: MDSM_output
clear elems;
elems(1) = Simulink.BusElement;
elems(1).Name = 'VeMDSM_DrvModeCmd_enum';
elems(1).Dimensions = 1;
elems(1).DimensionsMode = 'Fixed';
elems(1).DataType = 'uint16';
elems(1).Complexity = 'real';
elems(1).Min = double(modeId.PublicMinimum);
elems(1).Max = double(modeId.InternalMaximum);
elems(1).DocUnits = '';
elems(1).Description = 'MDSM command; public modes or internal 16..17';

elems(2) = Simulink.BusElement;
elems(2).Name = 'VbMDTM_PiReset_flg';
elems(2).Dimensions = 1;
elems(2).DimensionsMode = 'Fixed';
elems(2).DataType = 'boolean';
elems(2).Complexity = 'real';
elems(2).Min = [];
elems(2).Max = [];
elems(2).DocUnits = '';
elems(2).Description = '';

elems(3) = Simulink.BusElement;
elems(3).Name = 'VbMDCC_PiReset_flg';
elems(3).Dimensions = 1;
elems(3).DimensionsMode = 'Fixed';
elems(3).DataType = 'boolean';
elems(3).Complexity = 'real';
elems(3).Min = [];
elems(3).Max = [];
elems(3).DocUnits = '';
elems(3).Description = '';

elems(4) = Simulink.BusElement;
elems(4).Name = 'VeMDFM_FFEnable_enum';
elems(4).Dimensions = 1;
elems(4).DimensionsMode = 'Fixed';
elems(4).DataType = 'uint8';
elems(4).Complexity = 'real';
elems(4).Min = [];
elems(4).Max = [];
elems(4).DocUnits = '';
elems(4).Description = '';

elems(5) = Simulink.BusElement;
elems(5).Name = 'VfMDSM_TestUaUdId_NULL';
elems(5).Dimensions = 1;
elems(5).DimensionsMode = 'Fixed';
elems(5).DataType = 'single';
elems(5).Complexity = 'real';
elems(5).Min = [];
elems(5).Max = [];
elems(5).DocUnits = sprintf('V');
elems(5).Description = '';

elems(6) = Simulink.BusElement;
elems(6).Name = 'VfMDSM_TestUbUqIq_NULL';
elems(6).Dimensions = 1;
elems(6).DimensionsMode = 'Fixed';
elems(6).DataType = 'single';
elems(6).Complexity = 'real';
elems(6).Min = [];
elems(6).Max = [];
elems(6).DocUnits = sprintf('V');
elems(6).Description = '';

elems(7) = Simulink.BusElement;
elems(7).Name = 'VfMDSM_TrgtTq_Nm';
elems(7).Dimensions = 1;
elems(7).DimensionsMode = 'Fixed';
elems(7).DataType = 'single';
elems(7).Complexity = 'real';
elems(7).Min = [];
elems(7).Max = [];
elems(7).DocUnits = '';
elems(7).Description = '';

elems(8) = Simulink.BusElement;
elems(8).Name = 'VfMDSM_TrgtSpd_rpm';
elems(8).Dimensions = 1;
elems(8).DimensionsMode = 'Fixed';
elems(8).DataType = 'single';
elems(8).Complexity = 'real';
elems(8).Min = [];
elems(8).Max = [];
elems(8).DocUnits = '';
elems(8).Description = '';

elems(9) = Simulink.BusElement;
elems(9).Name = 'VeMDSM_DrvModeReq_enum';
elems(9).Dimensions = 1;
elems(9).DimensionsMode = 'Fixed';
elems(9).DataType = 'uint16';
elems(9).Complexity = 'real';
elems(9).Min = double(modeId.PublicMinimum);
elems(9).Max = double(modeId.PublicMaximum);
elems(9).DocUnits = '';
elems(9).Description = ...
    'Public drive-mode request interface, 0..10; values 7..10 reserved';

MDSM_output = Simulink.Bus;
MDSM_output.HeaderFile = '';
MDSM_output.Description = '';
MDSM_output.DataScope = 'Auto';
MDSM_output.Alignment = -1;
MDSM_output.PreserveElementDimensions = 0;
MDSM_output.Elements = elems;
clear elems;
assignin('base','MDSM_output', MDSM_output);

% Bus object: MDSP_output
clear elems;
elems(1) = Simulink.BusElement;
elems(1).Name = 'Direct_Output';
elems(1).Dimensions = 1;
elems(1).DimensionsMode = 'Fixed';
elems(1).DataType = 'Direct_Output';
elems(1).Complexity = 'real';
elems(1).Min = [];
elems(1).Max = [];
elems(1).DocUnits = '';
elems(1).Description = '';

elems(2) = Simulink.BusElement;
elems(2).Name = 'Resolver_Output';
elems(2).Dimensions = 1;
elems(2).DimensionsMode = 'Fixed';
elems(2).DataType = 'Resolver_Output';
elems(2).Complexity = 'real';
elems(2).Min = [];
elems(2).Max = [];
elems(2).DocUnits = '';
elems(2).Description = '';

elems(3) = Simulink.BusElement;
elems(3).Name = 'VfMDSP_DCBusCur_Filtered_A';
elems(3).Dimensions = [1 1];
elems(3).DimensionsMode = 'Fixed';
elems(3).DataType = 'single';
elems(3).Complexity = 'real';
elems(3).Min = [];
elems(3).Max = [];
elems(3).DocUnits = '';
elems(3).Description = '';

elems(4) = Simulink.BusElement;
elems(4).Name = 'VfMDSP_DCBusVoltCtrl_V';
elems(4).Dimensions = 1;
elems(4).DimensionsMode = 'Fixed';
elems(4).DataType = 'single';
elems(4).Complexity = 'real';
elems(4).Min = [];
elems(4).Max = [];
elems(4).DocUnits = 'V';
elems(4).Description = ...
    'Validity-qualified filtered DC-bus voltage for control algorithms';

elems(5) = Simulink.BusElement;
elems(5).Name = 'VfMDSP_DCBusVoltRaw_V';
elems(5).Dimensions = 1;
elems(5).DimensionsMode = 'Fixed';
elems(5).DataType = 'single';
elems(5).Complexity = 'real';
elems(5).Min = [];
elems(5).Max = [];
elems(5).DocUnits = 'V';
elems(5).Description = 'Unfiltered and unclamped DC-bus voltage for diagnostics';

elems(6) = Simulink.BusElement;
elems(6).Name = 'VfMDSP_DCBusVoltReport_V';
elems(6).Dimensions = 1;
elems(6).DimensionsMode = 'Fixed';
elems(6).DataType = 'single';
elems(6).Complexity = 'real';
elems(6).Min = [];
elems(6).Max = [];
elems(6).DocUnits = 'V';
elems(6).Description = 'Slow filtered voltage for telemetry';

elems(7) = Simulink.BusElement;
elems(7).Name = 'VbMDSP_DCBusVoltValid_flg';
elems(7).Dimensions = 1;
elems(7).DimensionsMode = 'Fixed';
elems(7).DataType = 'boolean';
elems(7).Complexity = 'real';
elems(7).Min = 0;
elems(7).Max = 1;
elems(7).DocUnits = 'flg';
elems(7).Description = 'Raw voltage is finite and inside the plausibility range';

elems(8) = Simulink.BusElement;
elems(8).Name = 'VfMDSP_DCBusCurRaw_A';
elems(8).Dimensions = 1;
elems(8).DimensionsMode = 'Fixed';
elems(8).DataType = 'single';
elems(8).Complexity = 'real';
elems(8).Min = [];
elems(8).Max = [];
elems(8).DocUnits = 'A';
elems(8).Description = 'Selected unfiltered DC-bus current';

elems(9) = Simulink.BusElement;
elems(9).Name = 'VbMDSP_DCBusCurValid_flg';
elems(9).Dimensions = 1;
elems(9).DimensionsMode = 'Fixed';
elems(9).DataType = 'boolean';
elems(9).Complexity = 'real';
elems(9).Min = 0;
elems(9).Max = 1;
elems(9).DocUnits = 'flg';
elems(9).Description = 'Selected DC-bus current source validity';

elems(10) = Simulink.BusElement;
elems(10).Name = 'VuMDSP_DCBusCurSource_enum';
elems(10).Dimensions = 1;
elems(10).DimensionsMode = 'Fixed';
elems(10).DataType = 'uint8';
elems(10).Complexity = 'real';
elems(10).Min = 0;
elems(10).Max = 1;
elems(10).DocUnits = 'enum';
elems(10).Description = '0=physical sensor, 1=FOC duty/current estimate';

% Shared control currents: preserve raw samples in Direct_Output for MDFM.
% One invalid phase is reconstructed; two or more produce a neutral vector.
elems(11) = Simulink.BusElement;
elems(11).Name = 'VfMDSP_PhaseUCurrentCtrl_A';
elems(11).Dimensions = 1;
elems(11).DataType = 'single';
elems(11).DocUnits = 'A';
elems(11).Description = 'Conditioned phase U current for current control and observer';

elems(12) = Simulink.BusElement;
elems(12).Name = 'VfMDSP_PhaseVCurrentCtrl_A';
elems(12).Dimensions = 1;
elems(12).DataType = 'single';
elems(12).DocUnits = 'A';
elems(12).Description = 'Conditioned phase V current for current control and observer';

elems(13) = Simulink.BusElement;
elems(13).Name = 'VfMDSP_PhaseWCurrentCtrl_A';
elems(13).Dimensions = 1;
elems(13).DataType = 'single';
elems(13).DocUnits = 'A';
elems(13).Description = 'Conditioned phase W current for current control and observer';

MDSP_output = Simulink.Bus;
MDSP_output.HeaderFile = '';
MDSP_output.Description = '';
MDSP_output.DataScope = 'Auto';
MDSP_output.Alignment = -1;
MDSP_output.PreserveElementDimensions = 0;
MDSP_output.Elements = elems;
clear elems;
assignin('base','MDSP_output', MDSP_output);

% Bus object: MDTM_output
clear elems;
elems(1) = Simulink.BusElement;
elems(1).Name = 'VfMDTM_IqCmd_A';
elems(1).Dimensions = 1;
elems(1).DimensionsMode = 'Fixed';
elems(1).DataType = 'single';
elems(1).Complexity = 'real';
elems(1).Min = [];
elems(1).Max = [];
elems(1).DocUnits = 'A';
elems(1).Description = '';

elems(2) = Simulink.BusElement;
elems(2).Name = 'VfMDTM_IdCmd_A';
elems(2).Dimensions = 1;
elems(2).DimensionsMode = 'Fixed';
elems(2).DataType = 'single';
elems(2).Complexity = 'real';
elems(2).Min = [];
elems(2).Max = [];
elems(2).DocUnits = 'A';
elems(2).Description = '';

elems(3) = Simulink.BusElement;
elems(3).Name = 'VfMDTM_IqLimit_A';
elems(3).Dimensions = 1;
elems(3).DimensionsMode = 'Fixed';
elems(3).DataType = 'single';
elems(3).Complexity = 'real';
elems(3).Min = 0;
elems(3).Max = [];
elems(3).DocUnits = 'A';
elems(3).Description = 'Final q-axis current magnitude limit';

elems(4) = Simulink.BusElement;
elems(4).Name = 'VfMDTM_CurrentUtilization_NULL';
elems(4).Dimensions = 1;
elems(4).DimensionsMode = 'Fixed';
elems(4).DataType = 'single';
elems(4).Complexity = 'real';
elems(4).Min = 0;
elems(4).Max = 2;
elems(4).DocUnits = 'NULL';
elems(4).Description = 'Command current-vector utilization';

elems(5) = Simulink.BusElement;
elems(5).Name = 'VfMDTM_VoltageUtilizationEst_NULL';
elems(5).Dimensions = 1;
elems(5).DimensionsMode = 'Fixed';
elems(5).DataType = 'single';
elems(5).Complexity = 'real';
elems(5).Min = 0;
elems(5).Max = [];
elems(5).DocUnits = 'NULL';
elems(5).Description = 'Steady-state PMSM voltage-model utilization';

elems(6) = Simulink.BusElement;
elems(6).Name = 'VbMDTM_FieldWeakeningActive_flg';
elems(6).Dimensions = 1;
elems(6).DimensionsMode = 'Fixed';
elems(6).DataType = 'boolean';
elems(6).Complexity = 'real';
elems(6).Min = [];
elems(6).Max = [];
elems(6).DocUnits = 'flg';
elems(6).Description = 'Sensored PMSM field-weakening state';

elems(7) = Simulink.BusElement;
elems(7).Name = 'VbMDTM_CurrentLimited_flg';
elems(7).Dimensions = 1;
elems(7).DimensionsMode = 'Fixed';
elems(7).DataType = 'boolean';
elems(7).Complexity = 'real';
elems(7).Min = [];
elems(7).Max = [];
elems(7).DocUnits = 'flg';
elems(7).Description = 'Current-circle constraint active';

elems(8) = Simulink.BusElement;
elems(8).Name = 'VfMDTM_FieldWeakeningId_A';
elems(8).Dimensions = 1;
elems(8).DimensionsMode = 'Fixed';
elems(8).DataType = 'single';
elems(8).Complexity = 'real';
elems(8).Min = [];
elems(8).Max = 0;
elems(8).DocUnits = 'A';
elems(8).Description = 'Field-weakening d-axis contribution';

elems(9) = Simulink.BusElement;
elems(9).Name = 'VfMDTM_IqAntiWindupFeedback_A';
elems(9).Dimensions = 1;
elems(9).DimensionsMode = 'Fixed';
elems(9).DataType = 'single';
elems(9).Complexity = 'real';
elems(9).Min = [];
elems(9).Max = [];
elems(9).DocUnits = 'A';
elems(9).Description = ...
    'Final torque-equivalent q-axis command returned to speed PI tracking';

elems(10) = Simulink.BusElement;
elems(10).Name = 'VfMDTM_TorqueRequest_Nm';
elems(10).Dimensions = 1;
elems(10).DimensionsMode = 'Fixed';
elems(10).DataType = 'single';
elems(10).Complexity = 'real';
elems(10).Min = [];
elems(10).Max = [];
elems(10).DocUnits = '';
elems(10).Description = ...
    'Torque request represented by the upstream equivalent current';

elems(11) = Simulink.BusElement;
elems(11).Name = 'VfMDTM_TorqueEstimate_Nm';
elems(11).Dimensions = 1;
elems(11).DimensionsMode = 'Fixed';
elems(11).DataType = 'single';
elems(11).Complexity = 'real';
elems(11).Min = [];
elems(11).Max = [];
elems(11).DocUnits = '';
elems(11).Description = ...
    'Electromagnetic torque estimate after Id/Iq constraints';

elems(12) = Simulink.BusElement;
elems(12).Name = 'VbMDTM_MtpaActive_flg';
elems(12).Dimensions = 1;
elems(12).DimensionsMode = 'Fixed';
elems(12).DataType = 'boolean';
elems(12).Complexity = 'real';
elems(12).Min = [];
elems(12).Max = [];
elems(12).DocUnits = 'flg';
elems(12).Description = ...
    'IPMSM MTPA current-reference allocation active';

MDTM_output = Simulink.Bus;
MDTM_output.HeaderFile = '';
MDTM_output.Description = '';
MDTM_output.DataScope = 'Auto';
MDTM_output.Alignment = -1;
MDTM_output.PreserveElementDimensions = 0;
MDTM_output.Elements = elems;
clear elems;
assignin('base','MDTM_output', MDTM_output);

% Bus object: Resolver_Output
clear elems;
elems(1) = Simulink.BusElement;
elems(1).Name = 'VuMDSP_MotEAngle_NULL';
elems(1).Dimensions = 1;
elems(1).DimensionsMode = 'Fixed';
elems(1).DataType = 'uint16';
elems(1).Complexity = 'real';
elems(1).Min = [];
elems(1).Max = [];
elems(1).DocUnits = '';
elems(1).Description = '';

elems(2) = Simulink.BusElement;
elems(2).Name = 'VuMDSP_MotMechAngleRaw_NULL';
elems(2).Dimensions = 1;
elems(2).DimensionsMode = 'Fixed';
elems(2).DataType = 'uint32';
elems(2).Complexity = 'real';
elems(2).Min = [];
elems(2).Max = [];
elems(2).DocUnits = '';
elems(2).Description = '';

Resolver_Output = Simulink.Bus;
Resolver_Output.HeaderFile = '';
Resolver_Output.Description = '';
Resolver_Output.DataScope = 'Auto';
Resolver_Output.Alignment = -1;
Resolver_Output.PreserveElementDimensions = 0;
Resolver_Output.Elements = elems;
clear elems;
assignin('base','Resolver_Output', Resolver_Output);

% Bus object: MDAS_output
clear elems;
elems(1) = Simulink.BusElement;
elems(1).Name = 'VfMDAS_MotMechSpdFiltered_rads';
elems(1).Dimensions = 1;
elems(1).DimensionsMode = 'Fixed';
elems(1).DataType = 'single';
elems(1).Complexity = 'real';
elems(1).Min = [];
elems(1).Max = [];
elems(1).DocUnits = 'rad/s';
elems(1).Description = 'Selected mechanical angular speed';

elems(2) = Simulink.BusElement;
elems(2).Name = 'VfMDAS_MotMechSpdFilteredAbs_rads';
elems(2).Dimensions = 1;
elems(2).DimensionsMode = 'Fixed';
elems(2).DataType = 'single';
elems(2).Complexity = 'real';
elems(2).Min = [];
elems(2).Max = [];
elems(2).DocUnits = 'rad/s';
elems(2).Description = 'Absolute selected mechanical angular speed';

elems(3) = Simulink.BusElement;
elems(3).Name = 'VfMDAS_MotElecSpd_rads';
elems(3).Dimensions = 1;
elems(3).DimensionsMode = 'Fixed';
elems(3).DataType = 'single';
elems(3).Complexity = 'real';
elems(3).Min = [];
elems(3).Max = [];
elems(3).DocUnits = 'rad/s';
elems(3).Description = 'Selected electrical angular speed';

elems(4) = Simulink.BusElement;
elems(4).Name = 'VbMDAS_SmoReady_flg';
elems(4).Dimensions = 1;
elems(4).DimensionsMode = 'Fixed';
elems(4).DataType = 'boolean';
elems(4).Complexity = 'real';
elems(4).Min = [];
elems(4).Max = [];
elems(4).DocUnits = '';
elems(4).Description = '';

elems(5) = Simulink.BusElement;
elems(5).Name = 'VfMDAS_HandoverBlend_NULL';
elems(5).Dimensions = 1;
elems(5).DimensionsMode = 'Fixed';
elems(5).DataType = 'single';
elems(5).Complexity = 'real';
elems(5).Min = 0;
elems(5).Max = 1;
elems(5).DocUnits = '';
elems(5).Description = 'Direct I/F-to-observer handover blend weight';

elems(6) = Simulink.BusElement;
elems(6).Name = 'VfMDAS_HandoverElecAngleDelta_rad';
elems(6).Dimensions = 1;
elems(6).DimensionsMode = 'Fixed';
elems(6).DataType = 'single';
elems(6).Complexity = 'real';
elems(6).Min = -pi;
elems(6).Max = pi;
elems(6).DocUnits = 'rad';
elems(6).Description = 'Electrical source-frame angle minus active blended electrical control angle';

elems(7) = Simulink.BusElement;
elems(7).Name = 'VfMDAS_MotMechAngle_rad';
elems(7).Dimensions = 1;
elems(7).DimensionsMode = 'Fixed';
elems(7).DataType = 'single';
elems(7).Complexity = 'real';
elems(7).Min = 0;
elems(7).Max = 2*pi;
elems(7).DocUnits = 'rad';
elems(7).Description = 'Generic mechanical angle';

elems(8) = Simulink.BusElement;
elems(8).Name = 'VfMDAS_MotElecAngle_rad';
elems(8).Dimensions = 1;
elems(8).DimensionsMode = 'Fixed';
elems(8).DataType = 'single';
elems(8).Complexity = 'real';
elems(8).Min = 0;
elems(8).Max = 2*pi;
elems(8).DocUnits = 'rad';
elems(8).Description = 'Generic selected electrical control angle';

elems(9) = Simulink.BusElement;
elems(9).Name = 'VbMDAS_PositionAngleValid_flg';
elems(9).Dimensions = 1;
elems(9).DimensionsMode = 'Fixed';
elems(9).DataType = 'boolean';
elems(9).Complexity = 'real';
elems(9).Min = [];
elems(9).Max = [];
elems(9).DocUnits = 'flg';
elems(9).Description = 'Selected angle validity';

elems(10) = Simulink.BusElement;
elems(10).Name = 'VbMDAS_PositionSpeedValid_flg';
elems(10).Dimensions = 1;
elems(10).DimensionsMode = 'Fixed';
elems(10).DataType = 'boolean';
elems(10).Complexity = 'real';
elems(10).Min = [];
elems(10).Max = [];
elems(10).DocUnits = 'flg';
elems(10).Description = 'Selected speed validity';

elems(11) = Simulink.BusElement;
elems(11).Name = 'VfMDAS_PositionQuality_NULL';
elems(11).Dimensions = 1;
elems(11).DimensionsMode = 'Fixed';
elems(11).DataType = 'single';
elems(11).Complexity = 'real';
elems(11).Min = 0;
elems(11).Max = 1;
elems(11).DocUnits = 'NULL';
elems(11).Description = 'Normalized selected source quality';

elems(12) = Simulink.BusElement;
elems(12).Name = 'VeMDAS_PositionDirection_enum';
elems(12).Dimensions = 1;
elems(12).DimensionsMode = 'Fixed';
elems(12).DataType = 'int8';
elems(12).Complexity = 'real';
elems(12).Min = -1;
elems(12).Max = 1;
elems(12).DocUnits = 'enum';
elems(12).Description = 'Mechanical rotation direction';

MDAS_output = Simulink.Bus;
MDAS_output.HeaderFile = '';
MDAS_output.Description = '';
MDAS_output.DataScope = 'Auto';
MDAS_output.Alignment = -1;
MDAS_output.PreserveElementDimensions = 0;
MDAS_output.Elements = elems;
clear elems;
assignin('base','MDAS_output', MDAS_output);

% Stable board-adapter output from the code-generation shell only.
% Keep generated types private to ymbox_model_adapter.c.
hardwareNames = {'dutyU','dutyV','dutyW','mode','stopRequest', ...
    'pwmDisableRequest','faultLatched','faultCode','clearReady', ...
    'rawFaultMask','latchedFaultMask','warningActive','faultAction', ...
    'torqueLimitFactor','id_A','iq_A','vdc_V'};
hardwareTypes = {'single','single','single','uint16','boolean', ...
    'boolean','boolean','uint16','boolean','uint32','uint32', ...
    'boolean','uint8','single','single','single','single'};
clear elems;
for hardwareIndex = 1:numel(hardwareNames)
    elems(hardwareIndex) = Simulink.BusElement;
    elems(hardwareIndex).Name = hardwareNames{hardwareIndex};
    elems(hardwareIndex).DataType = hardwareTypes{hardwareIndex};
    elems(hardwareIndex).Dimensions = 1;
end
YMBOX_HardwareOutputBus = Simulink.Bus;
YMBOX_HardwareOutputBus.Elements = elems;
YMBOX_HardwareOutputBus.Description = ...
    'Hardware output contract v1; PWM permission is finalized by YMBOX runtime.';
assignin('base','YMBOX_HardwareOutputBus',YMBOX_HardwareOutputBus);
clear elems hardwareNames hardwareTypes hardwareIndex;

