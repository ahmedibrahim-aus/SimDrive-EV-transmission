# SimDrive: EV Transmission Design Report

Follow this structure. Every section names what has to be in it. Tables carry
units in the column headings, and every figure is referred to in the text.

Write it so that a competent reader could reproduce your design from the report
alone, without access to your MATLAB.

---

## 1. Design requirements

The vehicle, the single-speed, two-stage gear train you were given, the three
load cases, the materials you chose, the target life, and the safety-factor
targets.

## 2. Load-case interpretation

The input, intermediate and output torque table, and the hill-climb hand check:
your settling speed and steady torque against the simulated `T_steady`, the
percentage difference, and what it tells you about the simulation.

Then explain why each torque belongs to the calculation you used it for, which
is where most of the points in this section sit. Why the peak torque rather than
the mean one sizes the gear teeth. Why the shaft fatigue check needs a mean and
an alternating value. Why the bearing calculation takes the cubic-mean torque
rather than the mean of the sinusoid. One or two sentences on each are enough,
provided the reasoning is your own rather than a restatement of the torque table
in `ASSIGNMENT_BRIEF.md`.

## 3. Gear design

For each stage: geometry, the three mesh force components, the AGMA rating
factors with a justification and a source for each, the material with its grade
and table row, the allowable stresses with the cycle count used for each member,
the bending and contact stresses, and the safety factors. Eight safety factors
in all.

State which check governed each stage, whether bending or contact and on which
member. Compare on a like basis: bending stress is linear in the load and
contact stress goes as its square root, so `S_F` is comparable with `S_H^2`, not
with `S_H`. Then say what you would change first if the design had to carry more
torque.

## 4. Intermediate-shaft design

Layout with dimensions. Bearing reactions in both planes and the combined
bending-moment diagram, including both helix thrust couples `M_0 = W_a d/2` and
the sign convention you took. State whether the two tangential forces, the two
radial forces, the two thrusts and the two couples add or oppose, and why. The endurance limit with every
Marin factor stated and justified. Stress-concentration and notch-sensitivity
factors at each shoulder, with the figure you read each one from. Fatigue and
yield safety factors at every critical section, including the check on the
stage-2 pinion rim. State which section and which check, fatigue or yield,
governed the diameter. Final mass, and a scaled drawing.

## 5. Extensions

If you took the input-shaft extension (Student 03, Task 8; Student 04, Task 5):
the same evidence for the input shaft,
and the comparison of thrust couple against mesh bending moment on the two
shafts.

If you took the finite-life extension (Student 03, Task 9): `sigma_ar`, the
S-N constants and the life in hours at every section at `T_steady`, the
governing section, and whether that life is a credible concern for a road car.

## 6. Bearing selection

Reactions at `T_cubic_mean_int` used for life, including both thrust couples. Candidate table with
catalog data, showing at least one candidate that fails. The `F_a/C_0` ratio,
the `e` and `Y` you interpolated from Table 11-1, the equivalent dynamic loads
and the rating lives in km. Final designations, with the catalog page.

State what decided each selection: rating life or the bore required by the
shaft. Where the bore governs, the bearing is not life-limited, and that should
be said explicitly.

## 7. Integrated design

Show that the parts fit together. Compare the bearing bore with the journal
diameter, the journal with its shoulder and fillet, and the gear seat with the
gear bore. Give the width of the flat shoulder face, `(D-d)/2 - r`, at every
shoulder and say what seats against it. A table of the final component set with
every dimension.

## 8. Design iteration

Document at least one change. Record which check failed or proved
over-designed, the alteration you made in response, the effect it had on the
results, and what this indicated about the parameter controlling that check. A design that passed on the first attempt, with
no iteration recorded, is not evidence that the design is a good one.

## 9. Assumptions and limitations

Be specific and be honest. At minimum:

- The equivalent-sinusoid reduction of the city cycle, and what it discards.
- Rigid shafts, rigid mounts, and constant drivetrain efficiency.
- No thermal effects, no lubrication analysis, no gear dynamics beyond the AGMA
  dynamic factor.
- `L_10` at 90 percent reliability as the bearing criterion, with no Weibull
  adjustment and no application factor.
- The axial normal stress neglected in the shaft fatigue check, per Ch. 7, and
  the tooth rating taken at peak torque for the full design life.
- The coplanar shaft arrangement and the fixed helix hands, which set how the
  forces on the intermediate shaft combine; a production unit places its shafts
  to suit the housing.

Stating a limitation yourself costs no points. Omitting one that your reader
identifies does.

## 10. References

*Shigley's Mechanical Engineering Design*, 11th ed., with the specific chapters,
figures and tables you used. The bearing catalog, with page numbers.
