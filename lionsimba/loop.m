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

% 恒流情况下的最大电压以及最大时间
cutoverV_cc_charge = 4.2;
maxtime_cc_charge = 10000;

% 恒压情况下最大电压以及最大时间
cutoverV_cv_charge = 5;
maxtime_cv_charge = 10000;

% 恒流情况下每1C对应多少电流，并且以多少倍这个标准的电流进行充电
I1C = 29.23;
C_rate = 1.5;

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
    
    % 恒流充电
    param{1}.CutoverVoltage = cutoverV_cc_charge;
    out_cc_charge = startSimulation(0, maxtime_cc_charge, initialState, C_rate * I1C, param);
    initialState = out_cc_charge.initialState;
    
    % 恒压充电
    param{1}.CutoverSOC = global_cutover_soc;
    param{1}.JacobianFunction = [];
    param2 = param;
    param2{1}.OperatingMode = 3;
    param2{1}.CutoverVoltage = cutoverV_cv_charge;
    param2{1}.V_reference = out_cc_charge.Voltage{1}(end);
    out_cv_charge = startSimulation(0, maxtime_cv_charge, initialState, 0, param2);
    initialState = out_cv_charge.initialState;
    % 调整界限防止一开始就越界
    param{1}.CutoverSOC = global_cutover_soc + 1;
    param{1}.CutoffSOC = global_cutoff_soc;
    param{1}.CutoverVoltage = cutoverV_cv_charge + 1;
    
    % 计算老化损失
    cur_currents = [out_discharge.curr_density
    
    % 记录数据
    times = [times; out_discharge.time{1} + curtime];
    curtime = curtime + out_discharge.time{1}(end);
    times = [times; out_rest.time{1} + curtime];
    curtime = curtime + out_rest.time{1}(end);
    times = [times; out_cc_charge.time{1} + curtime];
    curtime = curtime + out_cc_charge.time{1}(end);
    times = [times; out_cv_charge.time{1} + curtime];
    curtime = curtime + out_cv_charge.time{1}(end);

    currents = [currents; out_discharge.curr_density; out_rest.curr_density;
        out_cc_charge.curr_density; out_cv_charge.curr_density];
    voltages = [voltages; out_discharge.Voltage{1}; out_rest.Voltage{1};
        out_cc_charge.Voltage{1}; out_cv_charge.Voltage{1}];
    temperatures = [temperatures; out_discharge.Temperature{1}; out_rest.Temperature{1};
        out_cc_charge.Temperature{1}; out_cv_charge.Temperature{1}];
    socs = [socs; out_discharge.SOC{1}; out_rest.SOC{1}; out_cc_charge.SOC{1};
        out_cv_charge.SOC{1}];
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
