function Taste2AC_T4_OPTO_dry_licks

clc
global BpodSystem
global port;
global currentTrial;
global ZaberTime;
port=serialport('COM9', 115200,"DataBits",8,FlowControl="none",Parity="none",StopBits=1,Timeout=0.5);
configureTerminator(port,"CR/LF");
setDTR(port,true);
% fopen(port); %line 2-5 added 6/6/23 to control motor
%to account for faster motor reaction time, added CentralSpoutDelay(0.2),
%CentralDrink (S.GUI.CentralDrinkTime=0.75), CentralSpoutBack (which adds effective delay duration); decreased MyDelay (S.GUI.DelayDuration=1.4).
%% Setup (runs once before the first trial)
MaxTrials = 10000; % Set to some sane value, for preallocation

TrialTypes = ceil(rand(1,MaxTrials)*2);

valve1 = 8; v1 = (2*valve1)-1;
valve2 = 1; v2 = (2*valve2)-1;
percent_trials_stim = 0.8;
%%% early vs late?
%--- Define parameters and trial structure
S = BpodSystem.ProtocolSettings; % Loads settings file chosen in launch manager into current workspace as a struct called 'S'
if isempty(fieldnames(S))  % If chosen settings file was an empty struct, populate struct with default settings
    % Define default settings here as fields of S (i.e S.InitialDelay = 3.2)
    % Note: Any parameters in S.GUI will be shown in UI edit boxes.
    % See ParameterGUI plugin documentation to show parameters as other UI types (listboxes, checkboxes, buttons, text)
    %     S.GUI = struct;
    S.GUI.dry_licks = 1;
    S.GUI.TrainingLevel = 4;
    S.GUI.SamplingDuration = 5;
    S.GUI.TasteLeft = ['Valve ' num2str(valve1)];
    S.GUI.TasteRight = ['Valve ' num2str(valve2)];
    %     S.GUI.DelayDuration = 1.4;
    S.GUI.DelayDuration = 1.5;
    S.Stim_Time = 2.6;
    S.GUI.TastantAmount = 0.03;
    S.GUI.MotorTime = 0.5;
    S.GUI.Up        = 14;
    S.GUI.Down      =   5;
    S.GUI.ResponseTime = 6;
    S.GUI.DrinkTime = 2;
    S.GUI.RewardAmount = 2.8; % in ul
    S.GUI.PunishTimeoutDuration = 10; %10
    S.GUI.AspirationTime = 0.1;
    S.GUI.ITI = 12; %10
    S.GUI.CentralDrinkTime=1;

end
ITI_rand = randi([-3 3]);
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
% A.scope;
% A.scope_StartStop;
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

%% Opto params
% if isfield(BpodSystem.ModuleUSB,'WavePlayer1')
%     W = BpodSystem.ModuleUSB.WavePlayer1;
% end
W = BpodWavePlayer('COM10');
samples = W.SamplingRate;
total_duration = 2.6;
pulse_volts = 3;%[5 5 5 5];0.00076 0.00024 % 0.00095 0.00005
% pulse_duration = 0.0125;%[0.00025 0.00035 0.00054 0.00076];
% interpulse_interval =  0.0125;%[0.00075 0.00065 0.00046 0.00024];
pulse_duration = 0.0125;%[0.00025 0.00035 0.00054 0.00076];
interpulse_interval =  0.0125;%[0.00075 0.00065 0.00046 0.00024];
train1 = create_pulsetrain(pulse_volts, pulse_duration, interpulse_interval, total_duration, samples);

