function plot2AC_LickRaster(filename)
rootdir = 'D:\MATLAB\Bpod Local\Data';
sep = '\';
biasthreshold = 0.05;
 
%Load trial data
namechunks = strsplit(filename,'_');
sumData.mouseID = namechunks{1};
sumData.date = namechunks{4};
cd([rootdir sep sumData.mouseID sep namechunks{2} '_' namechunks{3} sep 'Session Data']);
load(filename);
dataRaw = SessionData;


%% Extract lick and trial data

%Extract lick events for central and lateral spouts

for i = 1:length(dataRaw.TrialSequence)
    
    if any(strcmp(fieldnames(dataRaw.RawEvents.Trial{1,i}.Events),'AnalogIn1_3'))
        data.trial(i).CentralLicks = dataRaw.RawEvents.Trial{1,i}.Events.AnalogIn1_3(1,:);
    else data.trial(i).CentralLicks = [];
    end
    
    if any(strcmp(fieldnames(dataRaw.RawEvents.Trial{1,i}.Events),'AnalogIn1_2'))  
        data.trial(i).RightLicks = dataRaw.RawEvents.Trial{1,i}.Events.AnalogIn1_2(1,:);
    else data.trial(i).RightLicks = [];
    end
    
    if any(strcmp(fieldnames(dataRaw.RawEvents.Trial{1,i}.Events),'AnalogIn1_1'))
        data.trial(i).LeftLicks = dataRaw.RawEvents.Trial{1,i}.Events.AnalogIn1_1(1,:);  
    else data.trial(i).LeftLicks = [];
    end
    
   data.trial(i).TrialSequence = dataRaw.TrialSequence(i); 
   data.trial(i).original_trialn = i; 
   data.trial(i).reward = ~isnan(dataRaw.RawEvents.Trial{1,i}.States.reward(1,1)); 
end 


%% delete lateral licks before the start of "WaitForLateralLicks" (lateral) or "WaitForLicks" (central)
 
a = []; b = []; c = [];
 
%Left licks
for i = 1:length(data.trial)
     if ~isempty(data.trial(i).LeftLicks(:))
         a = find(data.trial(i).LeftLicks(1:end) < dataRaw.RawEvents.Trial{1,i}.States.WaitForLateralLicks(1,1));      
         data.trial(i).LeftLicks(a) = [];
     else   
     end 
end

%Right licks
for i = 1:length(data.trial)
     if ~isempty(data.trial(i).RightLicks(:))
         b = find(data.trial(i).RightLicks(1:end) < dataRaw.RawEvents.Trial{1,i}.States.WaitForLateralLicks(1,1));      
         data.trial(i).RightLicks(b) = [];
     else
     end
end

for i = 1:length(data.trial)
     if ~isempty(data.trial(i).CentralLicks(:))
         c = find(data.trial(i).CentralLicks(1:end) < dataRaw.RawEvents.Trial{1,i}.States.WaitForLicks(1,1));      
         data.trial(i).CentralLicks(c) = [];
     else   
     end 
end

fprintf('Removed %d lateral licks and %d central licks\n',[length(a)+length(b),length(c)]);
%% find the direction of the first lateral lick for each trial; left-1; right-2
 
idx = 1;
for i = 1:length(dataRaw.TrialSequence)
    if ~isempty(data.trial(idx).LeftLicks(:)) && isempty( data.trial(idx).RightLicks(:)) %If there are only left licks ...
        data.trial(idx).FirstLick = 1;
    elseif ~isempty(data.trial(idx).RightLicks(:)) && isempty(data.trial(idx).LeftLicks(:)) %If there are only right licks ...
        data.trial(idx).FirstLick = 2;
    elseif ~isempty(data.trial(idx).LeftLicks(:)) && ~isempty(data.trial(idx).RightLicks(:)) %If there are licks for both left and right ...
        if data.trial(idx).LeftLicks(1,1) < data.trial(idx).RightLicks(1,1) %If first left lick occurs before first right lick ...
            data.trial(idx).FirstLick = 1;
        else
            data.trial(idx).FirstLick = 2;
        end
    end
    
        idx = idx + 1;
