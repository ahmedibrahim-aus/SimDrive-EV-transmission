# Changelog

All notable changes to **SimDrive: EV Transmission Design** are recorded here.
The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [1.0.0] - 2026-10-10

First public release.

### What it contains

- A single-speed, two-stage helical transmission for a passenger EV: 20:60 then 20:60 (G = 9) on three parallel shafts.
- A MATLAB and Simulink vehicle model that produces the design loads from three cases: the EPA FTP-75 city cycle (built in), a sustained hill climb, and a full-throttle launch (Drag Race).
- An instructor dashboard to set the vehicle, motor and gear train, run the cases, and export the data students receive.
- Four student templates, written as MATLAB Live Scripts: load the design inputs, rate both helical stages (Shigley Ch. 13 and 14), design the stepped intermediate shaft (Ch. 6 and 7), and select its bearings (Ch. 11).
- A student hand-out (`student_package/`, also attached to this release as a ZIP) with the templates, the project brief, the data and the student documents.
- An instructor guide, a quick start, the physics and modeling reference, and a list of what to assess.
- A worked answer key that follows whatever gear train the instructor sets. It ships encrypted in `instructor_answer_key.7z`; instructors can request the password (see the README).

### Requirements

- MATLAB R2025b or newer, Simulink, and the Signal Processing Toolbox. Tested on R2025b and R2026b on Windows.

### Known limitations

- The course answer key checks what the assignment teaches. Checks a production design would add, such as shaft deflection and the bearings' static rating, are listed in `docs/MathematicalModels.md`, Section 10.4, for use as extensions.
