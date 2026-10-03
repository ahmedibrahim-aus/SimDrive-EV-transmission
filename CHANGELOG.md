# Changelog

All notable changes to **SimDrive: EV Transmission Design** are recorded here.
The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [4.0.0] - 2026-10-03

### Changed

- The transmission is single speed with two helical stages on three parallel
  shafts, 20:60 then 20:60 (G = 9 exactly), the layout of a production EV drive
  unit. The v3 single 9:1 mesh needed a 766 mm driven gear; the largest gear is
  now 383 mm. Drag-race and hill-climb loads are unchanged; the FTP-75 loads changed (see Fixed).
- Students rate both stages, design the intermediate shaft that carries them, and
  select its two bearings. The input shaft is a worked extension; the output
  shaft and differential are out of scope.
- The answer key is parametric. It makes its design choices by rule (Q_v by
  Eq. (14-29), face width inside 3p_t to 5p_t, softest Table A-21 row inside the
  180 to 400 HB range of Figs. 14-2 and 14-5, smallest passing bore, lightest
  passing bearing) and names the reason when a train cannot meet a target.
- J is read from digitized Figs. 14-7 and 14-8 (`computeHelicalJ`); bearings come
  from an SKF catalog table (`bearingCatalogue`, checked against SKF 17000/1 EN
  section 1.1; the v3 bearing ratings came from different sources and matched
  neither that catalog nor each other). Each member's cycle count is computed
  exactly for 150,000 km.
- The Fig. 14-8 multiplier wording in the student gear template now matches the
  key: read at the member's own tooth count, as in Example 14-5.

### Added

- The answer key, `docs/EXPECTED_RESULTS.md` and the tests that contain
  reference answers ship encrypted in `instructor_answer_key.7z` (AES-256).
  Instructors request the password; the dashboard, `generateLoadCases` and the
  student package work without it.
- Dashboard gear-train panel: teeth, module and helix angle of both stages, G
  computed from the teeth, a train that breaks a Shigley rule refused as it is
  typed, with the rule named, and an option for the key to choose the stage-2
  module.
- Answer Key tab and `exports_design_ready/Answer_Key.md`, produced by running
  the worked solution on every complete export. No student package is built if
  the key cannot meet a target.
- Two-stage cutaway schematic drawn from the current train: gears to scale,
  bearing spans enlarged.
- The EPA FTP-75 schedule is built in (`instructor/ftp75Schedule.m`) and is the
  default drive cycle; `ftpcol.txt` is no longer needed. An instructor can still
  supply another speed trace: its units are set in the dashboard (next to the
  file name) or by `ftp_units` in `main.mlx`, or read from a header such as
  `speed_kph`; a guess is shown as a dashboard warning. Traces must start at
  0 s with no negative speeds.
- The student templates end each part with a save step and start the next with
  a load step, so the four parts can be run in separate sessions. Student 04
  adds a bearing abutment check against the Student 03 shoulder.
- `tests/tAnswerKeyParametric.m` (in the encrypted archive): the key is either
  correct or names its reason over a sweep of modules, helix angles and tooth
  counts.
- `MathematicalModels.md` Section 10.4 lists what the course key does not check
  (shaft slope and deflection, bearing static rating, repeated launches, bending
  cycles per revolution, stage-2 Q_v above the course speed, two-way tooth
  loading, gear axial location), with the reasons, for use as extensions.

### Fixed

- **The dashboard, the answer key and the package builder now run on MATLAB
  without Java.** R2026b ships without a Java runtime, and three path lookups
  used `java.io.File`; they now use `dir`.
- **Five faults had corrupted every FTP-75 load since v1.** The final FTP-75
  design values are `T_mean_eq` 9.15, `T_alt_eq` 46.27 and `T_cubic_mean`
  44.05 N·m (v3: 151.9, 172.8 and 135.8 N·m). Drag race and hill climb are
  unchanged. The faults were found in a review of the teaching material, and
  `tModelSmoke` now checks FTP torque against the cycle's own acceleration
  demand.
  - The torque-envelope Saturation Dynamic block had its up/u/lo ports crossed,
    which turned it into a relay: any positive speed-loop command applied full
    available torque, so the motor chattered between zero and its limit about
    four times a second, even at steady cruise.
  - The regen switch was inverted, and the speed integrator wound below zero at
    every stop.
  - Regenerative braking multiplied by the drivetrain efficiency both ways, which
    overstated regen torque by about 1/eta^2. It now applies the efficiency on
    the motor side, F = G T/(eta R_w); the FTP-75 minimum moves from -93.5 to
    -88.4 N·m.
  - Two-thirds of the rainflow cycles were controller ripple. A second review
    reproduced the FTP-75 torque from the speed trace by hand and traced the
    remaining low design values to them. Cycles under 2 percent of the full
    torque range are now gated out.

  The peak FTP torque is now 110 N·m, and FTP tracking improves from 2.28 to
  0.54 km/h RMS.
