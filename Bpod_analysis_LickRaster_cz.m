%% process data recorded from Intan board

    %filename - the .mat file output from Bpod
    

function [sumData] = Bpod_analysis_LickRaster_cz(filename)
%% 
clear
clc
filename='QM051_Taste2AC_Training4_20201226_130823';
sumData.mouseID=filename(1:5);
sumData.date=filename(end-14:end-7);
load(filename);
dataRaw = SessionData;
idx=1;

for i=1:length(dataRaw.TrialSequence)
    if any(strcmp(fieldnames(dataRaw.RawEvents.Trial{1,i}.Events),'AnalogIn1_3'))
        data.trial(idx).CentralLicks(:) = dataRaw.RawEvents.Trial{1,i}.Events.AnalogIn1_3(1,:);
    end
    if any(strcmp(fieldnames(dataRaw.RawEvents.Trial{1,i}.Events),'AnalogIn1_2'))  
        data.trial(idx).RightLicks(:)=dataRaw.RawEvents.Trial{1,i}.Events.AnalogIn1_2(1,:);
    end
    if any(strcmp(fieldnames(dataRaw.RawEvents.Trial{1,i}.Events),'AnalogIn1_1'))
        data.trial(idx).LeftLicks(:)=dataRaw.RawEvents.Trial{1,i}.Events.AnalogIn1_1(1,:);  
    end
   idx=idx+1;
end
 
data.TrialSequence=dataRaw.TrialSequence;
data.reward=zeros(1,dataRaw.nTrials);

for i=1:dataRaw.nTrials
data.reward(i)= ~isnan(dataRaw.RawEvents.Trial{1,i}.States.reward(1,1));  
end

idx=1;
for i=1:length(data.trial)
    data.trial(idx).TrialSequence(:)=dataRaw.TrialSequence(i);
    data.trial(idx).reward(:)=data.reward(i);
    data.trial(idx).original_trialn=i;
   
     idx=idx+1;
end
%% delete lateral licks before the start of "WaitForLateralLicks"
 
 a=[];
 b=[];
for i=1:length(data.trial)
 if ~isempty(data.trial(i).LeftLicks(:))
 a =find(data.trial(i).LeftLicks(1:end)<dataRaw.RawEvents.Trial{1,i}.States.WaitForLateralLicks(1,1));      
data.trial(i).LeftLicks(a)=[];
 else   
 end 
end
for i=1:length(data.trial)
 if ~isempty(data.trial(i).RightLicks(:))
 b =find(data.trial(i).RightLicks(1:end)<dataRaw.RawEvents.Trial{1,i}.States.WaitForLateralLicks(1,1));      
data.trial(i).RightLicks(b)=[];
 else
 end
end
%% find the direction of the first lateral lick; left-1; right-2
 
     idx=1;
for i=1:length(dataRaw.TrialSequence)
    if ~isempty(data.trial(idx).LeftLicks(:)) && isempty( data.trial(idx).RightLicks(:))
    data.trial(idx).FirstLick=1;
    elseif ~isempty(data.trial(idx).RightLicks(:))&& isempty(data.trial(idx).LeftLicks(:))
    data.trial(idx).FirstLick=2;
    elseif ~isempty(data.trial(idx).LeftLicks(:)) && ~isempty(data.trial(idx).RightLicks(:))
    if data.trial(idx).LeftLicks(1,1)<data.trial(idx).RightLicks(1,1)
        data.trial(idx).FirstLick=1;
    else
    data.trial(idx).FirstLick=2;
    end
    end
    
        idx=idx+1;
end
%% list trials with no lateral licks 

j=1;
lateralmiss=[];
for i=1:length(data.trial)
    
    A = isempty(data.trial(i).LeftLicks(:));
    B = isempty(data.trial(i).RightLicks(:));
    
    if A&&B
        lateralmiss(j) = i;
        j=j+1;
    end
end

%% remove these trials from trial struct

c=[lateralmiss]; % can add other problem trials in the future

data.trial(c) = [];
 
 %%   perf for sucrose (taste line 1) trials
trialcount_s=zeros(1, length(data.trial));
outcome_s=zeros(1, length(data.trial));
 for i=1:length(data.trial)
        if  data.trial(i).TrialSequence == 1 
            trialcount_s(i)=1;
            if  data.trial(i).FirstLick==1
            outcome_s(i)=1;
            else
            outcome_s(i)=0;
            end
        end
        
 end
 
totalcount_s=cumsum(trialcount_s);
x_s=cumsum(outcome_s);
perf_s=x_s/totalcount_s;
  
%%   perf for water (taste line 8) trials
trialcount_w=zeros(1, length(data.trial));
outcome_w=zeros(1, length(data.trial));
 for i=1:length(data.trial)
        if  data.trial(i).TrialSequence == 2 
            trialcount_w(i)=1;
            if  data.trial(i).FirstLick==2
            outcome_w(i)=1;
            else
            outcome_w(i)=0;
            end
        end
        
 end
 
totalcount_w=cumsum(trialcount_w);
x_w=cumsum(outcome_w);
perf_w=x_w/totalcount_w;
 perf=[perf_s; perf_w];
 x=[x_s(1, end) x_w(1, end)];
 trialcount=[totalcount_s(1,end) totalcount_w(1,end)];

