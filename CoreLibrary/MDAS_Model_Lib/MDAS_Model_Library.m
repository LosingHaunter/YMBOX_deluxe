% Range validation belongs to the configuration calculator and import checks.
% Leave data-object Min/Max unspecified; runtime limits use configured values.
% Consume the single drive/eSMO context published by
% YMBOX_InitializeModel. All rate-dependent parameters therefore use the
% same complete-control-task period.
assert(exist('YMBOX_Drive_Derived','var') && ...
    isstruct(YMBOX_Drive_Derived), ...
    'YMBOX:Initialization:MissingDriveDerived', ...
    'Run YMBOX_InitializeModel before MDAS_Model_Library.');
assert(exist('YMBOX_SMO_Config','var') && ...
    isstruct(YMBOX_SMO_Config) && ...
    exist('YMBOX_SMO_Derived','var') && ...
    isstruct(YMBOX_SMO_Derived), ...
    'YMBOX:Initialization:MissingSmoContext', ...
    'Run YMBOX_InitializeModel before MDAS_Model_Library.');
assert(exist('Cf_CONTROL_TASK_TIME_S','var'), ...
    'YMBOX:Initialization:MissingControlPeriod', ...
    'Run YMBOX_InitializeModel before MDAS_Model_Library.');
YMBOX_ControlPeriod_s = double(Cf_CONTROL_TASK_TIME_S);
assert(isfinite(YMBOX_ControlPeriod_s) && YMBOX_ControlPeriod_s > 0);

% Generic count-domain PLL. The estimator runs in native mechanical counts
% internally, then publishes the selected electrical angle as continuous
% single-precision radians. Trigonometric consumers normalize locally only
% when their backend requires a per-unit lookup-table input.

KfMDAS_SlsTwoPi_rad = mpt.Parameter;
KfMDAS_SlsTwoPi_rad.Value = 2 * pi;
KfMDAS_SlsTwoPi_rad.DataType = 'single';
KfMDAS_SlsTwoPi_rad.StorageClass = 'Const (Custom)';
KfMDAS_SlsTwoPi_rad.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_SlsTwoPi_rad.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_SlsTwoPi_rad.DocUnits = 'rad';

KfMDAS_SlsEAngleInit_rad = mpt.Parameter;
KfMDAS_SlsEAngleInit_rad.Value = 0;
KfMDAS_SlsEAngleInit_rad.DataType = 'single';
KfMDAS_SlsEAngleInit_rad.StorageClass = 'Const (Custom)';
KfMDAS_SlsEAngleInit_rad.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_SlsEAngleInit_rad.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_SlsEAngleInit_rad.DocUnits = 'rad';

KfPLL_PositionCountsPerRev_NULL = mpt.Parameter;
KfPLL_PositionCountsPerRev_NULL.Value = YMBOX_Drive_Derived.Position.NativeCountsPerMechanicalRev;
KfPLL_PositionCountsPerRev_NULL.DataType = 'single';
KfPLL_PositionCountsPerRev_NULL.StorageClass = 'Const (Custom)';
KfPLL_PositionCountsPerRev_NULL.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfPLL_PositionCountsPerRev_NULL.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfPLL_PositionCountsPerRev_NULL.DocUnits = 'cnt';

KfPLL_HalfPositionCounts_NULL = mpt.Parameter;
KfPLL_HalfPositionCounts_NULL.Value = YMBOX_Drive_Derived.Position.NativeHalfCount;
KfPLL_HalfPositionCounts_NULL.DataType = 'single';
KfPLL_HalfPositionCounts_NULL.StorageClass = 'Const (Custom)';
KfPLL_HalfPositionCounts_NULL.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfPLL_HalfPositionCounts_NULL.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfPLL_HalfPositionCounts_NULL.DocUnits = 'cnt';

KfPLL_ControlAngleCounts_NULL = mpt.Parameter;
KfPLL_ControlAngleCounts_NULL.Value = single( ...
    YMBOX_Drive_Derived.Position.ControlAngleCounts);
KfPLL_ControlAngleCounts_NULL.DataType = 'single';
KfPLL_ControlAngleCounts_NULL.StorageClass = 'Const (Custom)';
KfPLL_ControlAngleCounts_NULL.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfPLL_ControlAngleCounts_NULL.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfPLL_ControlAngleCounts_NULL.DocUnits = 'cnt';

KfPLL_CountToMechRad_radpercnt = mpt.Parameter;
KfPLL_CountToMechRad_radpercnt.Value = YMBOX_Drive_Derived.Position.NativeCountToMechRad;
KfPLL_CountToMechRad_radpercnt.DataType = 'single';
KfPLL_CountToMechRad_radpercnt.StorageClass = 'Const (Custom)';
KfPLL_CountToMechRad_radpercnt.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfPLL_CountToMechRad_radpercnt.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfPLL_CountToMechRad_radpercnt.DocUnits = 'NULL';

