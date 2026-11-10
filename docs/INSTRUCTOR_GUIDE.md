# Instructor guide for SimDrive: EV Transmission Design

## Purpose and scope

SimDrive is a design project for third- and fourth-year students enrolled in a
Machine Design or Design of Machine Elements course based on *Shigley's
Mechanical Engineering Design*, 11th edition. Each part uses the chapters named
in it, so the parts can be released as those chapters are taught. The instructor
generates EV load data, and students design a conceptual single-speed, two-stage
helical transmission using only the procedures of Shigley.

On completion of the project, students are able to:

- choose the design load for each failure mode from simulated duty cycles;
- rate a helical gear pair in bending and contact with the AGMA procedure;
- design a stepped shaft for fatigue and yield at every critical section;
- select rolling-contact bearings for a rating life from a catalog;
- verify a simulation result by hand calculation.

The vehicle and motor values are typical of a current rear-wheel-drive passenger
EV and are course inputs that do not represent any specific vehicle.

The [assignment
limitations](../student/ASSIGNMENT_BRIEF.md#scope-and-limitations) should be
read before results are distributed. A design that passes the course checks has
not been checked against every chart condition or production requirement;
`docs/EXPECTED_RESULTS.md`, in the emailed answer-key archive, gives the
reference design's values for these limits.

The dashboard rejects physically invalid inputs, including an ambient
temperature outside -40 to 60 °C, and does not overwrite saved Simulink
models.

The dashboard shows the vehicle and an enlarged view of the drive unit, both
animated at the current gear ratios with the gears to scale. Bearing spans and
gaps are illustrative and drawn enlarged for legibility, and design dimensions
should be taken from the calculations.

The schematic shows a motor and a separate transmission on the rear axle driving
the rear wheels, the layout of many rear-wheel-drive EVs. The transmission is
single speed with two stages on three parallel shafts in one plane: the input
pinion drives the stage-1 gear on the intermediate shaft, the stage-2 pinion on
the same shaft drives the output gear, and the output gear carries the
differential on the axle, which drives a half-shaft to each rear wheel.

Students frequently confuse single-speed with single-stage, and the distinction
should be made in the first session. The vehicle is single-speed, with one fixed
ratio and no gear changes. The reduction is two-stage because a 9:1 ratio in a
single pair requires a driven gear larger than the road wheel (with the
20-tooth, 4 mm pinion: a 794 mm gear against a 668 mm tire). The resulting
intermediate shaft carries both meshes and is the shaft that students design.

## Choosing the gear train

The gear-train panel of the dashboard sets both stages: the pinion and gear
tooth numbers, the normal module and the helix angle of each. The overall ratio
is computed from the tooth numbers and displayed as a read-only value. The
vehicle simulation uses this ratio, so a change that alters it requires a new
run before export. The normal pressure angle is locked at 20 degrees because the
Shigley Chapter 14 helical geometry-factor charts are drawn for 20 degrees only.

A train that the Shigley procedure cannot rate is rejected on entry, and the
violated rule is stated: a pinion below the interference minimum, a module not
on the Chapter 13 preferred list, a tooth count or helix angle outside the
printed domain of the Chapter 14 geometry-factor charts, or a helix angle below
21.8 degrees, where no face width up to 5 p_t reaches the face-contact ratio of
2 that those charts assume.

With "key picks" selected, the stage-2 module is chosen at export: the smallest
preferred module from the stage-1 module upward for which the key rates stage 2
with a face width from the larger of 3 p_t and 2 p_x (so that m_F is at least 2)
up to 5 p_t. Students always receive a fully prescribed train.

Once the answer-key archive is extracted, every complete export runs the worked
solution on the exported data, displays it on the Answer Key tab, and writes it
to `exports_design_ready/Answer_Key.md`. The key makes its own design choices by
rule (lowest admissible Q_v, narrowest passing face width, softest passing
Appendix A steel row, smallest passing bore, lightest passing bearing), so it is
valid for any train. If the key cannot meet a target, it states the reason and
no student package is built.

The key performs the checks that the course assigns: AGMA bending and contact
(Chapter 14), DE-Goodman fatigue and static yield of the intermediate shaft
(Chapters 6 and 7), and bearing L10 life (Chapter 11). It does not cover every
requirement of a production gearbox. Its limitations, with the reasons, are
listed in [`docs/MathematicalModels.md`](MathematicalModels.md), Section 10.3
("Not checked by the course key"). Among them are shaft deflection and slope,
the bearings' static load rating at peak torque, fatigue from repeated
full-throttle launches, the quality number of both stages above the course speed
(stage 1 cannot meet the limit at top speed), two-way tooth loading and the
axial location of the gears. Students should be informed which of these
limitations they are expected to discuss, since each is a suitable question for
the report.

## Preparation before class

1. Clone or download the repository.
2. Open MATLAB R2025b or newer and change to `instructor/`.
3. Run `Start_Here.mlx` and complete the dependency check.
4. Generate FTP-75, hill-climb, and drag-race cases with `InstructorApp` or
   `generateLoadCases`.
5. After a command-line run, call `buildStudentPackage` in `instructor/`. The
   dashboard does this automatically when exporting all three cases. Each build
   creates new contents in `student_package/` and a matching ZIP in `release/`,
   and the instructor solution is excluded. Partial runs cannot produce a
   complete package.

The output folders are located inside the repository regardless of the current
MATLAB folder. For a separate run folder, use
`InstructorApp(OutputRoot="absolute/output/path")`. Each build replaces the
contents of `student_package/` except its `README.md` and the project brief,
`SimDrive_Project_Brief.docx`. Course constraints should be placed in the brief,
and other notes kept elsewhere.

`main.mlx`, `generateLoadCases` and the answer key's `Solution_01` clear the
base workspace, so existing variables should be saved first.

## Materials provided to students

The `student_package/` folder, or the identical ZIP from `release/`:

- `SimDrive_Project_Brief.docx`, the project brief students read first
- `README.md` for the hand-out, which describes each file and the location of
  the data
- `Student_01_Load_Inputs.m` through `Student_04_Bearing_Selection.m`
- `ASSIGNMENT_BRIEF.md`
- `DESIGN_REPORT_TEMPLATE.md`
- `DATA_DICTIONARY.md`
- `computeShoulderNotchFactors.m`
- `LICENSE` and `LICENSE-docs`
- `exports_design_ready/`, located beside the templates

The dataset in the hand-out is the instructor export reduced for distribution.
Each case retains its `ds_single` design scalars unmodified and contains one
2000-point torque curve with a note that identifies the curve. For FTP-75 that
curve is the equivalent sinusoid that the Goodman calculation uses. The
full-resolution instructor export is written to `exports_design_ready/` at the
repository root when the load cases are run.

The `.m` files use MATLAB's plain-text Live Code format. They contain
explanatory text, Shigley equations, required output names, and comment-only
TODO cells. They contain no executable solution code.

`Student_03` supplies the notch-factor function for the minimum-mass sweep and
asks students to verify it against one shoulder read from the charts by hand.

## Materials retained by the instructor

- The Simulink model generator and the dashboard (`InstructorApp`)
- The completed solution, sent by email and extracted into
  `instructor/solution/`
- Expected-result ranges
- The Shigley figures used to verify the digitized chart data (held by the
  instructor; not redistributed with this project)

The use of the reference solution is described in
[`instructor/solution/README.md`](../instructor/solution/README.md), and the
solution must be kept out of the student package. The key and
`docs/EXPECTED_RESULTS.md` are not in the repository. They are sent to
instructors by email in the encrypted archive `instructor_answer_key.7z`, and
the [repository README](../README.md#the-reference-solution) explains how to
request and extract it. The password and the extracted files must not be shared
with students. The most effective protection remains to vary the inputs by
section (the dashboard recomputes the key for any gear train) and to grade
reasoning, traceability and design decisions.

Until the archive is extracted, the dashboard and `generateLoadCases` still run,
and the student package can still be built. In that case the dashboard uses the
entered stage-2 module, the command line uses 5 mm, and no answer key is
written.

## Scoping the assignment

The parts of the project can be assigned separately. `Student_01` is the data
transfer step and is always required, because it loads the design torques and
the gear geometry into the workspace. The three design parts that follow it are
independent submissions:

| Part | Template | Shigley chapters |
|---|---|---|
| Gear rating | `Student_02_Gear_Design.m` | 13 and 14 |
| Shaft design | `Student_03_Shaft_Design.m` | 6 and 7 |
| Bearing selection | `Student_04_Bearing_Selection.m` | 11 |

One, two or all three parts can be assigned. A single part with a short report
is a two- to three-week assignment within a machine design course. All three
parts, with the full design report, constitute a term project. Different
sections or teams can be assigned different parts and then present to one
another, which resembles the division of work in engineering practice.

An assignment can begin at an intermediate part because a complete worked
solution exists, which instructors receive by email. A student who is assigned
only the bearing task does not need to have completed the shaft task. The shaft
reactions from `docs/EXPECTED_RESULTS.md` (in the encrypted answer-key archive)
can be supplied as given data, in the same way that a practicing engineer
receives loads from another design group. The same applies to an assignment that
begins at the shaft with the mesh forces supplied. The assignment should state
explicitly which values are given and which are to be derived, because the
derivation is the assessed work (see
[`ASSESSMENT_RUBRIC.md`](ASSESSMENT_RUBRIC.md)).

The load cases are equally adjustable. Three load cases are provided, and each
can be used independently: the drag race is the peak-torque case, the hill climb
is the validation case (a hand-checkable steady state, with an optional
finite-life extension), and the FTP-75 city cycle is the fatigue and
bearing-life case. One case can be assigned, or different cases can be given to
different teams for a comparison of the checks that each case governs.
Regeneration with different vehicle parameters requires a single instructor-side
run, and [Assignment variation](#assignment-variation) below lists what can be
changed without changing what students calculate.

The repository contains the complete project: the vehicle, all three load cases,
both gear stages, the intermediate shaft and both its bearings, with the input
shaft as an optional extension, so that every smaller assignment is supported by
complete, verified data.

## Suggested delivery

The schedule below covers the full project, with all three parts, in six weekly
meetings. For a single-part assignment, the two or three applicable rows are
used. The [prototype challenge](PROTOTYPE_CHALLENGE.md) follows the same six
weeks.

| Week | Topic | Student outcome |
|---|---|---|
| 1 | Load paths, the three vehicle cases, the hill-climb hand check | Verified design-input table |
| 2 | Helical gear geometry and forces | Gear geometry and mesh-force table |
| 3 | Shigley/AGMA gear rating | Bending/contact safety factors |
| 4 | Shaft layout, reactions, stress concentration and notch sensitivity | Moment diagrams; `Kt`, `Kts`, `q`, `qs`, `Kf`, `Kfs` |
| 5 | Endurance limit, DE-Goodman and static yield | Critical-section shaft checks |
| 6 | Rolling-contact bearings and integration | Bearing selection and final design review |

If the course teaches Chapters 6 and 7 before Chapters 13 and 14, the gear
geometry and mesh forces (`Student_02` Task 2) should be released with the
shaft, trial face widths supplied as given data, and the shaft revisited by
students after the gear rating.

## Scope of the student calculations

- Vehicle simulation and FTP-75 reduction are instructor-side data preparation.
- Students use the supplied `T_mean_eq` and `T_alt_eq` as one equivalent
  sinusoidal cycle.
- Student gear equations are the AGMA procedure as presented in Shigley 11e.
- Student shaft equations are the Shigley endurance, notch, DE-Goodman, and
  distortion-energy procedures.
- Student bearing equations use the Shigley rating-life procedure at
  `T_cubic_mean`, the revolution-weighted cubic mean of the FTP-75 torque, which
  is the Shigley Chapter 11 equivalent load for a continuously varying load (`X`
  and `Y` held at their values for that load). Catalogs supply dimensions and
  `C`/`C0`, whereas `e` and `Y` are taken from the Shigley Chapter 11 table
  against `Fa/C0`. The exercise checks the nominal bore match, `L10`, and the
  catalog abutment diameter and corner radius against the shoulder, and asks for
  the static ratio of the floating bearing at peak torque (`Student_04`). It
  does not cover fits, retention or a static-capacity selection.
- The gear seats are plain sections: the press fit or keys that hold the gears
  are outside the project and are assumed to add no stress concentration, as
  stated in `Student_03` Task 1 and in
  [`MathematicalModels.md`](MathematicalModels.md), Section 9.2. A keyed seat is
  a logical extension. An end-milled keyseat carries the Chapter 7
  stress-concentration factors, which are higher in torsion than those of the
  shoulder, and the extension shows students the extent to which a keyseat
  shifts the governing section.
- Alternative fatigue criteria, finite-element stress results, ISO gear-rating
  equations and manufacturer-specific life-adjustment equations should not be
  introduced into the required solution.

## Selection of the load cases

The launch case is an open-loop drag race rather than a speed-controlled highway
merge from 0 to 120 km/h. It serves the same purpose, which is to produce the
largest torque that the transmission experiences, for the AGMA tooth stress and
the shaft yield check. It does so without a speed target for the controller to
follow, so the peak torque is the limit of the motor itself and is independent
of the PID gains.

Students do not run the Simulink model. The vehicle simulation is performed on
the instructor side for two practical reasons: one term is not sufficient to
build the vehicle model and complete a full gearbox design, and retaining the
model on the instructor side allows the loads to be varied between sections
without students editing model code. In both cases the instructor workflow is
fully scripted, through `generateLoadCases` or the dashboard.

At this level, the arrangement is a scoping decision, and the model is the
logical component through which to extend the project. One extension is to
provide students with the model in read-only form and to pose questions about
it: which design torque changes when the vehicle mass changes, which resistance
term dominates at 30 and at 120 km/h, and which omitted effects would be of
consequence. The counted rainflow spectrum is already supplied to students in
`ds_single.rf_data` and is documented in `DATA_DICTIONARY.md`, so students can
also be asked to reproduce the reduction themselves. The reduction is summarized
in [`FATIGUE_LOAD_REDUCTION.md`](FATIGUE_LOAD_REDUCTION.md).

## Assignment variation

One or more of the following can be varied while the same learning outcomes are
retained:

- Vehicle mass, drag or rolling resistance (dashboard or `main.mlx`)
- Motor torque, power or speed limit (dashboard or `main.mlx`)
- Gear train: teeth, modules and helix angles of both stages (dashboard)
- Hill angle. Grades far from 20 degrees may require a longer hill-climb run to
  reach steady state (up to approximately 240 s), and the answer key reports
  when the run has not reached steady state.
- Target service distance: the 150,000 km life is a course default that an
  instructor may change through `life_km` in
  `instructor/solution/courseTargets.m` (students may not). Students should be
  informed of any change, since the templates and the brief state 150,000 km.
- Required shaft steel or gear hardness range: state it in the project brief;
  the templates leave these choices to the students.
- Approved bearing series: state it in the project brief if the catalog
  available to students is to be restricted.

The project brief and several template sentences describe the default vehicle
(1610 kg, 9:1, 20-degree grade). If the vehicle or the gear train is changed,
students should be informed that the design values are those in the exported
data (`Design_Summary.mat` and the three case files).

Reliability is not among these parameters. The entire project is designed for 90
percent reliability (`L10` for the bearings, `K_R = 0.85` for the gears,
`k_e = 0.897` for the shaft), and no equation in the distributed code accepts a
different target. A higher reliability requires changes to `K_R` and `k_e` and
the addition of the Shigley Chapter 11 reliability relation with its Weibull
parameters to the bearing template and the answer key.

If the gear train or the vehicle is changed, student work should be compared
with the answer key that the dashboard writes for that export
(`exports_design_ready/Answer_Key.md`). `docs/EXPECTED_RESULTS.md` describes the
default train only.
