rootdir = 'D:\Neuropixel Data\Tests\';
sep = '\';
outputdir = 'D:\Neuropixel Data\Spikes\';

MouseID = 'GC002';
SessionID = '201110';
mkdir(outputdir,MouseID);


myPath = [rootdir MouseID sep MousID '_' SessionID '_g0']; %Folder containing nidaq data (parent folder to imec0 folder)

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Extract spikes and events for a given session
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[spikes,events,fs,cellInfo,labels] = getSpikeEventsKS(myPath);


cd([outputdir MouseID]);
save([MouseID '-' SessionID '-ClusterData'],'spks','fs','cellInfo','labels');
save([MouseID '-' SessionID '-EventData'],'events');

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Align and save lick times
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cd([outputdir MouseID]);
load([MouseID '-' SessionID '-EventData']);
lickData = getLickTimes(events,0);



save([MouseID '-' SessionID '-LickData'],'lickData');
mkdir('Figures');
cd('Figures');
print([MouseID '-' SessionID '-LickData'],'-dpdf','-r400');
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Separate files + raster per cluster
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


cd([outputdir MouseID]);
load([MouseID '-' SessionID '-ClusterData']);
load([MouseID '-' SessionID '-EventData']);
load([MouseID '-' SessionID '-LickData']);

nClust = size(cellInfo,1);

for i = 1%:nClust
    spikeMat = getClusterSpikeTimes(spikes.spks{i},events,lickData);
    
    CI = cellInfo(i,:);
    CellInfo = cell2table(CI,'VariableNames',labels);
    
    tempspike = spikeMat;
    tempspike(:,tempspike(1,:)==0) = []; %Cut all pre-behavior spikes

    %%% Plot spike rasters %%%
    subplot(3,2,1); % Trial-aligned spike times
    scatter(tempspike(3,:),tempspike(1,:),10,'filled','k');
    ylabel('Trial #','Fontsize',18); title('Trial start aligned','Fontsize',18)
    set(gca,'XLim',[0 inf],'TickDir','out','Fontsize',16)
    
    subplot(3,2,2); % Central lick-aligned spike times
    scatter(tempspike(4,:),tempspike(1,:),10,'filled','k');
    ylabel('Trial #','Fontsize',18); xlabel('Time (s)','Fontsize',18); title('Central lick aligned','Fontsize',18)
    set(gca,'XLim',[0 inf],'TickDir','out','Fontsize',16)

    %%% Plot spike PSTH + smoothed FR %%%
    
    binsize = 0.1; timeWin = [0 max(spikeMat(3,:))];
    [smoothFR1, spikePSTH1] = smoothFR(spikeMat(3,:),max(spikeMat(1,:)),binsize,timeWin,3);
    [smoothFR2, spikePSTH2] = smoothFR(spikeMat(4,:),max(spikeMat(1,:)),binsize,timeWin,3);
    t = [0:binsize:max(spikeMat(3,:))]; t = t(1:end-1);
    
    subplot(3,2,3); bar(t,spikePSTH1); box off;
    set(gca,'XLim',[0 inf],'TickDir','out','Fontsize',16)
    
    subplot(3,2,5); plot(t,smoothFR1); box off;
    ylabel('Firing Rate (Hz)','Fontsize',18); xlabel('Time (s)','Fontsize',18); 
    set(gca,'XLim',[0 inf],'TickDir','out','Fontsize',16)
    
    subplot(3,2,4); bar(t,spikePSTH2); box off;
    set(gca,'XLim',[0 inf],'TickDir','out','Fontsize',16)
    
    subplot(3,2,6); plot(t,smoothFR2); box off;
    ylabel('Firing Rate (Hz)','Fontsize',18); xlabel('Time (s)','Fontsize',18); 
    set(gca,'XLim',[0 inf],'TickDir','out','Fontsize',16)
    
    ppsize = [2000 1400];
    set(gcf,'PaperPositionMode','auto');         
    set(gcf,'PaperOrientation','landscape');
    set(gcf,'PaperUnits','points');
    set(gcf,'PaperSize',ppsize);
    set(gcf,'Position',[0 0 ppsize]);
    
    sgtitle([MouseID '-' SessionID '; Cell ' num2str(CellInfo.cellNum(1)) '; ' CellInfo.unitType{1}],'FontSize',20, 'Color', 'red') 
    
   
    save([MouseID '-' SessionID '-' num2str(CellInfo.cellNum) '-' num2str(CellInfo.unitTypeNum)],'SpikeMat','CellInfo')
    
    print(['Figures\' MouseID '-' SessionID '-' num2str(CellInfo.cellNum) '-' num2str(CellInfo.unitTypeNum)],'-djpeg','-r400');

end
