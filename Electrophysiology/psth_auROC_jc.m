function [PSTH_auROC] = psth_auROC_jc(psth, baseline_time, bin, varargin)
%This function computes a normalized psth using the area under the
%operating characteristic curve. This results in a normalized psth with
%possible values ranging from 0 to 1, with .5 being equal to baseline.
%This function does not use the typical pre and post inputs to determine the baseline bins and instead
%uses baseline_time and event_time inputs to determine which bins to use
%for baseline. This is done so that taste events, in which true baseline is
%3s prior to taste, can be input


%The baseline can either be input to the function (for events such as taste
%events in which the baseline is taken from outside the psth window.
if ~isempty(varargin)
    baseline = varargin{1};
else
%This creates a matrix of the baseline activity
baseline = psth(:,1:baseline_time*1000/bin);
end

totalbins = size(psth,2); 

%this finds the maximum value of the full psth to be used 
maxval = max(max(psth));

%This sets the number of increments for the critical value to take for the
%Sliding_Probability
increments = 100;

%This computes the probability vector that the baseline activity is greater
%than the criterion value which ranges from 0 to maxval.
Baseline_Prob = Sliding_Probability(baseline(:), maxval, increments);

Baseline_Prob = fliplr(Baseline_Prob);

%Baseline_Prob(end + 1) = 1;

Baseline_Prob = [0 Baseline_Prob 1];

%This computes the normalized psth for each bin of the psth matrix
for i = 1: totalbins

    %this computes the auROC for the currrent bin
    CurrentBin_Prob = fliplr(Sliding_Probability(psth(:,i)', maxval, increments));
    
    CurrentBin_Prob = [0 CurrentBin_Prob 1]; %#ok<AGROW>
   
    %This uses a trapezoidal approximation to compute the integral. This
    %is the method used by the perfcurve function which computes ROC stats.
    PSTH_auROC(i) = trapz(Baseline_Prob,CurrentBin_Prob); %#ok<AGROW>

    
    
end


end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [Prob_Vector] = Sliding_Probability(vector, maxval, increments)
%This computes a sliding probability of whether the vector values are
%greater than a criterion value which moves from zero to maxval in
%increments of the input variable, increments
%   Detailed explanation goes here

critvalues = 0:maxval/increments:maxval;

if maxval == 0

    Prob_Vector = zeros(1, length(critvalues));
return
end

for i = 1:length(critvalues)
    
Prob_Vector(i) = sum(vector > critvalues(i))/length(vector);

end


end
