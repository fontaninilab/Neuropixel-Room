function plot2AC_LickRaster(filename)
rootdir = 'D:\MATLAB\Bpod Local\Data';
sep = '\';
biasthreshold = 0.05;
 

%filename = 'TDPQF064_Taste2AC_Training4_20201227_090246';
namechunks = strsplit(filename,'_');
sumData.mouseID = namechunks{1};
sumData.date = namechunks{4};
cd([rootdir sep sumData.mouseID sep namechunks{2} '_' namechunks{3} sep 'Session Data']);
% cd([rootdir sep sumData.mouseID sep namechunks{2} '_' namechunks{3} '_' namechunks{4} '_' namechunks{5} sep 'Session Data']);
load(filename);
dataRaw = SessionData;


%% Extract lick and trial data

%Extract lick events for central and lateral spouts
idx = 1;
for i = 1:length(dataRaw.TrialSequence)
    if any(strcmp(fieldnames(dataRaw.RawEvents.Trial{1,i}.Events),'AnalogIn1_3'))
        data.trial(idx).CentralLicks(:) = dataRaw.RawEvents.Trial{1,i}.Events.AnalogIn1_3(1,:);
    end
    if any(strcmp(fieldnames(dataRaw.RawEvents.Trial{1,i}.Events),'AnalogIn1_2'))  
        data.trial(idx).RightLicks(:) = dataRaw.RawEvents.Trial{1,i}.Events.AnalogIn1_2(1,:);
    end
    if any(strcmp(fieldnames(dataRaw.RawEvents.Trial{1,i}.Events),'AnalogIn1_1'))
        data.trial(idx).LeftLicks(:) = dataRaw.RawEvents.Trial{1,i}.Events.AnalogIn1_1(1,:);  
    end
   idx = idx+1
end 

%Extract trial ID and reward
% % data.TrialSequence = dataRaw.TrialSequence;
reward = zeros(1,dataRaw.nTrials);

for i = 1:dataRaw.nTrials
    %data.reward(i)= ~isnan(dataRaw.RawEvents.Trial{1,i}.States.reward(1,1)); 
    reward(i) = ~isnan(dataRaw.RawEvents.Trial{1,i}.States.reward(1,1)); 
end

%idx = 1;
for i = 1:length(data.trial)
    
    data.trial(i).TrialSequence = dataRaw.TrialSequence(i);
    data.trial(i).reward = reward(i);
    data.trial(i).original_trialn = i;
   
    %idx = idx+1;
end
%% delete lateral licks before the start of "WaitForLateralLicks"
 
a = []; b = [];
 
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

j = 1;
lateralmiss = [];
for i = 1:length(data.trial)
    
    A = isempty(data.trial(i).LeftLicks(:));
    B = isempty(data.trial(i).RightLicks(:));
    
    if A && B
        lateralmiss(j) = i;
        j = j + 1;
    end
end

% remove these trials from trial struct
c = lateralmiss; % can add other problem trials in the future
data.trial(c) = [];

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

%% lick raster plot

figure; 
for i = 1:length(data.trial)  
    %trial type (L or R)
     if data.trial(i).TrialSequence == 1
        p1 = plot([0 0],[i i],'ob', 'MarkerSize',3);hold on;
     elseif data.trial(i).TrialSequence == 2
        p2 = plot([0 0],[i i],'oc', 'MarkerSize',3);hold on;
     end
 
   %central&lacteral licks
    for j = 1:length(data.trial(i).CentralLicks)
         p4 = plot([data.trial(i).CentralLicks(j) data.trial(i).CentralLicks(j)],[i i+0.9],'k');  
    end;hold on
       
    for j = 1:length(data.trial(i).LeftLicks)
         p5 = plot([data.trial(i).LeftLicks(j) data.trial(i).LeftLicks(j)],[i i+0.9],'b');  
    end;hold on
    
    for j = 1:length(data.trial(i).RightLicks)
         p6 = plot([data.trial(i).RightLicks(j) data.trial(i).RightLicks(j)],[i i+0.9],'c');  
    end;hold on
    
     
    %reward/no reward
    if data.trial(i).reward == 1
        p7 = plot([8 8],[i i],'og', 'MarkerSize',3);hold on;
    else
        p8 = plot([8 8],[i i],'or', 'MarkerSize',3);hold on;
    end


       
  
end

set(gca,'TickDir','out','FontSize',18,'XLim',[0 8],'YLim',[0 length(data.trial)+5])
xlabel('Time(s)','Interpreter','latex','FontSize',20)
ylabel('# Trials','Interpreter','latex','FontSize',20)
title([sumData.mouseID '-' sumData.date ' - Lick Raster'],'Interpreter','latex','FontSize',20) 
legend([p1,p2,p4,p5,p6,p7,p8],{'Left Trial','Right Trial','Central Licks','Left Licks','Right Licks','reward','no reward'},'location','NorthwestOutside')  
   
  
set(gcf,'units','normalized','outerposition',[0 0 1 1]);
