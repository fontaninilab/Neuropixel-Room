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
 weights = [0.1069 0.1906 0.3429 0.5087 0.6708]; %Enter weights for each valve time by hand
% weights = [0.1002 0.1813 0.3357 0.4819 0.6332];
% Possible_v3_weights = [0.1402 0.2110 0.3466 0.4754 0.6032];
data = calcCalibrationData(weights,valveOpenTimes,nTrials);

save(['Valve' num2str(valveN) '-' date],'data');

fprintf('**********************************\n')
fprintf(' Conversion for valve %d complete\n',valveN)
fprintf('**********************************\n')

%% --- Calculate valve times for desired output volume ---
rewardamt = 3; % Output volume in uL
valveTimes = getValveTimesCentral(rewardamt);



