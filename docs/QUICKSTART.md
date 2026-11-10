# Quick start guide for instructors

This guide describes the steps from download to student-ready files, which
require approximately 10 minutes.

## 1. First-time setup

In MATLAB, run:

```matlab
cd path/to/SimDrive-EV-transmission/instructor
check_dependencies
```

This function checks the MATLAB release (R2025b or newer), Simulink and the
Signal Processing Toolbox. It prints one line when all three are present and
otherwise stops with an error that names the missing product.

`Start_Here` runs this check and then opens the dashboard in one step.

## 2. Run the simulation

Two options are available. Both write the same files with the same design values
and plots of the same form (both generate them through `SimDriveCore`). The
command line also adds `*_out` shaft-torque fields to `ds` in
`Design_Summary.mat`. The command line always uses the default 20:60, 20:60 gear
train, and a different train can be set only in the dashboard.

### Option A: dashboard

```matlab
app = InstructorApp();
```

- Left panel: vehicle mass, motor specifications, tire radius and profile,
  ambient temperature. All parameters are editable, and the envelope preview
  updates in real time.
- Right panel: select which load cases to run (all three are enabled by
  default), set the gear train of both stages (or retain the defaults), then
  select **Run load cases**.
- When the run is complete, the summary cards display the principal design
  values and the result tabs contain the plots.
- Select **Export student files** to write the data of the run. When all three
  cases have been run, the export also builds a new student folder and ZIP
  archive. The export uses the inputs of the last run, so the load cases must be
  rerun after any input is changed.

### Option B: command line

Edit the parameter block at the top of `main.mlx`, then run:

```matlab
generateLoadCases
```

The outputs are written directly to `exports_design_ready/` with the default
gear train. `main.mlx` should not be run on its own before the student package
is built, because `generateLoadCases` adds the two-stage gear train that the
package requires. `generateLoadCases` runs `main.mlx` in the base workspace and
clears that workspace, so existing variables should be saved first.

## 3. Exported files

After a run, `exports_design_ready/` at the repository root contains the
complete instructor export:

| File | Contents |
|---|---|
| `FTP75_Outputs.mat` | Torque/speed timeseries; `ds_single` with T_mean_eq, T_alt_eq, cycle distance and T_cubic_mean (bearing load) |
| `HillClimb_Outputs.mat` | Torque/speed timeseries; `ds_single` with T_ss_mean (T_steady) |
| `DragRace_Outputs.mat` | Torque/speed timeseries; `ds_single` with T_peak |
| `Design_Summary.mat` | Scalar design values (`ds`), gear geometry and vehicle parameters. Students receive a reduced copy with the vehicle and gear data only |
| `*.png` | Torque and speed plots for each case |

Each case file also contains a `ds_single` struct with all the design values for
that case.

This folder is the working output of the instructor. It contains every simulated
signal at a 1 ms time step and occupies tens of megabytes. Students therefore
receive a reduced dataset, which is built from it in the next step.

## 4. Build and distribute the student hand-out

```matlab
buildStudentPackage
```

The dashboard calls the same builder automatically on a complete export. After
command-line generation, it must be called explicitly as above. The builder
reads the new `exports_design_ready/`, reduces each case to one torque curve of
2000 points together with the unmodified `ds_single` scalars, and writes the
result into `student_package/` at the repository root. It then writes a ZIP of
that same folder to `release/`. The tracked folder and the ZIP therefore always
hold the same files.

Each build replaces the contents of `student_package/` except its `README.md`
and `SimDrive_Project_Brief.docx`, so course constraints should be placed in the
brief and other notes kept elsewhere. In a git clone, a rebuild shows the data
files in `student_package/exports_design_ready/` as modified even when the
numbers are unchanged, because MATLAB writes a new timestamp into each file.

Students receive either the `student_package/` folder or the ZIP archive. The
data folder is located *beside* the templates within the package, so the package
can be copied to any location and the relative path `exports_design_ready/`
still resolves:

```
student_package/            <-- distributed to students
SimDrive_Project_Brief.docx README.md ASSIGNMENT_BRIEF.md DATA_DICTIONARY.md
DESIGN_REPORT_TEMPLATE.md Student_01_Load_Inputs.m Student_02_Gear_Design.m
Student_03_Shaft_Design.m Student_04_Bearing_Selection.m
computeShoulderNotchFactors.m LICENSE, LICENSE-docs exports_design_ready/
Design_Summary.mat FTP75_Outputs.mat HillClimb_Outputs.mat DragRace_Outputs.mat
*.png
```

Even with the archive extracted in the repository folder, the answer key is
never copied into the package.

## 5. Student tasks

1. `Student_01_Load_Inputs.m` loads the `.mat` files, places the design torques
   and gear geometry in the workspace, and computes intermediate- and
   output-shaft torques.

