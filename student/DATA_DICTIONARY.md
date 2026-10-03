# Student Data Dictionary

Everything the simulation hands you, what it means, and where it belongs.
Chapter references are to *Shigley's Mechanical Engineering Design*, 11th ed.

## Design torques

Each case file holds its design scalars in a struct named `ds_single`.

| Variable | Field | Unit | From | What it is | Where it goes |
|---|---|---:|---|---|---|
| `T_peak` | `ds_single.T_peak` | N·m | Drag race | Largest torque the motor delivers | Gear tooth stress of both stages (Ch. 14); shaft static yield (Ch. 5) |
| `T_mean_eq` | `ds_single.T_mean_eq` | N·m | FTP-75 | Steady part of the equivalent fatigue cycle | DE-Goodman mean stress (Ch. 6) |
| `T_alt_eq` | `ds_single.T_alt_eq` | N·m | FTP-75 | Swinging part of the equivalent fatigue cycle | DE-Goodman alternating stress (Ch. 6) |
| `T_cubic_mean` | `ds_single.T_cubic_mean` | N·m | FTP-75 | Revolution-weighted cubic-mean torque | Bearing equivalent load, Sec. 11-7 Eq. (11-17) (Ch. 11); use the FTP-75 file's value only |
| `T_steady` | `ds_single.T_ss_mean` | N·m | Hill climb | Settled torque on a long grade | Hand check of the simulation (Student 01); finite-life extension (Student 03) |

These come from the same simulation but are reduced by different rules, because
they answer different failure questions. They are not interchangeable.

`ds_single` also carries a few fields for checking the run rather than for design:

| Field | Unit | Case | What it is |
|---|---:|---|---|
| `ds_single.case_name` | - | All | `FTP75`, `HillClimb` or `DragRace` |
| `ds_single.ftp_distance_m` | m | FTP-75 | Distance driven over the cycle; scales bearing life to 150,000 km |
| `ds_single.rms_err_kph` | km/h | FTP-75 | How closely the simulated car followed the cycle (under 5 is good) |
| `ds_single.fatigue_method` | - | FTP-75 | Name of the reduction behind `T_mean_eq` and `T_alt_eq` |
| `ds_single.sn_exponent` | - | FTP-75 | Exponent used in that reduction: 3, a fixed course value, not the slope of a Shigley S-N line |

In the other two cases these fields are `NaN` or `"N/A"`.

Note which checks use the city cycle. `T_mean_eq` and `T_alt_eq` are the reduction
of the FTP-75 spectrum and are the fatigue load on the shaft. `T_cubic_mean` is
the same history reduced for bearings: the revolution-weighted cubic mean, which
is the Shigley Eq. (11-17) equivalent load for a continuously varying load. The
tooth rating in Student 02 is a single-point Ch. 14 check at `T_peak` and does
not use the spectrum at all.

### The alternating bending moment

The mean and alternating split is defined for torque, not for the bending
moment, so the bending moment has to be defined separately and it is defined
here for the whole class.

A rotating shaft carries its bending fully reversed, so the bending moment is
entirely alternating: `M_m = 0`. Evaluate the gear forces, and therefore `M_a`,
at `T_mean_eq + T_alt_eq`, the largest torque the equivalent cycle reaches, and
treat the resulting bending moment as fully reversed. The torque keeps both
parts, `T_m = T_mean_eq` and `T_a = T_alt_eq`.

Other readings are arguable from first principles and they change the shaft
safety factor by more than 50 percent, so use this one.

## Rainflow spectrum

`ds_single.rf_data` carries the counted FTP-75 spectrum that the equivalent
sinusoid was reduced from:

| Field | What it is |
|---|---|
| `n_cycles` | Count of each counted cycle (1 or 0.5) |
| `T_mean_cyc` | Mean torque of each counted cycle, N·m |
| `T_alt_cyc` | Amplitude of each counted cycle, N·m |
| `N_total` | Total counted cycles |
| `m_sn` | Exponent used in the reduction (the fixed course value, 3) |
| `method_used` | Reduction method identifier |
| `range_gate` | Cycles with a torque range below this value, N·m (2 percent of the full range), were dropped as controller ripple before the reduction |
| `legacy_method_alias_used` | Internal flag, always false for this module; ignore it |

