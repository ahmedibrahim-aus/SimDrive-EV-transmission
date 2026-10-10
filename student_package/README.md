# SimDrive: EV Transmission Design

### Student hand-out

Everything you need for the project is in this folder. Copy it somewhere you
can work in and open MATLAB R2025b or newer.

Start with **`SimDrive_Project_Brief.docx`**. It explains what you are
building and what is expected of you.

**Course context:** the project runs alongside your Machine Design course and
uses Shigley Ch. 3, 5, 6, 7, 11, 13 and 14 as you learn them. The templates name
the chapter and leave the engineering to you.

## What is here

| File | What it is |
|---|---|
| `SimDrive_Project_Brief.docx` | The project brief. Read this first. |
| `ASSIGNMENT_BRIEF.md` | The same requirements in short form, including every check your design must pass |
| `Student_01_Load_Inputs.m` | Open the simulation results and sort the torques by failure mode |
| `Student_02_Gear_Design.m` | Both helical stages: geometry, mesh forces, AGMA bending and contact stress |
| `Student_03_Shaft_Design.m` | The stepped intermediate shaft: endurance limit, notch factors, DE-Goodman, yield, minimum mass |
| `Student_04_Bearing_Selection.m` | Bearing loads, thrust factors, rating life, catalog selection |
| `computeShoulderNotchFactors.m` | Returns `Kt` and `Kts` digitized from the Shigley Appendix A stress-concentration charts, `q` and `qs` from the bending and torsion fits for the Neuber constant, and the resulting `Kf` and `Kfs` |
| `DATA_DICTIONARY.md` | Every supplied variable, its units, and which calculation it belongs to |
| `DESIGN_REPORT_TEMPLATE.md` | The structure your report must follow |
| `exports_design_ready/` | The simulation results and figures |
| `LICENSE`, `LICENSE-docs` | BSD-3-Clause for code, CC BY-SA 4.0 for documents |

## The simulation results

`Design_Summary.mat` holds the vehicle and gear data.

Each `*_Outputs.mat` file holds one driving case and contains three things:

- `ds_single`, the design values your templates read, such as `T_peak`,
  `T_mean_eq` and `T_cubic_mean`. These are exactly as the instructor's
  simulation produced them.
- `torque_Nm`, the torque-versus-time curve for that case, as a timeseries you
  can plot directly.
- `torque_note`, one sentence saying what that curve is.

**The FTP-75 curve is the equivalent sinusoid, not the raw torque.** The city
cycle produces a jagged, irregular torque history that no fatigue equation can
use as it stands, so it has already been reduced to a single equivalent
sinusoidal load with the mean and alternating components the DE-Goodman shaft
equation (Shigley Ch. 7) needs. That reduction is the one in `T_mean_eq` and `T_alt_eq`, and
plotting `torque_Nm` for FTP-75 shows you what it looks like. The hill-climb and
drag-race curves are the applied motor torque as simulated.

The FTP-75 sinusoid has a 120-second period
and the cycle is 1874 seconds long, which is 15.6 periods rather than a whole
number. Take `mean()` of that curve and you do not get `T_mean_eq` exactly (the
`torque_note` stored with the curve gives that mean for your data), because the
part-period at the end biases the average. The
centerline is the midpoint of the range, and that does equal `T_mean_eq`
exactly. Use the supplied scalars in your calculations.

The curves are resampled to 2000 points so the folder stays small to download,
which is about 128 points per 120 s period of the FTP-75 sinusoid. The scalars are
untouched. If you need a full-resolution trace, ask your instructor.

## Order of work

Work through `Student_01` to `Student_04` in order. Each one depends on the
results of the one before it. Fill in the cells marked `TODO`, and iterate until
every safety factor and life target is satisfied.

Choose and justify the design values in the templates. Compare feasible
geometries and identify which check determines the final dimensions.
