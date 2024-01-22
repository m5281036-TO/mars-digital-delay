freq1 = 1000;
freq2 = 100;

speed1 = 100;
speed2 = 300;


x = -10:0.1:10;
result = 1.0 ./ (1.0 + exp(-x));
result_v = min(speed1, speed2) + abs(speed1-speed2) * result;
plot(result_v);

fci = 1000;
% dist = 3000;

normalized_f = -10 + 20 * (fci - min(freq1, freq2)) / abs(freq1 - freq2);
fSigmoid = 1.0 ./ (1.0 + exp(-normalized_f));
if freq1 < freq2
    speed_iCf = speed1 + (abs(speed1-speed2) * fSigmoid);
else % freq1 > freq2
    speed_iCf = speed2 + (abs(speed1-speed2) * fSigmoid);
end