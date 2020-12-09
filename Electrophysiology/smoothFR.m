function [smoothedFR,spikePSTH] = smoothFR(SpikeData,nRep,binsize,timeWin,smoothWin)
%Smooths spike data by convolving firing rates with a gaussian filter
%
%Input:
    %SpikeData = matrix [time(relative to trial onset); trial #]
    %nRep = number of repeats in the stimulus
    %binsize = size of bin (in seconds) for histogram of spike data
    %timeWin = The time window (in seconds) of a single trial [start end]
    %smoothWin = Input for SmoothGaus function that gives the number of
    %            bins over which to smooth.
    
t = [timeWin(1):binsize:timeWin(2)];

f = histc(SpikeData, t)/(nRep*binsize); %dividing by nRep averages the number of spikes over the trials instead of just summing them and dividing by binsize makes it spikes per second instead of spikes per 5ms.

spikePSTH = f(1:end-1);

smoothedFR = SmoothGaus(spikePSTH, smoothWin);

end