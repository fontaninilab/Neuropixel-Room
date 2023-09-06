

%%
function behaviorEvents = getLickTimes_ag(npEvents,behaviorEvents,fig)
% Extracts and aligns NP lick times, adds lick times to BPOD behavior
% events struct, and removes licks outside of sampling windows
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
% behaviorEvents: struct with event data from behavior acquisition computer (from extractTrialData2AFC.m) 
%                 with licks outside sampling windows removed
%               .TrialStartNP = Time of trial start relative to start of recording
%               .CentralLicksNP = Central lick times from NP computer extracted and aligned to NP trial start
%               .RightLickTimesNP = Right lick times from NP computer extracted and aligned to NP trial start
%               .LeftLickTimesNP = Left lick times from NP computer extracted and aligned to NP trial start
%
% figure: Lick raster of BPOD alone (trial aligned) and NP lick times overlayed on BPOD lick times


%% Here to edits to BPOD behavior data

nTrials = size(behaviorEvents,2);

aCount = 0; bCount = 0; cCount = 0;

%Central licks
%{
for i = 1:nTrials
     if ~isempty(behaviorEvents(i).CentralLicks(:))
         c = find(behaviorEvents(i).CentralLicks > behaviorEvents(i).sampleCentralev(2) | behaviorEvents(i).CentralLicks < behaviorEvents(i).sampleCentralev(1));       
         behaviorEvents(i).CentralLicks(c) = [];
         cCount = cCount + length(c);
     end 
end
%}

%Left licks
for i = 1:nTrials
     if ~isempty(behaviorEvents(i).LeftLicks(:))
         a = find(behaviorEvents(i).LeftLicks(1:end) > behaviorEvents(i).sampleLateralev(2) | behaviorEvents(i).LeftLicks(1:end) < behaviorEvents(i).sampleLateralev(1));
         behaviorEvents(i).LeftLicks(a) = []; 
         aCount = aCount + length(a);
     end 
end



%Right licks
for i = 1:nTrials
     if ~isempty(behaviorEvents(i).RightLicks(:))
         b = find(behaviorEvents(i).RightLicks(1:end) > behaviorEvents(i).sampleLateralev(2) | behaviorEvents(i).RightLicks(1:end) < behaviorEvents(i).sampleLateralev(1));  
         behaviorEvents(i).RightLicks(b) = [];
         bCount = bCount + length(b);
     end
end

%{
for i = 1:nTrials
   firstLeft = min(behaviorEvents(i).LeftLicks); 
   firstRight = min(behaviorEvents(i).RightLicks);
   
   if isempty(firstLeft) && ~isempty(firstRight)
       behaviorEvents(i).firstLateral = 2;
   elseif isempty(firstRight) && ~isempty(firstLeft)
       behaviorEvents(i).firstLateral = 1;
   elseif ~isempty(firstRight) && ~isempty(firstLeft)
       [~,behaviorEvents(i).firstLateral] = min([firstLeft firstRight]);
   end
end
%}

fprintf('Removed %d lateral licks and %d central licks from BPOD data\n',[aCount + bCount,cCount]);

%% Now do stuff to NP behavior data
%Convert timestamps to time (in seconds)
trialStartTimes = npEvents.trialStartEv./npEvents.fsEv; 
centralLickTimesNP = []%npEvents.lickEv.central./npEvents.fsEv;
leftLickTimesNP = npEvents.lickEv.left./npEvents.fsEv;
rightLickTimesNP = npEvents.lickEv.right./npEvents.fsEv;

