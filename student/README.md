# SimDrive: EV Transmission Design

*Student design templates*

There are four templates. Each provides the method, the governing equations and
the Shigley chapter from which they are taken, but no solution code. The MATLAB
code is written in the cells marked `TODO`, and the design is iterated until
every safety factor and life target is satisfied. The worked solution is
retained by the instructor. The relation of the project to the course is
described in the [assignment brief](ASSIGNMENT_BRIEF.md#relation-to-the-course).

## Preparation

The instructor provides a single folder that contains these templates, the
supporting documents and a folder named `exports_design_ready`. The data folder
is located beside the templates, so the relative path `exports_design_ready/`
resolves from any location to which the hand-out is copied. The templates and
the data folder must be kept together.

The four templates and the three supporting documents in this repository's
`student/` folder are identical to the files in the hand-out and are kept here
as the version-controlled source. The hand-out is built by
`instructor/buildStudentPackage.m`.

All files in `exports_design_ready` are output from a vehicle simulation that
has already been run. The task is the design of the gearbox for the loads that
the simulation produced.

## Order of work

Each file depends on the preceding one.

1. `Student_01_Load_Inputs.m` loads the simulation results, assigns the torques
   to failure modes, and computes the intermediate- and output-shaft torques.
2. `Student_02_Gear_Design.m` covers the geometry and mesh forces of both
   helical stages, followed by AGMA bending and contact stress for all four
   gears. Shigley Chapters 13 and 14.
3. `Student_03_Shaft_Design.m` covers the stepped intermediate shaft, which
   carries both stages, with the input shaft as an extension: endurance limit
   and Marin factors, stress concentration and notch sensitivity, DE-Goodman
   fatigue and static yield at every critical section, and minimum mass. Shigley
   Chapters 3, 5, 6 and 7 and the Appendix A stress-concentration charts.
4. `Student_04_Bearing_Selection.m` covers equivalent radial load, rating life,
   and catalog selection for the intermediate shaft. Shigley Chapter 11.

## Contents of the hand-out

In addition to the four templates and the three supporting documents
(`ASSIGNMENT_BRIEF.md`, `DATA_DICTIONARY.md` and `DESIGN_REPORT_TEMPLATE.md`),
the student hand-out (`student_package/`) contains the project brief
`SimDrive_Project_Brief.docx` (to be read first), a hand-out `README.md` and
`computeShoulderNotchFactors.m`. Student 03 calls this function for the shoulder
stress-concentration and notch-sensitivity factors, and its use is recommended.
Its three `Kt` surfaces are digitized from the Shigley 11e Appendix A
stress-concentration charts for a shaft shoulder, so it returns the values that
would be read from those charts. Notch sensitivity is not read from a chart: `q`
and `qs` are obtained from the Shigley curve fits for the Neuber constant
(bending and torsion), which are the relations plotted in the Chapter 6
notch-sensitivity charts. Student 03, Task 4, describes how to verify the
function by hand calculation before it is relied upon.

The license files are also included, since the material is released under
BSD-3-Clause for code and CC BY-SA 4.0 for documents.

## Fixed parameters and design choices

The vehicle, the three load cases, and the two-stage gear train (tooth numbers,
modules and helix angles of both stages) are fixed. They constitute the project
requirement.

The following are selected by the student and must be justified in the report:

- The face width of each stage, material, grade and hardness, and every AGMA
  rating factor, each traced to the figure, table or equation from which it was
  taken.
- Shaft material, bearing span, gear positions, journal and gear-seat diameters,
  and the shoulder proportions `D/d` and `r/d`.
- Bearing designations. The factors `X`, `Y` and `e` are not part of that choice
  and are not catalog constants: Shigley Chapter 11 tabulates `e` and `Y`
  against the ratio `F_a/C_0`, so they are interpolated for each candidate.

## Interdependence of the design checks

No check can be satisfied in isolation, since the components depend on one
another. The journal diameter obtained in Student 03 determines the bearing bore
in Student 04, and a larger bearing requires a larger journal and a repetition
of the shaft checks. The shoulder on that journal governs the stress
concentration that determines the journal diameter. The selection of a larger
bearing as a precaution increases the shaft mass. Iterate through this loop, and
state in the report which constraint became active first.
