function velocity = moveALODeCKHeading_1(vr)
    leadingText = 'array(''d'', ';
    velocity = [0 0 0 0];
    invertX = 1;%SET TO 1 to uninvert
    invertY = -1;%SET TO 1 to uninvert
    
    if ~isfield(vr,'scaling')
        vr.scaling = [30 30];
    end
    
    if vr.controller.BytesAvailable > 0
        out = fgetl(vr.controller);
    end
    
    if exist('out', 'var') && ~isempty(out)
        out = str2num(erase(out(strfind(out, leadingText):end-2), leadingText));
    end
    if ~exist('out', 'var') || isempty(out)
        out = [0, 0]
    end
    try
        velocity(1) = out(3)*vr.scaling(1)*invertX;
        velocity(2) = out(4)*vr.scaling(2)*invertY;
    end

end