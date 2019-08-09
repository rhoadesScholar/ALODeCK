function velocity = moveALODeCK_1(vr)
    type = 'velocity';
    velocity = [0 0 0 0];
    invertX = 1;%SET TO 1 to uninvert
    invertY = -1;%SET TO 1 to uninvert
    
    if ~isfield(vr,'scaling')
        vr.scaling = [30 30];
    end
    
    if vr.controller.BytesAvailable == 0
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
    
    velocity(1) = out(1)*vr.scaling(1)*invertX;
    velocity(2) = out(2)*vr.scaling(2)*invertY;

end