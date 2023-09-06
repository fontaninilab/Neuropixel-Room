%clear; clc;

P = PulsePalModule('COM10');
% P.isBiphasic(1)=0;
%%
% Pulse Parameters
P.phase1Voltage(1) = 5;
%P.phase1Duration(1) = 0.025;
%P.interPulseInterval(1) = 0.025;

%change frequency 
 P.phase1Duration(1) = 0.0008;
 P.interPulseInterval(1) = 0.0002;


% P.phase1Duration(1) = 1.5;
% P.interPulseInterval(1) =1.5;
%
P.burstDuration(1) = 0;
% P.interBurstInterval(1) = 0.025;
P.pulseTrainDuration(1) = 4;
P.trigger(1)

%{
%%
(0.01875*2)
%%
P.customTrainID(2) = 1;
P.customTrainTarget (2) = 0;
P.customTrainLoop  (2) = 1;
P.trigger(2)
%}