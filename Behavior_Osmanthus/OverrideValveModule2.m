function OverrideValveModule2(valveID, valveDuration)
%for valve module 2
sma = NewStateMachine();
sma = AddState(sma, 'Name', 'ValveOpen', ...
'Timer', valveDuration,...
'StateChangeConditions', {'Tup', 'ValveClose'},...
'OutputActions', {'ValveModule2', ['O' valveID]});

sma = AddState(sma, 'Name', 'ValveClose', ...
'Timer', 0,...
'StateChangeConditions', {'Tup', 'Exit'},...
'OutputActions', {'ValveModule2', ['C' valveID]});
SendStateMachine(sma);
RawEvents = RunStateMachine;