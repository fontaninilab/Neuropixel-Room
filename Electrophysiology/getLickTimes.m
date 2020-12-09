function alignedLickTimes = getLickTimes(events,fig)


trialStartTimes = events.trialStartEv./events.fsEv; 
centralLickTimes = events.lickEv.central./events.fsEv;
leftLickTimes = events.lickEv.left./events.fsEv;
rightLickTimes = events.lickEv.right./events.fsEv;

centralLickTimesTrial = centralLickTimes;
leftLickTimesTrial = leftLickTimes;
rightLickTimesTrial = rightLickTimes;

centralLickTimesCentral = NaN(1,length(centralLickTimes));
leftLickTimesCentral = NaN(1,length(leftLickTimes));
rightLickTimesCentral = NaN(1,length(rightLickTimes));


for i = 1:length(trialStartTimes)-1
    
   trialIDXcentral = find(centralLickTimes >= trialStartTimes(i) & centralLickTimes < trialStartTimes(i+1));
   trialNc(trialIDXcentral) = i;
   centralLickTimesTrial(trialIDXcentral) = centralLickTimesTrial(trialIDXcentral) - trialStartTimes(i);% Align to trial start time
   centralLickTimesCentral(trialIDXcentral) = centralLickTimesTrial(trialIDXcentral) - centralLickTimesTrial(trialIDXcentral(1));
   alignedLickTimes.firstCentral(i) = centralLickTimesTrial(trialIDXcentral(1));
    
   trialIDXleft = find(leftLickTimes >= trialStartTimes(i) & leftLickTimes < trialStartTimes(i+1));
   trialNl(trialIDXleft) = i;
   leftLickTimesTrial(trialIDXleft) = leftLickTimesTrial(trialIDXleft) - trialStartTimes(i);% Align to trial start time
   leftLickTimesCentral(trialIDXleft) = leftLickTimesTrial(trialIDXleft) - centralLickTimesTrial(trialIDXcentral(1)); %Align to first central lick per trial
   
   trialIDXright = find(rightLickTimes >= trialStartTimes(i) & rightLickTimes < trialStartTimes(i+1));
   trialNr(trialIDXright) = i;
   rightLickTimesTrial(trialIDXright) = rightLickTimesTrial(trialIDXright) - trialStartTimes(i);% Align to trial start time
   rightLickTimesCentral(trialIDXright) = rightLickTimesTrial(trialIDXright) - centralLickTimesTrial(trialIDXcentral(1)); %Align to first central lick per trial
   
end

trialIDXcentral = find(centralLickTimes >= trialStartTimes(end));
trialNc(trialIDXcentral) = length(trialStartTimes);
centralLickTimesTrial(trialIDXcentral) = centralLickTimesTrial(trialIDXcentral) - trialStartTimes(end);
centralLickTimesCentral(trialIDXcentral) = centralLickTimesCentral(trialIDXcentral) - centralLickTimesTrial(trialIDXcentral(1));

alignedLickTimes.firstCentral(length(trialStartTimes)) = centralLickTimesTrial(trialIDXcentral(1));

trialIDXleft = find(leftLickTimes >= trialStartTimes(end));
trialNl(trialIDXleft) = length(trialStartTimes);
leftLickTimesTrial(trialIDXleft) = leftLickTimesTrial(trialIDXleft) - trialStartTimes(end);
leftLickTimesCentral(trialIDXleft) = leftLickTimesTrial(trialIDXleft) - centralLickTimesTrial(trialIDXcentral(1)); %Align to first central lick per trial

trialIDXright = find(rightLickTimes >= trialStartTimes(end));
trialNr(trialIDXright) = length(trialStartTimes);
leftLickTimesTrial(trialIDXright) = leftLickTimesTrial(trialIDXright) - trialStartTimes(end);
rightLickTimesCentral(trialIDXright) = rightLickTimesTrial(trialIDXright) - centralLickTimesTrial(trialIDXcentral(1));



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

if nargin > 1
   %%% Plot lick raster %%%
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