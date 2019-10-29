function [velocity, type, missedBeat] = moveALODeCK2D_3(vr)
    type = 'velocity';
    velocity = [0 0 0 0];
    invertX = 1;%SET TO 1 to uninvert
    invertY = -1;%SET TO 1 to uninvert
    
    if ~isfield(vr,'scaling')
        vr.scaling = [30 30];
    end
    
    try 
        byteAvail = vr.controller.BytesAvailable;
    catch
        vr = getController(vr);
    end
    if byteAvail == 0
        missedBeat = 1
    else
%         while vr.controller.BytesAvailable > 1
        [out, m] = split(sprintf('%c', fread(vr.controller, [vr.controller.InputBufferSize, 1], 'char')), {'[', ']'});
%         end
        out = str2num(out{find(strcmp(m, ']'), 1, 'last')});
        missedBeat = 0;
    end
    if ~exist('out', 'var') || isempty(out) || ~isnumeric(out) || length(out) < 6
        out = [0, 0, 0, 0, 0, 0];
    end
    try
        cmp = abs(out(5:6).*out(3:4));
        ind = (cmp == max(cmp)) & (sign(out(5:6)) == sign(out(3:4)));
        if ~any(ind), ind = (sign(out(5:6)) == sign(out(3:4))); end
        out(repmat(~ind, 1, 3)) = 0;
        velocity(1) = out(3)*vr.scaling(1)*invertX;
        velocity(2) = out(4)*vr.scaling(2)*invertY;
    end

end

function vr = getController(vr)
    disp('Resetting controller...');
    try
        fclose(vr.controller)
        delete(vr.controller)
        pause(5)
        vr.controller = serial(vr.exper.variables.comPort)
        fopen(vr.controller)
        vr.controller.ReadAsyncMode = 'continuous'
        out = fgetl(vr.controller)
        tic
        while ~contains(out, 'array') && toc < 3
            out = fgetl(vr.controller)
        end
        if isempty(out)
            vr.experimentEnded = true
            vr.code.termination(vr);
            evalin('caller', 'return');
        elseif ~contains(out, 'array')
            while ~contains(out, 'array')
                out = fgetl(vr.controller)
            end
        end
    catch
        disp('No controller found.');
        vr.controller = {};
        vr.experimentEnded = true
        vr.code.termination(vr);
        evalin('caller', 'return');
    end
    vr.missedBeats = 0;
end