- The corrected city duty is light, which changes which check governs the
  intermediate shaft and its bearings. The key's bearing candidates now include
  the next smaller bore, which is rejected on fit.
- Bearings use `T_cubic_mean`, the Shigley Sec. 11-7 Eq. (11-17) equivalent
  load, instead of the mean of the equivalent sinusoid, which understated the
  bearing load nearly fivefold. This reverses the 3.0.1 change.
- The hill climb now serves as a check on the simulation: students reproduce its
  steady torque by hand from the power-limited equilibrium (Student 01 Task 6),
  and an optional Student 03 extension finds how long the shaft survives a
  sustained full-power climb with the Shigley finite-life S-N line, Eqs.
  (6-11) to (6-15) and (6-59).
- The Marin surface factor uses the 11e Table 6-2 constants for a machined
  surface (3.04, -0.217) instead of the 10th-edition ones. Every shaft fatigue
  factor falls about 8 percent; the shaft geometry is unchanged.
- The motor has a speed limit, `n_max` = 16,000 rpm (about 224 km/h at G = 9),
  set in `main.mlx` and the dashboard. The available torque tapers to zero over
  the last 5 percent. The drag race now ends near 220 km/h instead of an
  unlimited 263 km/h; the design loads are unchanged.
- `Q_v` is checked against Eq. (14-29) at a stated course speed of 120 km/h
  (`courseTargets`), not at the motor base speed; `K_v` stays at base speed,
  where `T_peak` acts. Near top speed the stage-1 pinion would run past the
  Q_v = 11 limit of Fig. 14-9, so the course fixes the check speed. The higher
  stage-1 quality number lowers `K_v`, which narrows the stage-1 face and
  shortens the intermediate shaft.
- The shaft yield check applies K_f and K_fs, Shigley Eq. (7-15), not K_t.
- The documents now state the assumption that press fits and keys add no
  stress concentration (their design is outside the project; Shigley Sec. 7-8
  notes that they do raise the stress at the hub ends).
- The key's stage-1 face width now lies inside its own 3p_t to 5p_t band (v3
  used a face just above the upper limit).
- `C_pf` applies the Eq. (14-32) floor F/(10d) >= 0.05.
- The FTP-75 note in the student data quoted a stale mean of 155 N·m; it is now
  computed from the curve (about 10 N·m).
- The student `Design_Summary.mat` holds only the documented vehicle and gear
  data; the per-case summary with output-shaft torques is left out.
- The hill-climb hand check solves the steady state against the whole motor
  envelope, including the speed limiter, so it holds on any grade; a run that
  has not settled is reported as such, with the remedy, instead of as a
  mismatch. The dashboard allows hill-climb runs up to 600 s.
- The stage-1 gear force on the intermediate shaft is the stage-1 mesh force,
  2 T_in / d1, as Shigley treats a mesh; it had been taken about 1.5 percent
  low. The shaft geometry is unchanged.
- The Marin equation in Student 03 no longer carries a stray factor; the
  notch-sensitivity citations are Eq. (6-33) for q and Eq. (6-36) for the
  torsion fit; six, not four, Fig. A-15-7 entries are named as extrapolations.
- The key picks a quality number valid at both the Q_v check speed and the
  K_v rating speed. With the answer key locked, the dashboard's "key picks"
  option is off and the stage-2 module is typed.
- Load-case plots: axis colors match their lines, a legend is shown and the
  limit labels are no longer clipped. The dashboard and the command line now
  draw the same case and overview plots, and students no longer receive the
  raw FTP-75 trace in their FTP-75 plot.
- Export figures are never the current figure and every plotting call names
  its axes, so no stray blank "Figure 1" window can open during an export.
