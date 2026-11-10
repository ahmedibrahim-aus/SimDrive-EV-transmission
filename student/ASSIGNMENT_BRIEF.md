# SimDrive: EV Transmission Design

*Design assignment: a single-speed, two-stage EV transmission*

Design the gears of both reduction stages, the intermediate shaft, and its
rolling-contact bearings for the transmission of a rear-wheel-drive passenger
electric vehicle.

## Relation to the course

This project runs in parallel with the Machine Design course and applies the
Shigley material as it is taught: stresses (Chapter 3), static failure (Chapter
5), fatigue and the Marin factors (Chapter 6), shafts (Chapter 7),
rolling-contact bearings (Chapter 11), gear geometry (Chapter 13) and AGMA gear
rating (Chapter 14). Each part names the chapters that it uses, and the
instructor specifies the due date of each part. The templates provide the
method, and the engineering decisions are left to the student.

## Differences from a textbook problem

The methods are those already covered in the course. The project differs from a
textbook problem in three respects.

1. The load is obtained from a simulation. An instructor-side simulation drives
   the vehicle through three cases and returns the torque and speed that the
   transmission experiences. The table below states which torque supports which
   check, and the first task is to justify each assignment numerically. A
   gearbox is not subjected to a single load. It experiences a large torque a
   small number of times and a much smaller torque several million times, and
   these two conditions damage a component by different mechanisms. The student
   must determine and demonstrate which of them governs each component.

2. The rating factors are design choices. Every AGMA factor, every Marin factor,
   the material and its grade must be selected, traced to a named figure or
   table, and justified. The 150,000 km target life is fixed, whereas the cycle
   count of each member over that life must be derived.

3. The objective is the lightest assembly that meets the targets at every
   critical section. Feasible geometries are compared, and the constraint that
   determines the final dimensions is identified.

## Single speed, two stages

The vehicle has a single-speed transmission with one fixed ratio and no
shifting. This arrangement is used in almost every production EV, and for this
reason no clutch, synchronizer or shift logic appears in the project.

The ratio is obtained in two stages on three parallel shafts, as in a production
drive unit. In stage 1, the primary reduction, the input pinion on the motor
shaft drives a larger gear on the intermediate shaft. In stage 2, the final
drive, a pinion on the same intermediate shaft drives the output gear, which
carries the differential and rotates with the wheels. Dividing the reduction
between two stages keeps every gear small enough to fit beneath the vehicle.

The load path is short. Motor torque enters the input shaft, passes through the
stage-1 mesh to the intermediate shaft, is transmitted along that shaft between
its two gears, passes through the stage-2 mesh, and leaves through the
differential to the wheels. The intermediate shaft is the only component loaded
by both meshes simultaneously, and it is the shaft designed in this project.

## Fixed design basis

- Single-speed, two-stage helical reduction. Tooth numbers, normal modules and
  helix angles of both stages are prescribed in `Design_Summary.mat`, and the
  overall ratio is the product of the two stage ratios.
- The three shafts lie in one plane, and both gears on the intermediate shaft
  have the same helix hand.
- Three simulated cases: the FTP-75 city cycle, a sustained hill climb, and
  full-throttle acceleration from rest (the drag-race case, `DragRace` in the
  data files).
- The city-cycle torque history has already been reduced to one equivalent mean
  and alternating pair for the fatigue calculation.
- Methods restricted to those in *Shigley's Mechanical Engineering Design*, 11th
  edition. Catalogs supply component data only.

## Assignment of torques to design checks

| Torque | Source | Application | Reason |
|---|---|---|---|
| `T_peak` | Drag race | Gear tooth stress, shaft static yield | Chapter 14 rates a tooth at one transmitted load, and using the peak at the full-life cycle count is conservative. The shaft must also not yield under this torque |
| `T_mean_eq`, `T_alt_eq` | City cycle | Shaft fatigue, DE-Goodman | Repeated cycles cause shaft failure below the yield strength |
| `T_cubic_mean` | City cycle | Bearing rating life | The constant load equivalent to the varying one, Shigley Chapter 11 |
| `T_steady` | Hill climb | Hand check of the simulation (required) and finite-life extension | A steady climb has a closed-form torque, so it verifies the model before the results are used |

## Required submissions

1. The four completed templates (`.m`). Each must run without error, in order
   from 01 to 04, in a new MATLAB session with the supplied
   `exports_design_ready` folder beside it.
