% linear
x = 50:200;
p = plot(x,linear(x));

p.LineWidth = 1;
p.Color = [0.1 0.1 0.1];
fontsize(18,"points")

xlabel("Frequency (Hz)")
ylabel("Speed of Sound (m/s)")

xticks([80 170])
xticklabels({"freq1", "freq2"})

yticks([linear(80) linear(170)]);
yticklabels({"speed1", "speed2"})
grid on;

saveas(gcf,'./figures/linear_spectral.png');


% log
x = 0:200;
y = log(x);
p = plot(x,y);

p.LineWidth = 1;
p.Color = [0.1 0.1 0.1];
fontsize(18,"points")

xlabel("Frequency (Hz)")
ylabel("Speed of Sound (m/s)")

xticks([30 170])
xticklabels({"freq1", "freq2"})

yticks([log(30) log(170)]);
yticklabels({"speed1", "speed2"})
grid on;

saveas(gcf,'./figures/logarithm_spectral.png');



% sigmoid
x = -10:0.05:10;
y = sigmoid(x);
p = plot(x,y);

p.LineWidth = 1;
p.Color = [0.1 0.1 0.1];
fontsize(18,"points")

xlabel("Frequency (Hz)")
ylabel("Speed of Sound (m/s)")

xticks([-2 2.5])
xticklabels({"freq1", "freq2"})

yticks([sigmoid(-2) sigmoid(2.5)]);
yticklabels({"speed1", "speed2"})
grid on;

saveas(gcf,'./figures/sigmoid_spectral.png');

% stepwise
x = -6:0.01:6;
% Define the y values based on the condition
y = zeros(size(x));
y(x > -0.5) = 0.7;
y(x < -0.5) = -0.7;

p = plot(x,y);
p.LineWidth = 1;
p.Color = [0.1 0.1 0.1];
fontsize(18,"points")

xlabel("Frequency (Hz)")
ylabel("Speed of Sound (m/s)")
xticks([-3 -0.5 2])
xticklabels({"freq1", "Median", "freq2"})
yticks([-0.7 0  0.7]);
yticklabels({"speed1","", "speed2"})
ylim([-1 1])
grid on;
saveas(gcf,'./figures/stepwise_spectral.png');




% % % %
function y = linear(x)
y = 1.5 * x;
end


function y = sigmoid(x)
y  =1.0 ./ (1.0 + exp(-x));
end

function y = step(x)
if x < 500
    y = 0;
else
    y = 1;
end
end