2. `Student_02_Gear_Design.m` covers AGMA bending and contact stress for both
   gear stages at T_peak. Students choose face widths, materials and rating
   factors and iterate until the bending and contact safety factors reach 1.5
   and 1.2 on all four gears.

3. In `Student_03_Shaft_Design.m` students design the stepped intermediate
   shaft, which carries both gear stages, for minimum mass: DE-Goodman fatigue
   (T_mean_eq / T_alt_eq) and static yield (T_peak) at each critical section,
   with both helix thrust couples. The input shaft is an optional extension.

4. `Student_04_Bearing_Selection.m` covers bearing selection for the
   intermediate shaft from a manufacturer's catalog (the reference solution uses
   SKF) at T_cubic_mean, the Shigley Chapter 11 equivalent load of the FTP-75
   duty. Students interpolate `e` and `Y` from the Shigley Chapter 11 table for
   each candidate.

The templates contain comment-only `TODO` cells, and students write the code
from the equations given. Students also verify the simulation by hand
calculation in `Student_01` (the hill-climb torque). The use of the reference
solution is described in
[`instructor/solution/README.md`](../instructor/solution/README.md), and the
solution must be kept out of the student package. The worked solution is sent to
instructors by email (see [The reference
solution](../README.md#the-reference-solution) in the README). Once the archive
is extracted in the repository folder, each complete export also writes
`exports_design_ready/Answer_Key.md` for the exported gear train.

## 6. Summary of design values

All torques are on the input shaft (motor side). For the intermediate shaft, the
torque is multiplied by i1 x sqrt(eta_dt), where i1 is the stage-1 ratio N2/N1.
For the output shaft, it is multiplied by G x eta_dt.

| Value | Load case | Application |
|---|---|---|
| T_peak | Drag race | Gear stress, shaft yield |
| T_mean_eq | FTP-75 | Shaft fatigue (Goodman mean) |
| T_alt_eq | FTP-75 | Shaft fatigue (Goodman alternating) |
| T_cubic_mean | FTP-75 | Bearing L10 equivalent load (Shigley Chapter 11) |
| ftp_distance_m | FTP-75 | Distance of one cycle (reference only) |
| T_steady | Hill climb | Hand check of the simulation; finite-life extension |

## 7. Customization

The vehicle parameters are in the block at the top of `main.mlx` and in the
dashboard. Mass, drag coefficient, tire radius, motor torque, power and speed
limit are all editable. `validation/run_zero_to_100.m` gives the 0-100 km/h time
of the vehicle (see [`validation/README.md`](../validation/README.md)).

The EPA FTP-75 schedule is built in (`instructor/ftp75Schedule.m`) and is used
whenever no file is given. To use another cycle, select **Browse** in the
dashboard or set `ftp_file` in `main.mlx` to a two-column text file of time [s]
and speed, starting at 0 s. Specify the speed units with the drop-down list next
to the file name in the dashboard, or with `ftp_units = "kph"` (or `"mph"`) in
`main.mlx`. With the "auto" setting, a header that names the units (for example
`time_s,speed_kph`) determines them. Without a header, a trace that never
exceeds 75 is interpreted as mph and the dashboard displays a warning.

The gear train is set in the gear-train panel of the dashboard, which takes the
tooth numbers, module and helix angle of both stages. The ratio G is computed
from the tooth numbers. A train that the Shigley charts cannot rate is rejected,
and the reason is stated. With "key picks" selected (available once the answer
key is extracted), the export selects the stage-2 module. A change of ratio
requires a new run before export.

FTP-75 fatigue loads are reduced to one equivalent sinusoid by rainflow
counting, which requires the Signal Processing Toolbox. Students receive its
mean and alternating torques and do not choose a reduction method.

The hill grade is `theta_hill_deg` in `main.mlx` or the dashboard. The default
is 20 degrees.

The scope of the assignment is also adjustable. The gear, shaft and bearing
parts are separable submissions, and any one of the three load cases can stand
alone. See "Scoping the assignment" in
[`docs/INSTRUCTOR_GUIDE.md`](INSTRUCTOR_GUIDE.md), and see
[`docs/ASSESSMENT_RUBRIC.md`](ASSESSMENT_RUBRIC.md) for the assessment criteria.

## 8. Troubleshooting

| Problem | Resolution |
|---|---|
| `check_dependencies` stops with an error | Install the product it names or update MATLAB |
| FTP tracking RMS > 5 km/h | The PID speed-controller gains may require tuning for the vehicle; increase `Kp` in `main.mlx` (the dashboard uses the default gains) |
| "Select at least one load case" alert | Select at least one load case |
| Students cannot locate the `.mat` files | Confirm that `exports_design_ready/` is beside the templates in the hand-out folder |
| Rainflow not available | Install the Signal Processing Toolbox; FTP-75 fatigue extraction requires `rainflow()` |