end
%% list trials with no lateral licks and remove

count = 1;
lateralmiss = [];
for i = 1:length(data.trial)
    
    A = isempty(data.trial(i).LeftLicks(:));
    B = isempty(data.trial(i).RightLicks(:));
    
    if A && B
        lateralmiss(count) = i;
        count = count + 1;
    end
end

% remove these trials from trial struct
c = lateralmiss; % can add other problem trials in the future
data.trial(c) = [];

fprintf('Removed %d trials with no lateral licks\n',length(c));

%% bias calculation are they making more errors in one direction than the other

Lerror = 0;
Rerror = 0;
Lcount = 0;
Rcount = 0;
for i =1:length(data.trial)
    if data.trial(i).FirstLick == 2 && data.trial(i).TrialSequence == 1 %Licks right on a LEFT trial
        Lerror = Lerror+1;
    end
    if  data.trial(i).FirstLick == 1 && data.trial(i).TrialSequence == 2 %Licks left on a RIGHT trial
        Rerror = Rerror+1;
    end
    if data.trial(i).TrialSequence == 1 %Total number of left trials
        Lcount = Lcount+1;
    end
    if data.trial(i).TrialSequence == 2 %Total number of right trials
        Rcount = Rcount+1;
    end
    trial(i).bias = Lerror/Lcount - Rerror/Rcount;
end
sumData.bias = Lerror/Lcount - Rerror/Rcount;

%Display bias
if sumData.bias > biasthreshold
    fprintf('Right lick bias: %4.2f\n',sumData.bias);
    
elseif sumData.bias < -biasthreshold
    fprintf('Left lick bias: %4.2f\n',sumData.bias);
else
    fprintf('No lick bias\n');
end

%% %%%%%%%%%%%%%%%%%%%
%   Lick raster plot
%%%%%%%%%%%%%%%%%%%%%%

figure; 
for i = 1:length(data.trial)  
    %trial type (L or R)
     if data.trial(i).TrialSequence == 1
        p1 = scatter(0,i,'c', 'filled');hold on;
     elseif data.trial(i).TrialSequence == 2
        p2 = scatter(0,i,'m', 'filled');hold on;
     end
 
    %Plot licks
    p4 = plot([data.trial(i).CentralLicks;data.trial(i).CentralLicks] , [repmat(i-0.4,1,size(data.trial(i).CentralLicks,2));repmat(i+0.4,1,size(data.trial(i).CentralLicks,2))],'k');

    p5 =  plot([data.trial(i).LeftLicks;data.trial(i).LeftLicks] , [repmat(i-0.4,1,size(data.trial(i).LeftLicks,2));repmat(i+0.4,1,size(data.trial(i).LeftLicks,2))],'b');
    hold on;

    p6 = plot([data.trial(i).RightLicks;data.trial(i).RightLicks] , [repmat(i-0.4,1,size(data.trial(i).RightLicks,2));repmat(i+0.4,1,size(data.trial(i).RightLicks,2))],'r');
    hold on;


    %reward/no reward
    if data.trial(i).reward == 1
        p7 = scatter(8,i,'g','filled');hold on;
    else
        p8 = scatter(8,i,'r','filled');hold on;
    end

       
  
end

set(gca,'TickDir','out','FontSize',18,'XLim',[0 8],'YLim',[0 length(data.trial)+5])
xlabel('Time(s)','Interpreter','latex','FontSize',20)
ylabel('Trial','Interpreter','latex','FontSize',20)
title([sumData.mouseID '-' sumData.date ' - Lick Raster'],'Interpreter','latex','FontSize',20) 
legend([p1(1),p2(1),p4(1),p5(1),p6(1),p7(1),p8(1)],{'Left Trial','Right Trial','Central Licks','Left Licks','Right Licks','reward','no reward'},'location','NorthwestOutside')  
   
  
set(gcf,'units','normalized','outerposition',[0 0 1 1]);
