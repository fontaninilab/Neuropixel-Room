W = BpodWavePlayer('COM10');

% Target vals = 125, 250, 500, 1000 uW/mm^2
% fiber = 0.189mm^2
% = 23.6, 47.25, 94.5, 189uW
%%
% stays the same
total_duration =2;
samples = W.SamplingRate;
%%
% create_pulsetrain(pulse_volts, pulse_duration, interpulse_interval, total_duration, samples);
clc
ts{1} = [0.1 2 0];
ts{2} = [5 0.00035 0.00065];
% ts{3} = [5 0.00054 0.00046];
ts{3} = [5 0.0125 0.0125];

ts{4} = [5 0.00076 0.00024];
ts{5} = [4 0.0125 0.0125];

%ts{5} = [5 0.0007 0.0003];
ts{6} = [3 0.0125 0.0125];
 ts{7} = [5 0.0001 0.0001];
ts{8} = [5 0.001 0];
ts{9} = [5 0.001 0];

trains{1} = create_pulsetrain(ts{1}(1), ts{1}(2), ts{1}(3), total_duration, samples);
trains{2} = create_pulsetrain(ts{2}(1), ts{2}(2), ts{2}(3), total_duration, samples);
trains{3} = create_pulsetrain(ts{3}(1), ts{3}(2), ts{3}(3), total_duration, samples);
trains{4} = create_pulsetrain(ts{4}(1), ts{4}(2), ts{4}(3), total_duration, samples);
trains{5} = create_pulsetrain(ts{5}(1), ts{5}(2), ts{5}(3), 0.2, samples);
trains{6} = create_pulsetrain(ts{6}(1), ts{6}(2), ts{6}(3), 0.2, samples);
trains{7} = create_pulsetrain(ts{7}(1), ts{7}(2), ts{7}(3), total_duration, samples);
trains{8} = create_pulsetrain(ts{8}(1), ts{8}(2), ts{8}(3), total_duration, samples);
trains{9} = create_pulsetrain(ts{9}(1), ts{9}(2), ts{9}(3), total_duration, samples);

for i = 1:size(trains,2)
    W.loadWaveform(i, trains{i});
end


%%
    W.play(1,1)
    %%
        pause(2)

        W.play(1,5)
pause(0.2)
        W.play(1,6)

%%
    W.play(1,4)

%%
for i = 1:5
    W.play(1,4)
    pause(2)
end
%%
for i = 1:7
    W.play(1,i)
    pause(2)
end