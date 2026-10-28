# What to assess in SimDrive: EV Transmission Design

These are the things worth assessing in the design assignment. How to weigh them
is the instructor's choice. The prototype challenge in
[`PROTOTYPE_CHALLENGE.md`](PROTOTYPE_CHALLENGE.md) is a separate submission.

| Area | What to look for |
|---|---|
| Load cases, units and torque handoff | Correct use of the peak, equivalent-sinusoid and cubic-mean torques; the hill-climb hand check of the simulation, with the difference explained |
| Gear design | Geometry and forces; Shigley/AGMA factors, each with a named source; the same AGMA grade for bending and contact strength; per-member cycle counts; bending and contact stress; the governing mode compared on a like basis; iteration |
| Shaft design | Reactions in two planes including both helix thrust couples; endurance-limit modification (Marin factors); `Kt/Kts` and `q/qs`; DE-Goodman and yield at every critical section |
| Bearing selection | Reactions at the Shigley equivalent load; `e` and `Y` interpolated from the Chapter 11 table against `Fa/C0`; `L10`; a rejected candidate; the catalog cited |
| Engineering communication | Units, figures, references, limitations and MATLAB work another student can rerun |

When only some parts are assigned, assess those parts together with the
load-case handoff and the communication, since every part depends on the
handoff. Where an upstream result is supplied as given data, assess how it is
used.

Numerical agreement with the reference solution is not enough on its own, and
disagreement is not an error in itself (see
[`instructor/solution/README.md`](../instructor/solution/README.md)). Look for
correct load paths, stated assumptions, Shigley traceability and defensible
iteration. Accept any choice Shigley itself allows when it is sourced (for
example `K_s` from the Chapter 14 size-factor expression instead of 1). A method
from outside Shigley needs the instructor's explicit approval.