- The dashboard envelope legend now labels the right lines.
- `main.mlx` no longer closes every open Simulink model and figure; it closes
  only its own runtime model. Its output folder is fixed to the project, from
  any current folder, and its gear ratio comes from the default gear train.
- A fresh clone passes the dashboard test without first running `buildtool`.
- CI keeps test reports for failed runs only, and the parametric key test's
  unit check runs without simulated exports. The full-release job runs the
  dashboard tests on a virtual display and generates the load cases first, so
  the answer-key sweep runs too.

## [3.0.2] - 2026-09-16

### Fixed

- The dashboard schematic drew the pinion on the motor's own rotor shaft, inside
  a single housing that also enclosed the motor. That is not the architecture the
  students analyze, and it contradicted the answer key, which treats the input
  shaft as a discrete shaft on its own two bearings. The schematic now shows a
  motor and a separate transmission: the motor stands outside the housing and
  drives the transmission input shaft through a bolted coupling at the wall, and
  both gears, both shafts and all four bearings sit inside the housing.
- The four bearing stations are derived from the answer key rather than placed by
  eye, so the picture now matches the free body the students draw.
- Three labels added, INPUT SHAFT, TRANSMISSION and OUTPUT SHAFT, and color is
  now consistent: amber for the housing, blue for the motor, steel for the shafts
  and the driven gear.
- The instructor guide described the schematic as showing one motor and one
  gearbox, and said the differential was not drawn when it is. Corrected.

## [3.0.1] - 2026-09-16

Bearing life now runs on the same load reduction as the shaft. Nothing in the
vehicle, the gear pair, the duty cycles or the 150,000 km target moved, and the
instructor exports are unchanged, so `exports_design_ready/` from 3.0.0 still
reproduces every number.

### Changed

- Bearing rating life is taken at `T_mean_eq`, the mean of the FTP-75 equivalent
  sinusoid, applied as one constant equivalent radial load, in place of the
  revolution-weighted cubic mean `T_cubic_mean`. Shigley's Ch. 11 procedure is
  written for a constant load, which is what his worked problems solve, so a
  single constant equivalent load is the textbook case. It also puts the module
  on one load reduction: the same sinusoid sizes the shaft, through its mean and
  alternating components, and the bearings, through its mean. At 151.92 N·m
  against 135.82 N·m it is the more conservative of the two. (4.0.0 reverses
  this choice.)
- `T_cubic_mean` is still computed, still exported and still documented. It is no
  longer the required basis; it is the named extension for anyone assigning a
  variable-load bearing life.
- The input locating bearing moves up one series, because the previous choice
  no longer reached the 150,000 km target under the new load. The other three
  supports keep their bearings.
- `docs/EXPECTED_RESULTS.md` carries the revised reactions, thrust couples,
  Table 11-1 factors and rating lives, and records the 3.0.0 figures beside them.

## [3.0.0] - 2026-09-16

The answer key changes in this release, and with it every reference number for
the gear, shaft and bearing tasks. Any dataset or marked script issued from 2.1.x
should be regenerated. `docs/EXPECTED_RESULTS.md` carries the old and the new
figures side by side so an offering already under way can be reconciled.

The course level is also restated. This is a third and fourth year project for
students who have completed Mechanical Design or Design of Machine Elements, and
the templates no longer re-teach that material.

### Fixed

- The helical thrust force was applied as a normal stress but never as the
  bending couple it exerts at the gear station. Shigley takes moments about the
  bearings with the position vector reaching the tooth force at the pitch radius,
  so the couple `M_0 = W_a d/2 = T tan(psi)` belongs in the bending moment. It is
  a concentrated couple, so it adds on one side of the gear and subtracts on the
  other, and both shoulders are now checked. On the output shaft the couple is larger
  than the mesh bending moment. Correcting it drops the published output-shaft
  fatigue factor below its target, so the output journal and its bearing move
  up one size.
- The axial normal stress is now neglected in the fatigue check, which is what
  Shigley Ch. 7 prescribes when bending is present. It is kept in the static
  yield check. Here it was about 3 percent of the alternating bending stress.
- The selected shoulder had no flat seating face: the step was fully consumed
  by its fillet, with nothing for the bearing ring or gear to locate against. The search now requires a seating face at least as wide as the fillet.
- The alternating bending moment was never defined in the student material. Four
  defensible readings spanned a factor of 1.7. The template and the data
  dictionary now state that it is evaluated at `T_mean_eq + T_alt_eq` and treated
  as fully reversed.
