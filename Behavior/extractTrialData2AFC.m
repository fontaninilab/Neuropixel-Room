function data = extractTrialData2AFC(SessionData)
% Extract trial-by-trial session data from BPOD 2AFC task structure
%
% INPUTS
% SessionData: BPOD output
%
% OUTPUTS
% data: struct with trial data from BPOD behavior acquisition
%         .trialn = trial number
%         .TrialStart = start time of trial relative to session start
%         .CentralLicks = array containing central lick time vector for each trial
%         .LeftLicks = array containing left lick time vector for each trial
%         .RightLicks = array containing right lick time vector for each trial
%         .TrialSequence = Trial type for each trial
%         .ValveSequence = central valve ID for each trial
%         .sampleCentralev = time window for sampling from central spout
%         .sampleLateralev = time window for sampling from lateral spout

nTrials = SessionData.nTrials;

for i = 1:nTrials
    data(i).trialn = i;
    data(i).TrialStart = SessionData.TrialStartTimestamp(i);
    
    %Central licks
    if any(strcmp(fieldnames(SessionData.RawEvents.Trial{1,i}.Events),'AnalogIn1_3'))
        data(i).CentralLicks = SessionData.RawEvents.Trial{1,i}.Events.AnalogIn1_3(1,:);
    else data(i).CentralLicks = [];
    end
    
    %Right licks
    if any(strcmp(fieldnames(SessionData.RawEvents.Trial{1,i}.Events),'AnalogIn1_2'))  
        data(i).RightLicks = SessionData.RawEvents.Trial{1,i}.Events.AnalogIn1_2(1,:);
    else data(i).RightLicks = [];
    end
    
    %Left licks
    if any(strcmp(fieldnames(SessionData.RawEvents.Trial{1,i}.Events),'AnalogIn1_1'))
        data(i).LeftLicks = SessionData.RawEvents.Trial{1,i}.Events.AnalogIn1_1(1,:);  
    else data(i).LeftLicks = [];
    end
    
   data(i).TrialSequence = SessionData.TrialSequence(i);   
   data(i).reward = ~isnan(SessionData.RawEvents.Trial{1,i}.States.reward(1,1));
   
   if isfield(SessionData,'ValveSequence')
        data(i).ValveSequence = SessionData.ValveSequence(i);
   end
   
   %Time window of sampling for central licks
    if ~isempty(data(i).CentralLicks)
        data(i).sampleCentralev(1) = SessionData.RawEvents.Trial{1,i}.States.WaitForLicks(1); 
        data(i).sampleCentralev(2) = SessionData.RawEvents.Trial{1,i}.States.MyDelay(2);
    else
        data(i).sampleCentralev = SessionData.RawEvents.Trial{1,i}.States.WaitForLicks;
    end
    
    %Time window of sampling for lateral licks
    if data(i).reward
        data(i).sampleLateralev(1) = SessionData.RawEvents.Trial{1,i}.States.WaitForLateralLicks(1); 
        data(i).sampleLateralev(2) = SessionData.RawEvents.Trial{1,i}.States.Drinking(2);
    else
        data(i).sampleLateralev = SessionData.RawEvents.Trial{1,i}.States.WaitForLateralLicks;
    end
   
end 

