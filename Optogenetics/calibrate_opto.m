W = BpodWavePlayer('COM10');

% Target vals = 125, 250, 500, 1000 uW/mm^2
% fiber = 0.189mm^2
% = 23.6, 47.25, 94.5, 189uW
%%
% stays the same
total_duration =1;
samples = W.SamplingRate;
%%
% create_pulsetrain(pulse_volts, pulse_duration, interpulse_interval, total_duration, samples);

% 200
ts{1} = [5 0.00076 0.00024];
trains{1} = create_pulsetrain(ts{1}(1), ts{1}(2), ts{1}(3), total_duration, samples);

% 89
ts{2} = [5 0.00054 0.00046];
trains{2} = create_pulsetrain(ts{2}(1), ts{2}(2), ts{2}(3), total_duration, samples);

% 52
ts{3} = [5 0.00035 0.00065];
trains{3} = create_pulsetrain(ts{3}(1), ts{3}(2), ts{3}(3), total_duration, samples);

% 24
ts{4} = [5 0.00025 0.00075];
trains{4} = create_pulsetrain(ts{4}(1), ts{4}(2), ts{4}(3), total_duration, samples);

%%% used for ag12 higher voltage
pulse_duration = [0.00076 0.0008 0.0009 0.00099];
interpulse_interval = [0.00024 0.0002 0.0001 0.00001];

ts{5} = [5 0.00076 0.00024];
trains{5} = create_pulsetrain(ts{5}(1), ts{5}(2), ts{5}(3), total_duration, samples);

ts{6} = [5 0.0008 0.0002];
trains{6} = create_pulsetrain(ts{6}(1), ts{6}(2), ts{6}(3), total_duration, samples);

ts{7} = [5 0.00085 0.00015];
trains{7} = create_pulsetrain(ts{7}(1), ts{7}(2), ts{7}(3), total_duration, samples);

ts{8} = [5 0.0009 0.0001];
trains{8} = create_pulsetrain(ts{8}(1), ts{8}(2), ts{8}(3), total_duration, samples);






for i = 1:size(trains,2)
    W.loadWaveform(i, trains{i});
end

%%
 W.play(1,6)
%%
for i = 1:8
    W.play(1,i)
    pause(3)
end
%%
for j = 5:8
    for i = 1:3
        W.play(1,j)
        pause(5)
    end
end

%%
