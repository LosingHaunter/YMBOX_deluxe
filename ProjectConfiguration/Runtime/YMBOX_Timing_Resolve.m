function profile = YMBOX_Timing_Resolve( ...
        controlFrequency_Hz, timingCfg, pwmFrequency_Hz, options)
%YMBOX_TIMING_RESOLVE Resolve exact-divisor runtime timing.
%   PROFILE = YMBOX_TIMING_RESOLVE() returns the released default timing.
%   Every returned period is an integer multiple of BaseTick_s.  Requests
%   that would require a fractional tick are rejected instead of rounded
%   silently.  The current application shell intentionally executes input
%   acquisition and the complete control task synchronously at one rate.

arguments
    controlFrequency_Hz (1,1) double = NaN
    timingCfg (1,1) struct = struct()
    pwmFrequency_Hz (1,1) double = NaN
    options.AllowUnreleasedControlFrequency (1,1) logical = false
end

cfg = mergeKnownFields(YMBOX_Timing_Parameters(), timingCfg);
validatePositive(cfg.BaseTick_s, 'Timing.BaseTick_s');
validatePositive(cfg.MinimumControlFrequency_Hz, 'Timing.MinimumControlFrequency_Hz');
validatePositive(cfg.MaximumControlFrequency_Hz, 'Timing.MaximumControlFrequency_Hz');
validatePositive(cfg.ExactMatchTolerance_ppm, 'Timing.ExactMatchTolerance_ppm');
if cfg.MaximumControlFrequency_Hz < cfg.MinimumControlFrequency_Hz
    error('YMBOX:Timing:InvalidFrequencyRange', 'Maximum control frequency must be >= minimum control frequency.');
end

if isnan(controlFrequency_Hz)
    controlFrequency_Hz = cfg.ControlFrequency_Hz;
end
validatePositive(controlFrequency_Hz, 'requested control frequency');
if ~options.AllowUnreleasedControlFrequency && ...
        (controlFrequency_Hz < cfg.MinimumControlFrequency_Hz || ...
        controlFrequency_Hz > cfg.MaximumControlFrequency_Hz)
    error('YMBOX:Timing:ControlFrequencyOutOfRange', ...
        'Requested control frequency %.12g Hz is outside [%.12g, %.12g] Hz.', ...
        controlFrequency_Hz, cfg.MinimumControlFrequency_Hz, ...
        cfg.MaximumControlFrequency_Hz);
end

if isfinite(cfg.InputTaskFrequencyOverride_Hz)
    inputFrequency_Hz = cfg.InputTaskFrequencyOverride_Hz;
else
    inputFrequency_Hz = controlFrequency_Hz;
end
if isnan(pwmFrequency_Hz)
    pwmFrequency_Hz = controlFrequency_Hz;
end

control = resolveRate(controlFrequency_Hz, cfg, 'control');
input = resolveRate(inputFrequency_Hz, cfg, 'input');
validatePositive(pwmFrequency_Hz, 'requested PWM frequency');
pwmPeriod_s = 1/pwmFrequency_Hz;
pwmIdealTicks = pwmPeriod_s/cfg.BaseTick_s;
pwmNearestTicks = round(pwmIdealTicks);
if pwmNearestTicks < 1 || pwmNearestTicks > double(intmax('uint32'))
    error('YMBOX:Timing:PwmTickCountOutOfRange', ...
        'PWM period requires %.12g base ticks, outside uint32 range.', ...
        pwmIdealTicks);
end
pwmNearestFrequency_Hz = 1/(pwmNearestTicks*cfg.BaseTick_s);
pwmTickError_ppm = 1e6*abs( ...
    pwmNearestFrequency_Hz-pwmFrequency_Hz)/pwmFrequency_Hz;

if input.Ticks ~= control.Ticks
    error('YMBOX:Timing:AsynchronousInputTaskNotReleased', ...
        ['The current YMBOX shell requires input acquisition and control ' ...
        'to use the same period.']);
end

pwmPerControl = pwmFrequency_Hz/control.ActualFrequency_Hz;
pwmPerControlRounded = round(pwmPerControl);
ratioError_ppm = 1e6*abs(pwmPerControl-pwmPerControlRounded) / ...
    max(abs(pwmPerControl), eps);