KfPLL_PolePairsNativeToControl_NULL = mpt.Parameter;
KfPLL_PolePairsNativeToControl_NULL.Value = ...
    single(YMBOX_Drive_Derived.Motor.PolePairs) * ...
    single(YMBOX_Drive_Derived.Position.SignedNativeToControlCount);
KfPLL_PolePairsNativeToControl_NULL.DataType = 'single';
KfPLL_PolePairsNativeToControl_NULL.StorageClass = 'Const (Custom)';
KfPLL_PolePairsNativeToControl_NULL.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfPLL_PolePairsNativeToControl_NULL.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfPLL_PolePairsNativeToControl_NULL.DocUnits = 'NULL';

% Backward-compatible resolver calibration aliases.  New model blocks use
% the generic position-count names above.
KfPLL_Bandwidth_rads = mpt.Parameter;
KfPLL_Bandwidth_rads.Value = ...
    YMBOX_Drive_Derived.Position.PllBandwidth_rads;
KfPLL_Bandwidth_rads.DataType = 'single';
KfPLL_Bandwidth_rads.StorageClass = 'Const (Custom)';
KfPLL_Bandwidth_rads.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfPLL_Bandwidth_rads.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfPLL_Bandwidth_rads.DocUnits = 'rads';

KfPLL_OneByFreq_s = mpt.Parameter;
KfPLL_OneByFreq_s.Value = YMBOX_ControlPeriod_s;
KfPLL_OneByFreq_s.DataType = 'single';
KfPLL_OneByFreq_s.StorageClass = 'Const (Custom)';
KfPLL_OneByFreq_s.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfPLL_OneByFreq_s.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfPLL_OneByFreq_s.DocUnits = 's';

KfMDAS_ControlCountToElecRad_NULL = mpt.Parameter;
KfMDAS_ControlCountToElecRad_NULL.Value = YMBOX_Drive_Derived.Position.ControlCountToElecRad;
KfMDAS_ControlCountToElecRad_NULL.DataType = 'single';
KfMDAS_ControlCountToElecRad_NULL.StorageClass = 'Const (Custom)';
KfMDAS_ControlCountToElecRad_NULL.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_ControlCountToElecRad_NULL.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_ControlCountToElecRad_NULL.DocUnits = 'NULL';

KfMDAS_NativeCountToMechRad_NULL = mpt.Parameter;
KfMDAS_NativeCountToMechRad_NULL.Value = YMBOX_Drive_Derived.Position.NativeCountToMechRad;
KfMDAS_NativeCountToMechRad_NULL.DataType = 'single';
KfMDAS_NativeCountToMechRad_NULL.StorageClass = 'Const (Custom)';
KfMDAS_NativeCountToMechRad_NULL.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_NativeCountToMechRad_NULL.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_NativeCountToMechRad_NULL.DocUnits = 'NULL';

% Sensorless observer parameters follow the selected control rate.
KfMDAS_SlsCtrlPeriod_s = mpt.Parameter;
KfMDAS_SlsCtrlPeriod_s.Value = YMBOX_ControlPeriod_s;
KfMDAS_SlsCtrlPeriod_s.DataType = 'single';
KfMDAS_SlsCtrlPeriod_s.StorageClass = 'Const (Custom)';
KfMDAS_SlsCtrlPeriod_s.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_SlsCtrlPeriod_s.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_SlsCtrlPeriod_s.DocUnits = 's';

% Sample-time parameters must be ordinary numeric values for discrete blocks.
KfMDAS_SlsCtrlPeriodSample_s = KfMDAS_SlsCtrlPeriod_s.Value;

KfMDAS_SmoDeadTimeDuty_NULL = mpt.Parameter;
KfMDAS_SmoDeadTimeDuty_NULL.Value = YMBOX_SMO_Derived.DeadTimeDutyFraction;
KfMDAS_SmoDeadTimeDuty_NULL.DataType = 'single';
KfMDAS_SmoDeadTimeDuty_NULL.StorageClass = 'Const (Custom)';
KfMDAS_SmoDeadTimeDuty_NULL.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_SmoDeadTimeDuty_NULL.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_SmoDeadTimeDuty_NULL.DocUnits = 'NULL';

