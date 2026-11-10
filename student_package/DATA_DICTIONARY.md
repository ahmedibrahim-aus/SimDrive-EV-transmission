# Student data dictionary

This document lists every variable that the simulation supplies, its meaning and
the calculation in which it is used. Chapter references are to *Shigley's
Mechanical Engineering Design*, 11th ed.

## Design torques

Each case file contains its design scalars in a struct named `ds_single`.

| Variable | Field | Unit | Source | Description | Application |
|---|---|---:|---|---|---|
| `T_peak` | `ds_single.T_peak` | N·m | Drag race | Maximum torque delivered by the motor | Gear tooth stress of both stages (Chapter 14); shaft static yield (Chapter 5) |
| `T_mean_eq` | `ds_single.T_mean_eq` | N·m | FTP-75 | Mean component of the equivalent fatigue cycle | DE-Goodman mean stress (Chapters 6 and 7) |
| `T_alt_eq` | `ds_single.T_alt_eq` | N·m | FTP-75 | Alternating component of the equivalent fatigue cycle | DE-Goodman alternating stress (Chapters 6 and 7) |
| `T_cubic_mean` | `ds_single.T_cubic_mean` | N·m | FTP-75 | Revolution-weighted cubic-mean torque | Bearing equivalent load (Chapter 11); use the FTP-75 file's value only |
| `T_steady` | `ds_single.T_ss_mean` | N·m | Hill climb | Mean motor torque over the last 40 percent of the hill-climb run, as the vehicle approaches its settling speed | Hand check of the simulation (Student 01); finite-life extension (Student 03) |

`ds_single` also contains several fields for verification of the run:

| Field | Unit | Case | Description |
|---|---:|---|---|
| `ds_single.case_name` | - | All | `FTP75`, `HillClimb` or `DragRace` |
| `ds_single.ftp_distance_m` | m | FTP-75 | Distance driven over the cycle (reference only; Student 04 converts life with the tire radius and the stage-2 ratio) |
| `ds_single.rms_err_kph` | km/h | FTP-75 | RMS speed error of the simulated vehicle over the cycle (below 5 km/h indicates adequate tracking) |
| `ds_single.sn_exponent` | - | FTP-75 | Exponent of the reduction that produces `T_mean_eq` and `T_alt_eq`: 3, a fixed course value |

Every case file contains every field, and `rf_data` is empty for cases other
than FTP-75. A field that belongs to another case is `NaN`, except
`T_cubic_mean`, which every case reports. Use only the FTP-75 value.

### The alternating bending moment

The mean and alternating split is defined for torque only, so this section
defines the bending moment separately for the whole class.

A rotating shaft carries its bending fully reversed, so the bending moment is
entirely alternating: `M_m = 0`. Evaluate the gear forces, and therefore `M_a`,
at `T_mean_eq + T_alt_eq`, the maximum torque of the equivalent cycle, and treat
the resulting bending moment as fully reversed. The torque retains both
components, transferred to the intermediate shaft: `T_m = T_mean_eq_int` and
`T_a = T_alt_eq_int`.

## Rainflow spectrum

`ds_single.rf_data` contains the counted FTP-75 spectrum from which the
equivalent sinusoid was reduced:

| Field | Description |
|---|---|
| `n_cycles` | Weight of each rainflow cycle: 1 or 0.5 |
| `T_mean_cyc` | Mean torque of each counted cycle, N·m |
| `T_alt_cyc` | Alternating torque of each counted cycle, N·m |
| `N_total` | Total counted cycles |
| `m_sn` | Exponent used in the reduction (the fixed course value, 3) |
| `range_gate` | Cycles with a torque range below this value, N·m (2 percent of the full range), were discarded before the reduction as small oscillations of the simulated speed controller |

The spectrum is not needed for the required work, since `T_mean_eq` and
`T_alt_eq` are supplied. It is provided so that the reduction can be verified or
the spectrum plotted.

## The torque curves

| Variable | Unit | Location | Description |
|---|---:|---|---|
| `torque_Nm` | N·m | each `*_Outputs.mat` | Torque against time for that case, as a timeseries |
| `torque_note` | - | each `*_Outputs.mat` | One sentence describing that curve |

For the hill climb and the drag race, the curve is the applied motor torque. For
FTP-75, it is the equivalent sinusoid whose mean and alternating components are
`T_mean_eq` and `T_alt_eq`. The hand-out `README.md` gives the reason and the
points to observe when the curve is plotted.

## Drag-race speed plateau below the top speed

The drag race has no speed controller: full motor torque is applied from rest,
on a flat road, for a fixed 35 seconds, with no gear change. The speed levels
off immediately below the top speed `v_top`, approximately 224 km/h, because the
motor reaches its speed limit, `omega_max`, at which the available torque
decreases to zero. The final portion of the curve is not a vehicle-performance
claim and should not be quoted as one.

The plateau does not change any design load. `T_peak` is reached immediately
after launch and is maintained up to the motor base speed, where the motor
operates at its torque limit and the tractive force is highest, and this single
peak is the purpose of the case. The remainder of the trace is the
constant-power envelope, with torque decreasing as 1/omega as the speed rises
while increasing drag reduces the acceleration, and it is included to show the
shape of the curve.

## Vehicle and gear data

All of these quantities are top-level variables in `Design_Summary.mat`. The
transmission is single speed with two stages: stage 1 from the input pinion
(`N1`) to the intermediate gear (`N2`), stage 2 from the intermediate pinion
(`N3`) to the output gear (`N4`), which carries the differential.

| Variable | Unit | Description |
|---|---:|---|
| `gear_ratio` | - | Overall ratio `G = (N2/N1)(N4/N3)` |
| `i1`, `i2` | - | Stage-1 and stage-2 ratios |
| `eta_dt` | - | Drivetrain efficiency of the whole transmission; each mesh is assigned `sqrt(eta_dt)` |
| `wheel_R` | m | Tire radius; converts vehicle distance to shaft revolutions |
| `N1`, `N2`, `N3`, `N4` | teeth | Prescribed tooth numbers |
| `m_n1`, `m_n2` | m | Normal module of each stage (Chapter 13) |
| `m_t1`, `m_t2` | m | Transverse module of each stage |
| `phi_n_deg` | deg | Normal pressure angle, common to both stages |
| `phi_t1_deg`, `phi_t2_deg` | deg | Transverse pressure angle of each stage |
| `psi1_deg`, `psi2_deg` | deg | Helix angle of each stage, the source of the axial forces |
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

The intermediate shaft, which is the shaft to be designed, carries
`i1*sqrt(eta_dt)` times the motor torque and rotates `N4/N3` times faster than
the wheel. The torque determines the diameter, and the rotational speed
determines the number of load cycles accumulated over 150,000 km.
