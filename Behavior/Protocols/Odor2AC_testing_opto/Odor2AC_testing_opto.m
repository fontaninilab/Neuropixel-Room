function Odor2AC_testing_opto     
global BpodSystem
global port;
port=serialport('COM9', 115200,"DataBits",8,FlowControl="none",Parity="none",StopBits=1,Timeout=0.5);
setDTR(port,true);
configureTerminator(port,"CR/LF");
fopen(port); %line 2-5 added 6/6/23 to control motor
%% Setup (runs once before the first trial)
MaxTrials = 1000; % Set to some sane value, for preallocation

TrialOptions = [1 6];
TrialTypes_temp = randi(2,1,MaxTrials);
TrialTypes = TrialOptions(TrialTypes_temp);

%--- Define parameters and trial structure
S = BpodSystem.ProtocolSettings; % Loads settings file chosen in launch manager into current workspace as a struct called 'S'
if isempty(fieldnames(S))  % If chosen settings file was an empty struct, populate struct with default settings
    % Define default settings here as fields of S (i.e S.InitialDelay = 3.2)
    % Note: Any parameters in S.GUI will be shown in UI edit boxes.
    % See ParameterGUI plugin documentation to show parameters as other UI types (listboxes, checkboxes, buttons, text)
    %     S.GUI = struct;
    
    S.GUI.TrainingLevel = 4;
    S.GUI.SamplingDuration = 0.5;
    S.GUI.TasteLeft =1; %Taste1;
    S.GUI.TasteRight = 2;%Taste2;
    S.GUI.DelayDuration = 1;
    S.GUI.TastantAmount = 0.05;
    S.GUI.MotorTime = 0.5;
    S.GUI.Up        = 14;
    S.GUI.Down      =   5;
    S.GUI.Forward        = 14;
    S.GUI.ResponseTime =8; %10;
    S.GUI.DrinkTime = 3;
    S.GUI.RewardAmount = 5; % in ul
    S.GUI.PunishTimeoutDuration =5; %10;
    S.GUI.AspirationTime = 1; 
    S.GUI.ITI = 10;
    S.Stim_Time1 = 1;
    S.Stim_Time2 = 2;


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
A.scope;
A.scope_StartStop;

% Setting the seriers messages for opening the odor valve
% valve 8 is the vacumm; valve 1 is odor 1; valve 2 is odor 2
LoadSerialMessages('ValveModule2', {['O' 1],['C' 1],['O' 2],['C' 2],...
    ['O' 3],['C' 3],['O' 4],['C' 4],['O' 5],['C' 5],['O' 6],['C' 6],...
    ['O' 7],['C' 7],['O' 8],['C' 8]});

for j = 1:20
    MaxTrials = 24; 
    TrialOptions = [1 2];
    TrialTypes_temp = randi(2,1,MaxTrials);
    TrialTypes = TrialOptions(TrialTypes_temp);
    opto_temp{j} = zeros(3,24);

    for i= 4:length(TrialTypes)
        if TrialTypes(i-1) == TrialTypes(i-2) && TrialTypes(i-2) == TrialTypes(i-3)
            if TrialTypes(i-1) ==1
               TrialTypes(i) =2;
            else
               TrialTypes(i) =1; 
            end
        end
    end


   l_idx = find(TrialTypes==1);
   r_idx = find(TrialTypes==2);

   l_opto_idx = randperm(sum(TrialTypes==1),4);
   r_opto_idx = randperm(sum(TrialTypes==2),4);

   l_opto_f = l_idx(l_opto_idx);
   r_opto_f = r_idx(r_opto_idx);

   opto_temp{j}(1,:)=TrialTypes;
   opto_temp{j}(2,r_opto_f)=1;
   opto_temp{j}(2,l_opto_f)=1;

   % pick 2 left and 2 right  for early/late

   r_opto_early_idx = randperm(4,2);
   l_opto_early_idx = randperm(4,2);
   r_opto_late_idx = ~ismember(1:4,r_opto_early_idx);
   l_opto_late_idx = ~ismember(1:4,l_opto_early_idx);

   opto_temp{j}(3,l_opto_f(l_opto_early_idx)) = 1;
   opto_temp{j}(3,r_opto_f(r_opto_early_idx)) = 1;
   opto_temp{j}(3,l_opto_f(l_opto_late_idx)) = 2;
   opto_temp{j}(3,r_opto_f(r_opto_late_idx)) = 2;

end

