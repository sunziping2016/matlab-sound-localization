clear all;

run('parameter');

% 生成声音
t = 0:1/fs:(symbol_len-1)/fs;
symbol = chirp(t, f0, t(end), f1, 'linear');
%symbol = [symbol, zeros(1,symbol_len)];
output = [zeros(1,symbol_len), ...
          repmat(symbol, 1, symbol_num)];

figure(1);
plot(output);

audiowrite('speaker.wav', output, fs, 'BitsPerSample', 16);