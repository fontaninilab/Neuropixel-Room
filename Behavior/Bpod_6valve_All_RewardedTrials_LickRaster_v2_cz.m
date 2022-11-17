
%input variables
    %filename - the .mat file output from Bpod
    %behavioral session
    %excel_tastes (string) - concentration of sucrose in each line example {'100', '60','60_MV','40','40_MV','0'}
    %excel_directions - correct direction for each line, 1 left, 2 right,
    % example [1 1 1 2 2 2]
%output
    %all other outputs are saved in the summary variable but you can also output
    %things individually if you want
    %matfile- the file name for sumData saved. contains the name of the
    %folder

function [sumData,matfile] = Bpod_6valve_All_RewardedTrials_LickRaster_v2_cz(filename, excel_tastes, excel_directions,subfoldername)
%% 
namechunks = strsplit(filename,'_');
sumData.mouseID = namechunks{1};
sumData.date = namechunks{end-1};
cd
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
%     idx=1;
% for i=1:length(dataRaw.TrialSequence)
%     if ~isempty(data.trial(idx).LeftLicks(:)) && isempty( data.trial(idx).RightLicks(:))
%     data.trial(idx).FirstLick=1;
%     elseif ~isempty(data.trial(idx).RightLicks(:))&& isempty(data.trial(idx).LeftLicks(:))
%     data.trial(idx).FirstLick=2;
%     elseif ~isempty(data.trial(idx).LeftLicks(:)) && ~isempty(data.trial(idx).RightLicks(:))
%     if data.trial(idx).LeftLicks(1,1)<data.trial(idx).RightLicks(1,1)
%         data.trial(idx).FirstLick=1;
%     else
%     data.trial(idx).FirstLick=2;
%     end
%     end
%     
%         idx=idx+1;
% end
% 


%save trial indices (Trial_Idx is 1 for testing trials, aka 20% probability)

data.ValveSequence=dataRaw.ValveSequence;
data.reward=zeros(1,dataRaw.nTrials);

for i=1:dataRaw.nTrials
data.reward(i)= ~isnan(dataRaw.RawEvents.Trial{1,i}.States.reward(1,1));  
end

idx=1;
for i=1:length(data.trial)
    data.trial(idx).TrialSequence(:)=dataRaw.TrialSequence(i);
    data.trial(idx).ValveSequence(:)=dataRaw.ValveSequence(i);
    data.trial(idx).reward(:)=data.reward(i);
    data.trial(idx).original_trialn=i;
   
    idx=idx+1;
end
%  
%    
%% Remove random contacts that are detected as licks (i.e. removing the "licks" that are out of the licking periods)
 
 a=[];
 b=[];
 c=[];
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
 for i=1:length(data.trial)
     if ~isempty(data.trial(i).CentralLicks(:))
         c=find((data.trial(i).CentralLicks(1:end)<1)); % chose an arbiturary t=1s as the time around the start of central licks.
         data.trial(i).CentralLicks(c)=[];
     end
 end

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

d=[lateralmiss]; % can add other problem trials in the future

data.trial(d) = [];
 %% find lick duration and # of central licks for central, lateral
 % find reaction time (time between last central lick and first lateral
 % lick)
 idx=1;
for i=1:length(data.trial)
   data.trial(idx).CentralLickCount=numel(data.trial(i).CentralLicks);
   data.trial(idx).CentralLickDuration= data.trial(i).CentralLicks(end)- data.trial(i).CentralLicks(1);
   if ~isempty(data.trial(idx).LeftLicks(:))
   data.trial(idx).LeftLickCount=numel(data.trial(i).LeftLicks);
   data.trial(idx).LeftLickDuration= data.trial(i).LeftLicks(end)- data.trial(i).LeftLicks(1); 
   end
   if ~isempty(data.trial(idx).RightLicks(:))
   data.trial(idx).RightLickCount=numel(data.trial(i).RightLicks);
   data.trial(idx).RightLickDuration= data.trial(i).RightLicks(end)- data.trial(i).RightLicks(1);
   end
    if  data.trial(i).FirstLick==1
    data.trial(idx).ReactionTime= data.trial(i).LeftLicks(1)- data.trial(i).CentralLicks(end);
    
    else
       data.trial(idx).ReactionTime= data.trial(i).RightLicks(1)- data.trial(i).CentralLicks(end);
    end
  
    if ~isempty(data.trial(idx).LeftLicks(:)) && ~isempty(data.trial(idx).RightLicks(:))
        data.trial(idx).Switch=1;
        % find how many switches per trial
        R= data.trial(idx).RightLicks;
    L= data.trial(idx).LeftLicks;