r_opto=horzcat(opto_temp{:});
r_opto(1,r_opto(1,:)==2)=6;

for i= 4:length(r_opto)
    if r_opto(1,i-1) == r_opto(1,i-2) && r_opto(1,i-2) == r_opto(1,i-3)
        if r_opto(1,i-1) ==1
           r_opto(1,i) =6;
        else
           r_opto(1,i) =1; 
        end
    end
end

TrialTypes = r_opto(1,:);


% include the block sequence
%trialseq = [6,6,6,6,1,1];
%TrialTypes = repmat(trialseq,1,500);


%  Initialize plots
BpodSystem.ProtocolFigures.OutcomePlotFig = figure('Position', [200 200 1000 200],'name','Trial type outcome plot', 'numbertitle','off', 'MenuBar', 'none', 'Resize', 'off'); % Create a figure for the outcome plot
BpodSystem.GUIHandles.OutcomePlot = axes('Position', [.075 .3 .89 .6]); % Create axes for the trial type outcome plot
TrialTypeOutcomePlot(BpodSystem.GUIHandles.OutcomePlot,'init',TrialTypes);

%--- Initialize plots and start USB connections to any modules
BpodParameterGUI('init', S); % Initialize parameter GUI plugin

BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_MoveZaber';
%% Opto params

W = BpodWavePlayer('COM10');
samples = W.SamplingRate;
total_duration1 = S.Stim_Time1;
total_duration2 = S.Stim_Time2;

pulse_volts = 5;%[5 5 5 5];
pulse_duration = 0.00076;%[0.00025 0.00035 0.00054 0.00076];
interpulse_interval =  0.00024;%[0.00075 0.00065 0.00046 0.00024];
train1 = create_pulsetrain(pulse_volts, pulse_duration, interpulse_interval, total_duration1, samples);
train2 = create_pulsetrain(pulse_volts, pulse_duration, interpulse_interval, total_duration2, samples);
W.loadWaveform(1, train1);
W.loadWaveform(2, train2);

LoadSerialMessages('WavePlayer1', {['P' 3 0], ['P' 3 1] ['P' 3 2], ['P' 3 3]});
W.OutputRange = '0V:5V';
W.TriggerMode = 'Master';

%% Opto Params 40hz
%{
W = BpodWavePlayer('COM10');
samples = W.SamplingRate;
total_duration = 7;
pulse_volts = 5;%[5 5 5 5];0.00076 0.00024 % 0.00095 0.00005
pulse_duration = 0.0125;%[0.00025 0.00035 0.00054 0.00076];
interpulse_interval =  0.0125;%[0.00075 0.00065 0.00046 0.00024];
train1 = create_pulsetrain(pulse_volts, pulse_duration, interpulse_interval, total_duration, samples);

total_duration = 0.1;
pulse_volts = 4;%[5 5 5 5];0.00076 0.00024 % 0.00095 0.00005
pulse_duration = 0.0125;%[0.00025 0.00035 0.00054 0.00076];
interpulse_interval =  0.0125;%[0.00075 0.00065 0.00046 0.00024];
train2 = create_pulsetrain(pulse_volts, pulse_duration, interpulse_interval, total_duration, samples);

total_duration = 0.1;
pulse_volts = 3.25;%[5 5 5 5];0.00076 0.00024 % 0.00095 0.00005
pulse_duration = 0.0125;%[0.00025 0.00035 0.00054 0.00076];
interpulse_interval =  0.0125;%[0.00075 0.00065 0.00046 0.00024];
train3 = create_pulsetrain(pulse_volts, pulse_duration, interpulse_interval, total_duration, samples);

total_duration = 0.1;
pulse_volts = 3;%[5 5 5 5];0.00076 0.00024 % 0.00095 0.00005
pulse_duration = 0.0125;%[0.00025 0.00035 0.00054 0.00076];
interpulse_interval =  0.0125;%[0.00075 0.00065 0.00046 0.00024];
train4 = create_pulsetrain(pulse_volts, pulse_duration, interpulse_interval, total_duration, samples);
W.loadWaveform(1, [train1 train2 train3 train4]);
LoadSerialMessages('WavePlayer1', {['P' 3 0], ['P' 3 1]});
W.OutputRange = '0V:5V';
W.TriggerMode = 'Master';
%}

