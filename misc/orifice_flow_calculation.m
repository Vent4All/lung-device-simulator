% Main difference between gases and fluids in control vive sizing is compressability
% (eqs from) https://www.tlv.com/global/TI/calculator/air-flow-rate-through-orifice.html?advanced=on
% http://blackmonk.co.uk/2009/11/how-to-size-a-gas-control-valve/

Ta = 293.15; % Air Temperature (K)
p1 = 4*101325 ; % Primary Pressure (Pa abs)
p2 = 1*101325 ; % Secondary Pressure (Pa abs)
Od = 0.5; % Diameter of Orifice (mm)
C = 0.7; % Discharge Coefficient
Fy = 1.0; % Specific heat ratio factor (=Specific heat ratio/1.4) 1.4 = Specific heat ratio for Air & oxygen. So Fy = 1
xT = 0.72; % Pressure differential ratio factor (=0.72)

% Qa	: Air Flow Rate (Normal) (Nm³/min)
% 1/1000 factor to go from kPa to Pa
% additional 1/60 to go from m3/h to m3/s
if (p1-p2)/p1 < Fy*xT
  % Sub-critical flow
  Qa = (1/1000)*(1/60)*(1/60)*4.17*C*((Od/4.654)^2)*p1*(1-((p1-p2)/p1)/(3*Fy*xT))*sqrt(((p1-p2)/p1)/Ta);
  disp('Flow is sub-critical');
else
  % Critical (choked) flow
  Qa = (1/1000)*(1/60)*(1/60)*0.667*4.17*C*((Od/4.654)^2)*p1*sqrt((Fy*xT)/Ta);
  disp('Flow is critical (choked)');
endif

literPerMin = Qa * 1000 * 60