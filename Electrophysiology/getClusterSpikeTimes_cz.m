function [spikeMat,spikeMatLabels] = getClusterSpikeTimes_cz(spikeTimes,events,LickData)
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
    centralAligned = spikeTimes;
end

prestartspikes = find(spikeTimes < trialStartTimes(1));
trialN(prestartspikes) = 0;

if nargin > 2
    centralAligned(prestartspikes) = NaN;
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

        centralAligned(trialIDX) = spikeTimesTrial(trialIDX) - LickData(i).CentralLicksNP(1);
        if ~isempty(LickData(i).FirstLatNP)
            firstLatAligned(trialIDX) = spikeTimesTrial(trialIDX) - LickData(i).FirstLatNP;
        else
            firstLatAligned(trialIDX) = 0;
        end

    end

end

spikeMat(1,:) = trialN; spikeMatLabels{1,1} = 'Trial #';
spikeMat(2,:) = spikeTimes; spikeMatLabels{1,2} = 'spike times, recording start';
spikeMat(3,:) = spikeTimesTrial; spikeMatLabels{1,3} = 'spike times, trial start';

if nargin > 2
    spikeMat(4,:) = centralAligned; spikeMatLabels{1,3} = 'spike times, first central';
    spikeMat(5,:) = firstLatAligned; spikeMatLabels{1,5} = 'spike times, first lateral';
end



