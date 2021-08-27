function manual_habituation

%%% Figure properties %%%
fig = uifigure;
fig.Name = 'Manual Habituation';
fig.Position = [100 100 800 800]; %Size and position of figure gui

fsize = 18; %Font size to be used for all buttons
buttonheight = 30; %Button height
vertgap = 45; %Vertical spacing between buttons (gap between top of button below and bottom of button above)
vertpos = 75; %Vertical position of bottom buttons
buttonwidth = 200; %Button width
horzpos = 75; %Horizontal position of left-most buttons
horzgap = 25; %Size of space between buttons horizontally

%%% Add text to GUI %%%

txt1 = uilabel(fig); 
txt1.Text = 'Release tastant drop';
txt1.FontSize = fsize+2;
txt1.FontWeight = 'bold';
txt1.Position = [horzpos, vertpos+8*vertgap+8*buttonheight, buttonwidth, buttonheight];

txt2 = uilabel(fig); 
txt2.Text = 'Motor controls';
txt2.FontSize = fsize+2;
txt2.FontWeight = 'bold';
txt2.Position = [horzpos+1.75*horzgap+1.75*buttonwidth, vertpos+8*vertgap+8*buttonheight, buttonwidth, buttonheight];


%%% Buttons - motors %%%
btn1=uibutton(fig,'push','Position',[horzpos+horzgap+buttonwidth, vertpos+7*vertgap + 7*buttonheight, buttonwidth, buttonheight],'ButtonPushedFcn',@(btn1,event) central_forward(btn1));
btn1.Text='Central Forward';
btn1.FontSize = fsize;
btn1.FontWeight = 'bold';

btn3=uibutton(fig,'push','Position',[horzpos+horzgap+buttonwidth, vertpos+6*vertgap + 6*buttonheight, buttonwidth, buttonheight],'ButtonPushedFcn',@(btn3,event) lateral_forward(btn3));
btn3.Text='Lateral Up';
btn3.FontSize = fsize;
btn3.FontWeight = 'bold';

btn5=uibutton(fig,'push','Position',[horzpos+horzgap+buttonwidth, vertpos+5*vertgap + 5*buttonheight, buttonwidth, buttonheight],'ButtonPushedFcn',@(btn5,event) Aspiration_up(btn5));
btn5.Text='Aspiration Up';
btn5.FontSize = fsize;
btn5.FontWeight = 'bold';

btn2=uibutton(fig,'push','Position',[horzpos+2*horzgap+2*buttonwidth, vertpos+7*vertgap + 7*buttonheight, buttonwidth, buttonheight],'ButtonPushedFcn',@(btn2,event) central_back(btn2));
btn2.Text='Central Back';
btn2.FontSize = fsize;
btn2.FontWeight = 'bold';



btn4=uibutton(fig,'push','Position',[horzpos+2*horzgap+2*buttonwidth, vertpos+6*vertgap + 6*buttonheight, buttonwidth, buttonheight],'ButtonPushedFcn',@(btn4,event)lateral_back(btn4));
btn4.Text='Lateral Down';
btn4.FontSize = fsize;
btn4.FontWeight = 'bold';



btn6=uibutton(fig,'push','Position',[horzpos+2*horzgap+2*buttonwidth ,vertpos+5*vertgap + 5*buttonheight, buttonwidth ,buttonheight],'ButtonPushedFcn',@(btn6,event)Aspiration_down(btn6));
btn6.Text='Aspiration Down';
btn6.FontSize = fsize;
btn6.FontWeight = 'bold';

%%% Buttons - Central valves %%%

btn7=uibutton(fig,'push','Position',[horzpos ,vertpos+7*vertgap + 7*buttonheight, buttonwidth ,buttonheight],'ButtonPushedFcn',@(btn7,event)CentralDrop(btn7,1));
btn7.Text='Valve 1 - Drop';
btn7.FontSize = fsize;
btn7.FontWeight = 'bold';
btn7.BackgroundColor = [0.3010 0.7450 0.9330];

btn8=uibutton(fig,'push','Position',[horzpos ,vertpos+6*vertgap + 6*buttonheight, buttonwidth ,buttonheight],'ButtonPushedFcn',@(btn8,event)CentralDrop(btn8,2));
btn8.Text='Valve 2 - Drop';
btn8.FontSize = fsize;
btn8.FontWeight = 'bold';
btn8.BackgroundColor = [0.3010 0.7450 0.9330];

btn9=uibutton(fig,'push','Position',[horzpos ,vertpos+5*vertgap + 5*buttonheight, buttonwidth ,buttonheight],'ButtonPushedFcn',@(btn9,event)CentralDrop(btn9,3));
btn9.Text='Valve 3 - Drop';
btn9.FontSize = fsize;
btn9.FontWeight = 'bold';
btn9.BackgroundColor = [0.3010 0.7450 0.9330];

btn10=uibutton(fig,'push','Position',[horzpos ,vertpos+4*vertgap + 4*buttonheight, buttonwidth ,buttonheight],'ButtonPushedFcn',@(btn10,event)CentralDrop(btn10,4));
btn10.Text='Valve 4 - Drop';
btn10.FontSize = fsize;
btn10.FontWeight = 'bold';
btn10.BackgroundColor = [0.3010 0.7450 0.9330];

btn11=uibutton(fig,'push','Position',[horzpos ,vertpos+3*vertgap + 3*buttonheight, buttonwidth ,buttonheight],'ButtonPushedFcn',@(btn11,event)CentralDrop(btn11,5));
btn11.Text='Valve 5 - Drop';
btn11.FontSize = fsize;
btn11.FontWeight = 'bold';
btn11.BackgroundColor = [0.3010 0.7450 0.9330];

btn12=uibutton(fig,'push','Position',[horzpos ,vertpos+2*vertgap + 2*buttonheight, buttonwidth ,buttonheight],'ButtonPushedFcn',@(btn12,event)CentralDrop(btn12,6));
btn12.Text='Valve 6 - Drop';
btn12.FontSize = fsize;
btn12.FontWeight = 'bold';
btn12.BackgroundColor = [0.3010 0.7450 0.9330];

btn13=uibutton(fig,'push','Position',[horzpos, vertpos+vertgap + buttonheight, buttonwidth ,buttonheight],'ButtonPushedFcn',@(btn13,event)CentralDrop(btn13,7));
btn13.Text='Valve 7 - Drop';
btn13.FontSize = fsize;
btn13.FontWeight = 'bold';
btn13.BackgroundColor = [0.3010 0.7450 0.9330];

btn14=uibutton(fig,'push','Position',[horzpos, vertpos, buttonwidth, buttonheight],'ButtonPushedFcn',@(btn14,event)CentralDrop(btn14,8));
btn14.Text='Valve 8 - Drop';
btn14.FontSize = fsize;
btn14.FontWeight = 'bold';
btn14.BackgroundColor = [0.3010 0.7450 0.9330];

end


function central_forward(btn1)
t_ZaberMotor_test(2,24);
end
function central_back(btn2)
t_ZaberMotor_test(2,0);
end
function lateral_forward(btn3)
t_ZaberMotor_test(1,0);
end
function lateral_back(btn4)
t_ZaberMotor_test(1,20);
end
function Aspiration_up(btn5)
t_ZaberMotor_test(3,0);
end
function Aspiration_down(btn6)
t_ZaberMotor_test(3,10);
end
function CentralDrop(btnIDX,valveID)
valveDuration = 0.25; %Duration valve is open in seconds
OverrideValveModule(valveID,valveDuration);
end


