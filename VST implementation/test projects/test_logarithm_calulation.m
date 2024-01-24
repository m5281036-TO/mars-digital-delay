clear all
freq1 = 100;
freq2 = 3000;
speed1 = 50;
speed2 = 400;

f = [freq1 freq2];
s = [speed1 speed2];
iCf = 20;
logf = log(f);
lm = fitlm(log(f),s)
plot(log(f),s)

% fitlm
% y_intercept = lm.Coefficients.Estimate(1);
% slope = lm.Coefficients.Estimate(2);

% w/o fitlm
slope = (speed2 - speed1)/(log(freq2) - log(freq1))
y_intercept = speed1 -(slope * log(freq1))


plot((slope * log(freq1-freq1:freq2) + y_intercept))
% speed_iCf = x1 * log(iCf) + intercept
