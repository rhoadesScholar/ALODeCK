function states = pedestalPlay(varargin)
    %% settings
    evalin('base', 'beep off');
    beep off
    endConditions = {'env.timeElapsed >= env.timeOut', ...
                    'env.totalCount >= env.maxCount', 'thisState.trial > env.maxTrials'};
    transitionConditions = ...
        {'(thisState.ped1Count(end)/thisState.ped2Count(end))^((-1)^(thisState.trial + env.startPed)) >= env.transRatio && (thisState.ped1Count(end)+thisState.ped2Count(end)) >= env.minCount',...
        '(thisState.ped1Count(end) + thisState.ped2Count(end)) >= env.transCount', ...
        'thisState.thisElapsed(end) >= env.transTime'};
    
    %% initialize
    env = struct('timeElapsed', 0, 'totalCount', 0, 'startPed', 1, 'port', 'COM7', 'readWait', 1, 'minCount', 10);
    for v = 1:2:nargin
        eval(sprintf('env.%s = %s', varargin{v}, varargin{v+1}));
    end
    thisState = struct('trial', 1, 'timeElapsed', 0, 'totalCount', 0, ...
        'thisElapsed', 0, 'event', 'startRun', 'ped1Count', 0, 'ped2Count', 0);
    
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
    fig = figure;
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
               beep on
               thisState.totalCount(end+1) = thisState.totalCount(end) + 1;
               env.totalCount = env.totalCount + 1;
               if contains(outString, 'ped1')
                   thisState.ped1Count(end+1) = thisState.ped1Count(end) + 1;
                   thisState.ped2Count(end+1) = thisState.ped2Count(end);
                   if mod(thisState.trial + env.startPed, 2) == 0
                       beep
                   end
               elseif contains(outString, 'ped2')
                   thisState.ped2Count(end+1) = thisState.ped2Count(end) + 1;
                   thisState.ped1Count(end+1) = thisState.ped1Count(end);
                   if mod(thisState.trial + env.startPed, 2) ~= 0
                       beep
                   end
               end               
           else
               thisState.totalCount(end+1) = thisState.totalCount(end);
               thisState.ped1Count(end+1) = thisState.ped1Count(end);
               thisState.ped2Count(end+1) = thisState.ped2Count(end);
           end
           beep off
           env.timeElapsed = toc(allT);
           try
               thisState.event{end+1} = strip(outString);
           catch
               thisState.event = {thisState.event, strip(outString)};
           end
           thisState.timeElapsed(end+1) = toc(allT);
           thisState.thisElapsed(end+1) = toc(trialT);           
       end
       if ~exist('states', 'var')
           states = thisState;
       else
           states = [states thisState];
       end
       oldState = thisState;
       thisState = struct('trial', oldState.trial+1, 'timeElapsed', toc(allT), ...
           'totalCount', oldState.totalCount, 'thisElapsed', 0, 'event', 'startTrial', ...
           'ped1Count', 0, 'ped2Count', 0);
       clear oldState;
    end
    
    fclose(instrfind);
    delete(instrfind);
end

function isEnd = isEnd(thisState, endConditions, env)
    isEnd = false;    
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