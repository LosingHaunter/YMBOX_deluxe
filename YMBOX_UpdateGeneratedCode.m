function result = YMBOX_UpdateGeneratedCode(profileFile, projectDirectory)
%YMBOX_UpdateGeneratedCode - Refresh generated code in an integrated CCS project
%   RESULT = YMBOX_UpdateGeneratedCode(PROFILEFILE, PROJECTDIRECTORY) generates
%   code from the calculator JSON PROFILEFILE (a saved YMBOX profile or a
%   complete configuration with a drive node) and synchronizes only the
%   generated files under PROJECTDIRECTORY/model. Hand-written sources, board
%   code, linker files and CCS settings are not touched. The project must
%   have been integrated once from a YMBOX_ExportHardwarePackage export.
%
%   Example:
%     YMBOX_UpdateGeneratedCode('Tools/Calculator/YMBOX_Data/Profiles/ymbox/KY130_3000rpm_SMO_NoLoad.json', ...
%         'D:/Work/MyBoardProject')
%
%   See also YMBOX_ExportHardwarePackage

arguments
    profileFile (1,1) string {mustBeNonzeroLengthText}
    projectDirectory (1,1) string {mustBeNonzeroLengthText}
end

modelRoot = fileparts(mfilename('fullpath'));
profileFile = canonical(profileFile);
projectDirectory = canonical(projectDirectory);
destination = fullfile(projectDirectory,'model');
assert(isfile(profileFile),'YMBOX:Update:MissingProfile', ...
    'JSON file not found: %s',profileFile);
required = {'.cproject','model/include/ymbox_types.h', ...
    'model/source/ymbox_model_adapter.c','model/configuration/YMBOX_ActiveConfiguration.json', ...
    'model/manifest.json','model/sources.txt','model/defines.txt'};
assert(all(cellfun(@(p)isfile(fullfile(projectDirectory,p)),required)), ...
    'YMBOX:Update:NotIntegratedProject', ...
    'Select an existing integrated CCS project, not an empty directory.');

started = tic;
state.folder = pwd;
state.searchPath = path;
state.fileGen = Simulink.fileGenControl('getConfig');
state.models = {'YMBOX_Deluxe_code','YMBOX_Control_Core'};
state.loaded = cellfun(@bdIsLoaded,state.models);
state.params = cell(1,numel(state.models));
state.variant = [];
state.hadDocument = evalin('base','exist(''YMBOX_Configuration_UserConfig'',''var'') ~= 0');
state.document = [];
if state.hadDocument
    state.document = evalin('base','YMBOX_Configuration_UserConfig');
end
for k = find(state.loaded)
    assert(strcmp(get_param(state.models{k},'Dirty'),'off'), ...
        'YMBOX:Update:UnsavedModel','Save or close %s before generation.',state.models{k});
    assert(strcmp(get_param(state.models{k},'SimulationStatus'),'stopped'), ...
        'YMBOX:Update:ModelRunning','Stop %s before generation.',state.models{k});
    state.params{k} = modelSettings(state.models{k});
end
if state.loaded(2)
    ws = get_param(state.models{2},'ModelWorkspace');
    variant = ws.getVariable('KuMDAS_ObserverBuildVariant');
    state.variant = variant.Value;
