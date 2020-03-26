% Lung Ventilator simulation model
% Wilbert van de Ridder - 24-03-2020
%
% Sources:
% - [1] Lung model: https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5418399/pdf/12551_2011_Article_48.pdf
% - [2] Valve equation: https://www.engineeringtoolbox.com/kv-coefficients-d_1931.html
% - [3] Gas densities: https://www.engineeringtoolbox.com/gas-density-d_158.html
% - [4] Mechanics of ventilation: http://www.ubccriticalcaremedicine.ca/rotating/material/Lecture_1%20for%20Residents.pdf
% - [5] Example valve: https://docs.rs-online.com/5d73/0900766b81552f56.pdf
% - [6] Lung volumes: https://www.physio-pedia.com/Lung_volumes

clc;
clearvars;
clear all;

%%%%%%%%%%%%%%%%
%% Parameters %%
%%%%%%%%%%%%%%%%
% Valve
kv = 0.3; % Flow coefficient in m3/h [5]

% Respiratory system
Rrs = 4; % Airway resistance in cmH20/L/sec [4, p8]
Ers = 50; % Respiratory system elastance (inverse of lung compliance) in cmH20/L. [4, p7]
pMax = 1060; % maximum pressure in cmH20

% Environment
p0 = 1033; % Ambient perssure in cmH20
rho_d_air = 1.205; % density of air (gas) in kg/m3 at 273.15 Kelvin and 1013mbar / 1 atm [3]
rho_d_o2 = 1.331; % density of oxygen (gas) in kg/m3 at 273.15 Kelvin and 1013mbar / 1 atm [3]
T = 293.15; % Upstream temperature in Kelvin (20 degrees Celsius)

% Device settings
bpm = 10; % Breaths per minute
fio2 = 0.3; % FiO2  Natural air includes 21% oxygen, which is equivalent to FiO2 of 0.21. Oxygen-enriched air has a higher FiO2 than 0.21; up to 1.00 which means 100% oxygen.
fmax = 10; % Ma.ximum flow in L/s
TV = 0.4; % Tidal Volume in L
PEEP = 5; % Positive end-expiratory pressure (PEEP) in cmH20
ieRatio = 2; % Inspiratory:Expiratory ratio. 1:x.
pD = 4000; % Device tank pressure in cmH2O

%%%%%%%%%%%%%%%%
%% Simulation %%
%%%%%%%%%%%%%%%%

% Initialize actors
plantModel = PlantModel(p0, pD, pMax, Ers, Rrs, rho_d_air, rho_d_o2, T, kv, PEEP);
plantModel.adjustFiO2(fio2);
plantModel.valveInOpenRatio = 0.1;

% runtime variables
dT = 0.01;
tEnd = 24.0;

## I:E = 2, bpm = 10
## I tijd = 60/10 * 2/3
## flow = TV / Itijd
Itime = (60/bpm) * (1 / (ieRatio + 1));
dV_in_L = TV / Itime;
dV_in = dV_in_L * 3.6; % L/s -> m3/h
plantModel.dV_in = dV_in;
plantModel.dV = dV_in;

% Simulation results
pressure = zeros(1, tEnd/dT + 1);
flow = zeros(1, tEnd/dT + 1);
volume = zeros(1, tEnd/dT + 1);
time = 0 : dT : tEnd;

% Initial values
pressure(1,1) = plantModel.p0;
flow(1,1) = plantModel.dV_in;

i = 2;
while i <= (tEnd / dT) + 1    
  % Tick plant simulation
  plantModel.tick(dT); 
  
  % Save values
  pressure(1,i) = plantModel.pRS; 
  flow(1,i) = plantModel.dV; 
  volume(1,i) = plantModel.V; 
  
  % Cycle 1
  if i == round(Itime * (1/dT))
    plantModel.dV_in = 0;
    plantModel.valveOutOpenRatio = 0.1;
  end
  
  if i == round(3.15 * (1/dT))
    plantModel.valveOutOpenRatio = 0.0;
  end
  
  % Cycle 2 (with breath hold)
  if i == round((60/bpm)* (1/dT))
    plantModel.dV_in = dV_in;
  end
  
  if i == round(((60/bpm) + Itime) * (1/dT))
    plantModel.dV_in = 0;
  end
  
  if i == round(((60/bpm) + Itime + 0.5) * (1/dT))
    plantModel.valveOutOpenRatio = 0.1;
  end
  
  if i == round(10.15 * (1/dT))
    plantModel.valveOutOpenRatio = 0.0;    
  end
  
  % Cycle 3
  if i == round(2*(60/bpm)* (1/dT))
    plantModel.dV_in = dV_in;
  end
  
  if i == round((2*(60/bpm) + Itime) * (1/dT))
    plantModel.dV_in = 0;
    plantModel.valveOutOpenRatio = 0.1;
  end
  
  if i == round(15.6 * (1/dT))
    plantModel.valveOutOpenRatio = 0.0;
  end
  
   % Cycle 4
  if i == round(3*(60/bpm)* (1/dT))
    plantModel.dV_in = dV_in;
  end
  
  if i == round((3*(60/bpm) + Itime) * (1/dT))
    plantModel.dV_in = 0;
    plantModel.valveOutOpenRatio = 0.1;
  end
  
  if i == round(21.6 * (1/dT))
    plantModel.valveOutOpenRatio = 0.0;
  end
 
  i++;
endwhile

% Plot graphs
figure(1);
subplot(3,1,1);
plot(time, pressure * 1019.72, 'DisplayName','P_{aw}');
hold on;
plot([0,time(1,end)],[p0 + PEEP,p0 + PEEP], 'k--', 'DisplayName','PEEP')
hold off;
xlabel('t (s)') 
ylabel('cmH2O') 
xlim([0, tEnd])
legend

subplot(3,1,2); 
plot(time, flow * 1000 / 3600, 'DisplayName',"V'(t)");
xlabel('t (s)') 
ylabel('L/s') 
xlim([0, tEnd])
legend

subplot(3,1,3); 
plot(time, volume * 1000, 'DisplayName',"V(t)");
xlabel('t (s)') 
ylabel('L') 
xlim([0, tEnd])
legend

disp('Done!');
