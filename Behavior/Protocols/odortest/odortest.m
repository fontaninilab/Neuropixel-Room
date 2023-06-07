function odortest      
global BpodSystem

%% Setup (runs once before the first trial)
MaxTrials = 20; % Set to some sane value, for preallocation

TrialTypes = ceil(rand(1,MaxTrials)*2);

vacuumvalveID = 8;
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
    
    S.GUI.TrainingLevel = 1;
    S.GUI.SamplingDuration = 10;
    S.GUI.TasteLeft =1; %Taste1;
    S.GUI.TasteRight = 2;%Taste2;
    S.GUI.DelayDuration = 15;
    S.GUI.TastantAmount = 0.05;
    S.GUI.MotorTime = 0.5;
    S.GUI.Up        = 14;
    S.GUI.Down      =   5;
    S.GUI.ResponseTime =1; %10;
    S.GUI.DrinkTime = 2;
    S.GUI.RewardAmount = 3; % in ul
    S.GUI.PunishTimeoutDuration =1; %10;
    S.GUI.AspirationTime = 1; 
    S.GUI.ITI = 1; %10;
    
end
% set the threshold for the analog input signal to detect events
A = BpodAnalogIn('COM6');

A.nActiveChannels = 8;
A.InputRange = {'-5V:5V',  '-5V:5V',  '-5V:5V',  '-5V:5V',  '-10V:10V', '-10V:10V',  '-10V:10V',  '-10V:10V'};

%---Thresholds for optical detectors---
A.Thresholds = [1 1 1 2 2 2 2 2];
A.ResetVoltages = [0.1 0.1 0.1 1.5 1.5 1.5 1.5 1.5]; %Should be at or slightly above baseline (check oscilloscope)
%--------------------------------------

A.SMeventsEnabled = [1 1 1 0 0 0 0 0];
A.startReportingEvents();

% Setting the seriers messages for opening the odor valve
% valve 8 is the vacumm; valve 1 is odor 1; valve 2 is odor 2
LoadSerialMessages('ValveModule2', {['O' 1], ['C' 1],['O' 2], ['C' 2]});
LoadSerialMessages('ValveModule3', {['O' 8], ['C' 8]});

% include the block sequence
if S.GUI.TrainingLevel ~=4
    trialseq = [1,1,1];
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
%{
BpodSystem.ProtocolFigures.OutcomePlotFig = figure('Position', [200 200 1000 200],'name','Trial type outcome plot', 'numbertitle','off', 'MenuBar', 'none', 'Resize', 'off'); % Create a figure for the outcome plot
BpodSystem.GUIHandles.OutcomePlot = axes('Position', [.075 .3 .89 .6]); % Create axes for the trial type outcome plot
TrialTypeOutcomePlot(BpodSystem.GUIHandles.OutcomePlot,'init',TrialTypes);
%}
%--- Initialize plots and start USB connections to any modules
BpodParameterGUI('init', S); % Initialize parameter GUI plugin

BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_MoveZaber';

odorvalvetimes = [10 10]; % only for initial odor pre-loading (not sample time)

%% Main loop (runs once per trial)
vacuumofftime = zeros(MaxTrials,6);
odoropentime = zeros(MaxTrials,6);
vacuumontime = zeros(MaxTrials,6);
odorclosetime = zeros(MaxTrials,6);

%matlabStartTime = now;
%BpodSystem.SerialPort.write('*', 'uint8'); % Reset bpod session clock
%Confirmed = obj.SerialPort.read(1,'uint8');
%if Confirmed ~= 1
%    error('Error: confirm not returned after resetting session clock.')
%end

