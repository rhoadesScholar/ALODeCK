function code = TargetChaseJeff
% allThreeEnvironmentsTargetChase   Code for the ViRMEn experiment allThreeEnvironmentsTargetChase.
%   code = allThreeEnvironmentsTargetChase   Returns handles to the functions that ViRMEn
%   executes during engine initialization, runtime and termination.


% Begin header code - DO NOT EDIT
code.initialization = @initializationCodeFun;
code.runtime = @runtimeCodeFun;
code.termination = @terminationCodeFun;
% End header code - DO NOT EDIT



% --- INITIALIZATION code: executes before the ViRMEn engine starts.
function vr = initializationCodeFun(vr)


vr.minDistance = eval(vr.exper.variables.minDistance);
vr.minDistanceInside = eval(vr.exper.variables.minDistanceInside);
vr.minStartDistanceInside = eval(vr.exper.variables.minStartDistanceInside);
vr.minStartDistance = eval(vr.exper.variables.minStartDistance);
vr.maxStartDistance = 80;
vr.maxTargetRadiusShift = [0.5 0.5];
vr.minTargetRadius = eval(vr.exper.variables.minTargetRadius);

vr.radiusPower = 1.35;
vr.randomRadiusExponent = eval(vr.exper.variables.randomRadiusExponent);
vr.minTriggerRadius = eval(vr.exper.variables.minTriggerRadius);
vr.floorWidth = eval(vr.exper.variables.floorWidth);
vr.startingOrientation = eval(vr.exper.variables.startingOrientation);
vr.rewardProbability = eval(vr.exper.variables.rewardProbability);
vr.cylinderRadius = 5;
vr.freeRewards = 20;
vr.debugMode = eval(vr.exper.variables.debugMode);

vr.currentWorld = eval(vr.exper.variables.startWorld);

if ~vr.debugMode
    [vr.rewardSound, vr.rewardFs] = wavread('ding.wav');
end

