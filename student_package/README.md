# SimDrive: EV Transmission Design

*Student hand-out*

This folder contains all the material required for the project. Copy it to a
working location and open MATLAB R2025b or newer. No toolboxes are required.

Begin with **`SimDrive_Project_Brief.docx`**, which describes the design task
and the requirements.

## Contents

| File | Description |
|---|---|
| `SimDrive_Project_Brief.docx` | The project brief. Read this first. |
| `ASSIGNMENT_BRIEF.md` | The full requirements and every check that the design must satisfy |
| `Student_01_Load_Inputs.m` | Loading of the simulation results and assignment of the torques to failure modes |
| `Student_02_Gear_Design.m` | Both helical stages: geometry, mesh forces, AGMA bending and contact stress |
| `Student_03_Shaft_Design.m` | The stepped intermediate shaft: endurance limit, notch factors, DE-Goodman, yield, minimum mass |
| `Student_04_Bearing_Selection.m` | Bearing loads, X and Y factors, rating life, catalog selection |
| `computeShoulderNotchFactors.m` | The shoulder stress-concentration and notch-sensitivity factors that Student 03 uses |
| `DATA_DICTIONARY.md` | Every supplied variable, its units and the calculation in which it is used |
| `DESIGN_REPORT_TEMPLATE.md` | The required structure of the report |
| `exports_design_ready/` | The simulation results and figures |
| `LICENSE`, `LICENSE-docs` | BSD-3-Clause for code, CC BY-SA 4.0 for documents and the explanatory text in the templates |

## The simulation results

`Design_Summary.mat` contains the vehicle and gear data.

Each `*_Outputs.mat` file contains one driving case, with three items:

- `ds_single`, the design values that the templates read, such as `T_peak`,
  `T_mean_eq` and `T_cubic_mean`. These values are exactly as produced by the
  instructor simulation.
- `torque_Nm`, the torque-versus-time curve for that case, as a timeseries that
  can be plotted directly.
- `torque_note`, one sentence that identifies the curve.

For FTP-75 the curve is the equivalent sinusoid. The city cycle produces an
irregular torque history that the Goodman equation cannot use directly. The
history has therefore been reduced to a single equivalent sinusoidal load with
the mean and alternating components that the DE-Goodman shaft equation (Shigley
Chapter 7) requires. This reduction is expressed by `T_mean_eq` and `T_alt_eq`,
and a plot of `torque_Nm` for FTP-75 shows the resulting sinusoid. The
hill-climb and drag-race curves are the applied motor torque as simulated.

The FTP-75 sinusoid has a 120-second period and the cycle is 1874 seconds long,
which is 15.6 periods. The `mean()` of that curve is not exactly `T_mean_eq`,
because the partial period at the end biases the average (the `torque_note`
stored with the curve gives that mean for the supplied data). The centerline is
the midpoint of the range and equals `T_mean_eq`. Use the supplied scalars in
all calculations.

The curves are resampled to 2000 points to limit the download size, which
corresponds to approximately 128 points per 120 s period of the FTP-75 sinusoid.
The scalars are unmodified. A full-resolution trace is available from the
instructor on request.

## Order of work

Complete `Student_01` to `Student_04` in order, since each template depends on
the results of the preceding one. Complete the cells marked `TODO`, and select
and justify the design values that the templates request.

The course calculations rest on approximations that must be stated in the
report. They are listed under [scope and
limitations](ASSIGNMENT_BRIEF.md#scope-and-limitations) in the assignment brief.
