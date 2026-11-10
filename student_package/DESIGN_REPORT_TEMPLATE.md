# SimDrive: EV Transmission Design report

The report follows the structure below. Each section states its required
content. Tables carry units in the column headings, and every figure is cited in
the text.

The report must allow a competent reader to reproduce the design from the report
alone, without access to the MATLAB code.

## 1. Design requirements

The vehicle, the prescribed single-speed, two-stage gear train, the three load
cases, the selected materials, the target life, the design factor for the shaft,
and the AGMA safety-factor targets for the gears.

## 2. Load-case interpretation

The input, intermediate and output torque table, and the hill-climb hand check:
the calculated settling speed and steady torque compared with the simulated
`T_steady`, the percentage difference, and its implication for the simulation.
Compare `T_alt_eq` with `T_mean_eq`, and each FTP-75 torque with `T_peak`, and
state what each comparison indicates about the city cycle as a duty.

Explain why each torque belongs to the calculation in which it is used. This
explanation is the main content of the section. It covers (i) why the peak
torque, and not the mean torque, sizes the gear teeth, (ii) why the shaft
fatigue check requires a mean and an alternating value and (iii) why the bearing
calculation uses the cubic-mean torque and not the mean of the sinusoid. One or
two sentences on each point are sufficient, provided that the reasoning is
original and does more than restate the torque table in `ASSIGNMENT_BRIEF.md`.

## 3. Gear design

For each stage: geometry, the three mesh force components, the AGMA rating
factors with a justification and a source for each, the material with its grade
and table row, the allowable stresses with the cycle count used for each member,
the bending and contact stresses, and the safety factors. There are eight safety
factors in total. Also give the face width against the `3*p_t` to `5*p_t` band,
the face-contact ratio `m_F`, the `Q_v` check of each stage at 120 km/h, and the
stage-1 pitch-line velocity at `v_top`.

State which check governed each stage, whether bending or contact and on which
member. Compare on a like basis: bending stress is linear in the load and
contact stress varies with its square root, so `S_F` is comparable with `S_H^2`.
State the first change that would be made if the design were required to carry
more torque.

## 4. Intermediate-shaft design

Layout with dimensions. Bearing reactions in both planes and the combined
bending-moment diagram, including both helix thrust couples `M_0 = W_a d/2` and
the sign convention adopted. State whether the two tangential forces, the two
radial forces, the two thrusts and the two couples add or oppose, and why. The
endurance limit with every Marin factor stated and justified.
Stress-concentration and notch-sensitivity factors at each shoulder, with the
figure or equation from which each is obtained (`Kt` and `Kts` from the Shigley
Appendix A stress-concentration charts, `q` and `qs` from the bending and
torsion fits for the Neuber constant). The shoulder read from the charts by
hand, compared with `computeShoulderNotchFactors`. Fatigue and yield factors of
safety, `n_f` and `n_y`, at every critical section, including the check on the
stage-2 pinion rim. State which section and which check, fatigue or yield,
governed the diameter. Final mass, and a scaled drawing.

## 5. Bearing selection

Reactions at the intermediate-shaft cubic-mean torque (`T_cubic_mean_int` from
Student 01) used for life, including both thrust couples. Candidate table with
catalog data, showing at least one candidate that fails. The `F_a/C_0` ratio,
the `e` and `Y` interpolated from the Shigley Chapter 11 table, the equivalent
radial loads `F_e` and the rating lives in km. Final designations, with the
catalog page. The static ratio `s_0 = C_0/P_0` of the floating bearing at peak
torque.

State what determined each selection: rating life or the bore required by the
shaft. Where the bore governs, the bearing is not life-limited, and this must be
stated explicitly.

## 6. Integrated design

Demonstrate that the components are mutually compatible. Compare the bearing
bore with the journal diameter, the journal with its shoulder and fillet, and
the gear seat with the gear bore. Give the width of the flat shoulder face,
`(D-d)/2 - r`, at every shoulder and state the component that seats against it.
A table of the final component set with every dimension.

## 7. Design iteration

Document at least one change. Record which check failed or showed excess margin,
the alteration made in response, its effect on the results, and the parameter
that controls the check. If the first trial passes, compare it with a lighter
feasible geometry and justify the final choice.

## 8. Extensions

If the input-shaft extension was taken (Student 03, Task 8; Student 04, Task 5):
the same evidence for the input shaft, and the comparison of thrust couple
against mesh bending moment on the two shafts.

If the finite-life extension was taken (Student 03, Task 9): `sigma_ar`, the S-N
constants and the life in hours at every section at `T_steady`, the governing
section, and whether that life is a credible concern for a road vehicle.

## 9. Assumptions and limitations

As a minimum, state:

- The course approximations listed under [scope and
  limitations](ASSIGNMENT_BRIEF.md#scope-and-limitations) in the assignment
  brief, together with the additions that a production design would require.
- Rigid shafts, rigid mounts, and constant drivetrain efficiency.
- No thermal effects, no lubrication analysis, no gear dynamics beyond the AGMA
  dynamic factor.
- The axial normal stress neglected in the shaft fatigue check, per Chapter 7.
- Gear seats treated as plain cylinders, with no stress concentration from the
  press fit or keys.
- No static check of the locating bearing.
- The coplanar shaft arrangement and the same helix hand on both gears of the
  intermediate shaft, which set how the forces on the intermediate shaft
  combine, whereas a production unit places its shafts to suit the housing.

The limitations must be stated explicitly in the report, as the [assignment
brief](ASSIGNMENT_BRIEF.md#scope-and-limitations) requires.

## 10. References

*Shigley's Mechanical Engineering Design*, 11th ed., with the specific chapters,
figures and tables used. The bearing catalog, with page numbers.
