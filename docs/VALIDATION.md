# Validation notes

Local checks of the numerical model and dashboard passed in MATLAB R2026b on 13 October 2026, after the code formatting changes. MATLAB Online and Simulink were checked on 12 October 2026. These checks cover the software and the stated equations; they do not establish field accuracy or a measured energy-yield improvement.

## Numerical checks

`tests/validate_tracker.m` contains 17 assertions. They check finite, nonnegative PV output, unit-length sun vectors, zero PV power at night, the relation between GHI, DHI and DNI, panel travel and slew limits, motor consumption and standby energy. The remaining cases cover equinox and solstice geometry, polar night, a southern-hemisphere site, rejection of a zero slew rate, timestep convergence, zero actuator consumption and the overcast scenario.

Reducing the timestep from 60 seconds to 30 seconds changes the default daily energies by at most 0.00807%. The test accepts a difference below 1.5%.

## MATLAB and Simulink comparison

`verify_simulink` compares every sample of panel angle, actuator power and net power. The default run has 1440 samples.

| Quantity | Largest difference |
| --- | ---: |
| Panel angle | 0 degrees |
| Motor power | 0 W |
| Net power | 2.8422e-13 W |

Overcast and southern-hemisphere cases also matched at 1440 samples, with zero angle and motor differences and net-power differences below 6e-14 W. The saved values are in `results/simulink_verification.json`.

## Dashboard checks

The dashboard was checked at times throughout the simulated day and night. Horizontal night parking, time scrubbing, Play/Pause and the changing morning/afternoon frames worked. An overcast rerun produced 0.611 kWh dual-axis net energy and approximately -5.4% gain. Returning to clear sky restored the default comparison. CSV, scene-image and dashboard-image exports succeeded, and the Simulink model opened.

MATLAB Online initially showed blank plots and reported scene-tree errors with browser-side axes rendering. The app now displays images rendered by MATLAB and was checked through the normal MATLAB Online page. The camera is fixed; rendering time affects playback speed.

## Repeating the checks

Open the project folder and run:

```matlab
addpath tests
validate_tracker
run_study
verify_simulink
```

The first two commands need base MATLAB; `verify_simulink` needs Simulink. The study writes twelve example days to `results/seasonal_comparison.csv`. Those cases should not be treated as a full-year energy estimate.
