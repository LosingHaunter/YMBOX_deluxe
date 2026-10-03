function [document, file] = YMBOX_Configuration_ReadActive()
%YMBOX_Configuration_ReadActive - Read the calculator parameter file
%   [DOCUMENT, FILE] = YMBOX_Configuration_ReadActive() reads the saved JSON
%   file. Missing configuration is an error; generate it in the calculator.
%
%   See also YMBOX_Configuration_ReadFile, YMBOX_InitializeModel

root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
file = fullfile(root, 'ProjectConfiguration', 'ApplicationParameters', ...
    'YMBOX_ActiveConfiguration.json');
assert(isfile(file), 'YMBOX:Configuration:MissingFile', ...
    'Calculator configuration is missing. Use the calculator to write %s.', file);
document = YMBOX_Configuration_ReadFile(file);
end
