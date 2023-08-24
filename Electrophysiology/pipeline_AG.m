rootdir = 'C:\Users\admin\Documents\DATA\AG\';
sep = '\';
outputdir = 'C:\Users\admin\Documents\DATA\AG\Spikes\';

MouseID = 'AG10';
SessionID = 'session1';

NI_path = 'Z:\Fontanini\Allison\Animal data\AG10\Odor2AC_testing\session1';


%% getSpikeEvents
% loadEventDataSGLX

NI_binName = 'AG10_session1_g0_t0.nidq.bin';
NI_metaName = 'AG10_session1_g0_t0.nidq.meta';

% SGLXReadMeta
fid = fopen(fullfile(NI_path,NI_metaName), 'r');
C = textscan(fid, '%[^=] = %[^\r\n]');
fclose(fid);

NI_meta = struct();

% Convert each cell entry into a struct entry
for i = 1:length(C{1})
    tag = C{1}{i};
    if tag(1) == '~'
        % remake tag excluding first character
        tag = sprintf('%s', tag(2:end));
    end
    NI_meta = setfield(NI_meta, tag, C{2}{i});
end
fsEv = str2double(NI_meta.niSampRate);
nChan = str2double(NI_meta.nSavedChans);
nFileSamp = str2double(NI_meta.fileSizeBytes) / (2 * nChan);
nSamp = nFileSamp;
%%
%SGLXReadBin
nChan = str2double(NI_meta.nSavedChans);
nFileSamp = str2double(NI_meta.fileSizeBytes) / (2 * nChan);
samp0 = 0;
nSamp = min(nSamp, nFileSamp - samp0);

sizeA = [nChan, nSamp];

fid = fopen(fullfile(NI_path, NI_binName), 'rb');
fseek(fid, samp0 * 2 * nChan, 'bof');
dataArray = fread(fid, sizeA, 'int16=>double');
fclose(fid);

%% 1. Load analog channel data (these are the lick events) %%%

lickChanID = {'central','left','right'};
ch = [1 2 3];

M = str2num(NI_meta.snsMnMaXaDw);
MN = M(1);
MA = M(2);
if strcmp(NI_meta.typeThis, 'imec')
    fI2V = str2double(NI_meta.imAiRangeMax) / 512;
else
    fI2V = str2double(NI_meta.niAiRangeMax) / 32768;
end

dataArrayA = dataArray(ch,:); 

for i = 1:length(ch)
    j = ch(i);    % index into timepoint

    % ChanGainNI
    if j <= MN
        gain = str2double(NI_meta.niMNGain);    
    elseif j <= MN + MA
        gain = str2double(NI_meta.niMAGain);
    else
        gain = 1;
    end

    conv = fI2V / gain;
    dataArrayA(j,:) = dataArrayA(j,:) * conv;
end

%Extract lick indices from data array
for i = 2:length(lickChanID)
    lickIDX = find(dataArrayA(i,:)>0.5);
    lickIDXdiff = diff(lickIDX);
    lickstart = find(lickIDXdiff > 1) + 1;
    firsttrial = 1;
    lickEv.(lickChanID{i}) = lickIDX([firsttrial lickstart]);    
end
%% Load digital trial data

dwReq = 1;
dLineList = 0;
if strcmp(NI_meta.typeThis, 'imec')
     fprintf('missing channel counts IM');
else
    % ChannelCountsNi
    M = str2num(NI_meta.snsMnMaXaDw);
    MN = M(1);
    MA = M(2);
    XA = M(3);
    DW = M(4);

    % extractDigital
    if dwReq > DW
        fprintf('Maximum digital word in file = %d\n', DW);
        digArray = [];
    else
        digCh = MN + MA + XA + dwReq;
    end
end

[~,nSamp] = size(dataArray);
digArray = zeros(numel(dLineList), nSamp, 'uint8');
for i = 1:numel(dLineList)
    digArray(i,:) = bitget(dataArray(digCh,:), dLineList(i)+1, 'int16');
end

digPeakIDX = find(digArray); %Finds indices where values are > 0
digPeakDiff = diff(digPeakIDX); %Calculates difference between adjacent indices of digPeakIDX
boutstart = find(digPeakDiff > 1)+1; %Find where difference between consecutive indices is > 1 (and add 1 for correct start index)
firsttrial = 1;
trialStartEv = digPeakIDX([firsttrial boutstart]); %Extract indices of each trial start

Ev = trialStartEv;

