# Quick start guide for instructors

This gets you from download to student-ready files in about 10 minutes.

## 1. First-time setup

Open MATLAB, navigate to the project's `instructor/` folder, and run:

```matlab
cd path/to/SimDrive-EV-transmission/instructor
check_dependencies
```

This checks the MATLAB release (R2025b or newer), Simulink and the Signal
Processing Toolbox. It prints one line when all three are present and otherwise
stops with an error that names the missing product.

`Start_Here` runs this check and then opens the dashboard in one step.

## 2. Run the simulation

You have two options. They write the same files with the same design numbers and
the same plots (both draw them through `SimDriveCore`); the command line also
adds `*_out` shaft-torque fields to `ds` in `Design_Summary.mat`. The command
line always uses the default 20:60, 20:60 gear train; change the train in the
dashboard.

### Option A: dashboard

```matlab
app = InstructorApp();
```

- Left panel: vehicle mass, motor specs, tire radius and profile, ambient
  temperature. All parameters are editable; the envelope preview updates in real
  time.
- Right panel: select which load cases to run (all three are enabled by
  default), set the gear train of both stages (or keep the defaults), then press
  **Run load cases**.
- When it finishes, the stat cards show the key design values and the result
  tabs have plots.
- Click **Export student files** to write the run's data. When all three cases
  were run, this also builds a fresh student folder and ZIP. Export uses the
  inputs of the last run, so rerun after changing anything.

### Option B: command line

```matlab
generateLoadCases
```

Edit the parameter block at the top of `main.mlx`, then run `generateLoadCases`.
Outputs go straight to `exports_design_ready/` with the default gear train.
`generateLoadCases` runs `main.mlx` in the base workspace, which clears it, so
save your own variables first.

## 3. What gets exported

After running, `exports_design_ready/` at the repository root holds the full
instructor export:

| File | Contents |
|---|---|
| `FTP75_Outputs.mat` | Torque/speed timeseries, T_mean_eq, T_alt_eq, cycle distance, and T_cubic_mean (bearing load) |
| `HillClimb_Outputs.mat` | Torque/speed timeseries, T_steady |
| `DragRace_Outputs.mat` | Torque/speed timeseries, T_peak |
| `Design_Summary.mat` | Scalar design values (`ds`), gear geometry and vehicle parameters. Students receive a reduced copy with the vehicle and gear data only |
| `*.png` | Torque and speed plots for each case |

Each case file also contains a `ds_single` struct with all the design values for
that case.

This folder is the instructor's working output. It carries every simulated
signal at 1 ms and runs to tens of megabytes, so students receive a reduced
dataset built from it in the next step.

## 4. Build and distribute the student hand-out

```matlab
buildStudentPackage
```

The dashboard calls this same builder automatically on a complete export; after
command-line generation, call it explicitly as above. It reads the fresh
`exports_design_ready/`, reduces each case to one torque curve of 2000 points
alongside the untouched `ds_single` scalars, and writes the result into
`student_package/` at the repository root. It then writes a ZIP of that same
folder to `release/`. The tracked folder and the ZIP therefore always hold the
same files.

Each build replaces the contents of `student_package/`, so keep personal notes
elsewhere. In a git clone, a rebuild shows the data files in
`student_package/exports_design_ready/` as modified even when the numbers are
unchanged, because MATLAB writes a new timestamp into each file.

Give students either the `student_package/` folder or the ZIP. The data sits
*beside* the templates inside it, so a student can copy the folder anywhere and
the relative path `exports_design_ready/` resolves:

```
student_package/            <-- what you hand out
  SimDrive_Project_Brief.docx
  README.md
  ASSIGNMENT_BRIEF.md
  DATA_DICTIONARY.md
  DESIGN_REPORT_TEMPLATE.md
  Student_01_Load_Inputs.m
  Student_02_Gear_Design.m
  Student_03_Shaft_Design.m
  Student_04_Bearing_Selection.m
  computeShoulderNotchFactors.m
  LICENSE, LICENSE-docs
  exports_design_ready/
    Design_Summary.mat
    FTP75_Outputs.mat
    HillClimb_Outputs.mat
    DragRace_Outputs.mat
    *.png
```

The answer key in `instructor/solution/` is never copied into the package.

## 5. What students do

1. `Student_01_Load_Inputs.m` loads the `.mat` files, puts design torques and
   gear geometry into the workspace, and computes intermediate- and output-shaft
   torques.

