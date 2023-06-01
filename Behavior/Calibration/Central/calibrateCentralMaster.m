%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%          CALIBRATE CENTRAL SPOUT (BPOD)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Master script for calibrating valve open times for central spout using
% BPOD system (takes 10-15 minutes per valve)


rootdir = 'D:\GitHub\Neuropixel-Room\Behavior\Calibration\Central\';
cd(rootdir);
mkdir(date);
cd([rootdir date]);

%% ---- Run next two sections for each valve ----

valveN = 4; %Valve number
[valveOpenTimes, nTrials] = calibrateCentralValve(valveN);

fprintf('**********************************\n')
fprintf(' Calibration for valve %d complete\n',valveN)
fprintf('**********************************\n')

%%
weights = [0.1857 0.2526 0.4082 0.5582 0.7108]; %Enter weights for each valve time by hand
% Possible_v3_weights = [0.1402 0.2110 0.3466 0.4754 0.6032];
data = calcCalibrationData(weights,valveOpenTimes,nTrials);

save(['Valve' num2str(valveN) '-' date],'data');

fprintf('**********************************\n')
fprintf(' Conversion for valve %d complete\n',valveN)
fprintf('**********************************\n')

%% --- Calculate valve times for desired output volume ---
rewardamt = 4; % Output volume in uL
valveTimes = getValveTimesCentral(rewardamt);



