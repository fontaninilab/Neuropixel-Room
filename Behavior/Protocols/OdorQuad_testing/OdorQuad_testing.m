function OdorQuad_testing
global BpodSystem
global port;
port=serialport('COM9', 115200,"DataBits",8,FlowControl="none",Parity="none",StopBits=1,Timeout=0.5);
setDTR(port,true);
configureTerminator(port,"CR/LF");
fopen(port); %line 2-5 added 6/6/23 to control motor
%% Setup (runs once before the first trial)
MaxTrials = 1200; % Set to some sane value, for preallocation
TrialTypes = [];

% block of 40

trials=[];
for i =1:20
    all_trials = 1:40;
    left_trials = randperm(40,20);
    right_trials = all_trials(~ismember(all_trials,left_trials));

    left_water = left_trials(randperm(20,10));
    left_taste = left_trials(~ismember(left_trials,left_water));

    right_water = right_trials(randperm(20,10));
    right_taste = right_trials(~ismember(right_trials,right_water));

    trial_block = zeros(2,40);
    trial_block(1,left_water)=1;
    trial_block(1,left_taste)=3;
    trial_block(1,right_water)=2;
    trial_block(1,right_taste)=4;

    left_taste_catch = left_taste(randperm(10,3));
    right_taste_catch = right_taste(randperm(10,3));

    trial_block(2,left_taste_catch)=1;
    trial_block(2,right_taste_catch)=1;

    %TrialTypes=horzcat(TrialTypes,trial_block);
    trials = horzcat(trials,trial_block);
end

%no more than 5 of 1 side in a row
for i= 5:length(trials)
    if(all(mod([trials(1,i),trials(1,i-1),trials(1,i-2),trials(1,i-3),trials(1,i-4)],2)==0)) % all right
        if trials(2,i)~= 1
            trials(1,i)=randi([1,3]);
        end
    elseif(all(mod([trials(1,i),trials(1,i-1),trials(1,i-2),trials(1,i-3),trials(1,i-4)],2)==1)) % all right
        if trials(2,i)~= 1
            trials(1,i)=randi([2,4]);
        end
    end
end

%no more than 3 of same in a row
for i= 4:length(trials)
    if trials(1,i-1) == trials(1,i-2) && trials(1,i-2) == trials(1,i-3)
        if trials(1,i-1) == 1 || trials(1,i-1) == 3
            if trials(2,i-1)~= 1
                trials(1,i-1)=randi([2,4]);
            end
        elseif trials(1,i-1) == 2 || trials(1,i-1) == 4
            if trials(2,i-1)~= 1
                trials(1,i-1)=randi([1,3]);
            end
        end
    end
end

TrialTypes=trials(1,:);
disp([sum(TrialTypes==1), sum(TrialTypes==2), sum(TrialTypes==3), sum(TrialTypes==4)]);
disp(find(trials(2,:)==1));

%%
%AGQ1: odor1->L->water; odor2->R->water | odor4->L->MSG; odor3->R->Suc
%AGQ2: odor3->L->water; odor4->R->water | odor1->L->MSG; odor2->R->Suc

%--- Define parameters and trial structure
S = BpodSystem.ProtocolSettings; % Loads settings file chosen in launch manager into current workspace as a struct called 'S'
S.Catch = trials;
   %{ 
    S.GUI.TrainingLevel = 1;
    S.GUI.SamplingDuration = 0.5;
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
    S.GUI.ITI =10;
   %}



% set the threshold for the analog input signal to detect events
% set the threshold for the analog input signal to detect events
A = BpodAnalogIn('COM6');

A.nActiveChannels = 8;
A.InputRange = {'-5V:5V',  '-5V:5V',  '-5V:5V',  '-5V:5V',  '-10V:10V', '-10V:10V',  '-10V:10V',  '-10V:10V'};

%---Thresholds for optical detectors---
A.Thresholds = [1 1 1 2 2 2 2 2];
A.ResetVoltages = [0.5 0.5 0.1 1.5 1.5 1.5 1.5 1.5]; %Should be at or slightly above baseline (check oscilloscope)
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

%  Initialize plots
outcomePlot = LiveOutcomePlot([1 2 3 4], {'LW [1]','RW [2]','LT [3]','RT [4]'}, TrialTypes,120);
outcomePlot.RewardStateNames = {'Reward'};
outcomePlot.ErrorStateNames = {'Timeout_omit'};
outcomePlot.PunishStateNames = {'Timeout'};

