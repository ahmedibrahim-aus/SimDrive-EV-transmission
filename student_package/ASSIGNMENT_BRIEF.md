# SimDrive: EV Transmission Design

### Design assignment: a single-speed, two-stage EV transmission

Design the gears of both reduction stages, the intermediate shaft, and its
rolling-contact bearings for the transmission of a rear-wheel-drive passenger
electric vehicle.

## How this fits your course

This project runs alongside your Machine Design course and uses the Shigley
material as you learn it: Ch. 3 stresses, Ch. 5 static failure, Ch. 6 fatigue
and the Marin factors, Ch. 7 shafts, Ch. 11 rolling-contact bearings, Ch. 13
gear geometry and Ch. 14 AGMA gear rating. Each part names the chapters it uses,
and your instructor will say when each part is due. The templates give the
method and leave the engineering to you.

## What is new here

The methods are those you already know; three things differ.

1. The load is not in the question. An instructor-side simulation drives the
vehicle through three situations and returns the torque and speed the
transmission experiences. Establishing which of those torques belongs
in which calculation is the first task and it carries a substantial share of the
points, because a gearbox does not see a single load. It sees a large torque a
few times and a much smaller one several million times, and those two situations
damage a component by different mechanisms. Which of them governs is not given:
on this vehicle the city cycle turns out to be a light duty cycle, and part of the task
is to show, with numbers, which check sizes each component.

2. The rating factors are not handed to you. Every AGMA factor, every Marin factor,
the material and its grade are yours to choose, source from a named figure or
table, and defend. The 150,000 km service target is fixed; the cycle count of
each member over that target is yours to derive.

3. The design is not finished when it passes. The objective is the lightest
assembly that meets every target at every section, which means searching the
feasible geometry rather than checking one guess, and knowing which constraint
is binding.

## Single speed, two stages

The car has a single-speed transmission: one fixed ratio, no shifting. This is
true of almost every production EV, and it is why no clutch,
synchronizer, or shift logic appears anywhere in the project.

That one ratio is reached in two stages, on three parallel shafts, which is how
a production drive unit does it. Stage 1, the primary reduction: the input
pinion on the motor shaft drives a larger gear on the intermediate shaft. Stage
2, the final drive: a pinion on the same intermediate shaft drives the output
gear, which carries the differential and turns with the wheels. Splitting the
reduction keeps every gear small enough to fit beneath the car.

The load path is short. Motor torque enters the
input shaft, passes through the stage-1 mesh to the intermediate shaft, crosses
that shaft between its two gears, passes through the stage-2 mesh, and leaves
through the differential to the wheels. The intermediate shaft is the only
component loaded by both meshes at once, and it is the shaft you design.

## Fixed design basis

- Single-speed, two-stage helical reduction. Tooth counts, normal modules and
  helix angles of both stages are prescribed in `Design_Summary.mat`; the
  overall ratio is their product.
- The three shafts lie in one plane, and both gears on the intermediate shaft
  have the same helix hand.
- Three simulated cases: the FTP-75 city cycle, a sustained hill climb, and
  full-throttle acceleration.
- The city-cycle torque history has already been reduced to one equivalent mean
  and alternating pair for the fatigue calculation.
- Methods restricted to those in *Shigley's Mechanical Engineering Design*, 11th
  edition. Catalogs supply component data, not alternative equations.

## Which torque supports which check

| Torque | Source | Used for | Reason |
|---|---|---|---|
| `T_peak` | Full throttle | Gear tooth stress, shaft static yield | The worst single load must not fracture or permanently deform anything |
| `T_mean_eq`, `T_alt_eq` | City cycle | Shaft fatigue, DE-Goodman | Repeated cycles fail a shaft below its yield strength |
| `T_cubic_mean` | City cycle | Bearing rating life | The constant load equivalent to the varying one, Shigley Sec. 11-7 Eq. (11-17) |
| `T_steady` | Hill climb | Hand check of the simulation (required); finite-life extension | A steady climb has a closed-form torque, so it tests the model before you trust it |

The reduced city-cycle spectrum is the fatigue load on the shafts (whether it
or the static peak sizes them is for you to show); its cubic mean is
the bearing load. The spectrum
does not size the teeth: Ch. 14 rates a tooth at a single transmitted load, and
that load is `T_peak`.

## Required submissions

1. The four completed MATLAB templates.
2. A design report following `DESIGN_REPORT_TEMPLATE.md`.
3. Gear, shaft, and bearing result tables with units on every column.
4. A scaled diagram of the intermediate shaft showing diameters, lengths, and
   fillet radii.
5. At least one documented design iteration, stating what was changed, why, and
   what moved as a result.
6. The catalog page reference for the selected bearings.

## Checks the design must satisfy

- A hand calculation of the hill-climb steady torque from the power-limited
  equilibrium, agreeing with the simulated `T_steady` to within a few percent,
  with the difference explained.

- Gear bending safety factor of at least 1.5 and contact safety factor of at
  least 1.2, for all four gears of both stages, with `S_t` and `S_c` taken from
  the same AGMA grade and each member rated at its own cycle count.
- A statement of which mode governs each member, compared on a like basis:
  `S_F` against `S_H^2`, not against `S_H`.
- Intermediate-shaft fatigue and static yield safety factors of at least 1.5 at
  every critical section, not only at the section you expect to be worst, with
  both helix thrust couples `M_0 = W_a d/2 = T tan(psi)` included in the bending
  moment and the worse sign taken at each section.
- A stage-2 pinion rim backup ratio of at least 1.2 on its seat, Shigley
  Eq. (14-40), so that `K_B = 1` holds.
- Notch sensitivity read from the correct chart: `q` for bending and axial
  loading, `qs` for torsion. These are different curves.
- One shoulder's notch factors read off the Shigley charts by hand and checked
  against `computeShoulderNotchFactors`, with the comparison quoted in the
  report.
- Bearing rating life of at least 150,000 km, with `e` and `Y` interpolated from
  Shigley Table 11-1 against `F_a/C_0` for each candidate.
- Mutual compatibility of bearing bore, shaft journal, shoulder, fillet radius,
  and gear seat, with a flat shoulder face at every shoulder and a statement of
  what locates each bearing and each gear axially (shoulder, spacer or press fit).

## Scope and limitations

This is an educational design rather than a production transmission. The input
shaft and its bearings are an optional extension, and the output shaft and
differential are outside the assignment. Identifying the limitations of the
model forms part of the report and is not counted against your design.

Two limits of the method belong in that section: `L_10` at 90 percent
reliability is accepted as the bearing criterion, with no Weibull adjustment and
no application factor; and the tooth rating pairs the peak motor torque with the full design life, which the duty
cycle never does, so it is the most conservative point in the project.
