function Taste2AC_Training4
global BpodSystem
global port;
global currentTrial;
global ZaberTime;
port=serialport('COM9', 115200,"DataBits",8,FlowControl="none",Parity="none",StopBits=1,Timeout=0.5);
configureTerminator(port,"CR/LF");
setDTR(port,true);
fopen(port); %line 2-5 added 6/6/23 to control motor
%to account for faster motor reaction time, added CentralSpoutDelay(0.2),
%CentralDrink (S.GUI.CentralDrinkTime=0.75), CentralSpoutBack (which adds effective delay duration); decreased MyDelay (S.GUI.DelayDuration=1.4). 
%% Setup (runs once before the first trial)
MaxTrials = 10000; % Set to some sane value, for preallocation

TrialTypes = ceil(rand(1,MaxTrials)*2);

valve1 = 1; v1 = (2*valve1)-1;
valve2 = 8; v2 = (2*valve2)-1;

%--- Define parameters and trial structure
S = BpodSystem.ProtocolSettings; % Loads settings file chosen in launch manager into current workspace as a struct called 'S'
if isempty(fieldnames(S))  % If chosen settings file was an empty struct, populate struct with default settings
    % Define default settings here as fields of S (i.e S.InitialDelay = 3.2)
    % Note: Any parameters in S.GUI will be shown in UI edit boxes.
    % See ParameterGUI plugin documentation to show parameters as other UI types (listboxes, checkboxes, buttons, text)
    %     S.GUI = struct;

    S.GUI.TrainingLevel = 4;
    S.GUI.SamplingDuration = 3;
    S.GUI.TasteLeft = ['Valve ' num2str(valve1)];
    S.GUI.TasteRight = ['Valve ' num2str(valve2)];
%     S.GUI.DelayDuration = 1.4;
    S.GUI.DelayDuration = 1.8;

    S.GUI.TastantAmount = 0.05;
    S.GUI.MotorTime = 0.5;
    S.GUI.Up        = 14;
    S.GUI.Down      =   5;
    S.GUI.ResponseTime = 5;
    S.GUI.DrinkTime = 2;
    S.GUI.RewardAmount = 2; % in ul
    S.GUI.PunishTimeoutDuration = 10;
    S.GUI.AspirationTime = 1;
    S.GUI.ITI = 10;
    S.GUI.CentralDrinkTime=0.75;

end
% set the threshold for the analog input signal to detect events
A = BpodAnalogIn('COM6');

A.nActiveChannels = 8;
A.InputRange = {'-5V:5V',  '-5V:5V',  '-5V:5V',  '-5V:5V',  '-10V:10V', '-10V:10V',  '-10V:10V',  '-10V:10V'};

%---Thresholds for electrical detectors---
%A.Thresholds = [-0.5 -0.5 -0.5 2 2 2 2 2];
%A.ResetVoltages = [-0.2 -0.2 -0.2 1.5 1.5 1.5 1.5 1.5];
%-----------------------------------------

%---Thresholds for optical detectors---
A.Thresholds = [1 1 1 1 2 2 2 2];
A.ResetVoltages = [0.4 0.4 0.4 0.4 1.5 1.5 1.5 1.5]; %Should be at or slightly above baseline (check oscilloscope)
%--------------------------------------

A.SMeventsEnabled = [1 1 1 0 0 0 0 0];
A.startReportingEvents();
A.scope;
A.scope_StartStop;
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
BpodNotebook('init'); % Bpod Notebook (to record text notes about the session or individual trials)
BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_MoveZaber2';