for i = 1:nTrials

    aCount = 0; bCount = 0; cCount = 0;
    behaviorEvents(i).TrialStartNP = trialStartTimes(i);


    if i < length(trialStartTimes)
           trialIDXright = find(rightLickTimesNP >= trialStartTimes(i) & rightLickTimesNP < trialStartTimes(i+1));%Find lick times for trial i
       else
           trialIDXright = find(rightLickTimesNP >= trialStartTimes(end));
    end
       
   rightTrialAligned = rightLickTimesNP(trialIDXright) - trialStartTimes(i);       

   b = find(rightTrialAligned > behaviorEvents(i).sampleLateralev(2) | rightTrialAligned < behaviorEvents(i).sampleLateralev(1));      
   rightTrialAligned(b) = []; trialIDXright(b) = [];
   bCount = bCount + length(b);

   behaviorEvents(i).RightLicksNP = rightTrialAligned;       
 
   if i < length(trialStartTimes)
        trialIDXleft = find(leftLickTimesNP >= trialStartTimes(i) & leftLickTimesNP < trialStartTimes(i+1));%Find lick times for trial i
   else
        trialIDXleft = find(leftLickTimesNP >= trialStartTimes(end));
   end
   
   leftTrialAligned = leftLickTimesNP(trialIDXleft) - trialStartTimes(i);       
   
   %Remove licks outside of sampling window
   a = find(leftTrialAligned > behaviorEvents(i).sampleLateralev(2) | leftTrialAligned < behaviorEvents(i).sampleLateralev(1));      
   leftTrialAligned(a) = []; trialIDXleft(a) = [];
   aCount = aCount + length(a);

   LickTimesNP{i,2} = leftTrialAligned;
   behaviorEvents(i).LeftLicksNP = leftTrialAligned;

end


%%% For each lick align to trial start event and first central lick %%%

for i = 1:nTrials
    aCount = 0; bCount = 0; cCount = 0;

    behaviorEvents(i).TrialStartNP = trialStartTimes(i);
    
%%% Central lick times for trial i %%%
%{
    %Extract indices of central licks for trial i
   if i < length(trialStartTimes)        
       trialIDXcentralNP = find(centralLickTimesNP >= trialStartTimes(i) & centralLickTimesNP < trialStartTimes(i+1)); %Find lick times for trial i   
   else    
       trialIDXcentralNP = find(centralLickTimesNP >= trialStartTimes(end));
   end

   if ~isempty(trialIDXcentralNP)
       
       centralTrialAligned = centralLickTimesNP(trialIDXcentralNP) - trialStartTimes(i); %Align to trial start time
             
       %Remove licks outside of sampling window
       c = find(centralTrialAligned > behaviorEvents(i).sampleCentralev(2) | centralTrialAligned < behaviorEvents(i).sampleCentralev(1));      
       centralTrialAligned(c) = []; trialIDXcentralNP(c) = [];
       cCount = cCount + length(c);

       %LickTimesNP{i,1} = centralTrialAligned;
       behaviorEvents(i).CentralLicksNP = centralTrialAligned;
%}
%%% Right lick times for trial i %%%
       if i < length(trialStartTimes)
           trialIDXright = find(rightLickTimesNP >= trialStartTimes(i) & rightLickTimesNP < trialStartTimes(i+1));%Find lick times for trial i
       else
           trialIDXright = find(rightLickTimesNP >= trialStartTimes(end));
       end
       
       rightTrialAligned = rightLickTimesNP(trialIDXright) - trialStartTimes(i);       
       
       %Remove licks outside of sampling window
       b = find(rightTrialAligned > behaviorEvents(i).sampleLateralev(2) | rightTrialAligned < behaviorEvents(i).sampleLateralev(1));      
       rightTrialAligned(b) = []; trialIDXright(b) = [];
       bCount = bCount + length(b);

       behaviorEvents(i).RightLicksNP = rightTrialAligned;       
       
        
%%% Left lick times for trial i %%%
       if i < length(trialStartTimes)
           trialIDXleft = find(leftLickTimesNP >= trialStartTimes(i) & leftLickTimesNP < trialStartTimes(i+1));%Find lick times for trial i
       else
           trialIDXleft = find(leftLickTimesNP >= trialStartTimes(end));
       end
       
       leftTrialAligned = leftLickTimesNP(trialIDXleft) - trialStartTimes(i);       
       
       %Remove licks outside of sampling window
       a = find(leftTrialAligned > behaviorEvents(i).sampleLateralev(2) | leftTrialAligned < behaviorEvents(i).sampleLateralev(1));      
       leftTrialAligned(a) = []; trialIDXleft(a) = [];
       aCount = aCount + length(a);

       LickTimesNP{i,2} = leftTrialAligned;
       behaviorEvents(i).LeftLicksNP = leftTrialAligned;

