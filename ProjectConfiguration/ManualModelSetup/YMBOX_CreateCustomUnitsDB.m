function YMBOX_CreateCustomUnitsDB(outputFolder)
%YMBOX_CREATECUSTOMUNITSDB Rebuild the YMBOX Simulink custom unit database.
%   YMBOX_CREATECUSTOMUNITSDB() writes YMBOX_CustomUnits.xlsx and the generated
%   YMBOX_CustomUnits.slunitdb.mldatx file to CommonLibrary/Units.
%
%   YMBOX_CREATECUSTOMUNITSDB(OUTPUTFOLDER) writes both files to OUTPUTFOLDER.

if nargin == 0
    modelRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    outputFolder = fullfile(modelRoot, 'CommonLibrary', 'Units');
end

if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

unitName = [
    "motorctrl_null_upper"
    "motorctrl_null_lower"
    "motorctrl_count"
    "motorctrl_enum"
    "motorctrl_flag"
    "motorctrl_radians_per_second"
    "motorctrl_ampere_per_volt"
    "motorctrl_ampere_per_second"
    "motorctrl_volt_per_ampere"
    ];
symbol = ["NULL"; "null"; "cnt"; "enum"; "flg"; "rads"; ...
    "AperV"; "Aps"; "VperA"];
asciiSymbol = symbol;
displayName = symbol;
definitionExpression = ["1"; "1"; "1"; "1"; "1"; "rad/s"; ...
    "A/V"; "A/s"; "V/A"];
conversionFactor = ones(size(unitName));
conversionOffset = zeros(size(unitName));
physicalQuantity = [
    "dimensionless"
    "dimensionless"
    "dimensionless"
    "dimensionless"
    "dimensionless"
    "angular_velocity"
    "electric_conductance"
    "electric_current_rate"
    "electric_resistance"
    ];

unitAliases = table(unitName, symbol, asciiSymbol, displayName, ...
    definitionExpression, conversionFactor, conversionOffset, ...
    physicalQuantity, 'VariableNames', {'name', 'symbol', 'asciiSymbol', ...
    'displayName', 'definitionExpression', 'conversionFactor', ...
    'conversionOffset', 'physicalQuantity'});

quantityName = "electric_current_rate";
quantityDefinition = "electric_current/time";
customQuantities = table(quantityName, quantityDefinition, ...
    'VariableNames', {'name', 'definitionExpression'});

spreadsheetFile = fullfile(outputFolder, 'YMBOX_CustomUnits.xlsx');
originalFolder = pwd;
folderCleanup = onCleanup(@() cd(originalFolder));
cd(outputFolder);

writetable(unitAliases, spreadsheetFile, 'Sheet', 'unitAliases');
writetable(customQuantities, spreadsheetFile, 'Sheet', 'physicalQuantity');
createCustomDBFromExcel(spreadsheetFile);

fprintf('Created %s\n', fullfile(outputFolder, ...
    'YMBOX_CustomUnits.slunitdb.mldatx'));
end
