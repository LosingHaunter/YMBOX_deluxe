function cfg = YMBOX_Timing_Parameters()
%YMBOX_TIMING_PARAMETERS Define the released application timing parameters.
%   The application control period must be an integer multiple of BaseTick_s.
%   Hardware projects may override BaseTick_s with the timer resolution that
%   they actually realize, then pass the realized frequency back to YMBOX.

cfg.BaseTick_s = 1.0e-6;
cfg.ControlFrequency_Hz = 4000;
cfg.MinimumControlFrequency_Hz = 4000;
cfg.MaximumControlFrequency_Hz = 20000;
% Nominal MDTM divider relative to the control task. Critical startup,
% handover, and reset samples bypass this divider in the scheduler.
cfg.MDTMTaskDivider_NULL = uint16(10);
cfg.InputTaskFrequencyOverride_Hz = NaN;
cfg.ExactMatchTolerance_ppm = 0.10;
end
