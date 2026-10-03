function table = YMBOX_MathCodeReplacement
%YMBOX_MATHCODEREPLACEMENT Map scalar single math to board-selected services.
%   Covers accelerated math inside MATLAB Function blocks and generated code.
%   Mod and floor retain native MATLAB/Simulink code-generation behavior.
%   Divide blocks and / expressions stay unchanged in the source model.
%   The division macro expands inline; it is not an external library call.
table = RTW.TflTable;
addFunction(table,'sqrt','YMBOX_Sqrt_f32','ymbox_sqrt_f32.h',1,'Sqrt');
addFunction(table,'hypot','YMBOX_Hypot_f32','ymbox_scalar_math_f32.h',2,'SharedMath');
entry = RTW.TflCOperationEntry;
entry.setTflCOperationEntryParameters('Key','RTW_OP_DIV', ...
    'Priority',100,'ImplementationName','YMBOX_DIV_F32', ...
    'ImplementationHeaderFile','ymbox_tmu_div_inline.h', ...
    'ImplementationHeaderPath',platformFolder('SharedMath'), ...
    'ImplType','FCN_IMPL_MACRO','SideEffects',false);
addArguments(entry,2);
table.addEntry(entry);
end

function addFunction(table,key,name,header,nInputs,folder)
entry = RTW.TflCFunctionEntry;
entry.setTflCFunctionEntryParameters('Key',key,'Priority',100, ...
    'ImplementationName',name,'ImplementationHeaderFile',header, ...
    'ImplementationHeaderPath',platformFolder(folder),'SideEffects',false);
addArguments(entry,nInputs);
table.addEntry(entry);
end

function addArguments(entry,nInputs)
arg = entry.getTflArgFromString('y1','single');
arg.IOType = 'RTW_IO_OUTPUT';
entry.addConceptualArg(arg);
for k = 1:nInputs
    entry.addConceptualArg(entry.getTflArgFromString(sprintf('u%d',k),'single'));
end
entry.copyConceptualArgsToImplementation();
end

function folder = platformFolder(service)
modelRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
folder = fullfile(modelRoot,'Platform',service);
end
