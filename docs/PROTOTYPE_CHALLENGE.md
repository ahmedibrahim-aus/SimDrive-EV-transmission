# Prototype Challenge for SimDrive: EV Transmission Design

A team competition that runs on top of the design assignment. Teams take the
gearbox they sized in `Student_01` to `Student_04`, model it as a printable two-stage
gear train, print it, and defend the result against the numbers they computed.

The exercise turns a number calculated by week 4 into an object students can
hold in week 6, and any disagreement between the two must be explained.

---

## What each team submits

| Item | Form |
|---|---|
| Design calculation | Completed `Student_01` to `Student_04` templates |
| Printed gear train (both stages) | Physical parts, modeled and printed from their own design |
| Report | `DESIGN_REPORT_TEMPLATE.md`, plus the prototype section below |
| Photographs | The printed train, meshed, with a scale reference in frame |

Teams of three to four. One submission per team.

---

## Producing the parts

Teams model their own parts, in whatever CAD tool the department uses, from the
dimensions their design produced: tooth counts, normal module, pressure angle,
helix angle, face width, pitch and tip diameters, and center distance. Most of
those numbers are in the `Student_01` and `Student_02` output tables; the tip
diameters follow from the pitch diameter and the module.

Modeling the gear is part of the exercise. A team that has to
construct a tooth profile themselves generally comes away with a firmer grasp of
what module and pressure angle mean than one that runs an export function.

The tooth counts, pressure angle, and helix angle must match the designed
stages exactly, so the ratios are exact. **The size need not.** Scale all four
gears by one factor so the train fits the print bed and the two center distances
stay in proportion. State the scale factor in the report; a submission without
it is not accepted.

---

## The prototype section of the report

Four things, roughly a page:

1. **Scale and what it does to the physics.** State the scale factor. Stress
   does not scale with geometry the way length does, so explain what your
   printed train could and could not tell you about the real design.
2. **Measured against designed.** Measure the printed center distance, tip
   diameters, and face width. Tabulate measured against designed. Account for
   the differences: printer tolerance, shrinkage, slicer compensation.
3. **Mesh behavior.** Turn the train by hand. Does it bind, show excessive backlash, or run
   smoothly? Count the input turns per output turn and compare with the overall ratio `G`.
4. **What the print cannot show.** Your safety factors came from allowable
   stresses for through-hardened steel read from the Shigley Ch. 14 strength charts. Name at least three things
   about the printed part that make it unable to validate them.

A team reporting that the train binds, with an explanation of why and a proposed
correction, ranks above a team reporting a clean print and no analysis.

---

## Judging

Judged by the instructor plus one external reviewer where available. The
prototype challenge and the design assignment ([`docs/ASSESSMENT_RUBRIC.md`](ASSESSMENT_RUBRIC.md)) are
separate submissions. Things to look for:

- **Design correctness:** safety factors met, method traceable to Shigley, load
  cases used as intended.
- **Measurement and comparison:** real measurements, honest tabulation,
  differences accounted for.
- **Engineering judgment:** understanding of what the scaled print does and does
  not validate.
- **Print quality:** teeth clean and meshing, sensible orientation and settings.
- **Report and defense:** clear writing, correct units, answers to questions on
  the design.

### Disqualifying

- Parts not modeled from the team's own design numbers.
- Safety factors reported as passing when the submitted templates show otherwise.
- A scale factor omitted from the report.

---

## Running it

| When | What |
|---|---|
| Week 1 | Announce the challenge alongside the design assignment |
| Week 4 | Designs must pass their safety-factor checks before any printing |
| Week 5 | Model, print, measure |
| Week 6 | Submission, showcase, judging |
