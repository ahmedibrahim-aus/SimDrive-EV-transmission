# SimDrive: EV Transmission Design
## Physics and Modeling Reference

*Ahmed Hanafy Ibrahim, Assistant Professor (ahmedibrahim@aus.edu)*<br>
*Mahmoud Al Herbawi and Malek Zahir, senior undergraduate students*<br>
*Financial support: MathWorks Teaching Support Award*

---

## 1. Introduction and Scope

This document describes the simulation in full: vehicle dynamics model, motor torque-speed envelope, speed-tracking control, the fatigue load reduction, and unit conventions. Every computed quantity exported to the student design files is traceable to the equations below.

---

## 2. Workflow

### 2.1 Instructor Side

1. Set vehicle, motor, and control parameters in `main.mlx` (or the GUI).
2. Run the Simulink model for three load cases: FTP-75, Hill Climb, Drag Race.
3. Export to `exports_design_ready/`, then build the student hand-out with `buildStudentPackage`, which reduces each case to the design scalars and one 2000-point torque curve.

---

### 2.2 Student Side

Students receive the design torques already reduced, including the FTP-75 mean and alternating pair, and work through the AGMA gear rating, Shigley shaft fatigue and rolling-contact bearing life as those procedures are presented in Shigley 11e. They do not perform the reduction themselves; Section 8 is instructor-side data preparation. They iterate on geometry until every safety factor and the life target are met.

---

## 3. Modeling Philosophy and Assumptions

### 3.1 Torque-Based Design Input

Shigley-based design begins from known external loads and proceeds to analytical stress computation. This project follows the same approach: the motor output torque serves as the gearbox input torque. The electrical side of the motor is not modeled, and the gearbox is treated as rigid with a constant drivetrain efficiency.

---

## 4. Vehicle Longitudinal Dynamics

The model is the standard lumped-mass, one-dimensional formulation: the vehicle is represented as a point mass translating along its longitudinal axis.

### 4.1 Governing Equation

$$
m_{\text{eff}} \frac{dv}{dt} = F_{\text{trac}} - F_{\text{roll}} - F_{\text{aero}} - F_{\text{grade}}
$$

where:

- $m_{\text{eff}}$ = effective vehicle mass including rotational inertia [kg] (see §4.6)
- $v$ = vehicle longitudinal speed [m/s]
- $t$ = time [s]

Weight-based forces ($F_{\text{roll}}$, $F_{\text{grade}}$) use the actual vehicle mass $m$, not $m_{\text{eff}}$.

This is the standard treatment; see Gillespie (1992) Ch. 1 or Guzzella and Sciarretta (2013) Ch. 2.

---

### 4.2 Tractive Force

The drivetrain loss always sits on the output side of the power flow: at the wheels when the motor drives, at the motor when the wheels drive it during regenerative braking.

$$
F_{\text{trac}} = \begin{cases} \dfrac{\eta_{\text{dt}} T_m G}{R_w}, & T_m \ge 0 \text{ (driving)} \cr  \dfrac{T_m G}{\eta_{\text{dt}} R_w}, & T_m < 0 \text{ (regenerating)} \end{cases}
$$

where:

- $\eta_{\text{dt}}$ = drivetrain efficiency [-] (see §4.7)
- $T_m$ = electric motor output torque (gearbox input torque) [N·m]
- $G$ = fixed gear ratio (motor speed / wheel speed) [-]
- $R_w$ = effective rolling radius of the driven wheel [m] (see §4.8)

Assumptions:
- rigid driveline,
- no wheel slip.

---

### 4.3 Rolling Resistance

$$
F_{\text{roll}} = C_{rr} m g
$$

where:

- $C_{rr}$ = coefficient of rolling resistance [-]
- $g$ = gravitational acceleration (9.81 m/s²)

---

### 4.4 Aerodynamic Drag

$$
F_{\text{aero}} = \frac{1}{2} \rho C_d A \lvert v\rvert v
$$

where:

- $\rho$ = air density computed from ambient conditions [kg/m³] (see §4.9)
- $C_d$ = aerodynamic drag coefficient [-]
- $A$ = vehicle frontal area [m²]

---

### 4.5 Grade Resistance

$$
F_{\text{grade}} = m g \sin(\theta)
$$

where:

- $\theta$ = road inclination angle [rad]
- the implementation passes $\sin(\theta)$ directly to the Simulink model

---

