function alignedLickTimes = getLickTimes(events,fig)


trialStartTimes = events.trialStartEv./events.fsEv; 
centralLickTimes = events.lickEv.central./events.fsEv;
leftLickTimes = events.lickEv.left./events.fsEv;
rightLickTimes = events.lickEv.right./events.fsEv;

centralLickTimesTrial = centralLickTimes;
leftLickTimesTrial = leftLickTimes;
rightLickTimesTrial = rightLickTimes;

% Pre-allocate variables
centralLickTimesCentral = NaN(1,length(centralLickTimes));
leftLickTimesCentral = NaN(1,length(leftLickTimes));
rightLickTimesCentral = NaN(1,length(rightLickTimes));
alignedLickTimes.firstLateral = NaN(4,length(trialStartTimes));
alignedLickTimes.firstCentral = NaN(2,length(trialStartTimes));

%Lick ID's (consistent with BPOD output)
alignedLickTimes.RlickID = 2;
alignedLickTimes.LlickID = 1;

%%% For each lick align to trial start event and first central lick %%%
for i = 1:length(trialStartTimes)
    
    if i < length(trialStartTimes)        
         trialIDXcentral = find(centralLickTimes >= trialStartTimes(i) & centralLickTimes < trialStartTimes(i+1)); %Find lick times for trial i   
    else    
        trialIDXcentral = find(centralLickTimes >= trialStartTimes(end));
    end
   
   if ~isempty(trialIDXcentral)
       
       %%% Central lick times for trial i %%%
       trialNc(trialIDXcentral) = i; %Populate vector with trial N's
       centralLickTimesTrial(trialIDXcentral) = centralLickTimesTrial(trialIDXcentral) - trialStartTimes(i);% Align to trial start time
       centralLickTimesCentral(trialIDXcentral) = centralLickTimesTrial(trialIDXcentral) - centralLickTimesTrial(trialIDXcentral(1)); %Align to first central lick
       
       % Extract time of first central lick for trial i
       alignedLickTimes.firstCentral(1,i) = i;
       alignedLickTimes.firstCentral(2,i) = centralLickTimes(trialIDXcentral(1)); %Raw lick time relative to session start
       alignedLickTimes.firstCentral(3,i) = centralLickTimesTrial(trialIDXcentral(1)); %Raw lick time relative to trial start
        
       %%% Left lick times for trial i %%%
       if i < length(trialStartTimes)
           trialIDXleft = find(leftLickTimes >= trialStartTimes(i) & leftLickTimes < trialStartTimes(i+1));%Find lick times for trial i
       else
           trialIDXleft = find(leftLickTimes >= trialStartTimes(end));
       end
       
       trialNl(trialIDXleft) = i;%Populate vector with trial N's
       leftLickTimesTrial(trialIDXleft) = leftLickTimesTrial(trialIDXleft) - trialStartTimes(i);% Align to trial start time
       leftLickTimesCentral(trialIDXleft) = leftLickTimesTrial(trialIDXleft) - centralLickTimesTrial(trialIDXcentral(1)); %Align to first central lick 

       %%% Right lick times for trial i %%%
       if i < length(trialStartTimes)
           trialIDXright = find(rightLickTimes >= trialStartTimes(i) & rightLickTimes < trialStartTimes(i+1));%Find lick times for trial i
       else
           trialIDXright = find(rightLickTimes >= trialStartTimes(end));
       end
       
       trialNr(trialIDXright) = i;%Populate vector with trial N's
       rightLickTimesTrial(trialIDXright) = rightLickTimesTrial(trialIDXright) - trialStartTimes(i);% Align to trial start time
       rightLickTimesCentral(trialIDXright) = rightLickTimesTrial(trialIDXright) - centralLickTimesTrial(trialIDXcentral(1)); %Align to first central lick 

       %%% Find first lateral lick per trial %%%
       rightLicks = rightLickTimes(trialIDXright);
       leftLicks = leftLickTimes(trialIDXleft);
       if isempty(rightLicks) && ~isempty(leftLicks) %If only left licks...
           
           lateralID = alignedLickTimes.LlickID;
           alignedLickTimes.firstLateral(1,i) = i;
           alignedLickTimes.firstLateral(2,i) = leftLicks(1);
           alignedLickTimes.firstLateral(3,i) = leftLickTimes(trialIDXleft(1)) - trialStartTimes(i);
           alignedLickTimes.firstLateral(4,i) = leftLickTimesTrial(trialIDXleft(1)) - centralLickTimesTrial(trialIDXcentral(1));
           alignedLickTimes.firstLateral(5,i) = lateralID;

       elseif ~isempty(rightLicks) && isempty(leftLicks) %If only right licks...
           
           lateralID = alignedLickTimes.RlickID;
           alignedLickTimes.firstLateral(1,i) = i;
           alignedLickTimes.firstLateral(2,i) = rightLicks(1);
           alignedLickTimes.firstLateral(3,i) = rightLickTimes(trialIDXright(1)) - trialStartTimes(i);
           alignedLickTimes.firstLateral(4,i) = rightLickTimesTrial(trialIDXright(1)) - centralLickTimesTrial(trialIDXcentral(1));
           alignedLickTimes.firstLateral(5,i) = lateralID;

       elseif ~isempty(rightLicks) && ~isempty(leftLicks) %If both left and right licks ...

           [firstlatlick,idx] = min([min(leftLicks) min(rightLicks)]);
           lateralID = idx;
           alignedLickTimes.firstLateral(1,i) = i;
           alignedLickTimes.firstLateral(2,i) = firstlatlick;
           alignedLickTimes.firstLateral(3,i) = firstlatlick - trialStartTimes(i);
           alignedLickTimes.firstLateral(4,i) = firstlatlick - centralLickTimesTrial(trialIDXcentral(1));
           alignedLickTimes.firstLateral(5,i) = lateralID;


       else %If no licks...
           alignedLickTimes.firstLateral(1,i) = NaN;
           alignedLickTimes.firstLateral(2,i) = NaN;
           alignedLickTimes.firstLateral(3,i) = NaN;
           alignedLickTimes.firstLateral(4,i) = NaN;
           alignedLickTimes.firstLateral(5,i) = NaN;
       end




   end
   
   
   