total_duration = 0.2;
pulse_volts = 1.5;%[5 5 5 5];0.00076 0.00024 % 0.00095 0.00005
pulse_duration = 0.01;%[0.00025 0.00035 0.00054 0.00076];
interpulse_interval =  0.01;%[0.00075 0.00065 0.00046 0.00024];
train2 = create_pulsetrain(pulse_volts, pulse_duration, interpulse_interval, total_duration, samples);
% 
total_duration = 0.1;
pulse_volts = 1;%[5 5 5 5];0.00076 0.00024 % 0.00095 0.00005
pulse_duration = 0.001;%[0.00025 0.00035 0.00054 0.00076];
interpulse_interval =  0.001;%[0.00075 0.00065 0.00046 0.00024];
train3 = create_pulsetrain(pulse_volts, pulse_duration, interpulse_interval, total_duration, samples);
% 
total_duration = 0.1;
pulse_volts = 0.5;%[5 5 5 5];0.00076 0.00024 % 0.00095 0.00005
pulse_duration = 0.010;%[0.00025 0.00035 0.00054 0.00076];
interpulse_interval =  0.01;%[0.00075 0.00065 0.00046 0.00024];
train4 = create_pulsetrain(pulse_volts, pulse_duration, interpulse_interval, total_duration, samples);
% total_duration = 2.5;
% 
% pulse_volts = 1.5;%[5 5 5 5];0.00076 0.00024 % 0.00095 0.00005
% % pulse_duration = 0.0125;%[0.00025 0.00035 0.00054 0.00076];
% % interpulse_interval =  0.0125;%[0.00075 0.00065 0.00046 0.00024];
% pulse_duration = 2.5;%[0.00025 0.00035 0.00054 0.00076];
% interpulse_interval =  0;%[0.00075 0.00065 0.00046 0.00024];
% train1 = create_pulsetrain(pulse_volts, pulse_duration, interpulse_interval, total_duration, samples);
% 
% total_duration = 0.1;
% pulse_volts = 1;%[5 5 5 5];0.00076 0.00024 % 0.00095 0.00005
% pulse_duration = 0.1;%[0.00025 0.00035 0.00054 0.00076];
% interpulse_interval =  0;%[0.00075 0.00065 0.00046 0.00024];
% train2 = create_pulsetrain(pulse_volts, pulse_duration, interpulse_interval, total_duration, samples);
% 
% total_duration = 0.1;
% pulse_volts = 0.7;%[5 5 5 5];0.00076 0.00024 % 0.00095 0.00005
% pulse_duration = 0.1;%[0.00025 0.00035 0.00054 0.00076];
% interpulse_interval =  0;%[0.00075 0.00065 0.00046 0.00024];
% train3 = create_pulsetrain(pulse_volts, pulse_duration, interpulse_interval, total_duration, samples);
% 
% total_duration = 0.1;
% pulse_volts = 0.5;%[5 5 5 5];0.00076 0.00024 % 0.00095 0.00005
% pulse_duration = 0.010;%[0.00025 0.00035 0.00054 0.00076];
% interpulse_interval =  0.01;%[0.00075 0.00065 0.00046 0.00024];
% pulse_duration = 0.100;%[0.00025 0.00035 0.00054 0.00076];
% interpulse_interval =  0;[0.00075 0.00065 0.00046 0.00024];
% train4 = create_pulsetrain(pulse_volts, pulse_duration, interpulse_interval, total_duration, samples);
W.loadWaveform(1, [train1 train2 train3 train4]);
LoadSerialMessages('WavePlayer1', {['P' 3 0], ['P' 3 1]});
W.OutputRange = '0V:5V';
W.TriggerMode = 'Master';

%%
for j = 1%:20
%     MaxTrials = 100; 
    TrialOptions = [1 2];
    TrialTypes_temp = randi(2,1,MaxTrials);
    TrialTypes = TrialOptions(TrialTypes_temp);
    opto_temp{j} = zeros(3,MaxTrials);

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

   l_opto_idx = randperm(sum(TrialTypes==1),round((percent_trials_stim/2)*sum(TrialTypes==1)));
   r_opto_idx = randperm(sum(TrialTypes==2),round((percent_trials_stim/2)*sum(TrialTypes==2)));

   l_opto_f = l_idx(l_opto_idx);
   r_opto_f = r_idx(r_opto_idx);

   opto_temp{j}(1,:)=TrialTypes;
   opto_temp{j}(2,r_opto_f)=1;
   opto_temp{j}(2,l_opto_f)=1;

   % pick 2 left and 2 right  for early/late

%    r_opto_early_idx = randperm(4,2);
%    l_opto_early_idx = randperm(4,2);
%    r_opto_late_idx = ~ismember(1:4,r_opto_early_idx);
%    l_opto_late_idx = ~ismember(1:4,l_opto_early_idx);
% 
%    opto_temp{j}(3,l_opto_f(l_opto_early_idx)) = 1;
%    opto_temp{j}(3,r_opto_f(r_opto_early_idx)) = 1;
%    opto_temp{j}(3,l_opto_f(l_opto_late_idx)) = 2;
%    opto_temp{j}(3,r_opto_f(r_opto_late_idx)) = 2;

end
r_opto=horzcat(opto_temp{:});
r_opto(1,r_opto(1,:)==2)=8;
% TrialTypes = r_opto(1,:);
%%
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
valvetimes=[0.12	0.252015183439757	0.235023283423226	0.214166349433253	0.221691950592722	0.219748611779287	0.238973793602024	0.12];%4ul new 9v spout, 9/30/23
outcomePlot = LiveOutcomePlot([1 2], {'Left [1]','Right [2]'}, TrialTypes,90);

outcomePlot.RewardStateNames = {'reward'};
outcomePlot.ErrorStateNames = {'TimeoutCentral'};
outcomePlot.PunishStateNames = {'Timeout'};
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
%     Asp = GetValveTimes(S.GUI.AspirationTime,2); AspValveTime = Asp;
    %--- Typically, a block of code here will compute variables for assembling this trial's state machine
    %     Thisvalve = ['Valve' num2str(TrialTypes(currentTrial))];
    if S.GUI.TrainingLevel ==1 || S.GUI.TrainingLevel ==2
        leftAction = 'reward'; rightAction ='reward';
    end
    if currentTrial==1
        disp(r_opto)
    end
    if r_opto(2,currentTrial)==1    %% trigger Opto laser
