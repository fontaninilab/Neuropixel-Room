clear; clc;

P = PulsePalModule('COM5');
% P.isBiphasic(1)= 1;
% Pulse Parameters
P.phase1Voltage(1) = 10;
% P.phase2Voltage(1) = 1;

% P.phase1Duration(1) = 0.222;
% P.phase1Duration(1) = 0.0375;
P.phase1Duration(1) = 0.01875;

% P.phase1Duration(1) = 1.5;

% P.interPulseInterval(1) = 0.0375;
P.interPulseInterval(1) = 0.01875;

% P.interPulseInterval(1) =  0.0001;


% P.interPhaseInterval(1) = 0.025;

%
P.burstDuration(1) = 0;
% P.interBurstInterval(1) = 0.025;

P.pulseTrainDuration(1) = 1.5;

P.trigger(1)
%%

P.customTrainID(2) = 1;
P.customTrainTarget (2) = 0;
P.customTrainLoop  (2) = 1;
P.trigger(2)
