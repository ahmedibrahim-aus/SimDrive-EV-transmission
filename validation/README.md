# Validation workflow

This folder contains simple vehicle-performance checks that are separate from
the gearbox design answer key.

## 0-100 km/h check

Run:

```matlab
cd validation
run_zero_to_100
```

Run it from the repository folder. The car inputs block matches the
representative passenger-EV course baseline used by the load-case generator.
Edit only that block to match an assigned car; the rotational mass allowance,
`(I_motor*G^2 + 4*I_wheel)/R_w^2`, changes with the gear ratio, the motor
inertia and the tire, and `main.mlx` prints it for the car it runs. The script
reports the idealized full-throttle 0-100 km/h time and plots the simulated
speed, motor torque, and motor power.

The check is a longitudinal point-mass model. It uses the same basic force
balance as the teaching model but does not include the motor speed limit (so it
runs past the 224 km/h top speed of the load-case model), tire slip, traction
control, thermal derating, battery voltage sag, or road-load coastdown
calibration. Omitting the speed limit does not change the 0-100 km/h time;
omitting tire slip makes it optimistic (see docs/MathematicalModels.md, Section
10.1).