### 4.6 Effective Mass (Rotational Inertia)

$$
m_{\text{eff}} = m + \frac{I_{\text{motor}} G^2 + 4 I_{\text{wheel}}}{R_w^2}
$$

where:

- $m$ = vehicle mass [kg]
- $I_{\text{motor}}$ = motor rotor moment of inertia [kg·m²]
- $I_{\text{wheel}}$ = moment of inertia of one wheel+tire assembly [kg·m²]
- $G$ = gear ratio [-]
- $R_w$ = tire radius [m]

Wheel+tire modeled as a thick annular ring; $I_{\text{wheel}}$ is given in §4.8.


---

### 4.7 Drivetrain Efficiency

A constant $\eta_{\text{dt}} = 0.97$ is used throughout. It covers the two meshes together, about 0.985 per mesh, inside the range typical of helical reduction gearboxes (Niemann and Winter, 1989). The loss is split equally, $\sqrt{\eta_{\text{dt}}}$ per mesh (Section 9). Speed- and load-dependent losses are neglected; real efficiency varies slightly, but the effect on component sizing is negligible.

---

### 4.8 Wheel and Tire Specification

The tire radius $R_w$ is specified directly as a single input (default: 0.334 m, the unloaded radius of a 235/45R18 tire; a loaded rolling radius is about 2 to 4 percent smaller). This avoids the need to parse tire size designations and lets the instructor enter a measured or datasheet value.

For the wheel+tire inertia estimate, the user selects a tire profile (low, standard, or high), which sets the rim-to-radius ratio $r_{\text{rim}}/R_w$:

| Profile | Typical aspect ratio | $r_{\text{rim}} / R_w$ |
|---|---|---|
| Low | 35-40 | 0.74 |
| Standard | 45-55 | 0.68 |
| High | 60-70 | 0.62 |

The wheel+tire assembly is modeled as a thick annular ring with a fixed assembly mass of 20 kg (a representative value for a passenger-car wheel and tire):

$$
I_{\text{wheel}} = \frac{1}{2} m_{\text{wheel}}\left(1 + \left(\frac{r_{\text{rim}}}{R_w}\right)^2\right) R_w^2
$$

This is the exact second moment for a uniform annular ring with inner radius $r_{\text{rim}}$ and outer radius $R_w$. The profile selection is a minor correction. The difference between low and high profile is about 10 percent in $I_{\text{wheel}}$, which translates to less than 1 percent of the effective mass.

---

### 4.9 Air Density

Air density is computed from the ambient conditions rather than assuming the ISA standard value, because ambient temperature and humidity measurably influence air density and therefore the aerodynamic drag force:

$$
\rho = \frac{p_{\text{atm}} - p_v}{R_d T_K} + \frac{p_v}{R_v T_K}
$$

where:

- $p_{\text{atm}}$ = atmospheric pressure [Pa] (default: 101325)
- $T_K$ = ambient temperature in kelvin ($T_K = T_C + 273.15$)
- $R_d = 287.058$ J/(kg·K) = specific gas constant for dry air
- $R_v = 461.495$ J/(kg·K) = specific gas constant for water vapor

Saturation vapor pressure via Tetens:

$$
p_{\text{sat}} = 610.78 \exp\left(\frac{17.27 T_C}{T_C + 237.3}\right)
$$

$$
p_v = \text{RH} \times p_{\text{sat}}
$$

where RH is the relative humidity as a fraction [0-1].

At the default conditions ($T_C = 25$°C, $p_{\text{atm}} = 101325$ Pa, RH = 0.50), this yields $\rho = 1.177$ kg/m³, compared with the ISA standard value of 1.225 kg/m³ at 15°C dry air.

---

## 5. Motor Torque-Speed Envelope

When the motor drives ($T_m \ge 0$), its torque is bounded by $T_{\max}$ at low speed and by the available power above base speed. Regeneration has its own limit (Section 5.3).

### 5.1 Constant Torque Region

$$
T_m \le T_{\max}
$$

### 5.2 Constant Power Region

Above base speed ($\omega_{\text{base}} = P_{\max}/T_{\max}$), available torque drops as $1/\omega$:

$$
T_m \le \frac{P_{\max}}{\omega_m}
$$

Motor speed follows from kinematics: $\omega_m = G v / R_w$. This is the standard EV envelope shape (Ehsani et al., 2018).

