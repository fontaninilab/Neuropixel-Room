function odortest   
global BpodSystem
global port;
port=serialport('COM9', 115200,"DataBits",8,FlowControl="none",Parity="none",StopBits=1,Timeout=0.5);
setDTR(port,true);
configureTerminator(port,"CR/LF");
fopen(port); %line 2-5 added 6/6/23 to control motor
%% Setup (runs once before the first trial)
MaxTrials = 200; % Set to some sane value, for preallocation

%TrialTypes = ceil(rand(1,MaxTrials)*2);

vaccuumvalveID = 8;
odor1valveID = 1;
odor2valveID = 2;

taste1valveID = 1;
taste2valveID = 2;

%--- Define parameters and trial structure
S = BpodSystem.ProtocolSettings; % Loads settings file chosen in launch manager into current workspace as a struct called 'S'
if isempty(fieldnames(S))  % If chosen settings file was an empty struct, populate struct with default settings
    % Define default settings here as fields of S (i.e S.InitialDelay = 3.2)
    % Note: Any parameters in S.GUI will be shown in UI edit boxes.
    % See ParameterGUI plugin documentation to show parameters as other UI types (listboxes, checkboxes, buttons, text)
    %     S.GUI = struct;
    
    S.GUI.TrainingLevel = 4;
    S.GUI.SamplingDuration = 2;
    S.GUI.TasteLeft =1; %Taste1;
    S.GUI.TasteRight = 2;%Taste2;
    S.GUI.DelayDuration = 1.0;
    S.GUI.TastantAmount = 0.05;
    S.GUI.MotorTime = 0.5;
    S.GUI.Up        = 14;
    S.GUI.Down      =   5;
    S.GUI.ResponseTime =5; %10;
    S.GUI.DrinkTime = 3;
    S.GUI.RewardAmount = 5; % in ul
    S.GUI.PunishTimeoutDuration =10; %10;
    S.GUI.AspirationTime = 1; 
    S.GUI.ITI = 5;
    
end
% set the threshold for the analog input signal to detect events
A = BpodAnalogIn('COM6');

A.nActiveChannels = 8;
A.InputRange = {'-5V:5V',  '-5V:5V',  '-5V:5V',  '-5V:5V',  '-10V:10V', '-10V:10V',  '-10V:10V',  '-10V:10V'};

%---Thresholds for optical detectors---
A.Thresholds = [1 1 1 2 2 2 2 2];
A.ResetVoltages = [0.4 0.4 0.1 1.5 1.5 1.5 1.5 1.5]; %Should be at or slightly above baseline (check oscilloscope)
%--------------------------------------

A.SMeventsEnabled = [1 1 1 0 0 0 0 0];
A.startReportingEvents();

% Setting the seriers messages for opening the odor valve
% valve 8 is the vacumm; valve 1 is odor 1; valve 2 is odor 2
LoadSerialMessages('ValveModule2', {['O' 1],['C' 1],['O' 2],['C' 2],...
    ['O' 3],['C' 3],['O' 4],['C' 4],['O' 5],['C' 5],['O' 6],['C' 6],...
    ['O' 7],['C' 7],['O' 8],['C' 8]});

AllValveOnIds = 1:2:16;

% test all valves randomly
allvalves = [1 2 3 4 5 6];
r = randi([1 6],1,200);
randvalve = allvalves(r);

% test one valve
valvetotest = 1;
singlevalve = ones(1,200)*valvetotest;

odorvalvetimes = [1 1];

% CHANGE ME to randvalve if that's what you want
TrialTypes = singlevalve;
valveonids = AllValveOnIds(TrialTypes);

BpodParameterGUI('init', S); % Initialize parameter GUI plugin

%% Main loop (runs once per trial)

blankon = 14;
blankoff = 13;
vacon = 16;
vacoff = 15; 
preloadtime = 1;
for currentTrial = 1:MaxTrials
    odoron = valveonids(currentTrial);
    odoroff = odoron+1;

    disp(['Trial# ' num2str(currentTrial) ' TrialType: ' num2str(TrialTypes(currentTrial)) ' ' num2str(odoron)])
    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
    R = GetValveTimes(S.GUI.RewardAmount, [1 2]); LeftValveTime = R(1); RightValveTime = R(2); % Update reward amounts

    %--- Assemble state machine
    sma = NewStateMachine();

    % ---- TRIAL START -----

    % turn off blank
    sma = AddState(sma, 'Name', 'BlankOff', ... % Initiation
        'Timer', 0,...
        'StateChangeConditions ', {'Tup', 'OdorValveOn'},...
        'OutputActions', {'ValveModule2', blankoff}); 

    % open odor valve (preload), trigger
    sma = AddState(sma, 'Name', 'OdorValveOn', ... %Open specific odor valve
        'Timer', preloadtime,...
        'StateChangeConditions ', {'Tup', 'VaccuumOff'},...
        'OutputActions', {'ValveModule2', odoron}); 

    % vaccuum off - ODOR DELIVERED
    sma = AddState(sma, 'Name', 'VaccuumOff', ... 
        'Timer', S.GUI.SamplingDuration,...
        'StateChangeConditions', {'Tup', 'VaccuumOn'},...
        'OutputActions', {'ValveModule2', vacoff,'BNCState',1});

    % vaccuum on - ODOR REMOVED
     sma = AddState(sma, 'Name', 'VaccuumOn', ... 
        'Timer', 0,...
        'StateChangeConditions', {'Tup', 'OdorValveOff'},...
        'OutputActions', {'ValveModule2', vacon, 'BNCState', 0});

    % close odor valve
    sma = AddState(sma, 'Name', 'OdorValveOff', ...
    'Timer', 0,...
    'StateChangeConditions ', {'Tup', 'BlankOn'},...
    'OutputActions', {'ValveModule2', odoroff});
    
    % open blank valve
    sma = AddState(sma, 'Name', 'BlankOn', ...
    'Timer', 0,...
    'StateChangeConditions ', {'Tup', 'ITI'},...
    'OutputActions', {'ValveModule2', blankon});

    

     sma = AddState(sma, 'Name', 'ITI', ...
    'Timer', S.GUI.ITI,...
    'StateChangeConditions', {'Tup', '>exit'},...
    'OutputActions', {});
    
    SendStateMatrix(sma); % Send state machine to the Bpod state machine device
    RawEvents = RunStateMatrix; % Run the trial and return events
    
    %--- Package and save the trial's data, update plots
    if ~isempty(fieldnames(RawEvents)) % If you didn't stop the session manually mid-trial
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Adds raw events to a human-readable data struct
        BpodSystem.Data.TrialSequence(currentTrial) = TrialTypes(currentTrial);
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
        
    else
    end

    %--- This final block of code is necessary for the Bpod console's pause and stop buttons to work
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    if BpodSystem.Status.BeingUsed == 0
          delete(port);
        clear global port;
        return
    end
    
end