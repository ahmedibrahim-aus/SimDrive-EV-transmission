# Reference Solution

**For the instructor, not for students.** Once `instructor_answer_key.7z` is
extracted, this folder holds a complete worked solution of the project. It is
kept out of the student package.

In the repository the solution files are encrypted in
`instructor_answer_key.7z` (AES-256), together with
`docs/EXPECTED_RESULTS.md`. Only
`computeShoulderNotchFactors.m` and `courseTargets.m` are public here, because
students and the dashboard use them. To get the password, email Dr. Ahmed Hanafy Ibrahim at
[ahmedibrahim@aus.edu](mailto:ahmedibrahim@aus.edu?subject=SimDrive%20answer%20key%20request) from your institutional email
address, with your name, institution and the course you teach. Then extract
the archive in the repository folder: `7z x instructor_answer_key.7z`.

**It is for reference only.** It is one valid design, not the answer. The design
process is iterative and depends on the constraints set in your project
document, so students who make different, well-justified choices of face width,
material, rating factors, shaft layout or bearing can reach different numbers
and be equally correct. Use it as a starting point: to give you and your
students ideas, to check the order of magnitude of results, and to support
grading.

## What the folder holds once the archive is extracted

| File | Content |
|---|---|
| `Solution_00_Run_All.m` | Runs steps 01 to 04 and collects the results in one `answer_key` table |
| `Solution_01_Load_Inputs.m` | Loads the exports and the two-stage gear train, computes the torque on each shaft, and checks the simulation against the hill-climb hand calculation |
| `Solution_02_Gear_Design.m` | AGMA bending and contact rating of both helical stages, Shigley Ch. 13 and 14 |
| `Solution_03_Shaft_Design.m` | Minimum-mass stepped intermediate shaft: fatigue and yield at every critical section, plus the input-shaft and finite-life extensions |
| `Solution_04_Bearing_Selection.m` | Intermediate-shaft bearing selection, Shigley Ch. 11, from the SKF catalog table |
| `rateHelicalStage.m` | The AGMA rating of one stage, with the solution's design choices made by rule |
| `computeHelicalJ.m` | The Shigley Ch. 14 helical geometry-factor charts, digitized |
| `computeShoulderNotchFactors.m` | Shoulder stress-concentration and notch factors from the Shigley Appendix A charts and the bending and torsion fits for the Neuber constant; public, and students receive it |
| `bearingCatalogue.m` | SKF deep-groove ball bearings, 20 to 100 mm bore |
| `selectStage2Module.m`, `runAnswerKey.m`, `writeAnswerKeyReport.m`, `simplySupportedMoment.m` | Helpers used by the solution and by the dashboard export |
| `courseTargets.m` | The course targets (safety factors, the 150,000 km life, the 120 km/h quality-number check speed); public |

## How the solution makes its choices

Students choose and defend their own values. The solution has to work for any
gear train the instructor sets, so it chooses by stated rules: the lowest
quality number that Shigley's velocity limit allows at 120 km/h, the narrowest face width inside the
3 to 5 transverse-pitch band, the softest heat-treated steel from Shigley Appendix A inside the hardness
range of the Ch. 14 strength charts, the smallest standard bore that passes, and the
lightest bearing that fits it. A student design that meets every target with
sourced choices is correct even where it differs.

## Running it

Generate the exports first (the dashboard, or `generateLoadCases` in
`instructor/`), then:

```matlab
cd instructor/solution
Solution_00_Run_All
```

The dashboard runs the same solution after every complete export and writes the
summary to `exports_design_ready/Answer_Key.md`. Reference values for the
default gear train are in `docs/EXPECTED_RESULTS.md`, also in the archive.

The extracted files are listed in `.gitignore`, so they cannot be committed by
mistake.
