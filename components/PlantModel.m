% The 'plant' consisting of device in/out valves and the lungs.
% Simulates the lungs + device 
% Returns sensor readings
% Valve flow coefficient is assumed to scale linearly by its open ratio.
% Need to add: 
% - input valve 
% - pressure drop in supply tank
% Change:
% - valve equation
% - 
classdef PlantModel < handle
   properties
      % Volume
      dV_in = 0             % m3/s
      dV_out = 0            % m3/s
      dV = 0                % m3/s
      V = 0                 % m3
      
      % Pressure
      pRS = 0               % bar 
      
      % Gas mixture
      fio2 = 0.21           % ratio - dimensionless
      
      % Valve settings
      oD_in = 2             % orifice of input valve diameter in mm
      oD_out = 10           % orifice of ooutput valve diameter in mm
      valveInOpenRatio = 0  % ratio - dimensionless
      valveOutOpenRatio = 0 % ratio - dimensionless
      
      % Static
      p0                    % bar 
      pD                    % bar
      pMax                  % bar
      Ers                   % bar/m3
      ratioE2               % -
      Rrs                   % bar/m3/s
      T                     % Kelvin
      time
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
      % od = orifice diameter in mm
      function obj = PlantModel(p0, pD, pMax, Ers, ratioE2, Rrs, T, oD_in, oD_out, PEEP)
         if nargin > 0
           % Arguments
           obj.p0 = p0 * 98.0665;       % cmH2O -> Pa
           obj.pD = pD * 98.0665;       % cmH2O -> Pa
           obj.pMax = pMax * 98.0665;   % cmH2O -> Pa
           obj.Ers = Ers * 0.980665 * 1e5; % cmH2O/L -> bar/m3 -> Pa/m3
           obj.Rrs = Rrs * 0.980665 * 1e5; % cmH2O/L/sec -> bar/m3/s -> Pa/m3/s
           obj.T = T;    
           obj.oD_in = oD_in;             
           obj.oD_out = oD_out;  
           obj.ratioE2 = ratioE2;          
           obj.time = 0;
           
           % Initialize state
           obj.pRS = obj.p0; %  + (PEEP * 98.0665); % PEEP in cmH2O to Pa          
         end
      end
      
      function tick(obj, dT)       
        % using valve(In/Out)OpenRatio as a ratio in this manner, implies that the 
        % flow rate through the valve depends linearly on the open ratio.
        % For example, look at the Burkert Proportional Solenoid Valve 238934, 2 port , NC, 24 V dc, 1/8in
        % You see that the flow coefficient (kv/kvs ratio) varies linearly with
        % the driving current/voltage.Based on current understanding, this is considered to be valid.
##        
##        % Compute inlet flow (check condition pd>pu/2!   
##        if obj.pRS > obj.pD / 2 
##          obj.dV_in = (obj.valveInOpenRatio * obj.kv) * 514 / sqrt((obj.T*rho)/(obj.pRS*(obj.pD-obj.pRS)));
##        else
##          obj.dV_in = (obj.valveInOpenRatio * obj.kv) * 257 * obj.pD / sqrt(obj.T*rho);
##        end
##        
        % Compute outlet flow  
        obj.dV_out = obj.valveOutOpenRatio * computeValveFlow(obj.T, obj.pRS, obj.p0, obj.oD_out);   
        
        % Compute new pressure
        % - flow is inlet+output flow (however, in practice they should never be open at the same time!
        obj.dV = obj.dV_in - obj.dV_out;
        obj.V = obj.V + obj.dV * dT;    
        if obj.V < 0
          obj.V = 0;
        end        
     
        % Volume-dependent elastance model   
        ratioE1 = 1 - obj.ratioE2;
        
        pResistance = 0;
        if (obj.dV > 0)
          pResistance = obj.Rrs*obj.dV;
        end     
        % todo: adjust this, the dimensions to not pan out     
        obj.pRS = pResistance + ratioE1 * obj.Ers * obj.V + obj.ratioE2 * obj.Ers * obj.V^2 + obj.p0;         
        % fprintf('%.2f, dvIn: %d, dvOut: %d, pRS: %d, p0: %d\n', obj.time, obj.dV_in, obj.dV_out, obj.pRS, obj.p0);  

        % if over-pressure, release and calculate new volume    
        if obj.pRS > obj.p0 + obj.pMax
          deltaP = obj.pRS - obj.pMax;
          
        % compute volume to be released
          Vloss = deltaP / obj.Ers;
          
        % Update state
          obj.pRS = obj.pMax;
          obj.V -= Vloss;  
        end
        obj.time = obj.time + dT;
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