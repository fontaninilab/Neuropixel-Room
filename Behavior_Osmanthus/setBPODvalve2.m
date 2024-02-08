function setBPODvalve2(valveID,command)
% Function to open or close BPOD valve on valve module 2
% 
% Inputs:
%   valveID: (dbl) single number indicating valveID number
%   command: (str) input is either 'O' to open valve or 'C' to close

sma = NewStateMachine();

sma = AddState(sma, 'Name', 'ValveChange', ...
'Timer', 0,...
'StateChangeConditions', {'Tup', 'Exit'},...
'OutputActions', {'ValveModule2', [command valveID]});

SendStateMachine(sma);
RawEvents = RunStateMachine;