%% Main loop (runs once per trial)
%% OG TESTING
%{
for currentTrial = 1:500
    disp(['Trial# ' num2str(currentTrial) ' TrialType: ' num2str(TrialTypes(currentTrial))])
    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
    R = GetValveTimes(S.GUI.RewardAmount, [1 2]); LeftValveTime = R(1); RightValveTime = R(2); % Update reward amounts

    blankon = 14;
    blankoff = 13;
    vaccuumon = 16;
    vaccuumoff = 15; 
    preloadtime = 0.5;

    switch TrialTypes(currentTrial)
        case 1  % left trials; delivery of tastant from line 1
            odorvalveID = 1;
            tastevalveID = 1;

            %odorvalvetime = odorvalvetimes(1);

            odoropen = 1; % serial message ['O' 1]
            odorclose = 2; % serial message ['C' 1]

            tastevalvetime = LeftValveTime;
            leftAction = 'Reward'; rightAction = 'Timeout';


        case 6  % right trials; delivery of tastant from line 2
            odorvalveID = 6;
            tastevalveID = 2;

            %odorvalvetime = odorvalvetimes(2);

             odoropen = 11; % serial message ['O' 6]
            odorclose = 12; % serial message ['C' 6]

            tastevalvetime = RightValveTime;
            leftAction = 'Timeout'; rightAction = 'Reward';

    end
    
    % vary ITI
    r = randi([-3 3]);
    ITI_rand = r;

    %OPTO
    if currentTrial==1
        disp(r_opto)
    end
    if r_opto(2,currentTrial)==1
        if r_opto(3,currentTrial)==1
            opto_1 = 'VaccuumOffShort';
            opto_2 = 'LateralSpoutsUp';
            delay_duration = S.GUI.DelayDuration;
        elseif r_opto(3,currentTrial)==2
            opto_1 = 'VaccuumOff';
            opto_2 = 'Opto2On';
            delay_duration = S.GUI.DelayDuration-0.5;
        end
    else
        % non-opto
        opto_1 = 'VaccuumOff';
        opto_2 = 'LateralSpoutsUp';
        delay_duration = S.GUI.DelayDuration;

    end

    %--- Assemble state machine
    sma = NewStateMachine();

    % ---- TRIAL START -----

    sma = AddState(sma,'Name','Initiation',... % Initiation of a new trial with 2 s baseline
        'Timer',2,...
        'StateChangeConditions', {'Tup', 'BlankOff'},...
        'OutputActions',{'BNCState',1});

    % turn off blank
    sma = AddState(sma, 'Name', 'BlankOff', ... %Open specific odor valve
        'Timer', 0,...
        'StateChangeConditions ', {'Tup', 'OdorValveOn'},...
        'OutputActions', {'ValveModule2', blankoff,'BNCState',0}); 

    % open odor valve
    sma = AddState(sma, 'Name', 'OdorValveOn', ... %Open specific odor valve
        'Timer', preloadtime,...
        'StateChangeConditions ', {'Tup', opto_1},...
        'OutputActions', {'ValveModule2', odoropen}); 

    % vaccuum off - ODOR DELIVERED
    sma = AddState(sma, 'Name', 'VaccuumOff', ... 
        'Timer', S.GUI.SamplingDuration,...
        'StateChangeConditions', {'Tup', 'VaccuumOn'},...
        'OutputActions', {'ValveModule2', vaccuumoff});

    % -- IF OPTO 1 --

        % vaccuum off - ODOR DELIVERED - SHORT
        sma = AddState(sma, 'Name', 'VaccuumOffShort', ... 
            'Timer', S.GUI.SamplingDuration-0.25,...
            'StateChangeConditions', {'Tup', 'Opto1On'},...
            'OutputActions', {'ValveModule2', vaccuumoff});
    
        % VACCUUM OFF AND OPTO ON
        sma = AddState(sma, 'Name', 'Opto1On', ... 
            'Timer', 0.25,...
            'StateChangeConditions', {'Tup', 'VaccuumOn'},...
            'OutputActions', {'WavePlayer1',1});

    % -- END OPTO 1 --

    % vaccuum on - ODOR REMOVED
     sma = AddState(sma, 'Name', 'VaccuumOn', ... 
        'Timer', 0,...
        'StateChangeConditions', {'Tup', 'OdorValveOff'},...
        'OutputActions', {'ValveModule2', vaccuumon});

    % close odor valve
    sma = AddState(sma, 'Name', 'OdorValveOff', ...
    'Timer', 0,...
    'StateChangeConditions ', {'Tup', 'BlankOn'},...
    'OutputActions', {'ValveModule2', odorclose});
    
    % open blank valve
    sma = AddState(sma, 'Name', 'BlankOn', ...
    'Timer', 0,...
    'StateChangeConditions ', {'Tup', 'MyDelay'},...
    'OutputActions', {'ValveModule2', blankon});
  
    % delay
    sma = AddState(sma, 'Name', 'MyDelay', ...
    'Timer', delay_duration,...
    'StateChangeConditions', {'Tup', opto_2},...
    'OutputActions', {});
    
    % -- IF OPTO 2 ---
    sma = AddState(sma, 'Name', 'Opto2On', ... 
        'Timer', S.Stim_Time,...
        'StateChangeConditions', {'Tup', 'LateralSpoutsUp'},...
        'OutputActions', {'WavePlayer1',1});
    % -- END OPTO 2 ---

    % lateral up
    sma = AddState(sma, 'Name', 'LateralSpoutsUp', ...
    'Timer', S.GUI.MotorTime,...
    'StateChangeConditions', {'Tup', 'WaitForLateralLicks'},...
    'OutputActions', {'SoftCode', 3});

    % lateral licks
    sma = AddState(sma, 'Name', 'WaitForLateralLicks', ...
        'Timer', S.GUI.ResponseTime,...
        'StateChangeConditions', {'Tup', 'Timeout', 'AnalogIn1_1', leftAction, 'AnalogIn1_2', rightAction},...
        'OutputActions', {});

     sma = AddState(sma, 'Name', 'Reward', ... 
    'Timer', tastevalvetime,...
    'StateChangeConditions', {'Tup', 'Drinking'},...
    'OutputActions', {'ValveState', tastevalveID});

     sma = AddState(sma, 'Name', 'Drinking', ... 
    'Timer', S.GUI.DrinkTime,...
    'StateChangeConditions', {'Tup', 'LateralSpoutsDown'},...
    'OutputActions', {});

     sma = AddState(sma, 'Name', 'LateralSpoutsDown', ... % This example state does nothing, and ends after 0 seconds
    'Timer', S.GUI.MotorTime,...
    'StateChangeConditions', {'Tup', 'ITI'},...
    'OutputActions', {'SoftCode', 4});

     sma = AddState(sma, 'Name', 'Timeout', ...
    'Timer', S.GUI.PunishTimeoutDuration,...
    'StateChangeConditions', {'Tup', 'ITI'},...
    'OutputActions', {'SoftCode', 4});

     sma = AddState(sma, 'Name', 'ITI', ...
    'Timer', S.GUI.ITI+ ITI_rand,...
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
%}

%% longer silencing

for currentTrial = 1:500
    disp(['Trial# ' num2str(currentTrial) ' TrialType: ' num2str(TrialTypes(currentTrial))])
    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
    R = GetValveTimes(S.GUI.RewardAmount, [1 2]); LeftValveTime = R(1); RightValveTime = R(2); % Update reward amounts

    blankon = 14;
    blankoff = 13;
    vaccuumon = 16;
    vaccuumoff = 15; 
    preloadtime = 0.5;

    switch TrialTypes(currentTrial)
        case 1  % left trials; delivery of tastant from line 1
            odorvalveID = 1;
            tastevalveID = 1;

            %odorvalvetime = odorvalvetimes(1);

            odoropen = 1; % serial message ['O' 1]
            odorclose = 2; % serial message ['C' 1]

            tastevalvetime = LeftValveTime;
            leftAction = 'Reward'; rightAction = 'Timeout';


        case 6  % right trials; delivery of tastant from line 2
            odorvalveID = 6;
            tastevalveID = 2;

            %odorvalvetime = odorvalvetimes(2);

             odoropen = 11; % serial message ['O' 6]
            odorclose = 12; % serial message ['C' 6]

            tastevalvetime = RightValveTime;
            leftAction = 'Timeout'; rightAction = 'Reward';

    end
    
    % vary ITI
    r = randi([-3 3]);
    ITI_rand = r;

    %OPTO
    
    if currentTrial==1
        disp(r_opto)
    end
    if r_opto(2,currentTrial)==1
        if r_opto(3,currentTrial)==1
            opto_1 = 'Opto1On';
            opto_2 = 'MyDelay1';
           
        elseif r_opto(3,currentTrial)==2
            opto_1 = 'Opto1On';
            opto_2 = 'MyDelay1';
            %opto_2 = 'Opto2On';
        end
    else
        % non-opto
        opto_1 = 'MyDelay2';
        opto_2 = 'MyDelay1';

    end
    
   % opto_1 = 'Opto1On';
    %opto_2 = 'Opto2On';


    %--- Assemble state machine
    sma = NewStateMachine();

    % ---- TRIAL START -----

    sma = AddState(sma,'Name','Initiation',... % Initiation of a new trial with 2 s baseline
        'Timer',2,...
        'StateChangeConditions', {'Tup', 'OdorValveOn'},...
        'OutputActions',{'BNCState',1});


    % open odor valve
    sma = AddState(sma, 'Name', 'OdorValveOn', ... %Open specific odor valve
        'Timer', 0,...
        'StateChangeConditions ', {'Tup', 'BlankOff'},...
        'OutputActions', {'ValveModule2', odoropen}); 

    % turn off blank
    sma = AddState(sma, 'Name', 'BlankOff', ... %Open specific odor valve
        'Timer', preloadtime,...
        'StateChangeConditions ', {'Tup', 'VaccuumOff'},...
        'OutputActions', {'ValveModule2', blankoff,'BNCState',0}); 

    % -- IF OPTO 1 --
    % VACCUUM OFF AND OPTO ON


        sma = AddState(sma, 'Name', 'VaccuumOff', ... 
        'Timer', S.GUI.SamplingDuration,...
        'StateChangeConditions', {'Tup', 'VaccuumOn'},...
        'OutputActions', {'ValveModule2', vaccuumoff});



    % vaccuum on - ODOR REMOVED
     sma = AddState(sma, 'Name', 'VaccuumOn', ... 
        'Timer', 0,...
        'StateChangeConditions', {'Tup', 'OdorValveOff'},...
        'OutputActions', {'ValveModule2', vaccuumon});

    % close odor valve
        sma = AddState(sma, 'Name', 'OdorValveOff', ...
        'Timer', 0,...
        'StateChangeConditions ', {'Tup', 'BlankOn'},...
        'OutputActions', {'ValveModule2', odorclose});

    % open blank valve
    sma = AddState(sma, 'Name', 'BlankOn', ...
    'Timer', 0,...
    'StateChangeConditions ', {'Tup', 'MyDelay1'},...
    'OutputActions', {'ValveModule2', blankon});

     % -- IF OPTO 2 ---
     %{
    sma = AddState(sma, 'Name', 'Opto2On', ... 
        'Timer', 0,...
        'StateChangeConditions', {'Tup', 'MyDelay'},...
        'OutputActions', {'WavePlayer1',2});
     %}
    % -- END OPTO 2 ---


    % delay
    sma = AddState(sma, 'Name', 'MyDelay1', ...
    'Timer', 0.5,...
    'StateChangeConditions', {'Tup', opto_1},...
    'OutputActions', {});
    
    % delay
    sma = AddState(sma, 'Name', 'Opto1On', ...
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'MyDelay2'},...
    'OutputActions', {'WavePlayer1',1});
    
    % delay
    sma = AddState(sma, 'Name', 'MyDelay2', ...
    'Timer', 0.5,...
    'StateChangeConditions', {'Tup', 'LateralSpoutsUp'},...
    'OutputActions', {});
    
    % lateral up
    sma = AddState(sma, 'Name', 'LateralSpoutsUp', ...
    'Timer', S.GUI.MotorTime,...
    'StateChangeConditions', {'Tup', 'WaitForLateralLicks'},...
    'OutputActions', {'SoftCode', 3});

    % lateral licks
    sma = AddState(sma, 'Name', 'WaitForLateralLicks', ...
        'Timer', S.GUI.ResponseTime,...
        'StateChangeConditions', {'Tup', 'Timeout', 'AnalogIn1_1', leftAction, 'AnalogIn1_2', rightAction},...
        'OutputActions', {});

     sma = AddState(sma, 'Name', 'Reward', ... 
    'Timer', tastevalvetime,...
    'StateChangeConditions', {'Tup', 'Drinking'},...
    'OutputActions', {'ValveState', tastevalveID});

     sma = AddState(sma, 'Name', 'Drinking', ... 
    'Timer', S.GUI.DrinkTime,...
    'StateChangeConditions', {'Tup', 'LateralSpoutsDown'},...
    'OutputActions', {});

     sma = AddState(sma, 'Name', 'LateralSpoutsDown', ... % This example state does nothing, and ends after 0 seconds
    'Timer', S.GUI.MotorTime,...
    'StateChangeConditions', {'Tup', 'ITI'},...
    'OutputActions', {'SoftCode', 4});

     sma = AddState(sma, 'Name', 'Timeout', ...
    'Timer', S.GUI.PunishTimeoutDuration,...
    'StateChangeConditions', {'Tup', 'ITI'},...
    'OutputActions', {'SoftCode', 4});

     sma = AddState(sma, 'Name', 'ITI', ...
    'Timer', S.GUI.ITI+ ITI_rand,...
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
   
    Outcomes = zeros(1,BpodSystem.Data.nTrials); %Use for graph
    Outcomes2 = zeros(1,BpodSystem.Data.nTrials); %Populate for cumsum plot
    first_lick_L =  zeros(1,BpodSystem.Data.nTrials);
    first_lick_R =  zeros(1,BpodSystem.Data.nTrials);
    R_count = zeros(1,BpodSystem.Data.nTrials);
    L_count = zeros(1,BpodSystem.Data.nTrials);
    R_correct = zeros(1,BpodSystem.Data.nTrials);
    L_correct = zeros(1,BpodSystem.Data.nTrials);

    for x = 1:BpodSystem.Data.nTrials
        aa = BpodSystem.Data.RawEvents.Trial{x}.Events;

        if BpodSystem.Data.TrialSequence(x) ==1
            L_count(x)=1;
        elseif BpodSystem.Data.TrialSequence(x) ==2
            R_count(x)=1;
        end

        if isfield(aa, 'AnalogIn1_1')
            first_lick_L(x) = aa.AnalogIn1_1(1);
        elseif isfield(aa, 'AnalogIn1_2')
            first_lick_R(x) = aa.AnalogIn1_2(1);
        end

        if ~isnan(BpodSystem.Data.RawEvents.Trial{x}.States.Reward(1))
            if BpodSystem.Data.TrialSequence(x) ==1
                L_correct(x)=1;
            elseif BpodSystem.Data.TrialSequence(x) ==2
                R_correct(x)=1;
            end

            if isfield(aa, 'AnalogIn1_1') && isfield(aa, 'AnalogIn1_2')
                Outcomes(x) = 2; %If correct w both licks, mark as green open
                Outcomes2(x) = 1;
            else
                Outcomes(x) = 1; %If correct, mark as green
                Outcomes2(x) = 1;
            end
        elseif isfield(aa, 'AnalogIn1_1')
            Outcomes(x) = 0; %If response, but wrong, mark as red
            Outcomes2(x) = 0;
        elseif isfield(aa, 'AnalogIn1_2')
            Outcomes(x) = 0; %If response, but wrong, mark as red
            Outcomes2(x) = 0;
        elseif ~isnan(BpodSystem.Data.RawEvents.Trial{x}.States.Timeout(1))
            Outcomes(x) = -1; %If no lateral response, mark as red open circle
            Outcomes2(x) = NaN; %0;
        end
        
    end
    
    TrialTypeOutcomePlotModified(BpodSystem.GUIHandles.OutcomePlot,'update',BpodSystem.Data.nTrials+1,TrialTypes,Outcomes)
    
    %figure(100);
    %plot(nancumsum(Outcomes2)./([1:length(Outcomes2)]),'-o','Color','#ad6bd3','MarkerFaceColor','#ad6bd3')
    %xlabel('Trial #','fontsize',16);ylabel('Performance','fontsize',16); title(['Performance for Training ' num2str(S.GUI.TrainingLevel)],'fontsize',20)
    %grid on

figure(101); 
    plot(cumsum(R_correct)./(cumsum(R_count)),'-o');hold on;
    plot(nancumsum(Outcomes2)./([1:length(Outcomes2)]),'-o','Color','#ad6bd3','MarkerFaceColor','#ad6bd3');
    plot(cumsum(L_correct)./(cumsum(L_count)),'-o'); hold off;

    xlabel('Trial #','fontsize',16);ylabel('Performance','fontsize',16); title(['Performance for Training ' num2str(S.GUI.TrainingLevel)],'fontsize',20)
    grid on
        
    figure(102);
    plot(first_lick_R','-o'); hold on;
    plot(first_lick_L','-o'); hold off;
    xlabel('Trial #','fontsize',16);ylabel('Time to lick (s)','fontsize',16); title(['Lick time ' num2str(S.GUI.TrainingLevel)],'fontsize',20)
    legend('right','left');
    grid on

  

end