KfMDAS_SmoDeviceDrop_V = mpt.Parameter;
KfMDAS_SmoDeviceDrop_V.Value = YMBOX_SMO_Derived.DeviceVoltageDrop_V;
KfMDAS_SmoDeviceDrop_V.DataType = 'single';
KfMDAS_SmoDeviceDrop_V.StorageClass = 'Const (Custom)';
KfMDAS_SmoDeviceDrop_V.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_SmoDeviceDrop_V.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_SmoDeviceDrop_V.DocUnits = 'V';

KfMDAS_SmoDeadTimeCurrentBoundary_A = mpt.Parameter;
KfMDAS_SmoDeadTimeCurrentBoundary_A.Value = ...
    YMBOX_SMO_Derived.DeadTimeCurrentBoundary_A;
KfMDAS_SmoDeadTimeCurrentBoundary_A.DataType = 'single';
KfMDAS_SmoDeadTimeCurrentBoundary_A.StorageClass = 'Const (Custom)';
KfMDAS_SmoDeadTimeCurrentBoundary_A.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_SmoDeadTimeCurrentBoundary_A.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_SmoDeadTimeCurrentBoundary_A.DocUnits = 'A';

KbMDAS_SmoDeadTimeCompEnable_flg = mpt.Parameter;
KbMDAS_SmoDeadTimeCompEnable_flg.Value = logical( ...
    YMBOX_SMO_Derived.DeadTimeCompEnable);
KbMDAS_SmoDeadTimeCompEnable_flg.DataType = 'boolean';
KbMDAS_SmoDeadTimeCompEnable_flg.StorageClass = 'Const (Custom)';
KbMDAS_SmoDeadTimeCompEnable_flg.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KbMDAS_SmoDeadTimeCompEnable_flg.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KbMDAS_SmoDeadTimeCompEnable_flg.DocUnits = 'flg';

KfMDAS_SmoDeadTimePolarity_NULL = mpt.Parameter;
KfMDAS_SmoDeadTimePolarity_NULL.Value = YMBOX_SMO_Derived.DeadTimePolarity;
KfMDAS_SmoDeadTimePolarity_NULL.DataType = 'single';
KfMDAS_SmoDeadTimePolarity_NULL.StorageClass = 'Const (Custom)';
KfMDAS_SmoDeadTimePolarity_NULL.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_SmoDeadTimePolarity_NULL.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_SmoDeadTimePolarity_NULL.DocUnits = 'NULL';

KfMDAS_SlsElecSpdMax_rads = mpt.Parameter;
KfMDAS_SlsElecSpdMax_rads.Value = YMBOX_SMO_Derived.MaxElecSpeed_rads;
KfMDAS_SlsElecSpdMax_rads.DataType = 'single';
KfMDAS_SlsElecSpdMax_rads.StorageClass = 'Const (Custom)';
KfMDAS_SlsElecSpdMax_rads.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_SlsElecSpdMax_rads.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_SlsElecSpdMax_rads.DocUnits = 'rads';

KfMDAS_SlsElecSpdMin_rads = mpt.Parameter;
KfMDAS_SlsElecSpdMin_rads.Value = -YMBOX_SMO_Derived.MaxElecSpeed_rads;
KfMDAS_SlsElecSpdMin_rads.DataType = 'single';
KfMDAS_SlsElecSpdMin_rads.StorageClass = 'Const (Custom)';
KfMDAS_SlsElecSpdMin_rads.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_SlsElecSpdMin_rads.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_SlsElecSpdMin_rads.DocUnits = 'rads';

% I/F open-loop startup and automatic MRAS handover.
KfMDAS_IfAccel_rpms = mpt.Parameter;
KfMDAS_IfAccel_rpms.Value = YMBOX_SMO_Derived.IfAccel_rpms;
KfMDAS_IfAccel_rpms.DataType = 'single';
KfMDAS_IfAccel_rpms.StorageClass = 'Const (Custom)';
KfMDAS_IfAccel_rpms.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_IfAccel_rpms.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_IfAccel_rpms.DocUnits = 'rpm/s';

% Smoothly build the I/F acceleration after the Id-to-Iq transition.  This
% permits a faster average start without applying an acceleration step.
KfMDAS_IfAccelBlendTime_s = mpt.Parameter;
KfMDAS_IfAccelBlendTime_s.Value = YMBOX_SMO_Derived.IfAccelBlendTime_s;
KfMDAS_IfAccelBlendTime_s.DataType = 'single';
KfMDAS_IfAccelBlendTime_s.StorageClass = 'Const (Custom)';
KfMDAS_IfAccelBlendTime_s.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_IfAccelBlendTime_s.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_IfAccelBlendTime_s.DocUnits = 's';

