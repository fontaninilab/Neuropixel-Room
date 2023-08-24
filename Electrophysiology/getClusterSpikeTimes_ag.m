function [spikeMat,spikeMatLabels] = getClusterSpikeTimes_ag(spikeTimes,events,LickData);
% Aligns spike times to trial start
%
% INPUTS
%  spikeTimes: 1xN array containing spike times (seconds) for a
%              single cluster over entire recording session.
%  events: a struct with event data (from getSpikeEventsKS.m)
%          .MouseID = Mouse ID
%          .SessionID = Session ID
%          .lickEv = struct with lick event indices
%          .trialStartEv = trial start event indices
%          .fsEv = nidaq sampling rate
%  LickData: struct with aligned lick times (from getLickTimes.m)
%
% OUTPUTS
%   spikeMat: (array) 4xN (or 3xN with no lickData input) array containing spike times 
%             (raw, trial aligned, central lick aligned) and trial # for each spike.
%   spikeMatLabels: (cell) 4x1 (or 3x1 with no lickData input) cell containing 
%                   string labels for each row in spikeMat.

trialStartTimes = events.trialStartEv./events.fsEv; %Convert timestamps to time (s)
if nargin > 2
    trialStartTimes = [LickData.TrialStartNP];

end

trialN = NaN(1,length(spikeTimes));
spikeTimesTrial = spikeTimes;

if nargin > 2
  % centralAligned = spikeTimes;
end

prestartspikes = find(spikeTimes < trialStartTimes(1));
trialN(prestartspikes) = 0;

if nargin > 2
  % centralAligned(prestartspikes) = NaN;
end

for i = 1:length(trialStartTimes)
   
    if i < length(trialStartTimes)
        trialIDX = find(spikeTimes >= trialStartTimes(i) & spikeTimes < trialStartTimes(i+1));
    elseif i == length(trialStartTimes) %last trial
        trialIDX = find(spikeTimes >= trialStartTimes(i));
    end
    
    trialN(trialIDX) = i;
    spikeTimesTrial(trialIDX) = spikeTimesTrial(trialIDX) - trialStartTimes(i);
   
   if nargin > 2
     %{
        if ~isempty(LickData(i).RightLicksNP)
            centralAligned(trialIDX) = spikeTimesTrial(trialIDX) - LickData(i).RightLicksNP(1);
        elseif ~isempty(LickData(i).LeftLicksNP)
            centralAligned(trialIDX) = spikeTimesTrial(trialIDX) - LickData(i).LeftLicksNP(1);
        end
     %}
   end
          
end

spikeMat(1,:) = trialN; spikeMatLabels{1,1} = 'Trial #';
spikeMat(2,:) = spikeTimes; spikeMatLabels{1,2} = 'spike times, recording start';
spikeMat(3,:) = spikeTimesTrial; spikeMatLabels{1,3} = 'spike times, trial start';
spikeMat(4,:) = spikeTimesTrial-2; spikeMatLabels{1,4} = 'spike times, sound start';
spikeMat(5,:) = zeros(1,length(spikeMat));  'spike times, sound start';


for i = 1:length(spikeMat(4,:))
    firstlicktime=0;
    if spikeMat(1,i) ~= 0
       if ~isempty(LickData(spikeMat(1,i)).FirstLickNP)
            firstlicktime = LickData(spikeMat(1,i)).FirstLickNP(2);
            spikeMat(5,i) =  spikeMat(3,i) - firstlicktime; spikeMatLabels{1,5} = 'spike times, first lick';

       else
       end
  
    end
end
if nargin > 2
 %  spikeMat(4,:) = centralAligned; spikeMatLabels{1,3} = 'spike times, first central';
end

    

