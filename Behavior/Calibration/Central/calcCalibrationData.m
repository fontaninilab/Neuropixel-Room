function data = calcCalibrationData(weights,valveOpenTimes,nTrials)
% Function to calibrate valves for central spout using output from
% calibrateCentralValve.m and hand-entered weights. Converts weights into
% volume per single pulse. Use calibrateCentralSpout.m for calibration script.
%
% INPUTS
%   weights: (1xN array) contains water weights for each corresponding valve
%            open time
%   valveOpenTimes: (1xN array) contains valve time parameters used
%   nTrials: (1x1 array) contains # of valve pulses
%
% OUTPUTS
%   data: (2xN array) contains valve open times, seconds (row 1) and volume
%         of water per single pulse, uL (row 2)

% --- Check you have weights for each valve time ---
if length(weights) ~= length(valveOpenTimes)
    fprintf('Data missing!\n')
end


% --- Convert grams to uL/drop ---
data = NaN(2,length(valveOpenTimes));
data(1,:) = valveOpenTimes;
for i = 1:length(valveOpenTimes)
   
    data(2,i) = (weights(i)*1000)./nTrials;
    
end