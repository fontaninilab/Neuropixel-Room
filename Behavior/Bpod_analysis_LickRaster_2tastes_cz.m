%% process 2-taste 2AFC data recorded from Bpod

% make sure to cd the folder with the .mat file output from Bpod
% inputs:
%   filename - the .mat file 
%   assigned_tastes: 1 x 2 cell, the taste names
%   direction: 1 x 2 double 1: left, 2: right

% example output:'sumdata': struct with the following fields
%     mouseID: 'CZN02'
%     date: '20221031'
%     bias: 0.0817
%     data: [1×1 struct]
%     perf: [2×1 double]
%     correctcount: [45 54]
%     trialcount: [56 61]
function [sumData] = Bpod_analysis_LickRaster_2tastes_cz(filename,assigned_tastes,directions,plot)
% cd('D:\MATLAB\Bpod Local\Data\QM227\Taste2AC_Training4\Session Data')
% filename='QM227_Taste2AC_Training4_20230522_133651';
% assigned_tastes={ 'NaCl','suc'};
% directions=[1,2];
namechunks = strsplit(filename,'_');
sumData.mouseID =namechunks{1};
sumData.date = namechunks{end-1};

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
%% delete unreasonable "licks"
for i=1:length(data.trial)
    %delete central licks before "CentralForward" and after "MyDelay"
   if ~isempty (data.trial(i).CentralLicks)
 data.trial(i).CentralLicks(data.trial(i).CentralLicks<dataRaw.RawEvents.Trial{1,i}.States.CentralForward(1,2))=[];
   end
 %      data.trial(i).CentralLicks(data.trial(i).CentralLicks<dataRaw.RawEvents.Trial{1,i}.States.CentralForward(1,2)|data.trial(i).CentralLicks>dataRaw.RawEvents.Trial{1,i}.States.MyDelay(1,1))=[];
%     % delete lateral licks before the end of "WaitForLateralLicks" and after the start of "LateralSpoutsDown"
     if ~isempty(data.trial(i).LeftLicks) 
        data.trial(i).LeftLicks(data.trial(i).LeftLicks<dataRaw.RawEvents.Trial{1,i}.States.WaitForLateralLicks(1,2))=[];
  data.trial(i).LeftLicks(data.trial(i).LeftLicks>dataRaw.RawEvents.Trial{1,i}.States.LateralSpoutsDown(1,1))=[];        
    else
    end
    if ~isempty(data.trial(i).RightLicks)
     data.trial(i).RightLicks(data.trial(i).RightLicks<dataRaw.RawEvents.Trial{1,i}.States.WaitForLateralLicks(1,2))=[];    
      data.trial(i).RightLicks(data.trial(i).RightLicks>dataRaw.RawEvents.Trial{1,i}.States.LateralSpoutsDown(1,1))=[];    
    else
    end
end
 
% for i=1:length(data.trial)
%     if ~isempty(data.trial(i).RightLicks(:))
%         b =find(data.trial(i).RightLicks(1:end)<dataRaw.RawEvents.Trial{1,i}.States.WaitForLateralLicks(1,1));
%         data.trial(i).RightLicks(b)=[];
%     else
%     end
% end

%% remove trials with no lateral licks on either side, or no central licks
data_trial_cell=squeeze(struct2cell(data.trial)); % a # of fields x # of trial cell array
%trials with no central licks
temp1=cellfun(@isempty,data_trial_cell(1,:));
%trials with no right licks
temp2=cellfun(@isempty,data_trial_cell(2,:));
%trials with no left licks
temp3=cellfun(@isempty,data_trial_cell(3,:));
data.trial(temp1|(temp2&temp3))=[];
%% find the direction of the first lateral lick; left-1; right-2 
idx=1;
for i=1:length(data.trial)
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
%% %% find lick duration and # of central licks for central, lateral
% find reaction time (time between last central lick and first lateral
% lick)
idx=1;
for i=1:length(data.trial)
    data.trial(idx).CentralLickCount=numel(data.trial(i).CentralLicks);

    data.trial(idx).CentralLickDuration= data.trial(i).CentralLicks(end)- data.trial(i).CentralLicks(1);
    if  data.trial(i).FirstLick==1
        data.trial(idx).ReactionTime= data.trial(i).LeftLicks(1)- data.trial(i).CentralLicks(end);
        data.trial(idx).LeftLickCount=numel(data.trial(i).LeftLicks);
        data.trial(idx).LeftLickDuration= data.trial(i).LeftLicks(end)- data.trial(i).LeftLicks(1);
    else
        data.trial(idx).ReactionTime= data.trial(i).RightLicks(1)- data.trial(i).CentralLicks(end);
        data.trial(idx).RightLickCount=numel(data.trial(i).RightLicks);
        data.trial(idx).RightLickDuration= data.trial(i).RightLicks(end)- data.trial(i).RightLicks(1);
    end
    idx=idx+1;
end
%%  %%  performance for each taste, central lick counts duration, reaction time

n_tastes=size(assigned_tastes,2);

