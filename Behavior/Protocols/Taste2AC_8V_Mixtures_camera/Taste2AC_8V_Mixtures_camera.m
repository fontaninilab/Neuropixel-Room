function Taste2AC_8V_Mixtures_camera   
global BpodSystem

%% Setup (runs once before the first trial)
MaxTrials = 400; % Set to some sane value, for preallocation
TrialTypes = ceil(rand(1,MaxTrials)*2);
% to change directions 14-15 31-32 91-95 166-183
% % % Pad start with 12 blocked trials % % %

nPad = 2;
trialseq = [1,1,1,2,2,2];
TrialTypePad = repmat(trialseq,1,nPad);
% 
 valveseq = [1,1,1,8,8,8];
%  valveseq = [8,8,8,1,1,1];
ValveSeqPad = repmat(valveseq,1,nPad);

% % % % % % % % % % % % % % % % % % % % % % %

%--- Define parameters and trial structure
S = BpodSystem.ProtocolSettings; % Loads settings file chosen in launch manager into current workspace as a struct called 'S'
if isempty(fieldnames(S))  % If chosen settings file was an empty struct, populate struct with default settings
    % Define default settings here as fields of S (i.e S.InitialDelay = 3.2)
    % Note: Any parameters in S.GUI will be shown in UI edit boxes.
    % See ParameterGUI plugin documentation to show parameters as other UI types (listboxes, checkboxes, buttons, text)
    %     S.GUI = struct;
    
    S.GUI.TrainingLevel = 4;
    S.GUI.SamplingDuration = 3;
    S.GUI.TasteLeft = 'Salt';
    S.GUI.TasteRight = 'sucrose';
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
    S.GUI.ITI = 10;
    
end
% set the threshold for the analog input signal to detect events
A = BpodAnalogIn('COM6');

A.nActiveChannels = 8;
A.InputRange = {'-2.5V:2.5V',  '-2.5V:2.5V',  '-2.5V:2.5V',  '-5V:5V',  '-10V:10V', '-10V:10V',  '-10V:10V',  '-10V:10V'};

%---Thresholds for electrical detectors---
%A.Thresholds = [-0.5 -0.5 -0.5 2 2 2 2 2];
%A.ResetVoltages = [-0.2 -0.2 -0.2 1.5 1.5 1.5 1.5 1.5];
%-----------------------------------------

%---Thresholds for optical detectors---
A.Thresholds = [1 1 1 1 2 2 2 2];
A.ResetVoltages = [0.1 0.1 0.1 0.1 1.5 1.5 1.5 1.5]; %Should be at or slightly above baseline (check oscilloscope)
%--------------------------------------

A.SMeventsEnabled = [1 1 1 1 0 0 0 0];
A.startReportingEvents();


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
                if TrialTypes(i-1) == 1
                   TrialTypes(i) = 2;
                else
                   TrialTypes(i) = 1; 
                end
            end
        end
    end
    
end
% make a ValveSeq array


ValveSeq = TrialTypes;
Type1ValveIDX = 1:4;
% Type1ValveIDX = 5:8;
 Type2ValveIDX = 5:8;
% Type2ValveIDX = 1:4;
nRep = 4; %Number of repeats of each valve # per "block"

nSeq = ceil(length(ValveSeq)/(2*nRep*length(Type1ValveIDX))) + 5; %How many blocks of nRep per trial type
ValvePerm = NaN(nRep*length(Type1ValveIDX),nSeq);
ValveTemp = repmat(Type1ValveIDX,1,nRep);

%Randomly permute every trial chunk (nRep*nValves = length of chunk)
for j = 1:nSeq
    ValvePerm(:,j) = ValveTemp(randperm(length(ValveTemp)))';
end
ValveIDX = reshape(ValvePerm,1,nRep*length(Type1ValveIDX)*nSeq);
b = find(TrialTypes(:) == 1);
ValveSeq(b) = ValveIDX(1:length(b));

%Repeat for other trial type
nSeq = ceil(length(ValveSeq)/(2*nRep*length(Type2ValveIDX))) + 5;
ValvePerm = NaN(nRep*length(Type2ValveIDX),nSeq);
ValveTemp = repmat(Type2ValveIDX,1,nRep);
for j = 1:nSeq
    ValvePerm(:,j) = ValveTemp(randperm(length(ValveTemp)))';
end
ValveIDX = reshape(ValvePerm,1,nRep*length(Type2ValveIDX)*nSeq);
a = find(TrialTypes(:) == 2);
ValveSeq(a) = ValveIDX(1:length(a));

% % % Add block pad to sequence % % %

ValveSeq = [ValveSeqPad ValveSeq];
TrialTypes = [TrialTypePad TrialTypes];

