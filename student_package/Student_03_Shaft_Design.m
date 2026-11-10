%[text] # Student 03: Stepped intermediate shaft design
%[text] Complete the cells marked `TODO` using *Shigley's Mechanical Engineering Design*, 11th edition: Chapter 3 for stresses, Chapter 5 for static failure, Chapter 6 for fatigue, Chapter 7 for shafts, and the Appendix A charts for stress concentration.
%[text] The intermediate shaft carries two gears: the stage-1 gear, driven by the input pinion, and the stage-2 pinion, which drives the output gear. It is the only shaft in the transmission loaded by both meshes at once, and for that reason it is the shaft designed in this project. It is stepped: a journal at each bearing, one raised seat carrying both gears, and a shoulder at each end of that seat. The shoulders are the stress raisers that usually govern the final diameter. They bound the gear seat inboard of the bearings and are not bearing abutments (Student 04, Task 4, locates the bearings). Fatigue is checked against the FTP-75 city cycle and static yield against the drag-race peak, at every critical section.
%[text] The design objective is minimum mass. A shaft of sufficient diameter to satisfy every check is straightforward to obtain. The task is to find the lightest shaft that still satisfies every check, which requires identifying the section and the check that reach their limits first.
%[text:tableOfContents]{"heading":"Tasks"}
%%
%[text] ## 1. Material, layout, and trial geometry
%[text] Select a steel and record $S_{ut}$ and $S_y$ with the row of the Shigley Appendix A material tables from which they were read, and the density with its source (Appendix A). Use a design factor $n_d = 1.5$ for both fatigue and yield, so the factors of safety $n_f$ and $n_y$ must be at least 1.5 at every critical section.
%[text] The choice of steel is subject to one restriction. The Neuber-constant fits, one for bending and one for torsion, are drawn from the Shigley Chapter 6 notch-sensitivity charts, which plot steels from approximately 415 to 1400 MPa. Shigley states the fits for 340 to 1700 MPa (bending) and 340 to 1500 MPa (torsion), whereas the course uses the narrower range the figures cover. Outside that range the cubic fits are extrapolated beyond their data, and above approximately 1700 MPa they return $q>1$, which is physically impossible. The supplied chart function rejects an $S_{ut}$ outside 415 to 1400 MPa instead of returning an unsupported value, so select a steel inside that range.
%[text] Both gears are held on the seat by a press fit or keys. Designing that fit or those keys is outside this project, and for simplicity they are assumed to introduce no stress concentration: the two gear stations are treated as plain cylinders and the two shoulder fillets are the only stress raisers. State this assumption in the report and describe what it neglects, because Shigley Chapter 7 notes that a press fit raises the stress at the hub ends, and a keyseat has its own stress-concentration factors.
%[text] Then lay out the shaft along its axis: bearing A, the stage-1 gear, the stage-2 pinion, bearing B. Take the gear face widths from Student 02, allow room between each bearing and the nearest gear face for half the bearing width (take a trial width from the catalog at the trial bore and update it after Student 04), a shoulder or spacer, and running clearance, and leave a gap between the two gears. State every selected length.
%[text] Do not assume the journal diameter. Search the standard metric bearing bores and carry forward the smallest bore for which the shaft satisfies every check, so that the bore passed to Student 04 is a result of this calculation and not a prior assumption.
%[text] Require a flat face at each shoulder: its radial width is $(D-d)/2 - r$. Also check the stage-2 pinion rim: it is pressed onto the seat, so the ring of steel between its root circle and the seat must be thick enough for the $K_B = 1$ used in Student 02. Shigley gives $K_B = 1$ only for a backup ratio $m_B = t_R/h_t \\ge 1.2$. Take full-depth teeth (Shigley Chapter 13): addendum $m_n$, dedendum $1.25\\,m_n$ and whole depth $h_t = 2.25\\,m_n$.
% TODO: Load Student01_results.mat and Student02_results.mat, then define the material, targets, and the shaft layout.
%%
%[text] ## 2. Forces, planes, and the two thrust couples
%[text] The three shafts lie in one plane, so the stage-1 mesh is located on one side of the intermediate shaft and the stage-2 mesh on the opposite side. Place the shaft axis along $\\mathit{x}$ with the plane of the three axes as the $\\mathit{x}$-$\\mathit{z}$ plane, and take moments about the bearings with the position vector running to each mesh point, as Shigley does in the Chapter 13 shaft-force problems. Before any calculation, establish the effect of each component:
%[text] Tangential forces. The stage-1 gear is driven and the stage-2 pinion drives, and their mesh points are on opposite sides of the axis. Determine whether their tangential forces add or oppose in the $\\mathit{x}$-$\\mathit{y}$ plane. Each mesh has one tangential force, acting equally and oppositely on its two members: the stage-1 gear carries the stage-1 mesh force $2T_{in}/d_1$ and the stage-2 pinion carries $2T_{int}/d_3$. Their moments about the axis differ only by the stage-1 mesh loss, and the shaft carries the torque $T_{int}$ only between the two gears.
%[text] Radial forces point from each mesh point to the shaft axis. Determine whether they add or oppose in the $\\mathit{x}$-$\\mathit{z}$ plane.
%[text] Axial forces. Both gears on this shaft have the same helix hand. Shigley Chapter 13 advises choosing the hands of helical gears on a common shaft so that their thrusts partly cancel. Determine whether the same hand achieves that here, and state why. Take bearing A, on the stage-1 side, as the locating bearing (Student 04 uses the same choice): it reacts the net thrust, so axial force acts between bearing A and each gear that produces it.
%[text] Thrust couples. Each axial force acts at its own pitch radius, so each gear applies a concentrated couple in the $\\mathit{x}$-$\\mathit{z}$ plane:
%[text] $ M_0 = W_a\\,\\frac{d}{2} = T\\tan\\psi $
%[text] where $T = W_t d/2$ is the torque of that gear's own mesh. The pitch diameter cancels. Next, determine whether the two couples add or cancel. Their common sign still depends on the helix hand and the direction of rotation, which this project leaves unspecified, so evaluate both signs and take the worse at every section.
%[text] A concentrated couple on a simply supported span produces equal and opposite support reactions and a step in the moment diagram at its station. Resolve each plane as a beam, combine only at the end, $M=\\sqrt{M_{xy}^{2}+M_{xz}^{2}}$, and plot the combined diagram. Identify where the moment reaches its maximum and whether that maximum coincides with a shoulder.
% TODO: Calculate the reactions and the bending moment at every critical section,
% including both thrust couples, worse sign.
% TODO: Plot the combined bending-moment diagram.
%%
%[text] ## 3. Endurance limit
%[text] Modify the rotary-beam endurance limit with the Chapter 6 Marin factors and state the assumption behind each factor applied:
%[text] $ S_e = k_a k_b k_c k_d k_e\\,S_e^{\\prime} $
%[text] $k_b$ is a function of diameter and therefore changes at every step of a stepped shaft. A single value of $S_e$ cannot be calculated once and reused along the whole length.
% TODO: Calculate the modified endurance limit at each critical diameter.
%%
%[text] ## 4. Stress concentration and notch sensitivity
%[text] Read the theoretical factors from the Shigley Appendix A stress-concentration charts using the $D/d$ and $r/d$ of the shoulder. Separate charts for the shouldered round shaft cover axial loading, bending and torsion. Evaluate $\\mathit{q}$ from the Neuber equation with the Neuber constant $\\sqrt{a}$ from the bending fit for bending and axial loading, and $q_s$ for torsion from the same equation with $\\sqrt{a}$ from the torsion fit (the Chapter 6 notch-sensitivity curves). The two fits are different and are not interchangeable.
%[text] $ K_f=1+q\\,(K_t-1), \\qquad K_{fs}=1+q_s\\,(K_{ts}-1) $
%[text] As a check on the chart reading, $K_f$ must always fall between 1 and $K_t$.
%[text] ### Using the supplied chart function
%[text] Reading five charts by hand is practical for one shoulder but not for every candidate geometry in the search of Task 7, so `computeShoulderNotchFactors.m` is supplied. Call it as `factors = computeShoulderNotchFactors(D_over_d, r_over_d, S_ut_MPa, d_mm)`, where `d_mm` is the smaller shaft diameter at that shoulder in millimeters. It accepts arrays of `D_over_d` and `r_over_d` with scalar `S_ut_MPa` and `d_mm`, so a sweep at one journal diameter requires one call. Always pass `d_mm`, which otherwise defaults to 40 mm. It returns a table whose columns include `Kt_axial`, `Kt_bending`, `Kts`, `q`, `qs`, `Kf_axial`, `Kf_bending`, `Kfs`, the fillet radius `r_mm`, and `DigitizationTolerance`.
%[text] Its domain is $D/d$ from 1.05 to 1.50 and $r/d$ from 0.025 to 0.100, and outside that range it raises an error. It also requires $r/d$ to be at most $(D/d-1)/2$, the available shoulder height, so filter the grid before the call. Read at least one shoulder from the charts by hand and confirm that the function agrees before relying on it for the remaining geometries. Report the comparison.
% TODO: Determine Kt_axial, Kt_bending, Kts, q, qs, Kf_axial, Kf_bending, and Kfs
% at every shoulder.
%%
%[text] ## 5. DE-Goodman fatigue check
%[text] Rotation makes the bending fully reversed. Evaluate the gear forces, and therefore that alternating moment, at the largest torque the equivalent fatigue cycle reaches, $T_{mean,eq}+T_{alt,eq}$ carried to the intermediate shaft, and treat the resulting bending as fully reversed. The torque retains both components, $T_m$ = `T_mean_eq_int` and $T_a$ = `T_alt_eq_int`, the intermediate-shaft values from Student 01, and acts only at the sections between the two gears. Use those definitions exactly, because they are fixed for the whole class.
%[text] Omit the axial stress from this check. Shigley Chapter 7 states that the axial stresses transmitted to a shaft by helical gears are almost always negligible compared with the bending stress and may be neglected when bending is present. The static yield check in Task 6 retains the axial term.
%[text] $ \\frac{1}{n}=\\frac{\\sigma_a^{\\prime}}{S_e}+\\frac{\\sigma_m^{\\prime}}{S_{ut}} $
% TODO: Calculate alternating and mean equivalent stresses and n_fatigue at every section.
%%
%[text] ## 6. Static yield check
%[text] Next, consider the single most severe load. Use `T_peak_int` together with the gear forces and the thrust couples it produces. Apply the fatigue stress-concentration factors $K_f$ and $K_{fs}$ to the peak stresses, as Shigley Chapter 7 does, and retain the axial normal stress in the von Mises stress.
%[text] $ n_y=\\frac{S_y}{\\sigma_{max}^{\\prime}} $
% TODO: Calculate n_yield at every critical section.
%%
%[text] ## 7. Mass minimization and scaled drawing
%[text] $ m=\\sum_i \\rho\\,\\frac{\\pi d_i^{2}L_i}{4} $
%[text] Search the feasible combinations of bore, $D/d$ and $r/d$, and retain the lightest geometry that satisfies every fatigue and yield target at every section while maintaining a flat shoulder face and an adequate pinion rim. The report should identify which section and which check governed the result, and whether the binding constraint was a stress limit, the shoulder face, the rim, or the smallest bore that would carry the loads.
%[text] Draw the shaft to scale, marking diameters, lengths and fillet radii.
% TODO: Search the geometry and create intermediateShaftResults.
% TODO: Plot a scaled drawing of the intermediate shaft.
% TODO: Save the journal diameter, the seat and shoulder geometry, and the bearing
% and gear positions to Student03_results.mat for Student 04.
%%
%[text] ## 8. Extension: the input shaft
%[text] As an optional extension, repeat the procedure for the input shaft. It carries only the stage-1 pinion and receives the motor torque from a coupling at the bearing-A end, so torque is present from that end to the pinion and nowhere else. The shaft carries one mesh and one thrust couple. Take the worse sign of the couple at every section.
%[text] Then compare the two shafts quantitatively. On the input shaft one thrust couple acts in addition to the mesh bending moment, whereas on the intermediate shaft two thrust couples act. State how they combine. Report the ratio of thrust couple to mesh moment on each shaft and state its effect on the governing section.
% TODO (extension): Design the input shaft and report the comparison.
%%
%[text] ## 9. Extension: shaft life on a sustained climb
%[text] Task 5 checked the shaft against the city cycle. The hill climb is a more severe case: at full power on the `theta_hill_deg` grade (20 degrees for the default vehicle), the gear forces are those of `T_steady_int`, far above the city-cycle loads, and the shaft continues to rotate. The task is to determine the number of hours the intermediate shaft survives under that load.
%[text] At each critical section, form the bending stress from the gear forces at `T_steady_int` (fully reversed, as before) and the torsion from `T_steady_int` (steady, and only between the gears). Convert the pair to an equivalent completely reversed stress with the Goodman relation of Shigley Chapter 6, $\\sigma_{ar} = \\sigma_a^{\\prime}/(1 - \\sigma_m^{\\prime}/S_{ut})$. Where $\\sigma_{ar} \\le S_e$ the section has infinite life. Where it is larger, construct the Chapter 6 S-N line: the fatigue strength fraction $\\mathit{f}$, the constants $\\mathit{a}$ and $\\mathit{b}$, and the life $N = (\\sigma_{ar}/a)^{1/b}$.
%[text] Convert cycles into hours with the intermediate-shaft speed at the settling speed found in Student 01, Task 6. Report the governing section and its life in hours, and state whether that life is a credible concern for a road vehicle. Discuss which design changes would be required if the life were ten minutes.
% TODO (extension): Compute sigma_ar, N and hours at every section; report the governing one.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
