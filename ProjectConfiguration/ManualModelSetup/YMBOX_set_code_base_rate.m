function profile = YMBOX_set_code_base_rate(baseRate_Hz)
%YMBOX_SET_CODE_BASE_RATE Set the complete hardware control rate in one call.
%   The requested rate must map to an integer number of configured base
%   ticks and stay inside the released range.  No secondary hardware
%   divider is used: one ymbox_deluxe_step call is one complete control task.

arguments
    baseRate_Hz (1,1) double = NaN
end
rootDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldDir = pwd;
cleanupDir = onCleanup(@() cd(oldDir));
cd(rootDir);
model = 'YMBOX_Deluxe_code';
document = struct();
if evalin('base', 'exist(''YMBOX_Configuration_UserConfig'',''var'')')
    candidate = evalin('base', 'YMBOX_Configuration_UserConfig');
    if isstruct(candidate) && ~isempty(fieldnames(candidate))
        document = candidate;
    end
end
if isempty(fieldnames(document)), document = YMBOX_Configuration_ReadActive(); end
cfg = YMBOX_Configuration_Decode(document);
if isnan(baseRate_Hz), baseRate_Hz = cfg.Timing.ControlFrequency_Hz; end
assert(abs(baseRate_Hz-cfg.Timing.ControlFrequency_Hz) <= ...
    baseRate_Hz*cfg.Timing.ExactMatchTolerance_ppm*1e-6, ...
    'YMBOX:Configuration:CodeRateMismatch', ...
    'Set the control frequency in the calculator before changing the code rate.');
[~, derived] = YMBOX_Drive_ResolveProfile(1/baseRate_Hz, cfg);
requestedProfile = derived.Timing;
basePeriod_s = requestedProfile.ControlPeriod_s;
load_system(fullfile(rootDir, [model '.slx']));
set_param(model,'SolverType','Fixed-step','Solver','FixedStepDiscrete', ...
    'FixedStep',num2str(basePeriod_s,17));

rt = sfroot;
charts = rt.find('-isa','Stateflow.Chart');
chart = Stateflow.Chart.empty;
prefix = [model '/EV_MCU_Application/'];
for k = 1:numel(charts)
    if strncmp(charts(k).Path,prefix,length(prefix)) && ...
            contains(charts(k).Path,'Scheduler')
        chart = charts(k);
        break
    end
end
assert(~isempty(chart),'Unable to find the code-shell hardware scheduler.');
chart.ChartUpdate = 'DISCRETE';
chart.SampleTime = num2str(basePeriod_s,17);

modelBlock = [model '/EV_MCU_Application/MCU_Application_Strategy/App_Strategy'];
set_param(modelBlock,'AttributesFormatString', ...
    'one ymbox_deluxe_step = one complete control task', ...
    'Selected','off','ContentPreviewEnabled','off', ...
    'ForegroundColor','black','BackgroundColor','lightBlue');

codeMap = coder.mapping.api.get(model);
setFunction(codeMap,'Periodic','FunctionName','ymbox_deluxe_step');
setFunction(codeMap,'Initialize','FunctionName','ymbox_deluxe_initialize');
try
    setFunction(codeMap,'Terminate','FunctionName','ymbox_deluxe_terminate');
catch
end

set_param(model, 'InitFcn', ...
    'YMBOX_InitializeModel(''code'',bdroot);');

% Model update invokes the single initialization entry point, which resolves
% and publishes every rate-dependent calibration once.
set_param(model,'SimulationCommand','update');
save_system(model);
profile = evalin('base', 'YMBOX_Timing_Profile');
assert(profile.ControlDivider==1 && ...
    abs(profile.ControlPeriod_s-basePeriod_s)<1e-15);
end