if ~vr.debugMode
    % Start the DAQ acquisition
    daqreset; %reset DAQ in case it's still in use by a previous Matlab program
    vr.ai = analoginput('nidaq','dev1'); % connect to the DAQ card
    addchannel(vr.ai,0:1); % start channels 0 and 1
    set(vr.ai,'samplerate',1000,'samplespertrigger',inf);
    set(vr.ai,'bufferingconfig',[8 100]);
    set(vr.ai,'loggingmode','Disk');
    vr.tempfile = [tempname '.log'];
    set(vr.ai,'logfilename',vr.tempfile);
    set(vr.ai,'DataMissedFcn',@datamissed);
    start(vr.ai); % start acquisition
    
    vr.ao = analogoutput('nidaq','dev1');
    addchannel(vr.ao,0);
    set(vr.ao,'samplerate',10000);
    
    vr.finalPathname = 'C:\Users\Assad\Desktop\virmenLogs';
    vr.pathname = 'C:\Users\Assad\Desktop\testlogs';
    vr.filename = datestr(now,'yyyymmddTHHMMSS');
    exper = vr.exper; %#ok<NASGU>
    save([vr.pathname '\' vr.filename '.mat'],'exper');
    vr.fid = fopen([vr.pathname '\' vr.filename '.dat'],'w');
    vr.isStarting = true;
    
    vr.dio = digitalio('nidaq','dev1');
    addline(vr.dio,0:7,'out');
    start(vr.dio);
end

% Set up text boxes
vr.text(1).string = '0';
vr.text(1).position = [-.14 .1];
vr.text(1).size = .03;
vr.text(1).color = [1 0 1];

vr.text(2).string = '0';
vr.text(2).position = [-.14 0];
vr.text(2).size = .03;
vr.text(2).color = [1 1 0];

vr.text(3).string = '0';
vr.text(3).position = [-.14 -.1];
vr.text(3).size = .03;
vr.text(3).color = [0 1 1];


% Set up plots
vr.plotSize = 0.15;
vr.plot(1).x = [-1 1 1 -1 -1 NaN -1/2 1/2 1/2 -1/2 -1/2];
vr.plot(1).y = [-1 -1 1 1 -1 NaN -1/2 -1/2 1/2 1/2 -1/2];
scr = get(0,'screensize');
aspectRatio = scr(3)/scr(4)*.8;
vr.plotX = (aspectRatio+1)/2;
vr.plotY = 0.75;
vr.plot(1).x = vr.plot(1).x*vr.plotSize+vr.plotX;
vr.plot(1).y = vr.plot(1).y*vr.plotSize+vr.plotY;
vr.plot(1).color = [1 1 0];

num = 30;
vr.bins = linspace(-pi,pi,num+1);
vr.angleCounts = zeros(1,length(vr.bins)-1);


% Store cylinder triangulation coordinates
lst = vr.worlds{vr.currentWorld}.objects.vertices(vr.worlds{vr.currentWorld}.objects.indices.targetCylinder,:);
vr.cylinderTriangulation = vr.worlds{vr.currentWorld}.surface.vertices(1:2,lst(1):lst(2));

% Target initial position
ang = rand*2*pi;
r = vr.floorWidth/4;
vr.targetPosition = [r*cos(ang) r*sin(ang)];

% Initialize runtime variables
vr.numRewards = 0;
vr.numDeliver = 0;
vr.startTime = now;
vr.scaling = [13 13];

% Initialize position
r = vr.floorWidth/4;
th = rand*2*pi;
vr.position(1:2) = [r*cos(th) r*sin(th)];

% --- RUNTIME code: executes on every iteration of the ViRMEn engine.
function vr = runtimeCodeFun(vr)

% Update angle counts
actualV = atan2(vr.velocity(2),vr.velocity(1));
goalV = vr.targetPosition - vr.position(1:2);
goalV = atan2(goalV(2), goalV(1));
error = mod(actualV-goalV,2*pi);
if error > pi
    error = error-2*pi;
end
binIndx = find(vr.bins < error,1,'last');
if sqrt(sum(vr.velocity.^2)) > 3
    vr.angleCounts(binIndx) = vr.angleCounts(binIndx)+1;
end
vr.plot(2).x = sqrt(2)*vr.plotSize*(vr.bins(1:end-1)+diff(vr.bins)/2)/pi - vr.plotX;
vr.plot(2).y = vr.plotSize*(vr.angleCounts/max(vr.angleCounts)*2-1) + vr.plotY;
vr.plot(2).color = [1 0 0];

% Update plot
vr.plot(3).x = [-1 1 1 -1 -1]/100 + vr.plotSize*vr.position(1)/(vr.floorWidth/2) + vr.plotX;
vr.plot(3).y = [-1 -1 1 1 -1]/100 + vr.plotSize*vr.position(2)/(vr.floorWidth/2) + vr.plotY;
vr.plot(3).color = [1 0 0];
vr.plot(4).x = [-1 1 1 -1 -1]/100 + vr.plotSize*vr.targetPosition(1)/(vr.floorWidth/2) + vr.plotX;
vr.plot(4).y = [-1 -1 1 1 -1]/100 + vr.plotSize*vr.targetPosition(2)/(vr.floorWidth/2) + vr.plotY;
vr.plot(4).color = [0 1 0];

% Update time text box
vr.text(2).string = ['TIME ' datestr(now-vr.startTime,'MM.SS')];

% Test if the target was hit
isReward = false;
isDeliver = false;
% if (norm(vr.targetPosition - vr.position(1:2)) < vr.minDistance && norm(vr.position(1:2)) > vr.minTriggerRadius) ...
%             || (norm(vr.targetPosition - vr.position(1:2)) < vr.cylinderRadius + vr.minDistanceInside)
if norm(vr.targetPosition - vr.position(1:2)) < vr.minDistance
    isReward = true;
    isDeliver = (rand < vr.rewardProbability) || (vr.numRewards < vr.freeRewards);
end

% if norm(vr.position(1:2)) < vr.minTriggerRadius
%     lst = vr.worlds{vr.currentWorld}.objects.triangles(vr.worlds{vr.currentWorld}.objects.indices.targetCylinder,:);
%     vr.worlds{vr.currentWorld}.surface.visible(lst(1):lst(2)) = false;
% end

% Update reward text box
% Find a new position for the cylinder if the target was hit
if isReward    
    vr.numRewards = vr.numRewards + 1;
    if isDeliver
        newWorld = randi(length(vr.worlds));
        while vr.currentWorld == newWorld
            newWorld = randi(length(vr.worlds));
        end
        vr.currentWorld = newWorld;
        vr.numDeliver = vr.numDeliver + 1;
%         tempInd = [(abs(vr.position(1:2)) > vr.floorWidth/2), false, false];
%         vr.position(tempInd) = sign(vr.position(tempInd)).*(0.8*vr.floorWidth/2);
        if any(abs(vr.position(1:2)) > vr.floorWidth/2)
            vr.position(1:2) = [0, 0];
        end
    end
    vr.text(1).string = ['R=' num2str(vr.numDeliver) '/' num2str(vr.numRewards)];
    vr.targetPosition = vr.position(1:2);
    p = vr.randomRadiusExponent;
%     while (norm(vr.targetPosition) < vr.minTriggerRadius && norm(vr.targetPosition - vr.position(1:2)) < vr.minStartDistanceInside) || ...
%         (norm(vr.targetPosition) > vr.minTriggerRadius && norm(vr.targetPosition - vr.position(1:2)) < vr.minStartDistance)
    while norm(vr.targetPosition - vr.position(1:2)) < vr.minStartDistance ||...
        norm(vr.targetPosition-vr.position(1:2)) > vr.maxStartDistance
        if vr.currentWorld == 1%FOR ROUND ARENAS
            theta = 2*pi*rand;
            R = (rand.^p)*sqrt(2)*vr.floorWidth/2;
            vr.targetPosition = [R*cos(theta) R*sin(theta)];
        else
            vr.targetPosition = (rand(1,2).^p)*vr.floorWidth/2 .* sign(rand(1,2)-0.5);
        end
    end
end

% Relocate cylinder
if isReward || vr.iterations == 1
   lst = vr.worlds{vr.currentWorld}.objects.vertices(vr.worlds{vr.currentWorld}.objects.indices.targetCylinder,:);
   vr.worlds{vr.currentWorld}.surface.vertices(1,lst(1):lst(2)) = vr.cylinderTriangulation(1,:)+vr.targetPosition(1);
   vr.worlds{vr.currentWorld}.surface.vertices(2,lst(1):lst(2)) = vr.cylinderTriangulation(2,:)+vr.targetPosition(2);
end

% Beep in case the target was hit
if ~vr.debugMode
    if isReward
        sound(vr.rewardSound,vr.rewardFs);
    end
end

% Write data to file
if ~vr.debugMode
    if (isReward && isDeliver) || vr.textClicked == 1
        putdata(vr.ao,[0 5 5 5 5 0]');
        start(vr.ao);
        stop(vr.ao);
    end
       
    measurementsToSave = [now vr.position([1:2,4]) vr.velocity(1:2) vr.targetPosition(1:2) isDeliver isReward];
    if vr.isStarting
        vr.isStarting = false;
        fwrite(vr.fid,length(measurementsToSave),'double');
    end
    fwrite(vr.fid,measurementsToSave,'double');
end

% Send out synchronization pulse
switch mod(vr.iterations,5)
    case {0,1,3}
        v = mod(fix(vr.iterations),128);
    case 2
        v = mod(fix(vr.iterations/128),64)+128;
    case 4
        v = mod(fix(vr.iterations/8192),64)+192;
end

if ~vr.debugMode
	putvalue(vr.dio,v);
end
    
% --- TERMINATION code: executes after the ViRMEn engine stops.
function vr = terminationCodeFun(vr)

if ~vr.debugMode
    fclose all;
    fid = fopen([vr.pathname '\' vr.filename '.dat']);
    data = fread(fid,'double');
    num = data(1);
    data = data(2:end);
    data = reshape(data,num,numel(data)/num);
    assignin('base','data',data);
    fclose all;
    stop(vr.ai);
    stop(vr.dio);
    delete(vr.tempfile);
    
    vr.window.Dispose;
    answer = inputdlg({'Rat number','Comment'},'Question',[1; 5]);
    if ~isempty(answer)
        comment = answer{2}; %#ok<NASGU>
        save([vr.pathname '\' vr.filename '.mat'],'comment','-append')
        if ~exist([vr.pathname '\' answer{1}],'dir')
            mkdir([vr.pathname '\' answer{1}]);
        end
        movefile([vr.pathname '\' vr.filename '.mat'],[vr.finalPathname '\' answer{1} '\' vr.filename '.mat']);
        movefile([vr.pathname '\' vr.filename '.dat'],[vr.finalPathname '\' answer{1} '\' vr.filename '.dat']);
    end
    
    disp([answer{1} ' - ' num2str(sum(data(end,:)))])
end