KfMDAS_IfAlignTime_s = mpt.Parameter;
KfMDAS_IfAlignTime_s.Value = YMBOX_SMO_Derived.IfAlignTime_s;
KfMDAS_IfAlignTime_s.DataType = 'single';
KfMDAS_IfAlignTime_s.StorageClass = 'Const (Custom)';
KfMDAS_IfAlignTime_s.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_IfAlignTime_s.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_IfAlignTime_s.DocUnits = 's';

KfMDAS_IfBlendTime_s = mpt.Parameter;
KfMDAS_IfBlendTime_s.Value = YMBOX_SMO_Derived.IfBlendTime_s;
KfMDAS_IfBlendTime_s.DataType = 'single';
KfMDAS_IfBlendTime_s.StorageClass = 'Const (Custom)';
KfMDAS_IfBlendTime_s.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_IfBlendTime_s.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_IfBlendTime_s.DocUnits = 's';

KfMDAS_IfSwitchSpd_rpm = mpt.Parameter;
KfMDAS_IfSwitchSpd_rpm.Value = YMBOX_SMO_Derived.IfSwitchSpeed_rpm;
KfMDAS_IfSwitchSpd_rpm.DataType = 'single';
KfMDAS_IfSwitchSpd_rpm.StorageClass = 'Const (Custom)';
KfMDAS_IfSwitchSpd_rpm.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_IfSwitchSpd_rpm.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_IfSwitchSpd_rpm.DocUnits = 'rpm';

% 4-kHz sliding-mode observer coefficients.
% Bounded production-eSMO injection schedule.  A delayed filtered-EMF
% magnitude is normalized and smoothed before interpolating between these
% limits, which keeps generated execution deterministic and algebraic-loop
% free while preserving the validated low-speed fixed-gain behavior.
KfMDAS_SmoSlideGainMin_V = mpt.Parameter;
KfMDAS_SmoSlideGainMin_V.Value = YMBOX_SMO_Derived.SlideGainMin_V;
KfMDAS_SmoSlideGainMin_V.DataType = 'single';
KfMDAS_SmoSlideGainMin_V.StorageClass = 'Const (Custom)';
KfMDAS_SmoSlideGainMin_V.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_SmoSlideGainMin_V.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_SmoSlideGainMin_V.DocUnits = 'V';

KfMDAS_SmoSlideGainSpan_V = mpt.Parameter;
KfMDAS_SmoSlideGainSpan_V.Value = YMBOX_SMO_Derived.SlideGainSpan_V;
KfMDAS_SmoSlideGainSpan_V.DataType = 'single';
KfMDAS_SmoSlideGainSpan_V.StorageClass = 'Const (Custom)';
KfMDAS_SmoSlideGainSpan_V.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_SmoSlideGainSpan_V.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_SmoSlideGainSpan_V.DocUnits = 'V';

KfMDAS_SmoErrBoundaryMax_A = mpt.Parameter;
KfMDAS_SmoErrBoundaryMax_A.Value = YMBOX_SMO_Derived.ErrBoundaryMax_A;
KfMDAS_SmoErrBoundaryMax_A.DataType = 'single';
KfMDAS_SmoErrBoundaryMax_A.StorageClass = 'Const (Custom)';
KfMDAS_SmoErrBoundaryMax_A.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_SmoErrBoundaryMax_A.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_SmoErrBoundaryMax_A.DocUnits = 'A';

KfMDAS_SmoErrBoundarySpan_A = mpt.Parameter;
KfMDAS_SmoErrBoundarySpan_A.Value = YMBOX_SMO_Derived.ErrBoundarySpan_A;
KfMDAS_SmoErrBoundarySpan_A.DataType = 'single';
KfMDAS_SmoErrBoundarySpan_A.StorageClass = 'Const (Custom)';
KfMDAS_SmoErrBoundarySpan_A.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_SmoErrBoundarySpan_A.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_SmoErrBoundarySpan_A.DocUnits = 'A';

KfMDAS_SmoGainSchedEmfLow_V = mpt.Parameter;
KfMDAS_SmoGainSchedEmfLow_V.Value = YMBOX_SMO_Derived.GainScheduleEmfLow_V;
KfMDAS_SmoGainSchedEmfLow_V.DataType = 'single';
KfMDAS_SmoGainSchedEmfLow_V.StorageClass = 'Const (Custom)';
KfMDAS_SmoGainSchedEmfLow_V.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_SmoGainSchedEmfLow_V.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_SmoGainSchedEmfLow_V.DocUnits = 'V';

KfMDAS_SmoGainSchedInvSpan_PerV = mpt.Parameter;
KfMDAS_SmoGainSchedInvSpan_PerV.Value = ...
    YMBOX_SMO_Derived.GainScheduleEmfSpanInv_PerV;
