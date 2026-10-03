# Prototype Challenge for SimDrive: EV Transmission Design

A team competition that runs on top of the design assignment. Teams take the
gearbox they sized in `Student_01` to `Student_04`, model it as a printable two-stage
gear train, print it, and defend the result against the numbers they computed.

The exercise turns a number calculated in week 3 into an object students can
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

### Print settings that matter

- Layer height of 0.15 mm or finer. The tooth flanks are what matters here, and
  coarse layers reduce an involute to a staircase.
- Print flat, with the gear axis vertical. Teeth printed on their side tend to
  delaminate along the direction of loading.
- At least four wall perimeters, so that the teeth are solid rather than infill.
- Model the teeth with no backlash allowance. If the pair binds, either scale one
  part by 99.5 percent or add clearance in the slicer, and state which you did.
- Tooth size is the practical limit. Keep the printed module at 1 mm or more,
  which gives teeth roughly 2.3 mm tall and 1.6 mm thick at the pitch line,
  close to the floor of a 0.4 mm nozzle. If the teeth emerge as a scalloped edge
  rather than as distinct teeth, print at a larger scale and explain it.

---

## The prototype section of the report

Four things, roughly a page:

1. **Scale and what it does to the physics.** State the scale factor. Stress
   does not scale with geometry the way length does, so explain what your
   printed pair could and could not tell you about the real design.
2. **Measured against designed.** Measure the printed center distance, tip
   diameters, and face width. Tabulate measured against designed. Account for
   the differences: printer tolerance, shrinkage, slicer compensation.
3. **Mesh behavior.** Turn the pair by hand. Does it bind, backlash, or run
   smoothly? Count the input turns per output turn and compare with the overall ratio `G`.
4. **What the print cannot show.** Your safety factors came from allowable
   stresses for through-hardened steel read from Shigley Figs. 14-2 and 14-5. Name at least three things
   about the printed part that make it unable to validate them.

A team reporting that the pair binds, with an explanation of why and a proposed
correction, scores above a team reporting a clean print and no analysis.

---

## Judging

Judged by the instructor plus one external reviewer where available. This
weighting applies to the prototype challenge only. The design assignment is
graded against `docs/ASSESSMENT_RUBRIC.md`, and the two are separate
submissions.

| Criterion | Weight (percent) | What earns the points |
|---|---:|---|
| Design correctness | 35 | Safety factors met, method traceable to Shigley, load cases used as intended |
| Measurement and comparison | 25 | Real measurements, honest tabulation, differences accounted for |
| Engineering judgment | 20 | Understands what the scaled print does and does not validate |
| Print quality | 10 | Teeth clean and meshing, sensible orientation and settings |
| Report and defense | 10 | Clear writing, correct units, answers questions on the design |

Print quality carries the smallest weight. A rough print supported
by careful analysis is worth more here than a clean print with none.

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

Printing takes longer than teams expect. The output gear is a print of several
hours even at quarter scale, and the laboratory queue is shared. Hold the week-4
gate firmly, otherwise the final week becomes a print queue rather than an
engineering exercise.

### For the instructor

- One printer serves about six teams if the week-4 gate holds.
- Print one reference pair yourself before week 5 so the settings above are
  known-good on your hardware.
- Keep the winning submission, including scripts, report, and photographs, as
  an example for future classes.
