# SimDrive: EV Transmission Design
## Physics and modeling reference

*Ahmed Hanafy Ibrahim, Assistant Professor (ahmedibrahim@aus.edu)*<br>
*Mahmoud Al Herbawi and Malek Zahir, senior undergraduate students*<br>
*Financial support: MathWorks Teaching Support Award*

## 1. Introduction and scope

This reference presents the equations of the vehicle dynamics model, the motor
torque-speed envelope, the speed-tracking control, the fatigue load reduction,
and the unit conventions. Every quantity exported to the student design files
follows from these equations.

## 2. Workflow

### 2.1 Instructor side

1. Set vehicle, motor, and control parameters in `main.mlx` (or the dashboard).
2. Run the Simulink model for three load cases: FTP-75, hill climb and drag
   race.
3. Export to `exports_design_ready/`, then build the student hand-out with
   `buildStudentPackage`, which reduces each case to the design scalars and one
   2000-point torque curve.

### 2.2 Student side

Students receive the design torques already reduced, including the FTP-75 mean
and alternating pair, and apply the AGMA gear rating, shaft fatigue and
rolling-contact bearing life procedures as presented in Shigley 11e. Students do
not perform the reduction, since Section 8 is instructor-side data preparation.
The geometry is iterated until every safety factor and the life target are met.

## 3. Modeling assumptions

### 3.1 Torque-based design input

Shigley-based design begins from known external loads and proceeds to analytical
stress computation. This project follows the same approach: the motor output
torque serves as the gearbox input torque. The electrical side of the motor is
not modeled, and the gearbox is treated as rigid with a constant drivetrain
efficiency.

## 4. Vehicle longitudinal dynamics

The model is the standard lumped-mass, one-dimensional formulation: the vehicle
is represented as a point mass translating along its longitudinal axis.

### 4.1 Governing equation

$$
m_{\text{eff}} \frac{dv}{dt} = F_{\text{trac}} + F_{\text{brake}} - F_{\text{roll}} - F_{\text{aero}} - F_{\text{grade}}
$$

where:

- $m_{\text{eff}}$ = effective vehicle mass including rotational inertia [kg]
  (see Section 4.6)
- $F_{\text{brake}} \le 0$ = friction brake force at the wheels [N] (see
  Section 5.3)
- $v$ = vehicle longitudinal speed [m/s]
- $t$ = time [s]

Weight-based forces ($F_{\text{roll}}$, $F_{\text{grade}}$) use the actual
vehicle mass $m$, not $m_{\text{eff}}$.

This formulation is standard, as given in Gillespie (1992) Chapter 1 and
Guzzella and Sciarretta (2013) Chapter 2.

### 4.2 Tractive force

The drivetrain loss is always applied on the output side of the power flow: at
the wheels when the motor drives, and at the motor when the wheels drive it
during regenerative braking.

$$
F_{\text{trac}} = \begin{cases} \dfrac{\eta_{\text{dt}} T_m G}{R_w}, & T_m \ge 0 \text{ (driving)} \cr  \dfrac{T_m G}{\eta_{\text{dt}} R_w}, & T_m < 0 \text{ (regenerating)} \end{cases}
$$

where:

- $\eta_{\text{dt}}$ = drivetrain efficiency [-] (see Section 4.7)
- $T_m$ = electric motor output torque (gearbox input torque) [N·m]
- $G$ = fixed gear ratio (motor speed / wheel speed) [-]
- $R_w$ = tire radius of the driven wheel, unloaded by default [m] (see Section
  4.8)

Assumptions:
- rigid driveline,
- no wheel slip.

### 4.3 Rolling resistance

$$
F_{\text{roll}} = C_{rr} m g
$$

where:

- $C_{rr}$ = coefficient of rolling resistance [-]
- $g$ = gravitational acceleration (9.81 m/s²)

### 4.4 Aerodynamic drag

$$
F_{\text{aero}} = \frac{1}{2} \rho C_d A \left\lvert v\right\rvert v
$$

where:

- $\rho$ = air density computed from ambient conditions [kg/m³] (see Section
  4.9)
- $C_d$ = aerodynamic drag coefficient [-]
- $A$ = vehicle frontal area [m²]

### 4.5 Grade resistance

$$
F_{\text{grade}} = m g \sin(\theta)
$$

where:

- $\theta$ = road inclination angle [rad]
- the implementation passes $\sin(\theta)$ directly to the Simulink model

### 4.6 Effective mass (rotational inertia)

$$
m_{\text{eff}} = m + \frac{I_{\text{motor}} G^2 + 4 I_{\text{wheel}}}{R_w^2}
$$

