% Range validation belongs to the configuration calculator and import checks.
% Leave data-object Min/Max unspecified; runtime limits use configured values.
% Runtime publisher for legacy motor and simulation calibration objects.
% Values come from the single
% context resolved by YMBOX_InitializeModel. This script deliberately does
% not load defaults, merge profiles, or calculate parameters.
assert(exist('YMBOX_Drive_Config','var') && ...
    isstruct(YMBOX_Drive_Config), ...
    'YMBOX:Initialization:MissingDriveConfig', ...
    'Run YMBOX_InitializeModel before YMBOX_MotorParameter.');
assert(exist('YMBOX_Drive_Derived','var') && ...
    isstruct(YMBOX_Drive_Derived), ...
    'YMBOX:Initialization:MissingDriveDerived', ...
    'Run YMBOX_InitializeModel before YMBOX_MotorParameter.');

% Simulation-only switching-plant timing.  Edit
% cfg.Inverter.DeadTime_s in YMBOX_Drive_Parameters; these named values keep
% the model dialogs readable and prevent scattered timing constants.

KfSIM_PowerStageStep_s = double( ...
    YMBOX_Drive_Derived.Simulation.PowerStageStep_s);

KfSIM_PwmPeriod_s = double(YMBOX_Drive_Derived.PwmPeriod_s);

KfSIM_PwmDeadTime_s = double( ...
    YMBOX_Drive_Derived.Simulation.PwmDeadTimeRequested_s);

KuSIM_PwmDeadTimeSteps_NULL = uint16( ...
    YMBOX_Drive_Derived.Simulation.PwmDeadTimeSteps_NULL);

KfSIM_PwmDeadTimeEffective_s = double( ...
    YMBOX_Drive_Derived.Simulation.PwmDeadTimeEffective_s);

KuMDMP_Pole_Pair_Number_NULL = mpt.Parameter;
KuMDMP_Pole_Pair_Number_NULL.Value = ...
    uint16(YMBOX_Drive_Config.Motor.PolePairs);
KuMDMP_Pole_Pair_Number_NULL.DataType = 'uint16';
KuMDMP_Pole_Pair_Number_NULL.StorageClass = 'Const (Custom)';
KuMDMP_Pole_Pair_Number_NULL.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KuMDMP_Pole_Pair_Number_NULL.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KuMDMP_Pole_Pair_Number_NULL.DocUnits = 'NULL';

KfMDMP_EquiInductanceValueD_H = mpt.Parameter;
KfMDMP_EquiInductanceValueD_H.Value = ...
    YMBOX_Drive_Config.Motor.Ld_H;
KfMDMP_EquiInductanceValueD_H.DataType = 'single';
KfMDMP_EquiInductanceValueD_H.StorageClass = 'Const (Custom)';
KfMDMP_EquiInductanceValueD_H.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDMP_EquiInductanceValueD_H.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDMP_EquiInductanceValueD_H.DocUnits = 'H';

KfMDMP_EquiInductanceValueQ_H = mpt.Parameter;
KfMDMP_EquiInductanceValueQ_H.Value = ...
    YMBOX_Drive_Config.Motor.Lq_H;
KfMDMP_EquiInductanceValueQ_H.DataType = 'single';
KfMDMP_EquiInductanceValueQ_H.StorageClass = 'Const (Custom)';
KfMDMP_EquiInductanceValueQ_H.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDMP_EquiInductanceValueQ_H.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDMP_EquiInductanceValueQ_H.DocUnits = 'H';

KfMDMP_EquiFluxValue_Wb = mpt.Parameter;
KfMDMP_EquiFluxValue_Wb.Value = ...
    YMBOX_Drive_Config.Motor.PmFlux_Wb;
KfMDMP_EquiFluxValue_Wb.DataType = 'single';
KfMDMP_EquiFluxValue_Wb.StorageClass = 'Const (Custom)';
KfMDMP_EquiFluxValue_Wb.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDMP_EquiFluxValue_Wb.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDMP_EquiFluxValue_Wb.DocUnits = 'Wb';

KuMDMP_ResolverPosition_Number_NULL = mpt.Parameter;
KuMDMP_ResolverPosition_Number_NULL.Value = uint16( ...
    YMBOX_Drive_Config.PositionSensor.ControlAngleCounts);
KuMDMP_ResolverPosition_Number_NULL.DataType = 'uint16';
KuMDMP_ResolverPosition_Number_NULL.StorageClass = 'Const (Custom)';
KuMDMP_ResolverPosition_Number_NULL.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KuMDMP_ResolverPosition_Number_NULL.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KuMDMP_ResolverPosition_Number_NULL.DocUnits = 'NULL';

KfMDMP_ResolverPosition_Number_by2pi_NULL = mpt.Parameter;
KfMDMP_ResolverPosition_Number_by2pi_NULL.Value = ...
    YMBOX_Drive_Config.PositionSensor.ControlAngleCounts/(2*pi);
KfMDMP_ResolverPosition_Number_by2pi_NULL.DataType = 'single';
KfMDMP_ResolverPosition_Number_by2pi_NULL.StorageClass = 'Const (Custom)';
KfMDMP_ResolverPosition_Number_by2pi_NULL.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDMP_ResolverPosition_Number_by2pi_NULL.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDMP_ResolverPosition_Number_by2pi_NULL.DocUnits = 'NULL';
KfMDMP_ResolverPosition_Number_by2pi_NULL.Description = 'ResolverPosition_Number devided by 2pi';
