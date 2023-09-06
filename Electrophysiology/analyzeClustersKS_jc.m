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
 
rootdir = 'C:\Users\admin\Documents\DATA\JC\';
sep = '\';
outputdir = 'C:\Users\admin\Documents\DATA\JC\Spikes\';

MouseID = 'JCT01';
SessionID = 'g0';
mkdir(outputdir,MouseID);


% myPath = [rootdir MouseID sep MouseID '_' SessionID ] %Folder containing nidaq data (parent folder to imec0 folder)
myPath = [rootdir MouseID '_' SessionID] %Folder containing nidaq data (parent folder to imec0 folder)

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Extract spikes and events for a given session
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[spikes,events,fs,cellInfo,labels] = getSpikeEventsKS_jc(myPath);


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
LickData = getLickTimes(events,behaviorEvents,0); %Add to this code input from behavior computer to delete error licks


fprintf('Saving LickData...\n'); save([MouseID '-' SessionID '-LickData'],'LickData'); %save([MouseID '-' SessionID '-BehaviorData'],'behaviorEvents');
mkdir('Figures');
cd('Figures');
print([MouseID '-' SessionID '-LickData'],'-dpdf','-r400');

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Separate files + raster per cluster
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear smoothFR1

cd([outputdir MouseID]);
load([MouseID '-' SessionID '-ClusterData']);
load([MouseID '-' SessionID '-EventData']);
% load([MouseID '-' SessionID '-LickData']);

mkdir('Clusters');
cd('Clusters');

spikeTimes = spikes.spks;

%%% Uncomment to only analyze single units: %%%
% 
    clustQ = cell2mat(cellInfo(:,6));
    goodQID = find(clustQ == 1);
    cellInfo = cellInfo(goodQID,:);
    spikeTimes = spikeTimes(goodQID);
    fprintf('Analyzing single units only\n');
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nClust = length(spikeTimes);
xLimT = 4.5; %Time limit for x-axis on figures;

% events.trialStartEv = events.lickEv.laser1;
events.trialStartEv(1,1) = events.lickEv.laser1(1,1);
for i = 2:size(events.lickEv.laser1,2)
    if events.lickEv.laser1(1,i)-events.lickEv.laser1(1,i-1)<10000
        continue
    elseif events.lickEv.laser1(1,i)-events.lickEv.laser1(1,i-1)>10000
        events.trialStartEv(1,i) = events.lickEv.laser1(1,i);
    end
end
events.trialStartEv = events.trialStartEv(events.trialStartEv~=0)
for i = 1:nClust
    figure(i)
    spikeMat = getClusterSpikeTimes(spikeTimes{i},events); %CORRECT FOR NEW LICKDATA STRUCTURE!!!!
    cellInfo{i,10} = spikeMat; %Add spike mat to master table of all clusters

    CI = cellInfo(i,1:9);
    CellInfo = cell2table(CI,'VariableNames',labels);
    
    tempspike = spikeMat;
%     tempspike(:,tempspike(1,:)==0) = []; %Cut all pre-behavior spikes

    % Only create plots for single units
    if cell2mat(CI(1,6)) == 1 
        %%% Plot spike rasters %%%
        subplot(3,1,1); % Trial-aligned spike times
%                 rectangle('Position',[1,2.5 1.5,40],'FaceColor',[0 .5 .5])
        line([1.5, 1.5],[0, 40],'Color','red','LineStyle','--'); hold on;
        line([3, 3],[0, 40],'Color','red','LineStyle','--');

        scatter(tempspike(3,:),tempspike(1,:),10,'filled','k');
        ylabel('Trial #','Fontsize',18); title('Trial start aligned','Fontsize',18)
        set(gca,'XLim',[0 xLimT],'TickDir','out','Fontsize',16)
        hold on;

%         rectangle([1,2.5 1.5,40],'pos')
%         subplot(3,1,1); % Central lick-aligned spike times
%         scatter(tempspike(4,:),tempspike(1,:),10,'filled','k');
%         ylabel('Trial #','Fontsize',18); xlabel('Time (s)','Fontsize',18); title('Central lick aligned','Fontsize',18)
%         set(gca,'XLim',[0 xLimT],'TickDir','out','Fontsize',16)

        %%% Plot spike PSTH + smoothed FR %%%
        binsize = 0.1; timeWin = [0 max(spikeMat(3,:))];
        [smoothFR1, spikePSTH1] = smoothFR(spikeMat(3,:),max(spikeMat(1,:)),binsize,timeWin,3);
