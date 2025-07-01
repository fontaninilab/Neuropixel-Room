function Taste2AC_8valves      
global BpodSystem

%% Setup (runs once before the first trial)
MaxTrials = 350; % Set to some sane value, for preallocation

TrialTypes = ceil(rand(1,MaxTrials)*2);


%--- Define parameters and trial structure
S = BpodSystem.ProtocolSettings; % Loads settings file chosen in launch manager into current workspace as a struct called 'S'
if isempty(fieldnames(S))  % If chosen settings file was an empty struct, populate struct with default settings
    % Define default settings here as fields of S (i.e S.InitialDelay = 3.2)
    % Note: Any parameters in S.GUI will be shown in UI edit boxes.
    % See ParameterGUI plugin documentation to show parameters as other UI types (listboxes, checkboxes, buttons, text)
    %     S.GUI = struct;
    
    S.GUI.TrainingLevel = 4;
    S.GUI.SamplingDuration = 3;
    S.GUI.TasteLeft = 'Taste1';
    S.GUI.TasteRight = 'Taste2';
    S.GUI.DelayDuration = 2;
    S.GUI.TastantAmount = 0.05;
    S.GUI.MotorTime = 0.5;
    S.GUI.Up        = 14;
    S.GUI.Down      =   5;
    S.GUI.ResponseTime = 5;
    S.GUI.DrinkTime = 2;
    S.GUI.RewardAmount = 3; % in ul
    S.GUI.PunishTimeoutDuration = 10;
    S.GUI.AspirationTime = 1; 
    S.GUI.ITI = 8; %shorter ITI accounting for the rinse
    
end
% set the threshold for the analog input signal to detect events
A = BpodAnalogIn('COM6');

A.nActiveChannels = 8;
A.InputRange = {'-5V:5V',  '-5V:5V',  '-5V:5V',  '-5V:5V',  '-10V:10V', '-10V:10V',  '-10V:10V',  '-10V:10V'};
A.Thresholds = [-0.5 -0.5 -0.5 2 2 2 2 2];
A.ResetVoltages = [-0.2 -0.2 -0.2 1.5 1.5 1.5 1.5 1.5];
A.SMeventsEnabled = [1 1 1 0 0 0 0 0];
A.startReportingEvents();
% For sound generation
% SF = 50000;
% W = BpodWavePlayer('COM4');
% W.SamplingRate = SF;
% LeftSound = GenerateSineWave(SF, S.GUI.SoundFreqLeft, S.GUI.SoundDuration);
% RightSound = GenerateSineWave(SF, S.GUI.SoundFreqRight, S.GUI.SoundDuration);
% W.loadWaveform(1, LeftSound);
% W.loadWaveform(2, RightSound);
% LoadSerialMessages('WavePlayer1', {['P' 3 0], ['P' 3 1], ['P' 3 2]});

% LightPulseDuration = 10;
% LightWaveform = ones(1, 10*SF)*5;
% W.loadWaveform(2, LightWaveform);

% Setting the seriers messages for opening the odor valve
% valve 1 is the vacumm; valve 2 is odor 1; valve 3 is odor 2
LoadSerialMessages('ValveModule1', {['O' 1], ['C' 1],['O' 2], ['C' 2],['O' 3], ['C' 3], ['O' 4], ['C' 4],['O' 5], ['C' 5],['O' 6], ['C' 6], ['O' 7], ['C' 7], ['O' 8], ['C' 8]});

% include the block sequence
if S.GUI.TrainingLevel ~=4
    trialseq = [1,1,1,2,2,2];
    TrialTypes = repmat(trialseq,1,70);
else
    %break the random sequence into pseudo random (no more than 3 smae trial type in a row)
    for i= 1:length(TrialTypes)
        if i>3
            if TrialTypes(i-1) == TrialTypes(i-2) && TrialTypes(i-2) == TrialTypes(i-3)
                if TrialTypes(i-1) ==1
                   TrialTypes(i) = 2;
                else
                   TrialTypes(i) = 1; 
                end
            end
        end
    end
    
