function Odor2AC_testing_opto     
global BpodSystem
global port;
port=serialport('COM9', 115200,"DataBits",8,FlowControl="none",Parity="none",StopBits=1,Timeout=0.5);
setDTR(port,true);
configureTerminator(port,"CR/LF");
fopen(port); %line 2-5 added 6/6/23 to control motor
%% Setup (runs once before the first trial)
MaxTrials = 1000; % Set to some sane value, for preallocation

TrialTypes = ceil(rand(1,MaxTrials)*2);

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
    S.GUI.ResponseTime = 8; %10;
    S.GUI.DrinkTime = 3;
    S.GUI.RewardAmount = 5; % in ul
    S.GUI.PunishTimeoutDuration =6; %10;
    S.GUI.AspirationTime = 1; 
    S.GUI.ITI = 10;

    S.Stim_Time = 0.5; 
    S.train = 0;
    S.pulse_volts = 0;
    S.pulse_duration = 0; 
    S.interpulse_interval = 0;
    
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
%A.scope;
%A.scope_StartStop;

% Setting the seriers messages for opening the odor valve
% valve 8 is the vacumm; valve 1 is odor 1; valve 2 is odor 2
LoadSerialMessages('ValveModule2', {['O' 1], ['C' 1],['O' 2], ['C' 2],['O' 8], ['C' 8], ['O' 5], ['C' 5]});

% include the block sequence
if S.GUI.TrainingLevel ~=4
    trialseq = [2,2];
    TrialTypes = repmat(trialseq,1,500);
else
    %break the random sequence into pseudo random (no more than 3 smae trial type in a row)
    for i= 1:length(TrialTypes)
        if i>3
            if TrialTypes(i-1) == TrialTypes(i-2) && TrialTypes(i-2) == TrialTypes(i-3)
                if TrialTypes(i-1) ==1
                   TrialTypes(i) =2;
                else
                   TrialTypes(i) =1; 
                end
            end
        end
    end
    
end

%  Initialize plots
BpodSystem.ProtocolFigures.OutcomePlotFig = figure('Position', [200 200 1000 200],'name','Trial type outcome plot', 'numbertitle','off', 'MenuBar', 'none', 'Resize', 'off'); % Create a figure for the outcome plot
BpodSystem.GUIHandles.OutcomePlot = axes('Position', [.075 .3 .89 .6]); % Create axes for the trial type outcome plot
TrialTypeOutcomePlot(BpodSystem.GUIHandles.OutcomePlot,'init',TrialTypes);

%--- Initialize plots and start USB connections to any modules
BpodParameterGUI('init', S); % Initialize parameter GUI plugin

BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_MoveZaber';

odorvalvetimes = [1 1];

%% Opto params
W = BpodWavePlayer('COM10');
samples = W.SamplingRate;
total_duration = S.Stim_Time;
pulse_volts = 5;%[5 5 5 5];
pulse_duration = 0.00085;%[0.00025 0.00035 0.00054 0.00076];
interpulse_interval =  0.00015;%[0.00075 0.00065 0.00046 0.00024];
train = create_pulsetrain(pulse_volts, pulse_duration, interpulse_interval, total_duration, samples);
W.loadWaveform(1, train);
LoadSerialMessages('WavePlayer1', {['P' 3 0], ['P' 3 1]});
W.OutputRange = '0V:5V';
W.TriggerMode = 'Master';
%%
for i = 1:5
    r_opto_temp{i} = zeros(3,20);
    r_opto_temp{i}(1,:) = sort(randperm(60,20))+(60*(i-1));
    r_opto_temp{i}(2,:) = TrialTypes(r_opto_temp{i}(1,:));

    total_trials = 1:60;

    if sum(r_opto_temp{i}(2,:)==2) > 10
        possible_new = total_trials(~ismember(total_trials,r_opto_temp{i}(1,:)));
        possible_new = possible_new(TrialTypes(possible_new)==1);
        num_change = sum(r_opto_temp{i}(2,:)==2)-10;
        idx_change = randperm(10+num_change,num_change);
        idx_2 = r_opto_temp{i}(1,r_opto_temp{i}(2,:)==2);
        idx_to_change = ismember(r_opto_temp{i}(1,:),idx_2(idx_change));
        idx_new = randperm(length(possible_new),num_change);
        r_opto_temp{i}(1,idx_to_change)=possible_new(idx_new);
        r_opto_temp{i}(2,idx_to_change)=1;
    end
    
    if sum(r_opto_temp{i}(2,:)==2) < 10
        possible_new = total_trials(~ismember(total_trials,r_opto_temp{i}(1,:)));
        possible_new = possible_new(TrialTypes(possible_new)==2);
        num_change = sum(r_opto_temp{i}(2,:)==1)-10;
        idx_change = randperm(10+num_change,num_change);
        idx_2 = r_opto_temp{i}(1,r_opto_temp{i}(2,:)==1);
        idx_to_change = ismember(r_opto_temp{i}(1,:),idx_2(idx_change));
        idx_new = randperm(length(possible_new),num_change);
        r_opto_temp{i}(1,idx_to_change)=possible_new(idx_new);
        r_opto_temp{i}(2,idx_to_change)=2;
    end
    stimtimes=1:10;
    first_stim_R = randperm(10,5);
    last_stim_R = ~ismember(stimtimes,first_stim_R);
    r_opto_R = r_opto_temp{i}(:,r_opto_temp{i}(2,:)==2);
    r_opto_temp{i}(3,ismember(r_opto_temp{i}(1,:),r_opto_R(1,first_stim_R)))=1;
    r_opto_temp{i}(3,ismember(r_opto_temp{i}(1,:),r_opto_R(1,last_stim_R)))=2;
    
    first_stim_L = randperm(10,5);
    last_stim_L = ~ismember(stimtimes,first_stim_L);
    r_opto_L = r_opto_temp{i}(:,r_opto_temp{i}(2,:)==1);
    r_opto_temp{i}(3,ismember(r_opto_temp{i}(1,:),r_opto_L(1,first_stim_L)))=1;
    r_opto_temp{i}(3,ismember(r_opto_temp{i}(1,:),r_opto_L(1,last_stim_L)))=2;
