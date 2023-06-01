function t_ZaberMotor_test2 (motor_num,distance)
%changed into using serialport instead of serial to find the motor device.
%no need to use fopen and fclose
%  warning('off','instrument:serial:ClassToBeRemoved');
% port = serial('COM8'); % set the port
tic
% set(port, ...
%     'BaudRate', 115200, ...
%     'DataBits', 8, ...
%     'FlowControl', 'none', ...
%     'Parity', 'none', ...
%     'StopBits', 1, ...
%     'Terminator','CR/LF');
port=serialport("COM8",115200,"DataBits",8,FlowControl="none",Parity="none",StopBits=1,Timeout=0.5);
configureTerminator(port,"CR/LF");
% warning off MATLAB:serial:fgetl:unsuccessfulRead %To suppress warning
% message
% fopen(port);

protocol = Zaber.AsciiProtocol(port);
device = Zaber.AsciiDevice.initialize(protocol,motor_num); % very slow to execute


% tic
% % device.home();
% % device.waitforidle();
% toc

% distance = 14; % unit in mm; 25 mm is the max distance from Home
position = device.Units.positiontonative(distance/1000); % convert mm to m


device.moveabsolute(position); % Tell the device to move.
device.waitforidle(); % Wait for the move to finish.
toc

% distance = 5; % unit in mm; 25 mm is the max distance from Home
% position = device.Units.positiontonative(distance/1000); % convert mm to m
% device.moveabsolute(position); % Tell the device to move.

% fclose(port);
port=[];
end
