function Opto_Bpod
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
    S.ITI = 10;
    S.Stim_Time = 2; 
    S.train = 0;
    S.pulse_volts = 0;
    S.pulse_duration = 0; 
    S.interpulse_interval = 0;
end


W = BpodWavePlayer('COM10');
samples = W.SamplingRate;
total_duration = S.Stim_Time;

pulse_volts = [5 5 5 5];
%pulse_duration = [0.00025 0.00035 0.00054 0.00076];
%interpulse_interval = [0.00075 0.00065 0.00046 0.00024];

pulse_duration = [0.00076 0.0008 0.0009 0.00099];
interpulse_interval = [0.00024 0.0002 0.0001 0.00001];

% TRAIN 1 ideal = 23.6uW = 125uW/mm
% actual = ~24uW
train1 = create_pulsetrain(pulse_volts(1), pulse_duration(1), interpulse_interval(1), total_duration, samples);

% TRAIN 2 ideal= 47.25uW = 250uW/mm
% actual ~52
train2 = create_pulsetrain(pulse_volts(2), pulse_duration(2), interpulse_interval(2), total_duration, samples);

% TRAIN 3 ideal= 94.5uW = 500uW/mm
% actual ~89
train3 = create_pulsetrain(pulse_volts(3), pulse_duration(3), interpulse_interval(3), total_duration, samples);

% TRAIN 4 ideal= 189uW = 1000uW/mm
% actual ~ 200
train4 = create_pulsetrain(pulse_volts(4), pulse_duration(4), interpulse_interval(4), total_duration, samples);

W.loadWaveform(1, train1);
W.loadWaveform(2, train2);
W.loadWaveform(3, train3);
W.loadWaveform(4, train4);

LoadSerialMessages('WavePlayer1', {['P' 3 0], ['P' 3 1], ['P' 3 2], ['P' 3 3], ['P' 3 4]});

W.OutputRange = '0V:5V';
W.TriggerMode = 'Master';

for currentTrial = 1:MaxTrials
    r = randi([1 4]);

    S.train = r;
    S.pulse_volts = pulse_volts(r);
    S.pulse_duration = pulse_duration(r); 
    S.interpulse_interval = interpulse_interval(r);

    sprintf('Trial %i Running, train %g, voltage %g, duration %g, ipi %g',currentTrial,S.train,...
        S.pulse_volts, S.pulse_duration, S.interpulse_interval)
    
    %--- Assemble state machine
    sma = NewStateMachine();
    
    sma = AddState(sma, 'Name', 'Opto_Stim', ...
        'Timer', S.Stim_Time,...
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {'WavePlayer1',r,'BNCState',1}); 

    sma = AddState(sma, 'Name', 'ITI', ... % ITI
        'Timer', S.ITI,...
        'StateChangeConditions', {'Tup', '>exit'},...
        'OutputActions', {'BNCState',0}); 

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
        delete(port);
        clear global port;
        return
    end
end
