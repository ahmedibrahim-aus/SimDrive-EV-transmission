# Assessment Rubric for SimDrive: EV Transmission Design

This rubric governs the design assignment. The separate weighting in
`PROTOTYPE_CHALLENGE.md` governs the prototype challenge only, which is a
distinct submission. Do not apply both to the same piece of work.

The weights below are for the full project, all three design parts. When only
some parts are assigned, drop the rows that do not apply and rescale the rest to
100. Keep `Load cases, units, and torque handoff` in every variant, since it is
the handoff every part depends on, and keep `Engineering communication`. Where an
upstream result is supplied rather than derived, credit its correct use, not its
derivation.

| Area | Points | Evidence |
|---|---:|---|
| Load cases, units, and torque handoff | 15 | Correct use of the peak, equivalent-sinusoid and cubic-mean torques; the hill-climb hand check of the simulation with the difference explained |
| Gear design | 25 | Geometry, forces, Shigley/AGMA factors each with a named source, the same AGMA grade for bending and contact strength, per-member cycle counts, bending/contact stress, governing mode compared on a like basis, iteration |
| Shaft design | 25 | Reactions in two planes including both helix thrust couples, endurance modification, `Kt/Kts`, `q/qs`, DE-Goodman, yield at every critical section |
| Bearing selection | 15 | Reactions at the Eq. (11-17) equivalent load, Table 11-1 `e` and `Y` interpolated against `Fa/C0`, `L10`, a rejected candidate, catalog citation |
| Integration and iteration | 15 | Compatible bores/seats, a flat shoulder face at every shoulder, passing targets, practical mass, justified changes |
| Engineering communication | 5 | Units, figures, references, limitations, reproducible MATLAB work |
| **Total** | **100** | |

Numerical agreement alone does not earn full credit, and disagreement with the reference solution is not an error in itself: the reference is one valid design, and the design depends on the choices each student makes within the constraints of your project document. Award design points for correct load paths, assumptions, Shigley traceability, and defensible iteration. Accept any choice Shigley itself allows when it is sourced (for example `K_s` from Sec. 14-10 Eq. (a) rather than 1). Apply a major deduction only when a student uses a method from outside Shigley without explicit instructor approval.
