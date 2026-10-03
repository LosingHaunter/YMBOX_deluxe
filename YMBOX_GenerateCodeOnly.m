function report = YMBOX_GenerateCodeOnly(document, options)
%YMBOX_GENERATECODEONLY Generate controller code without running simulation.
%   REPORT = YMBOX_GENERATECODEONLY(DOCUMENT) validates an already
%   recalculated, complete YMBOX calculator document and generates code
%   from YMBOX_Deluxe_code. The UI service requires evidence binding the
%   current engine recalculation to that document. Advanced MATLAB callers
%   are responsible for supplying an equivalently refreshed document;
%   finite automatic values cannot be identified as stale by this function.
%   The simulation shell is neither loaded nor executed. This dedicated
%   entry point may accept an exact base-tick control frequency outside the
%   released UI frequency range; all other timing and drive validations
%   remain active.

arguments
    document
    options.OutputRoot (1,1) string = ""
    options.ReportFile (1,1) string = ""
    options.AllowUnreleasedControlFrequency (1,1) logical = true
end

assert(batchStartupOptionUsed(), ...
    'YMBOX:GenerateCode:FreshBatchRequired', ...
    ['Direct code generation must run in a new MATLAB -batch process. ' ...
    'Interactive sessions can contain model and workspace state that ' ...
    'must not influence generated code.']);

modelRoot = fileparts(mfilename('fullpath'));
codeModel = 'YMBOX_Deluxe_code';
coreModel = 'YMBOX_Control_Core';
simulationModel = 'YMBOX_Deluxe_sim';
hardwareDeviceType = 'Texas Instruments->C2000';
assert(isfile(fullfile(modelRoot, [codeModel '.slx'])) && ...
    isfile(fullfile(modelRoot, [coreModel '.slx'])), ...
    'YMBOX:GenerateCode:MissingModel', ...
    'The code-generation and shared-core models must be present in %s.', ...
    modelRoot);
assert(~any(cellfun(@bdIsLoaded, ...
    {codeModel, coreModel, simulationModel})), ...
    'YMBOX:GenerateCode:FreshBatchModelsRequired', ...
    ['The direct-codegen batch must start with no YMBOX models loaded. ' ...
    'The simulation shell is never loaded or run.']);
baseVariables = evalin('base', 'who');
assert(isempty(baseVariables), ...
    'YMBOX:GenerateCode:FreshBatchWorkspaceRequired', ...
    ['The fresh -batch base workspace must be empty. Pass a JSON path ' ...
    'literal instead of preparing configuration variables in base.']);

