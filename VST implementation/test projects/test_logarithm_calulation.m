freq1 = 100;
freq2 = 3000;
speed1 = 50;
speed2 = 400;

f = [freq1;freq2];
s = [speed1;speed2];
iCf = 20;
lm = fitlm(log(f),s);

intercept = lm.Coefficients.Estimate(1);
x1 = lm.Coefficients.Estimate(2);

plot((x1 * log(freq1-min(freq1,freq2):freq2) + intercept))
speed_iCf = x1 * log(iCf) + intercept