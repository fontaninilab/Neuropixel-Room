function alignedLickTimes = getLickTimes(npEvents,behaviorEvents,fig)
% Extracts and aligns lick times to trial start times/first central lick
%
% INPUTS
%  npEvents: struct with event data (from getSpikeEventsKS.m)
%          .MouseID = Mouse ID
%          .SessionID = Session ID
%          .lickEv = struct with lick event indices
%          .trialStartEv = trial start event indices
%          .fsEv = nidaq sampling rate
%
%  behaviorEvents: struct with event data from behavior acquisition computer (from extractTrialData2AFC.m)
%
%  fig: (any value) optional input to produce simple lick raster
%
% OUTPUTS
%  alignedLickTimes: struct with aligned lick times
%                   .firstCentral = 3xN array with, trial #; lick times aligned to session start, trial start
%                   .firstLateral = 5xN array, trial #; lick times aligned to session start, trial start, first central; lick ID
%                   .central = 4xM array, trial #; lick times aligned to session start, trial start, first central
%                   .left = 4xL array, trial #; lick times aligned to session start, trial start, first central
%                   .right = 4xR array, trial #; lick times aligned to session start, trial start, first central
%                   .RlickID = ID # for first right lick (.firstLateral row 5)
%                   .LlickID = ID # for first left lick (.firstLateral row 5)
%                   .labels = 4x1 cell labels for rows of lick times

%Convert timestamps to time (in seconds)
trialStartTimes = npEvents.trialStartEv./npEvents.fsEv; 
centralLickTimes = npEvents.lickEv.central./npEvents.fsEv;
leftLickTimes = npEvents.lickEv.left./npEvents.fsEv;
rightLickTimes = npEvents.lickEv.right./npEvents.fsEv;

centralLickArray = [];
leftLickArray = [];
rightLickArray = [];

% Pre-allocate variables

alignedLickTimes.firstLateral = NaN(5,size(behaviorEvents,2));
alignedLickTimes.firstCentral = NaN(3,size(behaviorEvents,2));

%Lick ID's (consistent with BPOD output)
alignedLickTimes.RlickID = 2;
alignedLickTimes.LlickID = 1;

alignedLickTimes.trialStartTimes = trialStartTimes;

behaviorFieldNames = fieldnames(behaviorEvents);
behaviorCell = table2cell(behaviorEvents);

%%% For each lick align to trial start event and first central lick %%%
for i = 1:size(behaviorEvents,2)
    aCount = 0; bCount = 0; cCount = 0;
    
%%% Central lick times for trial i %%%

    %Extract indices of central licks for trial i
   if i < length(trialStartTimes)        
       trialIDXcentral = find(centralLickTimes >= trialStartTimes(i) & centralLickTimes < trialStartTimes(i+1)); %Find lick times for trial i   
   else    
       trialIDXcentral = find(centralLickTimes >= trialStartTimes(end));
   end
   
   if ~isempty(trialIDXcentral)
       
       centralTrialAligned = centralLickTimes(trialIDXcentral) - trialStartTimes(i); %Align to trial start time
             
       %Remove licks outside of sampling window
       c = find(centralTrialAligned > behaviorEvents(i).sampleCentralev(2) | centralTrialAligned < behaviorEvents(i).sampleCentralev(1));      
       centralTrialAligned(c) = []; trialIDXcentral(c) = [];
       cCount = cCount + length(c);
       
       trialNc = i*ones(1,length(centralTrialAligned)); %Populate vector with trial N's 
       centralCentralAligned = centralTrialAligned - centralTrialAligned(1); %Align to first central lick
       
       %Concatenate trial licks to full lick array
       centralChunk = [trialNc; centralLickTimes(trialIDXcentral); centralTrialAligned; centralCentralAligned];
       centralLickArray = [centralLickArray centralChunk];
       
       % Extract time of first central lick for trial i
       alignedLickTimes.firstCentral(1,i) = i;
       alignedLickTimes.firstCentral(2,i) = centralLickTimes(trialIDXcentral(1));
       alignedLickTimes.firstCentral(3,i) = centralTrialAligned(1); %Raw lick time relative to trial start
        