end
% make a ValveSeq array
% make a ValveSeq array
    ValveSeq = TrialTypes;
    for i=1:length(TrialTypes)
        if TrialTypes(i)==2
            ValveSeq(i)=8;
        end
    end  
 
      b=find(TrialTypes(:)==1);
   
    
        %make a repeat permutation of 7 for the sucrose valves
    ValveIdx=zeros(ceil(length(b)/7),7);
        for j=1:ceil(length(b)/7)
    ValveIdx(j,:)=randperm(7);
        end
% concatenating the rows of the matrix TrialIdx into an array
    Valve_Idx=[];
        for j=1:ceil(length(b)/7)
    Valve_Idx=[Valve_Idx ValveIdx(j,:)];
        end
 
    for k=1:length(b)
        ValveSeq(b(k))=Valve_Idx(k); % use the Valve_Idx as the valve number
    
    end
 
%  Initialize plots
BpodSystem.ProtocolFigures.OutcomePlotFig = figure('Position', [200 200 1000 200],'name','Trial type outcome plot', 'numbertitle','off', 'MenuBar', 'none', 'Resize', 'off'); % Create a figure for the outcome plot
BpodSystem.GUIHandles.OutcomePlot = axes('Position', [.075 .3 .89 .6]); % Create axes for the trial type outcome plot
TrialTypeOutcomePlot(BpodSystem.GUIHandles.OutcomePlot,'init',TrialTypes);

%--- Initialize plots and start USB connections to any modules
BpodParameterGUI('init', S); % Initialize parameter GUI plugin

BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_MoveZaber';

TotalRewardDisplay('init'); 

valvetimes = [0.2914 0.3082 0.2864 0.2891 0.2757 0.2745 0.3080 0.2839];
%for delivering 6ul based on calibration 12/30/20

% valvetimes = [0.2251 0.2671 0.2668 0.2482 0.2034 0.2494 0.2552 0.2373];
%%for delivering 6ul based on calibration 10/19/20

 
%% Main loop (runs once per trial)
for currentTrial = 1:MaxTrials
    disp(['Trial# ' num2str(currentTrial) ' TrialType: ' num2str(TrialTypes(currentTrial)) ' ValveNumber: ' num2str(ValveSeq(currentTrial))  ])
    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
    R = GetValveTimes(S.GUI.RewardAmount, [1 2]); LeftValveTime = R(1); RightValveTime = R(2); % Update reward amounts
    if S.GUI.TrainingLevel ~=5 % context
        switch TrialTypes(currentTrial)
            case 1 
                for i=1:7
                     if ValveSeq(currentTrial) == i
                         valveID = 2*i-1;
                     end
                end
                leftAction = 'reward'; rightAction = 'Timeout';
                ValveCode = 1; ValveTime = LeftValveTime; % reward, valve1 = left spout
                centralvalvetime = valvetimes((valveID+1)/2);
          case 2 % right trials; delivery of tastant from line 2
                for i=8
                     if ValveSeq(currentTrial) == i
                         valveID=2*i-1;
                     end
                end
                leftAction = 'Timeout'; rightAction = 'reward';
                ValveCode = 2; ValveTime = RightValveTime; % reward, valve2 = right spout
                centralvalvetime = valvetimes((valveID+1)/2);
        end
    else
        % add context
        
        
    end
disp(['  ValveID ' num2str((valveID+1)/2)])
    Asp = GetValveTimes(S.GUI.AspirationTime,3); AspValveTime = Asp;
    %--- Typically, a block of code here will compute variables for assembling this trial's state machine
%     Thisvalve = ['Valve' num2str(TrialTypes(currentTrial))];
   if S.GUI.TrainingLevel ==1 || S.GUI.TrainingLevel ==2
       leftAction = 'reward'; rightAction ='reward';
   end
    
    
    %--- Assemble state machine
    sma = NewStateMachine();
    % set the two analog channel
