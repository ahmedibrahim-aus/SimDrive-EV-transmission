# SimDrive: EV Transmission Design

### Student design templates

There are four templates. Each gives the method, the governing equations, and
the chapter of Shigley they come from, but no solution code. You write the
MATLAB in the cells marked `TODO` and iterate until every safety factor and life
target is satisfied. The worked solution is held by your instructor. How the
project fits your course is described in the
[assignment brief](ASSIGNMENT_BRIEF.md#how-this-fits-your-course).

## Before you start

Your instructor hands out a single folder that already contains these templates,
the supporting documents, and a folder named `exports_design_ready`. The data
folder sits beside the templates, so the relative path `exports_design_ready/`
resolves from wherever you copy the hand-out. Keep them together.

The four templates and the three supporting documents in this repository's
`student/` folder are the same files as in the hand-out, kept here as the
version-controlled source. The hand-out itself is built by
`instructor/buildStudentPackage.m`.

Everything in that folder is output from a vehicle simulation that has already
been run for you. You are not modeling the car. You are designing the gearbox
that has to survive what the car does to it.

## Order of work

Each file depends on the one before it.

1. `Student_01_Load_Inputs.m` opens the simulation results, sorts the torques
   according to the failure mode each one supports, and computes the
   intermediate- and output-shaft torques.
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

## What comes with the assignment

Besides the four templates and the three supporting documents
(`ASSIGNMENT_BRIEF.md`, `DATA_DICTIONARY.md` and `DESIGN_REPORT_TEMPLATE.md`),
the student hand-out (`student_package/`) contains
`computeShoulderNotchFactors.m`. Student 03 calls it for the shoulder
stress-concentration and notch-sensitivity factors, and you are meant to use it.
Its three `Kt` surfaces are digitized from the Shigley 11e Appendix A
stress-concentration charts for a shaft shoulder, so it returns the numbers you
would read off those charts. Notch sensitivity is not read off a chart at all:
`q` and `qs` come from the Shigley curve fits for the Neuber constant (bending
and torsion), which is the relation the Chapter 6 notch-sensitivity charts draw.
Student 03, Task 4, says how to check the function by hand before you rely on
it.

The license files are included as well, since the material is released under
BSD-3-Clause for code and CC BY-SA 4.0 for documents.

## What is fixed and what you choose

The vehicle, the three load cases, and the two-stage gear train (tooth counts,
modules and helix angles of both stages) are fixed. They are the project
requirement.

You select, and must justify in the report:

- The face width of each stage, material, grade and hardness, and every AGMA
  rating factor, each traced to the figure, table or equation you took it from.
- Shaft material, bearing span, gear positions, journal and gear-seat diameters,
  and the shoulder proportions `D/d` and `r/d`.
- Bearing designations. The thrust factors `X`, `Y` and `e` are not part of that
  choice and are not catalog constants: Shigley Chapter 11 tabulates `e` and `Y`
  against the ratio `F_a/C_0`, so you interpolate them for each candidate.

## What makes the design hard

No check can be passed in isolation, and the components depend on one another.
The journal you arrive at in Student 03 fixes the smallest bearing bore you may
use in Student 04, and the shoulder on that journal governs the stress
concentration that decided the journal in the first place. Selecting a larger
bearing for reassurance makes the shaft heavier. Work around that loop, and
state in your report which constraint ran out first.
