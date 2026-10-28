# Instructor guide for SimDrive: EV Transmission Design

## Purpose and scope

This is a design project for third- and fourth-year students taking a Machine
Design or Design of Machine Elements course taught from *Shigley's Mechanical
Engineering Design*, 11th edition. Each part uses the chapters named in it, so
the parts can be released as those chapters are taught. The instructor generates
EV load data; students design a conceptual single-speed, two-stage helical
transmission using only the procedures of Shigley.

The vehicle and motor values are typical of a current rear-wheel-drive passenger
EV and are course inputs that describe no specific car.

Read the [assignment limitations](../student/ASSIGNMENT_BRIEF.md#scope-and-limitations)
before distributing results. A design that passes the course checks has not been
checked against every chart condition or production requirement;
`docs/EXPECTED_RESULTS.md` in the answer key gives the reference design's values
for these limits.

The dashboard rejects physically invalid inputs, including an ambient
temperature outside -40 to 60 degrees C, and does not overwrite saved Simulink
models.

The dashboard shows the vehicle and an enlarged view of the drive unit, both
animated at the current gear ratios with the gears to scale. Bearing spans are
drawn at 1.6 times true length for legibility; use the calculations for design
dimensions.

The schematic shows a motor and a separate transmission on the rear axle driving
the rear wheels, the layout of many rear-wheel-drive EVs. The transmission is
single speed with two stages on three parallel shafts in one plane: the input
pinion drives the stage-1 gear on the intermediate shaft, the stage-2 pinion on
the same shaft drives the output gear, and the output gear carries the
differential on the axle, which feeds a half-shaft to each rear wheel.

Students routinely conflate single-speed with single-stage, and the distinction
should be made in the first session. The car is single-speed, having one fixed
ratio and no shifting. The reduction is two-stage because 9:1 in a single pair
needs a driven gear larger than the road wheel (with the 20-tooth, 4 mm pinion:
a 794 mm gear against a 668 mm tire). The intermediate shaft that results
carries both meshes, and it is the shaft the students design.

## Choosing the gear train

The dashboard's gear-train panel sets both stages: pinion and gear teeth, the
normal module and the helix angle of each. The overall ratio is computed from
the teeth and shown read-only, and the vehicle simulation uses it, so a change
that moves the ratio needs a fresh run before export. The normal pressure angle
is locked at 20 degrees because the Shigley Chapter 14 helical geometry-factor
charts are drawn for 20 degrees only.

A train the Shigley procedure cannot rate is refused as it is typed, with the
rule it breaks: a pinion below the interference minimum, a module not on the
Chapter 13 preferred list, a tooth count or helix angle outside the printed
domain of the Chapter 14 geometry-factor charts, or a helix angle below 21.8
degrees, where no face width up to 5 p_t reaches the face-contact ratio of 2
that those charts assume.

With "key picks" ticked, the stage-2 module is chosen at export: the smallest
preferred module from the stage-1 module upward for which the key rates stage 2
with a face width from the larger of 3 p_t and 2 p_x (so that m_F is at least
2) up to 5 p_t. Students always receive a fully
prescribed train.

Every complete export then runs the worked solution on the exported data and
shows it on the Answer Key tab, and writes it to
`exports_design_ready/Answer_Key.md`. The key makes its own design choices by
rule (lowest admissible Q_v, narrowest passing face width, softest passing
Appendix A steel row, smallest passing bore, lightest passing bearing), so it is
valid for any train. If it cannot meet a target it names the reason and no
student package is built.

The key checks what the course assigns: AGMA bending and contact (Chapter 14),
DE-Goodman fatigue and static yield of the intermediate shaft (Chapters 6 and
7), and bearing L10 life (Chapter 11). It does not check everything a production
gearbox would need. Its limits, with the reasons, are listed in
[`docs/MathematicalModels.md`](MathematicalModels.md), Section 10.4 ("Not
checked by the course key"), among them shaft deflection and slope, the
bearings' static load rating at peak torque, fatigue from repeated full-throttle
launches, the stage-2 quality
number above the course speed, two-way tooth loading and the axial location of
the gears. Tell students which of these you expect them to discuss; they make
good report questions.

## Before class

1. Clone or download the repository.
2. Open MATLAB R2025b or newer and change to `instructor/`.
3. Run `Start_Here.mlx` and complete the dependency check.
4. Generate FTP-75, hill-climb, and drag-race cases with `InstructorApp` or
   `generateLoadCases`.
5. For a command-line run, run `buildStudentPackage` in `instructor/`. The
   dashboard does this automatically when exporting all three cases. Each build
   creates fresh contents in `student_package/` and a matching ZIP in
   `release/`; the instructor solution is excluded. Partial runs cannot produce
   a complete package.

Output folders are inside the repository whatever MATLAB's current folder is;
for a separate run folder, use
`InstructorApp(OutputRoot="absolute/output/path")`. Keep your own notes out of
`student_package/`, which each build replaces.

`main.mlx`, `generateLoadCases` and the answer key's `Solution_01` clear the
base workspace, so save your own variables first.

## What students receive

The `student_package/` folder, or the identical ZIP from `release/`:

- `SimDrive_Project_Brief.docx`, the project brief students read first
- `README.md` for the hand-out, explaining what each file is and where the data
  sits
- `Student_01_Load_Inputs.m` through `Student_04_Bearing_Selection.m`
- `ASSIGNMENT_BRIEF.md`
- `DESIGN_REPORT_TEMPLATE.md`
- `DATA_DICTIONARY.md`
- `computeShoulderNotchFactors.m`
- `LICENSE` and `LICENSE-docs`
- `exports_design_ready/`, sitting beside the templates

The dataset in the hand-out is the instructor export reduced for distribution.
Each case keeps its `ds_single` design scalars untouched and carries one
2000-point torque curve with a note saying what that curve is. For FTP-75 that
curve is the equivalent sinusoid that the Goodman calculation uses. The
full-resolution instructor export is written to `exports_design_ready/` at the
repository root when you run the load cases.

The `.m` files use MATLAB's plain-text Live Code format. They contain
explanatory text, Shigley equations, required output names, and comment-only
TODO cells. They contain no executable solution code.

Student 03 supplies the notch-factor function for the minimum-mass sweep and
asks students to check it against one shoulder they read off the charts by hand.

## What remains on the instructor side

- The Simulink model generator and Instructor App
- The completed solution in `instructor/solution/`
- Expected-result ranges
- The Shigley figures used to verify the digitized chart data (held by the
  instructor; not redistributed with this project)

How to use the reference solution is described in
[`instructor/solution/README.md`](../instructor/solution/README.md); keep it out
of the student package. The key and `docs/EXPECTED_RESULTS.md` are encrypted in
`instructor_answer_key.7z`, and the
[repository README](../README.md#the-reference-solution) explains how to request
the password and extract the archive. Do not share the password or the extracted
files with students. Varying the inputs by section (the dashboard recomputes the
key for any gear train) and grading reasoning, traceability and design decisions
remain the best protection.

Until the archive is extracted, the dashboard and `generateLoadCases` still run,
and the student package can still be built; the dashboard uses the typed stage-2
module, the command line uses 5 mm, and no answer key is written.

## Scoping the assignment

The project is built to be cut up. `Student_01` is the data handoff and is
always needed, because it is where the design torques and the gear geometry
enter the workspace. The three design parts that follow it are independent
submissions:

| Part | Template | Shigley chapters |
|---|---|---|
| Gear rating | `Student_02_Gear_Design.m` | 13 and 14 |
| Shaft design | `Student_03_Shaft_Design.m` | 6 and 7 |
| Bearing selection | `Student_04_Bearing_Selection.m` | 11 |

Assign one, two, or all three. A single part with a short report is a two- to
three-week assignment inside a machine design course. All three, with the full
design report, is a term project. Different sections or teams can take different
parts and then present to one another, which is closer to how the work is
divided in practice.

Cutting in partway works because the project ships a complete worked reference.
A student assigned only the bearing task does not need to have done the shaft
task: hand them the shaft reactions from `docs/EXPECTED_RESULTS.md` (in the
encrypted answer-key archive) as given data, exactly as a practicing engineer
receives loads from the group upstream. The same applies to starting at the
shaft with the mesh forces supplied. Say plainly in the assignment which numbers
are given and which are to be derived, because the derivation is what is
assessed (see [`ASSESSMENT_RUBRIC.md`](ASSESSMENT_RUBRIC.md)).

The load side is equally adjustable. Three duty cycles ship, and any one of them
can stand alone: the drag race is the peak-torque case, the hill climb is the
validation case (a hand-checkable steady state, with an optional finite-life
extension), and the FTP-75 city cycle is the fatigue and bearing-life case.
Assign one case, or give different cases to different teams and compare what
each one governs. Regenerating with different vehicle parameters is a single
instructor-side run, and [Assignment variation](#assignment-variation) below
lists what can be changed without changing what students calculate.

What ships is the full configuration of the project: the full vehicle, all three
duty cycles, both gear stages, the intermediate shaft and both its bearings,
with the input shaft as a worked extension, end to end, so that every smaller
assignment has complete, checked data behind it.

## Suggested delivery

The schedule below is the full project, all three parts, in six weekly meetings.
For a single-part assignment, take the two or three rows that apply. The
[prototype challenge](PROTOTYPE_CHALLENGE.md) runs on the same six weeks.

| Week | Topic | Student outcome |
|---|---|---|
| 1 | Load paths, the three vehicle cases, the hill-climb hand check | Verified design-input table |
| 2 | Helical gear geometry and forces | Gear geometry and mesh-force table |
| 3 | Shigley/AGMA gear rating | Bending/contact safety factors |
| 4 | Shaft layout, reactions, stress concentration and notch sensitivity | Moment diagrams; `Kt`, `Kts`, `q`, `qs`, `Kf`, `Kfs` |
| 5 | Endurance limit, DE-Goodman and static yield | Critical-section shaft checks |
| 6 | Rolling-contact bearings and integration | Bearing selection and final design review |

## What students calculate

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
  `C`/`C0`; `e` and `Y` come from the Shigley Chapter 11 table against `Fa/C0`.
  The exercise checks the nominal bore match, `L10`, and the catalog abutment
  diameter and corner radius against the shoulder, and asks for the static ratio
  of the floating bearing at peak torque (Student 04). It does not cover fits,
  retention or a static-capacity selection.
- The gear seats are plain sections: the press fit or keys that hold the gears
  are outside the project and are assumed to add no stress concentration, as
  stated in `Student_03` Task 1 and in
  [`MathematicalModels.md`](MathematicalModels.md), Section 9.2. A keyed seat is
  a natural extension: an end-milled keyseat carries the Chapter 7
  stress-concentration factors, which are harsher than the shoulder's, and it
  shows students how far a keyseat moves the governing section.
- Do not introduce alternative fatigue criteria, finite-element stress results,
  ISO gear-rating equations, or manufacturer-specific life-adjustment equations
  into the required solution.

## How the load cases were chosen

The launch case is an open-loop drag race rather than a speed-controlled highway
merge from 0 to 120 km/h. It serves the same purpose, which is to produce the
largest torque the transmission will ever see for the AGMA tooth stress and the
shaft yield check, and it does so without a speed target the controller has to
chase, so the peak is the motor's own limit and owes nothing to the PID gains.

Students do not run the Simulink model themselves. The vehicle simulation is
instructor-side in this release, for two practical reasons: one term is not long
enough to build the vehicle model and complete a full gearbox design, and
keeping the model on the instructor side lets you vary the loads between
sections without students editing model code. The instructor path is fully
scripted either way, through `generateLoadCases` or the GUI.

At this level that is a scoping decision, and it is the obvious place to extend
the project. A simple extension is to give students the model read-only and ask
them questions of it: which design torque moves when the vehicle mass changes,
which resistance term dominates at 30 and at 120 km/h, and what the model omits
that would matter. The counted rainflow spectrum already ships to students in
`ds_single.rf_data` and is documented in `DATA_DICTIONARY.md`, so students can
also be asked to reproduce the reduction themselves. The reduction is summarized
in [`FATIGUE_LOAD_REDUCTION.md`](FATIGUE_LOAD_REDUCTION.md).

## Assignment variation

Vary one or more of the following while retaining the same learning outcomes:

- Vehicle mass, drag or rolling resistance (dashboard or `main.mlx`)
- Motor torque, power or speed limit (dashboard or `main.mlx`)
- Gear train: teeth, modules and helix angles of both stages (dashboard)
- Hill angle. Grades far from 20 degrees can need a longer hill-climb run to
  settle (up to about 240 s); the answer key says so if the run has not settled.
- Target service distance: the 150,000 km life is a course default that an
  instructor may change through `life_km` in
  `instructor/solution/courseTargets.m` (students may not). Tell students, since
  the templates and brief quote 150,000 km.
- Required shaft steel or gear hardness range: state it in your project
  document; the templates leave these choices to the students.
- Approved bearing series: state it in your project document if you want to
  restrict the catalog students may choose from.

The project brief and a few template sentences describe the default car (1610
kg, 9:1, 20-degree grade). If you change the car or the gear train, tell
students that the values they design with are the ones in the exported data
(`Design_Summary.mat` and the three case files).

Reliability is not on that list. The whole project designs to 90 percent
reliability (`L10` for the bearings, `K_R = 0.85` for the gears, `k_e = 0.897`
for the shaft), and no equation in the shipped code consumes a different
target. Raising it means changing `K_R` and `k_e` and adding the Shigley Chapter
11 reliability relation with its Weibull parameters to the bearing template and
the answer key.

If you change the gear train or the vehicle, compare student work with the
answer key the dashboard writes for that export
(`exports_design_ready/Answer_Key.md`). `docs/EXPECTED_RESULTS.md` describes the
default train only.