% % % % % % % % % % % % % % % % % % % 

 
%  Initialize plots
BpodSystem.ProtocolFigures.OutcomePlotFig = figure('Position', [200 200 1000 200],'name','Trial type outcome plot', 'numbertitle','off', 'MenuBar', 'none', 'Resize', 'off'); % Create a figure for the outcome plot
BpodSystem.GUIHandles.OutcomePlot = axes('Position', [.075 .3 .89 .6]); % Create axes for the trial type outcome plot
TrialTypeOutcomePlot(BpodSystem.GUIHandles.OutcomePlot,'init',TrialTypes);

%--- Initialize plots and start USB connections to any modules
BpodParameterGUI('init', S); % Initialize parameter GUI plugin

BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_MoveZaber';

% TotalRewardDisplay('init'); 


valvetimes= [0.123254795829022	0.145159131734474	0.145159131734474	0.135159131734474	0.135159131734474	0.135159131734474	0.135159131734474	0.139127361055723]; %3ul 4/12/23
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Reminder to press record
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure(50);
text(1,1,'DID YOU PRESS RECORD, DUMMY??? I CERTAINLY HOPE YOU DID OR YOU"LL BE MAD!','fontsize',22,'color','red','fontweight','bold')
set(gca,'xlim',[0 20],'ylim',[0 2],'XTick',[],'YTick',[])

pp = [1800 200];
set(gcf,'PaperPositionMode','auto')
set(gcf,'PaperOrientation','Landscape')
set(gcf,'PaperUnits','points')
set(gcf,'Position',[100 400 pp])

%% Main loop (runs once per trial)
for currentTrial = 1:MaxTrials
    disp(['Trial# ' num2str(currentTrial) ' TrialType: ' num2str(TrialTypes(currentTrial)) ' ValveNumber: ' num2str(ValveSeq(currentTrial))  ])
    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
    R = GetValveTimes(S.GUI.RewardAmount, [1 2]); LeftValveTime = R(1); RightValveTime = R(2); % Update reward amounts
    if S.GUI.TrainingLevel ~=5 % context
        switch TrialTypes(currentTrial)

            case 1
                  if ismember(ValveSeq(currentTrial),[1:4])
%                 if ismember(ValveSeq(currentTrial),[5:8])
                    valveID = 2*ValveSeq(currentTrial)-1;
                end
                leftAction = 'reward'; rightAction = 'Timeout';
                ValveCode = 1; ValveTime = LeftValveTime; % reward, valve1 = left spout
                centralvalvetime = valvetimes((valveID+1)/2);

            case 2 % right trials; delivery of tastant from line 2
%                 if ismember(ValveSeq(currentTrial),[1:4])
                  if ismember(ValveSeq(currentTrial),[5:8])
                    valveID = 2*ValveSeq(currentTrial)-1;
                end
                leftAction = 'Timeout'; rightAction = 'reward';
                ValveCode = 2; ValveTime = RightValveTime; % reward, valve2 = right spout
                centralvalvetime = valvetimes((valveID+1)/2);

        end
    else
        % add context


    end

%     fprintf('Trial type: %d ::: Valve ID: %d\n',[TrialTypes(currentTrial) valveID]); 

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
    
%     sma = AddState(sma, 'Name', 'TasteValveOn', ... %Open specific taste valve
%         'Timer', centralvalvetime,...
%         'StateChangeConditions ', {'Tup', 'TasteValveOff'},...
%         'OutputActions', {'ValveModule1', valveID,'BNCState',1}); 
     sma = SetGlobalTimer(sma, 'TimerID', 1, 'Duration', 0.01, 'OnsetDelay', 0,...
                     'Channel', 'BNC2', 'OnLevel', 1, 'OffLevel', 0,...
                     'Loop', 1, 'SendGlobalTimerEvents', 0, 'LoopInterval', 0.01); 
  sma = AddState(sma, 'Name', 'TimerTrig', ...
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'TasteValveOn'},...
    'OutputActions', {'GlobalTimerTrig', 1});
    %NOTE: OutputAction occurs at the beginning of the 'Timer'
    sma = AddState(sma, 'Name', 'TasteValveOn', ... %Open specific taste valve
        'Timer', centralvalvetime,...
        'StateChangeConditions ', {'Tup', 'TasteValveOff'},...
        'OutputActions', {'ValveModule1', valveID,'BNC1',1}); 
 
     sma = AddState(sma, 'Name', 'TasteValveOff', ... % This example state does nothing, and ends after 0 seconds
        'Timer', 0.01,...
        'StateChangeConditions', {'Tup', 'CentralForward'},...
        'OutputActions', {'ValveModule1', valveID+1,'BNC1',0});
    
    sma = AddState(sma, 'Name', 'CentralForward', ... %Central spout moves forward
        'Timer', S.GUI.MotorTime,...
        'StateChangeConditions', {'Tup', 'WaitForLicks'},...
        'OutputActions', {'SoftCode', 1});

    sma = AddState(sma, 'Name', 'WaitForLicks', ... % 'Timer' duration does not do anything here..
        'Timer', S.GUI.SamplingDuration,...
        'StateChangeConditions', {'Tup','TimeoutCentral', 'AnalogIn1_3', 'MyDelay',},...
        'OutputActions', {});
    
    sma = AddState(sma, 'Name', 'TimeoutCentral', ... % 'Timer' duration does not do anything here..
        'Timer', S.GUI.PunishTimeoutDuration,...
        'StateChangeConditions', {'Tup', 'AspirationUp'},...
        'OutputActions', {'SoftCode', 2});

    sma = AddState(sma, 'Name', 'MyDelay', ... % This example state does nothing, and ends after 0 seconds
        'Timer', S.GUI.DelayDuration,...
        'StateChangeConditions', {'Tup', 'LateralSpoutsUp'},...
        'OutputActions', {'SoftCode', 2});
    
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
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {'SoftCode', 6});
    
