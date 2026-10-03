function profile = YMBOX_Drive_MigrateProfile(profile)
%YMBOX_DRIVE_MIGRATEPROFILE Remove retired leaves from an older drive profile.
%   The current PLL bandwidth takes precedence when both names exist.
%   An older profile containing only the alias retains its bandwidth.

if ~isfield(profile, 'PlatformMath')
    defaults = YMBOX_Drive_Parameters();
    profile.PlatformMath = defaults.PlatformMath;
end
if isfield(profile, 'Feedforward') && isstruct(profile.Feedforward)
    % Preserve the actual behavior of profiles saved before explicit switches.
    if ~isfield(profile.Feedforward, 'VoltageMode_enum')
        profile.Feedforward.VoltageMode_enum = uint8(0);
    end
    if ~isfield(profile.Feedforward, 'ElectricalAngleCompEnable')
        profile.Feedforward.ElectricalAngleCompEnable = true;
    end
end
if isfield(profile, 'PositionSensor') && isstruct(profile.PositionSensor)
    position = profile.PositionSensor;
    if ~isfield(position, 'PllBandwidth_rads') && ...
            isfield(position, 'ResolverPllBandwidth_rads')
        profile.PositionSensor.PllBandwidth_rads = ...
            position.ResolverPllBandwidth_rads;
    end
end
for path = YMBOX_Drive_RetiredFields()
    parts = strsplit(path{1}, '.');
    group = parts{1};
    leaf = parts{2};
    if isfield(profile, group) && isstruct(profile.(group)) && ...
            isfield(profile.(group), leaf)
        profile.(group) = rmfield(profile.(group), leaf);
    end
end
end
