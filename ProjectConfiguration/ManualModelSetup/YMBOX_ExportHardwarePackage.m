function result = YMBOX_ExportHardwarePackage(outputDirectory, hardwareDeviceType)
%YMBOX_ExportHardwarePackage - Build a relocatable hardware integration package
%   RESULT = YMBOX_ExportHardwarePackage exports the saved calculator profile,
%   generated control code, runtime, board template, and build manifest into
%   a new timestamped directory beside the model source tree.
%
%   RESULT = YMBOX_ExportHardwarePackage(FOLDER) uses a new or empty FOLDER.
%
%   RESULT = YMBOX_ExportHardwarePackage(FOLDER,DEVICE) temporarily selects
%   the Simulink production and test hardware DEVICE for both code shell and
%   core, so exported word sizes match the selected target compiler.
%   For example, DEVICE can be 'Texas Instruments->C2000'. An empty DEVICE
%   retains the saved target. The original model settings are restored.
%
%   Save model edits before export. No board flashing or motor startup occurs.
%   See also SLBUILD, PACKNGO

modelRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
[workspaceRoot, modelFolder] = fileparts(modelRoot);
runtimeRoot = fullfile(modelRoot,'Platform','Runtime');
if nargin < 1 || isempty(outputDirectory)
    % Same sibling output folder as YMBOX_Deluxe_init.m.
    outputDirectory = fullfile(workspaceRoot,[modelFolder '_outputs'], ...
        'hardware',char(datetime('now','Format','yyyyMMdd_HHmmss')));
end
if nargin < 2, hardwareDeviceType = ''; end
outputDirectory = char(java.io.File(char(outputDirectory)).getCanonicalPath());
if isfolder(outputDirectory)
    entries = dir(outputDirectory);
    assert(all(ismember({entries.name},{'.','..'})), ...
        'YMBOX:Export:OutputNotEmpty','Use a new or empty output directory.');
end
models = {'YMBOX_Deluxe_code','YMBOX_Control_Core'};
for k = 1:numel(models)
    if ~bdIsLoaded(models{k})
        open_system(fullfile(modelRoot,[models{k} '.slx']));
    end
    assert(strcmp(get_param(models{k},'Dirty'),'off'), ...
        'YMBOX:Export:UnsavedModel','Save %s before export.',models{k});
end
mkdir(outputDirectory);
codegenDirectory = fullfile(outputDirectory,'build','codegen');
packageDirectory = fullfile(outputDirectory,'package');
mkdir(packageDirectory);
savedFileGen = Simulink.fileGenControl('getConfig');
savedFolder = pwd;
savedDevice = cellfun(@(m)get_param(m,'ProdHWDeviceType'),models,'UniformOutput',false);
savedTargetDevice = cellfun(@(m)get_param(m,'TargetHWDeviceType'),models,'UniformOutput',false);
savedGenOnly = get_param(models{1},'GenCodeOnly');
savedDocumentExists = evalin('base','exist(''YMBOX_Configuration_UserConfig'',''var'') ~= 0');
savedDocument = [];
if savedDocumentExists
    savedDocument = evalin('base','YMBOX_Configuration_UserConfig');
end
savedState.models = models;
savedState.fileGen = savedFileGen;
savedState.folder = savedFolder;
savedState.device = savedDevice;
savedState.targetDevice = savedTargetDevice;
savedState.genOnly = savedGenOnly;
savedState.documentExists = savedDocumentExists;
savedState.document = savedDocument;
cleanup = onCleanup(@()restoreExportContext(savedState));
cd(modelRoot);
Simulink.fileGenControl('set','CodeGenFolder',codegenDirectory, ...
    'CacheFolder',fullfile(outputDirectory,'build','cache'),'createDir',true);
configurationFile = fullfile(modelRoot,'ProjectConfiguration', ...
    'ApplicationParameters','YMBOX_ActiveConfiguration.json');