where:

- $m$ = vehicle mass [kg]
- $I_{\text{motor}}$ = motor rotor moment of inertia [kg·m²]
- $I_{\text{wheel}}$ = moment of inertia of one wheel+tire assembly [kg·m²]
- $G$ = gear ratio [-]
- $R_w$ = tire radius [m]

The wheel and tire are modeled as a thick annular ring; $I_{\text{wheel}}$ is
given in Section 4.8.

### 4.7 Drivetrain efficiency

A constant $\eta_{\text{dt}} = 0.97$ is used throughout. It covers the two
meshes together, approximately 0.985 per mesh, within the range typical of
helical reduction gearboxes (Niemann and Winter, 1989). The loss is divided
equally, $\sqrt{\eta_{\text{dt}}}$ per mesh (Section 9). Speed- and
load-dependent losses are neglected. The actual efficiency varies slightly, but
the effect on component sizing is negligible.

### 4.8 Wheel and tire specification

The tire radius $R_w$ is specified directly as a single input (default: 0.334 m,
the unloaded radius of a 235/45R18 tire, whereas a loaded rolling radius is
approximately 2 to 4 percent smaller). This approach avoids the need to parse
tire size designations and allows the instructor to enter a measured or
datasheet value.

For the wheel+tire inertia estimate, the instructor selects a tire profile (low,
standard, or high), which sets the rim-to-radius ratio $r_{\text{rim}}/R_w$:

| Profile | Typical aspect ratio | $r_{\text{rim}} / R_w$ |
|---|---|---|
| Low | 35-40 | 0.74 |
| Standard | 45-55 | 0.68 |
| High | 60-70 | 0.62 |

The wheel+tire assembly is modeled as a thick annular ring with a fixed assembly
mass $m_{\text{wheel}} = 20$ kg (a representative value for a passenger-car
wheel and tire):

$$
I_{\text{wheel}} = \frac{1}{2} m_{\text{wheel}}\left(1 + \left(\frac{r_{\text{rim}}}{R_w}\right)^2\right) R_w^2
$$

This is the exact mass moment of inertia of a uniform annular ring with inner
radius $r_{\text{rim}}$ and outer radius $R_w$. The profile selection is a minor
correction: low and high profiles differ by approximately 12 percent in
$I_{\text{wheel}}$, less than 1 percent of the effective mass.

### 4.9 Air density

Air density follows from the ambient temperature, pressure and humidity, and it
scales the aerodynamic drag force directly:

$$
\rho = \frac{p_{\text{atm}} - p_v}{R_d T_K} + \frac{p_v}{R_v T_K}
$$

where:

- $p_{\text{atm}}$ = atmospheric pressure [Pa] (fixed: 101,325)
- $T_K$ = ambient temperature in kelvin ($T_K = T_C + 273.15$)
- $R_d = 287.058$ J/(kg·K) = specific gas constant for dry air
- $R_v = 461.495$ J/(kg·K) = specific gas constant for water vapor

The saturation vapor pressure is given by the Tetens equation:

$$
p_{\text{sat}} = 610.78 \exp\left(\frac{17.27 T_C}{T_C + 237.3}\right)
$$

$$
p_v = \text{RH} \times p_{\text{sat}}
$$

where RH is the relative humidity as a fraction [0-1] (fixed: 0.50).

At the default conditions ($T_C = 25$ °C, $p_{\text{atm}} = 101{,}325$ Pa, RH =
0.50), this yields $\rho = 1.177$ kg/m³, compared with the ISA standard value of
1.225 kg/m³ for dry air at 15 °C.

## 5. Motor torque-speed envelope

When the motor drives ($T_m \ge 0$), its torque is bounded by $T_{\max}$ at low
speed and by the available power above base speed. Regeneration has its own
limit (Section 5.3).

### 5.1 Constant torque region

$$
T_m \le T_{\max}
$$

### 5.2 Constant power region

Above base speed ($\omega_{\text{base}} = P_{\max}/T_{\max}$), the available
torque decreases as $1/\omega_m$:

$$
T_m \le \frac{P_{\max}}{\omega_m}
$$

Motor speed follows from kinematics: $\omega_m = G v / R_w$. The two regions
form the standard EV envelope shape (Ehsani et al., 2018).

The motor is also speed-limited, to $\omega_{\max}$ (`n_max` = 16,000 rpm by
default, approximately 224 km/h at $G = 9$). The available torque decreases
linearly to zero over the final 5 percent below $\omega_{\max}$, in the manner
of the speed limiter of a motor controller:

