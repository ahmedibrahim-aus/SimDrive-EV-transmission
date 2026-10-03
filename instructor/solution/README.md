# Reference Solution

**For the instructor, not for students.** This folder is a complete worked
solution of the project, kept out of the student package.

In the repository the solution files are encrypted in
`instructor_answer_key.7z` (AES-256), together with
`docs/EXPECTED_RESULTS.md` and the tests that contain reference answers. Only
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
| `computeHelicalJ.m` | Shigley Figs. 14-7 and 14-8, digitized |
| `computeShoulderNotchFactors.m` | Shoulder stress-concentration and notch factors from Figs. A-15-7 to A-15-9 and Eqs. (6-35) and (6-36); public, and students receive it |
| `bearingCatalogue.m` | SKF deep-groove ball bearings, 20 to 100 mm bore |
| `selectStage2Module.m`, `runAnswerKey.m`, `writeAnswerKeyReport.m`, `simplySupportedMoment.m` | Helpers used by the solution and by the dashboard export |
| `courseTargets.m` | The course targets (safety factors, the 150,000 km life, the 120 km/h quality-number check speed); public |

## How the solution makes its choices

Students choose and defend their own values. The solution has to work for any
gear train the instructor sets, so it chooses by stated rules: the lowest
quality number that Eq. (14-29) allows at 120 km/h, the narrowest face width inside the
3 to 5 transverse-pitch band, the softest Table A-21 steel inside the hardness
range of Figs. 14-2 and 14-5, the smallest standard bore that passes, and the
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

## Updating the archive (maintainers)

After changing any answer-key file, pack it again from the repository folder.
7-Zip asks for the password twice and encrypts the file names as well:

```
7z a -t7z -mhe=on -mx=9 -p instructor_answer_key.7z @tools/answer_key_files.txt
```

The plaintext files are listed in `.gitignore`, so they cannot be committed by
mistake.
