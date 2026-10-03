function folder = YMBOX_OutputDirectory(varargin)
% Return an output directory beside the model source folder.
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
[parent, name] = fileparts(root);
folder = fullfile(parent, [name '_outputs'], varargin{:});
if ~isfolder(folder), mkdir(folder); end
end