$$
T_m \le \min\left(T_{\max}, \frac{P_{\max}}{\omega_m}\right) \cdot \min\left(\max\left(\frac{\omega_{\max} - \left\lvert\omega_m\right\rvert}{0.05\thinspace \omega_{\max}}, 0\right), 1\right)
$$

The gear rating evaluates $K_v$ at the base speed, where $T_{\text{peak}}$ acts,
and applies the quality-number velocity check (Shigley Chapter 14) at a course
speed of 120 km/h. Near $\omega_{\max}$ the stage-1 pitch-line velocity would
exceed the $Q_v = 11$ limit.

### 5.3 Regenerative braking

Braking is blended between the motor and the friction brakes, as in an EV. The
motor receives the braking command $T_{\text{cmd}} < 0$, limited to
$-T_{\text{regen}}$ and scaled by a fraction that decreases linearly from one at
$v_0 = 10$ km/h to zero at rest:

$$
T_m = \max\left(T_{\text{cmd}}, -T_{\text{regen}}\right) \min\left(\frac{\left\lvert v\right\rvert}{v_0}, 1\right)
$$

The friction brakes apply the remainder of the command at the wheels,
$F_{\text{brake}} = \min(T_{\text{cmd}} - T_m, 0)\thinspace G/R_w$. They do not
load the gearbox, so neither the end of a stop nor standstill adds torque to the
design loads.

## 6. FTP-75 speed control

The FTP-75 schedule is the EPA cold-start and stabilized phases followed by the
hot-start phase, 1874 s and 17.77 km in total. The 10-minute soak between the
stabilized and hot-start phases is omitted, since the vehicle carries no load
during this period. The FTP-75 case uses a discrete PID controller to track this
reference speed profile:

$$
e(t) = v_{\text{ref}}(t) - v(t)
$$

The commanded torque is:

$$
T_{\text{cmd}}(t) = K_p e(t) + K_i \int e(t) dt + K_d \frac{de(t)}{dt}
$$

where:

- $K_p$, $K_i$, $K_d$ = proportional, integral, and derivative gains

All control computations run in SI units (m/s). The torque command passes
through an actuator lag, rate limiter, and envelope saturation before reaching
the plant, so the exported torque histories are the motor torque after these
limits.

## 7. Load cases

| Case | Control | Output |
|------|---------|--------|
| FTP-75 | PID speed tracking | Fatigue spectrum, bearing life |
| Hill climb | Open-loop, full torque on grade | `T_steady` |
| Drag race | Open-loop, full torque, flat road | `T_peak` for AGMA and yield |

The hill climb is synthetic and power-limited by design. The default grade of 20
degrees (36.4 percent, Section 10.5) is steeper than a public road. It is chosen
so that the motor settles at its power limit and the steady torque can be
verified by hand calculation (Student 01, Task 6; Section 10.6, item 3).

## 8. Fatigue load extraction

The FTP-75 simulation produces an irregular torque history: many cycles with
different mean torque, amplitude, and duration. Shigley's modified Goodman
criterion is normally applied with one mean stress and one alternating stress,
so the simulation reduces the FTP-75 torque history to one equivalent mean and
amplitude pair before students begin the shaft design.

### 8.1 Equivalent-sinusoid inputs

The simulation uses rainflow cycle counting, the standard method for reducing an
irregular fatigue history to closed and half cycles. The implementation calls
MATLAB `rainflow()` (Signal Processing Toolbox), following ASTM E1049. For each
counted cycle, the algorithm returns a cycle count $n_i$, a torque range
$\Delta T_i$, and a cycle mean torque $T_{\text{mean},i}$. The cycle amplitude
is half the range:

$$
T_{a,i} = \frac{\Delta T_i}{2}
$$

Only samples with vehicle speed above 5 km/h enter the count, so standing time
is excluded. Cycles whose range is below 2 percent of the full moving-torque
range are then discarded. They originate from speed-controller ripple and would
otherwise dominate the count and reduce the averages in the next two equations
without adding damage.

The damage-equivalent alternating torque is then computed using the
Palmgren-Miner linear damage rule. If the S-N curve is approximated by
$N S^m = \text{constant}$, preserving total damage gives:

$$
T_{\text{alt,eq}} = \left( \frac{\sum n_i T_{a,i}^{m}}{\sum n_i} \right)^{1/m}
$$

where $m=3$ is the fixed course reduction exponent, set on the instructor side,
and students do not change it.

The equivalent mean torque is the cycle-count-weighted average:

