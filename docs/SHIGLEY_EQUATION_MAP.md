# Shigley 11th-Edition Equation Map

This file defines the equation boundary for the assessed student solution. Page numbers vary by printing; chapter, equation, table and figure identifiers are authoritative.

| Student task | Shigley 11e source | Repository implementation |
|---|---|---|
| Transverse helical-gear geometry and gear forces | Ch. 13, helical-gear relations for `phi_t`, `m_t` and the `W_t`/`W_r`/`W_a` force set | `Student_02_Gear_Design` |
| Preferred normal modules of the gear train | Ch. 13, Table 13-2 (first-choice modules); the dashboard refuses others | `buildGearTrain.m` |
| Minimum pinion teeth without interference | Ch. 13, Eq. (13-22), helical form, full depth (`k = 1`), against the actual mate | `buildGearTrain.m` |
| AGMA bending rating | Ch. 14, Eq. (14-15) with `K_o`, `K_v`, `K_s`, `K_H`, `K_B`; Eq. (14-17) for the allowable | `Student_02_Gear_Design` |
| AGMA pitting rating | Ch. 14, Eq. (14-16) with `Z_E`, `Z_R`, `I`; Eq. (14-18) for the allowable | `Student_02_Gear_Design` |
| Dynamic factor and its velocity limit | Ch. 14, Eqs. (14-27) and (14-29) | `Student_02_Gear_Design` |
| Load-distribution factor | Ch. 14, Eqs. (14-30) to (14-35) with the Table 14-9 `C_ma` coefficients | `Student_02_Gear_Design` |
| Pitting geometry factor `I` | Ch. 14, Eqs. (14-21) to (14-25), length of action | `Student_02_Gear_Design` |
| Bending geometry factor `J` | Ch. 14, Figure 14-7 for `J'` and Figure 14-8 for the multiplier, read at each member's own tooth count as in Example 14-5 | `Student_02_Gear_Design` |
| Bending and contact strength against hardness | Ch. 14, Figure 14-2 (`S_t`) and Figure 14-5 (`S_c`), Grade 1 lines | `Student_02_Gear_Design` |
| Stress-cycle factors | Ch. 14, Figure 14-14 (`Y_N`) and Figure 14-15 (`Z_N`), applied at each member's own cycle count | `Student_02_Gear_Design` |
| Reliability factor | Ch. 14, Table 14-10; `K_R = 1.00` at 99 percent (distinct from bearing L10 at 90 percent) | `Student_02_Gear_Design` |
| Like-basis safety-factor comparison | Ch. 14, `S_F` against `S_H^2` because contact stress goes as the square root of load | `Student_02_Gear_Design` |
| Rim-thickness factor of the pinion pressed onto the intermediate shaft | Ch. 14, Eq. (14-40); `K_B = 1` requires backup ratio `m_B = t_R/h_t >= 1.2` | `Student_03_Shaft_Design` |
| Shaft material properties | Table A-20 and Table A-21 | `Student_03_Shaft_Design` |
| Shaft layout, locating shoulders and seating faces | Ch. 7, Sec. 7-3 | `Student_03_Shaft_Design` |
| Shaft reactions, critical sections and the helix thrust couples | Ch. 7 with the Ch. 13 vector moment balance about the bearings, in which the position vector runs to each tooth force, so each `W_a` contributes a couple `M_0 = T tan(psi)` in the radial plane while `W_r` contributes none; on the intermediate shaft the two same-hand couples act in the same sense; the same hand is the Sec. 13-10 rule for helical gears sharing a shaft (minimum thrust) | `Student_03_Shaft_Design` |
| Neglect of gear-induced axial stress in fatigue | Ch. 7, Sec. 7-4 | `Student_03_Shaft_Design` |
| Endurance limit and Marin factors | Ch. 6, Eq. (6-10) for `S'_e`, Marin Eq. (6-17) with the factor relations Eqs. (6-18) to (6-25) and Table 6-2 | `Student_03_Shaft_Design` |
| Modified Goodman relation | Ch. 6, Eqs. (6-40) and (6-41); Ch. 7 shaft form, Eqs. (7-7) and (7-8) | `Student_03_Shaft_Design` |
| Distortion-energy equivalent stress and static yield, with `K_f` and `K_fs` on the peak stresses | Ch. 5 and Ch. 7, Eqs. (7-15) and (7-16) | `Student_03_Shaft_Design` |
| Keyseat stress-concentration factors, if the seat is keyed | Ch. 7, Table 7-1, end-milled keyseat | `Student_03_Shaft_Design` |
| Axial shoulder `Kt` | Figure A-15-7 | `computeShoulderNotchFactors.m` |
| Torsional shoulder `Kts` | Figure A-15-8 | `computeShoulderNotchFactors.m` |
| Bending shoulder `Kt` | Figure A-15-9 | `computeShoulderNotchFactors.m` |
| Bending/axial notch sensitivity `q` | Eq. (6-33), combined with Kt in Eq. (6-34), with the Eq. (6-35) curve fit for the Neuber constant; Figure 6-26 plots the same fit | `computeShoulderNotchFactors.m` |
| Torsional notch sensitivity `qs` | Eq. (6-33), combined in Eq. (6-34), with the torsional Eq. (6-36) curve fit; Figure 6-27 plots the same fit | `computeShoulderNotchFactors.m` |
| Fatigue factors | Ch. 6, Eq. (6-32): `Kf=1+q(Kt-1)` and `Kfs=1+qs(Kts-1)` | `computeShoulderNotchFactors.m` |
| Bearing equivalent dynamic load | Ch. 11, `P = X F_r + Y F_a` with `X`, `Y` and `e` from Table 11-1 against `F_a/C_0` | `Student_04_Bearing_Selection` |
| Bearing equivalent load for a varying load | Ch. 11, Sec. 11-7, Eq. (11-17): cubic mean weighted by revolutions (`T_cubic_mean`) | `Student_04_Bearing_Selection` |
| Bearing rating life | Ch. 11, `L_10 = (C/P)^a` with `a = 3` for ball bearings | `Student_04_Bearing_Selection` |
| Finite life on a sustained climb (extension) | Ch. 6, Sec. 6-8, Eqs. (6-11) to (6-15); fully reversed equivalent stress, Eq. (6-59) | `Student_03_Shaft_Design`, Task 9 |

