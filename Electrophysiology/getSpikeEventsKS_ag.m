function [spikes,events,fs,cellInfo,labels] = getSpikeEventsKS_ag(myPath)
%
% This function loads spikes, events, and other cell info from
% kilosort-sorted data recorded by spikeGLX.
%
% INPUTS:
%  root: the path to your data (for spikeGLX, should be 'rootdir\MouseID\SessionID\')
%
% OUTPUTS:
%  spikes: a struct with spike data; 
%          .times = spike times
%          .clust = cluster id per spike
%          .clustID = a list of unique clusters in the data
%          .labels = label of unit type per cluster
%          .chans = channel # for each cluster
%          .depth = depth (in um) of each cluster - distance above base
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

[trialStartEv, fsEv] = loadEventDataSGLX_ag(myPath,'D');
[lickEv, ~ ] =  loadEventDataSGLX_ag(myPath,'A',[1 2 3],{'central','left','right'});

% Save all event info in one
events.MouseID = nameChunks{1};
events.SessionID = nameChunks{2};
events.lickEv = lickEv;
events.trialStartEv = trialStartEv;
events.fsEv = fsEv;

% %%% Plot event times to manually check for alignment (optional) %%% %

% % figure;
% % scatter(trialStartEv./fsEv,1.02*ones(1,length(trialStartEv)),'*');
% % hold on; scatter(lickEv.central./fsEv,ones(1,length(lickEv.central)),'filled','k');
% % scatter(lickEv.left./fsEv,0.98*ones(1,length(lickEv.left)),'filled','r');
% % scatter(lickEv.right./fsEv,0.98*ones(1,length(lickEv.right)),'filled','b');
% % 
% % 
% % set(gca,'ylim',[0.95 1.05]);
% % legend('Trial start','central lick','left lick','right lick','Location','best');


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%        Extract spikes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%% 1. Load meta data for spike acquisition %%%%%%%%
% % ap_metaName = [fileChunks{end} '_t0.imec0.ap.meta']; %Name of ap.meta file
% % ap_meta = SGLXReadMeta(ap_metaName, [myPath '\' fileChunks{end} '_imec0']);

% ap_metaName = [fileChunks{end} '_t0_CAR.imec.ap.meta']; %Name of ap.meta file
%ap_metaName = [fileChunks{end} '_tcat.imec0.ap.meta']; %Name of ap.meta file
% ap_meta = SGLXReadMeta(ap_metaName, [myPath '\' fileChunks{end} '_CAR']);
% ap_meta = SGLXReadMeta(ap_metaName, [myPath '\' fileChunks{end} '_tcat']);
%ap_meta = SGLXReadMeta(ap_metaName,[myPath '\']);

%ap_metaName = [fileChunks{end} '_t0_CAR.imec.ap.meta'] %Name of ap.meta file
ap_metaName =  'AG05_test1_g0_t0_CAR.imec.ap.meta';
 %Name of ap.meta file
ap_meta = SGLXReadMeta(ap_metaName, myPath)
fs = str2double(ap_meta.imSampRate);

%%%%%%%% 2. Load spike times and cluster IDs %%%%%%%%
% % spks = double(readNPY(fullfile([myPath '\' fileChunks{end} '_imec0'],'spike_times.npy'))) / fs;
% % clust  = double(readNPY(fullfile([myPath '\' fileChunks{end} '_imec0'],'spike_clusters.npy')));

% spks = double(readNPY(fullfile([myPath '\' fileChunks{end} '_CAR'],'spike_times.npy'))) / fs;
% clust  = double(readNPY(fullfile([myPath '\' fileChunks{end} '_CAR'],'spike_clusters.npy')));
% spks = double(readNPY(fullfile([myPath '\' fileChunks{end} '_tcat'],'spike_times.npy'))) / fs;
% clust  = double(readNPY(fullfile([myPath '\' fileChunks{end} '_tcat'],'spike_clusters.npy')));
spks = double(readNPY(fullfile([myPath],'spike_times.npy'))) / fs;
clust  = double(readNPY(fullfile([myPath],'spike_clusters.npy')));


% load cluster groups
opts = delimitedTextImportOptions("NumVariables", 4);
opts.DataLines = [2, Inf];
opts.Delimiter = "\t";
opts.VariableNames = ["id", "Amplitude", "ContamPct", "KSLabel", "amp", "ch", "depth", "fr", "group", "n_spikes", "sh"];
opts.VariableTypes = ["double", "double", "double", "char", "double", "double", "double", "double", "char", "double", "double"];
%dat = readtable([myPath '\' fileChunks{end} '_tcat\cluster_info.tsv'],opts);
dat = readtable([myPath '\cluster_info.tsv'],opts);


% discard noise clusters
clustID = dat.id(~contains(dat.group,'noise'));
labels = dat.group(~contains(dat.group,'noise'));
chans = dat.ch(~contains(dat.group,'noise'));
depth = dat.depth(~contains(dat.group,'noise'));

spikes.times = spks;
spikes.clust = clust;
spikes.clustID = clustID;
spikes.labels = labels;
spikes.chans = chans;
spikes.depth = depth;


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Make cell info matrix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

labels = {'mouseID','sessionID','clustID','cellNum','unitType','unitTypeNum','channel','depth','meanFR'};
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
    cellInfo{i,7} = spikes.chans(i); % channel 
    cellInfo{i,8} = spikes.depth(i); % depth
    
    spks = spikes.times(spikes.clust == spikes.clustID(i)); %Will give spike times in seconds relative to recording start for each cluster
    spikes.spks{i} = spks;
    cellInfo{i,9} = length(spks) / (spks(end) - spks(1)); % mean fr
    
end

    


