% Range validation belongs to the configuration calculator and import checks.
% Leave data-object Min/Max unspecified; runtime limits use configured values.
VMIN_ECAN_MCUEnb_flg = Simulink.Signal;
VMIN_ECAN_MCUEnb_flg.RTWInfo.StorageClass = 'ExportedGlobal';
VMIN_ECAN_MCUEnb_flg.DataType = 'boolean';
VMIN_ECAN_MCUEnb_flg.DocUnits = 'flg';
VMIN_ECAN_MCUEnb_flg.InitialValue = '0';

VMIN_ECAN_MotWrkMd_enum = Simulink.Signal;
VMIN_ECAN_MotWrkMd_enum.RTWInfo.StorageClass = 'ExportedGlobal';
VMIN_ECAN_MotWrkMd_enum.DataType = 'uint16';
VMIN_ECAN_MotWrkMd_enum.DocUnits = 'enum';
VMIN_ECAN_MotWrkMd_enum.InitialValue = '0';
VMIN_ECAN_MotWrkMd_enum.Description = ...
    'Public drive-mode request interface, 0..10; values 7..10 reserved';

VMIN_ECAN_MotTrgtSpd_rpm = Simulink.Signal;
VMIN_ECAN_MotTrgtSpd_rpm.RTWInfo.StorageClass = 'ExportedGlobal';
VMIN_ECAN_MotTrgtSpd_rpm.DataType = 'single';
VMIN_ECAN_MotTrgtSpd_rpm.DocUnits = 'rpm';
VMIN_ECAN_MotTrgtSpd_rpm.InitialValue = '0';

VMIN_ECAN_MotTrgtTq_Nm = Simulink.Signal;
VMIN_ECAN_MotTrgtTq_Nm.RTWInfo.StorageClass = 'ExportedGlobal';
VMIN_ECAN_MotTrgtTq_Nm.DataType = 'single';
VMIN_ECAN_MotTrgtTq_Nm.DocUnits = 'N*m';
VMIN_ECAN_MotTrgtTq_Nm.InitialValue = '0';

% Increment once for every accepted command frame. MDFM detects a stale
% counter only after the first increment, so legacy simulations remain
% compatible while production communication adapters can enable supervision.
VMIN_ECAN_CommandAliveCounter_u16 = Simulink.Signal;
VMIN_ECAN_CommandAliveCounter_u16.RTWInfo.StorageClass = 'ExportedGlobal';
VMIN_ECAN_CommandAliveCounter_u16.DataType = 'uint16';
VMIN_ECAN_CommandAliveCounter_u16.DocUnits = 'cnt';
VMIN_ECAN_CommandAliveCounter_u16.InitialValue = '0';

VMIN_ECAN_ClearFaultRequest_flg = Simulink.Signal;
VMIN_ECAN_ClearFaultRequest_flg.RTWInfo.StorageClass = 'ExportedGlobal';
VMIN_ECAN_ClearFaultRequest_flg.DataType = 'boolean';
VMIN_ECAN_ClearFaultRequest_flg.DocUnits = 'flg';
VMIN_ECAN_ClearFaultRequest_flg.InitialValue = '0';

% Logical event age: 0 selects the latest record, 1 the previous record.
VMIN_ECAN_FaultHistoryReadIndex_u8 = Simulink.Signal;
VMIN_ECAN_FaultHistoryReadIndex_u8.RTWInfo.StorageClass = 'ExportedGlobal';
VMIN_ECAN_FaultHistoryReadIndex_u8.DataType = 'uint8';
VMIN_ECAN_FaultHistoryReadIndex_u8.DocUnits = 'cnt';
VMIN_ECAN_FaultHistoryReadIndex_u8.InitialValue = '0';
