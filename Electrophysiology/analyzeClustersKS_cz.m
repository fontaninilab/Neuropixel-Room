% rootdir = 'C:\Users\admin\Documents\DATA\Jennifer\';
% sep = '\';
% outputdir = 'C:\Users\admin\Documents\DATA\Jennifer\Spikes\';
% 
% MouseID = 'JMB020';
% SessionID = 'Session1';
% mkdir(outputdir,MouseID);
% 
% 
% myPath = [rootdir MouseID sep MouseID '_' SessionID '_g0'] %Folder containing nidaq data (parent folder to imec0 folder)
 
rootdir = 'C:\Users\admin\Documents\DATA\CZ\';
% rootdir = 'F:\';
sep = '\';
outputdir = 'C:\Users\admin\Documents\DATA\CZ\Spikes\';

MouseID = 'CZN08';
SessionID = 'p1';
SessionGate ='0';
SessionTime = '0';
mkdir(outputdir,MouseID);


myPath = [rootdir MouseID sep MouseID '_' SessionID '_g0'] %Folder containing nidaq data (parent folder to imec0 folder)
% myPath = [rootdir MouseID sep 'catgt_' MouseID '_' SessionID '_g0'] %Folder containing nidaq data (parent folder to imec0 folder)

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Extract spikes and events for a given session
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[spikes,events,fs,cellInfo,labels] = getSpikeEventsKS_cz(myPath,MouseID,SessionID,SessionGate);


cd([outputdir sep MouseID]);
fprintf('Saving ClusterData...'); save([MouseID '-' SessionID '-ClusterData'],'spikes','fs','cellInfo','labels');
fprintf('Saving EventData...\n'); save([MouseID '-' SessionID '-EventData'],'events');



%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Align and save NP lick times
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% % % Run this section only if you have lick data % % %

cd([outputdir MouseID]);

fprintf('Select data file from BEHAVIOR ACQUISITION COMPUTER:\n');

%Open lick events from NP acquisition and BEHAVIOR acquisition - Will use event timestamps to remove licks outside of wait period
[behaviorfile,behaviorpath] = uigetfile({'*.mat'},'Select data file from BEHAVIOR ACQUISITION COMPUTER:');
load([behaviorpath sep behaviorfile]); 
behaviorEvents = extractTrialData2AFC(SessionData,SessionID); %Extract trial data from behavior computer data

load([MouseID '-' SessionID '-EventData']);
LickData = getLickTimes_cz(events,behaviorEvents,0); %Add to this code input from behavior computer to delete error licks


fprintf('Saving LickData...\n'); save([MouseID '-' SessionID '-LickData'],'LickData'); %save([MouseID '-' SessionID '-BehaviorData'],'behaviorEvents');
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
%remove trials with no lateral licks
LickTable=struct2table(LickData);
cutLickData=table2struct(LickTable(~cellfun(@isempty,LickTable.FirstLatNP),:))';

mkdir('Clusters');
cd('Clusters');

spikeTimes = spikes.spks;

%%% Uncomment to only analyze single units: %%%
% 
%     clustQ = cell2mat(cellInfo(:,6));
%     goodQID = find(clustQ == 1);
%     cellInfo = cellInfo(goodQID,:);
%     spikeTimes = spikeTimes(goodQID);
%     fprintf('Analyzing single units only\n');
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nClust = length(spikeTimes);
xLimT_end = 10; %Time limit for x-axis on figures;
xLimT_start = -2;

% create summary PSTH table
sum_Lick_PSTH_table=[];
for i = 1:nClust
    [spikeMat,~,PSTH_table] = getClusterSpikeTimes_cz(spikeTimes{i},events,cutLickData); %CORRECT FOR NEW LICKDATA STRUCTURE!!!!
PSTH_table.clustID=repmat(cellInfo{i,3},size(PSTH_table,1),1);
PSTH_table.cellNum=repmat(cellInfo{i,4},size(PSTH_table,1),1);
Lick_PSTH_table=[struct2table(cutLickData),PSTH_table];
sum_Lick_PSTH_table=[sum_Lick_PSTH_table;Lick_PSTH_table];
end
save([MouseID '-' SessionID '-sum_PSTH_Table'],'sum_Lick_PSTH_table');

