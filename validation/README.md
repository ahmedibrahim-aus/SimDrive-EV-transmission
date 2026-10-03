# Validation Workflow

This folder contains lightweight vehicle-performance checks that are separate from
the gearbox design answer key.

## 0-100 km/h Check

Run:

```matlab
cd validation
run_zero_to_100
```

The default parameter block matches the representative passenger-EV course
baseline used by the load-case generator. Edit only that block to match an
assigned car. The script reports the idealized full-throttle
0-100 km/h time and plots the simulated speed, motor torque, and motor power.

This is a simple longitudinal point-mass check. It uses the same basic force
balance as the teaching model but does not include tire slip, traction control,
thermal derating, gear shifts, battery voltage sag, or road-load coastdown
calibration.
