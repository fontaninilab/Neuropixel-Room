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
for i = 1:length(trialStartTimes)-1
    
   trialIDXcentral = find(centralLickTimes >= trialStartTimes(i) & centralLickTimes < trialStartTimes(i+1));
   trialNc(trialIDXcentral) = i;
   centralLickTimesTrial(trialIDXcentral) = centralLickTimesTrial(trialIDXcentral) - trialStartTimes(i);% Align to trial start time
   centralLickTimesCentral(trialIDXcentral) = centralLickTimesTrial(trialIDXcentral) - centralLickTimesTrial(trialIDXcentral(1));
       
   trialIDXleft = find(leftLickTimes >= trialStartTimes(i) & leftLickTimes < trialStartTimes(i+1));
   trialNl(trialIDXleft) = i;
   leftLickTimesTrial(trialIDXleft) = leftLickTimesTrial(trialIDXleft) - trialStartTimes(i);% Align to trial start time
   leftLickTimesCentral(trialIDXleft) = leftLickTimesTrial(trialIDXleft) - centralLickTimesTrial(trialIDXcentral(1)); %Align to first central lick per trial
   
   trialIDXright = find(rightLickTimes >= trialStartTimes(i) & rightLickTimes < trialStartTimes(i+1));
   trialNr(trialIDXright) = i;
   rightLickTimesTrial(trialIDXright) = rightLickTimesTrial(trialIDXright) - trialStartTimes(i);% Align to trial start time
   rightLickTimesCentral(trialIDXright) = rightLickTimesTrial(trialIDXright) - centralLickTimesTrial(trialIDXcentral(1)); %Align to first central lick per trial
   
   %%% Find first lateral lick per trial %%%
   rightLicks = rightLickTimes(trialIDXright);
   leftLicks = leftLickTimes(trialIDXleft);
   if isempty(rightLicks) && ~isempty(leftLicks) %If only left licks...
       lateralID = alignedLickTimes.LlickID;
       alignedLickTimes.firstLateral(1,i) = leftLicks(1);
       alignedLickTimes.firstLateral(2,i) = leftLickTimes(trialIDXleft(1)) - trialStartTimes(i);
       alignedLickTimes.firstLateral(3,i) = leftLickTimesTrial(trialIDXleft(1)) - centralLickTimesTrial(trialIDXcentral(1));
       alignedLickTimes.firstLateral(4,i) = lateralID;
       
   elseif ~isempty(rightLicks) && isempty(leftLicks) %If only right licks...
       lateralID = alignedLickTimes.RlickID;
       alignedLickTimes.firstLateral(1,i) = rightLicks(1);
       alignedLickTimes.firstLateral(2,i) = rightLickTimes(trialIDXright(1)) - trialStartTimes(i);
       alignedLickTimes.firstLateral(3,i) = rightLickTimesTrial(trialIDXright(1)) - centralLickTimesTrial(trialIDXcentral(1));
       alignedLickTimes.firstLateral(4,i) = lateralID;
       
   elseif ~isempty(rightLicks) && ~isempty(leftLicks) %If both left and right licks ...
       
       [firstlatlick,idx] = min([min(leftLicks) min(rightLicks)]);
       lateralID = idx;
       alignedLickTimes.firstLateral(1,i) = firstlatlick;
       alignedLickTimes.firstLateral(2,i) = firstlatlick - trialStartTimes(i);
       alignedLickTimes.firstLateral(3,i) = firstlatlick - centralLickTimesTrial(trialIDXcentral(1));
       alignedLickTimes.firstLateral(4,i) = lateralID;
       
   
   else %If no licks...
       alignedLickTimes.firstLateral(1,i) = NaN;
       alignedLickTimes.firstLateral(2,i) = NaN;
       alignedLickTimes.firstLateral(3,i) = NaN;
       alignedLickTimes.firstLateral(4,i) = NaN;
   end
        
   
   
   %%% Extract time of first central lick %%%
   alignedLickTimes.firstCentral(1,i) = centralLickTimes(trialIDXcentral(1)); %Raw lick time relative to session start
   alignedLickTimes.firstCentral(2,i) = centralLickTimesTrial(trialIDXcentral(1));
   
   
   
   