$$
T_{\text{mean,eq}} = \frac{\sum n_i T_{\text{mean},i}}{\sum n_i}
$$

### 8.2 Equivalent sinusoid

The irregular FTP-75 torque history is reduced to a single equivalent sinusoid:

$$
T_{\text{eq}}(t) = T_{\text{mean,eq}} + T_{\text{alt,eq}} \sin\left(\frac{2\pi t}{\tau}\right)
$$

with period $\tau = 120$ s. The values $T_{\text{mean,eq}}$ and
$T_{\text{alt,eq}}$ are the rainflow-derived design inputs for the modified
Goodman diagram. They define the mean stress and alternating stress that the
shaft must withstand for infinite life. The instructor plot shows the sinusoid
against the tracked torque trace so that the reduction can be inspected.
Students receive the sinusoid as the FTP-75 torque curve, and the student FTP-75
plot presents it as the curve used in the Goodman calculation. The overview
figure of all three cases shows the raw trace for context only.

### 8.3 Bearing equivalent torque

Bearing life uses the revolution-weighted cubic mean of the torque history, the
Shigley Chapter 11 equivalent load (Section 9.3).

## 9. Student design equations

The transmission is single speed with two helical stages on three parallel
shafts in one plane. Stage 1 extends from the input pinion ($N_1$, diameter
$d_1$) to the intermediate gear ($N_2$, $d_2$), and stage 2, the final drive,
extends from the intermediate pinion ($N_3$, $d_3$) to the output gear ($N_4$,
$d_4$), which carries the differential. The overall ratio is

$$
G = \frac{N_2}{N_1}\thinspace \frac{N_4}{N_3} = i_1\thinspace i_2
$$

The simulation exports motor torque, which is the input-shaft torque
$T_{\text{in}}$. Each mesh is assigned an equal share of the drivetrain loss, so
the intermediate and output torques are

$$
T_{\text{int}} = T_{\text{in}}\thinspace i_1\sqrt{\eta_{\text{dt}}}, \qquad T_{\text{out}} = T_{\text{in}}\thinspace G\thinspace \eta_{\text{dt}}
$$

At each mesh, with $T$ the torque on that stage's pinion shaft and $d$ the
pinion pitch diameter:

$$
W_t = \frac{2T}{d}, \qquad W_r = W_t \tan\phi_t, \qquad W_a = W_t \tan\psi
$$

where $\psi$ is the helix angle, $\phi_n$ the normal pressure angle and
$\phi_t = \arctan(\tan\phi_n / \cos\psi)$ the transverse pressure angle. These
forces determine the shaft bending moments, the bearing reactions and the tooth
stresses. The applicable torque depends on the component being designed:

| Task | Torque | Load case |
|---|---|---|
| Gear tooth stress, both stages | $T_{\text{peak}}$ | Drag race |
| Shaft fatigue (Goodman) | $T_{\text{mean,eq}}$, $T_{\text{alt,eq}}$ | FTP-75 |
| Shaft yield | $T_{\text{peak}}$ | Drag race |
| Bearing L10 | $T_{\text{cubic mean}}$ | FTP-75 |
| Validation hand check; finite-life extension | $T_{\text{steady}}$ | Hill climb |

### 9.1 Gear design (AGMA procedure as presented in Shigley 11e)

Both stages are rated by the same procedure. Bending stress in its SI form:

$$
\sigma = W_t K_o K_v K_s \frac{1}{b m_t} \frac{K_H K_B}{Y_J}
$$

Contact stress in its SI form:

$$
\sigma_c = Z_E \sqrt{W_t K_o K_v K_s \frac{K_H}{d_{w1} b} \frac{Z_R}{Z_I}}
$$

Shigley Chapter 14 pairs each SI symbol with its U.S. customary one: $b$ ($F$),
$K_H$ ($K_m$), $Y_J$ ($J$), $Z_E$ ($C_p$), $Z_R$ ($C_f$), $Z_I$ ($I$), $d_{w1}$
($d_P$). The student templates use the customary symbols.

The answer key (`rateHelicalStage`, in the archive sent to instructors) selects
its design values by rule so that it remains valid for any gear train that the
instructor sets: the lowest $Q_v$ whose velocity limit exceeds the pitch-line
velocity at 120 km/h (`courseTargets`) and at the $K_v$ rating speed, face width
searched in 5 mm steps from the larger of $3p_t$ and $2p_x$ (so that the
face-contact ratio $m_F \geq 2$) up to $5p_t$, and the softest passing row of
the Shigley Appendix A heat-treated steel table at the narrowest passing width.
$J$ is read from the digitized Shigley Chapter 14 helical geometry-factor charts
(`computeHelicalJ`, in the encrypted answer-key archive). When the stage-2
module is left to the key, the dashboard exports the smallest preferred module
(Shigley Chapter 13) that passes the stage-2 rating.

