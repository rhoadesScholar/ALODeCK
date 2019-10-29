% [now, vr.hiddenDp(1:2), vr.hiddenPosition([1:2,4]), vr.currentMode, ...
%             toc(vr.modeTimer), vr.modeTime, vr.velocity(1:2), vr.targetPosition(1:2), isDeliver, isReward];
fid = fopen('20190717T173030.dat');
data = fread(fid,'double');
num = data(1);
data = data(2:end);
data = reshape(data,num,numel(data)/num);
cumDistance = cumsum(sqrt(sum(data(2:3, :).^2, 1)));
plot(data(1, :), cumDistance)

figure
freeze = data(:, data(7,:) == 1);
move = data(:, data(7,:) ~= 1);
plot(freeze(1, :), cumsum(sqrt(sum(freeze(2:3, :).^2, 1))))
hold on
plot(move(1, :), cumsum(sqrt(sum(move(2:3, :).^2, 1))))

figure
plot(freeze(2, :), freeze(3, :))
hold on
plot(move(2, :), move(3, :))