**Speed limit.** The motor is limited to $\omega_{\max}$ (`n_max` = 16,000 rpm by default, about 224 km/h at $G = 9$). The available torque tapers linearly to zero over the last 5 percent below $\omega_{\max}$, as a motor controller's speed limiter does:

$$
T_m \le \min\left(T_{\max}, \frac{P_{\max}}{\omega_m}\right) \cdot \min\left(\max\left(\frac{\omega_{\max} - \lvert\omega_m\rvert}{0.05\thinspace \omega_{\max}}, 0\right), 1\right)
$$

The gear rating uses two speeds: $K_v$ at the base speed, where $T_{\text{peak}}$ acts, and the quality-number velocity check (Shigley Ch. 14) at a course speed of 120 km/h. Near $\omega_{\max}$ the stage-1 pitch-line velocity would exceed the $Q_v = 11$ limit.

### 5.3 Regenerative Braking

Regen is capped separately:

$$
T_m \ge -T_{\text{regen}}
$$

---

## 6. FTP-75 Speed Control

The FTP-75 case uses a discrete PID controller to track the reference speed profile:

$$
e(t) = v_{\text{ref}}(t) - v(t)
$$

Commanded torque:

$$
T_{\text{cmd}}(t) = K_p e(t) + K_i \int e(t) dt + K_d \frac{de(t)}{dt}
$$

where:

- $K_p$, $K_i$, $K_d$ = proportional, integral, and derivative gains

All control computations run in SI units (m/s). The torque command passes through an actuator lag, rate limiter, and envelope saturation before reaching the plant. Consequently, the exported torque histories reflect what the motor actually delivers, not the raw PID output.

---

## 7. Load Cases

| Case | Control | Output |
|------|---------|--------|
| FTP-75 | PID speed tracking | Fatigue spectrum, bearing life |
| Hill Climb | Open-loop, full torque on grade | `T_steady` |
| Drag Race | Open-loop, full torque, flat road | `T_peak` for AGMA + yield |

---

## 8. Fatigue Load Extraction

The FTP-75 simulation produces an irregular torque history: many cycles with different mean torque, amplitude, and duration. Shigley's modified Goodman criterion is normally applied with one mean stress and one alternating stress, so the simulation reduces the FTP-75 torque history to one equivalent mean and amplitude pair before students start the shaft design.

### 8.1 Equivalent-Sinusoid Inputs

The simulation uses rainflow cycle counting, the standard method for reducing an irregular fatigue history into closed and half cycles. The implementation calls MATLAB `rainflow()` following ASTM E1049. For each counted cycle, the algorithm returns a cycle count $n_i$, a torque range $\Delta T_i$, and a cycle mean torque $T_{m,i}$.

$$
T_{a,i} = \frac{\Delta T_i}{2}
$$

Cycles whose range is below 2 percent of the full torque range while the vehicle is moving (speed above 5 km/h) are dropped first: they are speed-controller ripple, not driving events, and would otherwise dominate the count and dilute the averages in the next two equations without adding damage.

The damage-equivalent alternating torque is then computed using Palmgren-Miner's linear damage rule. If the S-N curve is approximated by $N S^m = \text{constant}$, preserving total damage gives:

$$
T_{\text{alt,eq}} = \left( \frac{\sum n_i T_{a,i}^{m}}{\sum n_i} \right)^{1/m}
$$

where $m=3$ is the fixed course reduction exponent. It is an instructor-side preprocessing choice, not a student design variable. For comparison, the Shigley S-N line of the reference shaft has $1/\lvert b\rvert \approx 6$; a larger exponent gives a larger $T_{\text{alt,eq}}$, so $m = 3$ is not conservative. The sensitivity is a suggested student extension.

The equivalent mean torque is the cycle-count-weighted average:

$$
T_{\text{mean,eq}} = \frac{\sum n_i T_{m,i}}{\sum n_i}
$$

The instructor-side simulation converts a realistic FTP-75 history into the mean and alternating components needed for the modified Goodman calculation. A fully rigorous variable-amplitude fatigue analysis would apply mean-stress correction and damage accumulation to each counted cycle individually. That extension is outside this exercise: students receive only the equivalent sinusoidal inputs and apply the Shigley equations.

**Requires:** the Signal Processing Toolbox. No alternative fatigue method is implemented.

### 8.2 Equivalent Sinusoid

The irregular FTP-75 torque history is reduced to a single equivalent sinusoid:

