%%
% This script contains the flow for analyzing spikeGLX neuropixel data. I
% recommend going through all of the code yourself to make sure you
% understand it (and to catch any of my mistakes).
%
% Note: Kilosort program stores entire file, so I usually use the task
% manager to force quit matlab after I run it.

%%
% 1. Run Kilosort on raw data. Follow instructions in spike sorting manual

kilosort;

% 2. Open in phy to choose bad channels. Usually ~200/250->385.
%
% Maybe you could just always do >200, but I always check. For some reason
% I think including as many good channels as possible for the CAR is
% probably better???

%%
% 3. Run common average reference (will save in new folder _CAR)

MouseID = 'JMB024';
SessionID = 'Session1';
badchanIDX = [240:385];

CommonAverageReferenceSGLX(MouseID, SessionID, badchanIDX);

%%
% 4. Run kilosort again on CAR .ap file

kilosort;

%%
% Sort manually using phy

%%
% 5. Extract spike data for each cluster and (optionally) also BPOD
% behavior data.

analyzeClusterKS;
