function Odor2AC_Training2_water_rewards      
global BpodSystem
global port;
port=serialport('COM9', 115200,"DataBits",8,FlowControl="none",Parity="none",StopBits=1,Timeout=0.5);
setDTR(port,true);
configureTerminator(port,"CR/LF");
fopen(port); %line 2-5 added 6/6/23 to control motor
%% Setup (runs once before the first trial)
MaxTrials = 1000; % Set to some sane value, for preallocation

TrialTypes = ceil(rand(1,MaxTrials)*2);

%--- Define parameters and trial structure
S = BpodSystem.ProtocolSettings; % Loads settings file chosen in launch manager into current workspace as a struct called 'S'
if isempty(fieldnames(S))  % If chosen settings file was an empty struct, populate struct with default settings
    % Define default settings here as fields of S (i.e S.InitialDelay = 3.2)
    % Note: Any parameters in S.GUI will be shown in UI edit boxes.
    % See ParameterGUI plugin documentation to show parameters as other UI types (listboxes, checkboxes, buttons, text)
    %     S.GUI = struct;
    
    S.GUI.TrainingLevel = 1;
    S.GUI.SamplingDuration = 0.5;
    S.GUI.TasteLeft =1; %Taste1;
    S.GUI.TasteRight = 2;%Taste2;
    S.GUI.DelayDuration = 1;
    S.GUI.TastantAmount = 0.05;
    S.GUI.MotorTime = 0.5;
    S.GUI.Up        = 14;
    S.GUI.Down      =   5;
    S.GUI.Forward        = 14;
    S.GUI.ResponseTime = 15; %10;
    S.GUI.DrinkTime = 3;
    S.GUI.RewardAmount = 5; % in ul
    S.GUI.PunishTimeoutDuration = 5; %10;
    S.GUI.AspirationTime = 1; 
    S.GUI.ITI = 8; %10;
    
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

% include the block sequence
trialseq = [1,1,1, 6,6,6];
TrialTypes = repmat(trialseq,1,500);


%  Initialize plots
%BpodSystem.ProtocolFigures.OutcomePlotFig = figure('Position', [200 200 1000 200],'name','Trial type outcome plot', 'numbertitle','off', 'MenuBar', 'none', 'Resize', 'off'); % Create a figure for the outcome plot
%BpodSystem.GUIHandles.OutcomePlot = axes('Position', [.075 .3 .89 .6]); % Create axes for the trial type outcome plot

%PerformancePlot('init', [6 1],{'R','L'},1);

outcomePlot = LiveOutcomePlot([1 6], {'Left [1]','','','','','Right [6]'}, TrialTypes,90);
outcomePlot.RewardStateNames = {'Reward'};
outcomePlot.ErrorStateNames = {'Timeout'};

%--- Initialize plots and start USB connections to any modules
BpodParameterGUI('init', S); % Initialize parameter GUI plugin

BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_MoveZaber';

%% Main loop (runs once per trial)

