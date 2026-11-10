# Assessment guide for SimDrive: EV Transmission Design

This guide lists the areas to assess in the design assignment. The weighting of
the areas is at the discretion of the instructor. The prototype challenge in
[`PROTOTYPE_CHALLENGE.md`](PROTOTYPE_CHALLENGE.md) is a separate submission.

| Area | Indicators |
|---|---|
| Load cases, units and torque transfer | Correct use of the peak, equivalent-sinusoid and cubic-mean torques; the hill-climb hand check of the simulation, with the difference explained |
| Gear design | Geometry and forces; Shigley/AGMA factors, each with a named source; the same AGMA grade for bending and contact strength; per-member cycle counts; bending and contact stress; the governing mode compared on a like basis; iteration |
| Shaft design | Reactions in two planes including both helix thrust couples; endurance-limit modification (Marin factors); `Kt/Kts` and `q/qs`; DE-Goodman and yield at every critical section |
| Bearing selection | Reactions at the Shigley equivalent load; `e` and `Y` interpolated from the Chapter 11 table against `Fa/C0`; `L10`; a rejected candidate; the catalog cited |
| Engineering communication | Units, figures, references, limitations and MATLAB work that another student can reproduce |

When only some parts are assigned, assess those parts together with the
load-case transfer and the communication, since every part depends on the
transfer. Where an upstream result is supplied as given data, assess its use.

Numerical agreement with the reference solution is not sufficient in itself, and
disagreement is not in itself an error (see
[`instructor/solution/README.md`](../instructor/solution/README.md)). The
assessment should consider correct load paths, stated assumptions, Shigley
traceability and defensible iteration. Any choice that Shigley permits is
acceptable when its source is cited (for example `K_s` from the Chapter 14
size-factor expression instead of 1). A method from outside Shigley requires the
explicit approval of the instructor.