configurationHash = fileHash(configurationFile);
document = YMBOX_Configuration_ReadActive();
assignin('base','YMBOX_Configuration_UserConfig',document);
cfg = YMBOX_Configuration_Decode(document);
YMBOX_Control_Core_BusObjects;
% Register the "YMBOX single math" code replacement library (rtwTargetInfo.m)
% in sessions where its folder was added to the path after MATLAB started.
sl_refresh_customizations;
if ~isempty(hardwareDeviceType)
    for k = 1:numel(models)
        set_param(models{k},'ProdHWDeviceType',char(hardwareDeviceType));
        set_param(models{k},'TargetHWDeviceType',char(hardwareDeviceType));
    end
end
% These are temporary build settings, not edits to control topology.
set_param(models{1},'GenCodeOnly','on');
set_param(models{1},'SimulationCommand','update');
context = evalin('base','YMBOX_Initialization_Context');
assert(context.Timing.ControlDivider == 1, ...
    'YMBOX:Export:UnexpectedDivider','One ymbox_deluxe_step must be one control tick.');
periodUs = context.Timing.ControlPeriod_s*1e6;
assert(abs(periodUs-round(periodUs)) < 1e-6, ...
    'YMBOX:Export:FractionalMicrosecondPeriod', ...
    'This port ABI requires a whole-microsecond control period; got %.9g us.',periodUs);
targetDevice = get_param(models{1},'ProdHWDeviceType');
slbuild(models{1});
buildDirectory = RTW.getBuildDir(models{1});
buildData = load(fullfile(buildDirectory.BuildDirectory,'buildInfo.mat'),'buildInfo');
rawArchive = fullfile(outputDirectory,'model_sources.zip');
packNGo(buildData.buildInfo,'packType','flat','fileName',rawArchive, ...
    'minimalHeaders',false,'ignoreFileMissing',false);
unpacked = fullfile(outputDirectory,'build','packngo');
unzip(rawArchive,unpacked);
generatedDirectory = fullfile(packageDirectory,'generated');
mkdir(generatedDirectory);
% packNGo may contain referenced-model libraries. Also collect the referenced
% model C sources from this fresh build, so no target-specific .a is required.
roots = {unpacked,buildDirectory.BuildDirectory, ...
    fullfile(codegenDirectory,'slprj','ert')};
for rootIndex = 1:numel(roots)
    for extension = {'.c','.h'}
        files = dir(fullfile(roots{rootIndex},'**',['*' extension{1}]));
        for fileIndex = 1:numel(files)
            file = files(fileIndex);
            if ismember(file.name,{'ert_main.c','rt_main.c'}) || ...
                    startsWith(file.name,{'mdsa_sincos_','ymbox_atan_', ...
                    'ymbox_sqrt_','ymbox_math_init','ymbox_scalar_math_', ...
                    'ymbox_tmu_div_inline', ...
                    'ymbox_stm32_cordic'}) || ...
                    contains(file.folder,[filesep 'html' filesep])
                continue;
            end
            copyUnique(fullfile(file.folder,file.name), ...
                fullfile(generatedDirectory,file.name));
        end
    end
end
copyfile(fullfile(runtimeRoot,'include'),fullfile(packageDirectory,'include'));
copyfile(fullfile(runtimeRoot,'source'),fullfile(packageDirectory,'source'));
copyfile(fullfile(modelRoot,'Platform'),fullfile(packageDirectory,'Platform'));
% The runtime already sits at the package root as include/ and source/.
rmdir(fullfile(packageDirectory,'Platform','Runtime'),'s');
mkdir(fullfile(packageDirectory,'configuration'));
copyfile(configurationFile,fullfile(packageDirectory,'configuration','YMBOX_ActiveConfiguration.json'));
copyfile(fullfile(modelRoot,'Platform','PortTemplate','HARDWARE_PORT.md'), ...
    fullfile(packageDirectory,'README.md'));
copyfile(fullfile(modelRoot,'Platform','PortTemplate','CMakeLists.txt'), ...
    fullfile(packageDirectory,'CMakeLists.txt'));
copyfile(fullfile(modelRoot,'Platform','PortTemplate','integration_example.c'), ...
    fullfile(packageDirectory,'integration_example.c'));
