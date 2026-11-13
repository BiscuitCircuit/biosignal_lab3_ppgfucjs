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
saveas(gcf, 'fig2_ambient_corrected.png');



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
saveas(gcf, 'fig3_highpass.png');


%% Step 4: Savitzky-Golay smoothing to remove high-frequency noise
span = 15;   % window length in samples (odd number), 15 samples = about 0.23 s
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
saveas(gcf, 'fig4_cleaned.png');