### 9.2 Intermediate shaft fatigue (DE-Goodman)

The intermediate shaft is designed as a **stepped** shaft: a journal at each
bearing and one raised seat carrying the stage-1 gear and the stage-2 pinion,
with a shoulder at each end of the seat. Its mass is minimized over the
prescribed search grid subject to section safety factors. The journal diameter
is selected from standard metric bearing bores and must nominally match the
selected bearing. The seat shoulders bound the gear seat, inboard of the
bearings, and are not bearing abutments (Section 10.3). Both gears are held by a
press fit or keys whose design is outside the project. The fits and keys are
assumed to introduce no stress concentration, so the two gear stations are plain
sections (a stated simplification: Shigley Chapter 7 notes that press fits do
raise the stress at the hub ends). The stage-2 pinion rim must maintain a backup
ratio of at least 1.2 (Shigley Chapter 14), so that $K_B = 1$ holds. Total mass
is $m_{\text{shaft}} = \sum_i \rho_s \frac{\pi}{4} d_i^2 L_i$, with $\rho_s$ the
steel density.

Combined bending and torsion. On a rotating shaft, bending is fully reversed.
With the shaft axis along x and the three shaft axes in the x-z plane, the
stage-1 mesh is located on the $+z$ side and the stage-2 mesh on the $-z$ side.
The stage-1 gear carries the stage-1 mesh force $2T_{\text{in}}/d_1$, the
stage-2 pinion carries $2T_{\text{int}}/d_3$, and the shaft carries
$T_{\text{int}}$ between the two gears. Both gears have the same helix hand,
following the Shigley Chapter 13 rule for helical gears sharing a shaft (choose
the hands for minimum thrust). Each thrust acts at its pitch radius and applies
a couple in the x-z plane,

$$
M_0 = W_a \frac{d}{2} = T \tan\psi
$$

Student 03 requires students to determine, from the position vector to each mesh
point, whether the tangential forces, the radial forces, the thrusts and the two
couples add or oppose, and the answer key gives the result. The common sign of
the couples depends on helix hand and direction of rotation, which this project
does not fix, so both signs are evaluated and the worse is taken at every
section.

Each plane is solved as a simply supported beam (`simplySupportedMoment`, in the
encrypted answer-key archive), with the couples producing steps in the x-z
moment diagram at their stations, and the planes are combined only at the end:

$$
M_{\mathrm{res}} = \sqrt{M_{xy}^2 + M_{xz}^2}
$$

In each $M_0 = T\tan\psi$ above, $T$ is the mesh torque on that gear:
$T_{\text{in}} i_1$ at the stage-1 gear and $T_{\text{int}}$ at the stage-2
pinion. This follows the Shigley moment balance about the bearings, in which the
position vector runs to the tooth force and the axial component therefore
contributes a couple.

The bending stress is obtained from the resultant,
$\sigma_b = 32 M_{\mathrm{res}} / (\pi d^3)$, and the torsional shear stress is
evaluated separately, $\tau_t = 16T / (\pi d^3)$. Axial normal stress is not
carried into the fatigue check. Shigley Chapter 7 states that the axial stresses
transmitted to a shaft by helical gears or tapered roller bearings are almost
always negligible compared with the bending stress, are usually steady, and may
be neglected when bending is present. Here the axial stress follows the torque
and does not alternate with rotation, and it is small compared with the
alternating bending stress. The static yield check applies $K_f$ and $K_{fs}$ to
the peak stresses and retains the axial term.

Shoulder stress-concentration factors are evaluated from the trial geometry
ratios $D/d$ and $r/d$:

$$
K_f = 1 + q(K_t - 1), \qquad K_{fs} = 1 + q_s(K_{ts} - 1)
$$

with the steel notch-sensitivity estimate

$$
q = \frac{1}{1 + \sqrt{a}/\sqrt{r_{\mathrm{mm}}}}
$$

and the corresponding torsional notch sensitivity

$$
q_s = \frac{1}{1 + \sqrt{a_s}/\sqrt{r_{\mathrm{mm}}}}.
$$