KfMDAS_SmoGainSchedInvSpan_PerV.DataType = 'single';
KfMDAS_SmoGainSchedInvSpan_PerV.StorageClass = 'Const (Custom)';
KfMDAS_SmoGainSchedInvSpan_PerV.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_SmoGainSchedInvSpan_PerV.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_SmoGainSchedInvSpan_PerV.DocUnits = '1/V';

KfMDAS_SmoGainSchedAlpha_NULL = mpt.Parameter;
KfMDAS_SmoGainSchedAlpha_NULL.Value = YMBOX_SMO_Derived.GainScheduleAlpha;
KfMDAS_SmoGainSchedAlpha_NULL.DataType = 'single';
KfMDAS_SmoGainSchedAlpha_NULL.StorageClass = 'Const (Custom)';
KfMDAS_SmoGainSchedAlpha_NULL.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_SmoGainSchedAlpha_NULL.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_SmoGainSchedAlpha_NULL.DocUnits = 'NULL';

KfMDAS_SmoGainSchedAngleComp_rad = mpt.Parameter;
KfMDAS_SmoGainSchedAngleComp_rad.Value = ...
    YMBOX_SMO_Derived.GainScheduleAngleComp_rad;
KfMDAS_SmoGainSchedAngleComp_rad.DataType = 'single';
KfMDAS_SmoGainSchedAngleComp_rad.StorageClass = 'Const (Custom)';
KfMDAS_SmoGainSchedAngleComp_rad.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_SmoGainSchedAngleComp_rad.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_SmoGainSchedAngleComp_rad.DocUnits = 'rad';

% Effective discrete current-model parameters identified at the MDAS 4-kHz
% sampling point.  The effective inductance includes PWM/ZOH and sampling
% delay, so it is intentionally larger than the physical phase inductance.
% Physical saliency coefficient for the extended-EMF voltage model.
KfMDAS_SmoLdMinusLq_H = mpt.Parameter;
KfMDAS_SmoLdMinusLq_H.Value = YMBOX_SMO_Derived.SaliencyInductance_H;
KfMDAS_SmoLdMinusLq_H.DataType = 'single';
KfMDAS_SmoLdMinusLq_H.StorageClass = 'Const (Custom)';
KfMDAS_SmoLdMinusLq_H.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_SmoLdMinusLq_H.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_SmoLdMinusLq_H.DocUnits = 'H';

KfMDAS_SmoCurrentZohCoefA_NULL = mpt.Parameter;
KfMDAS_SmoCurrentZohCoefA_NULL.Value = YMBOX_SMO_Derived.CurrentZohA;
KfMDAS_SmoCurrentZohCoefA_NULL.DataType = 'single';
KfMDAS_SmoCurrentZohCoefA_NULL.StorageClass = 'Const (Custom)';
KfMDAS_SmoCurrentZohCoefA_NULL.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_SmoCurrentZohCoefA_NULL.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_SmoCurrentZohCoefA_NULL.DocUnits = 'NULL';

KfMDAS_SmoCurrentZohCoefB_AperV = mpt.Parameter;
KfMDAS_SmoCurrentZohCoefB_AperV.Value = ...
    YMBOX_SMO_Derived.CurrentZohB_AperV;
KfMDAS_SmoCurrentZohCoefB_AperV.DataType = 'single';
KfMDAS_SmoCurrentZohCoefB_AperV.StorageClass = 'Const (Custom)';
KfMDAS_SmoCurrentZohCoefB_AperV.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_SmoCurrentZohCoefB_AperV.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_SmoCurrentZohCoefB_AperV.DocUnits = 'AperV';

KfMDAS_SmoEmfLpfPole_rads = mpt.Parameter;
KfMDAS_SmoEmfLpfPole_rads.Value = YMBOX_SMO_Derived.EmfLpfPole_rads;
KfMDAS_SmoEmfLpfPole_rads.DataType = 'single';
KfMDAS_SmoEmfLpfPole_rads.StorageClass = 'Const (Custom)';
KfMDAS_SmoEmfLpfPole_rads.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_SmoEmfLpfPole_rads.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_SmoEmfLpfPole_rads.DocUnits = 'rads';

% Constant inverse avoids a division in every observer interrupt.
KfMDAS_SmoEmfLpfInvPole_s = YMBOX_CreateCalParameter( ...
    single(1)/single(KfMDAS_SmoEmfLpfPole_rads.Value), ...
    'single', 's');


