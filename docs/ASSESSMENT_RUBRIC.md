# What to Assess in SimDrive: EV Transmission Design

These are the things worth assessing in the design assignment. How to weigh
them is the instructor's choice. The prototype challenge in
[`PROTOTYPE_CHALLENGE.md`](PROTOTYPE_CHALLENGE.md) is a separate submission.

- **Load cases, units and torque handoff:** correct use of the peak,
  equivalent-sinusoid and cubic-mean torques; the hill-climb hand check of the
  simulation, with the difference explained.
- **Gear design:** geometry and forces; Shigley/AGMA factors, each with a named
  source; the same AGMA grade for bending and contact strength; per-member cycle
  counts; bending and contact stress; the governing mode compared on a like
  basis; iteration.
- **Shaft design:** reactions in two planes including both helix thrust couples;
  endurance-limit modification (Marin factors); `Kt/Kts` and `q/qs`; DE-Goodman and yield at every
  critical section.
- **Bearing selection:** reactions at the Shigley equivalent load; `e` and `Y`
  interpolated from the Ch. 11 table against `Fa/C0`; `L10`; a rejected candidate; the
  catalog cited.
- **Engineering communication:** units, figures, references, limitations and
  MATLAB work another student can rerun.

When only some parts are assigned, assess those parts together with the load-case
handoff and the communication, since every part depends on the handoff. Where an
upstream result is supplied rather than derived, assess its correct use, not its
derivation.

Numerical agreement with the reference solution is not enough on its own, and
disagreement is not an error in itself: the reference is one valid design, and
the design depends on the choices each student makes within the constraints of
the project. Look for correct load paths, stated assumptions, Shigley
traceability and defensible iteration. Accept any choice Shigley itself allows
when it is sourced (for example `K_s` from the Ch. 14 size-factor expression rather than 1). A
method from outside Shigley needs the instructor's explicit approval.
