function report = YMBOX_ImportConfiguration(document, options)
%YMBOX_ImportConfiguration - Validate and import a complete tool configuration
%   REPORT = YMBOX_ImportConfiguration(DOCUMENT) validates a configuration
%   struct or JSON file, updates model entry points, and saves it as JSON.
%
%   REPORT = YMBOX_ImportConfiguration(...,Activate=false) validates without
%   replacing the active configuration. The previous workspace is restored.
%
%   REPORT = YMBOX_ImportConfiguration(...,BuildCode=true) also builds the
%   generated-code model before activation.
%
%   See Also YMBOX_Configuration_Decode, YMBOX_InitializeModel

arguments
    document
    options.Activate (1,1) logical = true
    options.BuildCode (1,1) logical = false
    options.UpdateModels (1,1) logical = true
end
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
if ischar(document) || isstring(document)
    document = YMBOX_Configuration_ReadFile(document);
end
[cfg, resolvedPaths] = YMBOX_Configuration_Decode(document);
envelope = struct('schemaVersion', 1, 'kind', 'YMBOXConfiguration', 'drive', cfg);
metadataNames = {'parameterSources', 'parameterOrigins', 'recommendationTargets'};
for metadataIndex = 1:numel(metadataNames)
    metadataName = metadataNames{metadataIndex};
    if isfield(document, metadataName) && isstruct(document.(metadataName)) && ...
            isscalar(document.(metadataName))
        envelope.(metadataName) = document.(metadataName);
        retiredPaths = YMBOX_Drive_RetiredFields();
        obsolete = intersect(fieldnames(envelope.(metadataName)), ...
            [retiredPaths strrep(retiredPaths, '.', '_')]);
        if ~isempty(obsolete)
            envelope.(metadataName) = rmfield(envelope.(metadataName), obsolete);
        end
    end
end
for resolvedIndex = 1:numel(resolvedPaths)
    path = resolvedPaths{resolvedIndex};
    key = strrep(path, '.', '_');
    % Preserve model-calculated provenance after saving explicit numbers.
    for metadataName = {'parameterSources', 'parameterOrigins'}
        name = metadataName{1};
        if ~isfield(envelope, name), envelope.(name) = struct(); end
        if isfield(envelope.(name), path)
            envelope.(name) = rmfield(envelope.(name), path);
        end
    end
    envelope.parameterSources.(key) = '模型自动计算';
    envelope.parameterOrigins.(key) = 'automatic';
end
if ~bdIsLoaded('YMBOX_Control_Core')
    load_system(fullfile(root, 'YMBOX_Control_Core.slx'));
end
previous = captureState();
cleanup = onCleanup(@() restoreState(previous));
assignin('base', 'YMBOX_Configuration_UserConfig', envelope);
context = YMBOX_InitializeModel('simulation', 'YMBOX_Deluxe_sim');
report = struct('Passed', false, 'ProfileName', cfg.Meta.ProfileName, ...
    'ParameterValidationPassed', context.DriveValidation.Passed, ...
    'ModelUpdatesPassed', false, 'CodeBuildPassed', false, ...
    'Activated', false, 'ControlFrequency_Hz', context.Timing.ControlFrequency_Hz, ...
    'ObserverBuildVariant', cfg.Execution.ObserverBuildVariant, ...
    'Warnings', {cellstr(context.DriveValidation.Warnings)});
report.PlatformMath = cfg.PlatformMath;
report.PlatformMathAppliesTo = 'BOARD_BUILD';
report.SimulationMathBackend = 'GENERIC';
if options.UpdateModels || options.BuildCode
    models = {'YMBOX_Control_Core', 'YMBOX_Deluxe_sim', ...
        'YMBOX_Deluxe_code'};
    for index = 1:numel(models)
        if ~bdIsLoaded(models{index}), load_system(fullfile(root, [models{index} '.slx'])); end
        set_param(models{index}, 'SimulationCommand', 'update');
    end
    report.ModelUpdatesPassed = true;
    workspace = get_param('YMBOX_Control_Core', 'ModelWorkspace');
    actualVariant = workspace.getVariable('KuMDAS_ObserverBuildVariant');
    assert(isequal(actualVariant.Value, cfg.Execution.ObserverBuildVariant), ...
        'YMBOX:Configuration:VariantReadback', 'Core build selection did not match the imported configuration.');
    actualConfig = evalin('base', 'YMBOX_Drive_Config');
    assert(isequaln(actualConfig, cfg), 'YMBOX:Configuration:Readback', ...
        'Published model configuration did not match the imported configuration.');
    report.ParameterReadbackPassed = true;
