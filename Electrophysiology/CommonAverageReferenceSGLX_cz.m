function CommonAverageReferenceSGLX_cz(MouseID, SessionID, badchanID)
% Perform common average reference on spikeGLX datasets using
% Neuropixel-utilities toolbox https://djoshea.github.io/neuropixel-utils/
%
% Note: specific folder/file name structure is assumed
%
% Inputs:
%   MouseID (string) = mouse id
%   SessionID (string) = session id
%   badchanID (array) = 1xN vector with bad channel IDs to be ignored for
%                       CAR
%
% Outputs:
%   Will save a new imec.ap.bin file in a new CAR subfolder

rootdir = 'C:\Users\admin\Documents\DATA\CZ\';
% % MouseID = 'JMB011';
% % SessionID = 'Session2';
sep = '\';

cd([rootdir MouseID sep MouseID '_' SessionID '_g0']);
mkdir([MouseID '_' SessionID '_g0_CAR']);

apfilepath = [rootdir MouseID sep MouseID '_' SessionID '_g0' sep ...
    MouseID '_' SessionID '_g0_imec0' sep ...
    MouseID '_' SessionID '_g0_t0.imec0.ap.bin'];
channelMapFile = 'neuropixPhase3B1_kilosortChanMap.mat';
imec = Neuropixel.ImecDataset(apfilepath, 'channelMap', channelMapFile);

% imec.markBadChannels(276:385);  
imec.markBadChannels(badchanID); %Mark channels to exclude
 %For TDPQF070 it seems like we start to see spikes on channel 293
 %For TDPQF086 only channels up to 266 appeared for non-CAR sorting???
 %For TDPWM090 channels up to 275 are good
 
 
cleanedPath = [rootdir MouseID sep MouseID '_' SessionID '_g0' sep ...
    MouseID '_' SessionID '_g0_CAR' sep ...
    MouseID '_' SessionID '_g0_t0_CAR.imec.ap.bin'];

extraMeta = struct();
extraMeta.commonAverageReferenced = true;
fnList = {@Neuropixel.DataProcessFn.commonAverageReference};
imec = imec.saveTransformedDataset(cleanedPath, 'transformAP', fnList, 'extraMeta', extraMeta);