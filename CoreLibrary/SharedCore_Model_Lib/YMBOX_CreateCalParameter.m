function parameter = YMBOX_CreateCalParameter( ...
    value, dataType, units)
%YMBOX_CREATECALPARAMETER Create a generated-code calibration data object.
%   This helper keeps storage-class metadata consistent for parameters
%   derived from the unified drive profile. The configuration calculator
%   and import validation own ranges; data objects add no numeric limits.

arguments
    value
    dataType (1,:) char
    units (1,:) char = 'NULL'
end

parameter = mpt.Parameter;
parameter.Value = value;
parameter.DataType = dataType;
parameter.StorageClass = 'Const (Custom)';
parameter.RTWInfo.CustomAttributes.HeaderFile = 'evd_cal.h';
parameter.RTWInfo.CustomAttributes.DefinitionFile = 'evd_cal';
parameter.DocUnits = units;
end