$$
T_{\text{eq}}(t) = T_{\text{mean,eq}} + T_{\text{alt,eq}} \sin\left(\frac{2\pi t}{\tau}\right)
$$

with period $\tau = 120$ s. The values $T_{\text{mean,eq}}$ and $T_{\text{alt,eq}}$ are the rainflow-derived design inputs for the modified Goodman diagram. They define the mean stress and alternating stress that the shaft must withstand for infinite life. The instructor plot shows the sinusoid against the tracked torque trace so the reduction can be inspected. Students receive the sinusoid as their FTP-75 torque curve and in their FTP-75 plot, as the curve their Goodman calculation actually uses. The overview figure of all three cases shows the raw trace for context only.

### 8.3 Bearing Equivalent Torque

Bearing life uses the revolution-weighted cubic mean of the torque history, the Shigley Ch. 11 equivalent load; see Section 9.3.

---

## 9. Student Design Equations

The transmission is single speed with two helical stages on three parallel shafts in one plane. Stage 1 runs from the input pinion ($N_1$, diameter $d_1$) to the intermediate gear ($N_2$, $d_2$); stage 2, the final drive, runs from the intermediate pinion ($N_3$, $d_3$) to the output gear ($N_4$, $d_4$), which carries the differential. The overall ratio is

$$
G = \frac{N_2}{N_1}\thinspace \frac{N_4}{N_3} = i_1\thinspace i_2
$$

The simulation exports motor torque, which is the input-shaft torque. Each mesh takes the same share of the drivetrain loss, so the intermediate and output torques are

$$
T_{\text{int}} = T_{\text{in}}\thinspace i_1\sqrt{\eta_{\text{dt}}}, \qquad T_{\text{out}} = T_{\text{in}}\thinspace G\thinspace \eta_{\text{dt}}
$$

At each mesh, with $T$ the torque on that stage's pinion shaft and $d$ its pinion diameter:

$$
W_t = \frac{2T}{d}, \qquad W_r = W_t \tan\phi_t, \qquad W_a = W_t \tan\psi
$$

where $\phi_t = \arctan(\tan\phi_n / \cos\psi)$ is the transverse pressure angle. These forces give the shaft bending moments, the bearing reactions and the tooth stresses. Which torque you use depends on what you are sizing:

| Task | Torque | Load case |
|---|---|---|
| Gear tooth stress, both stages | $T_{\text{peak}}$ | Drag Race |
| Shaft fatigue (Goodman) | $T_{\text{mean,eq}}$, $T_{\text{alt,eq}}$ | FTP-75 |
| Shaft yield | $T_{\text{peak}}$ | Drag Race |
| Bearing L10 | $T_{\text{cubic mean}}$ | FTP-75 |
| Validation hand check; finite-life extension | $T_{\text{steady}}$ | Hill Climb |

### 9.1 Gear Design (AGMA Procedure as Presented in Shigley 11e)

Both stages are rated by the same procedure. Bending stress in its SI form:

$$
\sigma = W_t K_o K_v K_s \frac{1}{b m_t} \frac{K_H K_B}{Y_J}
$$

Contact stress in its SI form:

$$
\sigma_c = Z_E \sqrt{W_t K_o K_v K_s \frac{K_H}{d_{w1} b} \frac{Z_R}{Z_I}}
$$

Shigley Ch. 14 pairs each SI symbol with its U.S. customary one: $b$ ($F$), $K_H$ ($K_m$), $Y_J$ ($J$), $Z_E$ ($C_p$), $Z_R$ ($C_f$), $Z_I$ ($I$), $d_{w1}$ ($d_P$). The student templates use the customary symbols.

The answer key (`rateHelicalStage`) makes its design choices by rule so that it stays valid for any gear train the instructor sets: the lowest $Q_v$ whose velocity limit clears the pitch-line velocity at 120 km/h (`courseTargets`) and at the $K_v$ rating speed, face width searched in 5 mm steps across the $3p_t$ to $5p_t$ band, and the softest AISI 4340 row of the Shigley Appendix A steel table that passes at the narrowest passing width. $J$ is read from the digitized Shigley Ch. 14 helical geometry-factor charts (`computeHelicalJ`). With the stage-2 module left to the key, the dashboard exports the smallest preferred module (Shigley Ch. 13) that passes the stage-2 rating.

---

### 9.2 Intermediate Shaft Fatigue (DE-Goodman)

