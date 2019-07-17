fid = fopen('20190717T143009.dat');
data = fread(fid,'double');
num = data(1);
data = data(2:end);
data = reshape(data,num,numel(data)/num);
cumDistance = cumsum(sqrt(sum(data(2:3, :).^2, 1)));
plot(data(1, :), cumDistance)