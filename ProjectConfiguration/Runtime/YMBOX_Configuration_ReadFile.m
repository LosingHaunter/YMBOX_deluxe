function document = YMBOX_Configuration_ReadFile(file)
%YMBOX_Configuration_ReadFile - Read a JSON configuration document
%   DOCUMENT = YMBOX_Configuration_ReadFile(FILE) reads JSON without
%   executing code or updating any model. Other file types are rejected.
%
%   See also YMBOX_Configuration_Decode, YMBOX_Configuration_ReadActive

[~, ~, extension] = fileparts(file);
assert(strcmpi(extension, '.json'), 'YMBOX:Configuration:FileType', ...
    'Use a JSON configuration file.');
document = jsondecode(fileread(file));
end
