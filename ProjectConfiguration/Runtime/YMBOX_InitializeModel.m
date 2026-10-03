function context = YMBOX_InitializeModel(modelRole, modelName)
%YMBOX_INITIALIZEMODEL Resolve and publish all YMBOX runtime data.
%   CONTEXT = YMBOX_INITIALIZEMODEL(MODELROLE, MODELNAME) is the single
%   initialization entry point for simulation, generated-code, and shared
%   core models. It resolves the calculator configuration and timing once,
%   validates them, publishes compatibility variables, and then creates the
%   legacy Simulink.Signal and mpt.Parameter objects in dependency order.

arguments
    modelRole (1,1) string {mustBeMember(modelRole, ["simulation", "code", "core"])}
    modelName = ""
end

modelName = string(modelName);
% The calculator's complete document is the only configuration interface.
% Import/verification can supply that same document in the workspace.
toolConfiguration = readBaseStruct('YMBOX_Configuration_UserConfig');
if isempty(fieldnames(toolConfiguration))
    toolConfiguration = YMBOX_Configuration_ReadActive();
end
assert(isfield(toolConfiguration, 'drive'), ...
    'YMBOX:Configuration:CompleteDocumentRequired', ...
    'Use a complete document exported by the YMBOX calculator.');
allowUnreleasedControlFrequency = modelRole ~= "simulation" && ...
    readBaseLogical( ...
    'YMBOX_DirectCodegen_AllowUnreleasedControlFrequency');
requestedConfig = YMBOX_Configuration_Decode(toolConfiguration, ...
    AllowUnreleasedControlFrequency=allowUnreleasedControlFrequency);

% Apply the selected build even when a referenced core reuses the parent
% context. A freshly loaded core carries its saved workspace selection.
publishBuildVariant(requestedConfig.Execution.ObserverBuildVariant);

% A referenced core consumes the already-published parent context. This
% avoids executing the complete parameter pipeline twice during a top-model
% update while keeping standalone core compilation deterministic.
if modelRole == "core"
    existingContext = readBaseStruct('YMBOX_Initialization_Context');
    if isReusableContext(existingContext, requestedConfig, ...
            allowUnreleasedControlFrequency)
        context = existingContext;
        normalizePublishedSingleParameters();
        return;
    end
end

sampleTime_s = resolveControlPeriod(modelRole, modelName, requestedConfig);
[driveConfig, driveDerived] = YMBOX_Drive_ResolveProfile( ...
    sampleTime_s, requestedConfig, ...
    AllowUnreleasedControlFrequency=allowUnreleasedControlFrequency);

if modelRole == "code"
    requestedFrequency_Hz = requestedConfig.Timing.ControlFrequency_Hz;
    mismatch_ppm = 1e6*abs( ...
        driveDerived.Timing.ControlFrequency_Hz-requestedFrequency_Hz) / ...
        requestedFrequency_Hz;
    if mismatch_ppm > driveConfig.Timing.ExactMatchTolerance_ppm
        error('YMBOX:Initialization:CodeRateMismatch', [ ...
            'The code-model FixedStep realizes %.12g Hz, but ' ...
            'The calculator configuration requests %.12g Hz. Call ' ...
            'YMBOX_set_code_base_rate(%.12g) before building.'], ...
            driveDerived.Timing.ControlFrequency_Hz, ...
            requestedFrequency_Hz, requestedFrequency_Hz);
    end
end

validation = YMBOX_Drive_ValidateParams(driveConfig, driveDerived.SampleTime_s, false, driveDerived);
if ~validation.Passed
    error('YMBOX:Drive:InvalidProfile', '%s', ...
        strjoin(cellstr(validation.Errors), newline));
end

[smoConfig, smoDerived] = YMBOX_SMO_ResolveDriveProfile(driveDerived.SampleTime_s, driveConfig);

timingProfile = driveDerived.Timing;
timingProfile.Name = char(modelRole + " application scheduler");
timingProfile.BasePeriod_s = timingProfile.ControlPeriod_s;
timingProfile.BaseRate_Hz = timingProfile.ControlFrequency_Hz;
if strlength(modelName) > 0
    timingProfile.Model = char(modelName);
end

context.SchemaVersion = uint16(1);
context.IsComplete = false;
context.ModelRole = char(modelRole);
context.ModelName = char(modelName);
context.AllowUnreleasedControlFrequency = ...
    allowUnreleasedControlFrequency;
context.Timing = timingProfile;
context.RequestedConfig = requestedConfig;
context.DriveConfig = driveConfig;
context.DriveDerived = driveDerived;
context.DriveValidation = validation;
context.SmoConfig = smoConfig;
context.SmoDerived = smoDerived;

publishContext(context);

publisherScripts = [ ...
    "YMBOX_Input_Direct_Data"
    "YMBOX_Input_CAN_Data"
    "YMBOX_MotorParameter"
    "MDSP_Model_Library"
    "MDFM_Model_Library"
    "MDTM_Model_Library"
    "MDSA_Model_Library"
    "MDAS_Model_Library"
    "MDSM_Model_Library"
    "MDCC_Model_Library"
    ];
for scriptIndex = 1:numel(publisherScripts)
    evalin('base', char(publisherScripts(scriptIndex) + ";"));
end
normalizePublishedSingleParameters();