%         [smoothFR2, spikePSTH2] = smoothFR(spikeMat(4,:),max(spikeMat(1,:)),binsize,timeWin,3);
        t = [0:binsize:max(spikeMat(3,:))]; t = t(1:end-1);
        
        subplot(3,1,2); 
        line([1.5, 1.5],[0, max(spikePSTH1)+0.05],'Color','red','LineStyle','--'); hold on;
        line([3, 3],[0, max(spikePSTH1)+0.05],'Color','red','LineStyle','--');
        hold on;
        bar(t,spikePSTH1); box off;
        set(gca,'XLim',[0 xLimT],'TickDir','out','Fontsize',16)
        
        subplot(3,1,3); 
         line([1.5, 1.5],[0, max(smoothFR1)+0.05],'Color','red','LineStyle','--'); hold on;
        line([3, 3],[0, max(smoothFR1)+0.05],'Color','red','LineStyle','--');
        hold on;
        plot(t,smoothFR1); box off;
        ylabel('Firing Rate (Hz)','Fontsize',18); xlabel('Time (s)','Fontsize',18); 
        set(gca,'XLim',[0 xLimT],'TickDir','out','Fontsize',16)
        
%         subplot(3,2,4); bar(t,spikePSTH2); box off;
%         set(gca,'XLim',[0 xLimT],'TickDir','out','Fontsize',16)
        
%         subplot(3,2,6); plot(t,smoothFR2); box off;
%         ylabel('Firing Rate (Hz)','Fontsize',18); xlabel('Time (s)','Fontsize',18); 
%         set(gca,'XLim',[0 xLimT],'TickDir','out','Fontsize',16)
%         smoothFR1_all{i} = smoothFR1;
        ppsize = [2000 1400];
        set(gcf,'PaperPositionMode','auto');         
        set(gcf,'PaperOrientation','landscape');
        set(gcf,'PaperUnits','points');
        set(gcf,'PaperSize',ppsize);
        set(gcf,'Position', [-1320 208 389 858]);
        
        sgtitle([MouseID '-' SessionID '; Cluster ' num2str(CellInfo.clustID(1),'%03.f') ';Cell ' num2str(CellInfo.cellNum(1),'%03.f') '; ' CellInfo.unitType{1}],'FontSize',20, 'Color', 'red') 
    
%         cd([outputdir sep MouseID sep 'Figures']);
        print([MouseID '-' SessionID '-' num2str(CellInfo.cellNum,'%03.f') '-' num2str(CellInfo.unitTypeNum)],'-djpeg','-r400');

    end
    

    cd([outputdir sep MouseID sep 'Clusters']);
    save([MouseID '-' SessionID '-' num2str(CellInfo.cellNum,'%03.f') '-' num2str(CellInfo.unitTypeNum)],'spikeMat','CellInfo')
    


end
% mkdir('Figures');
% cd('Figures');
labels{10} = 'spikes';
ClusterData = cell2table(cellInfo,'VariableNames',labels);
cd([outputdir sep MouseID]);
save([MouseID '-' SessionID '-ClusterData'],'ClusterData','-append');

%%
% ClusterData(:,[11 12 13]) = [];

clear temp
for i = 1:size(ClusterData,1)
    temp = ClusterData.spikes{i,1}(1,1:end);
    idx = find(temp>= 1 & temp<= 12);
    ClusterData.stim1{i,1} = ClusterData.spikes{i,1}(1:3,idx);

    idx = find(temp>= 13 & temp<= 24);
    ClusterData.stim2{i,1} = ClusterData.spikes{i,1}(1:3,idx);

    idx = find(temp>= 25 & temp<= 40);
    ClusterData.stim3{i,1} = ClusterData.spikes{i,1}(1:3,idx);
    clear temp

end
%% Try to normalize to baseline




%%
close all
% neurons_to_plot = [3 6 8 9 11 13 14 15 17];
% neurons_to_plot = [3 6 8 9 11 13];