Here $\sqrt{a}$ and $\sqrt{a_s}$ are the separate Shigley steel fits as
functions of $S_{ut}$, and $r_{\mathrm{mm}} = (r/d)d$ is the fillet radius in
millimeters. The worked solution calls
`computeShoulderNotchFactors(D/d, r/d, S_ut, d_mm)` for every candidate. The
function returns separate `K_t` values for axial and bending loading, $K_{ts}$
for torsion, and the corresponding fatigue factors. Its three `K_t` surfaces
were digitized from the Shigley 11th-edition Appendix A charts for a shouldered
round shaft in tension, torsion and bending, with linear interpolation between
digitized points. The grids cover $r/d$ from 0.025 to 0.100 and $D/d$ from 1.05
to 1.50. The grid starts at $r/d = 0.025$, where the tension curves for $D/d$ =
1.05 to 1.50 have not yet begun (the extrapolated entries are listed below), so
smaller fillets are rejected. Entries read from a plotted curve carry a
chart-reading tolerance of approximately 0.05 in $K_t$. Six entries of the
tension chart (D/d = 1.05 at r/d = 0.025 and 0.030; D/d = 1.10 at r/d = 0.025;
D/d = 1.50 at r/d = 0.025, 0.030 and 0.040) lie where the plotted curve has not
started, are extrapolations of it, and are identified in the function. The two
notch sensitivities are not digitized. They are evaluated from the Shigley curve
fits above, which are the relations plotted in the Chapter 6 notch-sensitivity
charts.

DE von Mises equivalent stresses, in which $T_m$ and $T_a$ denote the mean and
alternating shaft torque and not the motor torque of Section 4:

$$
\sigma_{a}^{\prime} = \sqrt{\left(\frac{32 K_f M_a}{\pi d^3}\right)^2 + 3\left(\frac{16 K_{fs} T_a}{\pi d^3}\right)^2}
$$

$$
\sigma_{m}^{\prime} = \sqrt{3}\thinspace \frac{16 K_{fs} T_m}{\pi d^3}
$$

Rotation makes the bending fully reversed, so $M_m = 0$ and $M_a$ is the moment
at the peak torque of the equivalent cycle,
$T_{\text{mean,eq}} + T_{\text{alt,eq}}$. The torques $T_m$ and $T_a$ are
$T_{\text{mean,eq}}$ and $T_{\text{alt,eq}}$ transferred to the intermediate
shaft.

Modified Goodman criterion with von Mises stresses, the form underlying the
DE-Goodman shaft equation:

$$
\frac{\sigma_{a}^{\prime}}{S_e} + \frac{\sigma_{m}^{\prime}}{S_{ut}} \le \frac{1}{n}
$$

### 9.3 Bearing life (Shigley rating-life procedure)

Equivalent radial load (Shigley Chapter 11), with the rotation factor $V = 1$
(inner ring rotates) and $X$, $Y$ from the Chapter 11 table against $F_a/C_0$:

$$
F_e = X_i V F_r + Y_i F_a
$$

The bearing load follows from the revolution-weighted cubic mean of the FTP-75
torque, the Shigley Chapter 11 equivalent load,
$F_{eq} = [\frac{1}{\phi}\int_0^\phi F^a d\theta]^{1/a}$ with $a = 3$ for ball
bearings:

$$
T_{\text{cubic mean}} = \left(\frac{\int \left\lvert T(t)\right\rvert^3 \thinspace \left\lvert\omega(t)\right\rvert \thinspace \mathrm{d}t}{\int \left\lvert\omega(t)\right\rvert \thinspace \mathrm{d}t}\right)^{1/3}
$$

The mesh forces, and therefore the reactions, are proportional to torque, so
holding $X$ and $Y$ at their values for the equivalent load is the only
approximation. The bearing reactions include the same two helix thrust couples
as the shaft sections, and the locating bearing carries the net thrust. The mean
of the equivalent sinusoid is not used for bearings: on the FTP-75 history it is
9.25 N·m, a signed average of driving and regenerative torque that
underestimates the load carried by a bearing (the cubic mean is 43.88 N·m). The
equivalent sinusoid exists for FTP-75 only, whereas the hill-climb and drag-race
cases have a cubic mean but no sinusoid. The required exercise reports the
static ratio $s_0$ of the floating bearing only, makes no static-capacity
selection check, and does not design fits or retention (see Section 10.3). The
entire project is designed to 90 percent reliability: $L_{10}$ for the bearings,
$K_R = 0.85$ for the gears and $k_e = 0.897$ for the shaft. None of these
predicts complete gearbox reliability.

Rating life:

$$
L_{10} = \left(\frac{C_{10}}{F_e}\right)^a
$$