for currentTrial = 1:MaxTrials
    disp(['Trial# ' num2str(currentTrial) ' TrialType: ' num2str(TrialTypes(currentTrial))])
    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
    R = GetValveTimes(S.GUI.RewardAmount, [1 2 3 4]); LeftValveTime = R(1); RightValveTime = R(2); % Update reward amounts
    disp(R)
    blankon = 14;
    blankoff = 13;
    vacon = 16;
    vacoff = 15; 
    preloadtime = 0.5;

    switch TrialTypes(currentTrial)
        case 1  % left trials; delivery of tastant from line 1
            odorvalveID = 1;
            tastevalveID = 1;

            odoropen = 1; % serial message ['O' 1]
            odorclose = 2; % serial message ['C' 1]

            tastevalvetime = LeftValveTime;

        case 6  % right trials; delivery of tastant from line 2
            odorvalveID = 6;
            tastevalveID = 2;

            odoropen = 11; % serial message ['O' 6]
            odorclose = 12; % serial message ['C' 6]

            tastevalvetime = RightValveTime;
    end
  
    leftAction = 'Reward'; rightAction = 'Reward';

    %--- Assemble state machine
    sma = NewStateMachine();

    % ---- TRIAL START -----

    sma = AddState(sma,'Name','Initiation',... % Initiation of a new trial with 2 s baseline
        'Timer',0,...
        'StateChangeConditions', {'Tup', 'BlankOff'},...
        'OutputActions',{});

    % turn off blank
    sma = AddState(sma, 'Name', 'BlankOff', ... %Open specific odor valve
        'Timer', 0,...
        'StateChangeConditions ', {'Tup', 'OdorValveOn'},...
        'OutputActions', {'ValveModule2', blankoff}); 

    % open odor valve
    sma = AddState(sma, 'Name', 'OdorValveOn', ... %Open specific odor valve
        'Timer', preloadtime,...
        'StateChangeConditions ', {'Tup', 'VaccuumOff'},...
        'OutputActions', {'ValveModule2', odoropen}); 

    % vaccuum off - ODOR DELIVERED
    sma = AddState(sma, 'Name', 'VaccuumOff', ... 
        'Timer', S.GUI.SamplingDuration,...
        'StateChangeConditions', {'Tup', 'VaccuumOn'},...
        'OutputActions', {'ValveModule2', vacoff,'BNCState', 1});

    % vaccuum on - ODOR REMOVED
     sma = AddState(sma, 'Name', 'VaccuumOn', ... 
        'Timer', 0,...
        'StateChangeConditions', {'Tup', 'OdorValveOff'},...
        'OutputActions', {'ValveModule2', vacon,'BNCState', 0});

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
    'Timer', S.GUI.DelayDuration,...
    'StateChangeConditions', {'Tup', 'CentralForward'},...
    'OutputActions', {});

    % lateral up
    sma = AddState(sma, 'Name', 'CentralForward', ...
    'Timer', S.GUI.MotorTime,...
    'StateChangeConditions', {'Tup', 'WaitForLateralLicks'},...
    'OutputActions', {'SoftCode', 3});

    % lateral licks
    switch TrialTypes(currentTrial) % with correction

          case 1 % left trials; only see whether animals lick left spout
              sma = AddState(sma, 'Name', 'WaitForLateralLicks', ... 
                  'Timer', S.GUI.ResponseTime,...
                  'StateChangeConditions', {'Tup', 'Timeout', 'AnalogIn1_1', leftAction},...
                  'OutputActions', {});
          case 6
              sma = AddState(sma, 'Name', 'WaitForLateralLicks', ...
                  'Timer', S.GUI.ResponseTime,...
                  'StateChangeConditions', {'Tup', 'Timeout', 'AnalogIn1_2', rightAction},...
                  'OutputActions', {});
     end

     sma = AddState(sma, 'Name', 'Reward', ... 
    'Timer', tastevalvetime,...
    'StateChangeConditions', {'Tup', 'Drinking'},...
    'OutputActions', {'ValveState', tastevalveID});

     sma = AddState(sma, 'Name', 'Drinking', ... 
    'Timer', S.GUI.DrinkTime,...
    'StateChangeConditions', {'Tup', 'CentralBack'},...
    'OutputActions', {});

     sma = AddState(sma, 'Name', 'CentralBack', ... % This example state does nothing, and ends after 0 seconds
    'Timer', S.GUI.MotorTime,...
    'StateChangeConditions', {'Tup', 'ITI'},...
    'OutputActions', {'SoftCode', 4});

     sma = AddState(sma, 'Name', 'Timeout', ...
    'Timer', S.GUI.PunishTimeoutDuration,...
    'StateChangeConditions', {'Tup', 'ITI'},...
    'OutputActions', {'SoftCode', 4});

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

    outcomePlot.update(TrialTypes, BpodSystem.Data);

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
        elseif BpodSystem.Data.TrialSequence(x) ==6
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
            elseif BpodSystem.Data.TrialSequence(x) ==6
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
   
     figure(101); 
    plot(cumsum(R_correct)./(cumsum(R_count)),'-o');hold on;
    plot(cumsum(L_correct)./(cumsum(L_count)),'-o');
    plot(nancumsum(Outcomes2)./([1:length(Outcomes2)]),'-o','Color','#ad6bd3','MarkerFaceColor','#ad6bd3');
    hold off;
    legend({'right','left','cumulative'}, 'Location','northwest');

    xlabel('Trial #','fontsize',16);ylabel('Performance','fontsize',16); title(['Performance for Training ' num2str(S.GUI.TrainingLevel)],'fontsize',20)
    grid on
        
    figure(102);
    plot(first_lick_R','-o'); hold on;
    plot(first_lick_L','-o'); hold off;
    xlabel('Trial #','fontsize',16);ylabel('Time to lick (s)','fontsize',16); title(['Lick time ' num2str(S.GUI.TrainingLevel)],'fontsize',20)
    legend('right','left');
    grid on


 %   performancePlot = PerformancePlot('update', {6 1},5);

    %{
    TrialTypeOutcomePlotModified(BpodSystem.GUIHandles.OutcomePlot,'update',BpodSystem.Data.nTrials+1,TrialTypes,Outcomes)

   
    %}
    %{
    Outcomes = zeros(1,BpodSystem.Data.nTrials); %Use for graph
    Outcomes2 = zeros(1,BpodSystem.Data.nTrials); %Populate for cumsum plot
    for x = 1:BpodSystem.Data.nTrials
        aa = BpodSystem.Data.RawEvents.Trial{x}.Events;

        if ~isnan(BpodSystem.Data.RawEvents.Trial{x}.States.Reward(1))
            if isfield(aa, 'AnalogIn1_1') && isfield(aa, 'AnalogIn1_2')
                Outcomes(x) = 2; %If correct, mark as green
                Outcomes2(x) = 1;
            else
                Outcomes(x) = 1; %If correct, mark as green
                Outcomes2(x) = 1;
            end
        elseif isfield(aa, 'AnalogIn1_1') || isfield(aa, 'AnalogIn1_2')
            Outcomes(x) = 0; %If response, but wrong, mark as red
            Outcomes2(x) = 0;
        elseif ~isnan(BpodSystem.Data.RawEvents.Trial{x}.States.Timeout(1))
            Outcomes(x) = -1; %If no lateral response, mark as red open circle
            Outcomes2(x) = NaN; %0;
        end
        
    end
    
    
    TrialTypeOutcomePlotModified(BpodSystem.GUIHandles.OutcomePlot,'update',BpodSystem.Data.nTrials+1,TrialTypes,Outcomes)
    
    figure(100);
    plot(nancumsum(Outcomes2)./([1:length(Outcomes2)]),'-o','Color','#ad6bd3','MarkerFaceColor','#ad6bd3')
    xlabel('Trial #','fontsize',16);ylabel('Performance','fontsize',16); title(['Performance for Training ' num2str(S.GUI.TrainingLevel)],'fontsize',20)
    grid on
    %}
   % disp(BpodSystem.GUIData)
        %PerformancePlot('update', TrialTypes,Outcomes,BpodSystem.Data.nTrials);


end