- Bending strength was read off the AGMA Grade 1 line and contact strength off
  the Grade 2 line. Both are now Grade 1, and the materials are named against
  Table A-21.
- The geometry factor `J` was asserted as two literals. It is now read from
  Fig. 14-7 and corrected with the Fig. 14-8 multiplier, following the convention
  used in Shigley Example 14-5.
- Stress-cycle factors were applied at the same cycle count for both members. The
  gear turns nine times slower and now gets its own count.
- The overload factor was asserted at 1.25 with no service conditions stated. It
  is now Shigley's default of 1.00 for an unspecified application.
- The bearing task formed a static equivalent load attributed to Shigley Ch. 11.
  Shigley gives `C_0` but not the combined static factors, so the check is
  removed and `L_10` is the sole criterion.
- The templates told students to read `X`, `Y` and `e` from a catalog as
  constants, which is the error the answer key itself warns about. Table 11-1
  gives them against `F_a/C_0` and they must be interpolated.
- Every bearing candidate passed, and the bore said to be binding had been fixed
  in the previous notebook. The shaft now searches standard bores and hands the
  result to the bearing task, and each list carries a candidate that
  fails.
- The notch-factor tables carried rows at `r/d` below the range Shigley's figures
  actually draw, and the documented ordinate limit for Fig. A-15-7 was wrong. The
  extrapolated rows are gone and the tolerance is restated. Ultimate strengths
  outside the Eq. (6-35) fit range now raise an error instead of silently
  returning a notch sensitivity above one.
- The data dictionary said angles arrive in radians when the export ships
  degrees, and named three fields that do not exist under those names.

### Changed

- Student templates are re-pitched for third and fourth year. Roughly 1,300 words
  of material that re-taught completed Shigley content are removed, and the
  prerequisite is stated in the brief, both READMEs, the guide and the quick
  start.
- The answer key prints the Shigley like-basis comparison of `S_F` against
  `S_H^2` and states which mode governs, rather than leaving a single mixed
  column to be read.
- Reliability is stated as a deliberate choice: `L_10` at 90 percent is the
  design criterion for this project.
- The prose no longer implies the simulated duty cycle drives the gear rating.
  It drives the shaft and the bearings; the teeth are rated at `T_peak`, which is
  the single-point check Ch. 14 prescribes.

## [2.1.1] - 2026-09-12

### Changed

- The 3D car body in the instructor GUI schematic is redrawn. The old single
  loft read as a hull with rib lines; the body is now a lower shell up to a belt
  line and a separate greenhouse, with the glass laid on the greenhouse skin,
  wheel arches cut into the sections, and rounded nose and tail. The drive unit,
  wheels, battery, callouts, camera and animation are unchanged, and the
  reference results are unchanged.

## [2.1.0] - 2026-09-12

The reference results change in this release. Any dataset issued from 2.0.0
should be regenerated, and `docs/EXPECTED_RESULTS.md` carries both the old and
the new numbers so an offering already in progress can be reconciled.

### Fixed

- `check_dependencies` still listed the v1.x `.mlx` file names and reported nine
  failures on a clean checkout, which is the first thing an adopting instructor
  runs. It now lists the plain-text templates and the `Solution_*` answer key,
  reports the bundled mph speed trace as a pass with a note rather than a
  warning, and leaves the caller's workspace alone. A test runs it and asserts
  that nothing is flagged.
- The student templates told students to place `exports_design_ready` one level
  above the `student/` folder, while the hand-out places it beside them. The
  template, the student README and `docs/QUICKSTART.md` now describe the folder
  as it is shipped.
- The AGMA quality number in the answer key was below what Shigley Eq. (14-29)
  allows for the pitch-line velocity of the mesh. It is now raised to meet that
  limit, the Eq. (14-29) check is computed and printed, and the same check is
  set as a task in `Student_02`. `K_v` falls and the gear safety factors rise.
- The bearing solution held `e` at 0.30 and `Y` at 1.60 for every candidate.
  Both are now interpolated from Shigley Table 11-1 against `F_a/C_0`. The
  rating lives fall but stay above the 150,000 km target. Static factors are
  unchanged.
- The alternating axial stress now carries the 0.85 divisor printed in
  Eq. (6-66), on both shafts. The shaft fatigue factors change only in the
  third decimal place.