end


%%% Assign lick times to output structure %%%

alignedLickTimes.central(1,:) = trialNc;
alignedLickTimes.central(2,:) = centralLickTimes;
alignedLickTimes.central(3,:) = centralLickTimesTrial;
alignedLickTimes.central(4,:) = centralLickTimesCentral;

alignedLickTimes.left(1,:) = trialNl;
alignedLickTimes.left(2,:) = leftLickTimes;
alignedLickTimes.left(3,:) = leftLickTimesTrial;
alignedLickTimes.left(4,:) = leftLickTimesCentral;

alignedLickTimes.right(1,:) = trialNr;
alignedLickTimes.right(2,:) = rightLickTimes;
alignedLickTimes.right(3,:) = rightLickTimesTrial;
alignedLickTimes.right(4,:) = rightLickTimesCentral;

alignedLickTimes.labels = {'trial N';'lick times, recording start';'lick times, trial start';'lick times, first central'};


%%% Plot lick raster %%%
if nargin > 1
   
   subplot(2,1,1); % Trial-aligned lick times
    scatter(alignedLickTimes.central(3,:),alignedLickTimes.central(1,:),10,'filled','k');
    hold on; scatter(alignedLickTimes.left(3,:),alignedLickTimes.left(1,:),10,'filled','r');
    scatter(alignedLickTimes.right(3,:),alignedLickTimes.right(1,:),10,'filled','b');
    ylabel('Trial #','Fontsize',18); xlabel('Time (s)','Fontsize',18); title('Trial start aligned','Fontsize',18)
    set(gca,'XLim',[0 12],'TickDir','out','Fontsize',16)
    
   subplot(2,1,2); % Central-aligned lick times
    scatter(alignedLickTimes.central(4,:),alignedLickTimes.central(1,:),10,'filled','k');
    hold on; scatter(alignedLickTimes.left(4,:),alignedLickTimes.left(1,:),10,'filled','r');
    scatter(alignedLickTimes.right(4,:),alignedLickTimes.right(1,:),10,'filled','b');
    ylabel('Trial #','Fontsize',18); xlabel('Time (s)','Fontsize',18); title('Central lick aligned','Fontsize',18)
    set(gca,'XLim',[0 12],'TickDir','out','Fontsize',16)
    
    
    ppsize = [2000 1400];
    set(gcf,'PaperPositionMode','auto');         
    set(gcf,'PaperOrientation','landscape');
    set(gcf,'PaperUnits','points');
    set(gcf,'PaperSize',ppsize);
    set(gcf,'Position',[0 0 ppsize]);
    
    sgtitle([events.MouseID ' ' events.SessionID ' Lick Times'],'FontSize',20, 'Color', 'red')
end

end