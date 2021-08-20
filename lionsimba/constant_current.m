clear
close all

param{1} = Parameters_init(100);
param{1}.CutoverSOC = 101;
param{1}.CutoffSOC = 0;
param{1}.Tmax = 10000;
param{1}.CutoffVoltage = 0;
param{1}.CutoffSOC = 0;

out = startSimulation(0, 2000, [], -60, param);

time = out.time{1};

subplot(2, 2, 1)
plot(time, out.Voltage{1})
hold on
xlabel('Time [s]')
ylabel('Voltage [V]')
grid on
box on
title('Cell Voltage')

subplot(2, 2, 2)
plot(time, out.curr_density)
hold on
xlabel('Time [s]')
ylabel('Current [A/m^2]')
grid on
box on
title('Cell input current')

subplot(2, 2, 3)
plot(time, out.SOC{1})
hold on
xlabel('Time [s]')
ylabel('SOC')
grid on
box on
title('Cell SOC')

subplot(2, 2, 4)
plot(time, out.Temperature{1});
hold on
xlabel('Time [s]')
ylabel('Temperature (K)')
grid on
box on
title('Cell Temperature')