%     sma = AddState(sma, 'Name', 'ITI', ... % This example state does nothing, and ends after 0 seconds
%         'Timer', S.GUI.ITI,...
%         'StateChangeConditions', {'Tup', '>exit'},...
%         'OutputActions', {});
 sma = AddState(sma, 'Name', 'ITI', ... 
        'Timer', S.GUI.ITI,...
        'StateChangeConditions', {'Tup', 'TimerTriggerEnd'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'TimerTriggerEnd', ...
        'Timer', 0,...
          'StateChangeConditions', {'Tup', '>exit','GlobalTimer1_End', 'exit'},...
        'OutputActions', {'GlobalTimerCancel', 1});    
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
%         if ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.reward(1))
%             TotalRewardDisplay('add', S.GUI.RewardAmount);
%         end
    else
    end

    %--- This final block of code is necessary for the Bpod console's pause and stop buttons to work
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    if BpodSystem.Status.BeingUsed == 0
        return
    end
    
    Outcomes = zeros(1,BpodSystem.Data.nTrials); %Use for graph
    Outcomes2 = zeros(1,BpodSystem.Data.nTrials); %Populate for cumsum plot
%     for x = 1:BpodSystem.Data.nTrials
%         aa = BpodSystem.Data.RawEvents.Trial{x}.Events;
%         if ~isnan(BpodSystem.Data.RawEvents.Trial{x}.States.reward(1))
%             Outcomes(x) = 1; %If correct, mark as green
%             Outcomes2(x) = 1;
%         elseif ~isfield(aa, 'AnalogIn1_3')
%             Outcomes(x) = 3; %If no central response, mark as blue open circle
%             Outcomes2(x) = 0;            
%         elseif isfield(aa, 'AnalogIn1_1') || isfield(aa, 'AnalogIn1_2')
%             Outcomes(x) = 0; %If response, but wrong, mark as red
%             Outcomes2(x) = 0;
%         elseif ~isnan(BpodSystem.Data.RawEvents.Trial{x}.States.Timeout(1))
%             Outcomes(x) = -1; %If no lateral response, mark as red open circle
%             Outcomes2(x) = 0;
%         end         
%     end
%     
%     TrialTypeOutcomePlotModified(BpodSystem.GUIHandles.OutcomePlot,'update',BpodSystem.Data.nTrials+1,TrialTypes,Outcomes)
%     
%     figure(100);
%     plot(cumsum(Outcomes2)./([1:length(Outcomes2)]),'-o','Color','#ad6bd3','MarkerFaceColor','#ad6bd3')
   trialcounts = zeros(1,BpodSystem.Data.nTrials); %Populate for cumsum plot
    for x = 1:BpodSystem.Data.nTrials
        aa = BpodSystem.Data.RawEvents.Trial{x}.Events;
        if ~isnan(BpodSystem.Data.RawEvents.Trial{x}.States.reward(1))
            Outcomes(x) = 1; %If correct, mark as green
            Outcomes2(x) = 1;
            trialcounts(x) = 1;
        elseif ~isfield(aa, 'AnalogIn1_3')
            Outcomes(x) = 3; %If no central response, mark as blue open circle
            Outcomes2(x) = NaN; %0;
            trialcounts(x) = NaN;
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
    plot(nancumsum(Outcomes2)./(nancumsum(trialcounts)),'-o','Color','#ad6bd3','MarkerFaceColor','#ad6bd3')
       
xlabel('Trial #','fontsize',16);ylabel('Performance','fontsize',16); title('Performance for 8V Mixture Test','fontsize',20)
    grid on
end