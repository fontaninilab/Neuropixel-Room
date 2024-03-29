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
 
rootdir = 'C:\Users\admin\Documents\DATA\AG\';
sep = '\';
%outputdir = 'C:\Users\admin\Documents\DATA\AG\Spikes\';

MouseID = 'AG05';
SessionID = 'test1';
%mkdir(outputdir,MouseID);


myPath = [rootdir MouseID sep MouseID '_' SessionID '_g0_CAR']; %Folder containing nidaq data (parent folder to imec0 folder)

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Extract spikes and events for a given session
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[spikes,events,fs,cellInfo,labels] = getSpikeEventsKS_ag(myPath);
%%
cd('C:\Users\admin\Documents\DATA\AG\AG05\AG05_test1_g0_CAR');
fprintf('Saving ClusterData...'); save([MouseID '-' SessionID '-ClusterData'],'spikes','fs','cellInfo','labels');
fprintf('Saving EventData...\n'); save([MouseID '-' SessionID '-EventData'],'events');




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
behaviorEvents = extractTrialData2AFC_ag(SessionData,SessionID); %Extract trial data from behavior computer data
%%
load([MouseID '-' SessionID '-EventData']);
LickData = getLickTimes_ag(events,behaviorEvents,0); %Add to this code input from behavior computer to delete error licks


fprintf('Saving LickData...\n'); save([MouseID '-' SessionID '-LickData'],'LickData'); %save([MouseID '-' SessionID '-BehaviorData'],'behaviorEvents');
%mkdir('Figures');
%cd('Figures');
%print([MouseID '-' SessionID '-LickData'],'-dpdf','-r400');

%%
%cd(['Z:\Fontanini\Allison\' MouseID '\Testing'])
save([MouseID '-' SessionID '-LickData'],'LickData');
save([MouseID '-' SessionID '-ClusterData'],'spikes','fs','cellInfo','labels');
save([MouseID '-' SessionID '-EventData'],'events');
disp('finished saving')

%%




L = FirstLick(1,FirstLick(1,:)==1)
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Separate files + raster per cluster
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%cd([outputdir MouseID]);
%load([MouseID '-' SessionID '-ClusterData']);
%load([MouseID '-' SessionID '-EventData']);
%load([MouseID '-' SessionID '-LickData']);

%mkdir('Clusters');
%cd('Clusters');

spikeTimes = spikes.spks;

%%% Uncomment to only analyze single units: %%%

% % %     clustQ = cell2mat(cellInfo(:,6));
% % %     goodQID = find(clustQ == 1);
% % %     cellInfo = cellInfo(goodQID,:);
% % %     spikeTimes = spikeTimes(goodQID);
% % %     fprintf('Analyzing single units only\n');
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nClust = length(spikeTimes);
xLimT = 20; %Time limit for x-axis on figures;

for i =1:nClust
    spikeMat = getClusterSpikeTimes_ag(spikeTimes{i},events,LickData); %CORRECT FOR NEW LICKDATA STRUCTURE!!!!
    cellInfo{i,10} = spikeMat; %Add spike mat to master table of all clusters

    CI = cellInfo(i,1:9);
    CellInfo = cell2table(CI,'VariableNames',labels);
    
    tempspike = spikeMat;
    tempspike(:,tempspike(1,:)==0) = []; %Cut all pre-behavior spikes

    % Only create plots for single units
    if cell2mat(CI(1,6)) == 1 
        %disp(i);
        %%% Plot spike rasters %%%
        %{
        subplot(3,1,1); % Trial-aligned spike times
        scatter(tempspike(3,:),tempspike(1,:),10,'filled','k'); hold on;
        scatter(FirstLick(3,FirstLick(2,:)==2),FirstLick(1,FirstLick(2,:)==2),8,'^', 'filled','r')
        scatter(FirstLick(3,FirstLick(2,:)==1),FirstLick(1,FirstLick(2,:)==1),8,'^', 'filled','b')
          

        x = [2 2.5 2.5 2];
        y = [0 0 114 114];
        h = fill(x,y,[.8 .7 .8]);
        set(h,'facealpha',.5)
        ylabel('Trial #','Fontsize',18); title('Trial start aligned','Fontsize',18)
        set(gca,'XLim',[0 xLimT],'TickDir','out','Fontsize',16)
        hold off;
        
      %  subplot(3,2,2); % Central lick-aligned spike times
        
        %scatter(tempspike(4,:),tempspike(1,:),10,'filled','k');
      %  ylabel('Trial #','Fontsize',18); xlabel('Time (s)','Fontsize',18); title('Central lick aligned','Fontsize',18)
      %  set(gca,'XLim',[0 xLimT],'TickDir','out','Fontsize',16)
        
        %%% Plot spike PSTH + smoothed FR %%%
        binsize = 0.1; timeWin = [0 max(spikeMat(3,:))];
        [smoothFR1, spikePSTH1] = smoothFR(spikeMat(3,:),max(spikeMat(1,:)),binsize,timeWin,3);
    %    [smoothFR2, spikePSTH2] = smoothFR(spikeMat(4,:),max(spikeMat(1,:)),binsize,timeWin,3);
        t = [0:binsize:max(spikeMat(3,:))]; t = t(1:end-1);
        
        subplot(3,1,2); bar(t,spikePSTH1); box off;
        set(gca,'XLim',[0 xLimT],'TickDir','out','Fontsize',16)
        
        subplot(3,1,3); plot(t,smoothFR1); box off;
        ylabel('Firing Rate (Hz)','Fontsize',18); xlabel('Time (s)','Fontsize',18); 
        set(gca,'XLim',[0 xLimT],'TickDir','out','Fontsize',16)
        
       % subplot(3,2,4); bar(t,spikePSTH2); box off;
       % set(gca,'XLim',[0 xLimT],'TickDir','out','Fontsize',16)
        
       % subplot(3,2,6); plot(t,smoothFR2); box off;
      %  ylabel('Firing Rate (Hz)','Fontsize',18); xlabel('Time (s)','Fontsize',18); 
      %  set(gca,'XLim',[0 xLimT],'TickDir','out','Fontsize',16)
        
        ppsize = [2000 1400];
        set(gcf,'PaperPositionMode','auto');         
        set(gcf,'PaperOrientation','landscape');
        set(gcf,'PaperUnits','points');
        set(gcf,'PaperSize',ppsize);
        set(gcf,'Position',[0 0 ppsize]);
        

        sgtitle([MouseID '-' SessionID '; Cell ' num2str(CellInfo.cellNum(1),'%03.f') '; ' CellInfo.unitType{1}],'FontSize',20, 'Color', 'red') 
    
        cd([outputdir sep MouseID sep 'Figures']);
        print([MouseID '-' SessionID '-' num2str(CellInfo.cellNum,'%03.f') '-' num2str(CellInfo.unitTypeNum)],'-djpeg','-r400');

    end
    
    if cell2mat(CI(1,6)) == 1 
%   cd([outputdir sep MouseID sep 'Clusters']);
%   save([MouseID '-' SessionID '-' num2str(CellInfo.cellNum,'%03.f') '-' num2str(CellInfo.unitTypeNum)],'spikeMat','CellInfo')
    end
        %}

    end
end

labels{10} = 'spikes';
ClusterData = cell2table(cellInfo,'VariableNames',labels);
cd([outputdir sep MouseID]);
save([MouseID '-' SessionID '-ClusterData'],'ClusterData','-append');

