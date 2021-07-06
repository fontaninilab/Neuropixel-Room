function spikeMat = getClusterSpikeTimes(spikeTimes,events,lickData);

trialStartTimes = events.trialStartEv./events.fsEv; %Convert timestamps to time (s)
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

for i = 1:length(trialStartTimes)-1
    
   trialIDX = find(spikeTimes >= trialStartTimes(i) & spikeTimes < trialStartTimes(i+1));
   trialN(trialIDX) = i;
   spikeTimesTrial(trialIDX) = spikeTimesTrial(trialIDX) - trialStartTimes(i);
   
   if nargin > 2
       centralAligned(trialIDX) = spikeTimesTrial(trialIDX) - lickData.firstCentral(2,i);
   end
       
    
end

trialIDX = find(spikeTimes >= trialStartTimes(end));
trialN(trialIDX) = length(trialStartTimes);
spikeTimesTrial(trialIDX) = spikeTimesTrial(trialIDX) - trialStartTimes(end);

if nargin > 2
   centralAligned(trialIDX) = spikeTimesTrial(trialIDX) - lickData.firstCentral(2,end);
end

spikeMat(1,:) = trialN;
spikeMat(2,:) = spikeTimes;
spikeMat(3,:) = spikeTimesTrial; 

if nargin > 2
   spikeMat(4,:) = centralAligned;
end

    