writeBuildInfo(fullfile(packageDirectory,'include','ymbox_build_info.h'), ...
    cfg,context.Timing,configurationHash,targetDevice);

generatedFiles = dir(fullfile(generatedDirectory,'*.c'));
sourceFiles = [strcat("generated/",string({generatedFiles.name})), ...
    "source/drive_framework.c","source/drive_state_machine.c", ...
    "source/ymbox_runtime.c","source/ymbox_model_adapter.c"];
mathFiles = ["Platform/SharedMath/ymbox_math_init.c", ...
    "Platform/SharedMath/ymbox_scalar_math_f32.c", ...
    "Platform/SinCos/mdsa_sincos_" + lower(string(cfg.PlatformMath.SinCosBackend)) + ".c", ...
    "Platform/Atan/ymbox_atan_" + lower(string(cfg.PlatformMath.AtanBackend)) + ".c", ...
    "Platform/Sqrt/ymbox_sqrt_" + lower(string(cfg.PlatformMath.SqrtBackend)) + ".c"];
assert(all(isfile(fullfile(packageDirectory,mathFiles))), ...
    'YMBOX:Export:MissingMathBackend','A selected math implementation is missing.');
writeText(fullfile(packageDirectory,'sources.txt'),strjoin([sourceFiles,mathFiles],newline)+newline);
definitions = "MDSA_SINCOS_LUT_COUNTS=" + string(cfg.PositionSensor.ControlAngleCounts);
useTmu = any(strcmp(struct2cell(cfg.PlatformMath),'TI_TMU'));
definitions(end+1) = "YMBOX_TMU_DIVISION=" + string(double(useTmu));
writeText(fullfile(packageDirectory,'defines.txt'),strjoin(definitions,newline)+newline);
assert(strcmp(fileHash(configurationFile),configurationHash), ...
    'YMBOX:Export:ConfigurationChanged','Configuration changed during export. Rebuild.');
