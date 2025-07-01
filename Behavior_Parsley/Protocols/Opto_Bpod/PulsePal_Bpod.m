function PulsePal_Bpod
global BpodSystem
global port;
port=serialport('COM9', 115200,"DataBits",8,FlowControl="none",Parity="none",StopBits=1,Timeout=0.5);
setDTR(port,true);
configureTerminator(port,"CR/LF");
fopen(port);

MaxTrials = 500; % Set to some sane value, for preallocation

%--- Define parameters and trial structure
S = BpodSystem.ProtocolSettings; % Loads settings file chosen in launch manager into current workspace as a struct called 'S'
if isempty(fieldnames(S))  % If chosen settings file was an empty struct, populate struct with default settings
    % Define default settings here as fields of S (i.e S.InitialDelay = 3.2)
    % Note: Any parameters in S.GUI will be shown in UI edit boxes. 
    % See ParameterGUI plugin documentation to show parameters as other UI types (listboxes, checkboxes, buttons, text)
    %S.GUI.Stim_Voltage = 0;
    %S.GUI.ITI = 6;
    %S.GUI.Stim_Time = 2; 
end


W = BpodWavePlayer('COM10');

samples = W.SamplingRate;

pulse_duration =  0.0008;
interpulse_interval = 0.0002;
total_duration = 2;

numreps = total_duration/(pulse_duration + interpulse_interval);
pulse_duration_samples = pulse_duration * samples;
interpulse_interval_samples = interpulse_interval * samples;

pulse_volts = 4;
pulse_volts_samples = pulse_volts*ones(1,pulse_duration_samples)
interpulse_volts_samples = zeros(1,interpulse_interval_samples);

pulse_train = repmat([pulse_volts_samples,interpulse_volts_samples],1,numreps);
%pulse_train = repmat([pulse_volts_samples],1,2*numreps);

W.loadWaveform(1, pulse_train);
LoadSerialMessages('WavePlayer1', {['P' 3 0], ['P' 3 1]});


W.OutputRange = '0V:5V';
W.TriggerMode = 'Master';

for currentTrial = 1:MaxTrials
    %S.GUI.Stim_Voltage = voltages2use(random_order(currentTrial));
    %S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
    %LoadSerialMessages('WavePlayer1', {['P' 11 1]}, 1)
    %LoadSerialMessages('WavePlayer1', {['P' 11 random_order(currentTrial)-1],...
   %     ['P' 11 4]});  % Set serial message 1 %output on channels 1 and 2
   % sprintf('Trial %i Running, Stim Voltage %g',currentTrial, S.GUI.Stim_Voltage )

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
        'OutputActions', {'BNCState',0}); 
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