The intermediate shaft is designed as a **stepped** shaft: a journal at each bearing and one raised seat carrying the stage-1 gear and the stage-2 pinion, with a shoulder at each end of the seat. Its mass is minimized over the prescribed search grid subject to section safety factors. The journal is selected from standard metric bearing bores and must nominally match the selected bearing. The seat shoulders are also the bearing abutments: the flat face kept at each shoulder is a geometric constraint of the shaft design, and Student 04 checks each shoulder against the catalog abutment diameter and corner radius of the selected bearing. Both gears are held by a press fit or keys whose design is outside the project; for simplicity they are assumed to introduce no stress concentration, so the two gear stations are plain sections (a stated simplification: Shigley Ch. 7 notes that press fits do raise the stress at the hub ends). The stage-2 pinion rim must keep a backup ratio of at least 1.2 (Shigley Ch. 14), so that $K_B = 1$ holds. Total mass is $m = \sum_i \rho \frac{\pi}{4} d_i^2 L_i$.

Combined bending and torsion. On a rotating shaft, bending is fully reversed. With the shaft axis along x and the three shaft axes in the x-z plane, the stage-1 mesh sits on the $+z$ side and the stage-2 mesh on the $-z$ side. Taking moments with the position vector to each mesh point:

- the two tangential forces point the same way in the x-y plane and add. The stage-1 gear carries the stage-1 mesh force $2T_{\text{in}}/d_1$ and the stage-2 pinion carries $2T_{\text{int}}/d_3$; their moments about the axis differ only by the stage-1 mesh loss, and the shaft carries $T_{\text{int}}$ between the two gears;
- the two radial forces point at the axis from opposite sides and oppose in the x-z plane;
- both gears have the same helix hand, which is the Shigley Ch. 13 rule for helical gears sharing a shaft (choose the hands for minimum thrust); one is driven and one driving, so their thrusts oppose and the locating bearing carries $|W_{a3} - W_{a2}|$;
- each thrust acts at its pitch radius and applies a couple in the x-z plane,

$$
M_0 = W_a \frac{d}{2} = T \tan\psi
$$

and because the thrusts are opposite and act on opposite sides of the axis, the two couples have the **same** sense and add. Their common sign depends on helix hand and direction of rotation, which this project does not fix, so both signs are evaluated and the worse is taken at every section.

Each plane is solved as a simply supported beam (`simplySupportedMoment`, which asserts force and moment equilibrium), with the couples stepping the x-z diagram at their stations, and the planes are combined only at the end:

$$
M_{\mathrm{res}} = \sqrt{M_{xy}^2 + M_{xz}^2}
$$

The pitch diameter cancels between $W_a = W_t\tan\psi$ and $W_t = 2T/d$, so each $M_0 = T\tan\psi$ exactly, and the solution asserts that identity at run time. This follows the Shigley moment balance about the bearings, in which the position vector runs to the tooth force and the axial component therefore contributes a couple.

Bending stress from the resultant: $\sigma_b = 32 M_{\mathrm{res}} / (\pi d^3)$. Torsional shear separately: $\tau_t = 16T / (\pi d^3)$. Axial normal stress is not carried into the fatigue check. Shigley Ch. 7 states that the axial stresses transmitted to a shaft by helical gears or tapered roller bearings are almost always negligible against the bending stress, are usually steady, and may be neglected when bending is present. Here the axial stress follows the torque, not the rotation, and its range is about 2 to 3 percent of the alternating bending stress. The static yield check applies $K_f$ and $K_{fs}$ to the peak stresses and retains the axial term.

Shoulder stress concentration factors are evaluated from the trial geometry ratios $D/d$ and $r/d$:

$$
K_f = 1 + q(K_t - 1), \qquad K_{fs} = 1 + q_s(K_{ts} - 1)
$$

with the steel notch-sensitivity estimate

$$
q = \frac{1}{1 + \sqrt{a}/\sqrt{r_{\mathrm{mm}}}}
$$

and the corresponding torsional sensitivity is

$$
q_s = \frac{1}{1 + \sqrt{a_s}/\sqrt{r_{\mathrm{mm}}}}.
$$

