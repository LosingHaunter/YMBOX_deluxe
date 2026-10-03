%Setup Paths.
disp('Loading all Library paths.........')
%Add paths for Library in order to call startup m_files to initialize the Library.
% Resolve from this permanent bootstrap entry instead of the caller's
% current folder. This keeps model PreLoadFcn behavior deterministic when a
% model is opened by absolute path or from another MATLAB working folder.
YMBOX_RootDir = fileparts(mfilename('fullpath'));

% Keep generated files outside the source tree; preserve explicit overrides.
[YMBOX_ParentDir, YMBOX_ModelFolder] = fileparts(YMBOX_RootDir);
YMBOX_OutputRoot = fullfile(YMBOX_ParentDir, [YMBOX_ModelFolder '_outputs']);
% Redirect the former active folder's default generated-file location after
% the project rename. Other user-selected locations remain untouched.
YMBOX_LegacyOutputRoot = fullfile(YMBOX_ParentDir, 'matlab_model_4k_outputs');
YMBOX_FileGenConfig = Simulink.fileGenControl('getConfig');
YMBOX_FileGenOptions = {};
if isempty(YMBOX_FileGenConfig.CacheFolder) || ...
        strcmpi(YMBOX_FileGenConfig.CacheFolder, YMBOX_RootDir) || ...
        strcmpi(YMBOX_FileGenConfig.CacheFolder, fullfile(YMBOX_RootDir, 'build', 'cache')) || ...
        strcmpi(YMBOX_FileGenConfig.CacheFolder, fullfile(YMBOX_LegacyOutputRoot, 'cache'))
    YMBOX_FileGenOptions = [YMBOX_FileGenOptions, ...
        {'CacheFolder', fullfile(YMBOX_OutputRoot, 'cache')}];
end
if isempty(YMBOX_FileGenConfig.CodeGenFolder) || ...
        strcmpi(YMBOX_FileGenConfig.CodeGenFolder, YMBOX_RootDir) || ...
        strcmpi(YMBOX_FileGenConfig.CodeGenFolder, fullfile(YMBOX_RootDir, 'build', 'codegen')) || ...
        strcmpi(YMBOX_FileGenConfig.CodeGenFolder, fullfile(YMBOX_LegacyOutputRoot, 'codegen'))
    YMBOX_FileGenOptions = [YMBOX_FileGenOptions, ...
        {'CodeGenFolder', fullfile(YMBOX_OutputRoot, 'codegen')}];
end
if ~isempty(YMBOX_FileGenOptions)
    Simulink.fileGenControl('set', YMBOX_FileGenOptions{:}, 'createDir', true);
end
clear YMBOX_FileGenConfig YMBOX_FileGenOptions YMBOX_ParentDir YMBOX_ModelFolder ...
    YMBOX_OutputRoot YMBOX_LegacyOutputRoot;
YMBOX_LibraryPaths = {
    YMBOX_RootDir
    fullfile(YMBOX_RootDir, 'ProjectConfiguration', 'ManualModelSetup')
    fullfile(YMBOX_RootDir, 'ProjectConfiguration', 'ApplicationParameters')
    fullfile(YMBOX_RootDir, 'ProjectConfiguration', 'Runtime')
    fullfile(YMBOX_RootDir, 'CommonLibrary', 'Units')
    fullfile(YMBOX_RootDir, 'CoreLibrary', 'MDCC_Model_Lib')
    fullfile(YMBOX_RootDir, 'CoreLibrary', 'MDSP_Model_Lib')
    fullfile(YMBOX_RootDir, 'CoreLibrary', 'MDFM_Model_Lib')
    fullfile(YMBOX_RootDir, 'CoreLibrary', 'MDSA_Model_Lib')
    fullfile(YMBOX_RootDir, 'CoreLibrary', 'MDAS_Model_Lib')
    fullfile(YMBOX_RootDir, 'CoreLibrary', 'MDSM_Model_Lib')
    fullfile(YMBOX_RootDir, 'CoreLibrary', 'MDTM_Model_Lib')
    fullfile(YMBOX_RootDir, 'CoreLibrary', 'SharedCore_Model_Lib')
    fullfile(YMBOX_RootDir, 'CommonLibrary')
    };

% Add paths without depending on a base-workspace variable named "path".
for YMBOX_PathIndex = 1:numel(YMBOX_LibraryPaths)
    assert(isfolder(YMBOX_LibraryPaths{YMBOX_PathIndex}), ...
        'YMBOX:Initialization:MissingFolder', ...
        'Required YMBOX folder is missing: %s', ...
        YMBOX_LibraryPaths{YMBOX_PathIndex});
    addpath(YMBOX_LibraryPaths{YMBOX_PathIndex}, '-begin');
end

% Register the legacy YMBOX engineering-unit aliases before any parameter,
% signal, or bus object is created.  The database keeps existing data-object
% semantics while allowing Simulink to validate units such as NULL, flg,
% rads, AperV, Aps, and VperA without undefined-unit warnings.
if exist('YMBOX_CustomUnits.slunitdb.mldatx','file') == 2
    rehashUnitDBs;
else
    warning('YMBOX:MissingCustomUnitDatabase', ...
        'YMBOX custom unit database is missing from CommonLibrary\\Units.');
end

% Load the explicit bus objects used at the shared Model Reference boundary.
% Keeping this in the normal project initialization path allows both the
% simulation shell and the code-generation shell to compile the same core.
if exist('YMBOX_Control_Core_BusObjects','file') == 2
    YMBOX_Control_Core_BusObjects;
end

clear YMBOX_RootDir YMBOX_LibraryPaths YMBOX_PathIndex;

% Publish shared constants after all required folders and unit definitions
% are available. Model PreLoadFcn callbacks therefore need only this one
% bootstrap script.
YMBOX_Strategy_GlobalConst;

disp('Done.')