%--- Initialize plots and start USB connections to any modules
BpodParameterGUI('init', S); % Initialize parameter GUI plugin

BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_MoveZaber';

%% Main loop (runs once per trial)

for currentTrial = 1:MaxTrials
    disp(['Trial# ' num2str(currentTrial) ' TrialType: ' num2str(TrialTypes(currentTrial))])
    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
    R = GetValveTimes(S.GUI.RewardAmount, [1 2 3 4]); LWValveTime = R(1); RWValveTime = R(2); LTValveTime = R(3); RTValveTime = R(4); % Update reward amounts

    blankon = 10;
    blankoff = 9;
    vacon = 16;
    vacoff = 15; 
    preloadtime = 0.5;

    switch TrialTypes(currentTrial)
        case 1  % left trials; delivery of tastant from line 1
            odorvalveID = S.GUI.OdorLW;
            tastevalveID = 1;

            odoropen = (odorvalveID*2)-1; % serial message ['O' 1]
            odorclose = odorvalveID*2; % serial message ['C' 1]

            tastevalvetime = LWValveTime;
        

        case 2  % right trials; delivery of tastant from line 2
            odorvalveID = S.GUI.OdorRW;
            tastevalveID = 2;

            odoropen = (odorvalveID*2)-1; % serial message ['O' 6]
            odorclose = odorvalveID*2; % serial message ['C' 6]

            tastevalvetime = RWValveTime;
           

         case 3  % left trials; delivery of tastant from line 1
            odorvalveID = S.GUI.OdorLT;
            tastevalveID = 4;

            odoropen = (odorvalveID*2)-1; % serial message ['O' 1]
            odorclose = odorvalveID*2; % serial message ['C' 1]

            tastevalvetime = LTValveTime;

            if trials(2,currentTrial)==1 % catch trial
                tastevalveID = 1;
                tastevalvetime = LWValveTime;
            end

            
        case 4  % right trials; delivery of tastant from line 2
            odorvalveID = S.GUI.OdorRT;
            tastevalveID = 8;

            odoropen = (odorvalveID*2)-1; % serial message ['O' 6]
            odorclose = odorvalveID*2; % serial message ['C' 6]

            tastevalvetime = RTValveTime;

            if trials(2,currentTrial)==1 % catch trial
                tastevalveID = 2;
                tastevalvetime = RWValveTime;
            end
            

    end
            rightAction = 'Reward';
            leftAction = 'Reward'; 

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
        'OutputActions', {'ValveModule2', vacoff,'BNCState', 0});

    % vaccuum on - ODOR REMOVED
     sma = AddState(sma, 'Name', 'VaccuumOn', ... 
        'Timer', 0,...
        'StateChangeConditions', {'Tup', 'OdorValveOff'},...
        'OutputActions', {'ValveModule2', vacon});

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
    'StateChangeConditions', {'Tup', 'LateralUp'},...
    'OutputActions', {});

    % lateral up
    sma = AddState(sma, 'Name', 'LateralUp', ...
    'Timer', S.GUI.MotorTime,...
    'StateChangeConditions', {'Tup', 'WaitForLateralLicks'},...
    'OutputActions', {'SoftCode', 3});

    switch TrialTypes(currentTrial) % with correction

          case 1 % left trials; only see whether animals lick left spout
              sma = AddState(sma, 'Name', 'WaitForLateralLicks', ... 
                  'Timer', S.GUI.ResponseTime,...
                  'StateChangeConditions', {'Tup', 'Timeout_omit', 'AnalogIn1_1', leftAction, 'AnalogIn1_2', 'Timeout'},...
                  'OutputActions', {});
          case 2
              sma = AddState(sma, 'Name', 'WaitForLateralLicks', ...
                  'Timer', S.GUI.ResponseTime,...
                  'StateChangeConditions', {'Tup', 'Timeout_omit', 'AnalogIn1_2', rightAction, 'AnalogIn1_1', 'Timeout'},...
                  'OutputActions', {});
               case 3 
          sma = AddState(sma, 'Name', 'WaitForLateralLicks', ... 
              'Timer', S.GUI.ResponseTime,...
              'StateChangeConditions', {'Tup', 'Timeout_omit', 'AnalogIn1_1', leftAction,'AnalogIn1_2', 'Timeout'},...
              'OutputActions', {});

          case 4
          sma = AddState(sma, 'Name', 'WaitForLateralLicks', ...
              'Timer', S.GUI.ResponseTime,...
              'StateChangeConditions', {'Tup', 'Timeout_omit', 'AnalogIn1_2', rightAction, 'AnalogIn1_1', 'Timeout'},...
              'OutputActions', {});
     end

     sma = AddState(sma, 'Name', 'Reward', ... 
    'Timer', tastevalvetime,...
    'StateChangeConditions', {'Tup', 'Drinking'},...
    'OutputActions', {'ValveState', tastevalveID});

     sma = AddState(sma, 'Name', 'Drinking', ... 
    'Timer', S.GUI.DrinkTime,...
    'StateChangeConditions', {'Tup', 'LateralDown'},...
    'OutputActions', {});

     sma = AddState(sma, 'Name', 'LateralDown', ... % This example state does nothing, and ends after 0 seconds
    'Timer', S.GUI.MotorTime,...
    'StateChangeConditions', {'Tup', 'ITI'},...
    'OutputActions', {'SoftCode', 4});

     sma = AddState(sma, 'Name', 'Timeout', ...
    'Timer', S.GUI.PunishTimeoutDuration,...
    'StateChangeConditions', {'Tup', 'ITI'},...
    'OutputActions', {'SoftCode', 4});

     sma = AddState(sma, 'Name', 'Timeout_omit', ...
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
    RW_count = zeros(1,BpodSystem.Data.nTrials);
    LW_count = zeros(1,BpodSystem.Data.nTrials);
    RT_count = zeros(1,BpodSystem.Data.nTrials);
    LT_count = zeros(1,BpodSystem.Data.nTrials);

    RW_correct = zeros(1,BpodSystem.Data.nTrials);
    LW_correct = zeros(1,BpodSystem.Data.nTrials);
    RT_correct = zeros(1,BpodSystem.Data.nTrials);
    LT_correct = zeros(1,BpodSystem.Data.nTrials);

    for x = 1:BpodSystem.Data.nTrials
        aa = BpodSystem.Data.RawEvents.Trial{x}.Events;

        if BpodSystem.Data.TrialSequence(x) ==1
            LW_count(x)=1;
        elseif BpodSystem.Data.TrialSequence(x) ==2
            RW_count(x)=1;
        elseif BpodSystem.Data.TrialSequence(x) ==3
            LT_count(x)=1;
        elseif BpodSystem.Data.TrialSequence(x) ==4
            RT_count(x)=1;
        end

        if isfield(aa, 'AnalogIn1_1')
            first_lick_L(x) = aa.AnalogIn1_1(1);
        end
        if isfield(aa, 'AnalogIn1_2')
            first_lick_R(x) = aa.AnalogIn1_2(1);
        end

        if ~isnan(BpodSystem.Data.RawEvents.Trial{x}.States.Reward(1))
            if BpodSystem.Data.TrialSequence(x) ==1
                LW_correct(x)=1;
            elseif BpodSystem.Data.TrialSequence(x) ==2
                RW_correct(x)=1;
            elseif BpodSystem.Data.TrialSequence(x) ==3
                LT_correct(x)=1;
                elseif BpodSystem.Data.TrialSequence(x) ==4
                RT_correct(x)=1;
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
    
   % TrialTypeOutcomePlotModified(BpodSystem.GUIHandles.OutcomePlot,'update',BpodSystem.Data.nTrials+1,TrialTypes,Outcomes)

    figure(101); 
    plot(cumsum(LW_correct)./(cumsum(LW_count)),'-o');hold on;
    plot(cumsum(RW_correct)./(cumsum(RW_count)),'-o');
    plot(cumsum(LT_correct)./(cumsum(LT_count)),'-o');
    plot(cumsum(RT_correct)./(cumsum(RT_count)),'-o');

    plot(nancumsum(Outcomes2)./([1:length(Outcomes2)]),'-o','Color','#ad6bd3','MarkerFaceColor','#ad6bd3');
    hold off;
    legend({'LW','RW','LT','RT','cumulative'}, 'Location','northwest');

    xlabel('Trial #','fontsize',16);ylabel('Performance','fontsize',16); title(['Performance for Training ' num2str(S.GUI.TrainingLevel)],'fontsize',20)
    grid on
        
    figure(102);
    plot(first_lick_R','-o'); hold on;
    plot(first_lick_L','-o'); hold off;
    xlabel('Trial #','fontsize',16);ylabel('Time to lick (s)','fontsize',16); title(['Lick time ' num2str(S.GUI.TrainingLevel)],'fontsize',20)
    legend('right','left');
    grid on

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

    

end