if pwmPerControlRounded < 1 || ...
        ratioError_ppm > cfg.ExactMatchTolerance_ppm
    error('YMBOX:Timing:NonIntegerPwmControlRatio', ...
        ['PWM frequency must be an integer multiple of the control ' ...
        'frequency; requested ratio is %.12g.'], pwmPerControl);
end

profile.BaseTick_s = cfg.BaseTick_s;
profile.MinimumControlFrequency_Hz = cfg.MinimumControlFrequency_Hz;
profile.MaximumControlFrequency_Hz = cfg.MaximumControlFrequency_Hz;
profile.ExactMatchTolerance_ppm = cfg.ExactMatchTolerance_ppm;
profile.ControlFrequencyRequested_Hz = control.RequestedFrequency_Hz;
profile.ControlFrequency_Hz = control.ActualFrequency_Hz;
profile.ControlPeriod_s = control.Period_s;
profile.ControlTicks = control.Ticks;
profile.ControlFrequencyError_ppm = control.Error_ppm;
profile.InputFrequencyRequested_Hz = input.RequestedFrequency_Hz;
profile.InputFrequency_Hz = input.ActualFrequency_Hz;
profile.InputPeriod_s = input.Period_s;
profile.InputTicks = input.Ticks;
profile.InputFrequencyError_ppm = input.Error_ppm;
profile.PwmFrequencyRequested_Hz = pwmFrequency_Hz;
profile.PwmFrequency_Hz = pwmFrequency_Hz;
profile.PwmPeriod_s = pwmPeriod_s;
profile.PwmIdealBaseTicks = pwmIdealTicks;
profile.PwmNearestBaseTicks = uint32(pwmNearestTicks);
profile.PwmExactlyRepresentable = ...
    pwmTickError_ppm <= cfg.ExactMatchTolerance_ppm;
profile.PwmNearestFrequency_Hz = pwmNearestFrequency_Hz;
profile.PwmNearestFrequencyError_ppm = pwmTickError_ppm;
profile.PwmCyclesPerControl = uint32(pwmPerControlRounded);
profile.ControlDivider = uint32(1);
profile.InputDivider = uint32(1);
end

function rate = resolveRate(requestedFrequency_Hz, cfg, label)
validatePositive(requestedFrequency_Hz, ...
    sprintf('requested %s frequency', label));
idealTicks = 1/(requestedFrequency_Hz*cfg.BaseTick_s);
ticks = round(idealTicks);
if ticks < 1 || ticks > double(intmax('uint32'))
    error('YMBOX:Timing:TickCountOutOfRange', ...
        '%s period requires %.12g base ticks, outside uint32 range.', ...
        label, idealTicks);
end
period_s = ticks*cfg.BaseTick_s;
actualFrequency_Hz = 1/period_s;
error_ppm = 1e6*abs(actualFrequency_Hz-requestedFrequency_Hz) / ...
    requestedFrequency_Hz;
if error_ppm > cfg.ExactMatchTolerance_ppm
    error('YMBOX:Timing:FrequencyNotExactlyDivisible', ...
        ['Requested %s frequency %.12g Hz is not exactly representable ' ...
        'by the %.12g s base tick. Nearest supported value is %.12g Hz.'], ...
        label, requestedFrequency_Hz, cfg.BaseTick_s, actualFrequency_Hz);
end
rate.RequestedFrequency_Hz = requestedFrequency_Hz;
rate.ActualFrequency_Hz = actualFrequency_Hz;
rate.Period_s = period_s;
rate.Ticks = uint32(ticks);
rate.Error_ppm = error_ppm;
end

function output = mergeKnownFields(output, override)
fields = fieldnames(override);
for idx = 1:numel(fields)
    name = fields{idx};
    if ~isfield(output, name)
        error('YMBOX:Timing:UnknownSetting', ...
            'Unknown timing setting: %s.', name);
    end
    output.(name) = override.(name);
end
end

function validatePositive(value, name)
if ~(isscalar(value) && isfinite(value) && value > 0)
    error('YMBOX:Timing:InvalidParameter', '%s must be positive.', name);
end
end
