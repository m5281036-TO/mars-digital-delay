[y,Fs] = audioread('./Samples/sample.wav');

% extract 1~2000Hz
fpass1 = [1 2000];
y1 = bandpass(y,fpass1,Fs);

audiowrite('./Samples/out1.wav', y1, Fs); % play extracted audio