% save all events
events.MouseID = MouseID;
events.SessionID = SessionID;
events.lickEv = lickEv;
events.trialStartEv = trialStartEv;
events.fsEv = fsEv;
%% Extract spikes

AP_path = 'C:\Users\admin\Documents\DATA\AG\AG10_maxz_catgfixonly\catgt_AG10_session1_g0\AG10_session1_g0_imec0';
AP_metaName = 'AG10_session1_g0_tcat.imec0.ap.meta';

% SGLXReadMeta
fid = fopen(fullfile(AP_path,AP_metaName), 'r');
C = textscan(fid, '%[^=] = %[^\r\n]');
fclose(fid);

% New empty struct
AP_meta = struct();

% Convert each cell entry into a struct entry
for i = 1:length(C{1})
    tag = C{1}{i};
    if tag(1) == '~'
        % remake tag excluding first character
        tag = sprintf('%s', tag(2:end));
    end
    AP_meta = setfield(AP_meta, tag, C{2}{i});
end
fs = str2double(AP_meta.imSampRate);
%%
NPY_path = 'C:\Users\admin\Documents\DATA\AG\AG10_maxz_catgfixonly\catgt_AG10_session1_g0\AG10_session1_g0_imec0\imec0_ks3';
spks = double(readNPY(fullfile(NPY_path,'spike_times.npy'))) / fs;
clust  = double(readNPY(fullfile(NPY_path,'spike_clusters.npy')));

% load cluster groups
opts = delimitedTextImportOptions("NumVariables", 4);
opts.DataLines = [2, Inf];
opts.Delimiter = "\t";
opts.VariableNames = ["id", "Amplitude", "ContamPct", "KSLabel", "amp", "ch", "depth", "fr", "group", "n_spikes", "sh"];
opts.VariableTypes = ["double", "double", "double", "char", "double", "double", "double", "double", "char", "double", "double"];
dat = readtable([NPY_path '\cluster_info.tsv'],opts);

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

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Align and save NP lick times
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% % % Run this section only if you have lick data % % %

%cd([outputdir MouseID]);

fprintf('Select data file from BEHAVIOR ACQUISITION COMPUTER:\n');

%Open lick events from NP acquisition and BEHAVIOR acquisition - Will use event timestamps to remove licks outside of wait period
[behaviorfile,behaviorpath] = uigetfile({'*.mat'},'Select data file from BEHAVIOR ACQUISITION COMPUTER:');
load([behaviorpath sep behaviorfile]); 

%extractTrialData2AFC
nTrials = SessionData.nTrials;

for i = 1:nTrials
    data(i).trialn = i;
    data(i).TrialStart = SessionData.TrialStartTimestamp(i);
    
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
   data(i).Reward = ~isnan(SessionData.RawEvents.Trial{1,i}.States.Reward(1,1));
   
   if isfield(SessionData,'ValveSequence')
        data(i).ValveSequence = SessionData.ValveSequence(i);
   end
   
    %Time window of sampling for lateral licks
    if ~isnan(SessionData.RawEvents.Trial{1,i}.States.Drinking(2))
        data(i).sampleLateralev(1) = SessionData.RawEvents.Trial{1,i}.States.WaitForLateralLicks(1); 
        data(i).sampleLateralev(2) = SessionData.RawEvents.Trial{1,i}.States.Drinking(2);
    else
        data(i).sampleLateralev = SessionData.RawEvents.Trial{1,i}.States.WaitForLateralLicks;
    end
end 

%% bpod behavior data
%LickData = getLickTimes_ag(events,behaviorEvents,0); %Add to this code input from behavior computer to delete error licks
behaviorEvents = data;
nTrials = size(behaviorEvents,2);
aCount = 0; bCount = 0; cCount = 0;

for i = 1:nTrials
     if ~isempty(behaviorEvents(i).LeftLicks(:))
         a = find(behaviorEvents(i).LeftLicks(1:end) > behaviorEvents(i).sampleLateralev(2) | behaviorEvents(i).LeftLicks(1:end) < behaviorEvents(i).sampleLateralev(1));
         behaviorEvents(i).LeftLicks(a) = []; 
         aCount = aCount + length(a);
     end 
end

for i = 1:nTrials
     if ~isempty(behaviorEvents(i).RightLicks(:))
         b = find(behaviorEvents(i).RightLicks(1:end) > behaviorEvents(i).sampleLateralev(2) | behaviorEvents(i).RightLicks(1:end) < behaviorEvents(i).sampleLateralev(1));  
         behaviorEvents(i).RightLicks(b) = [];
         bCount = bCount + length(b);
     end
