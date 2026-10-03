function schema = YMBOX_Configuration_ExportSchema(outputDirectory)
%YMBOX_Configuration_ExportSchema - Export the complete model parameter form
%   SCHEMA = YMBOX_Configuration_ExportSchema(outputDirectory) writes the
%   JSON and browser catalog from the current typed MATLAB defaults.
%
%   See Also YMBOX_Drive_Parameters, YMBOX_Configuration_Decode

root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
if nargin == 0
    outputDirectory = fullfile(root, 'Tools', 'Calculator');
end
schema.schemaVersion = 1;
schema.model = 'YMBOX_Control_Core';
template = YMBOX_Drive_Parameters();
schema.defaults = YMBOX_Configuration_ResolveAuto(template);
schema.fields = flatten(template, '');
for index = 1:numel(schema.fields)
    parts = strsplit(schema.fields(index).path, '.');
    schema.fields(index).defaultValue = schema.defaults.(parts{1}).(parts{2});
end
schema.fieldCount = numel(schema.fields);
schema.retiredFields = YMBOX_Drive_RetiredFields();
schema.source = 'ProjectConfiguration/ApplicationParameters/YMBOX_Drive_Parameters.m';
schema.generatedAt = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
text = jsonencode(schema, 'PrettyPrint', true);
writeText(fullfile(outputDirectory, 'ymbox-config-schema.json'), text);
writeText(fullfile(outputDirectory, 'ymbox-config-schema.js'), ...
    ['window.YMBOXSchema = ' text ';' newline]);
fprintf('YMBOX_CONFIG_SCHEMA fields=%d\n', schema.fieldCount);
end

function result = flatten(value, prefix)
result = struct('path', {}, 'defaultValue', {}, 'type', {}, ...
    'shape', {}, 'allowsAuto', {}, 'canResolveAuto', {}, ...
    'autoResolvedDefault', {}, 'readOnly', {});
names = fieldnames(value);
fixed = {'Meta.ControlAngleConvention', ...
    'Timing.BaseTick_s', 'Timing.MinimumControlFrequency_Hz', ...
    'Timing.MaximumControlFrequency_Hz', ...
    'Timing.ExactMatchTolerance_ppm', ...
    'CurrentReference.AllocationModes_enum', ...
    'Features.SensorlessFieldWeakeningEnable', 'FieldWeakening.SensorlessEnable'};
for index = 1:numel(names)
    key = names{index};
    name = [prefix key];
    leaf = value.(key);
    if isstruct(leaf)
        entries = flatten(leaf, [name '.']);
    else
        entries = struct('path', name, 'defaultValue', leaf, ...
            'type', class(leaf), 'shape', size(leaf), ...
            'allowsAuto', false, ...
            'canResolveAuto', isnumeric(leaf) && isscalar(leaf) && ...
            (isnan(double(leaf)) || contains(key, 'Override') || strcmp(key, 'EffectiveInductance_H')), ...
            'autoResolvedDefault', isnumeric(leaf) && isscalar(leaf) && isnan(double(leaf)), ...
            'readOnly', ismember(name, fixed));
    end
    result = [result entries]; %#ok<AGROW>
end
end

function writeText(filename, text)
fid = fopen(filename, 'w', 'n', 'UTF-8');
assert(fid ~= -1, 'YMBOX:Configuration:WriteFailed', 'Cannot write %s.', filename);
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '%s', text);
end