% t = [-1.5:binsize:3]; t = t(1:end-1);
% clear smoothFR1_all_stim1 spikePSTH1_all_stim1
% for i = 1:size(ClusterData,1)
%     binsize = 0.1; timeWin = [0 4.5];
% 
%     [smoothFR1_all_stim1(i,:), spikePSTH1_all_stim1(i,:)] = smoothFR(ClusterData.stim1{i,1}(end,:),max(ClusterData.stim1{i,1}(1,:)),binsize,timeWin,3);
% %     smoothFR1_all_stim1 = zscore(smoothFR1_all_stim1,0,2)
% %     t = [0:binsize:max(spikeMat(3,:))]; t = t(1:end-1);
% 
% end
% figure(1)
% t = [-1.5:binsize:3]; t = t(1:end-1);
% 
%         
% y = mean(smoothFR1_all_stim1(neurons_to_plot,:)); % your mean vector;
% x = t;
% subplot(3,1,1)
% 
% std_dev = std(smoothFR1_all_stim1(neurons_to_plot,:));
% curve1 = y + std_dev/sqrt(size(smoothFR1_all_stim1(neurons_to_plot,:),1));
% curve2 = y - std_dev/sqrt(size(smoothFR1_all_stim1(neurons_to_plot,:),1));
% x2 = [x, fliplr(x)];
% inBetween = [curve1, fliplr(curve2)];
% grayColor = [.8 .8 .8];
% 
% fill(x2, inBetween, grayColor);
% hold on;
% plot(t, y, 'k', 'LineWidth', 2);
% line([0,0],[0, max(y)+0.5],'Color','red','LineStyle','--'); hold on;
%         line([1.5, 1.5],[0, max(y)+0.5],'Color','red','LineStyle','--');
% box off
%%
neurons_to_plot = [3 6 7 8 9 11 13 14 15 17];
% neurons_to_plot = [3 6 8 9 11 13];


%%
close all
figure(1)
clear smoothFR1_all_stim2 spikePSTH1_all_stim2 t
for i = 1:size(ClusterData,1)
    binsize = 0.05; timeWin = [0 4.5];

    [smoothFR1_all_stim2(i,:), spikePSTH1_all_stim2(i,:)] = smoothFR(ClusterData.stim2{i,1}(end,:),max(ClusterData.stim2{i,1}(1,:))-max(ClusterData.stim1{i,1}(1,:)),binsize,timeWin,3);
%     smoothFR1_all_stim2 = zscore(smoothFR1_all_stim2,0,2);

%     t = [0:binsize:max(spikeMat(3,:))]; t = t(1:end-1);

end
t = [-1.5:binsize:3]; t = t(1:end-1);

subplot(4,2,5)
y = mean(smoothFR1_all_stim2(neurons_to_plot,:)); % your mean vector;
x = t;
line([0,0],[0, max(y)+0.5],'Color','red','LineStyle','--'); hold on;
        line([1.5, 1.5],[0, max(y)+0.5],'Color','red','LineStyle','--');
std_dev = std(smoothFR1_all_stim2(neurons_to_plot,:));
curve1 = y + std_dev/sqrt(size(smoothFR1_all_stim2(neurons_to_plot,:),1));
curve2 = y - std_dev/sqrt(size(smoothFR1_all_stim2(neurons_to_plot,:),1));
x2 = [x, fliplr(x)];
inBetween = [curve1, fliplr(curve2)];
grayColor = [.8 .8 .8];

fill(x2, inBetween, grayColor);
hold on;
plot(t, y, 'k', 'LineWidth', 2); hold on;

line([0,0],[0, 6],'Color','red','LineStyle','--','LineWidth',2); hold on;
line([1.5, 1.5],[0, 6],'Color','red','LineStyle','--','LineWidth',2);

hold on

rectangle('Position',[0 5.5 1.5 0.5],'FaceColor','c' )
ylabel('Firing Rate (Hz)'); xlabel('Time (s)');title('40 Hz Laser Stim.')
box off
ylim([0 6]);xlim([-1.5 3]);xticks([-1.5 0 1.5 3])
subplot(4,2,6)
clear anovadata avg_firing_rate bar_sem
avg_firing_rate(1) = mean(mean(smoothFR1_all_stim2(neurons_to_plot,t>=-1.5 & t<0),2));
avg_firing_rate(2) = mean(mean(smoothFR1_all_stim2(neurons_to_plot,t>0 & t<1.5),2));
avg_firing_rate(3) = mean(mean(smoothFR1_all_stim2(neurons_to_plot,t>=1.5 & t<2.95),2));

bar_sem(1) = std(mean(smoothFR1_all_stim2(neurons_to_plot,t>=-1.5 & t<0),2))/size(neurons_to_plot,2);
bar_sem(2) = std(mean(smoothFR1_all_stim2(neurons_to_plot,t>0 & t<1.5),2))/size(neurons_to_plot,2);
bar_sem(3) = std(mean(smoothFR1_all_stim2(neurons_to_plot,t>=1.5 & t<2.95),2))/size(neurons_to_plot,2);

plot(1:3,avg_firing_rate,'-ok'); hold on;

errorbar(1:3,avg_firing_rate,bar_sem)
xlim([0 4]); ylim([0 3])
ylabel('Firing Rate (Hz)');
box off
xticks([1 2 3])