TotalRewardDisplay('init');
% valvetimes= [0.232420902410882	0.237617872714368	0.188261051628414	0.194688384124161	0.191379735900284	0.191379735900284	0.191379735900284	0.245306682107329]; %4ul 6/6/23
% valvetimes=[0.219132108962338	0.237617872714368	0.188261051628414	0.194688384124161	0.191379735900284	0.191379735900284	0.191379735900284	0.224489528795812]; %4ul 6/23/23 new spout
% valvetimes=[0.271654559851275	0.168330685774158	0.129059122511895	0.128404332713604	0.135159131734474	0.135159131734474	0.135159131734474	0.249830912304973]; %3ul 6/29/23
% valvetimes= [0.365754925924651	0.307617872714368	0.308261051628414	0.304688384124161	0.311379735900284	0.301379735900284	0.301379735900284	0.339864620046774]; % 4ul 6/29/23 measured horz
% valvetimes=[0.204013411697693	0.204255608916924	0.209059122511895	0.208404332713604	0.205159131734474	0.205159131734474	0.205159131734474	0.236493422280735]; %3ul new 9v spout, horz
% valvetimes=[0.166054185058842	0.156070159072266	0.191100615091752	0.150460700606757	0.153715493658294	0.152885705199814	0.139693114043015	0.130626544464950]; %3ul, 9v spout 9/30/23
valvetimes=[0.228353327306018	0.252015183439757	0.235023283423226	0.214166349433253	0.221691950592722	0.219748611779287	0.238973793602024	0.224751165191279];%4ul new 9v spout, 9/30/23
%% Main loop (runs once per trial)
for currentTrial = 1:MaxTrials
    disp(['Trial# ' num2str(currentTrial) ' TrialType: ' num2str(TrialTypes(currentTrial))])
    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
    R = GetValveTimes(S.GUI.RewardAmount, [1 2]); LeftValveTime = R(1); RightValveTime = R(2); % Update reward amounts
    if S.GUI.TrainingLevel ~=5 % context
        switch TrialTypes(currentTrial)
            case 1 % left trials; delivery of tastant from line 1
                valveID = v1; % it seems confusion; here the 3 means the message 3
                leftAction = 'reward'; rightAction = 'Timeout';
                ValveCode = 1; ValveTime = LeftValveTime; % reward, valve1 = left spout
                centralvalvetime = valvetimes((valveID+1)/2);
            case 2 % right trials; delivery of tastant from line 2
                valveID = v2;
                leftAction = 'Timeout'; rightAction = 'reward';
                ValveCode = 2; ValveTime = RightValveTime; % reward, valve2 = right spout
                centralvalvetime = valvetimes((valveID+1)/2);
        end
    else
        % add context


    end
    disp(['ValveID ' num2str((valveID+1)/2)])
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

    %NOTE: OutputAction occurs at the beginning of the 'Timer'
    sma = AddState(sma, 'Name', 'TasteValveOn', ... %Open specific taste valve
        'Timer', centralvalvetime,...
        'StateChangeConditions ', {'Tup', 'TasteValveOff'},...
        'OutputActions', {'ValveModule1', valveID,'BNC1',1});

    sma = AddState(sma, 'Name', 'TasteValveOff', ... % This example state does nothing, and ends after 0 seconds
        'Timer', 0.01,...
        'StateChangeConditions', {'Tup', 'CentralSpoutDelay'},...
        'OutputActions', {'ValveModule1', valveID+1,'BNC1',0});

    sma = AddState(sma, 'Name', 'CentralSpoutDelay', ... % This example state does nothing, and ends after 0 seconds
        'Timer', 0.2,...
        'StateChangeConditions', {'Tup', 'CentralForward'},...
        'OutputActions', {});

    sma = AddState(sma, 'Name', 'CentralForward', ... %Central spout moves forward
        'Timer', S.GUI.MotorTime ,...
        'StateChangeConditions', {'Tup', 'WaitForLicks'},...
        'OutputActions', {'SoftCode', 1});


    %     sma = AddState(sma, 'Name', 'WaitForLicks', ... % 'Timer' duration does not do anything here..
    %         'Timer', S.GUI.SamplingDuration,...
    %         'StateChangeConditions', {'Tup','TimeoutCentral', 'AnalogIn1_3', 'MyDelay',},...
    %         'OutputActions', {});

    sma = AddState(sma, 'Name', 'WaitForLicks', ... % 'Timer' duration does not do anything here..
        'Timer', S.GUI.SamplingDuration,...
        'StateChangeConditions', {'Tup','TimeoutCentral', 'AnalogIn1_3', 'CentralDrink',},...
        'OutputActions', {});

    sma = AddState(sma, 'Name', 'CentralDrink', ... % 'Timer' duration does not do anything here..
        'Timer', S.GUI.CentralDrinkTime,...
        'StateChangeConditions', {'Tup','CentralSpoutBack'},...
        'OutputActions', {});

    sma = AddState(sma, 'Name', 'CentralSpoutBack', ... % This example state does nothing, and ends after 0 seconds
        'Timer', S.GUI.MotorTime,...
        'StateChangeConditions', {'Tup', 'MyDelay'},...
        'OutputActions', {'SoftCode', 2});

    sma = AddState(sma, 'Name', 'TimeoutCentral', ... % 'Timer' duration does not do anything here..
        'Timer', S.GUI.PunishTimeoutDuration,...
        'StateChangeConditions', {'Tup', 'AspirationUp'},...
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
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {'SoftCode', 6});

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
        BpodSystem.Data = BpodNotebook('sync', BpodSystem.Data); % Sync with Bpod notebook plugin
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        BpodSystem.Data.ZaberTime=ZaberTime;
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
        %fclose(port); %added 6/6 to control motor
        delete(port);
        clear global port;
        return
    end

    Outcomes = zeros(1,BpodSystem.Data.nTrials); %Use for graph
    Outcomes2 = zeros(1,BpodSystem.Data.nTrials); %Populate for cumsum plot
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
    xlabel('Trial #','fontsize',16);ylabel('Performance','fontsize',16); title(['Performance for Training ' num2str(S.GUI.TrainingLevel)],'fontsize',20)
    grid on
end