end

r_opto=horzcat(r_opto_temp{:});
[C,IA,IC] = unique(r_opto(1,:));
r_opto=r_opto(:,IA);
exl_early = r_opto(1,:)>4;
r_opto=r_opto(:,exl_early);
% sanity
%{
 sum(r_opto(2,:)==2)
 sum(r_opto(3,:)==2)
  sum(r_opto(2,:)==1)
 sum(r_opto(3,:)==1)

  sum(r_opto(2,:)==1 & r_opto(3,:)==1)
  sum(r_opto(2,:)==1 & r_opto(3,:)==2)
  sum(r_opto(2,:)==2 & r_opto(3,:)==1)
    sum(r_opto(2,:)==2 & r_opto(3,:)==2)
%}
%disp(r_opto);
S.Opto_trials        = r_opto;

%% Main loop (runs once per trial)

for currentTrial = 1:MaxTrials
    disp(['Trial# ' num2str(currentTrial) ' TrialType: ' num2str(TrialTypes(currentTrial))])
    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
    R = GetValveTimes(S.GUI.RewardAmount, [1 2]); LeftValveTime = R(1); RightValveTime = R(2); % Update reward amounts

    vaccuumon = 6;
    vaccuumoff = 5;
    blankoff = 7;
    blankon = 8;

    switch TrialTypes(currentTrial)
        case 1  % left trials; delivery of tastant from line 1
            odorvalveID = odor1valveID;
            tastevalveID = taste1valveID;

            odorvalvetime = odorvalvetimes(1);

            odoropen = 1; % serial message ['O' 1]
            odorclose = 2; % serial message ['C' 1]

            tastevalvetime = LeftValveTime;
            leftAction = 'Reward'; rightAction = 'Timeout';


        case 2  % right trials; delivery of tastant from line 2
            odorvalveID = odor2valveID;
            tastevalveID = taste2valveID;

            odorvalvetime = odorvalvetimes(2);

            odoropen = 3; % serial message ['O' 2]
            odorclose = 4; % serial message ['C' 2]

            tastevalvetime = RightValveTime;
            leftAction = 'Timeout'; rightAction = 'Reward';

    end
    
    % vary ITI
    r = randi([-3 3]);
    ITI_rand = r;

    %OPTO
    if ismember(currentTrial,r_opto(1,:))
       
        if r_opto(3,r_opto(1,:)==currentTrial)==1
            opto_1 = 'VaccuumOffShort';
            opto_2 = 'LateralSpoutsUp';
           delay_duration = S.GUI.DelayDuration;

        end
        if r_opto(3,r_opto(1,:)==currentTrial)==2
            opto_1 = 'VaccuumOff';
            opto_2 = 'Opto2On';
            delay_duration = S.GUI.DelayDuration-0.5;

        end
    else
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
        'Timer', odorvalvetime,...
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
    'Timer', S.GUI.ITI,... %+ ITI_rand,...
    'StateChangeConditions', {'Tup', '>exit'},...
    'OutputActions', {});


    %{
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
        'Timer', odorvalvetime,...
        'StateChangeConditions ', {'Tup', 'VaccuumOff'},...
        'OutputActions', {'ValveModule2', odoropen}); 

    % vaccuum off - ODOR DELIVERED
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
    
    %OPTO
    if ismember(currentTrial,r_opto(1,:))
        delay_duration =  S.GUI.DelayDuration-0.5;

        if r_opto(3,r_opto(1,:)==currentTrial)==1
            opto_1 = 'Opto1';
            opto_2 = 'LateralSpoutsUp';
        end
        if r_opto(3,r_opto(1,:)==currentTrial)==2
            opto_1 = 'MyDelay';
            opto_2 = 'Opto2';
        end
    else
        delay_duration =  S.GUI.DelayDuration;
        opto_1 = 'MyDelay';
        opto_2 = 'LateralSpoutsUp';

    end

    % open blank valve
    sma = AddState(sma, 'Name', 'BlankOn', ...
    'Timer', 0,...
    'StateChangeConditions ', {'Tup', opto_1},...
    'OutputActions', {'ValveModule2', blankon});

    % OPTO 1
        sma = AddState(sma, 'Name', 'Opto1', ... 
            'Timer', S.Stim_Time,...
            'StateChangeConditions', {'Tup', 'MyDelay'},...
            'OutputActions', {'WavePlayer1',1});

    % delay
    sma = AddState(sma, 'Name', 'MyDelay', ...
    'Timer', delay_duration,...
    'StateChangeConditions', {'Tup', opto_2},...
    'OutputActions', {});

    % OPTO 2
    sma = AddState(sma, 'Name', 'Opto2', ... 
            'Timer', S.Stim_Time,...
            'StateChangeConditions', {'Tup', 'LateralSpoutsUp'},...
            'OutputActions', {'WavePlayer1',1});

    
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
    'Timer', S.GUI.ITI,... %+ ITI_rand,...
    'StateChangeConditions', {'Tup', '>exit'},...
    'OutputActions', {});
    %}


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