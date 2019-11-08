function [env, fig] = pedestalPlay(varargin)
    %% settings
    endConditions = {'env.timeElapsed >= env.timeOut', ...
                    'env.totalCount >= env.maxCount', 'thisState.trial > env.maxTrials'};
    transitionConditions = ...
        {'(thisState.ped1Count(end)/thisState.ped2Count(end))^((-1)^(thisState.trial + env.startPed)) >= env.transRatio && (thisState.ped1Count(end)+thisState.ped2Count(end)) >= env.minCount',...
        '(thisState.ped1Count(end) + thisState.ped2Count(end)) >= env.transCount', ...
        'thisState.thisElapsed(end) >= env.transTime'};
    
    %% initialize
    env = struct('timeElapsed', 0, 'totalCount', 0, 'startPed', 1, ...
        'port', 'COM7', 'readWait', 1, 'minCount', 30, 'ended', false);
    for v = 1:2:nargin
        eval(sprintf('env.%s = %s', varargin{v}, varargin{v+1}));
    end
    thisState = struct('startTime', datestr(datetime, 'yyyymmdd_HHMMSSFFF'), 'trial', 1, 'timeElapsed', 0, 'totalCount', 0, ...
        'thisElapsed', 0, 'event', 'startRun', 'ped1Count', 0, 'ped2Count', 0);
    env = makePlot(thisState, env);
    
    try
        env.controller = serial(env.port);
        fopen(env.controller);
    catch
        fclose(instrfind);
        delete(instrfind);
        env.controller = serial(env.port);
        fopen(env.controller);
    end
    env.controller.ReadAsyncMode = 'continuous';
    env.controller.Timeout = env.readWait;
    
    %% start run
    allT = tic;
    while ~isEnd(thisState, endConditions, env)
       %start trial
       trialT = tic;
       while ~isTrans(thisState, transitionConditions, env) && ~isEnd(thisState, endConditions, env)
           thisT = tic;
           outString = '';
           while isempty(outString) && (toc(thisT) <= env.readWait)
                outString = fgetl(env.controller)%get input
           end
           if ~isempty(outString) && contains(outString, 'on')
               thisState.totalCount(end+1) = thisState.totalCount(end) + 1;
               env.totalCount = env.totalCount + 1;
               if contains(outString, 'ped1')
                   thisState.ped1Count(end+1) = thisState.ped1Count(end) + 1;
                   thisState.ped2Count(end+1) = thisState.ped2Count(end);
                   if mod(thisState.trial + env.startPed, 2) == 0
                       beep
                       env.PrefPlot.UserData(1) = env.PrefPlot.UserData(1) + 1;
                   else
                       env.PrefPlot.UserData(2) = env.PrefPlot.UserData(2) + 1;
                   end
               elseif contains(outString, 'ped2')
                   thisState.ped2Count(end+1) = thisState.ped2Count(end) + 1;
                   thisState.ped1Count(end+1) = thisState.ped1Count(end);
                   if mod(thisState.trial + env.startPed, 2) ~= 0
                       beep
                       env.PrefPlot.UserData(1) = env.PrefPlot.UserData(1) + 1;
                   else
                       env.PrefPlot.UserData(2) = env.PrefPlot.UserData(2) + 1;
                   end
               end               
           else
               thisState.totalCount(end+1) = thisState.totalCount(end);
               thisState.ped1Count(end+1) = thisState.ped1Count(end);
               thisState.ped2Count(end+1) = thisState.ped2Count(end);
           end
           env.timeElapsed = toc(allT);
           thisState.timeElapsed(end+1) = toc(allT);
           thisState.thisElapsed(end+1) = toc(trialT);     
           try
               thisState.event{end+1} = strip(outString);
           catch
               thisState.event = {thisState.event, strip(outString)};
           end
           env = updatePlot(thisState, env);
%             refreshdata
       end
       if ~exist('states', 'var')
           env.states = thisState;
       else
           env.states = [env.states thisState];
       end
       oldState = thisState;
       thisState = struct('startTime', datestr(datetime, 'yyyymmdd_HHMMSSFFF'), 'trial', oldState.trial+1, 'timeElapsed', toc(allT), ...
           'totalCount', oldState.totalCount, 'thisElapsed', 0, 'event', 'startTrial', ...
           'ped1Count', 0, 'ped2Count', 0);
       clear oldState;
    end
    fig = env.fig;
    env = rmfield(env, 'fig');
    fclose(instrfind);
    delete(instrfind);
end