end
if options.BuildCode
    slbuild('YMBOX_Deluxe_code');
    report.CodeBuildPassed = true;
end
report.Passed = true;
clear cleanup;
if options.Activate
    activeFile = fullfile(root, 'ProjectConfiguration', ...
        'ApplicationParameters', 'YMBOX_ActiveConfiguration.json');
    hadActiveFile = isfile(activeFile);
    previousText = '';
    if hadActiveFile
        previousText = fileread(activeFile);
    end
    try
        writeTextAtomic(activeFile, [jsonencode(envelope, 'PrettyPrint', true) newline]);
        evalin('base', 'clear YMBOX_Configuration_UserConfig');
        YMBOX_InitializeModel('simulation', 'YMBOX_Deluxe_sim');
    catch exception
        if hadActiveFile
            writeTextAtomic(activeFile, previousText);
        elseif isfile(activeFile)
            delete(activeFile);
        end
        restoreState(previous);
        rethrow(exception);
    end
    report.Activated = true;
    report.ActiveFile = activeFile;
    report.BackupsCreated = false;
end
fprintf('YMBOX_CONFIGURATION_IMPORT pass=%u model_update=%u build=%u activated=%u\n', ...
    report.Passed, report.ModelUpdatesPassed, report.CodeBuildPassed, report.Activated);
end

function writeTextAtomic(file, text)
temporary = [tempname(fileparts(file)) '.json.tmp'];
cleanup = onCleanup(@() deleteIfPresent(temporary));
fid = fopen(temporary, 'w', 'n', 'UTF-8');
assert(fid ~= -1, 'YMBOX:Configuration:WriteFailed', ...
    'Cannot create temporary JSON configuration.');
closeFile = onCleanup(@() fclose(fid));
fprintf(fid, '%s', text);
clear closeFile;
[moved, message] = movefile(temporary, file, 'f');
assert(moved, 'YMBOX:Configuration:WriteFailed', ...
    'Cannot replace active JSON configuration: %s', message);
clear cleanup;
end

function deleteIfPresent(file)
if isfile(file), delete(file); end
end

function state = captureState()
names = {'YMBOX_Configuration_UserConfig', 'KuMDAS_ObserverBuildVariant'};
state.variables = struct();
state.names = names;
for index = 1:numel(names)
    if evalin('base', sprintf('exist(''%s'',''var'')', names{index}))
        value = evalin('base', names{index});
        if isa(value, 'Simulink.Parameter'), value = copy(value); end
        state.variables.(names{index}) = value;
    end
end
state.coreVariant = [];
state.coreDirty = '';
if bdIsLoaded('YMBOX_Control_Core')
    workspace = get_param('YMBOX_Control_Core', 'ModelWorkspace');
    state.coreVariant = copy(workspace.getVariable('KuMDAS_ObserverBuildVariant'));
    state.coreDirty = get_param('YMBOX_Control_Core', 'Dirty');
end
end

function restoreState(state)
for index = 1:numel(state.names)
    name = state.names{index};
    if isfield(state.variables, name)
        assignin('base', name, state.variables.(name));
    else
        evalin('base', ['clear ' name]);
    end
end
YMBOX_InitializeModel('simulation', 'YMBOX_Deluxe_sim');
if ~isempty(state.coreVariant) && bdIsLoaded('YMBOX_Control_Core')
    workspace = get_param('YMBOX_Control_Core', 'ModelWorkspace');
    workspace.assignin('KuMDAS_ObserverBuildVariant', state.coreVariant);
    set_param('YMBOX_Control_Core', 'Dirty', state.coreDirty);
end
end