Manufacturer catalogs may supply bearing dimensions, `C` and `C0`. They are data sources, not alternative equation sources.

## What is not used

- **No static bearing check.** `L_10` life is the sole bearing criterion, and `C_0` appears only as the argument of Table 11-1. Shigley 11e gives `C_0` but not the combined static factors `X_0` and `Y_0` a thrust-carrying bearing needs (the ISO 76 form `P_0 = max(0.6 F_r + 0.5 F_a, F_r)` is a catalog formula outside the course text). The floating bearing carries no thrust, so for it `P_0 = F_r` needs no such factors, and at the drag-race peak that load exceeds the selected bearing's `C_0`. This is a stated limitation of the course key; see `MathematicalModels.md`, Section 10.4.
- **No bearing reliability adjustment and no application factor.** The Eqs. (11-9)/(11-10) Weibull adjustment and `a_f` exist in Ch. 11, but this project accepts the 90 percent reliability that `L_10` already means, and says so in the answer key.
- **No axial normal stress in the shaft fatigue check.** Ch. 7 states that gear-induced axial stresses are almost always negligible against bending, are usually steady, and may be neglected when bending is present. The static yield check keeps the axial term.
- **No stress raiser at the gear seats, by assumption.** The gears are held by a press fit or keys, whose design is outside the project; for simplicity they are assumed to introduce no stress concentration. This is a stated simplification, not a Shigley result: Sec. 7-8 notes a press fit raises the stress at the hub ends (typically up to about 2), and Table 7-1 gives keyseat factors.

## Chart basis

The source figure images supplied by the project author are used for internal verification and are not distributed with this module.

The three `Kt` surfaces are digitized from the named A-15 charts. Entries read directly off a plotted curve carry an estimated reading tolerance of ±0.05. The grids cover `r/d` from 0.025 to 0.100 and `D/d` from 1.05 to 1.50; below `r/d = 0.025` the printed curves have not begun, so smaller fillets are refused. Six Figure A-15-7 entries (D/d = 1.05 at r/d = 0.025 and 0.030; D/d = 1.10 at r/d = 0.025; D/d = 1.50 at r/d = 0.025, 0.030 and 0.040) lie where the plotted curve has not started; they are extrapolations of it, named in `computeShoulderNotchFactors.m`. The two notch sensitivities are not digitized: they are evaluated from the Shigley SI curve fits, Eq. (6-35) for bending and Eq. (6-36) for torsion, which are what Figures 6-26 and 6-27 draw, and `S_ut` is validated against the 415 to 1400 MPa range those figures cover. Shigley states the fits for 340 to 1700 MPa (bending) and 340 to 1500 MPa (torsion); the narrower range is a course choice.
