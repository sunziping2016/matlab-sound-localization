clear all;

run('parameter');

%% 参数

start_threshold = 10;
start_end_num = 6;

%% 读取声音
sound = audioread('106.wav')';
sound = sound(1,:);

%% 生成声音
t = 0:1/fs:(symbol_len-1)/fs;
symbol = chirp(t, f0, t(end), f1, 'linear');
[cor, lags] = xcorr(sound, symbol);

figure(2);
plot(lags, cor);
title('信号匹配程度');

slide_num = floor(length(sound) / symbol_len) - 1;
values = [];
indices = [];
started = false;
for i = 1:slide_num
    window = sound((symbol_len*(i-1)+1):symbol_len*(i+1));
    [cor, lags] = xcorr(window, symbol);
    clip_start = floor(length(cor) / 2);
    cor = cor(clip_start:clip_start + symbol_len);
    lags = lags(clip_start:clip_start + symbol_len);
    [max_cor, index] = max(cor);
    value = max_cor / mean(abs(cor));
    values = [values, value];
    indices = [indices, index];
    % 检测开始
end

% start = 20450 - 50;
% fftlen = 1024*64;
% 
% t = 0:1/fs:(symbol_len-1)/fs;
% symbol = chirp(t, f0, t(end), f1, 'linear');
% %symbol = [symbol, zeros(1,symbol_len)];
% pseudo = repmat(symbol, 1, symbol_num);
% data = sound(start:start+symbol_len*symbol_num-1);
% s = pseudo.*data;
% 
% 
% for i = 1:symbol_num
%     FFT_out = abs(fft(s(symbol_len*(i-1)+1:symbol_len*i), fftlen));
%     [~, idx] = max(FFT_out(1:round(fftlen/10)));
%     idxs(i) = idx;
% end
% 
% start_idx=0;
% delta_distance = (idxs-start_idx)*fs/fftlen*340*T/(f1-f0);
% figure;
% plot(delta_distance);