end


%}
fprintf('Removed %d lateral licks from NP data\n',[aCount + bCount]);

%%

for i = 1:nTrials
    if ~isempty(behaviorEvents(i).RightLicksNP)
       behaviorEvents(i).FirstLickNP(2) = behaviorEvents(i).RightLicks(1);
       behaviorEvents(i).FirstLickNP(1) = 2;
    elseif ~isempty(behaviorEvents(i).LeftLicks)
       behaviorEvents(i).FirstLickNP(2) = behaviorEvents(i).LeftLicks(1);
       behaviorEvents(i).FirstLickNP(1) = 1;
    end

end


%%  Plot lick raster  %%
if nargin > 2
fprintf('Generating lick rasters...');
   
   subplot(1,2,1)
   tic
   for i = 1:nTrials

       %scatter(behaviorEvents(i).CentralLicks,repmat(i,1,length(behaviorEvents(i).CentralLicks)),10,'filled','k')
       hold on; scatter(behaviorEvents(i).LeftLicks,repmat(i,1,length(behaviorEvents(i).LeftLicks)),10,'filled','r')
       hold on; scatter(behaviorEvents(i).RightLicks,repmat(i,1,length(behaviorEvents(i).RightLicks)),10,'filled','b')
       

   end
   ylabel('Trial #','Fontsize',18); xlabel('Time (s)','Fontsize',18); title('Trial start aligned (BPOD)','Fontsize',18)
   set(gca,'XLim',[0 12],'TickDir','out','Fontsize',16)
   elapsed_time = toc;
   fprintf('%f seconds...',elapsed_time);
   
   % Overlap NP lick times with BPOD lick times to check alignment
   subplot(1,2,2)
   tic
   for i = 1:nTrials

       %scatter(behaviorEvents(i).CentralLicks,repmat(i,1,length(behaviorEvents(i).CentralLicks)),10,'filled','k')
       hold on; scatter(behaviorEvents(i).LeftLicks,repmat(i,1,length(behaviorEvents(i).LeftLicks)),10,'filled','r')
       hold on; scatter(behaviorEvents(i).RightLicks,repmat(i,1,length(behaviorEvents(i).RightLicks)),10,'filled','b')
       %hold on; scatter(behaviorEvents(i).CentralLicksNP,repmat(i,1,length(behaviorEvents(i).CentralLicksNP)),10,'filled','MarkerFaceColor',[0.5 0.5 0.5])
       hold on; scatter(behaviorEvents(i).LeftLicksNP,repmat(i,1,length(behaviorEvents(i).LeftLicksNP)),10,'filled','m')
       hold on; scatter(behaviorEvents(i).RightLicksNP,repmat(i,1,length(behaviorEvents(i).RightLicksNP)),10,'filled','c')
       

   end
   xlabel('Time (s)','Fontsize',18); title('NP + BPOD overlap','Fontsize',18)
   set(gca,'XLim',[0 12],'TickDir','out','Fontsize',16)
   elapsed_time = toc;
   fprintf('%f seconds\n',elapsed_time);
    
    ppsize = [2000 1400];
    set(gcf,'PaperPositionMode','auto');         
    set(gcf,'PaperOrientation','landscape');
    set(gcf,'PaperUnits','points');
    set(gcf,'PaperSize',ppsize);
    set(gcf,'Position',[0 0 ppsize]);
    
    sgtitle([npEvents.MouseID ' ' npEvents.SessionID ' Lick Times'],'FontSize',20, 'Color', 'red')
end



end