end

fprintf('Removed %d left licks and %d right licks from BPOD data\n',[aCount + bCount,cCount]);

npEvents = events;
trialStartTimes = npEvents.trialStartEv./npEvents.fsEv; 
leftLickTimesNP = npEvents.lickEv.left./npEvents.fsEv;
rightLickTimesNP = npEvents.lickEv.right./npEvents.fsEv;
for i = 1:nTrials

    aCount = 0; bCount = 0; cCount = 0;
    behaviorEvents(i).TrialStartNP = trialStartTimes(i);


    if i < length(trialStartTimes)
           trialIDXright = find(rightLickTimesNP >= trialStartTimes(i) & rightLickTimesNP < trialStartTimes(i+1));%Find lick times for trial i
       else
           trialIDXright = find(rightLickTimesNP >= trialStartTimes(end));
    end
       
   rightTrialAligned = rightLickTimesNP(trialIDXright) - trialStartTimes(i);       

   b = find(rightTrialAligned > behaviorEvents(i).sampleLateralev(2) | rightTrialAligned < behaviorEvents(i).sampleLateralev(1));      
   rightTrialAligned(b) = []; trialIDXright(b) = [];
   bCount = bCount + length(b);

   behaviorEvents(i).RightLicksNP = rightTrialAligned;       
 
   if i < length(trialStartTimes)
        trialIDXleft = find(leftLickTimesNP >= trialStartTimes(i) & leftLickTimesNP < trialStartTimes(i+1));%Find lick times for trial i
   else
        trialIDXleft = find(leftLickTimesNP >= trialStartTimes(end));
   end
   
   leftTrialAligned = leftLickTimesNP(trialIDXleft) - trialStartTimes(i);       
   
   %Remove licks outside of sampling window
   a = find(leftTrialAligned > behaviorEvents(i).sampleLateralev(2) | leftTrialAligned < behaviorEvents(i).sampleLateralev(1));      
   leftTrialAligned(a) = []; trialIDXleft(a) = [];
   aCount = aCount + length(a);

   LickTimesNP{i,2} = leftTrialAligned;
   behaviorEvents(i).LeftLicksNP = leftTrialAligned;

end

for i = 1:nTrials
    aCount = 0; bCount = 0; cCount = 0;

    behaviorEvents(i).TrialStartNP = trialStartTimes(i);
    
%%% Central lick times for trial i %%%
%{
    %Extract indices of central licks for trial i
   if i < length(trialStartTimes)        
       trialIDXcentralNP = find(centralLickTimesNP >= trialStartTimes(i) & centralLickTimesNP < trialStartTimes(i+1)); %Find lick times for trial i   
   else    
       trialIDXcentralNP = find(centralLickTimesNP >= trialStartTimes(end));
   end

   if ~isempty(trialIDXcentralNP)
       
       centralTrialAligned = centralLickTimesNP(trialIDXcentralNP) - trialStartTimes(i); %Align to trial start time
             
       %Remove licks outside of sampling window
       c = find(centralTrialAligned > behaviorEvents(i).sampleCentralev(2) | centralTrialAligned < behaviorEvents(i).sampleCentralev(1));      
       centralTrialAligned(c) = []; trialIDXcentralNP(c) = [];
       cCount = cCount + length(c);

       %LickTimesNP{i,1} = centralTrialAligned;
       behaviorEvents(i).CentralLicksNP = centralTrialAligned;
%}
%%% Right lick times for trial i %%%
       if i < length(trialStartTimes)
           trialIDXright = find(rightLickTimesNP >= trialStartTimes(i) & rightLickTimesNP < trialStartTimes(i+1));%Find lick times for trial i
       else
           trialIDXright = find(rightLickTimesNP >= trialStartTimes(end));
       end
       
       rightTrialAligned = rightLickTimesNP(trialIDXright) - trialStartTimes(i);       
       
       %Remove licks outside of sampling window
       b = find(rightTrialAligned > behaviorEvents(i).sampleLateralev(2) | rightTrialAligned < behaviorEvents(i).sampleLateralev(1));      
       rightTrialAligned(b) = []; trialIDXright(b) = [];
       bCount = bCount + length(b);

       behaviorEvents(i).RightLicksNP = rightTrialAligned;       
       
        