context.PublisherScripts = cellstr(publisherScripts);
context.IsComplete = true;
publishContext(context);

fprintf(['YMBOX initialization complete: %s, control %.12g Hz, ' ...
    'PWM %.12g Hz, profile %s, warnings %u.\n'], ...
    modelRole, timingProfile.ControlFrequency_Hz, ...
    timingProfile.PwmFrequency_Hz, driveConfig.Meta.ProfileName, ...
    validation.WarningCount);
end

function publishBuildVariant(value)
variantParameter = Simulink.Parameter;
variantParameter.Value = uint8(value);
variantParameter.DataType = 'uint8';
variantParameter.CoderInfo.StorageClass = 'Auto';
assignin('base', 'KuMDAS_ObserverBuildVariant', variantParameter);
if bdIsLoaded('YMBOX_Control_Core')
    workspace = get_param('YMBOX_Control_Core', 'ModelWorkspace');
    existingVariant = workspace.getVariable('KuMDAS_ObserverBuildVariant');
    if ~isequal(existingVariant.Value, variantParameter.Value)
        existingVariant.Value = variantParameter.Value;
    end
end
end

function sampleTime_s = resolveControlPeriod( ...
        modelRole, modelName, requestedConfig)
if modelRole == "code"
    if strlength(modelName) == 0
        modelName = string(bdroot);
    end
    fixedStep = get_param(char(modelName), 'FixedStep');
    if strcmp(strtrim(fixedStep), 'Cf_CONTROL_TASK_TIME_S')
        sampleTime_s = 1/double(requestedConfig.Timing.ControlFrequency_Hz);
    else
        sampleTime_s = str2double(fixedStep);
    end
    if ~isfinite(sampleTime_s) || sampleTime_s <= 0
        error('YMBOX:Initialization:InvalidCodeFixedStep', ...
            'Code-model FixedStep must be a positive numeric period.');
    end
    return;
end

sampleTime_s = 1/double(requestedConfig.Timing.ControlFrequency_Hz);
end

function publishContext(context)
timing = context.Timing;
assignin('base', 'Cf_TICK_TIME_S', timing.ControlPeriod_s);
assignin('base', 'Cf_CONTROL_TASK_TIME_S', timing.ControlPeriod_s);
assignin('base', 'Cf_INPUT_TASK_TIME_S', timing.InputPeriod_s);
assignin('base', 'Cf_PWM_TIME_S', timing.PwmPeriod_s);
assignin('base', 'YMBOX_Timing_Profile', timing);
assignin('base', 'YMBOX_Drive_Config', context.DriveConfig);
assignin('base', 'YMBOX_Drive_Derived', context.DriveDerived);
assignin('base', 'YMBOX_Drive_Validation', context.DriveValidation);
assignin('base', 'YMBOX_SMO_Config', context.SmoConfig);
assignin('base', 'YMBOX_SMO_Derived', context.SmoDerived);
assignin('base', 'YMBOX_Initialization_Context', context);
end

function value = readBaseStruct(variableName)
value = struct();
if evalin('base', sprintf('exist(''%s'',''var'')', variableName))
    candidate = evalin('base', variableName);
    if isstruct(candidate)
        value = candidate;
    end
end
end

function value = readBaseLogical(variableName)
value = false;
if evalin('base', sprintf('exist(''%s'',''var'')', variableName))
    candidate = evalin('base', variableName);
    assert(islogical(candidate) && isscalar(candidate), ...
        'YMBOX:Initialization:InvalidDirectCodegenOption', ...
        '%s must be a scalar logical value.', variableName);
    value = candidate;
end
end

function reusable = isReusableContext( ...
        context, requestedConfig, allowUnreleasedControlFrequency)
reusable = isstruct(context) && ...
    isfield(context, 'IsComplete') && context.IsComplete && ...
    isfield(context, 'RequestedConfig') && ...
    isequaln(context.RequestedConfig, requestedConfig) && ...
    isfield(context, 'AllowUnreleasedControlFrequency') && ...
    context.AllowUnreleasedControlFrequency == ...
    allowUnreleasedControlFrequency && ...
    isfield(context, 'ModelRole') && ...
    any(strcmp(context.ModelRole, {'simulation', 'code'}));
end

function normalizePublishedSingleParameters()
% Keep the stored calibration value consistent with its generated type.
% Offline profile derivation and scheduler timing intentionally use double,
% but every application parameter published as single must also carry a
% single Value so model update, tuning, and code generation see one type.
variables = evalin('base', 'whos');
for variableIndex = 1:numel(variables)
    variableName = variables(variableIndex).name;
    parameter = evalin('base', variableName);
    if ~isa(parameter, 'Simulink.Parameter') || ...
            ~strcmp(strtrim(parameter.DataType), 'single')
        continue;
    end

    value = parameter.Value;
    if isnumeric(value) && isfloat(value)
        typedValue = single(value);
        assert(isreal(value) && all(isfinite(typedValue(:))) && ...
            all(value(:) == 0 | typedValue(:) ~= 0), ...
            'YMBOX:Configuration:PublishedSingleRange', ...
            ['Calculated parameter %s cannot be represented by single. ' ...
            'Check the calculator inputs and derived values.'], variableName);
        if ~isa(value, 'single')
            parameter.Value = typedValue;
            assignin('base', variableName, parameter);
        end
    end
end
end