R1=[R;ones(size(R))]; %assign right licks with ones
L1=[L;zeros(size(L))];%assign left licks with zeros
com_LR=[R1 L1];

[~,order]=sort(com_LR(1,:)); %combine and sort the licks temporally and get the array with directions (left=0, right=1)
c=com_LR(:,order);
ind=diff(c(2,:))~=0; %caculate the differences between the adjecent licks (difference~=0: switch; difference=0: no switch)
data.trial(idx).SwitchCount=sum(ind); % count # of switches
       
        else
        data.trial(idx).Switch=0;
    end
    if  data.trial(idx).Switch==1 && data.trial(i).FirstLick==1
            data.trial(idx).SwitchLatency=data.trial(i).RightLicks(1)-data.trial(i).LeftLicks(1);
            
        elseif  data.trial(idx).Switch==1 && data.trial(i).FirstLick==2
             data.trial(idx).SwitchLatency=data.trial(i).LeftLicks(1)-data.trial(i).RightLicks(1);
    end     
    
    idx=idx+1;
end
 
 %%  performance for each taste, central lick counts duration, reaction time 
% tastes={num2str(100),num2str(50),num2str(25),num2str(10),num2str(5),num2str(2.5),num2str(1)};
tastes=1:6;
x=zeros(1,length(tastes));
trialcount=zeros(1,length(tastes));
c_lickcount=zeros(1,length(tastes));
c_lickduration=zeros(1,length(tastes));
correct_lateral_lickcount=zeros(1,length(tastes));
correct_lateral_lickduration=zeros(1,length(tastes));
error_lateral_lickcount=zeros(1,length(tastes));
error_lateral_lickduration=zeros(1,length(tastes));
react_t=zeros(1,length(tastes));
 
