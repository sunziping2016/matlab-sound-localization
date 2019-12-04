clear all;

run('parameter');

%% 参数

start_intensity_threshold = 6;
start_index_std_limit = 50;
end_intensity_threshold = 6;
end_index_std_limit = 100;
start_end_num = 6;
padding_offset = 50;
fftlen = 1024*64;

%% 读取声音
sound = audioread('106.wav')';
sound = sound(1,:);

%% 解析声音
t = 0:1/fs:(symbol_len-1)/fs;
symbol = chirp(t, f0, t(end), f1, 'linear');
[cor, lags] = xcorr(sound, symbol);

% figure;
% plot(lags, cor);
% title('信号匹配程度');

slide_num = floor(length(sound) / symbol_len) - 1;
intensities = [];
indices = [];
started = false;
index_offset = 0;
sound_buffer = [];
intensities_buffer = [];
indices_buffer = [];
signal_buffer = [];
positions = [];
for i = 1:slide_num
    window = sound((symbol_len*(i-1)+1):symbol_len*(i+1));
    [cor, lags] = xcorr(window, symbol);
    clip_start = floor(length(cor) / 2);
    cor = cor(clip_start:clip_start + symbol_len);
    lags = lags(clip_start:clip_start + symbol_len);
    [max_cor, index] = max(cor);
    intensity = max_cor / mean(abs(cor));
    intensities = [intensities, intensity];
    indices = [indices, index];
    % 构建缓冲区
    sound_buffer = [sound_buffer, window(1:symbol_len)];
    intensities_buffer = [intensities_buffer, intensity];
    indices_buffer = [indices_buffer, index];
    if length(intensities_buffer) > start_end_num
        sound_buffer = sound_buffer(end-start_end_num*symbol_len+1:end);
        intensities_buffer = intensities_buffer(end-start_end_num+1:end);
        indices_buffer = indices_buffer(end-start_end_num+1:end);
    end
    if length(intensities_buffer) == start_end_num
        mean_intensities_buffer = mean(intensities_buffer);
        std_indices_buffer = std(indices_buffer);
        skip_signal_buffer = false;
        if ~started
            % 检测开始
            if mean_intensities_buffer > start_intensity_threshold && ...
                    std_indices_buffer <= start_index_std_limit
                % fprintf('started: %d\n', i);
                started = true;
                index_offset = round(mean(indices_buffer));
                % 添加偏移，第1个信号可能会被丢弃
                index_offset = index_offset - padding_offset;
                if index_offset < 0
                    index_offset = index_offset + symbol_len;
                end
                signal_buffer = window(index_offset:symbol_len);
                skip_signal_buffer = true;
            end
        else
            % 检测结尾，最后start_end_num个信号可能会被丢弃
            if mean_intensities_buffer <= end_intensity_threshold || ...
                    std_indices_buffer > end_index_std_limit
                started = false;
                signal_buffer = [];
                % 绘图
                if ~isempty(positions)
                    figure;
                    distances = positions*fs/fftlen*340*T/abs(f1-f0);
                    plot(distances);
                end
                positions = [];
            end
        end
        if started && ~skip_signal_buffer
            signal_buffer = [signal_buffer, window(1:symbol_len)];
            while length(signal_buffer) > symbol_len
                signal = signal_buffer(1:symbol_len);
                signal_buffer = signal_buffer(symbol_len+1:end);
                mixed = signal.*symbol;
                fft_out = abs(fft(mixed, fftlen));
                [~, position] = max(fft_out(1:round(fftlen/10)));
                positions = [positions, position];
            end
        end
        % fprintf('threshold@%d (intensity: %f, index_std: %f, started: %d)\n', ...
        %     i, mean_intensities_buffer, std_indices_buffer, started)
    end
end

%% 硬编码解析声音
% start = 20450 - 50;
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

