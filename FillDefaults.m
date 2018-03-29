function output = FillDefaults(input,defaults)
%FILLDEFAULT Helper function for filling default values
% Fills in any missing parameters with passed in default values
% Inputs:
% input - The input parameter structure, to be filled
% defaults - The default parameter vaules
% Outputs:
% outputs - The filled parameter structure
tmpNames = fieldnames(defaults);
output = input;
for j = 1:numel(tmpNames)
    if ~isfield(input,tmpNames{j})
        output.(tmpNames{j}) = defaults.(tmpNames{j});
    end
end
end