xticklabels({'Pre' 'Stim' 'Post'})

anovadata(:,1) = mean(smoothFR1_all_stim2(neurons_to_plot,t>=-1.5 & t<0),2);
anovadata(:,2) = mean(smoothFR1_all_stim2(neurons_to_plot,t>0 & t<1.5),2);
anovadata(:,3) = mean(smoothFR1_all_stim2(neurons_to_plot,t>=1.5 & t<2.95),2);

[p,tbl,stats] = anova1(anovadata);
%
figure(1)

clear smoothFR1_all_stim3 spikePSTH1_all_stim3
for i = 1:size(ClusterData,1)
    binsize = 0.05; timeWin = [0 4.5];

    [smoothFR1_all_stim3(i,:), spikePSTH1_all_stim3(i,:)] = smoothFR(ClusterData.stim3{i,1}(end,:),max(ClusterData.stim3{i,1}(1,:))-max(ClusterData.stim2{i,1}(1,:)),binsize,timeWin,3);
%     smoothFR1_all_stim3 = zscore(smoothFR1_all_stim3,0,2);

%     t = [0:binsize:max(spikeMat(3,:))]; t = t(1:end-1);

end
t = [-1.5:binsize:3]; t = t(1:end-1);
%
subplot(4,2,7)
y = mean(smoothFR1_all_stim3(neurons_to_plot,:)); % your mean vector;
x = t;

std_dev = std(smoothFR1_all_stim3(neurons_to_plot,:));
curve1 = y + std_dev/sqrt(size(smoothFR1_all_stim3(neurons_to_plot,:),1));
curve2 = y - std_dev/sqrt(size(smoothFR1_all_stim3(neurons_to_plot,:),1));
x2 = [x, fliplr(x)];
inBetween = [curve1, fliplr(curve2)];
grayColor = [.8 .8 .8];

fill(x2, inBetween, grayColor);
hold on;
plot(t, y, 'k', 'LineWidth', 2);
hold on;
line([0,0],[0, 6],'Color','red','LineStyle','--','LineWidth',2); hold on;
        line([1.5, 1.5],[0, 6],'Color','red','LineStyle','--','LineWidth',2);
ylabel('Firing Rate (Hz)'); xlabel('Time (s)');title('Constant Laser Stim.')
ylim([0 6]);xlim([-1.5 3]);xticks([-1.5 0 1.5 3])

hold on
rectangle('Position',[0 5.5 1.5 0.5],'FaceColor','c' )


box off
subplot(4,2,8)
clear avg_firing_rate bar_sem anovadata
avg_firing_rate(1) = mean(mean(smoothFR1_all_stim3(neurons_to_plot,t>=-1.5 & t<0),2));
avg_firing_rate(2) = mean(mean(smoothFR1_all_stim3(neurons_to_plot,t>0 & t<1.5),2));
avg_firing_rate(3) = mean(mean(smoothFR1_all_stim3(neurons_to_plot,t>=1.5 & t<2.95),2));
bar_sem(1) = std(mean(smoothFR1_all_stim3(neurons_to_plot,t>=-1.5 & t<0),2))/size(neurons_to_plot,2);
bar_sem(2) = std(mean(smoothFR1_all_stim3(neurons_to_plot,t>0 & t<1.5),2))/size(neurons_to_plot,2);
bar_sem(3) = std(mean(smoothFR1_all_stim3(neurons_to_plot,t>=1.5 & t<2.95),2))/size(neurons_to_plot,2);


plot(1:3,avg_firing_rate,'-ok');
hold on;
errorbar(1:3,avg_firing_rate,bar_sem)
xlim([0 4]); ylim([0 2.5])
ylabel('Firing Rate (Hz)');
box off
xticks([1 2 3])
xticklabels({'Pre' 'Stim' 'Post'})
anovadata(:,1) = mean(smoothFR1_all_stim3(neurons_to_plot,t>=-1.5 & t<0),2);
anovadata(:,2) = mean(smoothFR1_all_stim3(neurons_to_plot,t>0 & t<1.5),2);
anovadata(:,3) = mean(smoothFR1_all_stim3(neurons_to_plot,t>=1.5 & t<2.95),2);

[p,tbl,stats] = anova1(anovadata);

%
figure(1);
subplot(4,2,2); % Example neuron raster and PSTH
temp_firiing = ClusterData.stim3{7,1};

scatter(temp_firiing(3,:),temp_firiing(1,:),10,'filled','k');
ylabel('Trial #','Fontsize',12);
title('Example neuron','Fontsize',12)
%         set(gca,'XLim',[0 xLimT],'TickDir','out','Fontsize',12)
hold on;

