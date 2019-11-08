function dataFile = pedestalLongRun(experimentEndConditions, experimentSettings, runSettings)
    % Possible experimentEndCondition(s):
    % 'toc(experimentT) >= totalT': totalT is in seconds
    % 'runNum >= maxRuns': where maxRuns = # of runs to do before stopping
    
    % Possible experimentSetting(s):
    % 'interRunPause = *seconds*'
    % 'runSubsequentNum = *# of runs to do before pause*'
    % 'subsequentRunPause = *seconds*'
    % 'runSchedule = [HHMMSS(s) of times to start runs]'
    % 'preRunBeep = *boolean*'
    % 'postRunBeep = *boolean*'
    
    %% settings
    if ~exist('experimentEndConditions', 'var') || isempty(experimentEndConditions)
        experimentEndConditions = {'toc(experimentT) >= 30*24*60*60'};%Default is to run for 30 days
    end
    if ~exist('experimentSettings', 'var') || isempty(experimentSettings)
        experimentSettings = {'preRunBeep = false;'};
    end
    
    if any(contains(runSettings, 'startPed')) && ...
            contains(runSettings(find(contains(runSettings, 'startPed'))+1), 'random')
        startPeds = mod(randperm(999999),2)+1;
    end
	theseRunSettings = runSettings;
        
    %% initialize
    beep on
    cellfun(@(x) evalin('caller', x), experimentSettings);
    destPath = uigetdir('', 'Choose the destination folder for your data.');
    runName = inputdlg('Enter run specifiers separated by commas (ex: mouseName, probabilityTest):');
    fileName = genvarname([datestr(date,'yyyymmdd') '_' replace(strip(runName{:}),',', '_')]);
    dataFile = matfile([destPath filesep fileName '.mat'],'Writable',true);
    mkdir([destPath filesep fileName '_figs'])
    
    %% start experiment
    experimentT = tic;
    runNum = 1;
    while ~any(cellfun(@(x) evalin('caller', x), experimentEndConditions))
       if exist('runSchedule', 'var')
           nextRun = runSchedule(mod(runNum-1, length(runSchedule)) + 1);
           while abs(nextRun - str2double(datestr(datetime, 'HHMMSS'))) > 10
               pause(30)
           end
       end
       if any(contains(runSettings, 'startPed')) && ...
            contains(runSettings(find(contains(runSettings, 'startPed'))+1), 'random')
            try
                startPed = startPeds(runNum);
            catch
                startPed = randi(2);
            end
            theseRunSettings{find(contains(theseRunSettings, 'startPed'))+1} = num2str(startPed);
       end
       %do run
       if exist('preRunBeep', 'var') && preRunBeep
           beep
       end
       [env, fig] = pedestalPlay(theseRunSettings{:});
       
       %prepare for next run (i.e. save, etc.)
       tic
       if exist('postRunBeep', 'var') && postRunBeep
           beep
       end
       runName = ['run' num2str(runNum) '_' datestr(datetime, 'yyyymmdd_HHMM')];
       dataFile.(runName) = env;
       savefig(fig, [destPath filesep fileName '_figs' filesep runName]);
       pause(interRunPause - toc)
       runNum = runNum + 1;
       if exist('runSubsequentNum', 'var') && mod(runNum, runSubsequentNum) == 0
           pause(subsequentRunPause - toc)
       end
    end
end