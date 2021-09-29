function data = calcCalibrationCurve(weights,valveOpenTimes,nTrials)

%Check you have weights for each valve time
if length(weights) ~= length(valveOpenTimes)
    fprintf('Data missing!\n')
end


% Convert grams to uL/drop
data = NaN(2,length(valveOpenTimes));
data(1,:) = valveOpenTimes;
for i = 1:length(valveOpenTimes)
   
    data(2,i) = (weights(i)*1000)./nTrials;
    
end