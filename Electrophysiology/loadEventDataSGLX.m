function [lickEv, trialStartEv, fsEv] = loadEventDataSGLX(myPath,fig)
%
% Extract event data from Spike GLX file formats where events are recorded
% via nidaq
%
% INPUTS:
%   myPath = (string) path directory to folder containing nidaq data (parent to imec0 folder)
%   fig = 0, optional input to produce figure to look at lick and trial
%         start event times aligned.
%
% OUTPUTS:
%   lickEv = struct containing central, left, and right lick event times
%            from analog channels
%   trialStartEv


fileChunks = strsplit(myPath,'\');
nameChunks = strsplit(fileChunks{end},'_');

NI_binName = [fileChunks{end} '_t0.nidq.bin'];
NI_meta = SGLXReadMeta(NI_binName, myPath);
fsEv = str2double(NI_meta.niSampRate);

%Extract # of samples
nChan = str2double(NI_meta.nSavedChans);
nFileSamp = str2double(NI_meta.fileSizeBytes) / (2 * nChan);
nSamp = nFileSamp;

dataArray = SGLXReadBin(0, nSamp, NI_meta, NI_binName, myPath); %Loads data from both analog and digital channels


%%% 1. Load analog channel data (these are the lick events) %%%

dataType = 'A'; 
ch = [1 2 3]; %Channels to extract
lickChanID = {'central','left','right'}; %IDs of each channel


[MN,MA] = ChannelCountsNI(NI_meta);
fI2V = Int2Volts(NI_meta);
dataArrayA = dataArray(ch,:); 

for i = 1:length(ch)
    j = ch(i);    % index into timepoint
    conv = fI2V / ChanGainNI(j, MN, MA, NI_meta);
    dataArrayA(j,:) = dataArrayA(j,:) * conv;
end

%Extract lick indices from data array
for i = 1:length(lickChanID)
    lickIDX = find(dataArrayA(i,:)>0.5);
    lickIDXdiff = diff(lickIDX);
    lickstart = find(lickIDXdiff > 1) + 1;
    firsttrial = 1;
    lickEv.(lickChanID{i}) = lickIDX([firsttrial lickstart]);    
    
end


%%% 2. Load digital channel data (these are the trial start events) %%%
dataType = 'D'; 

dw = 1;
dLineList = 0;


digArray = ExtractDigital(dataArray, NI_meta, dw, dLineList);

digPeakIDX = find(digArray); %Finds indices where values are > 0
digPeakDiff = diff(digPeakIDX); %Calculates difference between adjacent indices of digPeakIDX
boutstart = find(digPeakDiff > 1)+1; %Find where difference between consecutive indices is > 1 (and add 1 for correct start index)
firsttrial = 1;
trialStartEv = digPeakIDX([firsttrial boutstart]); %Extract indices of each trial start


%%% 3. Plot event times to manually check for alignment (optional) %%%
if nargin > 1
    figure;
    scatter(trialStartEv./fsEv,1.02*ones(1,length(trialStartEv)),'*');
    hold on; scatter(lickEv.central./fsEv,ones(1,length(lickEv.central)),'filled','k');
    scatter(lickEv.left./fsEv,0.98*ones(1,length(lickEv.left)),'filled','r');
    scatter(lickEv.right./fsEv,0.98*ones(1,length(lickEv.right)),'filled','b');


    set(gca,'ylim',[0.95 1.05]);
    legend('Trial start','central lick','left lick','right lick','Location','best');
end


end


function digArray = ExtractDigital(dataArray, meta, dwReq, dLineList)
    % Get channel index of requested digital word dwReq
    if strcmp(meta.typeThis, 'imec')
        [AP, LF, SY] = ChannelCountsIM(meta);
        if SY == 0
            fprintf('No imec sync channel saved\n');
            digArray = [];
            return;
        else
            digCh = AP + LF + dwReq;
        end
    else
        [MN,MA,XA,DW] = ChannelCountsNI(meta);
        if dwReq > DW
            fprintf('Maximum digital word in file = %d\n', DW);
            digArray = [];
            return;
        else
            digCh = MN + MA + XA + dwReq;
        end
    end
    [~,nSamp] = size(dataArray);
    digArray = zeros(numel(dLineList), nSamp, 'uint8');
    for i = 1:numel(dLineList)
        digArray(i,:) = bitget(dataArray(digCh,:), dLineList(i)+1, 'int16');
    end
end % ExtractDigital

function [MN,MA,XA,DW] = ChannelCountsNI(meta)
    M = str2num(meta.snsMnMaXaDw);
    MN = M(1);
    MA = M(2);
    XA = M(3);
    DW = M(4);
end % ChannelCountsNI

function fI2V = Int2Volts(meta)
    if strcmp(meta.typeThis, 'imec')
        fI2V = str2double(meta.imAiRangeMax) / 512;
    else
        fI2V = str2double(meta.niAiRangeMax) / 32768;
    end
end % Int2Volts

function gain = ChanGainNI(ichan, savedMN, savedMA, meta)
    if ichan <= savedMN
        gain = str2double(meta.niMNGain);
    elseif ichan <= savedMN + savedMA
        gain = str2double(meta.niMAGain);
    else
        gain = 1;
    end
end % ChanGainNI