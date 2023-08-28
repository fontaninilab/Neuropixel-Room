function [Ev, fsEv] = loadEventDataSGLX(myPath,dataType, ch, chanID)
%[lickEv, trialStartEv, fsEv] = loadEventDataSGLX(myPath,dataType, ch)
%
% Extract event data from Spike GLX file formats where events are recorded
% via nidaq
%
% INPUTS:
%   myPath = (string) path directory to folder containing nidaq data (parent to imec0 folder)
%   dataType = (string) indicates data type, digital ('D') or analog ('A')
%   ch = (array) channel ID's for analog (goes unused for digital)
%   chanID = (cell of strings) string IDs for each analog channel (goes unused for digital)
%
% OUTPUTS:
%   Ev = for 'A', struct containing central, left, and right lick event times
%            from analog channels. For 'D', array containing trial start
%            event times.
%   fsEv = sampling rate of nidaq


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

if strcmp(dataType,'A')
    %lickChanID = {'central','left','right'}; %IDs of each channel
    lickChanID = chanID;

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
    
    Ev = lickEv;

%%% 2. Load digital channel data (these are the trial start events) %%%
elseif strcmp(dataType,'D')
    dw = 1;
    dLineList = 0;


    digArray = ExtractDigital(dataArray, NI_meta, dw, dLineList);

    digPeakIDX = find(digArray); %Finds indices where values are > 0
    digPeakDiff = diff(digPeakIDX); %Calculates difference between adjacent indices of digPeakIDX
    boutstart = find(digPeakDiff > 1)+1; %Find where difference between consecutive indices is > 1 (and add 1 for correct start index)
    firsttrial = 1;
    trialStartEv = digPeakIDX([firsttrial boutstart]); %Extract indices of each trial start
    
    Ev = trialStartEv;


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