%         if r_opto(3,currentTrial)==1
            opto_1 = 'OptoOn';
%             opto_2 = 'LateralSpoutsUp';
            delay_duration =  S.Stim_Time - S.GUI.DelayDuration;
%         elseif r_opto(3,currentTrial)==2 
%             opto_1 = 'VaccuumOff';
%             opto_2 = 'Opto2On';
%             delay_duration = S.GUI.DelayDuration-0.5;
%         end
    else %% NO trigger Opto laser, non-opto
        opto_1 = 'MyDelay';
%         opto_2 = 'LateralSpoutsUp';
        delay_duration = S.GUI.DelayDuration;

    end

    %--- Assemble state machine
    sma = NewStateMachine();
    % set the two analog channel
    %     sma = SetGlobalCounter(sma, 1, 'Port1In', 1); % Arguments: (sma, CounterNumber, TargetEvent, Threshold)
    %     sma = SetGlobalCounter(sma, 1, 'Port2In', 1); % Arguments: (sma, CounterNumber, TargetEvent, Threshold)
    if S.GUI.dry_licks == 1  % all other case, meaning not correction trials; (include the habituation + no_correction)
        sma = AddState(sma, 'Name', 'CentralForward', ... %Central spout moves forward
            'Timer', S.GUI.MotorTime ,...
            'StateChangeConditions', {'Tup', 'WaitForLicks'},...
            'OutputActions', {'SoftCode', 1});
         
            sma = AddState(sma, 'Name', 'WaitForLicks', ... % This example state does nothing, and ends after 0 seconds
                'Timer', S.GUI.ResponseTime,...
                'StateChangeConditions', {'Tup', 'TimeoutCentral', 'AnalogIn1_3', 'TasteValveOn'},...
                'OutputActions', {});
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
                'StateChangeConditions', {'Tup', 'CentralDrink'},...
                'OutputActions', {});
           
        
    else


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
        sma = AddState(sma, 'Name', 'WaitForLicks', ... % 'Timer' duration does not do anything here..
            'Timer', S.GUI.SamplingDuration,...
            'StateChangeConditions', {'Tup','TimeoutCentral', 'AnalogIn1_3', 'CentralDrink',},...
            'OutputActions', {});
    end

    %     sma = AddState(sma, 'Name', 'WaitForLicks', ... % 'Timer' duration does not do anything here..
    %         'Timer', S.GUI.SamplingDuration,...
    %         'StateChangeConditions', {'Tup','TimeoutCentral', 'AnalogIn1_3', 'MyDelay',},...
    %         'OutputActions', {});



    sma = AddState(sma, 'Name', 'CentralDrink', ... % 'Timer' duration does not do anything here..
        'Timer', S.GUI.CentralDrinkTime,...
        'StateChangeConditions', {'Tup','CentralSpoutBack'},...
        'OutputActions', {});

    sma = AddState(sma, 'Name', 'CentralSpoutBack', ... % This example state does nothing, and ends after 0 seconds
        'Timer', S.GUI.MotorTime,...
        'StateChangeConditions', {'Tup', opto_1},...
        'OutputActions', {'SoftCode', 2});

    sma = AddState(sma, 'Name', 'TimeoutCentral', ... % 'Timer' duration does not do anything here..
        'Timer', S.GUI.PunishTimeoutDuration,...
        'StateChangeConditions', {'Tup', 'AspirationUp'},...
        'OutputActions', {'SoftCode', 2});

    sma = AddState(sma, 'Name', 'MyDelay', ... % This example state does nothing, and ends after 0 seconds
        'Timer', delay_duration,...
        'StateChangeConditions', {'Tup', 'LateralSpoutsUp'},...
        'OutputActions', {});
 % -- IF OPTO 2 ---
    sma = AddState(sma, 'Name', 'OptoOn', ... 
        'Timer', S.GUI.DelayDuration,... %%Should be full delay length from control trials
        'StateChangeConditions', {'Tup', 'LateralSpoutsUp'},...
        'OutputActions', {'WavePlayer1',1});
    % -- END OPTO 2 ---
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
        'Timer', S.GUI.ITI+ITI_rand,...
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

 outcomePlot.update(TrialTypes, BpodSystem.Data);

    figure(100);
    plot(cumsum(Outcomes2)./([1:length(Outcomes2)]),'-o','Color','#ad6bd3','MarkerFaceColor','#ad6bd3')
    xlabel('Trial #','fontsize',16);ylabel('Performance','fontsize',16); title('Performance for 8V Mixture Test','fontsize',20)
    grid on
end