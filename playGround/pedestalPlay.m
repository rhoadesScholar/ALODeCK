function states = pedestalPlay(varargin)
    endConditions = {'thisState.timeElapsed(end) >= timeOut', ...
                    'thisState.totalCount(end) >= maxCount', 'thisState.trial > maxTrials'};
    transitionConditions = {'(thisState.ped1Count(end)/thisState.ped2Count(end))^((-1)^thisState.trial) >= transRatio',...
        '(thisState.ped1Count(end) + thisState.ped2Count(end)) >= transCount', 'thisState.thisElapsed(end) >= transTime'};
    
    %initialize
    thisState = struct('trial', 1, 'timeElapsed', 0, 'totalCount', 0, ...
        'thisElapsed', 0, 'event', 'startRun', 'ped1Count', 0, 'ped2Count', 0);
    for v = 1:2:nargin
        eval(sprintf('%s = %s', varargin{v}, varargin{v+1}));
    end
    states = struct();
    
    %start run
    allT = tic;
    while ~isEnd(thisState, endConditions)
       %start trial
       trialT = tic;
       while ~isTrans(thisState, transitionConditions) && ~isEnd(thisState, endConditions)
           thisT = tic;
           outString = '';
           while isempty(outString) && toc(thisT) <= 1%EDIT AMBIENT RECORD RATE HERE
                outString = ######
           end
           if ~isempty(outString)
               thisState.event(end+1) = outString;
               
               if contains(outString, 'on')
                   thisState.totalCount(end+1) = thisState.totalCount(end) + 1;
                   if contains(outString, 'ped1')
                       thisState.ped1Count(end+1) = thisState.ped1Count(end) + 1;
                   elseif contains(outString, 'ped2')
                       thisState.ped2Count(end+1) = thisState.ped2Count(end) + 1;
                   end
               end

           end
           thisState.timeElapsed(end+1) = toc(allT);
           thisState.thisElapsed(end+1) = toc(trialT);
       end
       states = [states thisState];
       oldState = thisState;
       thisState = struct('trial', oldState.trial+1, 'timeElapsed', toc(allT), ...
           'totalCount', oldState.totalCount, 'thisElapsed', 0, 'event', 'startTrial', ...
           'ped1Count', 0, 'ped2Count', 0);
       clear oldState;
    end
end

function isEnd = isEnd(thisState, endConditions)
    isEnd = false;    
    for e = 1:length(endConditions)
        eval(sprintf('isEnd = isEnd || (%s);', endConditions{e}));
    end
    return
end

function isTrans = isTrans(thisState, transitionConditions)
    isTrans = false;    
    for c = 1:length(endConditions)
        eval(sprintf('isTrans = isTrans || (%s);', transitionConditions{c}));
    end
    return
end