You do not need it for the required work, since `T_mean_eq` and `T_alt_eq` are
supplied. It is there so that you can check the reduction, plot the spectrum,
or test how sensitive your shaft factor is to the exponent.

## The torque curves

| Variable | Unit | In | What it is |
|---|---:|---|---|
| `torque_Nm` | N·m | each `*_Outputs.mat` | Torque against time for that case, as a timeseries |
| `torque_note` | - | each `*_Outputs.mat` | One sentence describing that curve |

For the hill climb and the drag race this is the applied motor torque. For
FTP-75 it is the **equivalent sinusoid**, not the raw tracked torque. The real
city-cycle history is far too irregular to put into a fatigue equation, so it
has been reduced to the single sinusoidal load whose mean and alternating parts
are `T_mean_eq` and `T_alt_eq`.

## Why the drag-race plot levels off just below 224 km/h

The drag race is open-loop: full motor torque from rest, on a flat road, for a
fixed 35 seconds, with no gear change. The speed levels off just below the
top speed `v_top`, about 224 km/h, because the motor reaches its speed limit, `omega_max`, where the available
torque tapers to zero. The tail of that curve is not a vehicle-performance
claim and you should not quote it as one.

It does not change any load you design with. `T_peak` is reached just after launch and held up to the motor base speed, where the
motor is against its torque limit and the tractive force is highest, and that
single peak is the purpose of the case. The rest of the trace is the
constant-power envelope falling away as drag builds, and it is there so you can
see the shape.

## Vehicle and gear data

All of these are top-level variables in `Design_Summary.mat`. The transmission
is single speed with two stages: stage 1 from the input pinion (`N1`) to the
intermediate gear (`N2`), stage 2 from the intermediate pinion (`N3`) to the
output gear (`N4`), which carries the differential.

| Variable | Unit | What it is |
|---|---:|---|
| `gear_ratio` | - | Overall ratio `G = (N2/N1)(N4/N3)` |
| `i1`, `i2` | - | Stage-1 and stage-2 ratios |
| `eta_dt` | - | Drivetrain efficiency of the whole transmission; each mesh takes `sqrt(eta_dt)` |
| `wheel_R` | m | Wheel radius; converts vehicle distance to shaft revolutions |
| `N1`, `N2`, `N3`, `N4` | teeth | Prescribed tooth counts |
| `m_n1`, `m_n2` | m | Normal module of each stage (Ch. 13) |
| `m_t1`, `m_t2` | m | Transverse module of each stage |
| `phi_n_deg` | deg | Normal pressure angle, common to both stages |
| `phi_t1_deg`, `phi_t2_deg` | deg | Transverse pressure angle of each stage |
| `psi1_deg`, `psi2_deg` | deg | Helix angle of each stage, which is what gives rise to the axial forces |
| `d1`, `d2`, `d3`, `d4` | m | Pitch diameters of the four gears |
| `Tmax`, `Pmax` | N·m, W | Motor torque and power limits |
| `omega_base`, `v_base` | rad/s, m/s | Motor base speed and the vehicle speed at which it is reached; the speed for `K_v` in Student 02 |
| `omega_max`, `v_top` | rad/s, m/s | Motor speed limit and the top speed it allows; the `Q_v` check itself is made at 120 km/h |
| `m_vehicle` | kg | Vehicle mass, for the hill-climb hand check |
| `Crr`, `Cd`, `A_frontal`, `rho_air` | -, -, m², kg/m³ | Rolling, drag and air-density data, for the hill-climb hand check |
| `theta_hill_deg` | deg | Hill-climb grade angle |

The angles are exported in **degrees** while the lengths are in meters. Convert
the angles once, in Student 01, and carry radians through the rest of the work.

## Torques on the other shafts

Every input torque has an intermediate and an output counterpart:

```
T_int = T_in * i1 * sqrt(eta_dt)
T_out = T_in * G  * eta_dt
```

The intermediate shaft, the one you design, carries about three times the motor
torque and turns about three times faster than the wheel. Both effects matter.
The torque determines the diameter, and the rotational speed determines how many
load cycles accumulate over 150,000 km.