for currentTrial = 1:MaxTrials
    disp(['Trial# ' num2str(currentTrial) ' TrialType: ' num2str(TrialTypes(currentTrial))])
    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
    R = GetValveTimes(S.GUI.RewardAmount, [1 2]); LeftValveTime = R(1); RightValveTime = R(2); % Update reward amounts

    vacuumon = 2;
    vacuumoff = 1;

    switch TrialTypes(currentTrial)
        case 1  % left trials; delivery of tastant from line 1
            odorvalveID = odor1valveID;
            tastevalveID = taste1valveID;

            odorvalvetime = odorvalvetimes(1);

            odoropen = 1; % serial message ['O' 1]
            odorclose = 2; % serial message ['C' 1]

            tastevalvetime = LeftValveTime;


        case 2  % right trials; delivery of tastant from line 2
            odorvalveID = odor2valveID;
            tastevalveID = taste2valveID;

            odorvalvetime = odorvalvetimes(2);

            odoropen = 3; % serial message ['O' 2]
            odorclose = 4; % serial message ['C' 2]

            tastevalvetime = RightValveTime;

    end

    leftAction = 'Reward'; 
    rightAction = 'Reward'; 

    %--- Assemble state machine
    sma = NewStateMachine();

    % ---- TRIAL START -----
    sma = AddState(sma, 'Name', 'OdorValveOn', ... %Open specific odor valve
        'Timer', odorvalvetime,...
        'StateChangeConditions ', {'Tup', 'vacuumOff'},...
        'OutputActions', {'ValveModule2', odoropen}); 

    sma = AddState(sma, 'Name', 'vacuumOff', ... 
        'Timer', S.GUI.SamplingDuration,...
        'StateChangeConditions', {'Tup', 'vacuumOn'},...
        'OutputActions', {'ValveModule3', vacuumoff});

    sma = AddState(sma, 'Name', 'vacuumOn', ... 
    'Timer', 10,...
    'StateChangeConditions', {'Tup', 'OdorValveOff'},...
    'OutputActions', {'ValveModule3', vacuumon});

    % close nitrogen valve
    sma = AddState(sma, 'Name', 'OdorValveOff', ... 
    'Timer', 10,...
    'StateChangeConditions ', {'Tup', 'MyDelay'},...
    'OutputActions', {'ValveModule2', odorclose});

    sma = AddState(sma, 'Name', 'MyDelay', ...
    'Timer', S.GUI.DelayDuration,...
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
        return
    end

    %{
    Outcomes = zeros(1,BpodSystem.Data.nTrials); %Use for graph
    Outcomes2 = zeros(1,BpodSystem.Data.nTrials); %Populate for cumsum plot
    for x = 1:BpodSystem.Data.nTrials
        aa = BpodSystem.Data.RawEvents.Trial{x}.Events;
        if ~isnan(BpodSystem.Data.RawEvents.Trial{x}.States.Reward(1))
            Outcomes(x) = 1; %If correct, mark as green
            Outcomes2(x) = 1;
            trialcounts(x) = 1;
        elseif isfield(aa, 'AnalogIn1_1') || isfield(aa, 'AnalogIn1_2')
            Outcomes(x) = 0; %If response, but wrong, mark as red
            Outcomes2(x) = 0;
            trialcounts(x) = 1;
        elseif ~isnan(BpodSystem.Data.RawEvents.Trial{x}.States.Timeout(1))
            Outcomes(x) = -1; %If no lateral response, mark as red open circle
            Outcomes2(x) = NaN; %0;
            trialcounts(x) = NaN;
        end      
    end
    
    TrialTypeOutcomePlotModified(BpodSystem.GUIHandles.OutcomePlot,'update',BpodSystem.Data.nTrials+1,TrialTypes,Outcomes)
    
    figure(100);
    plot(cumsum(Outcomes2)./([1:length(Outcomes2)]),'-o','Color','#ad6bd3','MarkerFaceColor','#ad6bd3')
    xlabel('Trial #','fontsize',16);ylabel('Performance','fontsize',16); title(['Performance for Training ' num2str(S.GUI.TrainingLevel)],'fontsize',20)
    grid on
    %}
end