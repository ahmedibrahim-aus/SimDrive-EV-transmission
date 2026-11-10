# Reference solution

This folder is intended for the instructor. Once `instructor_answer_key.7z` is
extracted, it contains a complete worked solution of the project. It is excluded
from the student package.

The solution files and `docs/EXPECTED_RESULTS.md` are not included in the
repository. They are sent to instructors by email in the encrypted archive
`instructor_answer_key.7z` (AES-256). Only `computeShoulderNotchFactors.m` and
`courseTargets.m` are public in this folder, because students and the dashboard
use them. The [repository README](../../README.md#the-reference-solution)
explains how to request the archive and extract it.

The solution is one valid design among several. The design process is iterative
and depends on the constraints set in the project brief, so students who make
different, well-justified choices of face width, material, rating factors, shaft
layout or bearing can obtain different values and be equally correct. The
solution serves as a reference: it indicates design directions to instructors
and students, provides an order-of-magnitude check of results, and supports
grading.

## Contents of the folder after extraction

| File | Content |
|---|---|
| `Solution_00_Run_All.m` | Runs steps 01 to 04 and collects the results in one `answer_key` table |
| `Solution_01_Load_Inputs.m` | Loads the exports and the two-stage gear train, computes the torque on each shaft, and checks the simulation against the hill-climb hand calculation |
| `Solution_02_Gear_Design.m` | AGMA bending and contact rating of both helical stages, Shigley Chapters 13 and 14 |
| `Solution_03_Shaft_Design.m` | Minimum-mass stepped intermediate shaft: fatigue and yield at every critical section, plus the input-shaft and finite-life extensions |
| `Solution_04_Bearing_Selection.m` | Intermediate-shaft bearing selection, Shigley Chapter 11, from the SKF catalog table |
| `rateHelicalStage.m` | The AGMA rating of one stage, with the solution's design choices made by rule |
| `computeHelicalJ.m` | The Shigley Chapter 14 helical geometry-factor charts, digitized |
| `computeShoulderNotchFactors.m` | Shoulder stress-concentration and notch factors from the Shigley Appendix A charts and the bending and torsion fits for the Neuber constant; public, and students receive it |
| `bearingCatalog.m` | SKF deep-groove ball bearings, 20 to 100 mm bore |
| `selectStage2Module.m`, `runAnswerKey.m`, `writeAnswerKeyReport.m`, `simplySupportedMoment.m` | Supporting functions used by the solution and by the dashboard export |
| `courseTargets.m` | The course targets (safety factors, the 150,000 km life, the 120 km/h quality-number check speed); public |

## Design choices of the solution

Students select and justify their own values. The solution must be valid for any
gear train that the instructor sets, so it selects by stated rules: the lowest
quality number that Shigley's velocity limit allows at 120 km/h, the narrowest
face width from the larger of 3 p_t and 2 p_x (face-contact ratio at least 2) up
to 5 p_t, the softest heat-treated steel from Shigley Appendix A inside the
hardness range of the Chapter 14 strength charts, the smallest standard bore
that passes, and the lightest bearing that fits it. It takes the AGMA size
factor as 1, which Shigley permits. A student design that meets every target
with sourced choices is correct even where it differs.

## Running the solution

Generate the exports first (the dashboard, or `generateLoadCases` in
`instructor/`), then:

```matlab
cd instructor/solution
Solution_00_Run_All
```

The dashboard runs the same solution after every complete export and writes the
summary to `exports_design_ready/Answer_Key.md`. Reference values for the
default gear train are in `docs/EXPECTED_RESULTS.md`, also in the archive.