2. `Student_02_Gear_Design.m` covers AGMA bending and contact stress for both
   gear stages at T_peak. Students choose face widths, materials and rating
   factors and iterate until bending reaches 1.5 and contact 1.2 on all four
   gears.

3. In `Student_03_Shaft_Design.m` students design the stepped intermediate
   shaft, which carries both gear stages, for minimum mass: DE-Goodman fatigue
   (T_mean_eq / T_alt_eq) and static yield (T_peak) at each critical section,
   with both helix thrust couples. The input shaft is an extension.

4. `Student_04_Bearing_Selection.m` covers bearing selection for the
   intermediate shaft from a manufacturer's catalog (the reference solution uses
   SKF) at T_cubic_mean, the Shigley Chapter 11 equivalent load of the FTP-75
   duty. Students interpolate `e` and `Y` from the Shigley Chapter 11 table for
   each candidate.

The templates contain comment-only `TODO` cells: students write the code from
the equations given. Students also check the simulation by hand in `Student_01`
(the hill-climb torque). For how to use the reference solution, see
[`instructor/solution/README.md`](../instructor/solution/README.md), and keep it
out of the student package. The worked solution ships encrypted (see
[The reference solution](../README.md#the-reference-solution) in the README);
once extracted into `instructor/solution/`, each complete export also writes
`exports_design_ready/Answer_Key.md` for the exported gear train.

## 6. Key design values at a glance

All torques are on the input shaft (motor side). For the intermediate shaft
multiply by i1 x sqrt(eta_dt), where i1 is the stage-1 ratio N2/N1; for the
output multiply by G x eta_dt.

| Value | From which case | Used for |
|---|---|---|
| T_peak | Drag race | Gear stress, shaft yield |
| T_mean_eq | FTP-75 | Shaft fatigue (Goodman mean) |
| T_alt_eq | FTP-75 | Shaft fatigue (Goodman alternating) |
| T_cubic_mean | FTP-75 | Bearing L10 equivalent load (Shigley Chapter 11) |
| ftp_distance_m | FTP-75 | Scale bearing life to 150,000 km |
| T_steady | Hill climb | Hand check of the simulation; finite-life extension |

## 7. Customizing

The vehicle parameters are in the block at the top of `main.mlx` and in the GUI.
Mass, drag coefficient, tire radius, motor torque, power and speed limit are all
editable.

The EPA FTP-75 schedule is built in (`instructor/ftp75Schedule.m`) and is used
whenever no file is given. To use another cycle, press **Browse** in the
dashboard or set `ftp_file` in `main.mlx` to a two-column text file of time [s]
and speed, starting at 0 s. State the speed units with the dropdown next to the
file name in the dashboard, or `ftp_units = "kph"` (or `"mph"`) in `main.mlx`.
On "auto" a header naming the units (for example `time_s,speed_kph`) decides;
with no header, a trace that never exceeds 75 is taken as mph and the dashboard
shows a warning.

The gear train is set in the dashboard's gear-train panel: the teeth, module and
helix angle of both stages. The ratio G is computed from the teeth; trains
Shigley's charts cannot rate are refused with the reason. With "key picks"
ticked (available once the answer key is extracted), the export chooses the
stage-2 module. A change of ratio needs a fresh run before export.

FTP-75 fatigue loads are reduced to one equivalent sinusoid by rainflow
counting, which needs the Signal Processing Toolbox. Students receive its mean
and alternating torques and do not choose a reduction method.

The hill grade is `theta_hill_deg` in `main.mlx` or the GUI. Default is 20
degrees.

How much you assign is also adjustable. The gear, shaft and bearing parts are
separable submissions, and any one of the three duty cycles can stand alone. See
"Scoping the assignment" in [`docs/INSTRUCTOR_GUIDE.md`](INSTRUCTOR_GUIDE.md),
and see [`docs/ASSESSMENT_RUBRIC.md`](ASSESSMENT_RUBRIC.md) for what to assess.

## 8. Troubleshooting

| Problem | Fix |
|---|---|
| `check_dependencies` stops with an error | Install the product it names or update MATLAB |
| FTP tracking RMS > 5 km/h | The PID speed-controller gains may need tuning for your vehicle; raise `Kp` in `main.mlx` (the dashboard uses the default gains) |
| Simulation runs but plots are empty | Make sure at least one load case is checked |
| Students cannot find the `.mat` files | Check that `exports_design_ready/` is beside the templates in the hand-out folder |
| Rainflow not available | Install the Signal Processing Toolbox; FTP-75 fatigue extraction requires `rainflow()` |