Here $\sqrt{a}$ and $\sqrt{a_s}$ are the separate Shigley steel fits as functions of $S_{ut}$, and $r_{\mathrm{mm}} = (r/d)d$ is the fillet radius in millimeters. The worked solution calls `computeShoulderNotchFactors(D/d, r/d, S_ut, d_mm)` for every candidate. The helper returns separate `K_t` values for axial and bending loading, `K_{ts}` for torsion, and the corresponding fatigue factors. Its three `K_t` surfaces were digitized from the Shigley 11th-edition Appendix A charts for a shouldered round shaft in tension, torsion and bending, with linear interpolation between digitized points. The grids cover $r/d$ from 0.025 to 0.100 and $D/d$ from 1.05 to 1.50; below $r/d = 0.025$ the printed curves have not begun, so smaller fillets are refused. Entries read off a plotted curve carry a chart-reading tolerance of about 0.05 in $K_t$; six entries of the tension chart (D/d = 1.05 at r/d = 0.025 and 0.030; D/d = 1.10 at r/d = 0.025; D/d = 1.50 at r/d = 0.025, 0.030 and 0.040) lie where the plotted curve has not started, are extrapolations of it, and are named in the helper. The two notch sensitivities are not digitized; they are evaluated from the Shigley curve fits above, which is the relation the Ch. 6 notch-sensitivity charts plot.

DE von Mises equivalent stresses:

$$
\sigma_{a}^{\prime} = \sqrt{\left(\frac{32 K_f M_a}{\pi d^3}\right)^2 + 3\left(\frac{16 K_{fs} T_a}{\pi d^3}\right)^2}
$$

$$
\sigma_{m}^{\prime} = \sqrt{3}\thinspace \frac{16 K_{fs} T_m}{\pi d^3}
$$

Rotation makes bending fully reversed, so $M_m = 0$ and $M_a$ is the moment at the peak torque of the equivalent cycle, $T_{\text{mean,eq}} + T_{\text{alt,eq}}$; $T_m$ and $T_a$ are $T_{\text{mean,eq}}$ and $T_{\text{alt,eq}}$ carried to the intermediate shaft. This is a course simplification: see Section 10.4, "Bending cycles per revolution".

Modified Goodman criterion with von Mises stresses, the form behind the DE-Goodman shaft equation:

$$
\frac{\sigma_{a}^{\prime}}{S_e} + \frac{\sigma_{m}^{\prime}}{S_{ut}} \le \frac{1}{n}
$$

---

### 9.3 Bearing Life (Shigley Rating-Life Procedure)

Equivalent radial load (Shigley Ch. 11), with the rotation factor $V = 1$ (inner ring rotates) and $X$, $Y$ from the Ch. 11 table against $F_a/C_0$:

$$
F_e = X_i V F_r + Y_i F_a
$$

The bearing load is the revolution-weighted cubic mean of the FTP-75 torque, the Shigley Ch. 11 equivalent load, $F_{eq} = [\frac{1}{\phi}\int_0^\phi F^a d\theta]^{1/a}$ with $a = 3$ for ball bearings:

$$
T_{\text{cubic mean}} = \left(\frac{\int \lvert T(t)\rvert^3 \lvert\omega(t)\rvert \mathrm{d}t}{\int \lvert\omega(t)\rvert \mathrm{d}t}\right)^{1/3}
$$

The mesh forces and so the reactions are proportional to torque; holding $X$ and $Y$ at their values for the equivalent load is the one approximation. The mean of the equivalent sinusoid is not used for bearings: on the FTP-75 history it is 9.15 N·m, a signed average of driving and regenerative torque that understates the load a bearing feels (the cubic mean is 44.05 N·m). The equivalent sinusoid exists for FTP-75 only; hill-climb and drag-race cases carry a cubic mean but no sinusoid. The required exercise makes no static-capacity check and does not design fits or retention (see Section 10.4). Bearing reliability stays at the 90 percent that $L_{10}$ means; the gear calculation separately uses $K_R=1$ at 99 percent. Neither predicts complete gearbox reliability. The bearing reactions include the same two helix thrust couples as the shaft sections, and the locating bearing carries the net thrust.

Rating life:

$$
L_{10} = \left(\frac{C}{P}\right)^a
$$

with $a = 3$ for ball bearings (Shigley Ch. 11).

---

## 10. Assumptions and Limitations

This is a load-generation tool for Shigley-level component sizing, not a validated vehicle dynamics simulator. The following subsections document each simplification and its impact on the design outputs.

### 10.1 Vehicle Dynamics

**Drivetrain efficiency** is a constant 0.97 for the two meshes together, about 0.985 per mesh, inside the 0.98 to 0.99 typical of a helical mesh.