with $C_{10}$ the catalog basic dynamic load rating, $L_{10}$ in millions of
revolutions and $a = 3$ for ball bearings (Shigley Chapter 11).

## 10. Assumptions and limitations

The model generates loads for Shigley-level component sizing. The subsections
below list each simplification and its effect on the design outputs.

### 10.1 Vehicle dynamics

The constant drivetrain efficiency (Section 4.7) neglects speed- and
load-dependent losses.

Rolling resistance omits the $\cos(\theta)$ factor. At 20 degrees this
introduces a 6 percent error in $F_{\text{roll}}$, but rolling resistance
accounts for only approximately 3 percent of total resistance at that grade, so
the net effect on motor torque is below 0.3 percent.

The model has no wheel slip. With default parameters the maximum tractive force
is approximately 9.1 kN ($\eta_{\text{dt}} G T_{\max}/R_w$). The vehicle is
rear-wheel drive, so the traction limit is $\mu$ times the rear-axle load,
approximately 6 to 7 kN at $\mu = 0.8$ including load transfer. Full motor
torque would therefore cause wheel spin at launch. Neglecting slip makes
`T_peak` an upper bound on the torque that the gearbox experiences, which is
conservative for sizing and is one reason that the 0-100 km/h time is
optimistic.

In the hill climb, `T_steady` is the mean motor torque over the last 40 percent
of the run. The default 60 s stop time allows the vehicle to reach its
grade-limited terminal velocity (approximately 124 km/h on the default 20-degree
grade), so `T_steady` is a settled sustained-load value. The standard deviation
of the speed over that window is approximately 0.5 km/h, and the simulation
issues a warning if it exceeds 1 km/h. This condition occurs on shallow grades,
where the vehicle approaches its speed limit and requires more time to settle,
or with a shortened `stop_hill`. The answer key then requests a longer run.

### 10.2 Motor model

The motor model has no electrical dynamics. Motor electrical time constants for
a PMSM are 1 to 5 ms, much shorter than the mechanical time scales relevant to
component sizing. A first-order actuator lag ($\tau$ = 0.05 s open-loop, 0.12 s
for FTP-75) and a 5000 N·m/s slew-rate limiter are included to prevent
unrealistic step changes in torque.

There is no thermal derating. The constant envelope produces upper-bound
torques, which is appropriate for worst-case component sizing. An actual motor
reduces the available torque after sustained high-current operation, so this
assumption is conservative.

### 10.3 Checks outside the course key

The course key sizes the components with the checks taught in the assignment:
AGMA bending and contact, DE-Goodman fatigue and static yield of the
intermediate shaft, and bearing L10 life. A production design would add the
checks below. They are omitted intentionally, to confine the assignment to its
chapters, and none of them changes a load exported by the simulation.

- Shaft deflection and slope (Shigley Chapter 7) are not checked. Minimizing
  mass against fatigue and yield alone produces a slender shaft, which at peak
  torque can exceed the Chapter 7 slope limits at the gears (0.0005 rad for
  uncrowned teeth) and at the bearings. Slope scales with $1/d^4$, so meeting
  the limits can require larger diameters. The gear rating assumes
  precision-enclosed mounting (Shigley Chapter 14) for $K_m$ ($K_H$), which
  presumes that the shaft meets those limits.
- The static load rating of the bearings is not a selection criterion. The
  bearings are selected on L10 life at $T_{\text{cubic mean}}$, and at the
  drag-race peak the radial load on a bearing chosen for life can exceed its
  static rating $C_0$. Students report $s_0 = C_0/P_0$ at peak torque for the
  floating bearing only, with $P_0 = F_r$ because that bearing carries no
  thrust. A static check of the locating bearing requires static thrust factors
  from the catalog, since Shigley provides none, so students list it as a
  limitation (Student 04). A static check may require a larger bearing and a
  shaft redesign.
- The component torque transfer applies the motoring loss factor to the reduced
  FTP-75 torques in both directions, although the vehicle model treats
  regenerative losses separately. The [assignment
  scope](../student/ASSIGNMENT_BRIEF.md#scope-and-limitations) gives the factor
  for negative torque and its effect for the default vehicle.
- Shaft fatigue is checked against the FTP-75 duty only. Each drag-race run
  rotates the intermediate shaft many times near the peak bending moment, in the
  finite-life region of the Shigley S-N line. A Miner's-rule sum (Chapter 6,
  cumulative fatigue damage) over a stated number of launches would size the
  shaft for that duty. The tire traction limit (Section 10.1) reduces the launch
  torque but does not remove this loading.
