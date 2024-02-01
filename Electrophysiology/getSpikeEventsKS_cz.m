function [spikes,events,fs,cellInfo,labels] = getSpikeEventsKS_cz(myPath,MouseID,SessionID,SessionGate)
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
run_name=[MouseID '_' SessionID '_g' SessionGate];
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%        Extract events
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

NI_binName = [run_name '_t0.nidq.bin'];
[trialStartEv, fsEv] = loadEventDataSGLX_cz(myPath,NI_binName,'D');
[lickEv, ~ ] =  loadEventDataSGLX_cz(myPath,NI_binName,'A',[1 2 3],{'central','left','right'});

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

% ap_metaName = [fileChunks{end} '_tcat.imec0.ap.meta']; %Name of ap.meta file
% ap_meta = SGLXReadMeta(ap_metaName, [myPath '\' fileChunks{end} '_imec0']);

% ap_metaName = [fileChunks{end} '_t0_CAR.imec.ap.meta']; %Name of ap.meta file
% ap_meta = SGLXReadMeta(ap_metaName, [myPath '\' fileChunks{end} '_CAR']);

% ap_metaName = [fileChunks{end} '_t0.imec0.ap.meta']; %Name of ap.meta file
% ap_meta = SGLXReadMeta(ap_metaName, [myPath '\' fileChunks{end} '_imec0']);

% ap_metaName = [run_name '_t0.imec0.ap.meta']; %Name of ap.meta file
ap_metaName = [run_name '_tcat.imec0.ap.meta']; %Name of ap.meta file
% ap_metaName = [fileChunks{end} '_tcat.imec0.ap.meta']; %Name of ap.meta file

ap_meta = SGLXReadMeta(ap_metaName, [myPath '\' run_name '_imec0']);
% ap_meta = SGLXReadMeta(ap_metaName, [myPath '\' fileChunks{end} '_imec0']);

fs = str2double(ap_meta.imSampRate);

%%%%%%%% 2. Load spike times and cluster IDs %%%%%%%%
% spks = double(readNPY(fullfile([myPath '\' fileChunks{end} '_CAR'],'spike_times.npy'))) / fs;
% clust  = double(readNPY(fullfile([myPath '\' fileChunks{end} '_CAR'],'spike_clusters.npy')));

% spks = double(readNPY(fullfile([myPath '\' fileChunks{end} '_imec0'],'spike_times.npy'))) / fs;
% clust  = double(readNPY(fullfile([myPath '\' fileChunks{end} '_imec0'],'spike_clusters.npy')));

% spks = double(readNPY(fullfile([myPath '\' fileChunks{end} '_imec0\imec0_ks3'],'spike_times.npy'))) / fs;
% clust  = double(readNPY(fullfile([myPath '\' fileChunks{end} '_imec0\imec0_ks3'],'spike_clusters.npy')));
spks = double(readNPY(fullfile([myPath '\' run_name  '_imec0\imec0_ks3'],'spike_times.npy'))) / fs;
clust  = double(readNPY(fullfile([myPath '\' run_name  '_imec0\imec0_ks3'],'spike_clusters.npy')));


% load cluster groups
opts = delimitedTextImportOptions("NumVariables", 38);
opts.DataLines = [2, Inf];
opts.Delimiter = "\t";
% opts.VariableNames = ["id", "Amplitude", "ContamPct", "KSLabel", "amp", "ch", "depth", "fr", "group", "n_spikes", "sh"];
% opts.VariableTypes = ["double", "double", "double", "char", "double", "double", "double", "double", "char", "double", "double"];
opts.VariableNames = ["id",  "ContamPct", "KSLabel", "PT_ratio", "amp","amplitude","amplitude_cutoff", "ch", "contam_rate","cumulative_drift","d_prime","depth", "duration","epoch_name","epoch_name_quality_metrics","epoch_name_waveform_metrics","firing_rate","fr","group","halfwidth","isi_viol","isolation_distance","l_ratio","max_drift","n_spikes","nn_hit_rate","nn_miss_rate","num_viol","peak_channel","presence_ratio","recovery_slope","repolarization_slope","sh","silhouette_score","snr","spread","velocity_above","velocity_below"];
opts.VariableTypes = ["double", "double", "char",    "double",  "double","double",  "double",       "double", "double",   "double",         "double",  "double" ,"double",  "char",   "char", "char",                                                "double", "double", "char",   "double", "double",   "double",  "double", "double",  "double", "double",   "double",          "double",   "double",      "double",      "double",             "double",   "double", "double",        "double", "double","double", "double"];
% dat = readtable([myPath '\' fileChunks{end} '_imec0\cluster_info.tsv'],opts);
% dat = readtable([myPath '\' fileChunks{end} '_CAR\cluster_info.tsv'],opts);
dat = readtable([myPath '\' run_name '_imec0\imec0_ks3\cluster_info.tsv'],opts);

% discard noise clusters and clusters with no group name (not marked when
% sorting)
% clustID = dat.id(~contains(dat.group,'noise'));
% labels = dat.group(~contains(dat.group,'noise'));
% chans = dat.ch(~contains(dat.group,'noise'));
% depth = dat.depth(~contains(dat.group,'noise'));
clustID = dat.id(~contains(dat.group,'noise')&~strcmp(dat.group,""));
labels = dat.group(~contains(dat.group,'noise')&~strcmp(dat.group,""));
chans = dat.ch(~contains(dat.group,'noise')&~strcmp(dat.group,""));
depth = dat.depth(~contains(dat.group,'noise')&~strcmp(dat.group,""));
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

    cellInfo{i,1} = MouseID; % mouse
    cellInfo{i,2} = SessionID; % session
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