b=1;
perf=zeros(6,1);
for j=1:6
    for i=1:length(data.trial)
         
            if data.trial(i).ValveSequence == tastes(j) && data.trial(i).reward == 1 
             x(b)=x(b)+1;
            else
            end
        
        if data.trial(i).ValveSequence == tastes(j) 
            trialcount(b)=trialcount(b)+1;
            c_lickcount(b)= c_lickcount(b)+ data.trial(i).CentralLickCount;
            c_lickduration(b)= c_lickduration(b)+ data.trial(i).CentralLickDuration;
            react_t(b)=react_t(b)+ data.trial(i).ReactionTime;
         
            if  data.trial(i).TrialSequence==1 && data.trial(i).reward == 1 
            correct_lateral_lickcount(b)=correct_lateral_lickcount(b)+ data.trial(i).LeftLickCount;
            correct_lateral_lickduration(b)=correct_lateral_lickduration(b)+data.trial(i).LeftLickDuration;
            elseif data.trial(i).TrialSequence == 2 && data.trial(i).reward == 1 
            correct_lateral_lickcount(b)=correct_lateral_lickcount(b)+ data.trial(i).RightLickCount;
            correct_lateral_lickduration(b)=correct_lateral_lickduration(b)+ data.trial(i).RightLickDuration;
            elseif data.trial(i).TrialSequence==1 && data.trial(i).reward == 0
            error_lateral_lickcount(b)=error_lateral_lickcount(b)+ data.trial(i).RightLickCount;
            error_lateral_lickduration(b)=error_lateral_lickduration(b)+ data.trial(i).RightLickDuration;
            elseif data.trial(i).TrialSequence==2 && data.trial(i).reward == 0
            error_lateral_lickcount(b)=error_lateral_lickcount(b)+data.trial(i).LeftLickCount;
            error_lateral_lickduration(b)= error_lateral_lickduration(b)+data.trial(i).LeftLickDuration;
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
    correct_lateral_lickcount=correct_lateral_lickcount./trialcount;
    react_t=react_t./trialcount;
    correct_lateral_lickduration=correct_lateral_lickduration./trialcount;
    error_lateral_lickduration= error_lateral_lickduration./trialcount;
    error_lateral_lickcount=error_lateral_lickcount./trialcount;
    %% switch count
    
    trials_switched=zeros(1, length(tastes));
    switch_counts=zeros(1, length(tastes));
   switch_on_correct=zeros(1, length(tastes));
   switch_on_error=zeros(1, length(tastes));
  switch_counts_on_correct=zeros(1, length(tastes));
 switch_counts_on_error = zeros(1, length(tastes));
 
 b=1;
 
 for j=1:length(tastes)
 for i=1:length(data.trial)
        if   data.trial(i).ValveSequence == tastes(j) && data.trial(i).Switch == 1  
            trials_switched(b)=trials_switched(b)+1;
             switch_counts(b)=switch_counts(b)+data.trial(i).SwitchCount;
             
             
              if data.trial(i).reward==1
                switch_on_correct(b)=switch_on_correct(b)+1;
                switch_counts_on_correct(b)=switch_counts_on_correct(b)+data.trial(i).SwitchCount;
            elseif data.trial(i).reward==0
                switch_on_error(b)=switch_on_error(b)+1;
                switch_counts_on_error(b) = switch_counts_on_error(b)+data.trial(i).SwitchCount;
                end
            
        else
            data.trial(i).tastes(j) = 0; 
        end
       
 end
 b=b+1;
 end
 

  
counts_per_switch_on_correct=switch_counts_on_correct./switch_on_correct;
counts_per_switch_on_error=switch_counts_on_error./switch_on_error;
counts_per_switch=switch_counts./trials_switched;

 
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
    

%% extract tastes and directions from Excel

sumData.excel_tastes=excel_tastes;
sumData.excel_directions=excel_directions;



 
 %% save data
 
sumData.data=data;
sumData.perf=perf;
sumData.tastes=tastes;
sumData.correctcount=x;
sumData.trialcount=trialcount;
sumData.c_lickcount=c_lickcount;
sumData.c_lickduration=c_lickduration;
sumData.error_lateral_lickcount=error_lateral_lickcount;
sumData.correct_lateral_lickcount=correct_lateral_lickcount;
sumData.react_t=react_t;
sumData.error_lateral_lickduration=error_lateral_lickduration;
sumData.correct_lateral_lickduration=correct_lateral_lickduration;
 
%save switch counts

sumData.trials_switched=trials_switched;
sumData.switch_counts=switch_counts;
sumData.switch_on_correct=switch_on_correct;
sumData.switch_on_error=switch_on_error;
sumData.switch_counts_on_correct=switch_counts_on_correct;
sumData.switch_counts_on_error=switch_counts_on_error;
sumData.counts_per_switch_on_correct=counts_per_switch_on_correct;
sumData.counts_per_switch_on_error=counts_per_switch_on_error ;
sumData.counts_per_switch=counts_per_switch;

