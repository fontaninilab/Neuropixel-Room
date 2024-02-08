function SoftCodeHandler_MoveZaber2(position)
global port
% tic
% device.home();
% device.waitforidle();
% toc
if position == 1 || position == 2
     tic
%     port = serial('COM8'); % set the port
%     set(port, ...
%         'BaudRate', 115200, ...
%         'DataBits', 8, ...
%         'FlowControl', 'none', ...
%         'Parity', 'none', ...
%         'StopBits', 1, ...
%         'Terminator','CR/LF','DataTerminalReady','on');
%     set(port, 'Timeout', 0.5)
%     warning('off','instrument:serial:ClassToBeRemoved')
%     fopen(port);

    protocol = Zaber.AsciiProtocol(port);
    device = Zaber.AsciiDevice.initialize(protocol, 2); % Central Spout
    switch position
        case 1 % going Forward
            distance =22;
            position = device.Units.positiontonative(distance/1000); % convert mm to m
            device.moveabsolute(position); % Tell the device to move.
            device.waitforidle(); % Wait for the move to finish.
             toc
        case 2 % going Backward
            distance = 0;
            position = device.Units.positiontonative(distance/1000); % convert mm to m
            device.moveabsolute(position); % Tell the device to move.
            device.waitforidle(); % Wait for the move to finish.
             toc
    end
%     fclose(port);
elseif position == 3 || position == 4
     tic
%     port = serial('COM8'); % set the port
%     set(port, ...
%         'BaudRate', 115200, ...
%         'DataBits', 8, ...
%         'FlowControl', 'none', ...
%         'Parity', 'none', ...
%         'StopBits', 1, ...
%         'Terminator','CR/LF');
%     set(port, 'Timeout', 0.5)
%    warning('off','instrument:serial:ClassToBeRemoved')
%    fopen(port);
     protocol = Zaber.AsciiProtocol(port);
    device = Zaber.AsciiDevice.initialize(protocol, 1); % very slow to execute
    switch position
        case 3 % going up
            distance = 15;
            position = device.Units.positiontonative(distance/1000); % convert mm to m
            device.moveabsolute(position); % Tell the device to move.
            device.waitforidle(); % Wait for the move to finish.
             toc
        case 4 % going down
            distance = 0;
            position = device.Units.positiontonative(distance/1000); % convert mm to m
            device.moveabsolute(position); % Tell the device to move.
            device.waitforidle(); % Wait for the move to finish.
            toc
    end
%     fclose(port);
% %     
elseif position == 5 || position == 6
     tic
%     port = serial('COM8'); % set the port
%     set(port, ...
%         'BaudRate', 115200, ...
%         'DataBits', 8, ...
%         'FlowControl', 'none', ...
%         'Parity', 'none', ...
%         'StopBits', 1, ...
%         'Terminator','CR/LF');
%     set(port, 'Timeout', 0.5)
%       warning('off','instrument:serial:ClassToBeRemoved')
%     fopen(port);
    protocol = Zaber.AsciiProtocol(port);
    device = Zaber.AsciiDevice.initialize(protocol, 3); % very slow to execute
    switch position
        case 5 % going up
            distance = 0;
            position = device.Units.positiontonative(distance/1000); % convert mm to m
            device.moveabsolute(position); % Tell the device to move.
            device.waitforidle(); % Wait for the move to finish.
             toc
        case 6 % going down
            distance = 10;
            position = device.Units.positiontonative(distance/1000); % convert mm to m
            device.moveabsolute(position); % Tell the device to move.
            device.waitforidle(); % Wait for the move to finish.
            toc
    end
%     fclose(port);
%     
end
% 
% 
% 
