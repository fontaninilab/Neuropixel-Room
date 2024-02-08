function OverrideStateMachine(portID, valveDuration)

sma = NewStateMachine();
sma = AddState(sma, 'Name', 'ValveOpen', ...
'Timer', valveDuration,...
'StateChangeConditions', {'Tup', '>exit'},...
'OutputActions', {'ValveState', portID});

SendStateMachine(sma);
RawEvents = RunStateMachine;