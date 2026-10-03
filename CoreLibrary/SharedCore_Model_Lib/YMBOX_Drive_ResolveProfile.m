function [cfg, prm] = YMBOX_Drive_ResolveProfile( ...
        sampleTime_s, userProfile, options)
%YMBOX_DRIVE_RESOLVEPROFILE Merge optional leaves and derive calibrations.

arguments
    sampleTime_s (1,1) double {mustBeFinite, mustBePositive}
    userProfile struct = struct()
    options.AllowUnreleasedControlFrequency (1,1) logical = false
end

cfg = YMBOX_Drive_Parameters();
cfg = mergeStruct(cfg, YMBOX_Drive_MigrateProfile(userProfile));
% Normalize user overrides at the configuration boundary. This prevents
% ordinary MATLAB numeric literals in a user profile from reintroducing a
% double-valued MDSP calibration chain.
cfg.DcBusMeasurement.VoltageControlFilterAlpha_NULL = single( ...
    cfg.DcBusMeasurement.VoltageControlFilterAlpha_NULL);
cfg.DcBusMeasurement.VoltageReportFilterAlpha_NULL = single( ...
    cfg.DcBusMeasurement.VoltageReportFilterAlpha_NULL);
cfg.DcBusMeasurement.VoltagePlausibleMin_V = single( ...
    cfg.DcBusMeasurement.VoltagePlausibleMin_V);
cfg.DcBusMeasurement.VoltagePlausibleMaxFactor_NULL = single( ...
    cfg.DcBusMeasurement.VoltagePlausibleMaxFactor_NULL);
cfg.DcBusMeasurement.CurrentInputMovingAverageWindowSamples = single( ...
    cfg.DcBusMeasurement.CurrentInputMovingAverageWindowSamples);
prm = YMBOX_Drive_CalculateParams(cfg, sampleTime_s, ...
    AllowUnreleasedControlFrequency= ...
    options.AllowUnreleasedControlFrequency);
end

function output = mergeStruct(output, userValues)
fields = fieldnames(userValues);
for idx = 1:numel(fields)
    name = fields{idx};
    if ~isfield(output, name)
        error('YMBOX:Drive:UnknownProfileField', ...
            'Unknown YMBOX drive-profile field: %s.', name);
    end
    if isfield(output, name) && isstruct(output.(name)) && ...
            isstruct(userValues.(name))
        output.(name) = mergeStruct(output.(name), userValues.(name));
    else
        output.(name) = userValues.(name);
    end
end
end
