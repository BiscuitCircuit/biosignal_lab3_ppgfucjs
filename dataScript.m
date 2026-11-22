clear all
close all
clc

data = readtable('ppg_lab3.csv');

fs  = 64;                              % PPG sample rate (Hz)
amb = data.PPG1;                       % ambient
ir  = data.PPG2;                       % infrared
red = data.PPG3;                       % red
t   = (0:height(data)-1)' / fs;        % time in seconds

%% Step 1: Original Signals
figure;
subplot(2,1,1);
plot(t, ir);
title('Original IR PPG Signal');
xlabel('Time (s)'); ylabel('Amplitude'); grid on;

subplot(2,1,2);
plot(t, red, 'r');
title('Original Red PPG Signal');
xlabel('Time (s)'); ylabel('Amplitude'); grid on;


saveas(gcf, 'fig1_original.png');


%% Step 2: fix dropped samples and subtract ambient light

% Find samples recorded as 0 (dropped Bluetooth packets) and fill them in
bad = (amb == 0) | (ir == 0) | (red == 0);
fprintf('%d dropped samples out of %d\n', sum(bad), height(data));
amb(bad) = NaN;  ir(bad) = NaN;  red(bad) = NaN;
amb = fillmissing(amb, 'linear');
ir  = fillmissing(ir,  'linear');
red = fillmissing(red, 'linear');

% Subtract ambient light from instrucitons
realIR  = ir  - amb;
realRed = red - amb;

% Ambient-corrected signals
figure;
subplot(2,1,1);
plot(t, realIR);
title('IR: Ambient Subtracted');
xlabel('Time (s)'); ylabel('Amplitude'); grid on;

subplot(2,1,2);
plot(t, realRed, 'r');
title('Red: Ambient Subtracted');
xlabel('Time (s)'); ylabel('Amplitude'); grid on;
%saveas(gcf, 'fig2_ambient_corrected.png');



%% Step 3: high-pass filter to remove drift
fc = 0.5; % cutoff frequency 
irHP  = highpass(realIR,  fc, fs);
redHP = highpass(realRed, fc, fs);

figure;
subplot(2,1,1);
plot(t, irHP);
title(sprintf('IR: High-Pass Filtered (%.1f Hz cut off)', fc));
xlabel('Time (s)'); ylabel('Amplitude'); grid on;

subplot(2,1,2);
plot(t, redHP, 'r');
title(sprintf('Red: High-Pass Filtered (%.1f Hz cutu off)', fc));
xlabel('Time (s)'); ylabel('Amplitude'); grid on;
%saveas(gcf, 'fig3_highpass.png');


%% Step 4: Savitzky-Golay smoothing to remove high-frequency noise
span = 9;   % window length in samples (odd number), 15 samples = about 0.23 s
deg  = 3;    % polynomial order

irClean  = sgolayfilt(irHP,  deg, span);
redClean = sgolayfilt(redHP, deg, span);

figure;
subplot(2,1,1);
plot(t, irClean);
title(sprintf('IR: High-Pass & Savitzky-Golay)', span));
xlabel('Time (s)'); ylabel('Amplitude'); grid on;

subplot(2,1,2);
plot(t, redClean, 'r');
title(sprintf('Red: High-Pass & Savitzky-Golay)', span));
xlabel('Time (s)'); ylabel('Amplitude'); grid on;
%saveas(gcf, 'fig4_cleaned.png');

%% Step 5: Plotting the Power Spectral Density (PSD) 
N = length(irClean);
f = (0:N-1) * fs / N; 
pIR  = abs(fft(irClean)).^2;          
pRed = abs(fft(redClean)).^2;

% only keep the first half 
half = 1:floor(N/2);
f = f(half);  pIR = pIR(half);  pRed = pRed(half);

figure;
subplot(2,1,1);
plot(f, pIR);
title('IR: Power Spectrum');
xlabel('Frequency (Hz)'); ylabel('Power');
xlim([0 5]); grid on;

subplot(2,1,2);
plot(f, pRed, 'r');
title('Red: Power Spectrum');
xlabel('Frequency (Hz)'); ylabel('Power');
xlim([0 5]); grid on;

%% Step 6: Heartbeat from PSD

%narrow down to reasonable range of frequency for heart beat
band = f>= 0.67 & f <=3.5;
fband = f(band);

pb = pIR(band);
pb_red = pRed(band);

[max_val_ir, max_in_ir] = max(pb);
[max_val_red, max_in_red] = max(pb_red);

hr_ir = fband(max_in_ir) * 60;
hr_red = fband(max_in_red) * 60;

fprintf('Heart rate(IR): %.1f bpm\n',hr_ir);
fprintf('Heart rate(IR): %.1f bpm\n',hr_red);

%% Step 7: Heart rate by counting peaks
t1 = 10;  
t2 = 40;
%looking at a specific time-window
idx = (t >= t1 & t <= t2);
t_seg = t(idx);
ir_seg = irClean(idx);
red_seg = redClean(idx);

% peaks at least 0.4 s apart (max ~150 bpm) and clearly above the noise
[pksIR, locsIR]  = findpeaks(ir_seg,t_seg,'MinPeakDistance', 0.4,'MinPeakProminence',0.5*std(ir_seg));
[pksRed, locsRed] = findpeaks(red_seg,t_seg,'MinPeakDistance', 0.4,'MinPeakProminence',0.5*std(red_seg));

hrPeaks_ir = length(pksIR) /(t2 - t1) *60;
hrPeaks_red = length(pksRed) /(t2 - t1)* 60;

%Visual Confirmation for the peak detection
figure;
subplot(2,1,1);
plot(t_seg, ir_seg); hold on;
plot(locsIR, pksIR,'.','MarkerSize',20);
title('IR: Detected Peaks');
xlabel('Time (s)'); ylabel('Amplitude'); grid on;
subplot(2,1,2);
plot(t_seg, red_seg); hold on;
plot(locsRed, pksRed, '.','MarkerSize',20);
title('Red: Detected Peaks');
xlabel('Time (s)'); ylabel('Amplitude'); grid on;


%% Step 8: Compare peak counting method vs PSD for heart rate
fprintf('\n       PeaksCount     PSD     Difference\n');
fprintf('IR:     %6.1f    %6.1f  %6.1f bpm\n', hrPeaks_ir,hr_ir,  abs(hrPeaks_ir- hr_ir));
fprintf('Red:    %6.1f    %6.1f  %6.1f bpm\n', hrPeaks_red, hr_red, abs(hrPeaks_red- hr_red));

%% Step 9: Heart rate variability 

%Method 1: Root Mean Square
ibi_ir  = diff(locsIR);          % inter-beat intervals (s)
ibi_red = diff(locsRed);

rmssd_ir  = sqrt(mean(diff(ibi_ir).^2));
rmssd_red = sqrt(mean(diff(ibi_red).^2));

%Method 2: Standard Deviation of NN intervals
interval_lengths = diff(locsIR); 
interval_mean = mean(interval_lengths);

len_mean = interval_lengths - interval_mean;

len_mean_square = len_mean.^2;

len_mean_square_sum = sum(len_mean_square); 

sdnn_ir = sqrt(len_mean_square_sum/(length(interval_lengths)-1));

sdnn_red = std(diff(locsRed));

fprintf('\nHeart Rate Variability:\n');
fprintf('IR: RMS peak time: %.3f s, SDNN: %.3f s\n', rmssd_ir, sdnn_ir);
fprintf('Red: RMS peak time: %.3f s, SDNN: %.3f s\n',rmssd_red, sdnn_red);


