deleteFields = {'port', 'ended', 'PrefPlot', 'thisPedBar', 'thisPrefPlot', 'controller'};

clear runs runLabels data
vars = whos;
runs = {vars(contains({vars(:).name}, 'run')).name};
runLabels = squeeze(split(runs,'_'));
dateString = strcat(runLabels(:,2), runLabels(:,3));
dateString = cellfun(@(c) str2double(c), dateString);
[~, I] = sort(dateString);  %sort by datetime
runs = runs(I);
runLabels = squeeze(split(runs,'_'));

k = 0;
for i = 1:numel(runs)
    theseRuns = eval(runs{i});
    for j = 1:numel(theseRuns)
        k = k + 1;
        thisRun = theseRuns(j);
        try
            data(k) = thisRun;
        catch
            oldFields = fieldnames(data(1));
            newFields = fieldnames(thisRun);
            thisRun = rmfield(thisRun, setdiff(newFields,oldFields));
            data(k) = thisRun;
        end
    end
end

data = rmfield(data, deleteFields);
