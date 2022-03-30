function EventPulseNP(dur)

dur = 0.1;
sma = NewStateMachine();
sma = AddState(sma, 'Name', 'ValveOpen', ...
'Timer', dur,...
'StateChangeConditions', {'Tup', '>exit'},...
'OutputActions', {'BNCState',1});

SendStateMachine(sma);
RawEvents = RunStateMachine;