% clearvars -except sumData FinalPerformance data tasteID x cwd
 
 
cd('E:\MATLAB_files\Taste2AC\summary_data\');

% cd('C:\Users\User\MATLAB Drive\Taste2AC\summary_data\');
matfile=['Summary_6v_AllRewarded_',subfoldername,'.mat'];
if exist(sumData.mouseID)==7
    cd(['E:\MATLAB_files\Taste2AC\summary_data\' sumData.mouseID]);
%     cd(['C:\Users\User\MATLAB Drive\Taste2AC\summary_data\' sumData.mouseID]);
%     if exist(sumData.date)==7

    if  exist(matfile)==2
         load(matfile);
    f = size(summaryData,2);
    summaryData(f+1) = sumData;
    save(matfile,'summaryData');
    else
    f=1;
    summaryData = sumData;
    save(matfile,'summaryData');  
    end
%     else mkdir(sumData.date);
%          cd(['E:\MATLAB_files\Taste2AC\summary_data\' sumData.mouseID '\' sumData.date]);
%     f=1;
%     summaryData = sumData;
%     save('Summary_AllRewarded','summaryData');
%     end
else
    mkdir(sumData.mouseID);
    cd(['E:\MATLAB_files\Taste2AC\summary_data\' sumData.mouseID]);
%     cd(['C:\Users\User\MATLAB Drive\Taste2AC\summary_data\' sumData.mouseID]);
%      mkdir(sumData.date);
%          cd(['E:\MATLAB_files\Taste2AC\summary_data\' sumData.mouseID '\' sumData.date]);
    f=1;
    summaryData = sumData;
    save(matfile,'summaryData');
end
%% 
% 
% total_correct = [summaryData(1).correctcount; summaryData(2).correctcount; summaryData(3).correctcount]

%% 
% create a default color map ranging from blue to light blue for sucrose
% concentration
 cd(['E:\MATLAB_files\Taste2AC\summary_data\' sumData.mouseID]);
% cd(['C:\Users\User\MATLAB Drive\Taste2AC\summary_data\' sumData.mouseID]);
figure
color_n = length(unique(data.ValveSequence));
magenta = [179, 0, 153]/255;
lightmagenta = [247,230,245]/255;
color_gradient = [linspace(magenta(1),lightmagenta(1),color_n)', linspace(magenta(2),lightmagenta(2),color_n)', linspace(magenta(3),lightmagenta(3),color_n)'];

for i=1:length(data.trial)  
    %trial type (L or R)
     if data.trial(i).TrialSequence==1
    p1 = plot([0 0],[i+0.5 i+0.5],'ob', 'MarkerSize',3);hold on;
   elseif data.trial(i).TrialSequence==2
       p2 = plot([0 0],[i+0.5 i+0.5],'oc', 'MarkerSize',3);hold on;
     end
 
    for k=1:color_n
        if data.trial(i).ValveSequence==k
       p3= plot([0.5 0.5],[i+0.5 i+0.5],'sb','MarkerSize',3,'MarkerEdgeColor',color_gradient(k,:),'MarkerFaceColor',color_gradient(k,:));hold on;
        end
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
            if data.trial(i).reward==1
        p7=plot([8 8],[i+0.5 i+0.5],'og', 'MarkerSize',3);hold on;
            else
                p8=plot([8 8],[i+0.5 i+0.5],'or', 'MarkerSize',3);hold on;
            end
            
    % show trials with licks on both sides
   if data.trial(i).Switch==1
        p9=plot([8.1 8.1],[i+0.5 i+0.5],'.b', 'MarkerSize',15);hold on;
   end
   
end
 
       

   xlim([0 8.1]);
   ylim([0 length(data.trial)+5]);
   xlabel('Time(s)','Interpreter','latex','FontSize',20)
ylabel('Number of Trials','Interpreter','latex','FontSize',20)
title([sumData.mouseID '-' sumData.date ' - Lick Raster'],'Interpreter','latex','FontSize',20) 
  legend([p1,p2,p3,p4,p5,p6,p7,p8,p9],{'Left Trial','Right Trial','Sucrose Concentration','Central Licks','Left Licks','Right Licks','reward','no reward','switch'},'location','NorthwestOutside')  
   
  
 set(gcf,'units','normalized','outerposition',[0 0 1 1]);
 set(gcf,'renderer','painters')
 set(gcf,'PaperOrientation','landscape');
% 

figurename2=[sumData.date,'-',sumData.mouseID,subfoldername,'.pdf'];
folder=cd;
fullname= fullfile(folder,figurename2); 
print(fullname,'-dpdf','-fillpage');

end