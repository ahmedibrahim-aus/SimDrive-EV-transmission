# Release Checklist for SimDrive: EV Transmission Design

A checklist for tagging a release. The File Exchange steps apply only if the module is also published on MathWorks File Exchange.

## 1. Pre-flight (run locally)

```matlab
cd SimDrive-EV-transmission/instructor
check_dependencies          % expect ALL CHECKS PASSED, no FAIL and no WARN
cd ../tests
validate_release            % expect "RELEASE VALIDATION: PASS"
```

- [ ] `buildtool check testFull` passes (Code Analyzer zero-warning gate, then the full test suite: file layout, core math, Simulink smoke run, student-template, solution-readiness, and 3D-view checks).
- [ ] `generateLoadCases` runs end-to-end and writes `exports_design_ready/`.
- [ ] `buildStudentPackage` refreshes `student_package/` and the `release/` ZIP, and
      `git diff --stat student_package/` shows only intended changes.
- [ ] The `InstructorApp` GUI opens, runs, and exports.
- [ ] Dashboard E2E regression verifies run/edit/export consistency, a fresh
      three-case ZIP, rejection of partial datasets, and laptop/desktop layout.
- [ ] Hosted full-release CI passes on the release commit, with the
      `ANSWER_KEY_PASSWORD` secret set so the answer-key tests run. A private copy
      also needs `MLM_LICENSE_TOKEN`, as described in `CONTRIBUTING.md`.
- [ ] `instructor/solution/Solution_00_Run_All.m` runs against regenerated exports and all design targets pass.
- [ ] No stray generated files committed (`*.slx`, `*.autosave`, `exports_design_ready/`,
      `*.mat`, `*.png`), all covered by `.gitignore`.
- [ ] No local absolute paths, credentials, or personal notes in tracked files.

## 2. Version

Use semantic versioning against the previous tag. Raise the major version when
the reference results change, or when a change breaks an adopter's folder layout
or the export contract, so that an issued dataset must be regenerated. Raise the
minor version when the hand-out gains material and the reference results stay
the same, and the patch version for fixes that change no reference number.
(2.1.0 changed reference results under a minor version, before this rule.)

Update the version in `Contents.m`, `CITATION.cff` (version and `date-released`),
`CHANGELOG.md`, the ZIP name in `tools/buildStudentPackage.m` and in
`package_name` in `instructor/InstructorApp.m`, the release badge in
`README.md`, and `tests/tReleaseMetadata.m` so they all match the tag.

## 3. Packaging decision: GitHub-linked File Exchange (recommended)

This module is best distributed as a **downloadable repository**, linked from File
Exchange, **not** as an installed `.mltbx` toolbox. Reasons:

- The workflow depends on an **editable, writable folder structure**: the instructor
  edits parameters in the InstructorApp GUI, runs it, the exports land in
  `exports_design_ready/` at the repository root, and `buildStudentPackage` then
  rewrites `student_package/` and its ZIP from that run.
- An installed toolbox places files in a read-only Add-Ons location, which breaks the
  "edit parameters" and "rebuild the hand-out" steps and is inconvenient for a
  teaching exercise.
- File Exchange's GitHub integration gives users the latest repo with a single
  "Download" or clone. (The module has not been tested in MATLAB Online, so do
  not add an "Open in MATLAB Online" badge until it has.)

> Optional: a `.mltbx` can still be produced for instructors who prefer an Add-On,
> using the MATLAB `matlab.addons.toolbox.packageToolbox` workflow, but document that
> they must copy the files to a writable folder before running. Not recommended as the
> primary channel.

## 4. GitHub release

- **Title:** `SimDrive v<version>`
- **Repository description:** *Shigley-based machine design project in MATLAB
  and Simulink: design the two-stage helical gearbox, stepped shaft and bearings
  of a passenger EV from simulated load cases.*
- **Topics/tags:** `agma`, `bearing-selection`, `electric-vehicle`,
  `engineering-education`, `fatigue`, `gear-design`, `machine-design`, `matlab`,
  `mechanical-engineering`, `shaft-design`, `shigley`, `simulink`
- **Release notes:** paste the matching section of `CHANGELOG.md`.

## 5. File Exchange submission

- **Title:** `SimDrive: EV Transmission Design`
- **Summary (one line):** *Simulation-based loads for an undergraduate EV gearbox
  design project: AGMA gear rating, Shigley shaft design and bearing life.*
- **Description:** A Simulink 1-DOF EV model generates motor torque/speed histories for
  three driving scenarios (FTP-75 city cycle, hill climb, drag race). Students use the
  exported loads to design a single-speed, two-stage helical gearbox following Shigley
  and the AGMA method, with SKF catalog data, in plain-text MATLAB templates. Includes an instructor dashboard, a command-line
  load-case generator, a full physics and assumptions reference, and a test suite.
- **Required products:** MATLAB (R2025a+), Simulink,
  Signal Processing Toolbox.
- **Tags:** as in the GitHub topics above.
- **Link to GitHub repo** (use the GitHub-linked submission flow).

## 6. Suggested thumbnail / screenshots

- [ ] `Overview_AllCases.png` (3-case torque/speed overview, produced by `generateLoadCases`).
- [ ] InstructorApp dashboard with results populated.
- [ ] A student gear/shaft/bearing result table from a `Student_*.m` template.

## 7. Final manual checks

- [ ] README badges/links resolve; repo URL correct in `README.md` and `CITATION.cff`.
- [ ] After the File Exchange submission exists, add its badge to `README.md`
      and set `url:` in `CITATION.cff` to the submission page. Until then both
      point at the GitHub repository, not at a bare File Exchange index.
- [ ] `LICENSE` (BSD-3-Clause) and `LICENSE-docs` (CC BY-SA 4.0) present.
- [ ] `buildtool check testFull` passes locally, and the GitHub Actions workflow (`.github/workflows/matlab-tests.yml`) is green.
