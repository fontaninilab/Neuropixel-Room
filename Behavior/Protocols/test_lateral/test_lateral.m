function test_lateral    
global BpodSystem
global port;
port=serialport('COM9', 115200,"DataBits",8,FlowControl="none",Parity="none",StopBits=1,Timeout=0.5);
setDTR(port,true);
configureTerminator(port,"CR/LF");
fopen(port); %line 2-5 added 6/6/23 to control motor
%% Setup (runs once before the first trial)
MaxTrials = 10000; % Set to some sane value, for preallocation

%--- Define parameters and trial structure
S = BpodSystem.ProtocolSettings; % Loads settings file chosen in launch manager into current workspace as a struct called 'S'
if isempty(fieldnames(S))  % If chosen settings file was an empty struct, populate struct with default settings
    % Define default settings here as fields of S (i.e S.InitialDelay = 3.2)
    % Note: Any parameters in S.GUI will be shown in UI edit boxes. 
    % See ParameterGUI plugin documentation to show parameters as other UI types (listboxes, checkboxes, buttons, text)
    S.GUI.MotorTime = 0.5;
    S.GUI.RewardAmount = 3; % in ul

end

A = BpodAnalogIn('COM6');

A.nActiveChannels = 8;
A.InputRange = {'-5V:5V',  '-5V:5V',  '-5V:5V',  '-5V:5V',  '-10V:10V', '-10V:10V',  '-10V:10V',  '-10V:10V'};

%---Thresholds for optical detectors---
A.Thresholds = [1 1 1 2 2 2 2 2];
A.ResetVoltages = [0.4 0.4 0.1 1.5 1.5 1.5 1.5 1.5]; %Should be at or slightly above baseline (check oscilloscope)
%--------------------------------------

A.SMeventsEnabled = [1 1 1 0 0 0 0 0];
A.startReportingEvents();
A.scope;
A.scope_StartStop;
% Setting the seriers messages for opening the odor valve
% valve 8 is the vacumm; valve 1 is odor 1; valve 2 is odor 2
%LoadSerialMessages('ValveModule2', {['O' 1], ['C' 1],['O' 2], ['C' 2],['O' 8], ['C' 8], ['O' 5], ['C' 5]});
%LoadSerialMessages('ValveModule3', {['O' 8], ['C' 8]});

%--- Initialize plots and start USB connections to any modules
BpodParameterGUI('init', S); % Initialize parameter GUI plugin
BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_MoveZaber';

%% Main loop (runs once per trial)
for currentTrial = 1:MaxTrials
    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
    R = GetValveTimes(S.GUI.RewardAmount, [1 2]); LeftValveTime = R(1); RightValveTime = R(2); % Update reward amounts

    %--- Typically, a block of code here will compute variables for assembling this trial's state machine
        sma = NewStateMachine();

    %--- Assemble state machine
    sma = AddState(sma, 'Name', 'Initiation', ...
    'Timer', 2,...
    'StateChangeConditions', {'Tup', 'LoadWaterLeft'},...
    'OutputActions', {'BNCState',1});

    % load water
   sma = AddState(sma, 'Name', 'LoadWaterLeft', ... 
         'Timer', LeftValveTime,...
         'StateChangeConditions', {'Tup', 'LoadWaterRight'},...
         'OutputActions', {'ValveState', 1, 'BNCState',0});

      sma = AddState(sma, 'Name', 'LoadWaterRight', ... 
         'Timer', RightValveTime,...
         'StateChangeConditions', {'Tup', 'CentralForward'},...
         'OutputActions', {'ValveState', 2});

     sma = AddState(sma, 'Name', 'CentralForward', ... %Central spout moves forward
         'Timer', S.GUI.MotorTime,...
         'StateChangeConditions', {'Tup', 'WaitForLateralLicks'},...
         'OutputActions', {'SoftCode', 1});
    
    sma = AddState(sma, 'Name', 'WaitForLateralLicks', ...
        'Timer', 5,...
        'StateChangeConditions', {'Tup', 'CentralBack'},...
        'OutputActions', {});

     sma = AddState(sma, 'Name', 'CentralBack', ... %Central spout moves forward
         'Timer', S.GUI.MotorTime,...
         'StateChangeConditions', {'Tup', 'ITI'},...
         'OutputActions', {'SoftCode', 2});

      sma = AddState(sma, 'Name', 'ITI', ... %Central spout moves forward
         'Timer', 5,...
         'StateChangeConditions', {'Tup', '>exit'},...
         'OutputActions', {});
    SendStateMachine(sma); % Send state machine to the Bpod state machine device
    RawEvents = RunStateMachine; % Run the trial and return events
    
    %--- Package and save the trial's data, update plots
    if ~isempty(fieldnames(RawEvents)) % If you didn't stop the session manually mid-trial
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Adds raw events to a human-readable data struct
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
        
        %--- Typically a block of code here will update online plots using the newly updated BpodSystem.Data
        
    end
    
    %--- This final block of code is necessary for the Bpod console's pause and stop buttons to work
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    if BpodSystem.Status.BeingUsed == 0
                  delete(port);
        clear global port;
        return
    end
end