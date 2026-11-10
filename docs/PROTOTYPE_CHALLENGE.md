# Prototype challenge for SimDrive: EV Transmission Design

This team competition runs in parallel with the design assignment. Each team
takes the gearbox designed in `Student_01` to `Student_04`, models it as a
printable two-stage gear train, prints it, and compares the result with the
computed values.

The exercise converts a value calculated by Week 3 into a physical object in
Week 6, and any discrepancy between the two must be explained.

## Team submission

| Item | Form |
|---|---|
| Design calculation | Completed `Student_01` to `Student_04` templates |
| Printed gear train (both stages) | Physical parts, modeled and printed from the team's own design |
| Report | `DESIGN_REPORT_TEMPLATE.md`, plus the prototype section below |
| Photographs | The printed train, meshed, with a scale reference in frame |

Teams consist of three to four students, and each team makes one submission.

## Producing the parts

Teams model their own parts, in the CAD software used by the department, from
the dimensions of their design: tooth counts, normal module, pressure angle,
helix angle, face width, pitch and tip diameters, and center distance. Most of
these values are in the `Student_01` and `Student_02` output tables, and the tip
diameters follow from the pitch diameter and the module.

Modeling the gear is part of the exercise. Constructing the tooth profile
conveys the meaning of the module and the pressure angle more effectively than
running an export function.

The tooth counts, pressure angle, and helix angle must match the designed stages
exactly, so that the ratios are exact. The size need not match. All four gears
are scaled by one factor so that the train fits the print bed and the two center
distances remain in proportion. The scale factor must be stated in the report,
and a submission without it is not accepted.

## The prototype section of the report

The section covers four points in approximately one page:

1. The scale factor and the effect of scaling on the physics. Stress does not
   scale with geometry in the same way as length, so explain what the printed
   train can and cannot indicate about the full-size design.
2. Measured against designed dimensions. Measure the printed center distance,
   tip diameters, and face width, tabulate them against the designed values, and
   account for the differences: printer tolerance, shrinkage, slicer
   compensation.
3. Mesh behavior. Turn the train by hand and report whether it binds, shows
   excessive backlash or runs smoothly. Count the input revolutions per output
   revolution and compare the result with the overall ratio `G`.
4. Limitations of the print. The safety factors were obtained from allowable
   stresses for the selected steel and heat treatment, read from the Shigley
   Chapter 14 strength charts. Identify at least three characteristics of the
   printed part that prevent it from validating these factors.

A team that reports binding of the train, with an explanation of the cause and a
proposed correction, ranks above a team that reports a clean print without
analysis.

## Judging

The submissions are judged by the instructor and, where available, one external
reviewer. The prototype challenge and the design assignment
([`docs/ASSESSMENT_RUBRIC.md`](ASSESSMENT_RUBRIC.md)) are separate submissions.

| Criterion | Indicators |
|---|---|
| Design correctness | Safety factors met, method traceable to Shigley, load cases used as intended |
| Measurement and comparison | Actual measurements, complete tabulation, differences accounted for |
| Engineering judgment | Understanding of what the scaled print does and does not validate |
| Print quality | Clean, meshing teeth; appropriate print orientation and settings |
| Report and defense | Clear writing, correct units, answers to questions on the design |

### Grounds for disqualification

- Parts not modeled from the team's own design values.
- Safety factors reported as passing when the submitted templates show
  otherwise.
- A scale factor omitted from the report.

## Schedule

The weeks are the six weekly meetings of the
[suggested delivery](INSTRUCTOR_GUIDE.md#suggested-delivery) in the instructor
guide.

| Week | Activity |
|---|---|
| Week 1 | Announce the challenge alongside the design assignment |
| Week 4 | Both gear stages (`Student_02`) must meet their AGMA bending and contact targets before any printing |
| Week 5 | Modeling, printing and measurement |
| Week 6 | Submission, presentation and judging |