KfMDAS_SmoEmfLpfCoefA_NULL = mpt.Parameter;
KfMDAS_SmoEmfLpfCoefA_NULL.Value = YMBOX_SMO_Derived.EmfLpfA;
KfMDAS_SmoEmfLpfCoefA_NULL.DataType = 'single';
KfMDAS_SmoEmfLpfCoefA_NULL.StorageClass = 'Const (Custom)';
KfMDAS_SmoEmfLpfCoefA_NULL.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_SmoEmfLpfCoefA_NULL.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_SmoEmfLpfCoefA_NULL.DocUnits = 'NULL';

KfMDAS_SmoEmfLpfCoefB_NULL = mpt.Parameter;
KfMDAS_SmoEmfLpfCoefB_NULL.Value = YMBOX_SMO_Derived.EmfLpfB;
KfMDAS_SmoEmfLpfCoefB_NULL.DataType = 'single';
KfMDAS_SmoEmfLpfCoefB_NULL.StorageClass = 'Const (Custom)';
KfMDAS_SmoEmfLpfCoefB_NULL.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_SmoEmfLpfCoefB_NULL.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_SmoEmfLpfCoefB_NULL.DocUnits = 'NULL';

KfMDAS_SmoPllKp_NULL = mpt.Parameter;
KfMDAS_SmoPllKp_NULL.Value = YMBOX_SMO_Derived.PllKp;
KfMDAS_SmoPllKp_NULL.DataType = 'single';
KfMDAS_SmoPllKp_NULL.StorageClass = 'Const (Custom)';
KfMDAS_SmoPllKp_NULL.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_SmoPllKp_NULL.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_SmoPllKp_NULL.DocUnits = 'NULL';

KfMDAS_SmoPllKiTs_NULL = mpt.Parameter;
KfMDAS_SmoPllKiTs_NULL.Value = YMBOX_SMO_Derived.PllKiTs;
KfMDAS_SmoPllKiTs_NULL.DataType = 'single';
KfMDAS_SmoPllKiTs_NULL.StorageClass = 'Const (Custom)';
KfMDAS_SmoPllKiTs_NULL.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_SmoPllKiTs_NULL.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_SmoPllKiTs_NULL.DocUnits = 'NULL';

KfMDAS_SmoPllSpeedLpfAlpha_NULL = mpt.Parameter;
KfMDAS_SmoPllSpeedLpfAlpha_NULL.Value = YMBOX_SMO_Derived.PllSpeedLpfAlpha;
KfMDAS_SmoPllSpeedLpfAlpha_NULL.DataType = 'single';
KfMDAS_SmoPllSpeedLpfAlpha_NULL.StorageClass = 'Const (Custom)';
KfMDAS_SmoPllSpeedLpfAlpha_NULL.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_SmoPllSpeedLpfAlpha_NULL.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_SmoPllSpeedLpfAlpha_NULL.DocUnits = 'NULL';

KfMDAS_SmoPllMinEmf_V = mpt.Parameter;
KfMDAS_SmoPllMinEmf_V.Value = YMBOX_SMO_Derived.MinEmf_V;
KfMDAS_SmoPllMinEmf_V.DataType = 'single';
KfMDAS_SmoPllMinEmf_V.StorageClass = 'Const (Custom)';
KfMDAS_SmoPllMinEmf_V.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_SmoPllMinEmf_V.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_SmoPllMinEmf_V.DocUnits = 'V';

KfMDAS_SmoAngleOffset_rad = mpt.Parameter;
KfMDAS_SmoAngleOffset_rad.Value = YMBOX_SMO_Derived.StaticAngleOffset_rad;
KfMDAS_SmoAngleOffset_rad.DataType = 'single';
KfMDAS_SmoAngleOffset_rad.StorageClass = 'Const (Custom)';
KfMDAS_SmoAngleOffset_rad.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_SmoAngleOffset_rad.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_SmoAngleOffset_rad.DocUnits = 'rad';

KfMDAS_SmoTotalDelay_s = mpt.Parameter;
KfMDAS_SmoTotalDelay_s.Value = YMBOX_SMO_Derived.TotalDelay_s;
KfMDAS_SmoTotalDelay_s.DataType = 'single';
KfMDAS_SmoTotalDelay_s.StorageClass = 'Const (Custom)';
KfMDAS_SmoTotalDelay_s.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_SmoTotalDelay_s.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_SmoTotalDelay_s.DocUnits = 's';

