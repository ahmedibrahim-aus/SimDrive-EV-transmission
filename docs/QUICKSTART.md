# Quick Start Guide for Instructors

This gets you from download to student-ready files in about 10 minutes.

SimDrive: EV Transmission Design is a design project for third- and fourth-year
students taking a Shigley-based Machine Design / Design of Machine Elements course.

---

## 1. First-Time Setup

Open MATLAB, navigate to the project's `instructor/` folder, and run:

```matlab
cd path/to/SimDrive-EV-transmission/instructor
check_dependencies
```

This checks your MATLAB version, Simulink, toolboxes, and the built-in FTP-75 schedule. Fix anything marked FAIL before proceeding. WARN items do not stop the module from running.

Tip: `Start_Here` runs this check and then opens the dashboard in one step.

---

## 2. Run the Simulation

You have two options. They write the same files with the same design numbers and
the same plots (both draw them through `SimDriveCore`); the command line also
adds `*_out` shaft-torque fields to `ds` in `Design_Summary.mat`. The command line always uses the default 20:60, 20:60
gear train; change the train in the dashboard.

### Option A: GUI

```matlab
app = InstructorApp();
```

- Left panel: vehicle mass, motor specs, tire radius and profile, ambient temperature. All parameters are editable; the envelope preview updates in real time.
- Right panel: select which load cases to run (all three are enabled by default), set the gear train of both stages (or keep the defaults), then press **Run load cases**.
- When it finishes, the stat cards show the key design values and the result tabs have plots.
- Click **Export student files** to write the completed run's data and automatically build a fresh student folder and ZIP when all three cases were run. Later control edits do not change the saved run; rerun to use changed inputs. Partial runs export data only and cannot create a complete student package.

### Option B: Command line

```matlab
generateLoadCases
```

Edit the parameter block at the top of `main.mlx`, then run `generateLoadCases`. Outputs go straight to `exports_design_ready/` with the default gear train. `generateLoadCases` runs `main.mlx` in the base workspace, which clears it, so save your own variables first.

---

## 3. What Gets Exported

After running, `exports_design_ready/` at the repository root holds the full
instructor export:

| File | Contents |
|---|---|
| `FTP75_Outputs.mat` | Torque/speed timeseries, T_mean_eq, T_alt_eq, cycle distance, and T_cubic_mean (bearing load) |
| `HillClimb_Outputs.mat` | Torque/speed timeseries, T_steady |
| `DragRace_Outputs.mat` | Torque/speed timeseries, T_peak |
| `Design_Summary.mat` | Scalar design values (`ds`), gear geometry and vehicle parameters. Students receive a reduced copy with the vehicle and gear data only |
| `*.png` | Torque and speed plots for each case |

Each case file also contains a `ds_single` struct with all the design values for that case.

This folder is the instructor's working output. It is not what students receive;
it carries every simulated signal at 1 ms and runs to tens of megabytes. The
student dataset is reduced from it in the next step.

---

## 4. Build and Distribute the Student Hand-Out

```matlab
cd ../tools
buildStudentPackage
```

The dashboard calls this same builder automatically on a complete export;
after command-line generation, call it explicitly as above. It reads the fresh
`exports_design_ready/`, reduces each case to one torque curve of 2000 points
alongside the untouched `ds_single` scalars, and writes the result into
`student_package/` at the repository root. It then writes a ZIP of that same
folder to `release/`. The tracked folder and the ZIP therefore always hold the
same files.

Every build starts from fresh staging contents. The builder checks that all
three cases match the current summary and refuses unrelated content in the
destination. Keep personal notes outside `student_package/`.

Give students either the `student_package/` folder or the ZIP. The data sits
*beside* the templates inside it, so a student can copy the folder anywhere and
the relative path `exports_design_ready/` resolves:

