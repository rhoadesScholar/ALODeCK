function dataFile = pedestalLongRun(experimentEndConditions, experimentSettings, runSettings)
    % Possible experimentEndCondition(s):
    % 'toc(runT) >= totalT': totalT is in seconds
    % 'runNum >= maxRuns': where maxRuns = # of runs to do before stopping
    
    % Possible experimentSetting(s):
    % 'interRunPause = *seconds*'
    % 'runSubsequentNum = *# of runs to do before pause*'
    % 'subsequentRunPause = *seconds*'
    % 'runSchedule = [HHMMSS(s) of times to start runs]'
    % 'preRunBeep = *boolean*'
    
    %% settings
    evalin('base', 'beep off');
    beep off
    if ~exist('experimentEndConditions', 'var') || isempty(experimentEndConditions)
        experimentEndConditions = {'toc(runT) >= 30*24*60*60'};
    end
    if ~exist('experimentSettings', 'var') || isempty(experimentSettings)
        experimentSettings = {'preRunBeep = false;'};
    end
    
    %% initialize
    cellfun(@(x) evalin('caller', x), experimentSettings);
    destPath = uigetdir('', 'Choose the destination folder for your data.');
    runName = inputdlg('Enter run specifiers separated by commas (ex: mouseName, probabilityTest):');
    fileName = genvarname([datestr(date,'yyyymmdd') '_' replace(strip(runName{:}),',', '_')]);
    dataFile = matfile([destPath filesep fileName '.mat'],'Writable',true);
    
    %% start experiment
    runT = tic;
    runNum = 1;
    while ~any(cellfun(@(x) eval(x), experimentEndConditions))
       if exist('runSchedule', 'var')
           nextRun = runSchedule(mod(runNum-1, length(runSchedule)) + 1);
           while abs(nextRun - str2double(datestr(datetime, 'HHMMSS'))) > 10
               pause(30)
           end
       end
       
       %do run
       if exist('preRunBeep', 'var') && preRunBeep
           beep
       end
       [env, fig] = pedestalPlay(runSettings{:});
       
       %prepare for next run (i.e. save, etc.)
       tic
       runName = ['run' num2str(runNum) '_' datestr(datetime, 'yyyymmdd_HHMM')];
       dataFile.(runName) = env;
       savefig(fig, runName);
       pause(interRunPause - toc)
       runNum = runNum + 1;
       if exist('runSubsequentNum', 'var') && mod(runNum, runSubsequentNum) == 0
           pause(subsequentRunPause - toc)
       end
    end
end