%%% Left lick times for trial i %%%
       if i < length(trialStartTimes)
           trialIDXleft = find(leftLickTimesNP >= trialStartTimes(i) & leftLickTimesNP < trialStartTimes(i+1));%Find lick times for trial i
       else
           trialIDXleft = find(leftLickTimesNP >= trialStartTimes(end));
       end
       
       leftTrialAligned = leftLickTimesNP(trialIDXleft) - trialStartTimes(i);       
       
       %Remove licks outside of sampling window
       a = find(leftTrialAligned > behaviorEvents(i).sampleLateralev(2) | leftTrialAligned < behaviorEvents(i).sampleLateralev(1));      
       leftTrialAligned(a) = []; trialIDXleft(a) = [];
       aCount = aCount + length(a);

       LickTimesNP{i,2} = leftTrialAligned;
       behaviorEvents(i).LeftLicksNP = leftTrialAligned;

end


%}
fprintf('Removed %d lateral licks from NP data\n',[aCount + bCount]);
%%

for i = 1:nTrials
    if ~isempty(behaviorEvents(i).RightLicksNP)
       behaviorEvents(i).FirstLickNP(2) = behaviorEvents(i).RightLicks(1);
       behaviorEvents(i).FirstLickNP(1) = 2;
    elseif ~isempty(behaviorEvents(i).LeftLicks)
       behaviorEvents(i).FirstLickNP(2) = behaviorEvents(i).LeftLicks(1);
       behaviorEvents(i).FirstLickNP(1) = 1;
    end

end

LickData=behaviorEvents;
%%
fprintf('Generating lick rasters...');
   
subplot(1,2,1)
tic
for i = 1:nTrials

   %scatter(behaviorEvents(i).CentralLicks,repmat(i,1,length(behaviorEvents(i).CentralLicks)),10,'filled','k')
   hold on; scatter(behaviorEvents(i).LeftLicks,repmat(i,1,length(behaviorEvents(i).LeftLicks)),10,'filled','r')
   hold on; scatter(behaviorEvents(i).RightLicks,repmat(i,1,length(behaviorEvents(i).RightLicks)),10,'filled','b')

end
ylabel('Trial #','Fontsize',18); xlabel('Time (s)','Fontsize',18); title('Trial start aligned (BPOD)','Fontsize',18)
set(gca,'XLim',[0 12],'TickDir','out','Fontsize',16)
elapsed_time = toc;
fprintf('%f seconds...',elapsed_time);

% Overlap NP lick times with BPOD lick times to check alignment
subplot(1,2,2)
tic
for i = 1:nTrials

   %scatter(behaviorEvents(i).CentralLicks,repmat(i,1,length(behaviorEvents(i).CentralLicks)),10,'filled','k')
   hold on; scatter(behaviorEvents(i).LeftLicks,repmat(i,1,length(behaviorEvents(i).LeftLicks)),10,'filled','r')
   hold on; scatter(behaviorEvents(i).RightLicks,repmat(i,1,length(behaviorEvents(i).RightLicks)),10,'filled','b')
   %hold on; scatter(behaviorEvents(i).CentralLicksNP,repmat(i,1,length(behaviorEvents(i).CentralLicksNP)),10,'filled','MarkerFaceColor',[0.5 0.5 0.5])
   hold on; scatter(behaviorEvents(i).LeftLicksNP,repmat(i,1,length(behaviorEvents(i).LeftLicksNP)),10,'filled','m')
   hold on; scatter(behaviorEvents(i).RightLicksNP,repmat(i,1,length(behaviorEvents(i).RightLicksNP)),10,'filled','c')
   

end
xlabel('Time (s)','Fontsize',18); title('NP + BPOD overlap','Fontsize',18)
set(gca,'XLim',[0 12],'TickDir','out','Fontsize',16)
elapsed_time = toc;
fprintf('%f seconds\n',elapsed_time);

%{
ppsize = [2000 1400];
set(gcf,'PaperPositionMode','auto');         
set(gcf,'PaperOrientation','landscape');
set(gcf,'PaperUnits','points');
set(gcf,'PaperSize',ppsize);
set(gcf,'Position',[0 0 ppsize]);
%}

sgtitle([npEvents.MouseID ' ' npEvents.SessionID ' Lick Times'],'FontSize',20, 'Color', 'red')

%%
cd('Z:\Fontanini\Allison\Animal data\AG10\Odor2AC_testing\session1');
fprintf('Saving ClusterData...'); save([MouseID '-' SessionID '-ClusterData'],'spikes','fs','cellInfo','labels');
fprintf('Saving EventData...\n'); save([MouseID '-' SessionID '-EventData'],'events');
fprintf('Saving LickData...\n'); save([MouseID '-' SessionID '-LickData'],'LickData');

