% The 'plant' consisting of device in/out valves and the lungs.
% Simulates the lungs + device 
% Returns sensor readings
% Valve flow coefficient is assumed to scale linearly by its open ratio.
% Need to add: 
% - input valve 
% - pressure drop in supply tank

classdef PlantModel < handle
   properties
      % Volume
      dV_in = 0             % m3/h
      dV_out = 0            % m3/h
      dV = 0                % m3/h
      V = 0                 % m3
      
      % Pressure
      pRS = 0               % bar 
      
      % Gas mixture
      fio2 = 0.21           % ratio - dimensionless
      
      % Valve settings
      valveInOpenRatio = 0  % ratio - dimensionless
      valveOutOpenRatio = 0 % ratio - dimensionless
      
      % Static
      p0                    % bar 
      pD                    % bar
      pMax                  % bar
      Ers                   % bar/m3
      Rrs                   % bar/m3/h
      rho_d_air             % kg/m3
      rho_d_o2              % kg/m3
      T                     % Kelvin
      kv                    % m3/h
   end
   methods
      % PlantModel
      % p0 in cmH20
      % pD in cmH2O
      % pMax in cmH2O
      % Ers in cmH2O/L
      % Rrs in cmH2O/L/sec 
      % rho_d_air in kg/m3
      % rho_d_o2 in kg/m3
      % T in Kelvin
      % kv flow capacity in metric units - m3/h - that a valve will pass for a pressure drop of 1 bar
      function obj = PlantModel(p0, pD, pMax, Ers, Rrs, rho_d_air, rho_d_o2, T, kv, PEEP)
         if nargin > 0
           % Arguments
           obj.p0 = p0 * 0.000980665;       % cmH2O -> bar
           obj.pD = pD * 0.000980665;       % cmH2O -> bar
           obj.pMax = pMax * 0.000980665;   % cmH2O -> bar
           obj.Ers = Ers * 0.980665;        % cmH2O/L -> bar/m3
           obj.Rrs = Rrs * 0.980665 / 3600; % cmH2O/L/sec -> bar/m3/h
           obj.rho_d_air = rho_d_air;
           obj.rho_d_o2 = rho_d_o2;
           obj.T = T;    
           obj.kv = kv;             
           
           % Initialize state
           obj.pRS = obj.p0 + (PEEP * 0.000980665);          
         end
      end
      
      function tick(obj, dT_s)
        dT = dT_s / 3600; % s --> h
        
        % Compute density of mixed gas
        rho = obj.fio2 * obj.rho_d_o2 + (1-obj.fio2)*obj.rho_d_air;
##        
##        % Compute inlet flow (check condition pd>pu/2!   
##        if obj.pRS > obj.pD / 2 
##          obj.dV_in = (obj.valveInOpenRatio * obj.kv) * 514 / sqrt((obj.T*rho)/(obj.pRS*(obj.pD-obj.pRS)));
##        else
##          obj.dV_in = (obj.valveInOpenRatio * obj.kv) * 257 * obj.pD / sqrt(obj.T*rho);
##        end
##        
        % Compute outlet flow        
        if obj.p0 > obj.pRS / 2 
          obj.dV_out = (obj.valveOutOpenRatio * obj.kv * 10) * 514 / sqrt((obj.T*rho)/(obj.p0*(obj.pRS-obj.p0)));
        else
          obj.dV_out = (obj.valveOutOpenRatio * obj.kv * 10) * 257 * obj.pRS / sqrt(obj.T*rho);
        end
        
        % Compute new pressure
        % - flow is inlet+output flow (however, in practice they should never be open at the same time!
        % obj.dV = obj.dV_in - obj.dV_out;
        obj.dV = obj.dV_in - obj.dV_out;
        obj.V = obj.V + obj.dV * dT;     
     
        % Volume-dependent elastance model   
        ratioE2 = 0.5;
        ratioE1 = 1 - ratioE2;
        
        pResistance = 0;
        if (obj.dV > 0)
          pResistance = obj.Rrs*obj.dV;
        end          
        obj.pRS = pResistance + ratioE1 * obj.Ers * obj.V + ratioE2 * obj.Ers * obj.V^2 + obj.p0;    

        % if over-pressure, release and calculate new volume    
        if obj.pRS > obj.p0 + obj.pMax
          deltaP = obj.pRS - obj.pMax;
          
        % compute volume to be released
          Vloss = deltaP / obj.Ers;
          
        % Update state
          obj.pRS = obj.pMax;
          obj.V -= Vloss;  
        end
      end
      
      function adjustFiO2(obj, val)
        obj.fio2 = val;
      end
      
      function p = pressure(obj)
        p = obj.pRS;
      end
      
      function f = flow(obj)
        f = obj.dV;
      end
      
      function v = volume(obj)
        v = obj.V;
      end
   end
end