```
student_package/            <-- what you hand out
  EV_Gearbox_Project_Brief.docx
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

---

## 5. What Students Do

1. **`Student_01_Load_Inputs.m`**: loads the `.mat` files, puts design torques and gear geometry into the workspace, computes intermediate- and output-shaft torques.

2. **`Student_02_Gear_Design.m`**: AGMA bending and contact stress for both gear stages at T_peak. Students choose face widths, materials and rating factors and iterate until bending reaches 1.5 and contact 1.2 on all four gears.

3. **`Student_03_Shaft_Design.m`**: design the **stepped** intermediate shaft, which carries both gear stages, for **minimum mass**: DE-Goodman fatigue (T_mean_eq / T_alt_eq) and static yield (T_peak) at each critical section, with both helix thrust couples. The input shaft is an extension.

4. **`Student_04_Bearing_Selection.m`**: SKF bearing selection for the intermediate shaft at T_cubic_mean, the Shigley Sec. 11-7, Eq. (11-17) equivalent load of the FTP-75 duty. Students interpolate `e` and `Y` from Shigley Table 11-1 for each candidate.

The templates contain comment-only `TODO` cells: students write the code from the equations given. Students also check the simulation by hand in `Student_01` (the hill-climb torque). The reference solution is one valid design, not the answer; see `instructor/solution/README.md`, and keep it out of the student package. The worked solution ships encrypted in `instructor_answer_key.7z` (instructors request the password); once extracted into `instructor/solution/`, each complete export also writes `exports_design_ready/Answer_Key.md` for the exported gear train.

---

## 6. Key Design Values at a Glance

All torques are on the input shaft (motor side). For the intermediate shaft multiply by i1 x sqrt(eta_dt), where i1 is the stage-1 ratio N2/N1; for the output multiply by G x eta_dt.

| Value | From which case | Used for |
|---|---|---|
| T_peak | Drag Race | Gear stress, shaft yield |
| T_mean_eq | FTP-75 | Shaft fatigue (Goodman mean) |
| T_alt_eq | FTP-75 | Shaft fatigue (Goodman alternating) |
| T_cubic_mean | FTP-75 | Bearing L10 equivalent load, Shigley Eq. (11-17) |
| ftp_distance_m | FTP-75 | Scale bearing life to 150,000 km |
| T_steady | Hill Climb | Hand check of the simulation; finite-life extension |

---

## 7. Customizing

**Change the vehicle:** Edit the parameter block at the top of `main.mlx` (or use the GUI). Mass, drag coefficient, tire radius, motor torque, power and speed limit are all editable.

**Change the drive cycle:** The EPA FTP-75 schedule is built in (`instructor/ftp75Schedule.m`) and is used whenever no file is given. To use another cycle, press **Browse** in the dashboard or set `ftp_file` in `main.mlx` to a two-column text file of time [s] and speed, starting at 0 s. State the speed units with the dropdown next to the file name in the dashboard, or `ftp_units = "kph"` (or `"mph"`) in `main.mlx`. On "auto" a header naming the units (for example `time_s,speed_kph`) decides; with no header, a trace that never exceeds 75 is taken as mph and the dashboard shows a warning.

**Change the gear train:** In the dashboard's gear-train panel, set the teeth, module and helix angle of both stages. The ratio G is computed from the teeth; trains Shigley's charts cannot rate are refused with the reason. With "key picks" ticked (available once the answer key is extracted), the export chooses the stage-2 module. A change of ratio needs a fresh run before export.

**Fatigue method:** FTP-75 fatigue loads use the fixed `approach-a-equivalent-sinusoid` route (requires the Signal Processing Toolbox). Students receive its mean and alternating torque outputs; they do not choose or implement a competing reduction method.

**Change the hill grade:** `theta_hill_deg` in `main.mlx` or the GUI. Default is 20 degrees.

**Change how much you assign:** The gear, shaft and bearing parts are separable submissions, and any one of the three duty cycles can stand alone. The reference solution and `docs/EXPECTED_RESULTS.md` (both in the encrypted answer-key archive) cover the whole chain, so you can start students at the shaft or the bearing task by handing them the upstream numbers as given data. See "Scoping the assignment" in `docs/INSTRUCTOR_GUIDE.md`, and rescale the rubric as described in `docs/ASSESSMENT_RUBRIC.md`.

---

## 8. Troubleshooting

| Problem | Fix |
|---|---|
| `check_dependencies` shows FAIL | Install the missing toolbox or update MATLAB |
| FTP tracking RMS > 5 km/h | PID gains may need tuning for your vehicle; raise `Kp` in `main.mlx` (the dashboard uses the default gains) |
| Simulation runs but plots are empty | Make sure at least one load case is checked |
| Students can't find the `.mat` files | Check that `exports_design_ready/` is beside the templates in the hand-out folder |
| Rainflow not available | Install the Signal Processing Toolbox; FTP-75 fatigue extraction requires `rainflow()` |
