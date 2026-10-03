disp('Cleaning all Library paths and variables in Workspace.........')
%Cleanup paths added by Library.
if exist('DCL_path', 'var')
    rmpath(DCL_path);
end

%Cleanup paths added by model.
if exist('Library_Paths_Added', 'var')
    Number_Of_Paths_Added = size(Library_Paths_Added);
    for i = 1:1:Number_Of_Paths_Added(1)
        rmpath(Library_Paths_Added{i});
    end

    clear Number_Of_Paths_Added;
    clear Library_Paths_Added;
end

clear all;
bdclose all;

disp('Done.')
