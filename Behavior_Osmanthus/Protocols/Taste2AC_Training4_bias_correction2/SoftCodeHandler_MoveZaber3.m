function SoftCodeHandler_MoveZaber3(position)
global ZaberMotors;
global currentTrial;
global ZaberTime;
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

%     protocol = Zaber.AsciiProtocol(port);
%     device = Zaber.AsciiDevice.initialize(protocol, 2); % Central Spout
    switch position
        case 1 % going Forward
            distance = 22;
            position = ZaberMotors.device2.Units.positiontonative(distance/1000); % convert mm to m
            ZaberMotors.device2.moveabsolute(position); % Tell the device to move.
            ZaberMotors.device2.waitforidle(); % Wait for the move to finish.
             ZaberTime(currentTrial,1)=toc;
        case 2 % going Backward
            distance = 0;
            position = ZaberMotors.device2.Units.positiontonative(distance/1000); % convert mm to m
            ZaberMotors.device2.moveabsolute(position); % Tell the device to move.
            ZaberMotors.device2.waitforidle(); % Wait for the move to finish.
             ZaberTime(currentTrial,2)=toc;
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
%      protocol = Zaber.AsciiProtocol(port);
%     device = Zaber.AsciiDevice.initialize(protocol, 2); % very slow to execute
    switch position
        case 3 % going up
            distance = 15;
            position = ZaberMotors.device1.Units.positiontonative(distance/1000); % convert mm to m
            ZaberMotors.device1.moveabsolute(position); % Tell the device to move.
            ZaberMotors.device1.waitforidle(); % Wait for the move to finish.
             ZaberTime(currentTrial,3)=toc;
        case 4 % going down
            distance = 0;
            position = ZaberMotors.device1.Units.positiontonative(distance/1000); % convert mm to m
            ZaberMotors.device1.moveabsolute(position); % Tell the device to move.
            ZaberMotors.device1.waitforidle(); % Wait for the move to finish.
            ZaberTime(currentTrial,4)=toc;
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
%     protocol = Zaber.AsciiProtocol(port);
%     device = Zaber.AsciiDevice.initialize(protocol, 2); % very slow to execute
    switch position
        case 5 % going up
            distance = 0;
            position = ZaberMotors.device3.Units.positiontonative(distance/1000); % convert mm to m
            ZaberMotors.device3.moveabsolute(position); % Tell the device to move.
            ZaberMotors.device3.waitforidle(); % Wait for the move to finish.
             ZaberTime(currentTrial,5)=toc;
        case 6 % going down
            distance = 10;
            position = ZaberMotors.device3.Units.positiontonative(distance/1000); % convert mm to m
            ZaberMotors.device3.moveabsolute(position); % Tell the device to move.
            ZaberMotors.device3.waitforidle(); % Wait for the move to finish.
            ZaberTime(currentTrial,6)=toc;
    end
%     fclose(port);
%     
end
% 
% 
% 