function env = makePlot(thisState, env)
    env.fig = figure('WindowState', 'maximized', 'Color', 'none', 'MenuBar', 'none');
    env.PrefAx = subplot(2,2,1:2);
    env.PrefPlot = plot(0, 0, 'LineWidth', 3, 'Marker','x', 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r');
    env.PrefPlot.UserData = [0 0];
    xlabel('Time (s)')
    ylabel('Preference Ratio (TrCount/Total)')
    set(gca, 'Color', [.01 .01 .01]);
    set(gca, 'XColor', 'w');
    set(gca, 'YColor', 'w');
    set(gca, 'GridColor', 'w');
    ylim([-1 1]);
    grid on
    
    env.PedBarAx = subplot(2,2,3);
    env.thisPedBar = bar([0 0; 0 0]);
    xticklabels({['trig=' num2str(env.startPed)], ['trig=' num2str(mod(env.startPed,2)+1)]});
    xlabel('(sequential trials)')
    ylabel('Event Count')
    legend({'Pedestal 1', 'Pedestal 2'})
    set(gca, 'Color', [.01 .01 .01]);
    set(gca, 'XColor', 'w');
    set(gca, 'YColor', 'w');
    set(gca, 'GridColor', 'w');
    grid on
    
    env.thisPrefAx = subplot(2,2,4);
    env.thisPrefPlot = plot(0, 0, 'LineWidth', 1.5, 'Marker','x', 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r');
    env.thisPrefPlot.UserData = 1;
    xlabel('Time (s)')
    ylabel('Preference Diff.')
    set(gca, 'Color', [.01 .01 .01]);
    set(gca, 'XColor', 'w');
    set(gca, 'YColor', 'w');
    set(gca, 'GridColor', 'w');
    grid on
    hold on
    
    drawnow
    return
end

function env = updatePlot(thisState, env)
    try
        env.PrefPlot.XData(end+1) = env.timeElapsed;
        env.PrefPlot.YData(length(env.PrefPlot.XData)) = nansum([2*(env.PrefPlot.UserData(1)/nansum(env.PrefPlot.UserData)) - 1, 0]);
        if length(env.PrefPlot.MarkerIndices) > thisState.trial
           env.PrefPlot.MarkerIndices = [env.PrefPlot.MarkerIndices(1:thisState.trial-1), length(env.PrefPlot.XData)];
        end
        env.PrefPlot.MarkerIndices(thisState.trial) = length(env.PrefPlot.XData);
        if  contains(thisState.event{end}, 'on')
            env.PrefPlot.Color = 'g';
        elseif contains(thisState.event{end}, 'off')
            env.PrefPlot.Color = 'b';
        end
        subplot(2,2,1:2)
        if length(env.PrefPlot.XData) > 1800
            xlim([(env.PrefPlot.XData(end)-1800) (env.PrefPlot.XData(end)+30)]);
%             ylim([min(env.PrefPlot.YData(end-1800:end)) max(env.PrefPlot.YData(end-1800:end))]);
        end
        
        env.thisPedBar(1).YData(thisState.trial) = max(thisState.ped1Count(:));
        env.thisPedBar(2).YData(thisState.trial) = max(thisState.ped2Count(:));
        
        if env.thisPrefPlot.UserData ~= thisState.trial
            env.thisPrefPlot.MarkerIndices = [];
            subplot(2,2,4)
            env.thisPrefPlot = plot(0,'LineWidth', 1.5, 'Marker','x', 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r');
            env.thisPrefPlot.UserData = thisState.trial;
            xlabel('Time (s)')
            ylabel('Preference Diff.')
            hold on
        else
            countInds = [(1+mod(thisState.trial + env.startPed, 2)), (1+mod(thisState.trial + env.startPed+1, 2))];
            counts = [thisState.ped1Count(end) thisState.ped2Count(end)];
            env.thisPrefPlot.XData(end+1) = thisState.thisElapsed(end);
            env.thisPrefPlot.YData(length(env.thisPrefPlot.XData)) = counts(countInds(1)) - counts(countInds(2));
            env.thisPrefPlot.MarkerIndices = length(env.thisPrefPlot.XData);
            env.thisPrefAx.YLim = [-max(abs(env.thisPrefAx.YLim)) max(abs(env.thisPrefAx.YLim))];
        end
        drawnow
    catch
        if ~isvalid(env.fig)
            env.ended = true;
        end
    end
    return
end

function isEnd = isEnd(thisState, endConditions, env)
    isEnd = false || env.ended;    
    for e = 1:length(endConditions)
        try
            eval(sprintf('isEnd = isEnd || (%s);', endConditions{e}));
        catch
%             disp(endConditions{e})
        end
    end
    return
end

function isTrans = isTrans(thisState, transitionConditions, env)
    isTrans = false;    
    for c = 1:length(transitionConditions)
        try
            eval(sprintf('isTrans = isTrans || (%s);', transitionConditions{c}));
        catch
%             disp(transitionConditions{c});
        end
    end
    return
end