line([1.5, 1.5],[20, 40],'Color','red','LineStyle','--','LineWidth',2); hold on;
line([3, 3],[20, 40],'Color','red','LineStyle','--','LineWidth',2);
xlim([-0.1 4.5])
ylim([25 40]);
xticks([0 1.5 3 4.5])
xticklabels({[-1.5 0 1.5 3]})
xlabel('Time (s)')

subplot(4,2,4); % Example neuron raster and PSTH
binsize = 0.1; timeWin = [0 4.5];
[smoothFR1_all_stim3_cell7(7,:), ~] = smoothFR(ClusterData.stim3{7,1}(end,:),max(ClusterData.stim3{7,1}(1,:))-max(ClusterData.stim2{7,1}(1,:)),binsize,timeWin,3);
t = [-1.5:binsize:3]; t = t(1:end-1);

plot(t,smoothFR1_all_stim3_cell7(7,:),'k', 'LineWidth', 1.5); hold on;
line([0, 0],[0, 8],'Color','red','LineStyle','--','LineWidth',2); hold on;
line([1.5, 1.5],[0, 8],'Color','red','LineStyle','--','LineWidth',2); hold on;
rectangle('Position',[0 7.5 1.5 0.5],'FaceColor','c' )

xlim([-1.6 3]); ylim([0 8])
xticks([-1.5 0 1.5 3])
xticklabels({[-1.5 0 1.5 3]})
ylabel('Firing Rate (Hz)','Fontsize',12);
xlabel('Time (s)')
box off
clc

subplot(4,2,3); % Heatmap of all inhibited neurons avg firing
clear smoothFR1_all_stim3 spikePSTH1_all_stim3 binsize
for i = 1:size(ClusterData,1)
    binsize = 0.05; timeWin = [0 4.5];

    [smoothFR1_all_stim3(i,:), spikePSTH1_all_stim3(i,:)] = smoothFR(ClusterData.stim3{i,1}(end,:),max(ClusterData.stim3{i,1}(1,:))-max(ClusterData.stim2{i,1}(1,:)),binsize,timeWin,3);
%     smoothFR1_all_stim3 = zscore(smoothFR1_all_stim3,0,2);

%     t = [0:binsize:max(spikeMat(3,:))]; t = t(1:end-1);

end
t = [-1.5:binsize:3]; t = t(1:end-1);
clims = [0 1];
% imagesc(zscore(smoothFR1_all_stim2(neurons_to_plot,:),0,2),clims);
for i = 1:size(neurons_to_plot,2)
    r(i) = length(find(smoothFR1_all_stim3(neurons_to_plot(i),1:20)>0.5));
end
[~,I] = sort(r);
imagesc(t,1:size(neurons_to_plot,2),smoothFR1_all_stim3(neurons_to_plot(I),:),clims);
hold on;
line([0, 0],[0, 11],'Color','red','LineStyle','--','LineWidth',2); hold on;
line([1.5, 1.5],[0, 11],'Color','red','LineStyle','--','LineWidth',2);
yticks([1 10]);
xticks([-1.5 0 1.5 3]);

ylabel('Neuron #','Fontsize',12); xlabel('Time (s)')
box off 
% for j = 34 % Trial number
%     figure(1);
% 
%     % plot one trial with all neurons used in analysis
%     trial_example = j;
%     % line([1.5, 1.5],[0, 40],'Color','red','LineStyle','--'); hold on;
%     % line([3, 3],[0, 40],'Color','red','LineStyle','--');
%     for i = 1:size(neurons_to_plot,2)
%         temp_firiing = ClusterData.stim3{i,1};
%         scatter(temp_firiing(3,temp_firiing(1,:)==trial_example),i,10,'filled','k');
%         hold on
%         clear temp_firiing
%     end
%     line([1.5, 1.5],[0, 40],'Color','red','LineStyle','--'); hold on;
%     line([3, 3],[0, 40],'Color','red','LineStyle','--');
%     xlim([-0.1 4.6])
%     ylim([1 10]);
% xticks([0 1.5 3 4.5])
% xticklabels({[-1.5 0 1.5 4]})
%     title('Example Photoinhibition Trial')
%     ylabel('Neuron #','Fontsize',12); 
% %     set(gca,'XLim',[0 xLimT],'TickDir','out','Fontsize',12);
%     hold on;
%     pause(2)
%     clear trial_example
% end
set(gcf,'Position',  [-1232 430 418 676]);

%%
filename='Summary_Opto_figure_v2'
saveas(gcf,filename,'pdf')