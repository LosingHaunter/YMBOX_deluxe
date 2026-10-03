function rtwTargetInfo(registry)
%RTWTARGETINFO Register the YMBOX single-precision math code replacement.
registry.registerTargetInfo(@registerMath);
end

function entry = registerMath
entry = RTW.TflRegistry;
entry.Name = 'YMBOX single math';
entry.TableList = {'YMBOX_MathCodeReplacement.m'};
entry.TargetHWDeviceType = {'*'};
entry.Description = ['Shared sqrt/hypot services and inline, guarded ' ...
    'TMU division selected by the target build.'];
end
