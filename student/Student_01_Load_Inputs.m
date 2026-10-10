%[text] # Student 01: Load the Design Inputs
%[text] This is a fill-in template. Write MATLAB only in the cells marked `TODO`. The rest of the file is your brief.
%[text] Every method in this assignment comes from *Shigley's Mechanical Engineering Design*, 11th edition. Chapter numbers are given so that you can cite them in your report.
%[text] The load is not stated in the question. An instructor-side simulation has already driven the vehicle through three situations, and this file is where you open those results and decide which quantity belongs in which later calculation. Reading a design load spectrum out of a system-level model is the part of this project you have not done before, and the decisions you make here carry through all three files that follow.
%[text:tableOfContents]{"heading":"Tasks"}
%%
%[text] ## 1. Load the instructor data
%[text] Your hand-out folder contains a folder named `exports_design_ready`. It sits beside this file, so the relative path `exports_design_ready/` resolves from wherever you put the hand-out. Keep the two together.
%[text] The folder contains four MAT-files. `Design_Summary.mat` holds the vehicle and gear data. The other three each hold one driving case: `FTP75_Outputs.mat` for the city cycle, `HillClimb_Outputs.mat` for a sustained climb, and `DragRace_Outputs.mat` for full-throttle acceleration. In each case file the design scalars sit in a struct named `ds_single`.
% TODO: Define exportDir and load the four MAT-files.
% Required workspace variables: S_summary, S_ftp, S_hill, S_drag
%%
%[text] ## 2. Extract the design torques
%[text] Five torque quantities are supplied and each one supports a different check. They come from the same simulation but are reduced by different rules, so they are not interchangeable. All of them are motor torques, which is the torque on the input shaft.
%[text] `T_peak` is the largest torque the motor can produce, taken from the full-throttle case. It sizes the gear teeth (Ch. 14) and the shaft static yield check (Ch. 5).
%[text] `T_mean_eq` and `T_alt_eq` come from the city cycle. The FTP-75 torque history has already been reduced to one equivalent sinusoid by rainflow counting (a standard cycle-counting method, ASTM E1049, that splits an irregular load history into individual cycles, each with its own mean and alternating value). The result is the mean and alternating pair, $T_m$ and $T_a$, that the Ch. 6 and Ch. 7 fatigue procedure requires.
%[text] `T_cubic_mean` also comes from the city cycle but is reduced with a cubic mean weighted by shaft revolutions, because ball-bearing life varies inversely with the cube of the load. It is the bearing load, the constant load equivalent to the varying one (Shigley Ch. 11).
%[text] `T_steady` is the settled torque on a long climb. You use it twice: in Task 6 below to check the simulation by hand before trusting any torque, and in the optional Student 03 extension to find how long the shaft survives a sustained climb. It is stored as `ds_single.T_ss_mean` in `HillClimb_Outputs.mat`.
%[text] Note which checks the city cycle drives and which it does not. The reduced spectrum drives the shaft fatigue check and the bearing lives. It does not drive the tooth rating: Ch. 14 rates a tooth at a single transmitted load, and here that load is `T_peak`. Your report should say so rather than imply the duty cycle sized the teeth.
% TODO: Extract T_peak, T_mean_eq, T_alt_eq, T_cubic_mean, and T_steady.
% Required units: N*m
%%
%[text] ## 3. Extract the prescribed gear train
%[text] The transmission is single speed with two stages, on three parallel shafts. Stage 1 is the primary reduction: the input pinion, `N1` teeth, drives gear `N2` on the intermediate shaft. Stage 2 is the final drive: pinion `N3` on the same intermediate shaft drives gear `N4` on the output shaft, which carries the differential. The overall ratio is $G = (N_2/N_1)(N_4/N_3)$. This is the layout of many production EV drive units.
%[text] The tooth counts, the two normal modules and the two helix angles are fixed for the whole class and stored in `Design_Summary.mat`. You do not select them. Face widths and materials are yours to choose, in Student 02.
%[text] Read, for each stage, the tooth numbers, the normal and transverse modules, the transverse pressure angle, the helix angle, and the two pitch diameters (`d1` to `d4`). The normal pressure angle `phi_n_deg` is common to both stages.
%[text] One trap in the export. The angles are stored in degrees (`phi_n_deg`, `phi_t1_deg`, `psi1_deg`, and the stage-2 pair), while the modules and diameters are in meters. Convert the angles once, here, and carry radians through the rest of the project.
% TODO: Extract G (stored as gear_ratio), eta_dt, R_w (stored as wheel_R), N1, N2, N3, N4, m_n1, m_n2, m_t1, m_t2,
% phi_n, phi_t1, phi_t2, psi1, psi2, and d1, d2, d3, d4.
%%
%[text] ## 4. Calculate the torque on every shaft
%[text] The drivetrain efficiency `eta_dt` is one number for the whole transmission. The two meshes are of the same kind, so give each the same share of the loss, $\\sqrt{\\eta_{dt}}$:
%[text] $ T_{int}=T_{in}\\,\\dfrac{N_2}{N_1}\\sqrt{\\eta_{dt}}, \\qquad T_{out}=T_{int}\\,\\dfrac{N_4}{N_3}\\sqrt{\\eta_{dt}}=T_{in}\\,G\\,\\eta_{dt} $
%[text] Apply this to all five torques. The intermediate shaft is the shaft you design in Student 03 and Student 04, so the intermediate torques are the ones those files use.
% TODO: Calculate the intermediate- and output-shaft torques.
% Required outputs: T_peak_int, T_mean_eq_int, T_alt_eq_int,
% T_cubic_mean_int, T_steady_int, and the five *_out torques.
%%
%[text] ## 5. Check the handoff before continuing
%[text] Build one table of the input, intermediate and output shaft torques and a second table of the gear train, giving every column a unit.
%[text] Then confirm four things. The product of the two stage ratios equals `G`. Each output torque equals $G\\,\\eta_{dt}$ times the corresponding input torque. The alternating torque is larger than the mean, which is what you would expect from a city cycle that brakes regeneratively about as often as it accelerates: the equivalent sinusoid swings through zero. And every FTP-75 torque is far below `T_peak`: the city cycle is a light duty cycle. If any check fails, you have probably read the wrong variable from the file.
% TODO: Create designInputs and gearTrain tables.
%%
%[text] ## 6. Validate the simulation with the hill climb
%[text] Check a torque before you design with it. The hill climb gives you one you can check by hand. On a long grade at full throttle the car settles at the fastest speed it can hold, where the motor runs on its power limit and there is no acceleration, so the steady state has a closed form:
%[text] $ \\eta_{dt}\\,P_{max} = \\left(m g \\sin\\theta + C_{rr} m g + \\tfrac{1}{2}\\rho C_d A v^2\\right) v, \\qquad T_{steady} = \\dfrac{P_{max}}{\\omega_m}, \\quad \\omega_m = \\dfrac{G v}{R_w} $
%[text] Every input is in `Design_Summary.mat`: `m_vehicle`, `Crr`, `Cd`, `A_frontal`, `rho_air`, `theta_hill_deg`, `Pmax`, `eta_dt`, `wheel_R` and `gear_ratio`. The first equation is a cubic in the settling speed $\\mathit{v}$; solve it numerically (for example with `fzero`), then compute $T_{steady}$ and compare it with the simulated value.
%[text] State the percentage difference and explain it. Say which mass you used and why the rotating inertia plays no part, check that your torque is below `Tmax` (if it were not, the climb would be torque-limited and the steady torque would be `Tmax` itself), check that your settling speed is below 95 percent of `v_top` (above it the motor's speed limiter is reducing the available torque, so the power-limited equation no longer applies), and say what a difference of more than a few percent would tell you about the simulation.
% TODO: Solve for the settling speed v_hill and compute T_steady_hand.
% TODO: Report T_steady_hand, the simulated T_steady, and their ratio.
%%
%[text] ## 7. Save the results for the next parts
%[text] Each later part starts by loading what this one produced, so the parts can be run in separate MATLAB sessions. Keep the variable names used above.
% TODO: Save the torques on all three shafts and the gear-train data to Student01_results.mat.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
