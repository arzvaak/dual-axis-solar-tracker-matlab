# How the model works

The sun position, weather, module rating, temperature calculation and electrical losses are the same for all three panels. Orientation and motor consumption are the differences being compared.

## Sun position and weather

`tracker_sun` uses NOAA's fractional-year approximation for declination and the equation of time. The local clock, longitude and UTC offset give the solar hour angle. The result is a unit vector pointing east, north and up, together with compass azimuth and geometric elevation. Atmospheric refraction is not included.

The default coordinates are Roorkee: latitude 29.8543 degrees, longitude 77.8880 degrees and UTC offset +5.5 hours. The offset is fixed; adjust it yourself when daylight saving applies. For a southern-hemisphere comparison, set the fixed azimuth to 0 degrees so the baseline faces north. The interface accepts latitudes between -89 and +89 degrees.

Clear-sky global horizontal irradiance is calculated with the Haurwitz equation. For a positive sun height, `z = sunUp`:

```text
GHI = 1098 z exp(-0.059/z)
DHI = diffuseFraction GHI
DNI = (GHI - DHI) / z
```

At night, all three irradiance terms are zero. Clear sky uses a 15% diffuse fraction. Broken cloud adds two smooth attenuation events, centred at 10:00 and 14:00, and increases the diffuse fraction as transmission falls. Overcast uses 30% transmission and a 95% diffuse fraction. These are synthetic scenarios, not forecasts or site weather records.

Ambient temperature follows a daily sinusoidal cycle with an amplitude of 4 degrees C around the value selected in the dashboard.

## Panel orientation and control

The fixed panel keeps the selected tilt and azimuth. Its default tilt equals the latitude, and its default azimuth is 180 degrees. This is the comparison baseline; it has not been optimised for annual energy.

The single-axis panel rotates about a horizontal north-south axis. Its angle is limited to +/-60 degrees, and its normal is `[sin(theta), 0, cos(theta)]`. The model does not include row shading or backtracking.

The dual-axis panel follows solar azimuth and normal elevation. Tilt is limited to 85 degrees, and azimuth travel is limited to +/-175 degrees around the selected fixed azimuth. Negative azimuth values can appear with a north-facing baseline; they are signed angles about that baseline. Both trackers park horizontally at night.

Commands update every 300 seconds by default. Between commands, each axis moves toward the held target at a maximum rate of 0.2 degrees per second. A 1-degree deadband prevents small corrections. Each sample records the position at the end of its interval. This describes the movement of a position-controlled tracker; it does not simulate the motor's electrical response or the structure's dynamics.

## Irradiance and PV power

For panel normal `n` and sun vector `s`, the plane-of-array irradiance includes direct sunlight, diffuse sky light and ground reflection:

```text
POA = DNI max(0, dot(s,n))
    + DHI (1 + nUp)/2
    + albedo GHI (1 - nUp)/2
```

The diffuse term assumes an isotropic sky. Default albedo is 0.20.

Cell temperature and DC power use a simplified NOCT calculation:

```text
Tcell = Tamb + (NOCT - 20) POA/800
Pdc = Prated POA/1000 max(0, 1 + gamma (Tcell - 25)) (1 - loss)
```

Defaults are NOCT 45 degrees C, a power temperature coefficient of -0.004 per degree C and 10% lumped electrical loss. Each panel has the same 400 W rating.

## Motor consumption and energy

Each moving axis uses 8 W at full slew by default. Average motor power for a sample is based on how long the requested movement would take at that slew rate. Each tracker also uses 0.05 W standby throughout the day. The fixed panel has no actuator consumption.

```text
Pmotor = Pstandby + Paxis sum(abs(axisMovement))/(slewRate dt)
Pnet = Pdc - Pmotor
Enet[kWh] = sum(Pnet) dt/3600000
Gain[%] = 100 (EdualNet/EfixedNet - 1)
```

The timestep is 60 seconds. Samples run from 0 to 86340 seconds, and each represents one complete interval, giving exactly 24 hours of energy and standby consumption. When fixed-panel energy is zero, gain is undefined rather than reported as a percentage.

## What the simulation leaves out

Capturing more sunlight through tracking does not make the solar cell itself more efficient. The energy gain depends on the weather, diffuse fraction, temperature relation and motor consumption assumed here.

Terrain horizons, shading and wind loads are outside this model, as are detailed motor and structural dynamics, diode I-V behaviour, MPPT, inverter clipping and economics. The 3D view illustrates calculated angles rather than a Simscape mechanical model. There is no measured weather input or field validation.

In mostly diffuse light, a horizontal panel can collect more than a panel pointed toward the sun. This controller still follows the sun, so the overcast comparison can favour the fixed panel. A diffuse-aware control strategy would be a separate extension.

## Simulink model

The Simulink model uses a MATLAB Function block for the sampled controller, a Unit Delay for the previous angles and a second MATLAB Function block for irradiance, temperature and PV output. It subtracts motor power before saving the net-power results. `tracker_build_simulink` stores the input timeseries in the model workspace, then saves the `.slx` file.

Both implementations share the solar and weather inputs. Their agreement checks the controller and power equations. It does not independently validate those solar or weather assumptions.