- `main.mlx` writes the canonical `approach-a-equivalent-sinusoid` method name
  itself, so a direct notebook run is stamped the same way as a
  `generateLoadCases` run.
- Notch sensitivity was described as digitized from Figures 6-26 and 6-27. It is
  evaluated from the Eq. (6-35) curve fits for the Neuber constant; only the
  three `Kt` surfaces are digitized. Corrected wherever it appeared.
- `docs/MathematicalModels.md` said students extract the mean and alternating
  loads and see the sinusoid against the raw FTP-75 trace. Both are
  instructor-side. Sections 2.2 and 8.2 are rewritten, and the section headings
  that named AGMA 2101 and SKF as the authority now use the module's own
  boundary wording.
- `LICENSE-docs` listed `MathematicalModels.md` at the repository root, where it
  has not been since the 2.0.0 restructure.
- The GUI and the command-line generator wrote different `ds_single` structs.
  The GUI packed its plotting traces into the exported design-value struct, so
  a GUI export stored every signal twice and put a 1 ms trace inside
  `Design_Summary.mat`, which came to 70 MB against the command line's 0.05 MB.
  Both paths now write the same eleven design values, and a GUI export is
  46 MB rather than 114 MB. The two paths agree to the last printed digit on
  every design quantity, which is what `docs/QUICKSTART.md` has always claimed.
- The "INSTRUCTOR FLOW" caption in the GUI was drawn under the step strip.

### Changed

- `tools/buildStudentPackage.m` is now the single source of the student
  hand-out. It reduces the instructor export to one binned torque curve per case
  alongside the untouched design scalars, refreshes `student_package/` from it,
  and zips that same folder to `release/`. The browsable folder and the
  distributed archive can no longer differ, and the archive is about 1 MB rather
  than 67 MB. Previously no tracked code produced the tracked folder and the
  ZIP carried a different file schema.
- `student_package/` is described in `README.md`, `Contents.m`,
  `docs/QUICKSTART.md` and `docs/INSTRUCTOR_GUIDE.md`. None of them mentioned it
  before.
- The instructor export drops the three controller diagnostic traces nothing
  downstream reads. `FTP75_Outputs.mat` falls from 67.8 MB to 46.3 MB.
- The gears are stated to be interference-fitted with no keyway, in
  `Student_03`, the answer key and the instructor guide, with the keyseat
  variant named as an extension.
- The face width is justified against the `3p_t` to `5p_t` guidance the
  template gives, in both the key and the template.
- `docs/INSTRUCTOR_GUIDE.md` records the two departures from the funded
  proposal: the Highway Merge case is delivered as the open-loop Drag Race, and
  the vehicle simulation is instructor-side by design.
- `student/DATA_DICTIONARY.md` explains why the drag-race plot reaches
  263 km/h.
- The Word project brief is regenerated by `tools/build_project_brief.py`, now
  tracked with the render it embeds. Document properties are set explicitly, so
  the file no longer carries the python-docx template's author, description,
  2013 dates or application string. `CONTRIBUTING.md` documents `python-docx` as
  a maintainer dependency.

### Added

- `tests/tEngineeringBenchmarks.m` gains independent rebuilds of the
  Eq. (14-29) velocity limit, the AGMA rating chain and the Table 11-1
  interpolation, checked against the refreshed reference values.
- `tests/tRequiredFiles.m` runs `check_dependencies` and asserts a clean report.
- `tests/tTeachingPackage.m` asserts that the archive carries the project brief,
  that the packaged FTP-75 case contains its torque curve, and that the hand-out
  folder and the archive hold the same files.

### Removed

- `docs/EV_Gearbox_v2_Overview_5_Slides.pptx` and `.pdf`, and
  `tools/build_overview_deck.py`. The deck was an internal progress report
  carrying a release-readiness score and a stale test count, not course
  material.
- The git-reconciliation section of `docs/release-checklist.md`, which was a
  working note about branch history.

## [2.0.0] - 2026-09-02

### Added
- Cutaway 3D powertrain view (`instructor/PowertrainView3D.m`) on the instructor
  dashboard, replacing the 2D side schematic. The wheels, pinion, and driven
  gear turn at their true relative rates, so the 9:1 reduction is visible.
- MathWorks EV Gearbox Design & Prototype Challenge brief and rubric
  (`docs/PROTOTYPE_CHALLENGE.md`), completing the prototype deliverable.