manifest.schemaVersion = 1;
manifest.interfaceVersion = 1;
manifest.model = models{1};
manifest.profile = cfg.Meta.ProfileName;
manifest.hardwareDeviceType = targetDevice;
manifest.controlPeriod_us = round(context.Timing.ControlPeriod_s*1e6);
manifest.pwmFrequency_Hz = context.Timing.PwmFrequency_Hz;
manifest.mdtmDivider = cfg.Timing.MDTMTaskDivider_NULL;
manifest.configurationSha256 = configurationHash;
manifest.sourceModelSha256 = fileHash(fullfile(modelRoot,[models{1} '.slx']));
manifest.coreModelSha256 = fileHash(fullfile(modelRoot,[models{2} '.slx']));
manifest.matlabVersion = version;
manifest.math = cfg.PlatformMath;
manifest.compileDefinitions = cellstr(definitions);
manifest.boardImplementationRequired = true;
manifest.hardwareValidated = false;
manifest.generatedSources = cellstr(sourceFiles);
allFiles = dir(fullfile(packageDirectory,'**','*'));
allFiles = allFiles(~[allFiles.isdir]);
manifest.files = repmat(struct('path','','sha256',''),numel(allFiles),1);
for k = 1:numel(allFiles)
    source = fullfile(allFiles(k).folder,allFiles(k).name);
    manifest.files(k).path = strrep(source(numel(packageDirectory)+2:end),'\','/');
    manifest.files(k).sha256 = fileHash(source);
end
writeText(fullfile(packageDirectory,'manifest.json'),string(jsonencode(manifest,'PrettyPrint',true)));
archive = fullfile(outputDirectory,'YMBOX_HardwarePackage.zip');
zip(archive,{'*'},packageDirectory);
result = struct('PackageDirectory',packageDirectory,'Archive',archive, ...
    'Manifest',fullfile(packageDirectory,'manifest.json'),'BuildDirectory', ...
    buildDirectory.BuildDirectory,'ConfigurationSha256',configurationHash);
fprintf('YMBOX_HARDWARE_PACKAGE_OK\n%s\n',archive);
clear cleanup;
end

function restoreExportContext(state)
for k = 1:numel(state.models)
    if bdIsLoaded(state.models{k})
        set_param(state.models{k},'ProdHWDeviceType',state.device{k});
        set_param(state.models{k},'TargetHWDeviceType',state.targetDevice{k});
    end
end
if bdIsLoaded(state.models{1})
    set_param(state.models{1},'GenCodeOnly',state.genOnly);
end
if state.documentExists
    assignin('base','YMBOX_Configuration_UserConfig',state.document);
else
    evalin('base','clear YMBOX_Configuration_UserConfig');
end
Simulink.fileGenControl('setConfig','config',state.fileGen);
cd(state.folder);
% Files are never saved by export. Temporary values have been restored;
% every model was clean on entry.
for k = 1:numel(state.models)
    if bdIsLoaded(state.models{k})
        set_param(state.models{k},'Dirty','off');
    end
end
end

function writeBuildInfo(file,cfg,timing,hash,hardware)
period = round(timing.ControlPeriod_s*1e6);
supported = 63 + 64*double(cfg.Execution.ObserverBuildVariant == 1);
hardware = strrep(strrep(hardware,'\','\\'),'"','\"');
text = sprintf([ ...
    '#ifndef YMBOX_BUILD_INFO_H_\n#define YMBOX_BUILD_INFO_H_\n' ...
    '#include "ymbox_types.h"\n' ...
    '/* Generated with the model. Do not hand-edit timing or limits. */\n' ...
    'static const YMBOX_BuildInfo YMBOX_BUILD_INFO = {\n' ...
    '  YMBOX_PORT_ABI_VERSION, %uU, %uU, %uU, %uU, %uU,\n' ...
    '  %uU, 62U,\n' ...
    '  DRIVE_FEATURE_GATE_POWER | DRIVE_FEATURE_GATE_LOGIC |\n' ...
    '  DRIVE_FEATURE_PWM_OUTPUT | DRIVE_FEATURE_CURRENT_FEEDBACK |\n' ...
    '  DRIVE_FEATURE_VOLTAGE_FEEDBACK,\n' ...
    '  %s, %s, %s, %s, %s, %s,\n' ...
    '  "%s", "%s"\n};\n#endif\n'], ...
    period,cfg.Timing.MDTMTaskDivider_NULL, ...
    ceil(cfg.Protection.CommandTimeout_s*1e6),period, ...
    cfg.PositionSensor.NativeCountsPerMechanicalRev,supported, ...
    cFloat(timing.PwmFrequency_Hz),cFloat(cfg.Inverter.DeadTime_s), ...
    cFloat(cfg.Inverter.MinDuty_NULL),cFloat(cfg.Inverter.MaxDuty_NULL), ...
    cFloat(cfg.Timing.ExactMatchTolerance_ppm), ...
    string(logical(cfg.DcBusMeasurement.CurrentSource_enum == 0)),hash,hardware);
% MATLAB string(logical) is "true" or "false", matching stdbool.h.
writeText(file,string(text));
end

function text = cFloat(value)
text = sprintf('%.9g',single(value));
if ~contains(text,{'.','e','E'}), text = [text '.0']; end
text = [text 'F'];
end

function copyUnique(source,destination)
if isfile(destination)
    assert(strcmp(fileHash(source),fileHash(destination)), ...
        'YMBOX:Export:FilenameCollision','Different dependency files named %s.',destination);
else
    copyfile(source,destination);
end
end

function hash = fileHash(file)
fid = fopen(file,'rb');
assert(fid >= 0,'YMBOX:Export:ReadFailed','Cannot read %s.',file);
cleanup = onCleanup(@()fclose(fid));
bytes = fread(fid,Inf,'*uint8');
digest = java.security.MessageDigest.getInstance('SHA-256');
digest.update(bytes);
hash = lower(reshape(dec2hex(typecast(digest.digest(),'uint8'),2).',1,[]));
end

function writeText(file,text)
fid = fopen(file,'w','n','UTF-8');
assert(fid >= 0,'YMBOX:Export:WriteFailed','Cannot write %s.',file);
cleanup = onCleanup(@()fclose(fid));
fprintf(fid,'%s',text);
end