2. A design report following `DESIGN_REPORT_TEMPLATE.md`.
3. Gear, shaft, and bearing result tables with units on every column.
4. A scaled drawing of the intermediate shaft showing diameters, lengths, and
   fillet radii.
5. At least one documented design iteration, stating the change, its reason and
   its effect on the results.
6. The catalog page reference for the selected bearings.

## Checks the design must satisfy

- A hand calculation of the hill-climb steady torque from the power-limited
  equilibrium, agreeing with the simulated `T_steady` to within one percent,
  with the difference explained.
- AGMA bending safety factor `S_F` of at least 1.5 and contact safety factor
  `S_H` of at least 1.2, for all four gears of both stages, with `S_t` and `S_c`
  taken from the same AGMA grade and each member rated at its own cycle count.
  Each face width lies inside the `3*p_t` to `5*p_t` band and is at least
  `2*p_x`, so that the face-contact ratio `m_F = F/p_x` is at least 2, the range
  for which the Chapter 14 helical geometry factors are stated.
- The gears, the shaft and the bearings designed for 90 percent reliability
  (`K_R`, `k_e` and `L_10`) at normal operating temperature, below 120 °C
  (`K_T = 1`, `k_d = 1`).
- A statement of which mode governs each member, compared on a like basis (`S_F`
  against `S_H^2`).
- Intermediate-shaft fatigue and static-yield factors of safety, `n_f` and
  `n_y`, of at least 1.5 (design factor `n_d = 1.5`) at every critical section,
  including sections that are not expected to govern, with both helix thrust
  couples `M_0 = W_a d/2 = T tan(psi)` included in the bending moment and the
  worse sign taken at each section.
- A stage-2 pinion rim backup ratio of at least 1.2 on its seat, Shigley Chapter
  14, so that `K_B = 1` holds.
- Notch sensitivity from the correct Shigley fit (Chapter 6): `q` for bending
  and axial loading from the bending fit for the Neuber constant, `qs` for
  torsion from the torsion fit. These are different curves.
- The notch factors of one shoulder read from the Shigley charts by hand and
  compared with `computeShoulderNotchFactors`, with the comparison quoted in the
  report.
- Bearing rating life of at least 150,000 km, with `e` and `Y` interpolated from
  the Shigley Chapter 11 table against `F_a/C_0` for each candidate.
- Mutual compatibility of bearing bore, shaft journal, shoulder, fillet radius,
  and gear seat, with a flat shoulder face at every shoulder and a statement of
  the feature that locates each bearing and each gear axially (shoulder, spacer
  or press fit).

## Scope and limitations

The project is an educational design exercise. The input shaft and its bearings
are an optional extension, and the output shaft and differential are outside the
assignment.

The course calculations rest on the approximations below. Each approximation
must be stated in the report, together with the additions that a production
design would require. An approximation that is used but not stated is treated as
an error.

- The multiplier applied to the helical geometry factor J (Shigley Chapter 14)
  is read at the number of teeth of the member itself, the convention given in
  Student 02.
- Bearings are selected on `L_10` rating life (Shigley Chapter 11) at 90 percent
  reliability, with no Weibull adjustment and no application factor. At peak
  torque the radial load on a bearing chosen for life can exceed its basic
  static load rating `C_0`, and Student 04 specifies the static ratio to report.
  A production design would also require adequate static capacity, which can
  require a larger bearing and a revised shaft, and would detail the fits,
  retention and spacers that locate each bearing.
- The torque transfer in Student 01 applies the motoring loss factor,
  `i1*sqrt(eta_dt)`, to the reduced FTP-75 torques in both directions, although
  the vehicle simulation treats driving and regenerative losses separately. For
  negative motor torque the intermediate-shaft factor would be
  `i1/sqrt(eta_dt)`. For the default vehicle, mapping the signed history before
  the cubic reduction raises the intermediate equivalent bearing torque by
  approximately 1 percent and lowers the predicted bearing life by approximately
  3 percent.
- The tooth rating pairs the peak motor torque with the full design life, a
  combination that never occurs in the duty cycle, so this is the most
  conservative assumption in the project. A production durability check would
  add tire slip, shaft deflection and slope, damage from repeated full-throttle
  launches, and the stresses from keys and press fits.