**Rolling resistance** omits the $\cos(\theta)$ factor. At 20 degrees this introduces a 6 percent error in $F_{\text{roll}}$, but rolling resistance accounts for only about 3 percent of total resistance at that grade, so the net effect on motor torque is under 0.3 percent.

**No tire slip.** With default parameters the maximum tractive force is about 9.1 kN ($\eta G T_{\max}/R_w$). The car is rear-wheel drive, so the traction limit is $\mu$ times the rear-axle load, about 6 to 7 kN at $\mu = 0.8$ including load transfer: full motor torque would spin the tires at launch. Ignoring slip makes `T_peak` an upper bound on the torque the gearbox sees, which is conservative for sizing and is one reason the 0-100 km/h time is optimistic.

**Hill Climb steady state.** `T_steady` is the mean motor torque over the last 40 percent of the Hill Climb run. The default 60 s stop time lets the vehicle reach its grade-limited terminal velocity (about 124 km/h on the default 20-degree grade), so `T_steady` is a settled sustained-load value. The late-window speed standard deviation is about 0.5 km/h. The simulation warns if that standard deviation exceeds 1 km/h. That happens on shallow grades, where the car climbs toward its speed limit and takes longer to settle, or with a shortened `stop_hill`; the answer key then asks for a longer run.

### 10.2 Motor Model

**No electrical dynamics.** Motor electrical time constants for a PMSM are 1-5 ms, far shorter than the mechanical time scales relevant to component sizing. A first-order actuator lag ($\tau$ = 0.05 s open-loop, 0.12 s for FTP-75) and a 5000 N·m/s slew-rate limiter are included to prevent unrealistic step changes in torque.

**No thermal derating.** The constant envelope produces upper-bound torques, which is appropriate for worst-case component sizing. A real motor reduces available torque after sustained high-current operation, so this assumption is conservative.

### 10.3 Fatigue Load Extraction

Rainflow counting is described in detail in Section 8. The main limitation is the final compression of a variable-amplitude, variable-mean spectrum into one equivalent sinusoidal design cycle for a Shigley-level Goodman calculation.

**Goodman with a single equivalent cycle** does not capture sequence effects or the changing mean stress of the original drive cycle (Shigley Ch. 6). The design safety factors $n \geq 1.5$ and the documented preprocessing assumption should therefore be treated as course-design margins, not production durability certification.

### 10.4 Not Checked by the Course Key

The course key sizes the parts with the checks the assignment teaches: AGMA bending and contact, DE-Goodman fatigue and static yield of the intermediate shaft, and bearing L10 life. A production design would add the checks below. They are left out on purpose, to keep the assignment to its chapters, and none of them changes a load the simulation exports. Each makes a good extension or report question.

- **Shaft deflection and slope** (Shigley Ch. 7). Minimizing mass against fatigue and yield alone gives a slender shaft, which at peak torque can exceed the Ch. 7 slope limits at the gears (0.0005 rad for uncrowned teeth) and at the bearings. Slope scales with $1/d^4$, so meeting the limits can need noticeably larger diameters. The gear rating assumes precision-enclosed mounting (Shigley Ch. 14) for $K_m$ ($K_H$), which presumes the shaft meets those limits.
- **Static load rating of the bearings.** The bearings are chosen on L10 life at $T_{\text{cubic mean}}$. At the drag-race peak, the radial load on a bearing chosen for L10 life can exceed its static rating $C_0$. For a bearing that carries no thrust, $P_0 = F_r$ and no static $X_0$, $Y_0$ factors are needed; a check $F_r \le C_0$ at $T_{\text{peak}}$ may select a larger bearing. The locating bearing would need $X_0$ and $Y_0$, which Shigley does not tabulate.
- **Repeated full-throttle launches.** Shaft fatigue is checked against the FTP-75 duty. Each drag-race run turns the intermediate shaft many times at close to the peak bending moment, which is finite life on the Shigley S-N line. A Miner's-rule sum (Ch. 6, cumulative fatigue damage) over a stated number of launches would size the shaft for that duty. The tire traction limit (Section 10.1) lowers the launch torque but does not remove this.
- **Bending cycles per revolution.** A rotating shaft completes one bending cycle per revolution, while $T_{\text{alt,eq}}$ comes from rainflow counting of torque reversals. The bending torque $T_{\text{mean,eq}} + T_{\text{alt,eq}}$ is below the FTP-75 maximum torque, which the shaft carries for many revolutions over the design life. Using that maximum lowers the fatigue safety factors. Rainflow remains the right reduction for the torsion pair.
- **Stage-2 quality number above the course speed.** $Q_v$ is chosen so that the pitch-line velocity at the 120 km/h course speed is inside the velocity limit for that $Q_v$. No $Q_v \le 11$ lets stage 1 meet the limit at top speed. Stage 2 could, with a higher $Q_v$ (and then a smaller module); with the course choice it is outside the limit above about 125 km/h.
- **Two-way tooth loading.** Regenerative braking loads the coast flanks. The ratings treat tooth bending as one-way. AGMA practice lowers the allowable bending stress for fully reversed loading; the regen loading here is partial, so the reduction would be smaller.
- **Axial location of the gears.** The shaft shoulders locate the bearings. How each gear is held against its helix thrust (spacer, sleeve or press fit) is left to the report.
- **Reliability of the bearing pair.** Each bearing is selected at 90 percent reliability; the reliability of the pair is the product of the two (Ch. 11).
- **Charts at their edge.** Some shoulder geometries in the search fall at the edge of the Shigley Appendix A tension and torsion charts or on the extrapolated entries. Report it if yours does.