% Passive-observer sweep: SMO phase is inside 30 electrical degrees from
% 2000 rpm is the lowest validated direct-SMO pickup threshold.  The 100-ms
% continuous quality counter moves the actual takeover to about 2090 rpm.
KfMDAS_SmoSwitchSpd_rpm = mpt.Parameter;
KfMDAS_SmoSwitchSpd_rpm.Value = YMBOX_SMO_Derived.SwitchSpeed_rpm;
KfMDAS_SmoSwitchSpd_rpm.DataType = 'single';
KfMDAS_SmoSwitchSpd_rpm.StorageClass = 'Const (Custom)';
KfMDAS_SmoSwitchSpd_rpm.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_SmoSwitchSpd_rpm.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_SmoSwitchSpd_rpm.DocUnits = 'rpm';

KfMDAS_SmoReadySpdErr_rads = mpt.Parameter;
KfMDAS_SmoReadySpdErr_rads.Value = YMBOX_SMO_Derived.ReadySpeedError_rads;
KfMDAS_SmoReadySpdErr_rads.DataType = 'single';
KfMDAS_SmoReadySpdErr_rads.StorageClass = 'Const (Custom)';
KfMDAS_SmoReadySpdErr_rads.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_SmoReadySpdErr_rads.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_SmoReadySpdErr_rads.DocUnits = 'rad/s';

KfMDAS_SmoReadyPllErr_NULL = mpt.Parameter;
KfMDAS_SmoReadyPllErr_NULL.Value = YMBOX_SMO_Derived.ReadyPllError;
KfMDAS_SmoReadyPllErr_NULL.DataType = 'single';
KfMDAS_SmoReadyPllErr_NULL.StorageClass = 'Const (Custom)';
KfMDAS_SmoReadyPllErr_NULL.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_SmoReadyPllErr_NULL.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_SmoReadyPllErr_NULL.DocUnits = 'NULL';

% Direct I/F -> observer angle/current handover time.  The transition uses a
% captured circular phase offset and a smoothstep weight, so 0%% is exactly
% the I/F frame and 100%% is exactly the observer frame.
YMBOX_DirectHandoverTime_s = YMBOX_SMO_Derived.DirectHandoverTime_s;
if exist('YMBOX_DirectHandoverTimeOverride_s','var') && ...
        isfinite(YMBOX_DirectHandoverTimeOverride_s)
    YMBOX_DirectHandoverTime_s = min(0.5,max(0.02,double(YMBOX_DirectHandoverTimeOverride_s)));
end
KfMDAS_DirectHandoverTime_s = mpt.Parameter;
KfMDAS_DirectHandoverTime_s.Value = YMBOX_DirectHandoverTime_s;
KfMDAS_DirectHandoverTime_s.DataType = 'single';
KfMDAS_DirectHandoverTime_s.StorageClass = 'Const (Custom)';
KfMDAS_DirectHandoverTime_s.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_DirectHandoverTime_s.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_DirectHandoverTime_s.DocUnits = 's';
clear YMBOX_DirectHandoverTime_s;

KuMDAS_SmoReadyConfirmCnt = mpt.Parameter;
KuMDAS_SmoReadyConfirmCnt.Value = YMBOX_SMO_Derived.SmoReadyConfirmCount;
KuMDAS_SmoReadyConfirmCnt.DataType = 'uint16';
KuMDAS_SmoReadyConfirmCnt.StorageClass = 'Const (Custom)';
KuMDAS_SmoReadyConfirmCnt.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KuMDAS_SmoReadyConfirmCnt.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KuMDAS_SmoReadyConfirmCnt.DocUnits = 'cnt';

% Observer-specific acquisition and health qualification.  Each observer
% has an independent threshold and confirmation counter; no shared AUX
% qualification state is retained.
KfMDAS_ObserverExitRatio_NULL = mpt.Parameter;
KfMDAS_ObserverExitRatio_NULL.Value = YMBOX_SMO_Derived.ObserverExitRatio;
KfMDAS_ObserverExitRatio_NULL.DataType = 'single';
KfMDAS_ObserverExitRatio_NULL.StorageClass = 'Const (Custom)';
KfMDAS_ObserverExitRatio_NULL.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
KfMDAS_ObserverExitRatio_NULL.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
KfMDAS_ObserverExitRatio_NULL.DocUnits = 'NULL';

% LEO uses K*(ihat-i) as the estimated back-EMF injection, so the raw
% current error is intentionally proportional to back EMF and is not a
% zero-residual health metric.  Qualify on injection headroom instead.
VfMDAS_MotMechSpdFiltered_rads = Simulink.Signal;
VfMDAS_MotMechSpdFiltered_rads.RTWInfo.StorageClass = 'ExportedGlobal';
VfMDAS_MotMechSpdFiltered_rads.DataType = 'single';
VfMDAS_MotMechSpdFiltered_rads.DocUnits = 'rad/s';