%     sma = SetGlobalCounter(sma, 1, 'Port1In', 1); % Arguments: (sma, CounterNumber, TargetEvent, Threshold)
%     sma = SetGlobalCounter(sma, 1, 'Port2In', 1); % Arguments: (sma, CounterNumber, TargetEvent, Threshold)
    
    sma = AddState(sma, 'Name', 'TasteValveOn', ... %Open specific taste valve
        'Timer', centralvalvetime,...
        'StateChangeConditions ', {'Tup', 'TasteValveOff'},...
        'OutputActions', {'ValveModule1', valveID,'BNCState',1}); 
    
     sma = AddState(sma, 'Name', 'TasteValveOff', ... % This example state does nothing, and ends after 0 seconds
        'Timer', 0.01,...
        'StateChangeConditions', {'Tup', 'CentralForward'},...
        'OutputActions', {'ValveModule1', valveID+1,'BNCState',0});
    
    sma = AddState(sma, 'Name', 'CentralForward', ... %Central spout moves forward
        'Timer', S.GUI.MotorTime,...
        'StateChangeConditions', {'Tup', 'WaitForLicks'},...
        'OutputActions', {'SoftCode', 1});

    sma = AddState(sma, 'Name', 'WaitForLicks', ... % This example state does nothing, and ends after 0 seconds
        'Timer', S.GUI.SamplingDuration,...
        'StateChangeConditions', {'Tup','Timeout', 'AnalogIn1_3', 'MyDelay',},...
        'OutputActions', {'SoftCode', 2});

    sma = AddState(sma, 'Name', 'MyDelay', ... % This example state does nothing, and ends after 0 seconds
        'Timer', S.GUI.DelayDuration,...
        'StateChangeConditions', {'Tup', 'LateralSpoutsUp'},...
        'OutputActions', {});
    
    sma = AddState(sma, 'Name', 'LateralSpoutsUp', ... % This example state does nothing, and ends after 0 seconds
        'Timer', S.GUI.MotorTime,...
        'StateChangeConditions', {'Tup', 'WaitForLateralLicks'},...
        'OutputActions', {'SoftCode', 3});
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if S.GUI.TrainingLevel ~=2  % all other case, meaning not correction trials; (include the habituation + no_correction)
    sma = AddState(sma, 'Name', 'WaitForLateralLicks', ... % This example state does nothing, and ends after 0 seconds
        'Timer', S.GUI.ResponseTime,...
        'StateChangeConditions', {'Tup', 'Timeout', 'AnalogIn1_1', leftAction, 'AnalogIn1_2', rightAction},...
        'OutputActions', {});
  else
      switch TrialTypes(currentTrial) % with correction
          case 1 % left trials; only see whether animals lick left spout
              sma = AddState(sma, 'Name', 'WaitForLicks', ... % This example state does nothing, and ends after 0 seconds
                  'Timer', S.GUI.ResponseTime,...
                  'StateChangeConditions', {'Tup', 'Timeout', 'AnalogIn1_1', leftAction},...
                  'OutputActions', {});
          case 2
              sma = AddState(sma, 'Name', 'WaitForLicks', ... % This example state does nothing, and ends after 0 seconds
                  'Timer', S.GUI.ResponseTime,...
                  'StateChangeConditions', {'Tup', 'Timeout', 'AnalogIn1_2', rightAction},...
                  'OutputActions', {});
      end
  end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    sma = AddState(sma, 'Name', 'reward', ... % This example state does nothing, and ends after 0 seconds
        'Timer', ValveTime,...
        'StateChangeConditions', {'Tup', 'Drinking'},...
        'OutputActions', {'ValveState', ValveCode});
    
    sma = AddState(sma, 'Name', 'Drinking', ... % This example state does nothing, and ends after 0 seconds
        'Timer', S.GUI.DrinkTime,...
        'StateChangeConditions', {'Tup', 'LateralSpoutsDown'},...
        'OutputActions', {});
    
    sma = AddState(sma, 'Name', 'LateralSpoutsDown', ... % This example state does nothing, and ends after 0 seconds
        'Timer', S.GUI.MotorTime,...
        'StateChangeConditions', {'Tup', 'AspirationUp'},...
        'OutputActions', {'SoftCode', 4});
    
    sma = AddState(sma, 'Name', 'Timeout', ...
        'Timer', S.GUI.PunishTimeoutDuration,...
        'StateChangeConditions', {'Tup', 'AspirationUp'},...
        'OutputActions', {'SoftCode', 4});
    
    sma = AddState(sma, 'Name', 'AspirationUp', ...
        'Timer', 0.5,...
        'StateChangeConditions', {'Tup', 'VacumnOn'},...
        'OutputActions', {'SoftCode', 5});
    
     sma = AddState(sma, 'Name', 'VacumnOn', ...
        'Timer', S.GUI.AspirationTime,...
        'StateChangeConditions', {'Tup', 'AspirationDown'},...
        'OutputActions', {'ValveState', 4});
    
    sma = AddState(sma, 'Name', 'AspirationDown', ...
        'Timer', 0.5,...
        'StateChangeConditions', {'Tup', 'RinseValveOn'},...
        'OutputActions', {'SoftCode', 6});
     %start of rinse
    sma = AddState(sma, 'Name', 'RinseValveOn', ... %Open valve #8 to deliver 6uL water
        'Timer', valvetimes(8)*0.8,...
        'StateChangeConditions ', {'Tup', 'RinseValveOff'},...
        'OutputActions', {'ValveModule1', 15,'BNCState',1}); 
    
     sma = AddState(sma, 'Name', 'RinseValveOff', ... % close valve #8
        'Timer', 0.01,...
        'StateChangeConditions', {'Tup', 'AspUp'},...
        'OutputActions', {'ValveModule1', 16,'BNCState',0});
     
    sma = AddState(sma, 'Name', 'AspUp', ...
        'Timer', 0.5,...
        'StateChangeConditions', {'Tup', 'VacOn'},...
        'OutputActions', {'SoftCode', 5});
    
     sma = AddState(sma, 'Name', 'VacOn', ...
        'Timer', S.GUI.AspirationTime,...
        'StateChangeConditions', {'Tup', 'AspDown'},...
        'OutputActions', {'ValveState', 4});
    
    sma = AddState(sma, 'Name', 'AspDown', ...
        'Timer', 0.5,...
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {'SoftCode', 6});
    %end of rinse
    
    sma = AddState(sma, 'Name', 'ITI', ... % This example state does nothing, and ends after 0 seconds
        'Timer', S.GUI.ITI,...
        'StateChangeConditions', {'Tup', '>exit'},...
        'OutputActions', {});
    
    SendStateMatrix(sma); % Send state machine to the Bpod state machine device
    RawEvents = RunStateMatrix; % Run the trial and return events
    
    %--- Package and save the trial's data, update plots
    if ~isempty(fieldnames(RawEvents)) % If you didn't stop the session manually mid-trial
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Adds raw events to a human-readable data struct
        BpodSystem.Data.TrialSequence(currentTrial) = TrialTypes(currentTrial);
        BpodSystem.Data.ValveSequence(currentTrial) = ValveSeq(currentTrial);
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
        
        %--- Typically a block of code here will update online plots using the newly updated BpodSystem.Data
        if ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.reward(1))
            TotalRewardDisplay('add', S.GUI.RewardAmount);
        end
    else
    end

    %--- This final block of code is necessary for the Bpod console's pause and stop buttons to work
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    if BpodSystem.Status.BeingUsed == 0
        return
    end
    
    
    
    Outcomes = zeros(1,BpodSystem.Data.nTrials);
    for x = 1:BpodSystem.Data.nTrials
        if ~isnan(BpodSystem.Data.RawEvents.Trial{x}.States.reward(1))
            Outcomes(x) = 1;
        elseif ~isnan(BpodSystem.Data.RawEvents.Trial{x}.States.Timeout(1))
            Outcomes(x) = 0;
        end         
    end
    TrialTypeOutcomePlot(BpodSystem.GUIHandles.OutcomePlot,'update',BpodSystem.Data.nTrials+1,TrialTypes,Outcomes)
    figure(100);
    plot(cumsum(Outcomes)./([1:length(Outcomes)]),'-o','Color','r')
    xlabel('Trial #');ylabel('Performance')
end