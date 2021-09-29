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

valveN = 1; %Valve number
[valveOpenTimes, nTrials] = calibrateCentralValve(valveN);

fprintf('**********************************\n')
fprintf(' Calibration for valve %d complete\n',valveN)
fprintf('**********************************\n')

%%
weights = [0.136 0.21 0.327 0.452 0.572]; %Enter weights for each valve time by hand
data = calcCalibrationData(weights,valveOpenTimes,nTrials);

save(['Valve' num2str(valveN) '-' date],'data');

fprintf('**********************************\n')
fprintf(' Conversion for valve %d complete\n',valveN)
fprintf('**********************************\n')

%% --- Calculate valve times for desired output volume ---
rewardamt = 4; % Output volume in uL
valveTimes = getValveTimesCentral(rewardamt);



