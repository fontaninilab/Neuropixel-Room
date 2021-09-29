function valveTimes = getValveTimesCentral(outputamt)
% Use calibration curves for each valve to calculate valve open times for
% desired output volume. Use calibrateCentralSpout.m for calibration script.
%
% INPUTS
%   outputamt: (1x1 array) desired output volume (uL)
%
% OUTPUTS
%   valveTimes: (1xN array) time, seconds, for each valve to be open for
%               desired output volume



% --- Select folder containing calibration data for each valve ---
% --- from calcCalibrationData.m                               ---
selpath = uigetdir;
cd(selpath);
filenames = ls(selpath);
filenames(1:2,:) = [];


figure;
for i = 1:size(filenames,1)
    
    load(filenames(i,:));
    
    % Calculate line of best fit
    P = polyfit(data(1,:),data(2,:),1);
    y = polyval(P,data(1,:));
    
    % Calculate valve open time
    valveTimes(1,i) = i;
    valveTimes(2,i) = (outputamt - P(2))./P(1);
    
    %Plot calibration curve
    hold on; scatter(data(1,:),data(2,:),25,'filled','k')
    plot(data(1,:),y);
    scatter(valveTimes(2,i),outputamt,'*','c');

    
    
end
set(gca,'tickdir','out')
xlabel('Valve open time (s)'); ylabel('Droplet volume (uL)');