% plot raster and PSTH plots
for i = 1:nClust
    spikeMat = getClusterSpikeTimes_cz(spikeTimes{i},events,cutLickData); %CORRECT FOR NEW LICKDATA STRUCTURE!!!!
    cellInfo{i,10} = spikeMat; %Add spike mat to master table of all clusters

    CI = cellInfo(i,1:9);
    CellInfo = cell2table(CI,'VariableNames',labels);
    
    tempspike = spikeMat;
    tempspike(:,tempspike(1,:)==0) = []; %Cut all pre-behavior spikes
    % Only create plots for single units
    if cell2mat(CI(1,6)) == 1 
        %%% Plot spike rasters %%%
        h=gobjects(3,2);
        t=tiledlayout(3,2);
        %subplot(3,2,1); % Trial-aligned spike times
        h(1,1)=nexttile;
        scatter(tempspike(4,:),tempspike(1,:),10,'filled','k');
        ylabel('Trial #','Fontsize',18); title('Central lick aligned','Fontsize',18)
        set(gca,'XLim',[xLimT_start xLimT_end],'TickDir','out','Fontsize',16)
        
        %subplot(3,2,2); % Central lick-aligned spike times
        h(1,2)=nexttile;
        scatter(tempspike(5,:),tempspike(1,:),10,'filled','k');
        ylabel('Trial #','Fontsize',18); xlabel('Time (s)','Fontsize',18); title('Lateral lick aligned','Fontsize',18)
        set(gca,'XLim',[xLimT_start xLimT_end],'TickDir','out','Fontsize',16)

        %%% Plot spike PSTH + smoothed FR %%%
          binsize = 0.1; timeWin = [xLimT_start max(spikeMat(3,:))];
        [smoothFR1, spikePSTH1] = smoothFR(spikeMat(3,:),max(spikeMat(1,:)),binsize,timeWin,3);
        [smoothFR2, spikePSTH2] = smoothFR(spikeMat(4,:),max(spikeMat(1,:)),binsize,timeWin,3);
        [smoothFR3, spikePSTH3] = smoothFR(spikeMat(5,:),max(spikeMat(1,:)),binsize,timeWin,3);
        t = [xLimT_start:binsize:max(spikeMat(3,:))]; t = t(1:end-1);
            
        %subplot(3,2,3); 
        h(2,1)=nexttile;
        bar(t,spikePSTH2); box off;
        set(gca,'XLim',[xLimT_start xLimT_end],'TickDir','out','Fontsize',16)
        
        %subplot(3,2,4);
        h(2,2)=nexttile;
        bar(t,spikePSTH3); box off;
        set(gca,'XLim',[xLimT_start xLimT_end],'TickDir','out','Fontsize',16)

        %subplot(3,2,5); 
        h(3,1)=nexttile;
        plot(t,smoothFR2); box off;
        ylabel('Firing Rate (Hz)','Fontsize',18); xlabel('Time (s)','Fontsize',18); 
        set(gca,'XLim',[xLimT_start xLimT_end],'TickDir','out','Fontsize',16)
        
        %subplot(3,2,6); 
        h(3,2)=nexttile;
        plot(t,smoothFR3); box off;
        ylabel('Firing Rate (Hz)','Fontsize',18); xlabel('Time (s)','Fontsize',18); 
        set(gca,'XLim',[xLimT_start xLimT_end],'TickDir','out','Fontsize',16)
        
        ppsize = [2000 1400];
        set(gcf,'PaperPositionMode','auto');         
        set(gcf,'PaperOrientation','landscape');
        set(gcf,'PaperUnits','points');
        set(gcf,'PaperSize',ppsize);
        set(gcf,'Position',[0 0 ppsize]);
        linkaxes(h(2,:),'y');
        linkaxes(h(3,:),'y');
        sgtitle([MouseID '-' SessionID '; Cluster ' num2str(CellInfo.clustID(1),'%03.f') ';Cell ' num2str(CellInfo.cellNum(1),'%03.f') '; ' CellInfo.unitType{1}],'FontSize',20, 'Color', 'red') 
    
        cd([outputdir sep MouseID sep 'Figures']);
        print([MouseID '-' SessionID '-' num2str(CellInfo.cellNum,'%03.f') '-' num2str(CellInfo.unitTypeNum)],'-djpeg','-r400');

    end
    

    cd([outputdir sep MouseID sep 'Clusters']);
    save([MouseID '-' SessionID '-' num2str(CellInfo.cellNum,'%03.f') '-' num2str(CellInfo.unitTypeNum)],'spikeMat','CellInfo')
    


end

labels{10} = 'spikes';
ClusterData = cell2table(cellInfo,'VariableNames',labels);
cd([outputdir sep MouseID]);
save([MouseID '-' SessionID '-ClusterData'],'ClusterData','-append');


%% Some ClusterData metrics for summary table
%number of single units; depth range
fprintf('%d single units; depth %d to %d',sum(ClusterData.unitTypeNum==1),min(ClusterData.depth(ClusterData.unitTypeNum==1,:)),max(ClusterData.depth(ClusterData.unitTypeNum==1,:)))