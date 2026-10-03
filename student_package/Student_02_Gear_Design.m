%[text] # Student 02: Two-Stage Helical Gear Design
%[text] Complete the cells marked `TODO` using only the gear procedure of *Shigley's Mechanical Engineering Design*, 11th edition: Ch. 13 for geometry and tooth forces, Ch. 14 for the AGMA stress and strength equations. A manufacturer's catalog may supply material data. It does not supply an alternative equation.
%[text] The gear train is prescribed: stage 1 from the input pinion to the intermediate gear, stage 2 from the intermediate pinion to the output gear. What you select, and must justify in your report, is the face width of each stage, the material and its hardness, and every rating factor that appears in the AGMA equations. Bending and pitting are rated separately and both have to pass, on both stages.
%[text] The two stages are rated by the same procedure. Write it once, as a local function at the end of this file that takes one stage's geometry, torque, speed and cycle count and returns its stresses and safety factors, then call it twice. If the function gives the right answer for stage 1, the only new thing in stage 2 is its inputs.
%[text:tableOfContents]{"heading":"Tasks"}
%%
%[text] ## 1. Load inputs and select trial design values
%[text] Load the results of Student 01 and use `T_peak` for the tooth stresses. Ch. 14 rates a tooth at one transmitted load, so this is a single-point check at the worst torque the motor can deliver. The stage-1 pinion carries `T_peak`; the stage-2 pinion carries `T_peak_int`, the same torque after the first mesh and its loss. The city-cycle spectrum is not used here. It drives the shaft fatigue check in Student 03 and the bearing lives in Student 04.
%[text] Then select your starting values, one set per stage. Each of the following is a design decision you defend in the report, and each has a corresponding treatment in Ch. 14.
%[text] Face width `F_w`: Shigley Ch. 14 recommends three to five times the transverse circular pitch, $p_t = \pi m_t$. Work out that band for each stage from its own module. Narrower overstresses the tooth; wider will not load evenly across its length. Face width is the first lever to reach for when you come to minimize mass.
%[text] Brinell hardness of each pinion and gear: these set the allowable bending and contact stresses. A pinion turns faster than its gear by the stage ratio, so it accumulates load cycles faster and is normally specified harder. Name the steel and the heat treatment, and quote the Shigley Table A-20 or A-21 row you read the hardness from.
%[text] One grade, both modes. Figure 14-2 gives `S_t` and Figure 14-5 gives `S_c`, each with a Grade 1 and a Grade 2 line. Grade 2 is a cleanliness and metallurgical-control specification, so a single material sits on a single grade and raises both numbers together. Reading bending off one grade and pitting off the other describes a material you cannot buy.
%[text] The remaining factors are the overload factor `K_o`, size factor `K_s`, rim-thickness factor `K_B`, surface-condition factor `Z_R` (`C_f`), temperature factor `K_T`, reliability factor `K_R`, hardness-ratio factor `C_H`, quality number `Q_v`, geometry factors `J` and `I`, and elastic coefficient `Z_E`. Each has to be sourced from a named Ch. 14 figure, table or equation and defended in the report. Defending these choices carries more points in this file than the arithmetic does. The service target, 150,000 km, is fixed for the course; what you derive from it in Task 5 is the cycle count of each member.
%[text] Two of them repay particular care. `J` is read from Figure 14-7, which is drawn for 75 teeth in the mating element, then multiplied by the Figure 14-8 factor. Read the multiplier at the member's own tooth count, as Shigley does in Example 14-5, so a member with fewer than 75 teeth takes a multiplier below one and a larger member one above it; in the default train all four multipliers are below one. And `K_o` covers load above nominal, so justify it against a torque that is already the motor's hard limit, or say why you set it to one.
%[text] Treat all of these as trial values. You will return and change them.
% TODO: Load Student01_results.mat and define the trial design variables of both stages.
% Required outputs include F_w1, F_w2, the hardness of all four members,
% K_o, K_s, K_B, Z_R, K_T, K_R, C_H, Q_v1, Q_v2, the four J values, and Z_E.
%%
%[text] ## 2. Geometry and the forces at each mesh
%[text] The transverse pressure angle is the one the force calculation needs:
%[text] $ \phi_t=\tan^{-1}\!\left(\dfrac{\tan\phi_n}{\cos\psi}\right), \qquad m_t=\dfrac{m_n}{\cos\psi}, \qquad d = N\,m_t $
%[text] $ W_t=\dfrac{2T}{d_{pinion}}, \qquad W_r=W_t\tan\phi_t, \qquad W_a=W_t\tan\psi $
%[text] Carry all three components of both meshes forward, not only $W_t$. The intermediate shaft in Student 03 carries the stage-1 gear and the stage-2 pinion, so it is loaded by both meshes at once: two sets of radial forces, two thrusts, and two thrust couples. The helix gives a smoother mesh at the cost of an axial thrust.
% TODO: Calculate the pitch diameters, both center distances, and W_t, W_r, W_a
% of each stage. Required units: geometry in both m and mm; forces in N.
%%
%[text] ## 3. AGMA rating factors
%[text] Take each factor from Ch. 14 and be able to state what it corrects for and where you read it.
%[text] `Q_v` is not a free choice. Each quality number is rated only up to a stated pitch-line velocity, Eq. (14-29):
%[text] $ (V_t)_{max} = \left[A + (Q_v - 3)\right]^2 \ \mathrm{ft/min} $
%[text] with the same $A$ that appears in the $K_v$ expression. Evaluate $K_v$ at the motor base speed, where full torque is reached. Check `Q_v` against Eq. (14-29) at a vehicle speed of **120 km/h**, the course check speed: compute each stage's pitch-line velocity there and compare it with the limit for the `Q_v` you picked. The stage-1 pitch line runs faster than the stage-2 pitch line by the factor $i_1 d_1/d_3$ (about 2 in the default train), so the two stages need not share a quality number. Make the check for both and report both figures. Note in your report why the course fixes a check speed: the motor turns to `omega_max` (`v_top`, about 224 km/h for the default car), and near that speed the stage-1 pinion runs faster than the $Q_v = 11$ limit of Fig. 14-9 (10,000 ft/min).
%[text] `K_H` depends on face width, shaft stiffness and mounting accuracy; `I` depends on the two flank curvatures and the helix angle. Ch. 14 offers more than one admissible reading for each. State which you took and why.
%[text] Show every unit conversion explicitly. Several of the AGMA factor equations are empirical and expect inches or feet per minute while the rest of your work is in SI. Mixing them produces a plausible wrong answer rather than an obvious one.
% TODO: Calculate K_v, K_H and I for each stage.
%%
%[text] ## 4. Bending and contact stresses
%[text] Assemble the two stresses from the Ch. 14 equations, and write them with every factor visible even where a factor is one. Bending is calculated separately for each pinion and gear: both members of a pair carry the same $W_t$, but their geometry factors differ. Contact stress is common to both members of a pair, so there is one $\sigma_H$ per stage; what differs between the members is the allowable.
%[text] Report all stresses in MPa.
% TODO: Calculate the four bending stresses and the two contact stresses in MPa.
%%
%[text] ## 5. Allowable stresses, safety factors, and iteration
%[text] Obtain the allowable bending and contact strengths from the hardness values, then modify them for design life, reliability and temperature exactly as Ch. 14 prescribes.
%[text] The four members do not share a cycle count. Each pinion sees the revolutions of its own shaft over the 150,000 km service target, and each gear sees its pinion's count divided by the stage ratio, so $Y_N$ and $Z_N$ are evaluated separately for every member. Justify the counts against the service target rather than asserting a round number.
%[text] Note the difference between the two safety factors before you interpret your results. Contact stress varies with the square root of the load, so a contact factor of 1.2 does not represent the same reserve as a bending factor of 1.2. This is why the two targets in this project differ, and why Shigley compares $S_F$ against $S_H^2$, not against $S_H$, when deciding which mode governs. Make that comparison explicitly for all four members.
%[text] Targets: bending $n \ge 1.5$ and contact $n \ge 1.2$, for every member of both stages.
%[text] If any check fails, iterate. Face width is the most direct lever on bending stress, and hardness is the corresponding lever on pitting. Change one variable at a time, re-run, and record what moved. Your report must include at least one documented iteration.
% TODO: Calculate the bending and contact safety factors of all four members.
% TODO: Create gearResults with stress, allowable stress, safety factor,
% target, and pass/fail columns, one row per check.
% TODO: Report which mode governs each member on a like basis, S_F against S_H^2.
%%
%[text] ## 6. Save the results for the next parts
%[text] Each later part starts by loading what this one produced, so the parts can be run in separate MATLAB sessions. Keep the variable names used above.
% TODO: Save the face widths, pitch diameters and mesh forces to Student02_results.mat.
%%
%[text] ## Local functions
%[text] Put your stage-rating function here, below every cell that calls it.
% TODO: function results = rateStage(...)

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