VfMDAS_MotMechSpdFilteredAbs_rads = Simulink.Signal;
VfMDAS_MotMechSpdFilteredAbs_rads.RTWInfo.StorageClass = 'ExportedGlobal';
VfMDAS_MotMechSpdFilteredAbs_rads.DataType = 'single';
VfMDAS_MotMechSpdFilteredAbs_rads.DocUnits = 'rad/s';

VfMDAS_MotElecSpd_rads = Simulink.Signal;
VfMDAS_MotElecSpd_rads.RTWInfo.StorageClass = 'ExportedGlobal';
VfMDAS_MotElecSpd_rads.DataType = 'single';
VfMDAS_MotElecSpd_rads.DocUnits = 'rad/s';

VfMDAS_MotMechAngle_rad = Simulink.Signal;
VfMDAS_MotMechAngle_rad.RTWInfo.StorageClass = 'ExportedGlobal';
VfMDAS_MotMechAngle_rad.DataType = 'single';
VfMDAS_MotMechAngle_rad.DocUnits = 'rad';

VfMDAS_MotElecAngle_rad = Simulink.Signal;
VfMDAS_MotElecAngle_rad.RTWInfo.StorageClass = 'ExportedGlobal';
VfMDAS_MotElecAngle_rad.DataType = 'single';
VfMDAS_MotElecAngle_rad.DocUnits = 'rad';

VbMDAS_PositionAngleValid_flg = Simulink.Signal;
VbMDAS_PositionAngleValid_flg.RTWInfo.StorageClass = 'ExportedGlobal';
VbMDAS_PositionAngleValid_flg.DataType = 'boolean';
VbMDAS_PositionAngleValid_flg.DocUnits = 'flg';

VbMDAS_PositionSpeedValid_flg = Simulink.Signal;
VbMDAS_PositionSpeedValid_flg.RTWInfo.StorageClass = 'ExportedGlobal';
VbMDAS_PositionSpeedValid_flg.DataType = 'boolean';
VbMDAS_PositionSpeedValid_flg.DocUnits = 'flg';

VfMDAS_PositionQuality_NULL = Simulink.Signal;
VfMDAS_PositionQuality_NULL.RTWInfo.StorageClass = 'ExportedGlobal';
VfMDAS_PositionQuality_NULL.DataType = 'single';
VfMDAS_PositionQuality_NULL.DocUnits = 'NULL';

VeMDAS_PositionDirection_enum = Simulink.Signal;
VeMDAS_PositionDirection_enum.RTWInfo.StorageClass = 'ExportedGlobal';
VeMDAS_PositionDirection_enum.DataType = 'int8';
VeMDAS_PositionDirection_enum.DocUnits = 'enum';

VbMDAS_MrasReady_flg = Simulink.Signal;
VbMDAS_MrasReady_flg.RTWInfo.StorageClass = 'ExportedGlobal';
VbMDAS_MrasReady_flg.DataType = 'boolean';
VbMDAS_MrasReady_flg.DocUnits = 'NULL';

VbMDAS_SmoReady_flg = Simulink.Signal;
VbMDAS_SmoReady_flg.RTWInfo.StorageClass = 'ExportedGlobal';
VbMDAS_SmoReady_flg.DataType = 'boolean';
VbMDAS_SmoReady_flg.DocUnits = 'NULL';

VbMDAS_BemfPllReady_flg = Simulink.Signal;
VbMDAS_BemfPllReady_flg.RTWInfo.StorageClass = 'ExportedGlobal';
VbMDAS_BemfPllReady_flg.DataType = 'boolean';
VbMDAS_BemfPllReady_flg.DocUnits = 'NULL';

VbMDAS_LeoReady_flg = Simulink.Signal;
VbMDAS_LeoReady_flg.RTWInfo.StorageClass = 'ExportedGlobal';
VbMDAS_LeoReady_flg.DataType = 'boolean';
VbMDAS_LeoReady_flg.DocUnits = 'NULL';

VfMDAS_HandoverBlend_NULL = Simulink.Signal;
VfMDAS_HandoverBlend_NULL.RTWInfo.StorageClass = 'ExportedGlobal';
VfMDAS_HandoverBlend_NULL.DataType = 'single';
VfMDAS_HandoverBlend_NULL.DocUnits = 'NULL';

VfMDAS_HandoverElecAngleDelta_rad = Simulink.Signal;
VfMDAS_HandoverElecAngleDelta_rad.RTWInfo.StorageClass = 'ExportedGlobal';
VfMDAS_HandoverElecAngleDelta_rad.DataType = 'single';
VfMDAS_HandoverElecAngleDelta_rad.DocUnits = 'rad';

clear YMBOX_ControlPeriod_s;
