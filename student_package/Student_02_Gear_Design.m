%[text] # Student 02: Two-stage helical gear design
%[text] Complete the cells marked `TODO` using only the gear procedure of *Shigley's Mechanical Engineering Design*, 11th edition: Chapter 13 for geometry and tooth forces, Chapter 14 for the AGMA stress and strength equations. A manufacturer's catalog may supply material data. It does not supply an alternative equation.
%[text] The gear train is prescribed: stage 1 from the input pinion to the intermediate gear, stage 2 from the intermediate pinion to the output gear. The design variables, each of which must be justified in the report, are the face width of each stage, the material and its hardness, and every rating factor that appears in the AGMA equations. Bending and pitting are rated separately, and both checks must be satisfied on both stages.
%[text] The two stages are rated by the same procedure. Write it once, as a local function at the end of this file that takes one stage's geometry, torque, speed and cycle count and returns its stresses and safety factors, then call it twice. If the function returns the correct result for stage 1, only the inputs change for stage 2.
%[text] Report the face-contact ratio $m_F$ of each stage with the safety factors (Task 1 states the requirement).
%[text:tableOfContents]{"heading":"Tasks"}
%%
%[text] ## 1. Load inputs and select trial design values
%[text] Load the results of Student 01 and use `T_peak` for the tooth stresses. Chapter 14 rates a tooth at one transmitted load, so this is a single-point check at the maximum torque the motor can deliver. The stage-1 pinion carries `T_peak`, and the stage-2 pinion carries `T_peak_int`, the same torque after the first mesh and its loss.
%[text] Then select the trial values, one set per stage. Each of the following is a design decision to be defended in the report, and each has a corresponding treatment in Chapter 14.
%[text] Face width $\\mathit{F}$ (variable `F_w`): Shigley recommends three to five times the circular pitch, applied here with the transverse circular pitch $p_t = \\pi m_t$. Determine that range for each stage from its own module. The Chapter 14 helical geometry factors also require a face-contact ratio $m_F = F/p_x \\ge 2$, with the axial pitch $p_x = \\pi m_n/\\sin\\psi$, so the narrowest admissible width is the larger of $3p_t$ and $2p_x$. Determine which one governs at the course helix angle. A narrower face overstresses the tooth, whereas a wider face is not loaded evenly across its length. Face width is the first variable to adjust when minimizing mass.
%[text] Brinell hardness of each pinion and gear: these set the allowable bending and contact stresses. A pinion rotates faster than its gear by the stage ratio, so it accumulates load cycles more rapidly and is normally specified harder. Name the steel and the heat treatment, and cite the row of the Shigley Appendix A material tables from which the hardness was read.
%[text] Use one grade for both failure modes. The Chapter 14 strength charts give `S_t` and `S_c`, each with a Grade 1 and a Grade 2 line. Grade 2 is a cleanliness and metallurgical-control specification, so a single material belongs to a single grade, which raises both values together. Taking `S_t` from one grade and `S_c` from the other does not describe a real material.
%[text] The remaining factors are the overload factor `K_o`, size factor `K_s`, rim-thickness factor `K_B`, surface condition factor `C_f`, temperature factor `K_T`, reliability factor `K_R`, hardness-ratio factor `C_H`, quality number `Q_v`, geometry factors `J` and `I`, and elastic coefficient `C_p`. Symbols follow the Shigley Chapter 14 symbol table, which gives the SI symbol of each factor in parentheses, for example `K_m` (`K_H`), `C_p` (`Z_E`), `C_f` (`Z_R`), `J` (`Y_J`) and `I` (`Z_I`). Use one set consistently. Each factor must be taken from a named Chapter 14 figure, table or equation and defended in the report.
%[text] `J` and `K_o` require particular care. `J` is read from the Chapter 14 helical-gear geometry-factor chart, which is drawn for 75 teeth in the mating element, then multiplied by the factor from the companion multiplier chart. Read the multiplier at the number of teeth of the member itself, as the Shigley Chapter 14 worked helical example does, although the chart caption refers to the mating member, and state this convention in the report. A member with fewer than 75 teeth then takes a multiplier below one and a larger member one above it. The overload factor `K_o` covers load above nominal, so justify it against a torque that is already the upper limit of the motor, or state why it was set to one.
%[text] Treat all of these as trial values. They are revised during the iteration in Task 5.
% TODO: Load Student01_results.mat and define the trial design variables of both stages.
% Required outputs include F_w1, F_w2, the hardness of all four members,
% K_o, K_s, K_B, C_f, K_T, K_R, C_H, Q_v1, Q_v2, the four J values, and C_p.
%%
%[text] ## 2. Geometry and the forces at each mesh
%[text] The force calculation requires the transverse pressure angle:
%[text] $ \\phi_t=\\tan^{-1}\\!\\left(\\frac{\\tan\\phi_n}{\\cos\\psi}\\right), \\qquad m_t=\\frac{m_n}{\\cos\\psi}, \\qquad d = N\\,m_t $
%[text] $ W_t=\\frac{2T}{d_{pinion}}, \\qquad W_r=W_t\\tan\\phi_t, \\qquad W_a=W_t\\tan\\psi $
%[text] The helix produces a smoother mesh at the cost of an axial thrust. Carry all three components of both meshes forward. The intermediate shaft in Student 03 carries the stage-1 gear and the stage-2 pinion, so it is loaded by both meshes at once: two sets of radial forces, two thrusts, and two thrust couples.
% TODO: Check the pitch diameters against d = N*m_t, then calculate both center
% distances and W_t, W_r, W_a
% of each stage. Required units: geometry in both m and mm; forces in N.
%%
%[text] ## 3. AGMA rating factors
%[text] Take each factor from Chapter 14, and be prepared to state what it corrects for and where it was read.
%[text] `Q_v` depends on speed. Each quality number is rated only up to a stated pitch-line velocity:
%[text] $ (V_t)_{max} = \\frac{\\left[A + (Q_v - 3)\\right]^2}{200} \\ \\mathrm{m/s} $
%[text] with the same $\\mathit{A}$ that appears in the $K_v$ expression.
%[text] - Evaluate $K_v$ at the motor base speed, where full torque is reached.
%[text] - Check each stage's `Q_v` against this limit at a vehicle speed of **120 km/h**, the course check speed: compute the pitch-line velocity there and compare it with the limit for the selected `Q_v`. Report both stages.
%[text] - The stage-1 pitch line runs faster than the stage-2 pitch line by the factor $i_1 d_1/d_3$, where $i_1 = N_2/N_1$ is the stage-1 ratio, so the two stages need not share a quality number.
%[text] State in the report why the course fixes a check speed: compute the stage-1 pitch-line velocity at `v_top`, the vehicle speed at `omega_max`, and compare it with the $Q_v = 11$ limit.
%[text] The load-distribution factor `K_m` depends on face width, shaft stiffness and mounting accuracy. The geometry factor `I` depends on the two flank curvatures and the helix angle. Chapter 14 offers more than one admissible reading for each. State which reading was adopted and why.
%[text] Show every unit conversion explicitly. Several of the AGMA factor equations are empirical and expect inches or feet per minute whereas the remainder of the work is in SI. A unit error at this point produces a plausible result and is therefore difficult to detect.
% TODO: Calculate K_v, K_m and I for each stage.
%%
%[text] ## 4. Bending and contact stresses
%[text] Assemble the two stresses from the Chapter 14 equations, and write them with every factor visible even where a factor is one. Bending is calculated separately for each pinion and gear: both members of a pair carry the same $W_t$, but their geometry factors differ. Contact stress is common to both members of a pair, so there is one $\\sigma_c$ per stage, and only the allowable stress differs between the members.
%[text] Report all stresses in MPa.
% TODO: Calculate the four bending stresses and the two contact stresses in MPa.
%%
%[text] ## 5. Allowable stresses, safety factors, and iteration
%[text] Obtain the allowable bending and contact strengths from the hardness values, then modify them for design life, reliability and temperature exactly as Chapter 14 prescribes.
%[text] The four members do not share a cycle count. Each pinion accumulates the revolutions of its own shaft over the 150,000 km target life, and each gear accumulates the count of its pinion divided by the stage ratio, so $Y_N$ and $Z_N$ are evaluated separately for every member. Justify the counts against the service target instead of assuming a rounded value.
%[text] The two safety factors differ in meaning, and this difference must be considered before the results are interpreted. Contact stress varies with the square root of the load, so a contact factor of 1.2 does not represent the same reserve as a bending factor of 1.2. For this reason the two targets in this project differ, and Shigley compares $S_F$ against $S_H^2$, not against $S_H$, when deciding which mode governs. Make that comparison explicitly for all four members.
%[text] Targets: $S_F \\ge 1.5$ (bending) and $S_H \\ge 1.2$ (contact), for every member of both stages.
%[text] If any check fails, iterate. Face width has the most direct effect on bending stress, and hardness has the corresponding effect on pitting. Change one variable at a time, run the file again, and record the change in each result. The report must include at least one documented iteration.
% TODO: Calculate the bending and contact safety factors of all four members.
% TODO: Create gearResults with stress, allowable stress, safety factor,
% target, and pass/fail columns, one row per check.
% TODO: Report which mode governs each member on a like basis, S_F against S_H^2.
%%
%[text] ## 6. Save the results for the next parts
%[text] Student 03 and Student 04 load these results, as Student 01, Task 7, explains. Retain the variable names used above.
% TODO: Save the face widths, pitch diameters and mesh forces to Student02_results.mat.
%%
%[text] ## Local functions
%[text] Place the stage-rating function here, below every cell that calls it.
% TODO: function results = rateStage(...)

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
