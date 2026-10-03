%***********************************************************************
%
% Initialize runtime constants and compile-time product variants.
%
%**********************************************************************/
disp('Loading VCU global constants.........')

%-----------------------------
% General global constants
%-----------------------------

TRUE = 1;
FALSE = 0;

%-----------------------------
% Model execution period
%-----------------------------

% Default standalone/shared-core context. Top models override these in
% their InitFcn. One invocation always executes one complete input/control
% task; YMBOX_Timing_Resolve owns all frequency-to-period conversion.
if ~exist('Cf_CONTROL_TASK_TIME_S','var')
    YMBOX_DefaultTimingProfile = YMBOX_Timing_Resolve();
    Cf_CONTROL_TASK_TIME_S = YMBOX_DefaultTimingProfile.ControlPeriod_s;
    Cf_INPUT_TASK_TIME_S = YMBOX_DefaultTimingProfile.InputPeriod_s;
    Cf_PWM_TIME_S = YMBOX_DefaultTimingProfile.PwmPeriod_s;
    clear YMBOX_DefaultTimingProfile;
end
if ~exist('Cf_TICK_TIME_S','var')
    Cf_TICK_TIME_S = Cf_CONTROL_TASK_TIME_S;
end
if ~exist('Cf_INPUT_TASK_TIME_S','var')
    Cf_INPUT_TASK_TIME_S = Cf_CONTROL_TASK_TIME_S;
end
if ~exist('Cf_PWM_TIME_S','var')
    Cf_PWM_TIME_S = Cf_CONTROL_TASK_TIME_S;
end
%-----------------------------
% Observer architecture configuration
%-----------------------------

% Canonical mode-number contract:
%   request interface 0..10, implemented public modes 0..6,
%   reserved public values 7..10, internal commands 16..31.
% C = compile-time constant, e = enumerated integer, MDSM = owner.
YMBOX_DriveMode = YMBOX_DriveModeDefinitions();
CeMDSM_DrvModeOff_enum = YMBOX_DriveMode.GateOff;
CeMDSM_DrvModeVoltAB_enum = YMBOX_DriveMode.VoltageAlphaBetaOpenLoop;
CeMDSM_DrvModeVoltDQ_enum = YMBOX_DriveMode.VoltageDqOpenLoop;
CeMDSM_DrvModeCurrDQ_enum = YMBOX_DriveMode.CurrentDqOpenLoop;
CeMDSM_DrvModeSpdSens_enum = YMBOX_DriveMode.SensoredSpeedLoop;
CeMDSM_DrvModeTrq_enum = YMBOX_DriveMode.TorqueControl;
CeMDSM_DrvModeSpdSlsReq_enum = YMBOX_DriveMode.SensorlessSpeedRequest;
CeMDSM_DrvModeReqMax_enum = YMBOX_DriveMode.PublicMaximum;
CeMDSM_DrvModeIfStart_enum = YMBOX_DriveMode.IfStartupInternal;
CeMDSM_DrvModeSpdSmo_enum = YMBOX_DriveMode.SmoClosedLoopInternal;
CeMDSM_DrvModeIntMax_enum = YMBOX_DriveMode.InternalMaximum;

% Product compile-time observer selection. Build Variant numbering is
% intentionally independent from runtime work-mode numbering:
%    0 = sensored-only build (public modes 1 through 5)
%    1 = SMO sensorless build (public request 6, internal 16 -> 17)
if ~exist('KuMDAS_ObserverBuildVariant','var')
    KuMDAS_ObserverBuildVariant = Simulink.Parameter;
    KuMDAS_ObserverBuildVariant.Value = uint8(1);
    KuMDAS_ObserverBuildVariant.DataType = 'uint8';
    KuMDAS_ObserverBuildVariant.CoderInfo.StorageClass = 'Auto';
    KuMDAS_ObserverBuildVariant.Description = ...
        'Product observer build Variant: 0=sensored-only, 1=SMO sensorless';
end

% MotorCurrentReferenceGenerator compile-time selection.  The unified
% drive profile overwrites this default in MDTM_Model_Library.
if ~exist('KuMDTM_MotorCurrentReferenceVariant','var')
    KuMDTM_MotorCurrentReferenceVariant = Simulink.Parameter;
    KuMDTM_MotorCurrentReferenceVariant.Value = uint8(0);
    KuMDTM_MotorCurrentReferenceVariant.DataType = 'uint8';
    KuMDTM_MotorCurrentReferenceVariant.CoderInfo.StorageClass = 'Auto';
    KuMDTM_MotorCurrentReferenceVariant.Description = ...
        'MotorCurrentReferenceGenerator Variant: 0=SPMSM, 1=IPMSM MTPA';
end

clear YMBOX_DriveMode;

disp('Done.')