x=zeros(1,length(assigned_tastes));
trialcount=zeros(1,length(assigned_tastes));
c_lickcount=zeros(1,length(assigned_tastes));
c_lickduration=zeros(1,length(assigned_tastes));
lateral_lickcount=zeros(1,length(assigned_tastes));
lateral_lickduration=zeros(1,length(assigned_tastes));
react_t=zeros(1,length(assigned_tastes));
b=1;
perf=zeros(n_tastes,1);
for j=1:n_tastes
    for i=1:length(data.trial)

        if data.trial(i).TrialSequence == directions(j) && data.trial(i).reward == 1
            x(b)=x(b)+1;
        else
        end

        if data.trial(i).TrialSequence == directions(j)
            trialcount(b)=trialcount(b)+1;
            c_lickcount(b)= c_lickcount(b)+ data.trial(i).CentralLickCount;
            c_lickduration(b)= c_lickduration(b)+ data.trial(i).CentralLickDuration;
            react_t(b)=react_t(b)+ data.trial(i).ReactionTime;
            if  data.trial(i).FirstLick==1
                lateral_lickcount(b)=lateral_lickcount(b)+ data.trial(i).LeftLickCount;
                lateral_lickduration(b)=lateral_lickcount(b)+data.trial(i).LeftLickDuration;
            elseif data.trial(i).FirstLick == 2
                lateral_lickcount(b)=lateral_lickcount(b)+ data.trial(i).RightLickCount;
                lateral_lickduration(b)=lateral_lickcount(b)+ data.trial(i).RightLickDuration;
            end

            data.trial(i).tastes(j) = x(b)/trialcount(b);

        else
            data.trial(i).tastes(j) = 0;
        end
    end
    perf(j)=x(j)/trialcount(j);
    b=b+1;
end
c_lickcount= c_lickcount./trialcount;
c_lickduration=c_lickduration./trialcount;
lateral_lickcount=lateral_lickcount./trialcount;
react_t=react_t./trialcount;
lateral_lickduration=lateral_lickduration./trialcount;

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
if plot==1
clf

for i=1:length(data.trial)
    %trial type (L or R)
    if data.trial(i).TrialSequence==1
       p1 = plot([0 0],[i i],'sb', 'MarkerSize',3,'MarkerEdgeColor','#B30099','MarkerFaceColor','#B30099');hold on;
    elseif data.trial(i).TrialSequence==2
        p2 = plot([0 0],[i i],'sb', 'MarkerSize',3,'MarkerEdgeColor','#33FFFF','MarkerFaceColor','#33FFFF');hold on;
    end
 
    %central&lateral licks
    for j=1:length(data.trial(i).CentralLicks)
        p4=plot([data.trial(i).CentralLicks(j) data.trial(i).CentralLicks(j)],[i i+0.9],'k');
    end;hold on
if ~ isempty(data.trial(i).LeftLicks)
    for j=1:length(data.trial(i).LeftLicks)
        p5= plot([data.trial(i).LeftLicks(j) data.trial(i).LeftLicks(j)],[i i+0.9],'Color','#B30099');
    end;hold on
else
end
if ~ isempty(data.trial(i).RightLicks)
    for j=1:length(data.trial(i).RightLicks)
        p6=plot([data.trial(i).RightLicks(j) data.trial(i).RightLicks(j)],[i i+0.9],'Color','#33FFFF');
    end;hold on
    else
end
    %reward/no reward

%     for j=1:n_tastes
%         if (data.trial(i).TrialSequence==j && data.trial(i).FirstLick==1)|| (data.trial(i).TrialSequence==2 && data.trial(i).FirstLick==2)
%             p7=plot([8 8],[i i],'og', 'MarkerSize',3);hold on;
%         else
%             p8=plot([8 8],[i i],'or', 'MarkerSize',3);hold on;
%         end
%     end
 
        if data.trial(i).TrialSequence==data.trial(i).FirstLick
            p7=plot([8 8],[i i],'og', 'MarkerSize',3);hold on;
        else
            p8=plot([8 8],[i i],'or', 'MarkerSize',3);hold on;
        end
 


end
xlim([0 8]);
ylim([0 length(data.trial)+5]);
xlabel('Time(s)','FontSize',20)
ylabel('Trials','FontSize',20)
title([sumData.mouseID '-' sumData.date ' - Lick Raster'],'FontSize',20)
if ~ isempty(data.trial(i).RightLicks) && ~ isempty(data.trial(i).LeftLicks)
legend([p1,p2,p4,p5,p6,p7,p8],{[assigned_tastes{directions(directions==1)},' Trial'],[assigned_tastes{directions(directions==2)},' Trial'],'Central Licks','Left Licks','Right Licks','reward','no reward'},'location','NorthwestOutside')
elseif  isempty(data.trial(i).RightLicks) 
    legend([p1,p2,p4,p5,p7,p8],{[assigned_tastes{directions(directions==1)},' Trial'],[assigned_tastes{directions(directions==2)},' Trial'],'Central Licks','Left Licks','reward','no reward'},'location','NorthwestOutside')
elseif  isempty(data.trial(i).LeftLicks)
    legend([p1,p2,p4,p6,p7,p8],{[assigned_tastes{directions(directions==1)},' Trial'],[assigned_tastes{directions(directions==2)},' Trial'],'Central Licks','Right Licks','reward','no reward'},'location','NorthwestOutside')
end
set(gcf,'units','normalized','outerposition',[0 0 1 1]);



  figurename1=[filename,'_','licking_raster','.pdf'];
    exportgraphics(gcf,figurename1,'ContentType','vector')

else
end
%% save data
sumData.data=data;
sumData.perf=perf;
sumData.correctcount=x;
sumData.trialcount=trialcount;
% cd('D:\MATLAB Drive\Taste2AC\summary_data\');
% if exist(sumData.mouseID)==7
%     cd(['D:\MATLAB Drive\Taste2AC\summary_data\' sumData.mouseID]);
%     if  exist('training.mat')==2
%         load('training.mat');
%         f = size(summaryData,2);
%         summaryData(f+1) = sumData;
%         save('training','summaryData');
%     else
%         f=1;
%         summaryData = sumData;
%         save('training','summaryData');
%     end
% else
%     mkdir(sumData.mouseID);
%     cd(['D:\MATLAB Drive\Taste2AC\summary_data\' sumData.mouseID]);
%     f=1;
%     summaryData = sumData;
%     save('training','summaryData');

end