end
restore = onCleanup(@()restoreContext(state));
cd(modelRoot);
evalin('base',sprintf('run(''%s'');',strrep(fullfile(modelRoot,'YMBOX_Deluxe_init.m'),'''','''''')));
document = readProfile(profileFile);
cfg = document.drive;
oldDocument = readProfile(fullfile(destination,'configuration','YMBOX_ActiveConfiguration.json'));
checkBoardContract(cfg,oldDocument.drive);

[workspaceRoot, modelFolder] = fileparts(modelRoot);
outputRoot = fullfile(workspaceRoot,[modelFolder '_outputs'],'ccs_update');
if ~isfolder(outputRoot), mkdir(outputRoot); end
lockFile = fullfile(outputRoot,'generation.lock');
lock = java.io.File(lockFile);
assert(lock.createNewFile(),'YMBOX:Update:Busy', ...
    ['Another update is running. If MATLAB previously crashed, first ' ...
     'confirm no update is running, then remove %s.'],lockFile);
unlock = onCleanup(@()delete(lockFile));
Simulink.fileGenControl('set','CodeGenFolder',fullfile(outputRoot,'codegen'), ...
    'CacheFolder',fullfile(outputRoot,'cache'),'createDir',true);
assignin('base','YMBOX_Configuration_UserConfig',document);
sl_refresh_customizations;
for k = 1:numel(state.models)
    if ~bdIsLoaded(state.models{k})
        load_system(fullfile(modelRoot,[state.models{k} '.slx']));
    end
    assert(strcmpi(canonical(get_param(state.models{k},'FileName')), ...
        canonical(fullfile(modelRoot,[state.models{k} '.slx']))), ...
        'YMBOX:Update:WrongModel','A different copy of %s is loaded.',state.models{k});
    set_param(state.models{k},'ProdHWDeviceType','Texas Instruments->C2000', ...
        'TargetHWDeviceType','Texas Instruments->C2000','GenCodeOnly','on');
end
fprintf('YMBOX: %s\nJSON: %s\nTarget: %s\n',cfg.Meta.ProfileName,profileFile,projectDirectory);
slbuild(state.models{1},'GenerateCodeOnly',true);
context = evalin('base','YMBOX_Initialization_Context');
assert(isequaln(context.RequestedConfig,cfg), ...
    'YMBOX:Update:ConfigurationMismatch','Generated configuration does not match the selected JSON.');
assert(context.Timing.ControlDivider == 1 && ...
    abs(context.Timing.ControlPeriod_s*1e6-round(context.Timing.ControlPeriod_s*1e6)) < 1e-6, ...
    'YMBOX:Update:UnsupportedPeriod','This interface requires one whole-microsecond control tick.');

stage = tempname(outputRoot);
mkdir(stage);
discardStage = onCleanup(@()removeTemporary(stage,outputRoot));
mkdir(fullfile(stage,'generated'));
buildDirectories = cell(1,numel(state.models));
for k = 1:numel(state.models)
    info = RTW.getBuildDir(state.models{k});
    if k == 1
        buildDirectories{k} = info.BuildDirectory;
    else
        buildDirectories{k} = fullfile(info.CodeGenFolder,info.ModelRefRelativeBuildDir);
    end
end
collectGenerated(buildDirectories,fullfile(outputRoot,'codegen'), ...
    modelRoot,destination,fullfile(stage,'generated'));
writeMetadata(stage,destination,cfg,document,context.Timing);
result = synchronize(stage,destination,outputRoot);
result.Profile = cfg.Meta.ProfileName;
result.ProjectDirectory = projectDirectory;
result.Elapsed_s = toc(started);
fprintf(['YMBOX_UPDATE_OK: updated %u, removed %u, unchanged %u; %.1f s.\n' ...
    'Refresh (F5) in CCS, then build manually. No firmware was compiled or downloaded.\n'], ...
    numel(result.Updated),numel(result.Removed),result.Unchanged,result.Elapsed_s);
if ~isempty(result.Removed)
    fprintf('Previous changed/removed files: %s\n',result.BackupDirectory);
end
clear discardStage unlock restore;
end

function document = readProfile(file)
[~,~,ext] = fileparts(file);
assert(strcmpi(ext,'.json'),'YMBOX:Update:NotJson','Use a JSON configuration or YMBOX profile.');
raw = jsondecode(fileread(file));
if isfield(raw,'kind') && strcmp(raw.kind,'ymbox')
    assert(raw.schemaVersion == 1 && isfield(raw,'data') && ...
        raw.data.schemaVersion == 1 && isfield(raw.data,'values'), ...
        'YMBOX:Update:ProfileSchema','Unsupported saved profile schema.');
    [values,used] = readFields(YMBOX_Drive_Parameters(),raw.data.values,'');
    assert(isempty(setdiff(fieldnames(raw.data.values),used)), ...
        'YMBOX:Update:UnknownProfileField','Saved profile contains unknown fields.');
    raw = values;
end
cfg = YMBOX_Configuration_Decode(raw);
document = struct('schemaVersion',1,'kind','YMBOXConfiguration','drive',cfg);
end

function [out,used] = readFields(template,flat,prefix)
out = template;
used = {};
names = fieldnames(template);
for k = 1:numel(names)
    field = names{k};
    fullName = [prefix field];
    if isstruct(template.(field))
        [out.(field),nested] = readFields(template.(field),flat,[fullName '.']);
        used = [used; nested]; %#ok<AGROW>
    else
        key = matlab.lang.makeValidName(fullName);
        assert(isfield(flat,key),'YMBOX:Update:MissingProfileField', ...
            'Missing profile value: %s. Save a complete profile in the calculator.',fullName);
        value = flat.(key);
        if ~ischar(template.(field)) && (ischar(value) || isstring(value))
            text = strtrim(char(value));
            if isempty(text) || any(strcmpi(text,{'auto','null','nan','自动'}))
                value = [];
            else
                % JSON numbers/arrays/booleans only; never evaluate MATLAB text.
                value = jsondecode(text);
            end
        end
        out.(field) = value;
        used{end+1,1} = key; %#ok<AGROW>
    end
end
end

function checkBoardContract(cfg,old)
groups = {'Timing','Inverter','PositionSensor','PlatformMath'};
fields = {{'ControlFrequency_Hz','InputTaskFrequencyOverride_Hz'}, ...
    {'PwmFrequencyOverride_Hz','DeadTime_s','MinDuty_NULL','MaxDuty_NULL'}, ...
    {'NativeCountsPerMechanicalRev','ControlAngleCounts'},fieldnames(cfg.PlatformMath)};
for g = 1:numel(groups)
    for f = 1:numel(fields{g})
        field = fields{g}{f};
        assert(isequaln(cfg.(groups{g}).(field),old.(groups{g}).(field)), ...
            'YMBOX:Update:BoardContractChanged', ...
            ['%s.%s differs from the installed configuration. This updater does ' ...
             'not change drivers, compiler options or math backends. Adapt the ' ...
             'board and its configuration snapshot together before updating.'],groups{g},field);
    end
end
end

function collectGenerated(buildDirectories,codegenRoot,modelRoot,destination,stage)
queue = buildDirectories;
visited = {};
files = {};
includeDirs = {};
while ~isempty(queue)
    buildDir = canonical(queue{1});
    queue(1) = [];
    if any(strcmpi(visited,buildDir)), continue; end
    visited{end+1} = buildDir; %#ok<AGROW>
    data = load(fullfile(buildDir,'buildInfo.mat'),'buildInfo');
    bi = data.buildInfo;
    files = [files reshape(getSourceFiles(bi,true,true),1,[]) ...
        reshape(getIncludeFiles(bi,true,true),1,[])]; %#ok<AGROW>
    includeDirs = [includeDirs {buildDir} reshape(getIncludePaths(bi,true),1,[])]; %#ok<AGROW>
    links = getLinkObjects(bi);
    for k = 1:numel(links)
        linkDir = strrep(links(k).Path,'$(START_DIR)',codegenRoot);
        assert(isfile(fullfile(linkDir,'buildInfo.mat')), ...
            'YMBOX:Update:ExternalLibrary','Cannot collect source dependency %s.',links(k).Name);
        queue{end+1} = linkDir; %#ok<AGROW>
    end
end
includeDirs = unique([visited includeDirs],'stable');
systemHeaders = {'assert.h','stdbool.h','stdint.h','stddef.h','stdlib.h', ...
    'stdio.h','string.h','math.h','float.h','limits.h','errno.h','stdarg.h', ...
    'time.h','ctype.h','fenv.h','tgmath.h','complex.h','inttypes.h'};
seen = containers.Map('KeyType','char','ValueType','char');
while ~isempty(files)
    file = char(files{1});
    files(1) = [];
    [~,name,ext] = fileparts(file);
    leaf = [name ext];
    if any(strcmp(leaf,{'ert_main.c','rt_main.c'})) || any(strcmp(leaf,systemHeaders))
        continue;
    end
    if ~isfile(file)
        candidates = fullfile(includeDirs,file);
        index = find(cellfun(@isfile,candidates),1);
        assert(~isempty(index),'YMBOX:Update:MissingDependency','Cannot resolve %s.',file);
        file = candidates{index};
    end
    file = canonical(file);
    if isKey(seen,lower(leaf))
        assert(sameFile(file,seen(lower(leaf))), ...
            'YMBOX:Update:FilenameCollision','Different dependencies named %s.',leaf);
        continue;
    end
    seen(lower(leaf)) = file;
    platformRoot = [canonical(fullfile(modelRoot,'Platform')) filesep];
    if startsWith(file,platformRoot,'IgnoreCase',true)
        local = fullfile(destination,'Platform',file(numel(platformRoot)+1:end));
        assert(isfile(local),'YMBOX:Update:MissingMathService', ...
            'Existing board math service is missing: %s',local);
        assert(sameFile(file,local),'YMBOX:Update:MathServiceChanged', ...
            'Math service differs: %s. Review it separately; it was not overwritten.',local);
        continue;
    end
    assert(any(strcmpi(ext,{'.c','.h'})),'YMBOX:Update:UnsupportedDependency', ...
        'Unsupported dependency: %s',file);
    copyfile(file,fullfile(stage,leaf));
    includes = regexp(fileread(file),'(?m)^\s*#\s*include\s*["<]([^">]+)[">]','tokens');
    for k = 1:numel(includes)
        inc = includes{k}{1};
        if isfile(fullfile(fileparts(file),inc))
            files{end+1} = fullfile(fileparts(file),inc); %#ok<AGROW>
        else
            files{end+1} = inc; %#ok<AGROW>
        end
    end
end
assert(isfile(fullfile(stage,'YMBOX_Deluxe_code.c')) && ...
    isfile(fullfile(stage,'YMBOX_Control_Core.c')), ...
    'YMBOX:Update:IncompleteSources','Top model or referenced core is missing.');
end

function writeMetadata(stage,destination,cfg,document,timing)
mkdir(fullfile(stage,'include'));
mkdir(fullfile(stage,'configuration'));
configText = [jsonencode(document,'PrettyPrint',true) newline];
writeText(fullfile(stage,'configuration','YMBOX_ActiveConfiguration.json'),configText);
% Keep the existing BuildInfo ABI. The identifier is informational only.
digest = java.security.MessageDigest.getInstance('SHA-256');
digest.update(unicode2native(configText,'UTF-8'));
identifier = lower(reshape(dec2hex(typecast(digest.digest(),'uint8'),2).',1,[]));
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
    '  "%s", "Texas Instruments->C2000"\n};\n#endif\n'], ...
    round(timing.ControlPeriod_s*1e6),cfg.Timing.MDTMTaskDivider_NULL, ...
    ceil(cfg.Protection.CommandTimeout_s*1e6),round(timing.ControlPeriod_s*1e6), ...
    cfg.PositionSensor.NativeCountsPerMechanicalRev, ...
    63+64*double(cfg.Execution.ObserverBuildVariant == 1), ...
    cFloat(timing.PwmFrequency_Hz),cFloat(cfg.Inverter.DeadTime_s), ...
    cFloat(cfg.Inverter.MinDuty_NULL),cFloat(cfg.Inverter.MaxDuty_NULL), ...
    cFloat(cfg.Timing.ExactMatchTolerance_ppm), ...
    string(logical(cfg.DcBusMeasurement.CurrentSource_enum == 0)),identifier);
writeText(fullfile(stage,'include','ymbox_build_info.h'),text);
generated = dir(fullfile(stage,'generated','*.c'));
sources = "generated/" + string({generated.name});
oldSources = strtrim(splitlines(string(fileread(fullfile(destination,'sources.txt')))));
manual = oldSources(strlength(oldSources)>0 & ~startsWith(oldSources,'generated/'));
writeText(fullfile(stage,'sources.txt'),strjoin([sources(:);manual],newline)+newline);
% These files describe the build; the CCS project itself stays user-owned.
copyfile(fullfile(destination,'defines.txt'),fullfile(stage,'defines.txt'));
manifest.schemaVersion = 1;
manifest.interfaceVersion = 1;
manifest.kind = 'YMBOXGeneratedUpdate';
manifest.model = 'YMBOX_Deluxe_code';
manifest.profile = cfg.Meta.ProfileName;
manifest.hardwareDeviceType = 'Texas Instruments->C2000';
manifest.controlPeriod_us = round(timing.ControlPeriod_s*1e6);
manifest.pwmFrequency_Hz = timing.PwmFrequency_Hz;
manifest.mdtmDivider = cfg.Timing.MDTMTaskDivider_NULL;
manifest.configurationSha256 = identifier;
manifest.matlabVersion = version;
manifest.math = cfg.PlatformMath;
manifest.hardwareValidated = false;
manifest.generatedSources = cellstr(sources);
manifest.managedFiles = [relativeFiles(stage); {'manifest.json'}];
writeText(fullfile(stage,'manifest.json'),[jsonencode(manifest,'PrettyPrint',true) newline]);
end

function result = synchronize(stage,destination,outputRoot)
newFiles = relativeFiles(stage);
old = jsondecode(fileread(fullfile(destination,'manifest.json')));
if isfield(old,'managedFiles')
    owned = cellstr(string(old.managedFiles));
else
    % First update adopts only generated files listed by the old exporter.
    listed = {old.files.path};
    owned = listed(startsWith(listed,'generated/'))';
end
obsolete = setdiff(owned,newFiles,'stable');
for k = 1:numel(owned)
    managedPath(destination,owned{k});
end
existingSources = dir(fullfile(destination,'generated','**','*.c'));
for k = 1:numel(existingSources)
    file = fullfile(existingSources(k).folder,existingSources(k).name);
    relative = strrep(file(numel(destination)+2:end),'\','/');
    assert(any(strcmp(relative,[owned;newFiles])), ...
        'YMBOX:Update:UnmanagedSource', ...
        'Unlisted C file %s would remain in the build. Move hand-written code out of generated.',file);
end
changes = {};
for k = 1:numel(newFiles)
    target = managedPath(destination,newFiles{k});
    if ~isfile(target) || ~sameFile(fullfile(stage,newFiles{k}),target)
        changes{end+1,1} = newFiles{k}; %#ok<AGROW>
    end
end
affected = unique([changes;obsolete],'stable');
result = struct('Updated',{changes},'Removed',{obsolete}, ...
    'Unchanged',numel(newFiles)-numel(changes),'BackupDirectory','');
if isempty(affected), return; end

% One recoverable snapshot per project, outside the firmware directory.
[~,projectName] = fileparts(fileparts(destination));
key = sprintf('%08x',typecast(int32(java.lang.String(destination).hashCode()),'uint32'));
backup = fullfile(outputRoot,['previous_' projectName '_' key]);
if isfolder(backup)
    marker = fullfile(backup,'.ymbox-update-backup');
    assert(isfile(marker) && strcmpi(fileread(marker),destination), ...
        'YMBOX:Update:UnknownBackup','Refusing to replace unrecognized directory %s.',backup);
    removeTemporary(backup,outputRoot);
end
mkdir(backup);
writeText(fullfile(backup,'.ymbox-update-backup'),destination);
hadFile = false(size(affected));
for k = 1:numel(affected)
    target = managedPath(destination,affected{k});
    assert(~isfolder(target),'YMBOX:Update:PathIsDirectory','Expected a file: %s',target);
    hadFile(k) = isfile(target);
    if hadFile(k)
        saved = fullfile(backup,affected{k});
        ensureParent(saved);
        copyfile(target,saved);
    end
end
receipt = struct('destination',destination,'files',{affected},'existed',hadFile);
writeText(fullfile(backup,'restore.json'),jsonencode(receipt,'PrettyPrint',true));
transaction = containers.Map({'committed','touched'},{false,false(size(affected))});
undo = onCleanup(@()rollbackUpdate(destination,backup,affected,hadFile,transaction));
for k = 1:numel(changes)
    target = managedPath(destination,changes{k});
    ensureParent(target);
    touched = transaction('touched');
    touched(strcmp(affected,changes{k})) = true;
    transaction('touched') = touched;
    copyfile(fullfile(stage,changes{k}),target,'f');
end
for k = 1:numel(obsolete)
    target = managedPath(destination,obsolete{k});
    touched = transaction('touched');
    touched(strcmp(affected,obsolete{k})) = true;
    transaction('touched') = touched;
    if isfile(target), delete(target); end
end
transaction('committed') = true; %#ok<NASGU> Handle state read by cleanup.
clear undo;
result.BackupDirectory = backup;
end

function rollbackUpdate(destination,backup,affected,hadFile,transaction)
if transaction('committed'), return; end
for j = find(transaction('touched'))'
    target = managedPath(destination,affected{j});
    try
        if hadFile(j)
            saved = fullfile(backup,affected{j});
            if ~isfile(target) || ~sameFile(saved,target)
                copyfile(saved,target,'f');
            end
        elseif isfile(target)
            delete(target);
        end
    catch exception
        warning('YMBOX:Update:RestoreFailed', ...
            'Restore %s manually from %s: %s',target,backup,exception.message);
    end
end
end

function target = managedPath(root,relative)
allowed = {'include/ymbox_build_info.h','configuration/YMBOX_ActiveConfiguration.json', ...
    'sources.txt','defines.txt','manifest.json'};
relative = strrep(char(relative),'\','/');
assert(any(strcmp(relative,allowed)) || ...
    ~isempty(regexp(relative,'^generated/[A-Za-z0-9_][A-Za-z0-9_.-]*\.[ch]$','once')), ...
    'YMBOX:Update:UnmanagedPath','Refusing to change non-generated file: %s',relative);
target = canonical(fullfile(root,relative));
assert(startsWith(target,[canonical(root) filesep],'IgnoreCase',true), ...
    'YMBOX:Update:OutsideTarget','File escapes the selected model directory.');
end

function files = relativeFiles(root)
entries = dir(fullfile(root,'**','*'));
entries = entries(~[entries.isdir]);
files = cell(numel(entries),1);
for k = 1:numel(entries)
    absolute = fullfile(entries(k).folder,entries(k).name);
    files{k} = strrep(absolute(numel(root)+2:end),'\','/');
end
files = sort(files);
end

function settings = modelSettings(model)
names = {'ProdHWDeviceType','TargetHWDeviceType','GenCodeOnly'};
settings = cell(1,2*numel(names));
for k = 1:numel(names)
    settings{2*k-1} = names{k};
    settings{2*k} = get_param(model,names{k});
end
end

function restoreContext(state)
for k = 1:numel(state.models)
    model = state.models{k};
    if ~bdIsLoaded(model), continue; end
    if state.loaded(k)
        set_param(model,state.params{k}{:});
        if k == 2 && ~isempty(state.variant)
            ws = get_param(model,'ModelWorkspace');
            variant = ws.getVariable('KuMDAS_ObserverBuildVariant');
            variant.Value = state.variant;
        end
        set_param(model,'Dirty','off');
    else
        % This project's CloseFcn runs clear all/bdclose all. Do not execute
        % that interactive exit callback when closing a tool-loaded model.
        set_param(model,'CloseFcn','');
        close_system(model,0);
    end
end
if state.hadDocument
    assignin('base','YMBOX_Configuration_UserConfig',state.document);
else
    evalin('base','clear YMBOX_Configuration_UserConfig');
end
Simulink.fileGenControl('setConfig','config',state.fileGen);
cd(state.folder);
path(state.searchPath);
end

function text = cFloat(value)
text = sprintf('%.9g',single(value));
if ~contains(text,{'.','e','E'}), text = [text '.0']; end
text = [text 'F'];
end

function value = canonical(value)
value = char(java.io.File(char(value)).getCanonicalPath());
end

function same = sameFile(a,b)
same = isequal(readBytes(a),readBytes(b));
end

function bytes = readBytes(file)
fid = fopen(file,'rb');
assert(fid >= 0,'YMBOX:Update:ReadFailed','Cannot read %s.',file);
closeFile = onCleanup(@()fclose(fid));
bytes = fread(fid,Inf,'*uint8');
end

function writeText(file,text)
fid = fopen(file,'w','n','UTF-8');
assert(fid >= 0,'YMBOX:Update:WriteFailed','Cannot write %s.',file);
closeFile = onCleanup(@()fclose(fid));
assert(fprintf(fid,'%s',text) >= 0,'YMBOX:Update:WriteFailed','Cannot write %s.',file);
end

function ensureParent(file)
parent = fileparts(file);
if ~isfolder(parent), mkdir(parent); end
end

function removeTemporary(folder,parent)
folder = canonical(folder);
assert(startsWith(folder,[canonical(parent) filesep],'IgnoreCase',true), ...
    'YMBOX:Update:UnsafeCleanup','Refusing cleanup outside the update cache.');
if isfolder(folder), rmdir(folder,'s'); end
end