- $Q_v$ is chosen so that the pitch-line velocity at the 120 km/h course speed
  is within the velocity limit for that $Q_v$. No $Q_v \le 11$ allows stage 1 to
  meet the limit at top speed. Stage 2 could meet it with a higher $Q_v$ (and a
  correspondingly smaller module). With the course choice, stage 2 can exceed
  its limit near top speed.
- Regenerative braking loads the coast flanks. The ratings treat tooth bending
  as one-way. AGMA practice reduces the allowable bending stress for fully
  reversed loading. The regenerative loading in this project is partial, so the
  reduction would be smaller.
- The shaft shoulders bound the raised gear seat, inboard of the bearings, and
  are not bearing abutments. A complete design specifies how the gears and the
  locating bearing are retained against thrust and whether a spacer or separate
  bearing shoulder is required, and checks the catalog abutment diameters and
  corner clearances. Detailed fits and retention remain outside the key.
- Each bearing is selected at 90 percent reliability, and the reliability of the
  pair is the product of the two (Chapter 11).
- Some shoulder geometries in the search lie at the edge of the Shigley Appendix
  A tension and torsion charts or on the extrapolated entries. Students should
  report any such geometry.

The following are entirely outside the project: multi-speed transmissions,
torsional vibration and gear mesh harmonics, bearing preload and misalignment,
temperature-dependent material properties, and statistically characterized road
spectra.

### 10.4 Units and signal conventions

All physical quantities in the Simulink model are in SI units:

- Distance: m
- Time: s
- Mass: kg
- Force: N
- Torque: N·m
- Speed (internal): m/s
- Motor speed: rad/s

Vehicle speed is logged and plotted in km/h
($v_{\text{kph}} = 3.6 v_{\text{mps}}$) for readability, but the control loop
runs strictly in m/s. The km/h conversion is applied only on logging branches.
It must remain outside the feedback path, since the PID gains would otherwise be
incorrect.

### 10.5 Road grade definition (percent grade and sine of road angle)

The model uses $F_{\text{grade}} = m g \sin\theta$. The grade is entered in
degrees (`theta_hill_deg`, default 20 degrees, a 36.4 percent grade) and
converted to radians before the sine is taken.

Industry practice often quotes percent grade as $100\tan(\theta)$. Below a 10
percent grade its difference from $100\sin(\theta)$ is negligible (below 0.5
percent), but at 20 degrees it becomes significant. The angle is specified
directly here to avoid ambiguity.

### 10.6 Instructor verification checklist

Recommended checks before distributing files to students:

1. FTP-75 tracking:
   - $v_{\text{sim}}(t)$ follows $v_{\text{ref}}(t)$ closely (no unit mismatch
     in feedback).
2. Envelope behavior:
   - At low speed, torque reaches approximately $T_{\max}$.
   - At higher speed, torque transitions toward $P_{\max}/\omega_m$.
3. Hill climb plausibility:
   - On the chosen grade, speed settles above the motor base speed, in the
     constant-power region, so `T_steady` is close to $P_{\max}/\omega_m$ at the
     settled speed.
4. Sign conventions:
   - Positive (tractive) torque increases speed, and negative (regenerative)
     torque reduces it.
5. Units:
   - Logged speed is in km/h, whereas internal speed and control are in m/s.

## 11. References

1. Budynas, R. G., and Nisbett, J. K. (2020). *Shigley's Mechanical Engineering
   Design*, 11th ed., McGraw-Hill.

2. ANSI/AGMA 2101-D04. *Fundamental Rating Factors and Calculation Methods for
   Involute Spur and Helical Gear Teeth*.

3. Gillespie, T. D. (1992). *Fundamentals of Vehicle Dynamics*, SAE.

4. Guzzella, L., and Sciarretta, A. (2013). *Vehicle Propulsion Systems*, 3rd
   ed., Springer.

5. SKF Group (2021). *Rolling bearings*, PUB BU/P1 17000/1 EN.

6. Ehsani, M., Gao, Y., Longo, S., and Ebrahimi, K. (2018). *Modern Electric,
   Hybrid Electric, and Fuel Cell Vehicles*, 3rd ed., CRC Press.

7. Niemann, G., and Winter, H. (1989). *Maschinenelemente, Band II*, 2nd ed.,
   Springer.

8. ASTM E1049-85 (2017). *Standard Practices for Cycle Counting in Fatigue
   Analysis*.

9. US EPA. *Dynamometer Drive Schedules* (FTP-75).
   https://www.epa.gov/vehicle-and-fuel-emissions-testing/dynamometer-drive-schedules
