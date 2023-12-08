function t_ZaberMotor_test3 (motor_num,distance)
    global devices
%uses new Zaber Motion Library instead of Zaber Device Control Tollbox
%(deprecated)
import zaber.motion.ascii.*;
import zaber.motion.*;
% tic
% % port=serialport("COM9",115200,"DataBits",8,FlowControl="none",Parity="none",StopBits=1,Timeout=0.5);
% % configureTerminator(port,"CR/LF");
% conn = Connection.openSerialPort('COM9');
% devices = conn.detectDevices();
tic
device = devices(motor_num);
axis = device.getAxis(1);
axis.moveAbsolute(distance/10, Units.LENGTH_CENTIMETRES);
axis.stop();
% position = axis.getPosition(Units.LENGTH_MILLIMETRES);
% fprintf('Position: %d\n', position);
try
    conn.close();
catch
end
toc
end
