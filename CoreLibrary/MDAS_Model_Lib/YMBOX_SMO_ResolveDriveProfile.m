function [cfg, prm] = YMBOX_SMO_ResolveDriveProfile(sampleTime_s, driveConfig)
%YMBOX_SMO_RESOLVEDRIVEPROFILE Resolve eSMO from the calculator configuration.
%   The complete drive configuration supplies all motor, inverter, observer,
%   and startup settings. The observer representation is an internal mapping.

arguments
    sampleTime_s (1,1) double {mustBeFinite, mustBePositive}
    driveConfig (1,1) struct
end

cfg = YMBOX_Drive_ToLegacySmoConfig(driveConfig);
prm = YMBOX_SMO_CalculateParams(cfg, sampleTime_s);
end
