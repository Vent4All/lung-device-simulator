# Vent4All Lung & device simulation model.
**Unvalidated model, work in progress!**  
Lung and device simulation model to validate control implementation.

For controller validation, a patient-lung simulation will be embedded. A volume-dependent elastance model is implemented [1].  
![Volume Dependant Elastance Lung Model](https://github.com/Vent4All/lung-device-simulator/raw/master/images/volume-dependent-elastance-model-eq.png)

Paw is the airway pressure. V is the volume (0 at beginning of inspiration). Rrs is the airway resistance. E1 and E2 are fractions of the respiratory system elastance (Ers). P0 is the end-expiratory pressure (equal to ambient pressure).

**Valve model**  
To implement valve behaviour, the following model is used: [2]    
![Valve model Model](https://github.com/Vent4All/lung-device-simulator/raw/master/images/valve_model.png)

## Simulation #1
Initial results (TV: 0.4L, I:E = 2, Ers = 50cmH2O/L, Rrs = 10cmH2O/L/s, %E2 = 0.5, PEEP = 5)  
![Sim1](https://github.com/Vent4All/lung-device-simulator/raw/master/plots/sim1.png)

Shown are 4 cycles:  
1. Startup cycle
2. Cycle with breath hold (BH) of 0.5 seconds at t=10s
3. Normal cycle
4. Normal cycle

## References
[1] Carvalho, A. R., & Zin, W. A. (2011). Respiratory system dynamical mechanical properties: modeling in time and frequency domain. Biophysical reviews, 3(2), 71.  
[2] [RS online - Burkert 2/2-Way Solenoid Control Valve](https://docs.rs-online.com/5d73/0900766b81552f56.pdf)