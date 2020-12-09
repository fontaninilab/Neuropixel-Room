function [spikes,events,fs,cellInfo,labels] = getSpikeEventsKS(myPath)
%
%
% This function loads spikes, events, and other cell info from
% kilosort-sorted data recorded by spikeGLX.
%
% INPUTS:
%  root: the path to your data (for spikeGLX, should be 'rootdir\MouseID\SessionID\'
%
% OUTPUTS:
%  spikes: a struct with spike data; 
%          .times = spike times
%          .clust = cluster id per spike
%          .clustID = a list of unique clusters in the data
%          .labels = label of unit type per cluster
%          .spks = cell containing spike times for each cluster
%  events: a struct with event data; %
%          .MouseID = Mouse ID
%          .SessionID = Session ID
%          .lickEv = struct with lick event indices
%          .trialStartEv = trial start event indices
%          .fsEv = nidaq sampling rate
%  fs: recording sampling rate
%  cellInfo: cell array with information for each cluster
%  labels: cell array with the labels for each column in cell info

%% Extract file names
fileChunks = strsplit(myPath,'\');
nameChunks = strsplit(fileChunks{end},'_');

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%        Extract events
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[lickEv, trialStartEv, fsEv] = loadEventDataSGLX(myPath,0);

% Save all event info in one
events.MouseID = nameChunks{1};
events.SessionID = nameChunks{2};
events.lickEv = lickEv;
events.trialStartEv = trialStartEv;
events.fsEv = fsEv;


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%        Extract spikes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%% 1. Load meta data for spike acquisition %%%%%%%%
ap_metaName = [fileChunks{end} '_t0.imec0.ap.meta']; %Name of ap.meta file
ap_meta = SGLXReadMeta(ap_metaName, [myPath '\' fileChunks{end} '_imec0']);
fs = str2double(ap_meta.imSampRate);

%%%%%%%% 2. Load spike times and cluster IDs %%%%%%%%
spks = double(readNPY(fullfile([myPath '\' fileChunks{end} '_imec0'],'spike_times.npy'))) / fs;
clust  = double(readNPY(fullfile([myPath '\' fileChunks{end} '_imec0'],'spike_clusters.npy')));

% load cluster groups
fid = fopen(fullfile([myPath '\' fileChunks{end} '_imec0'],'cluster_group.tsv'));
textscan(fid,'%s\t%s\n');     % header
dat = textscan(fid,'%d\t%s'); % data
fclose(fid);

% discard noise clusters
clustID = dat{1}(~contains(dat{2},'noise'));
labels = dat{2}(~contains(dat{2},'noise'));

spikes.times = spks;
spikes.clust = clust;
spikes.clustID = clustID;
spikes.labels = labels;


%% Make cell info matrix

labels = {'mouseID','sessionID','clustID','cellNum','unitType','unitTypeNum','meanFR'};
for i = 1:length(spikes.clustID)
    
    cellInfo{i,1} = nameChunks{1}; % mouse
    cellInfo{i,2} = nameChunks{2}; % session
    cellInfo{i,3} = spikes.clustID(i); % cluster ID
    cellInfo{i,4} = i; % unit number;
    cellInfo{i,5} = spikes.labels{i}; % unit type

    if strcmp(cellInfo{i,5},'good')
        cellInfo{i,6} = 1;
    elseif strcmp(cellInfo{i,5},'mua')
        cellInfo{i,6} = 2;
    end
    spks = spikes.times(spikes.clust == spikes.clustID(i)); %Will give spike times in seconds relative to recording start for each cluster
    spikes.spks{i} = spks;
    cellInfo{i,7} = length(spks) / (spks(end) - spks(1)); % mean fr
    
end
    