Outside the project altogether: multi-speed transmissions, torsional vibration and gear mesh harmonics, bearing preload and misalignment, temperature-dependent material properties, and statistically characterized road spectra.

### 10.5 Units and Signal Conventions

All physics inside Simulink runs in SI:

- Distance: m
- Time: s
- Mass: kg
- Force: N
- Torque: N·m
- Speed (internal): m/s
- Motor speed: rad/s

Vehicle speed is logged and plotted in km/h ($v_{\text{kph}} = 3.6 v_{\text{mps}}$) for readability, but the control loop runs strictly in m/s. The km/h conversion only happens on logging branches, so keep it out of the feedback path or the PID gains will be wrong.


### 10.6 Road Grade Definition (Percent Grade vs Sine of Road Angle)

The model uses $F_{\text{grade}} = m g \sin\theta$. The grade is entered in degrees (`theta_hill_deg`, default 20 degrees, a 36.4 percent grade) and converted to radians before the sine is taken.

Note: industry practice often quotes "percent grade" = $100\tan(\theta)$, not $\sin(\theta)$. Below a 10 percent grade the difference is negligible (under 0.5 percent), but at 20 degrees it becomes significant. The angle is specified directly here to avoid ambiguity.

### 10.7 Instructor Verification Checklist

Recommended checks before distributing files to students:

1. FTP-75 tracking:
   - $v_{\text{sim}}(t)$ follows $v_{\text{ref}}(t)$ closely (no unit mismatch in feedback).
2. Envelope behavior:
   - At low speed, torque reaches approximately $T_{\max}$.
   - At higher speed, torque transitions toward $P_{\max}/\omega_m$.
3. Hill climb plausibility:
   - On the chosen grade, speed settles above the motor base speed, in the constant-power region, so `T_steady` is close to $P_{\max}/\omega_m$ at the settled speed.
4. Sign conventions:
   - Tractive torque positive increases speed; regen torque (if enabled) reduces speed.
5. Units:
   - Logged speed is in km/h; internal speed and control are in m/s.

---

## 11. References

1. Budynas, R. G., and Nisbett, J. K.
   *Shigley's Mechanical Engineering Design*, 11th ed., McGraw-Hill, 2020.

2. ANSI/AGMA 2101-D04
   *Fundamental Rating Factors and Calculation Methods for Involute Spur and Helical Gear Teeth*.

3. Gillespie, T. D. (1992).
   *Fundamentals of Vehicle Dynamics*, SAE.

4. Guzzella, L., and Sciarretta, A. (2013).
   *Vehicle Propulsion Systems*, 3rd ed., Springer.

5. SKF Group (2021).
   *Rolling bearings*, PUB BU/P1 17000/1 EN.

6. Ehsani, M., Gao, Y., Longo, S., and Ebrahimi, K. (2018).
   *Modern Electric, Hybrid Electric, and Fuel Cell Vehicles*, 3rd ed., CRC Press.

7. Niemann, G., and Winter, H. (1989).
   *Maschinenelemente, Band II*, 2nd ed., Springer.

8. ASTM E1049-85 (2017).
    *Standard Practices for Cycle Counting in Fatigue Analysis*.
