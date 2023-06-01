function Laser_Stim_Only 
global BpodSystem

%% Setup (runs once before the first trial)
MaxTrials = 500; % Set to some sane value, for preallocation

%--- Define parameters and trial structure
S = BpodSystem.ProtocolSettings; % Loads settings file chosen in launch manager into current workspace as a struct called 'S'
if isempty(fieldnames(S))  % If chosen settings file was an empty struct, populate struct with default settings
    % Define default settings here as fields of S (i.e S.InitialDelay = 3.2)
    % Note: Any parameters in S.GUI will be shown in UI edit boxes. 
    % See ParameterGUI plugin documentation to show parameters as other UI types (listboxes, checkboxes, buttons, text)
    S.GUI.Stim_Voltage = 0;
    S.GUI.ITI = 5;
    S.GUI.Stim_Time = 2; 
end

W = BpodWavePlayer('COM5');
W.OutputRange = '0V:5V';
W.TriggerMode = 'Master'; %trigger mode allows for pulses to interrupt eachother, pulses must be longer than states
% W.BpodEvents{1} = 'On'; W.BpodEvents{2} = 'On'; W.BpodEvents{3} = 'On'; W.BpodEvents{4} = 'On';
voltages2use=[];
voltages2use = .5:.5:2; %input the range of voltages to use for opto stim (check these on oscope for accuracy)
waveNumber={};
for i=1:length(voltages2use)
   waveNumber{i} =  repmat(voltages2use(i),1,(3*10000)); %constant outpu
%      waveNumber{i} =  repmat([repmat(voltages2use(i),1,1000) repmat(2.5,1,500)],1,60); %example of pulsed output

   W.loadWaveform(i,waveNumber{i})
end
waveNumber{length(voltages2use)+1} =  repmat(2.5,1,(6*10000)); %ITI, voltage is set to high (2.5V) so that shutter is off
W.loadWaveform(length(voltages2use)+1,waveNumber{length(voltages2use)+1});
% generate pseudorandom order to present different voltage sequences
trial_sequences = repmat(1:length(voltages2use),1,3);
num_rand_sequences = round(MaxTrials/length(trial_sequences))+1; %generate enough sequences for all the trials
random_order=[]; %this will be the full sequence of wave numbers to use for each trial
for i=1:num_rand_sequences %loop through so that sequences are pseudorandom across the session
    random_order = [random_order trial_sequences(randperm(length(trial_sequences)))];
end
%--- Initialize plots and start USB connections to any modules
BpodParameterGUI('init', S); % Initialize parameter GUI plugin

%% Main loop (runs once per trial)
for currentTrial = 1:MaxTrials
    S.GUI.Stim_Voltage = voltages2use(random_order(currentTrial));
    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
    LoadSerialMessages('WavePlayer1', {['P' 11 random_order(currentTrial)-1],...
        ['P' 11 4]});  % Set serial message 1 %output on channels 1 and 2
    sprintf('Trial %i Running, Stim Voltage %g',currentTrial, S.GUI.Stim_Voltage )

    %--- Typically, a block of code here will compute variables for assembling this trial's state machine
    
    %--- Assemble state machine
    sma = NewStateMachine();
    
    sma = AddState(sma, 'Name', 'Opto_Stim', ... % This example state does nothing, and ends after 0 seconds
        'Timer', 2,...
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {'WavePlayer1',1,'BNCState',1}); 
%     sma = AddState(sma, 'Name', 'Stim_end', ... % This example state does nothing, and ends after 0 seconds
%         'Timer', 3,...
%         'StateChangeConditions', {'Tup', 'Stim_end'},...
%         'OutputActions', {'WavePlayer1',2}); 
    sma = AddState(sma, 'Name', 'ITI', ... % ITI
        'Timer', 5,...
        'StateChangeConditions', {'Tup', 'exit'},...
        'OutputActions', {'WavePlayer1',2,'BNCState',0}); 
%     sma = AddState(sma, 'Name', 'Trial_done', ... % ITI
%         'Timer', 0,...
%         'StateChangeConditions', {'Tup', 'exit'},...
%         'OutputActions', {}); 
    SendStateMatrix(sma); % Send state machine to the Bpod state machine device
    RawEvents = RunStateMatrix; % Run the trial and return events
    %--- Package and save the trial's data, update plots
    if ~isempty(fieldnames(RawEvents)) % If you didn't stop the session manually mid-trial
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Adds raw events to a human-readable data struct
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
        
        %--- Typically a block of code here will update online plots using the newly updated BpodSystem.Data
        
    end
    
    %--- This final block of code is necessary for the Bpod console's pause and stop buttons to work
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    if BpodSystem.Status.BeingUsed == 0
        return
    end
end