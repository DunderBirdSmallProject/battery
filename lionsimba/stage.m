clear
close all

% 循环次数
loopcnt = 5;
global_cutoff_soc = 0;
global_cutover_soc = 100;
param{1} = Parameters_init(global_cutover_soc);
param{1}.CutoffSOC = global_cutoff_soc;
param{1}.CutoverSOC = global_cutover_soc + 1; % 防止一开始就超过界限了

% 放电电流密度
curr_discharge = -25;
maxtime_discharge = 10000;

% 休息的时间
time_rest = 5000;

% 恒流情况下每1C对应多少电流，并且以多少倍这个标准的电流进行充电
I1C = 29.23;
% 各个阶段对应的电流
C_grad = [1.5, 1.2, 0.9, 0.6, 0.4];
voltage_limit = [3.9, 4.0, 4.1, 4.15, 4.2, 4.25]; %电压限值
grads = length(C_grad);
maxtime_charge = 10000;

% 收集的实验数据
curtime = 0;
times = [];
currents = [];
voltages = [];
temperatures = [];
socs = [];

initialState.Y = [];
initialState.YP = [];

for i=1:1:loopcnt
    % 放电
    out_discharge = startSimulation(0, maxtime_discharge, initialState, curr_discharge, param);
    param{1}.JacobianFunction = out_discharge.JacobianFun;
    initialState = out_discharge.initialState;

    % 休息（冷却？）
    param{1}.CutoffSOC = global_cutoff_soc - 1;
    out_rest = startSimulation(0, time_rest, initialState, 0, param);
    initialState = out_rest.initialState;
    
    param{1}.CutoverSOC = global_cutover_soc;
    out_charge = cell(1, grads);
    % 恒流充电
    for j=1:1:grads
        charge_curr = C_grad(j) * I1C;
        param{1}.CutoverVoltage = voltage_limit(j);
        out_charge{j} = startSimulation(0, maxtime_charge, initialState, charge_curr, param);
        initialState = out_charge{j}.initialState;
        param{1}.JacobianFunction = out_charge{j}.JacobianFun;
    end
    
    
    % 调整界限防止一开始就越界
    param{1}.CutoverSOC = global_cutover_soc + 1;
    param{1}.CutoffSOC = global_cutoff_soc;
    param{1}.CutoverVoltage = voltage_limit(end) + 1;
    
    % 记录数据
    times = [times; out_discharge.time{1} + curtime];
    curtime = curtime + out_discharge.time{1}(end);
    times = [times; out_rest.time{1} + curtime];
    curtime = curtime + out_rest.time{1}(end);

    currents = [currents; out_discharge.curr_density; out_rest.curr_density];
    voltages = [voltages; out_discharge.Voltage{1}; out_rest.Voltage{1}];
    temperatures = [temperatures; out_discharge.Temperature{1}; out_rest.Temperature{1}];
    socs = [socs; out_discharge.SOC{1}; out_rest.SOC{1}];
    
    for j=1:1:grads
        times = [times; out_charge{j}.time{1} + curtime];
        curtime = curtime + out_charge{j}.time{1}(end);
        currents = [currents; out_charge{j}.curr_density];
        voltages = [voltages; out_charge{j}.Voltage{1}];
        temperatures = [temperatures; out_charge{j}.Temperature{1}];
        socs = [socs; out_charge{j}.SOC{1}];
    end
end

figure(1)
plot(times, voltages);
hold on
xlabel('Time [s]')
ylabel('Voltage [V]')
grid on
box on
title('Cell Voltage')

figure(2)
plot(times, socs);
hold on
xlabel('Time [s]')
ylabel('SOC')
grid on
box on
title('Cell SOC')

figure(3)
plot(times, temperatures);
hold on
xlabel('Time [s]')
ylabel('Temperature')
grid on
box on
title('Cell Temperature')

figure(4)
plot(times, currents);
hold on
xlabel('Time [s]')
ylabel('Current Density')
grid on
box on
title('Cell Current Density')
