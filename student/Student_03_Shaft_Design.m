%[text] # Student 03: Stepped Intermediate Shaft Design
%[text] Complete the cells marked `TODO` using *Shigley's Mechanical Engineering Design*, 11th edition: Ch. 3 for stresses, Ch. 5 for static failure, Ch. 6 for fatigue, Ch. 7 for shafts, and the Table A-15 charts for stress concentration.
%[text] The intermediate shaft carries two gears: the stage-1 gear, driven by the input pinion, and the stage-2 pinion, which drives the output gear. It is the one shaft in the transmission loaded by both meshes at once, and that is why it is the shaft you design. It is stepped: a journal at each bearing, one raised seat carrying both gears, and a shoulder at each end of that seat. The shoulders are the stress raisers that usually decide the final diameter; whether each one can also locate its bearing is a catalog abutment check you make in Student 04. Fatigue is checked against the FTP-75 city cycle and static yield against the drag-race peak, at every critical section.
%[text] The design objective is minimum mass. A shaft thick enough to pass every check is straightforward. The exercise is the lightest shaft that still passes everywhere, and that requires you to know which section and which check runs out of margin first.
%[text:tableOfContents]{"heading":"Tasks"}
%%
%[text] ## 1. Material, layout, and trial geometry
%[text] Select a steel and record $S_{ut}$ and $S_y$ with the Shigley Table A-20 or A-21 row you read them from, and the density with its source (Table A-5). Set the safety-factor targets at 1.5 for fatigue and 1.5 for yield, applied at every critical section.
%[text] One limit on that choice. The notch-sensitivity fits, Eq. (6-35) for bending and Eq. (6-36) for torsion, are drawn from Figures 6-26 and 6-27, which plot steels from about 415 to 1400 MPa. Shigley states the fits for 340 to 1700 MPa (bending) and 340 to 1500 MPa (torsion); the course uses the narrower range the figures cover. Outside that band the cubics leave their data, and above about 1700 MPa they return $q>1$, which is physically impossible. The supplied chart function rejects an $S_{ut}$ outside 415 to 1400 MPa rather than returning a number it cannot support, so choose a steel inside that range.
%[text] Both gears are held on the seat by a press fit or keys. Designing that fit or those keys is outside this project, and for simplicity they are assumed to introduce no stress concentration: the two gear stations are treated as plain cylinders and the two shoulder fillets are the only stress raisers. State this assumption in your report and say what it hides, because Shigley Sec. 7-8 notes that a press fit does raise the stress at the hub ends, and a keyseat carries the Table 7-1 factors.
%[text] Then lay out the shaft along its axis: bearing A, the stage-1 gear, the stage-2 pinion, bearing B. Take the gear face widths from Student 02, allow room between each bearing and the nearest gear face for half the bearing width, a shoulder or spacer, and running clearance, and leave a gap between the two gears. State every length you choose.
%[text] Do not assume the journal. Search the standard metric bearing bores and carry forward the smallest bore whose shaft passes every check, so that the bore you hand to Student 04 is an outcome of this calculation rather than an assumption made ahead of it.
%[text] Require a flat face at each shoulder: its radial width is $(D-d)/2 - r$. And check the stage-2 pinion rim: it is pressed onto the seat, so the ring of steel between its root circle and the seat must be thick enough for the $K_B = 1$ you used in Student 02. Shigley Eq. (14-40) gives $K_B = 1$ only for a backup ratio $m_B = t_R/h_t \ge 1.2$.
% TODO: Load Student01_results.mat and Student02_results.mat, then define the material, targets, and the shaft layout.
%%
%[text] ## 2. Forces, planes, and the two thrust couples
%[text] The three shafts lie in one plane, so the stage-1 mesh sits on one side of the intermediate shaft and the stage-2 mesh on the opposite side. Put the shaft axis along $x$ with the plane of the three axes as the $x$-$z$ plane, and take moments about the bearings with the position vector running to each mesh point, as Shigley does in the Ch. 13 shaft-force problems. Before computing anything, work out what each component does:
%[text] Tangential forces. The stage-1 gear is driven and the stage-2 pinion drives, and their mesh points are on opposite sides of the axis. Decide whether their tangential forces add or oppose in the $x$-$y$ plane. Each mesh has one tangential force, acting equally and oppositely on its two members: the stage-1 gear carries the stage-1 mesh force $2T_{in}/d_1$ and the stage-2 pinion carries $2T_{int}/d_3$. Their moments about the axis differ only by the stage-1 mesh loss, and the torque the shaft carries, only between the two gears, is $T_{int}$.
%[text] Radial forces point from each mesh point to the shaft axis. Decide whether they add or oppose in the $x$-$z$ plane.
%[text] Axial forces. Both gears on this shaft have the same helix hand. Shigley Sec. 13-10 says that when two or more single helical gears share a shaft, their hands should be chosen to produce the minimum thrust load. Check that the same hand does that here, and say why.
%[text] Thrust couples. Each axial force acts at its own pitch radius, so each gear applies a concentrated couple in the $x$-$z$ plane:
%[text] $ M_0 = W_a\,\dfrac{d}{2} = T\tan\psi $
%[text] where $T = W_t d/2$ is the torque of that gear's own mesh. The pitch diameter cancels. Now decide whether the two couples add or cancel. The thrusts are opposite, and so are the sides of the axis they act on. Many students expect the couples to cancel; check this. Their common sign still depends on the helix hand and the direction of rotation, which this project leaves unspecified, so evaluate both signs and take the worse at every section.
%[text] A concentrated couple on a simply supported span produces equal and opposite support reactions and a step in the moment diagram at its station. Resolve each plane as a beam, combine only at the end, $M=\sqrt{M_{xy}^{2}+M_{xz}^{2}}$, and plot the combined diagram. What matters is not only where the moment reaches its maximum but whether that maximum coincides with a shoulder.
% TODO: Calculate the reactions and the bending moment at every critical section,
% including both thrust couples, worse sign.
% TODO: Plot the combined bending-moment diagram.
%%
%[text] ## 3. Endurance limit
%[text] Modify the rotary-beam endurance limit with the Ch. 6 Marin factors and state the assumption behind each one you apply:
%[text] $ S_e = k_a k_b k_c k_d k_e\,S'_e $
%[text] Note that $k_b$ is a function of diameter and therefore changes at every step of a stepped shaft. A single value of $S_e$ cannot be calculated once and reused along the whole length.
% TODO: Calculate the modified endurance limit at each critical diameter.
%%
%[text] ## 4. Stress concentration and notch sensitivity
%[text] Read the theoretical factors from the Shigley 11e charts using your shoulder's $D/d$ and $r/d$. Figure A-15-7 covers axial loading, A-15-9 bending, and A-15-8 torsion. Read $q$ from Figure 6-26 for bending and axial loading and $q_s$ from Figure 6-27 for torsion; these are different curves and are not interchangeable.
%[text] $ K_f=1+q\,(K_t-1), \qquad K_{fs}=1+q_s\,(K_{ts}-1) $
%[text] As a check on your chart reading, $K_f$ must always fall between 1 and $K_t$.
%[text] ### Using the supplied chart function
%[text] Reading five charts by hand for one shoulder is reasonable. Doing it for every candidate geometry in the search of Task 7 is not, so `computeShoulderNotchFactors.m` is supplied. Call it as `factors = computeShoulderNotchFactors(D_over_d, r_over_d, S_ut_MPa, d_mm)`, where `d_mm` is the smaller shaft diameter at that shoulder in millimeters. It accepts arrays of `D_over_d` and `r_over_d` with scalar `S_ut_MPa` and `d_mm`, so a sweep at one journal diameter is one call. Always pass `d_mm`: it defaults to 40 mm. It returns `Kt_axial`, `Kt_bending`, `Kts`, `q`, `qs`, `Kf_axial`, `Kf_bending`, `Kfs`, the fillet radius `r_mm`, and `DigitizationTolerance`.
%[text] Its domain is $D/d$ from 1.05 to 1.50 and $r/d$ from 0.025 to 0.100, and it raises an error outside that range rather than extrapolating silently. Read at least one shoulder off the charts by hand and confirm the function agrees with you before you trust it for the rest. Quote the comparison in your report.
% TODO: Determine Kt_axial, Kt_bending, Kts, q, qs, Kf_axial, Kf_bending, and Kfs
% at every shoulder.
%%
%[text] ## 5. DE-Goodman fatigue check
%[text] Rotation makes the bending fully reversed. Evaluate the gear forces, and therefore that alternating moment, at the largest torque the equivalent fatigue cycle reaches, $T_{mean,eq}+T_{alt,eq}$ carried to the intermediate shaft, and treat the resulting bending as fully reversed. The torque keeps both parts, $T_m = T_{mean,eq}$ and $T_a = T_{alt,eq}$, and acts only at the sections between the two gears. Use those definitions exactly; they are fixed for the whole class.
%[text] Leave the axial stress out of this check. Shigley Ch. 7 states that the axial stresses a shaft picks up from helical gears are almost always negligible beside the bending stress and may be neglected when bending is present. The static yield check in Task 6 keeps the axial term.
%[text] $ \dfrac{1}{n}=\dfrac{\sigma'_a}{S_e}+\dfrac{\sigma'_m}{S_{ut}} $
% TODO: Calculate alternating and mean equivalent stresses and n_fatigue at every section.
%%
%[text] ## 6. Static yield check
%[text] Now consider the single worst load. Use `T_peak_int` together with the gear forces and the thrust couples it produces. Apply the fatigue factors $K_f$ and $K_{fs}$ to the peak stresses, as Shigley Eq. (7-15) does, and keep the axial normal stress in the von Mises sum.
%[text] $ n_y=\dfrac{S_y}{\sigma'_{max}} $
% TODO: Calculate n_yield at every critical section.
%%
%[text] ## 7. Mass minimization and schematic
%[text] $ m=\sum_i \rho\,\dfrac{\pi d_i^{2}L_i}{4} $
%[text] Search the feasible combinations of bore, $D/d$ and $r/d$, and retain the lightest geometry that satisfies every fatigue and yield target at every section while keeping a flat shoulder face and an adequate pinion rim. Your report should identify which section and which check governed the result, and whether the binding constraint was a stress limit, the seating face, the rim, or the smallest bore that would carry the loads.
%[text] Draw the shaft to scale, marking diameters, lengths and fillet radii.
% TODO: Search the geometry and create intermediateShaftResults.
% TODO: Plot a scaled intermediate-shaft schematic.
% TODO: Save the journal diameter, the seat and shoulder geometry and the bearing
% positions to Student03_results.mat for Student 04.
%%
%[text] ## 8. Extension: the input shaft
%[text] If you have time, repeat the procedure for the input shaft. It carries only the stage-1 pinion and takes the motor torque from a coupling at the bearing-A end, so torque is present from that end to the pinion and nowhere else. One mesh, one thrust couple, worse sign.
%[text] Then compare the two shafts with numbers. On the input shaft the thrust couple is a modest fraction of the mesh bending moment; on the intermediate shaft two couples act together. Quote the ratio of thrust couple to mesh moment on each shaft and say what it does to the governing section.
% TODO (extension): Design the input shaft and report the comparison.
%%
%[text] ## 9. Extension: how long can the shaft climb?
%[text] The city cycle shows the shaft has fatigue margin in everyday use. The hill climb asks a harder question: at full power up the `theta_hill_deg` grade (20 degrees for the default car), the gear forces are those of `T_steady_int`, far above the city-cycle loads, and the shaft keeps turning. How many hours of that can your intermediate shaft survive?
%[text] At each critical section, form the bending stress from the gear forces at `T_steady_int` (fully reversed, as before) and the torsion from `T_steady_int` (steady, and only between the gears). Convert the pair to an equivalent completely reversed stress with the Goodman relation, Shigley Eq. (6-59), $\sigma_{ar} = \sigma'_a/(1 - \sigma'_m/S_{ut})$. Where $\sigma_{ar} \le S_e$ the section has infinite life. Where it is larger, build the S-N line of Sec. 6-8: $f$ from Eq. (6-11), $a$ and $b$ from Eqs. (6-13) and (6-14), and the life $N = (\sigma_{ar}/a)^{1/b}$ from Eq. (6-15).
%[text] Turn cycles into hours with the intermediate-shaft speed at the settling speed you found in Student 01, Task 6. Report the governing section and its life in hours, and say whether that is a credible concern for a road car. What would you change if the answer were ten minutes?
% TODO (extension): Compute sigma_ar, N and hours at every section; report the governing one.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
