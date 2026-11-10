%[text] # Student 01: Load the design inputs
%[text] This file is a template to be completed. Write MATLAB code only in the cells marked `TODO`. The remaining text is the brief for this part.
%[text] Every method in this assignment is taken from *Shigley's Mechanical Engineering Design*, 11th edition. Chapter numbers are given so that they can be cited in the report.
%[text] The loads for this project are obtained from a vehicle simulation that the instructor has already run for three driving cases. In this file those results are loaded and each quantity is assigned to the later calculation it supports. Extracting a design load spectrum from a system-level model is the part of this project that earlier coursework does not cover, and the decisions made here carry through the three files that follow.
%[text:tableOfContents]{"heading":"Tasks"}
%%
%[text] ## 1. Load the instructor data
%[text] The hand-out contains a folder named `exports_design_ready`. It is located beside this file, so the relative path `exports_design_ready/` resolves wherever the hand-out is stored. Keep the two together.
%[text] The folder contains four MAT-files. `Design_Summary.mat` contains the vehicle and gear data. Each of the other three contains one driving case: `FTP75_Outputs.mat` for the city cycle, `HillClimb_Outputs.mat` for a sustained climb, and `DragRace_Outputs.mat` for full-throttle acceleration. In each case file the design scalars are stored in a struct named `ds_single`.
% TODO: Define exportDir and load the four MAT-files.
% Required workspace variables: S_summary, S_ftp, S_hill, S_drag
%%
%[text] ## 2. Extract the design torques
%[text] Five torque quantities are supplied and each one supports a different check. They are obtained from the same simulation but are reduced by different rules, so they are not interchangeable. All of them are motor torques, that is, torques on the input shaft.
%[text] `T_peak` is the maximum torque the motor can produce, taken from the full-throttle case. It is the load for the gear tooth rating (Chapter 14) and for the shaft static yield check (Chapter 5).
%[text] `T_mean_eq` and `T_alt_eq` are obtained from the city cycle. The FTP-75 torque history has already been reduced to one equivalent sinusoid by rainflow counting (a standard cycle-counting method, ASTM E1049, that splits an irregular load history into individual cycles, each with its own mean and alternating value). The result is the mean and alternating pair, $T_m$ and $T_a$, that the fatigue procedure of Chapters 6 and 7 requires.
%[text] `T_cubic_mean` is also obtained from the city cycle but is reduced with a cubic mean weighted by shaft revolutions, because ball-bearing life varies inversely with the cube of the load. It is the bearing load, the constant load equivalent to the varying one (Shigley, Chapter 11).
%[text] `T_steady` is the settled torque on a long climb. It is used twice: in Task 6 below to verify the simulation by hand calculation before any torque is relied upon, and in the optional Student 03 extension to determine how long the shaft survives a sustained climb. It is stored as `ds_single.T_ss_mean` in `HillClimb_Outputs.mat`.
%[text] The reduced city-cycle spectrum is the basis of the shaft fatigue check and the bearing lives. The tooth rating uses `T_peak` alone (the torque table in `ASSIGNMENT_BRIEF.md` gives the reason), and the report should state this.
% TODO: Extract T_peak, T_mean_eq, T_alt_eq, T_cubic_mean, and T_steady.
% Required units: N·m
%%
%[text] ## 3. Extract the prescribed gear train
%[text] The transmission is single speed with two stages, on three parallel shafts. Stage 1 is the primary reduction: the input pinion, `N1` teeth, drives gear `N2` on the intermediate shaft. Stage 2 is the final drive: pinion `N3` on the same intermediate shaft drives gear `N4` on the output shaft, which carries the differential. The overall ratio is $G = (N_2/N_1)(N_4/N_3)$.
%[text] The numbers of teeth, the two normal modules and the two helix angles are fixed for the whole class and stored in `Design_Summary.mat`. They are not design variables. Face widths and materials are selected in Student 02.
%[text] Read, for each stage, the numbers of teeth, the normal and transverse modules, the transverse pressure angle, the helix angle, and the two pitch diameters (`d1` to `d4`). The normal pressure angle `phi_n_deg` is common to both stages.
%[text] The export stores the angles in degrees (`phi_n_deg`, `phi_t1_deg`, `psi1_deg`, and the stage-2 pair), while the modules and diameters are in meters. Convert the angles once, here, and carry radians through the rest of the project.
% TODO: Extract G (stored as gear_ratio), eta_dt, R_w (stored as wheel_R), N1, N2, N3, N4, m_n1, m_n2, m_t1, m_t2,
% phi_n, phi_t1, phi_t2, psi1, psi2, d1, d2, d3, d4, and v_base and v_top.
%%
%[text] ## 4. Calculate the torque on every shaft
%[text] The torque transfer below applies the motoring loss factor in both directions, a course approximation described under Scope and limitations in `ASSIGNMENT_BRIEF.md`.
%[text] The drivetrain efficiency `eta_dt` is a single value for the whole transmission. The two meshes are of the same kind, so assign each the same share of the loss, $\\sqrt{\\eta_{dt}}$:
%[text] $ T_{int}=T_{in}\\,\\frac{N_2}{N_1}\\sqrt{\\eta_{dt}}, \\qquad T_{out}=T_{int}\\,\\frac{N_4}{N_3}\\sqrt{\\eta_{dt}}=T_{in}\\,G\\,\\eta_{dt} $
%[text] Apply this to all five torques. The intermediate shaft is the shaft designed in Student 03 and Student 04, so those files use the intermediate torques.
% TODO: Calculate the intermediate- and output-shaft torques.
% Required outputs: T_peak_int, T_mean_eq_int, T_alt_eq_int,
% T_cubic_mean_int, T_steady_int, and the five *_out torques.
%%
%[text] ## 5. Check the torque table before continuing
%[text] Build one table of the input, intermediate and output shaft torques and a second table of the gear train, giving every column a unit.
%[text] Then confirm two conditions. The product of the two stage ratios equals `G`, and each output torque equals $G\\,\\eta_{dt}$ times the corresponding input torque. If either check fails, the wrong variable has probably been read from the file. Finally, compare `T_alt_eq` with `T_mean_eq`, and every FTP-75 torque with `T_peak`, and state in the report what each comparison indicates about the city cycle as a duty.
% TODO: Create designInputs and gearTrain tables.
%%
%[text] ## 6. Validate the simulation with the hill climb
%[text] The hill climb provides a torque that can be verified by hand calculation before any value from the model is used in design. On a long grade at full throttle the vehicle settles at the highest speed it can sustain, where the motor runs on its power limit and there is no acceleration, so the steady state reduces to a single equilibrium equation:
%[text] $ \\eta_{dt}\\,P_{max} = \\left(m g \\sin\\theta + C_{rr} m g + \\frac{1}{2}\\rho C_d A v^2\\right) v, \\qquad T_{steady} = \\frac{P_{max}}{\\omega_m}, \\quad \\omega_m = \\frac{G v}{R_w} $
%[text] Every input is in `Design_Summary.mat`: `m_vehicle`, `Crr`, `Cd`, `A_frontal`, `rho_air`, `theta_hill_deg`, `Pmax`, `eta_dt`, `wheel_R` and `gear_ratio`. Take $g = 9.81$ m/s², as the model does. The first equation is a cubic in the settling speed $\\mathit{v}$. Solve it numerically (for example with `fzero`), then compute $T_{steady}$ and compare it with the simulated value.
%[text] State the percentage difference and explain it. State which mass was used and why the rotating inertia plays no part. Check that the calculated torque is below `Tmax` (if it were not, the climb would be torque-limited and the steady torque would be `Tmax` itself), check that the settling speed is below 95 percent of `v_top` (above it the speed limiter of the motor reduces the available torque, so the power-limited equation no longer applies), and state what a difference of more than one percent would indicate about the simulation.
% TODO: Solve for the settling speed v_hill and compute T_steady_hand.
% TODO: Report T_steady_hand, the simulated T_steady, and their ratio.
%%
%[text] ## 7. Save the results for the next parts
%[text] Each later part begins by loading the results of this one, so the parts can be run in separate MATLAB sessions. Retain the variable names used above.
% TODO: Save the torques on all three shafts, every variable extracted in Task 3, and v_hill to Student01_results.mat.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