%% bias calculation are they making more errors in one direction than the other

Lerror = 0;
Rerror=0;
Lcount = 0;
Rcount = 0;
for i =1:length(data.trial)
    if data.trial(i).FirstLick==2 && data.trial(i).TrialSequence==1
        Lerror = Lerror+1;
    end
    if  data.trial(i).FirstLick==1 && data.trial(i).TrialSequence==2
        Rerror = Rerror+1;
    end
    if data.trial(i).TrialSequence==1
        Lcount = Lcount+1;
    end
    if data.trial(i).TrialSequence==2
        Rcount = Rcount+1;
    end
    trial(i).bias = Lerror/Lcount - Rerror/Rcount;
end
sumData.bias = Lerror/Lcount - Rerror/Rcount;
    


%% lick raster plot
 
for i=1:length(data.trial)  
    %trial type (L or R)
     if data.trial(i).TrialSequence==1
    p1 = plot([0 0],[i i],'ob', 'MarkerSize',3);hold on;
   elseif data.trial(i).TrialSequence==2
       p2 = plot([0 0],[i i],'oc', 'MarkerSize',3);hold on;
     end
 
   %central&lacteral licks
    for j=1:length(data.trial(i).CentralLicks)
                p4=plot([data.trial(i).CentralLicks(j) data.trial(i).CentralLicks(j)],[i i+0.9],'k');  
    end;hold on
       
    for j=1:length(data.trial(i).LeftLicks)
               p5= plot([data.trial(i).LeftLicks(j) data.trial(i).LeftLicks(j)],[i i+0.9],'b');  
    end;hold on
    for j=1:length(data.trial(i).RightLicks)
                p6=plot([data.trial(i).RightLicks(j) data.trial(i).RightLicks(j)],[i i+0.9],'c');  
    end;hold on
    %reward/no reward
     
        for j=1:7
            if (data.trial(i).TrialSequence==j && data.trial(i).FirstLick==1)|| (data.trial(i).TrialSequence==2 && data.trial(i).FirstLick==2)
        p7=plot([8 8],[i i],'og', 'MarkerSize',3);hold on;
            else
                p8=plot([8 8],[i i],'or', 'MarkerSize',3);hold on;
            end
        end
    
       
  
end
   xlim([0 8]);
   ylim([0 length(data.trial)+5]);
   xlabel('Time(s)','Interpreter','latex','FontSize',20)
ylabel('# Trials','Interpreter','latex','FontSize',20)
title([sumData.mouseID '-' sumData.date ' - Lick Raster'],'Interpreter','latex','FontSize',20) 
  legend([p1,p2,p4,p5,p6,p7,p8],{'Left Trial','Right Trial','Central Licks','Left Licks','Right Licks','reward','no reward'},'location','NorthwestOutside')  
   
  
set(gcf,'units','normalized','outerposition',[0 0 1 1]);

 



 
 %% save data
sumData.mouseID=filename(1:5);
sumData.date=filename(end-14:end-7);
sumData.data=data;
sumData.perf=perf;
sumData.correctcount=x;
sumData.trialcount=trialcount;
clearvars -except sumData FinalPerformance data tasteID x cwd
 
 
% cd('E:\MATLAB_files\Taste2AC\summary_data\');
% 
% if exist(sumData.mouseID)==7
%     cd(['E:\MATLAB_files\Taste2AC\summary_data\' sumData.mouseID]);
%     if exist(sumData.date)==7
%     load('Summary.mat');
%     f = size(summaryData,2);
%     summaryData(f+1) = sumData;
%     save('Summary','summaryData');
%     else mkdir(sumData.date);
%          cd(['E:\MATLAB_files\Taste2AC\summary_data\' sumData.mouseID '\' sumData.date]);
%     f=1;
%     summaryData = sumData;
%     save('Summary','summaryData');
%     end
% else
%     mkdir(sumData.mouseID);
%     cd(['E:\MATLAB_files\Taste2AC\summary_data\' sumData.mouseID]);
%      mkdir(sumData.date);
%          cd(['E:\MATLAB_files\Taste2AC\summary_data\' sumData.mouseID '\' sumData.date]);
%     f=1;
%     summaryData = sumData;
%     save('Summary','summaryData');
% end

cd('E:\MATLAB_files\Taste2AC\summary_data\');


if exist(sumData.mouseID)==7
    cd(['E:\MATLAB_files\Taste2AC\summary_data\' sumData.mouseID]);

    if  exist('thresholdtest.mat')==2
         load('thresholdtest.mat');
%     if  exist('training.mat')==2
%          load('training.mat');
    f = size(summaryData,2);
    summaryData(f+1) = sumData;
    save('thresholdtest','summaryData');
%     save('training','summaryData'); 
    else
    f=1;
    summaryData = sumData;
    save('thresholdtest','summaryData');  
%      save('training','summaryData');  
    end
%     
else
    mkdir(sumData.mouseID);
    cd(['E:\MATLAB_files\Taste2AC\summary_data\' sumData.mouseID]);
    f=1;
    summaryData = sumData;
    save('thresholdtest','summaryData');
    %      save('training','summaryData');  
end

