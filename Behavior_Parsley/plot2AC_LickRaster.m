function plot2AC_LickRaster
% Plot raster for all lick trials for 2AFC task (training only) from BPOD format. 
% Running this code will open file dialog box to select data file.
% Function will save figure and summary stats (lick bias, # trials removed)

 rootdir = 'D:\MATLAB\Bpod Local\Data';
% rootdir='F:\';
sep = '\';
biasthreshold = 0.05;

cd(rootdir);
filename = uigetfile;
 
%Load trial data
namechunks = strsplit(filename,'_');
sumData.mouseID = namechunks{1};
sumData.date = namechunks{4};
cd([rootdir sep sumData.mouseID sep namechunks{2} '_' namechunks{3} sep 'Session Data']);
load(filename);


%% Extract lick and trial data

data = extractTrialData2AFC(SessionData);


%% delete lateral licks before the start of "WaitForLateralLicks" (lateral) or "WaitForLicks" (central)
 
aCount = 0; bCount = 0; cCount = 0;
 
%Left licks
for i = 1:length(data)
     if ~isempty(data(i).LeftLicks)
         a = find(data(i).LeftLicks > data(i).sampleLateralev(2) | data(i).LeftLicks  < data(i).sampleLateralev(1));  
         data(i).LeftLicks(a) = [];
         aCount = aCount + length(a);
     end 
end

%Right licks
for i = 1:length(data)
     if ~isempty(data(i).RightLicks)
         b = find(data(i).RightLicks > data(i).sampleLateralev(2) | data(i).RightLicks  < data(i).sampleLateralev(1));      
         data(i).RightLicks(b) = [];
         bCount = bCount + length(b);
     end
end

for i = 1:length(data)
     if ~isempty(data(i).CentralLicks)
         c = find(data(i).CentralLicks > data(i).sampleCentralev(2) | data(i).CentralLicks <data(i).sampleCentralev(1));      
         data(i).CentralLicks(c) = [];
         cCount = cCount + length(c);
     end 
end

fprintf('Removed %d lateral licks and %d central licks\n',[aCount+bCount,cCount]);
sumData.Rlicksremoved = bCount;
sumData.Llicksremoved = aCount;
sumData.Clicksremoved = cCount;


%% list trials with no lateral licks and remove

count1 = 1; count2 = 1;
lateralmiss = [];
centralmiss = [];
for i = 1:length(data)
    
    A = isempty(data(i).LeftLicks);
    B = isempty(data(i).RightLicks);
    C = isempty(data(i).CentralLicks);
    
    if A && B
        lateralmiss(count1) = i;
        count1 = count1 + 1;
    elseif C
        centralmiss(count2) = i;
        count2 = count2 + 1;
    end
end

% remove these trials from trial struct
data([lateralmiss centralmiss]) = [];

fprintf('Removed %d trials with no lateral licks\nRemoved %d trials with no central licks\n',[length(lateralmiss) length(centralmiss)]);

%% find the direction of the first lateral lick for each trial; left-1; right-2
 
for i = 1:length(data)
    if ~isempty(data(i).LeftLicks(:)) && isempty(data(i).RightLicks(:)) %If there are only left licks ...
        
        data(i).FirstLick = 1;
        
    elseif ~isempty(data(i).RightLicks(:)) && isempty(data(i).LeftLicks(:)) %If there are only right licks ...
        
        data(i).FirstLick = 2;
    
    elseif ~isempty(data(i).LeftLicks(:)) && ~isempty(data(i).RightLicks(:)) %If there are licks for both left and right ...
        
        if data(i).LeftLicks(1,1) < data(i).RightLicks(1,1) %If first left lick occurs before first right lick ...
            data(i).FirstLick = 1;
        else
            data(i).FirstLick = 2;
        end
    end
    
end

%% bias calculation - are they making more errors in one direction than the other

Lerror = 0;
Rerror = 0;
Lcount = 0;
Rcount = 0;

for i = 1:length(data)
    if data(i).FirstLick == 2 && data(i).TrialSequence == 1 %Licks right on a LEFT trial
        Lerror = Lerror+1;
    end
    if  data(i).FirstLick == 1 && data(i).TrialSequence == 2 %Licks left on a RIGHT trial
        Rerror = Rerror+1;
    end
    if data(i).TrialSequence == 1 %Total number of left trials
        Lcount = Lcount+1;
    end
    if data(i).TrialSequence == 2 %Total number of right trials
        Rcount = Rcount+1;
    end
end
sumData.bias = Lerror/Lcount - Rerror/Rcount;

%Display bias
if sumData.bias > biasthreshold
    fprintf('Right lick bias: %4.2f\n',sumData.bias);
    sumData.biasdir = 'R';
    
elseif sumData.bias < -biasthreshold
    fprintf('Left lick bias: %4.2f\n',sumData.bias);
    sumData.biasdir = 'L';
else
    fprintf('No lick bias\n');
    sumData.biasdir = 'none';
end

%Calculate percent trials correct
sumData.performance = 100*(sum([data.reward])./length(data));
fprintf('Percent correct: %4.2f\n',sumData.performance);

%% %%%%%%%%%%%%%%%%%%%
%   Lick raster plot
%%%%%%%%%%%%%%%%%%%%%%
p = zeros(1,7);
legendlabels = {'Left Trial','Right Trial','Central Licks','Left Licks','Right Licks','reward','no reward'};

figure; 
for i = 1:length(data) 
    hold on;
    %trial type (L or R)
     if data(i).TrialSequence == 1
        p1 = scatter(0,i,'c', 'filled');hold on;
        p(1) = p1(1);
     elseif data(i).TrialSequence == 2
        p2 = scatter(0,i,'m', 'filled');hold on;
        p(2) = p2(1);
     end
 
    %Plot licks
    p3 = plot([data(i).CentralLicks; data(i).CentralLicks] , [repmat(i-0.4,1,size(data(i).CentralLicks,2));repmat(i+0.4,1,size(data(i).CentralLicks,2))],'k');
    p(3) = p3(1);
    
    if ~isempty(data(i).LeftLicks)
        p4 =  plot([data(i).LeftLicks; data(i).LeftLicks] , [repmat(i-0.4,1,size(data(i).LeftLicks,2));repmat(i+0.4,1,size(data(i).LeftLicks,2))],'b');    
        p(4) = p4(1);
    end
    
    if ~isempty(data(i).RightLicks)
        p5 = plot([data(i).RightLicks; data(i).RightLicks] , [repmat(i-0.4,1,size(data(i).RightLicks,2));repmat(i+0.4,1,size(data(i).RightLicks,2))],'r');    
        p(5) = p5(1);
    end


    %reward/no reward
    if data(i).reward == 1
        p6 = scatter(0.5,i,'g','filled');hold on;
        p(6) = p6(1);
    else
        p7 = scatter(0.5,i,'r','filled');hold on;
        p(7) = p7(1);
    end

       
  
end

set(gca,'TickDir','out','FontSize',18,'YLim',[0 length(data)+2])
xlabel('Time(s)','Interpreter','latex','FontSize',20)
ylabel('Trial','Interpreter','latex','FontSize',20)
title([sumData.mouseID '-' sumData.date ' - Lick Raster'],'Interpreter','latex','FontSize',20) 
leg = legendlabels; leg(p == 0) = []; legend(p(p>0),leg,'location','NorthwestOutside')

  
ppsize = [1400 700];
set(gcf,'PaperPositionMode','auto');         
set(gcf,'PaperOrientation','landscape');
set(gcf,'PaperUnits','points');
set(gcf,'PaperSize',ppsize);
set(gcf,'Position',[0 0 ppsize]);


print([sumData.mouseID '-' sumData.date '-LickRaster'],'-r400','-dpdf');
save([sumData.mouseID '-' sumData.date '-SummaryData'],'data','sumData');

