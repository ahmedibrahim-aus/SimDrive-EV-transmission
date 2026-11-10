# Validation workflow

This folder contains a vehicle-performance check that is independent of the
gearbox design.

## 0-100 km/h check

Run:

```matlab
cd validation
run_zero_to_100
```

The script is run from the repository folder. The vehicle inputs block matches
the representative passenger-EV course baseline used by the load-case generator.
Only that block should be edited to match an assigned vehicle. The rotational
mass allowance, `(I_motor*G^2 + 4*I_wheel)/R_w^2`, changes with the gear ratio,
the motor inertia and the tire, and `main.mlx` prints it for the vehicle that it
simulates. The script reports the idealized full-throttle 0-100 km/h time and
plots the simulated speed, motor torque, and motor power.

The check is a longitudinal point-mass model. It uses the same force balance as
the load-case model but does not include the motor speed limit (so it continues
beyond the 224 km/h top speed of the load-case model), tire slip, traction
control, the actuator lag (0.05 s) and the 5000 N·m/s torque rate limit
(together they remove less than 0.1 s of full torque), thermal derating, battery
voltage sag, or road-load coastdown calibration. The omission of the speed limit
does not change the 0-100 km/h time, whereas the omission of tire slip makes it
optimistic (see docs/MathematicalModels.md, Section 10.1).
