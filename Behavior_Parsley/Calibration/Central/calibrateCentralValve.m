function [valveOpenTimes, nTrials] = calibrateCentralValve(valveN)
% Function to calibrate valves for central spout using BPOD. Outputs
% parameters used that will be necessary in other functions to calculate
% calibration curves. Use calibrateCentralSpout.m for calibration script.
%
% INPUTS
%   valveN: (1x1 array) valve number
%
% OUTPUTS
%   valveOpenTimes: (1xN array) contains valve time parameters used
%   nTrials: (1x1 array) contains # of valve pulses

ITI = 0.1; % inter-trial interval (s) 
nTrials = 100; %Number of pulses
valveOpenTimes = [0.05 0.1 0.2 0.3 0.4]; % Time (in seconds) valve opens
valveID = (2*valveN)-1; %Convert valve number to BPOD valve ID

% --- Define parameters and trial structure for BPOD ---
global BpodSystem
S = BpodSystem.ProtocolSettings; % Loads settings file chosen in launch manager into current workspace as a struct called 'S'

S.GUI.ValveID = valveID;
S.GUI.ITI = ITI;
S.GUI.MaxTrials = nTrials; % Set to some sane value, for preallocation

LoadSerialMessages('ValveModule1', {['O' 1], ['C' 1],['O' 2], ['C' 2],['O' 3], ['C' 3], ['O' 4], ['C' 4],['O' 5], ['C' 5],['O' 6], ['C' 6], ['O' 7], ['C' 7], ['O' 8], ['C' 8]});
BpodParameterGUI('init', S); % Initialize parameter GUI plugin

fprintf('Calibrating valve %d\n',valveN);


for i = 1:length(valveOpenTimes) %loop through valve times
    
    S.GUI.TastantAmount = valveOpenTimes(i);
    fprintf('Calibrating %4.2f s pulses...',valveOpenTimes(i));


    for trial = 1:nTrials
        S = BpodParameterGUI('sync', S);

        sma = NewStateMachine();

        sma = AddState(sma, 'Name', 'TasteValveOn', ... %Open specific taste valve
            'Timer',  S.GUI.TastantAmount,...
            'StateChangeConditions ', {'Tup', 'TasteValveOff'},...
            'OutputActions', {'ValveModule1', S.GUI.ValveID});

        sma = AddState(sma, 'Name', 'TasteValveOff', ... % This example state does nothing, and ends after 0 seconds
            'Timer', 0.01,...
            'StateChangeConditions', {'Tup', 'ITI'},...
            'OutputActions', {'ValveModule1', S.GUI.ValveID+1});

        sma = AddState(sma, 'Name', 'ITI', ... % This example state does nothing, and ends after 0 seconds
            'Timer', S.GUI.ITI,...
            'StateChangeConditions', {'Tup', '>exit'},...
            'OutputActions', {});              

        SendStateMatrix(sma); % Send state machine to the Bpod state machine device
        RawEvents = RunStateMatrix; % Run the trial and return events

        %--- This final block of code is necessary for the Bpod console's pause and stop buttons to work
        HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
        if BpodSystem.Status.BeingUsed == 0
            return
        end

    end
    fprintf('Waiting to record weight...')
    
   %  ---- Pause before starting next valve time to measure liquid, then key press to continue ----
    pause; 
    fprintf('Weight recorded\n');
end