- License files are now included in the generated student package.
- Plain-text MATLAB Live Code student templates with comment-only TODO cells,
  required output names, units, and Shigley 11e scope prompts.
- Instructor guide, assignment brief, assessment rubric, report template, data
  dictionary, Approach-A contract, and Shigley equation map.
- Student-only ZIP builder, MATLAB build-tool tasks, GitHub Actions, engineering
  hand-calculation tests, and temporary-copy integration validation.

### Changed
- Locked the course to the single Approach-A FTP-75 equivalent-sinusoid path.
- Recorded Shigley 11e Figures A-15-7, A-15-8, A-15-9, 6-26, and 6-27 as the
  source of the shaft stress-concentration and notch-sensitivity data.
- Separated bending/axial notch sensitivity `q` from torsional sensitivity `qs`.
- Reframed AGMA and bearing calculations as the procedures presented in Shigley;
  manufacturer catalogs supply component data only.

### Fixed
- Removed claims that the shoulder chart surfaces are assumed placeholders.
- Release tests no longer overwrite the working repository's generated data.

## [1.1.0] - 2026-06-22

### Changed
- Rebuilt the student shaft exercise as a **stepped-shaft minimum-mass** design:
  per-section DE-Goodman fatigue + static yield at each shoulder and the gear seat,
  a bending-moment diagram, a scaled shaft schematic, total-mass calculation, and
  journal diameters constrained by the selected bearing bore. The worked solution
  now sweeps feasible `D/d` and `r/d` shoulder ratios and computes `K_t`, `K_ts`,
  `q`, `K_f`, and `K_fs` through a helper with an interim assumed chart surface.
  The design is not unique, and many valid stepped shafts satisfy the same targets.
- Raised the Hill Climb stop time from 15 s to 60 s so the vehicle reaches its
  grade-limited terminal velocity; `T_steady` is now a settled sustained-load value
  (late-window speed std ~0.5 km/h) rather than a still-accelerating reading.
- Reorganized the repository into `instructor/`, `student/`, and `docs/` folders to
  separate the two audiences.
- Converted the instructor scripts to interactive Live Scripts:
  `main.m` → `instructor/main.mlx`, `check_dependencies.m` →
  `instructor/check_dependencies.mlx`, and folded `run_instructor_app.m` into
  `instructor/Start_Here.mlx` (preflight check + launch).
- The student workflow is now pure no-code Live Script templates; added
  `instructor/solution/Student_00_Run_All.mlx` to run the worked answer key in sequence.
- Exports now land in a single `exports_design_ready/` folder at the repository
  root, shared between the instructor and student sides.
- The interactive `.mlx` interface and release validation target **MATLAB R2025a+**.
  Older releases may run parts of the programmatic engine but are not supported.

### Fixed
- The instructor "STUDENT DESIGN OUTPUTS" summary table rendered empty because of a
  string-in-cell `strcmp` lookup (`strcmp({"FTP75"},"FTP75")` returns `0`). Switched
  to a string-array comparison so the table populates. Computed values and exported
  `.mat` files were always correct, so this was a display-only bug.

### Removed
- Redundant `student_solution/*.m` batch companions (`load_inputs.m`,
  `gear_design.m`, `shaft_design.m`, `bearing_design.m`, `run_all.m`). The runnable
  worked logic now lives in `instructor/solution/Student_*.mlx`; `student/` contains
  no-code templates.

### Added
- `tests/`, a `matlab.unittest` suite: core-math unit tests (FTP-75 loading, plot
  binning, bearing cubic-mean torque, rainflow fatigue reduction), a Simulink
  build + short-simulation smoke test, file-layout checks, no-code student-template
  checks, and worked-solution readiness checks, plus `run_all_tests.m` and
  `validate_release.m`.
- Tests are run locally with `validate_release` before each release (the repository
  was private at 1.1.0, so GitHub-hosted CI was not used; CI was enabled in 2.0.0).

## [1.0.0] - 2026
- Initial release. Simulink 1-DOF EV longitudinal model generating FTP-75, Hill
  Climb, and Drag Race motor torque/speed histories for single-stage helical
  gearbox design: AGMA 2101 gear stress, Shigley modified-Goodman shaft fatigue,
  and SKF L10 bearing life. Programmatic Simulink model and instructor GUI; guided
  student Live Scripts; full physics/assumptions reference.
