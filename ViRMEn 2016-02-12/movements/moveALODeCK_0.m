function velocity = moveALODeCK_0(vr)
    out = fgetl(vr.controller);
    leadingText = 'array(''d'', ';
    out = str2num(erase(out(strfind(out, leadingText):end-2), leadingText));
    
    if isempty(out)
        out = [0, 0]
    end
    
    velocity = [0 0 0 0];
    if ~isfield(vr,'scaling')
        vr.scaling = [30 30];
    end
    velocity(1) = out(1)*vr.scaling(1);
    velocity(2) = out(2)*vr.scaling(2);

end