state = captureState({codeModel, coreModel});
restore = onCleanup(@() restoreState(state, simulationModel));
cd(modelRoot);
evalin('base', sprintf('run(''%s'');', ...
    strrep(fullfile(modelRoot, 'YMBOX_Deluxe_init.m'), '''', '''''')));

configurationFile = '';
if ischar(document) || isstring(document)
    configurationFile = canonical(document);
    document = YMBOX_Configuration_ReadFile(configurationFile);
end
[configuration, ~] = YMBOX_Configuration_Decode(document, ...
    AllowUnreleasedControlFrequency= ...
    options.AllowUnreleasedControlFrequency);
if isfield(document, 'drive')
    buildDocument = document;
    buildDocument.drive = configuration;
else
    buildDocument = struct( ...
        'schemaVersion', 1, ...
        'kind', 'YMBOXConfiguration', ...
        'drive', configuration);
end

outputRoot = resolveOutputRoot(modelRoot, options.OutputRoot);
codeGenFolder = fullfile(outputRoot, 'codegen');
cacheFolder = fullfile(outputRoot, 'cache');
if ~isfolder(codeGenFolder), mkdir(codeGenFolder); end
if ~isfolder(cacheFolder), mkdir(cacheFolder); end
if strlength(options.ReportFile) == 0
    reportFile = fullfile(outputRoot, ...
        'YMBOX_CodeGenerationReport.json');
else
    reportFile = canonical(options.ReportFile);
end
assert(isWithin(reportFile, outputRoot), ...
    'YMBOX:GenerateCode:ReportOutsideOutput', ...
    'The code-generation report must stay inside OutputRoot.');

Simulink.fileGenControl('set', ...
    'CodeGenFolder', codeGenFolder, ...
    'CacheFolder', cacheFolder, 'createDir', true);
assignin('base', 'YMBOX_Configuration_UserConfig', buildDocument);
assignin('base', ...
    'YMBOX_DirectCodegen_AllowUnreleasedControlFrequency', ...
    options.AllowUnreleasedControlFrequency);
sl_refresh_customizations;

for model = {codeModel, coreModel}
    if ~bdIsLoaded(model{1})
        load_system(fullfile(modelRoot, [model{1} '.slx']));
    end
    assert(strcmpi(canonical(get_param(model{1}, 'FileName')), ...
        canonical(fullfile(modelRoot, [model{1} '.slx']))), ...
        'YMBOX:GenerateCode:WrongModel', ...
        'A different copy of %s is loaded.', model{1});
    set_param(model{1}, ...
        'ProdHWDeviceType', hardwareDeviceType, ...
        'TargetHWDeviceType', hardwareDeviceType, ...
        'GenCodeOnly', 'on');
end
set_param(codeModel, ...
    'FixedStep', sprintf('%.17g', ...
    1/double(configuration.Timing.ControlFrequency_Hz)));

slbuild(codeModel, 'GenerateCodeOnly', true);
assert(~bdIsLoaded(simulationModel), ...
    'YMBOX:GenerateCode:SimulationModelUnexpectedlyLoaded', ...
    '%s was unexpectedly loaded during direct code generation.', ...
    simulationModel);
context = evalin('base', 'YMBOX_Initialization_Context');
assert(context.IsComplete && strcmp(context.ModelRole, 'code'), ...
    'YMBOX:GenerateCode:IncompleteInitialization', ...
    'The generated code did not use a complete code-model context.');
assert(isequaln(context.RequestedConfig, configuration), ...
    'YMBOX:GenerateCode:ConfigurationMismatch', ...
    'The generated parameters do not match the selected configuration.');
assert(context.AllowUnreleasedControlFrequency == ...
    options.AllowUnreleasedControlFrequency, ...
    'YMBOX:GenerateCode:OptionMismatch', ...
    'The code model did not receive the direct-codegen timing option.');

buildInfo = RTW.getBuildDir(codeModel);
requestedFrequency_Hz = ...
    double(configuration.Timing.ControlFrequency_Hz);
report.Passed = true;
report.CodeBuildPassed = true;
report.MatlabStarted = true;
report.SimulationRun = false;
report.SimulationModelLoaded = false;
report.FreshBatchProcess = true;
report.AllowUnreleasedControlFrequency = ...
    options.AllowUnreleasedControlFrequency;
report.UsedReleasedFrequencyRange = ...
    requestedFrequency_Hz >= ...
    double(configuration.Timing.MinimumControlFrequency_Hz) && ...
    requestedFrequency_Hz <= ...
    double(configuration.Timing.MaximumControlFrequency_Hz);
report.ProfileName = char(configuration.Meta.ProfileName);
report.ControlFrequencyRequested_Hz = requestedFrequency_Hz;
report.ControlFrequency_Hz = context.Timing.ControlFrequency_Hz;
report.ControlPeriod_s = context.Timing.ControlPeriod_s;
report.PwmFrequency_Hz = context.Timing.PwmFrequency_Hz;
report.Model = codeModel;
report.ReferencedModel = coreModel;
report.HardwareDeviceType = hardwareDeviceType;
report.OutputRoot = outputRoot;
report.CodeGenFolder = codeGenFolder;
report.CacheFolder = cacheFolder;
report.BuildDirectory = buildInfo.BuildDirectory;
report.ConfigurationFile = configurationFile;
report.ReportFile = reportFile;
report.GeneratedAtUtc = char(datetime('now', ...
    'TimeZone', 'UTC', 'Format', 'yyyy-MM-dd''T''HH:mm:ss.SSSXXX'));
writeJson(reportFile, report);
fprintf(['YMBOX_CODEGEN_ONLY_OK: %s, %.12g Hz, output %s. ' ...
    'Simulation was not loaded or run.\n'], ...
    report.ProfileName, report.ControlFrequency_Hz, outputRoot);
clear restore;
end

function outputRoot = resolveOutputRoot(modelRoot, requestedRoot)
if strlength(requestedRoot) == 0
    [parent, modelFolder] = fileparts(modelRoot);
    baseRoot = fullfile(parent, [modelFolder '_outputs'], ...
        'direct-codegen');
    if ~isfolder(baseRoot), mkdir(baseRoot); end
    outputRoot = tempname(baseRoot);
else
    outputRoot = canonical(requestedRoot);
end
sourceRoot = canonical(modelRoot);
assert(~strcmpi(outputRoot, sourceRoot) && ...
    ~startsWith(outputRoot, [sourceRoot filesep], ...
    'IgnoreCase', true), ...
    'YMBOX:GenerateCode:OutputInsideSource', ...
    'OutputRoot must be outside the YMBOX source-model folder.');
if ~isfolder(outputRoot), mkdir(outputRoot); end
outputRoot = canonical(outputRoot);
end

function state = captureState(models)
state.folder = pwd;
state.searchPath = path;
state.fileGen = Simulink.fileGenControl('getConfig');
state.models = models;
state.loaded = cellfun(@bdIsLoaded, models);
state.settings = cell(1, numel(models));
state.dirty = cell(1, numel(models));
state.coreVariant = [];
for index = find(state.loaded)
    model = models{index};
    assert(strcmp(get_param(model, 'Dirty'), 'off'), ...
        'YMBOX:GenerateCode:UnsavedModel', ...
        'Save or close %s before direct code generation.', model);
    assert(strcmp(get_param(model, 'SimulationStatus'), 'stopped'), ...
        'YMBOX:GenerateCode:ModelRunning', ...
        'Stop %s before direct code generation.', model);
    state.settings{index} = modelSettings(model);
    state.dirty{index} = get_param(model, 'Dirty');
end
coreIndex = find(strcmp(models, 'YMBOX_Control_Core'), 1);
if ~isempty(coreIndex) && state.loaded(coreIndex)
    workspace = get_param('YMBOX_Control_Core', 'ModelWorkspace');
    variant = workspace.getVariable('KuMDAS_ObserverBuildVariant');
    state.coreVariant = variant.Value;
end
state.baseVariables = evalin('base', 'who');
state.hadDocument = evalin('base', ...
    'exist(''YMBOX_Configuration_UserConfig'',''var'') ~= 0');
state.document = [];
if state.hadDocument
    state.document = evalin('base', ...
        'YMBOX_Configuration_UserConfig');
end
state.hadDirectOption = evalin('base', ...
    ['exist(''YMBOX_DirectCodegen_AllowUnreleasedControlFrequency'',' ...
    '''var'') ~= 0']);
state.directOption = [];
if state.hadDirectOption
    state.directOption = evalin('base', ...
        'YMBOX_DirectCodegen_AllowUnreleasedControlFrequency');
end
end

function settings = modelSettings(model)
names = {'FixedStep', 'ProdHWDeviceType', ...
    'TargetHWDeviceType', 'GenCodeOnly'};
settings = cell(1, 2*numel(names));
for index = 1:numel(names)
    settings{2*index-1} = names{index};
    settings{2*index} = get_param(model, names{index});
end
end

function restoreState(state, simulationModel)
if bdIsLoaded(simulationModel)
    set_param(simulationModel, 'CloseFcn', '');
    close_system(simulationModel, 0);
end
for index = 1:numel(state.models)
    model = state.models{index};
    if ~bdIsLoaded(model), continue; end
    if state.loaded(index)
        set_param(model, state.settings{index}{:});
        if strcmp(model, 'YMBOX_Control_Core') && ...
                ~isempty(state.coreVariant)
            workspace = get_param(model, 'ModelWorkspace');
            variant = workspace.getVariable( ...
                'KuMDAS_ObserverBuildVariant');
            variant.Value = state.coreVariant;
        end
        set_param(model, 'Dirty', state.dirty{index});
    else
        set_param(model, 'CloseFcn', '');
        close_system(model, 0);
    end
end
if state.hadDocument
    assignin('base', 'YMBOX_Configuration_UserConfig', ...
        state.document);
else
    evalin('base', 'clear YMBOX_Configuration_UserConfig');
end
if state.hadDirectOption
    assignin('base', ...
        'YMBOX_DirectCodegen_AllowUnreleasedControlFrequency', ...
        state.directOption);
else
    evalin('base', ...
        ['clear ' ...
        'YMBOX_DirectCodegen_AllowUnreleasedControlFrequency']);
end
clearNewBaseVariables(state.baseVariables);
Simulink.fileGenControl('setConfig', 'config', state.fileGen);
cd(state.folder);
path(state.searchPath);
end

function clearNewBaseVariables(originalNames)
currentNames = evalin('base', 'who');
newNames = setdiff(currentNames, originalNames);
for index = 1:numel(newNames)
    evalin('base', ['clear ' newNames{index}]);
end
end

function writeJson(file, value)
folder = fileparts(file);
if ~isfolder(folder), mkdir(folder); end
temporary = tempname(folder);
cleanup = onCleanup(@() deleteIfPresent(temporary));
stream = fopen(temporary, 'w', 'n', 'UTF-8');
assert(stream >= 0, 'YMBOX:GenerateCode:ReportWriteFailed', ...
    'Cannot create code-generation report %s.', file);
closeStream = onCleanup(@() fclose(stream));
text = [jsonencode(value, 'PrettyPrint', true) newline];
assert(fprintf(stream, '%s', text) >= 0, ...
    'YMBOX:GenerateCode:ReportWriteFailed', ...
    'Cannot write code-generation report %s.', file);
clear closeStream;
[moved, message] = movefile(temporary, file, 'f');
assert(moved, 'YMBOX:GenerateCode:ReportWriteFailed', ...
    'Cannot publish code-generation report %s: %s', file, message);
clear cleanup;
end

function deleteIfPresent(file)
if isfile(file), delete(file); end
end

function inside = isWithin(file, folder)
file = canonical(file);
folder = canonical(folder);
inside = startsWith(file, [folder filesep], 'IgnoreCase', true);
end

function value = canonical(value)
value = char(java.io.File(char(value)).getCanonicalPath());
end