end

%%% Repeat above, but for last trial %%%
trialIDXcentral = find(centralLickTimes >= trialStartTimes(end));
trialNc(trialIDXcentral) = length(trialStartTimes);
centralLickTimesTrial(trialIDXcentral) = centralLickTimesTrial(trialIDXcentral) - trialStartTimes(end);
centralLickTimesCentral(trialIDXcentral) = centralLickTimesCentral(trialIDXcentral) - centralLickTimesTrial(trialIDXcentral(1));

alignedLickTimes.firstCentral(1,length(trialStartTimes)) = centralLickTimes(trialIDXcentral(1));
alignedLickTimes.firstCentral(2,length(trialStartTimes)) = centralLickTimesTrial(trialIDXcentral(1));

trialIDXleft = find(leftLickTimes >= trialStartTimes(end));
trialNl(trialIDXleft) = length(trialStartTimes);
leftLickTimesTrial(trialIDXleft) = leftLickTimesTrial(trialIDXleft) - trialStartTimes(end);
leftLickTimesCentral(trialIDXleft) = leftLickTimesTrial(trialIDXleft) - centralLickTimesTrial(trialIDXcentral(1)); %Align to first central lick per trial

trialIDXright = find(rightLickTimes >= trialStartTimes(end));
trialNr(trialIDXright) = length(trialStartTimes);
leftLickTimesTrial(trialIDXright) = leftLickTimesTrial(trialIDXright) - trialStartTimes(end);
rightLickTimesCentral(trialIDXright) = rightLickTimesTrial(trialIDXright) - centralLickTimesTrial(trialIDXcentral(1));


rightLicks = rightLickTimes(trialIDXright);
leftLicks = leftLickTimes(trialIDXleft);
if isempty(rightLicks) && ~isempty(leftLicks) %If only left licks...
   lateralID = alignedLickTimes.LlickID;
   alignedLickTimes.firstLateral(1,end) = leftLicks(1);
   alignedLickTimes.firstLateral(2,end) = leftLickTimes(trialIDXleft(1)) - trialStartTimes(end);
   alignedLickTimes.firstLateral(3,end) = leftLickTimesTrial(trialIDXleft(1)) - centralLickTimesTrial(trialIDXcentral(1));
   alignedLickTimes.firstLateral(4,end) = lateralID;

elseif ~isempty(rightLicks) && isempty(leftLicks) %If only right licks...
   lateralID = alignedLickTimes.RlickID;
   alignedLickTimes.firstLateral(1,end) = rightLicks(1);
   alignedLickTimes.firstLateral(2,end) = rightLickTimes(trialIDXright(1)) - trialStartTimes(end);
   alignedLickTimes.firstLateral(3,end) = rightLickTimesTrial(trialIDXright(1)) - centralLickTimesTrial(trialIDXcentral(1));
   alignedLickTimes.firstLateral(4,end) = lateralID;

elseif ~isempty(rightLicks) && ~isempty(leftLicks) %If both left and right licks ...

   [firstlatlick,idx] = min([min(leftLicks) min(rightLicks)]);
   lateralID = idx;
   alignedLickTimes.firstLateral(1,end) = firstlatlick;
   alignedLickTimes.firstLateral(2,end) = firstlatlick - trialStartTimes(end);
   alignedLickTimes.firstLateral(3,end) = firstlatlick - centralLickTimesTrial(trialIDXcentral(1));
   alignedLickTimes.firstLateral(4,end) = lateralID;


else %If no licks...
   alignedLickTimes.firstLateral(1,end) = NaN;
   alignedLickTimes.firstLateral(2,end) = NaN;
   alignedLickTimes.firstLateral(3,end) = NaN;
   alignedLickTimes.firstLateral(4,end) = NaN;
end



alignedLickTimes.firstCentral(1,end) = centralLickTimes(trialIDXcentral(1)); %Raw lick time relative to session start
alignedLickTimes.firstCentral(2,end) = centralLickTimesTrial(trialIDXcentral(1));




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