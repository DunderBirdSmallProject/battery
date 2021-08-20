clear
close all

param{1} = Parameters_init;
param{1}.Tref = 298.15;
param{1}.CutoffSOC = 20;

I1C = 29.23;
C_rate = 1.5;

initial_state.Y = [];
initial_state.YP = [];

out = startSimulation(0, 10000, initial_state, -25, param);

param{1}.JacobianFunction = out.JacobianFun;
initial_state = out.initialState;
param{1}.CutoffSOC = 2;

out2 = startSimulation(0, 5000, initial_state, 0, param);
initial_state = out2.initialState;
param{1}.CutoverVoltage = 4.05;

out3 = startSimulation(0, 10000, initial_state, C_rate * I1C, param);
initial_state = out3.initialState;

param2 = param;
param2{1}.JacobianFunction = [];
param2{1}.OperatingMode = 3;
param2{1}.CutoverVoltage = 4.3;
param2{1}.V_reference = out3.Voltage{1}(end);

out4 = startSimulation(0, 10000, initial_state, 0, param2);
initial_state = out4.initialState;

time = [out.time{1}; out2.time{1} + out.time{1}(end);
    out3.time{1} + out2.time{1}(end) + out.time{1}(end);
    out4.time{1} + out3.time{1}(end) + out2.time{1}(end) + out.time{1}(end)
    ];

figure(1)
plot(time, [out.Voltage{1};out2.Voltage{1}; out3.Voltage{1}; out4.Voltage{1}]);
hold on
xlabel('Time [s]')
ylabel('Voltage [V]')
grid on
box on
title('Cell Voltage')

figure(2)
plot(time, [out.SOC{1}; out2.SOC{1}; out3.SOC{1}; out4.SOC{1}]);
hold on
xlabel('Time [s]')
ylabel('SOC')
grid on
box on
title('Cell SOC')

figure(3)
plot(time, [out.Temperature{1}; out2.Temperature{1}; out3.Temperature{1}; out4.Temperature{1}]);
hold on
xlabel('Time [s]')
ylabel('Temperature')
grid on
box on
title('Cell Temperature')

figure(4)
plot(time, [out.curr_density; out2.curr_density; out3.curr_density; out4.curr_density]);
hold on
xlabel('Time [s]')
ylabel('Current Density')
grid on
box on
title('Cell Current Density')