%%% Left lick times for trial i %%%
       if i < length(trialStartTimes)
           trialIDXleft = find(leftLickTimes >= trialStartTimes(i) & leftLickTimes < trialStartTimes(i+1));%Find lick times for trial i
       else
           trialIDXleft = find(leftLickTimes >= trialStartTimes(end));
       end
       
       leftTrialAligned = leftLickTimes(trialIDXleft) - trialStartTimes(i);       
       
       %Remove licks outside of sampling window
       a = find(leftTrialAligned > behaviorEvents(i).sampleLateralev(2) | leftTrialAligned < behaviorEvents(i).sampleLateralev(1));      
       leftTrialAligned(a) = []; trialIDXleft(a) = [];
       aCount = aCount + length(a);
       
       trialNl = i*ones(1,length(leftTrialAligned)); %Populate vector with trial N's 
       leftCentralAligned = leftTrialAligned - centralTrialAligned(1); %Align to first central lick
       
       %Concatenate trial licks to full lick array
       leftChunk = [trialNl; leftLickTimes(trialIDXleft); leftTrialAligned; leftCentralAligned];
       leftLickArray = [leftLickArray leftChunk];
       

%%% Right lick times for trial i %%%
       if i < length(trialStartTimes)
           trialIDXright = find(rightLickTimes >= trialStartTimes(i) & rightLickTimes < trialStartTimes(i+1));%Find lick times for trial i
       else
           trialIDXright = find(rightLickTimes >= trialStartTimes(end));
       end
       
       rightTrialAligned = rightLickTimes(trialIDXright) - trialStartTimes(i);       
       
       %Remove licks outside of sampling window
       b = find(rightTrialAligned > behaviorEvents(i).sampleLateralev(2) | rightTrialAligned < behaviorEvents(i).sampleLateralev(1));      
       rightTrialAligned(b) = []; trialIDXright(b) = [];
       bCount = bCount + length(b);
       
       trialNr = i*ones(1,length(rightTrialAligned)); %Populate vector with trial N's 
       rightCentralAligned = rightTrialAligned - centralTrialAligned(1); %Align to first central lick
       
       %Concatenate trial licks to full lick array
       rightChunk = [trialNr; rightLickTimes(trialIDXright); rightTrialAligned; rightCentralAligned];
       rightLickArray = [rightLickArray rightChunk];

%%% Find first lateral lick per trial %%%
       rightLicks = rightLickTimes(trialIDXright);
       leftLicks = leftLickTimes(trialIDXleft);
       if isempty(rightLicks) && ~isempty(leftLicks) %If only left licks...
           
           lateralID = alignedLickTimes.LlickID;
           alignedLickTimes.firstLateral(1,i) = i;
           alignedLickTimes.firstLateral(2,i) = leftLicks(1);
           alignedLickTimes.firstLateral(3,i) = leftTrialAligned(1);
           alignedLickTimes.firstLateral(4,i) = leftCentralAligned(1);
           alignedLickTimes.firstLateral(5,i) = lateralID;

       elseif ~isempty(rightLicks) && isempty(leftLicks) %If only right licks...
           
           lateralID = alignedLickTimes.RlickID;
           alignedLickTimes.firstLateral(1,i) = i;
           alignedLickTimes.firstLateral(2,i) = rightLicks(1);
           alignedLickTimes.firstLateral(3,i) = rightTrialAligned(1);
           alignedLickTimes.firstLateral(4,i) = rightCentralAligned(1);
           alignedLickTimes.firstLateral(5,i) = lateralID;

       elseif ~isempty(rightLicks) && ~isempty(leftLicks) %If both left and right licks ...

           [firstlatlick,idx] = min([min(leftLicks) min(rightLicks)]);
           lateralID = idx;
           alignedLickTimes.firstLateral(1,i) = i;
           alignedLickTimes.firstLateral(2,i) = firstlatlick;
           alignedLickTimes.firstLateral(3,i) = firstlatlick - trialStartTimes(i);
           alignedLickTimes.firstLateral(4,i) = firstlatlick - centralTrialAligned(1);
           alignedLickTimes.firstLateral(5,i) = lateralID;


       else %If no licks...(this might be redundant due to pre-allocation)
           alignedLickTimes.firstLateral(1,i) = NaN;
           alignedLickTimes.firstLateral(2,i) = NaN;
           alignedLickTimes.firstLateral(3,i) = NaN;
           alignedLickTimes.firstLateral(4,i) = NaN;
           alignedLickTimes.firstLateral(5,i) = NaN;
       end

   end
     
end


%%% Assign lick times to output structure %%%

alignedLickTimes.central = centralLickArray;
alignedLickTimes.left = leftLickArray;
alignedLickTimes.right = rightLickArray;


alignedLickTimes.labels = {'trial #';'lick times, recording start';'lick times, trial start';'lick times, first central'};

fprintf('Removed %d lateral licks and %d central licks\n',[aCount + bCount,cCount]);


%%% Plot lick raster %%%
if nargin > 2
   
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
    
    sgtitle([npEvents.MouseID ' ' npEvents.SessionID ' Lick Times'],'FontSize',20, 'Color', 'red')
end

end