%[text] # Student 04: Rolling-contact bearing selection
%[text] Complete the cells marked `TODO` using the rolling-contact bearing procedure of *Shigley's Mechanical Engineering Design*, 11th edition, Chapter 11. A manufacturer's catalog supplies the bore, the outside dimensions and the two load ratings $\\mathit{C}$ and $C_0$. It does not supply the thrust factors: $\\mathit{e}$ and $\\mathit{Y}$ are listed in the Shigley Chapter 11 table of X and Y factors against the ratio $F_a/C_0$, so they are interpolated for each candidate rather than copied from a catalog page. Cite the catalog page for every value you did take from one.
%[text] This is the first component in the project that you do not size from first principles. You calculate the loads, evaluate the life each candidate would give, and select. The skill being assessed is defending the selection, and a selection means nothing unless something was rejected.
%[text] $L_{10}$ is the life that 90 percent of a large batch of nominally identical bearings reach before the first evidence of fatigue spalling. The whole project designs to 90 percent reliability, so $L_{10}$ is the life to compare with the target, with no reliability adjustment and no application factor.
%[text] The intermediate shaft is carried on one locating bearing and one floating bearing. The locating bearing takes the axial thrust and fixes the axial position of the shaft; the floating bearing carries radial load only and is free to slide as the shaft expands. Take bearing A, on the stage-1 side, as the locating bearing, or state your own choice.
%[text] The selection is on rating life. Also report the static ratio $s_0 = C_0/P_0$ for the floating bearing at peak torque, with $P_0 = F_r$ because that bearing carries no thrust. The static check of the locating bearing would need the catalog's static thrust factors, which Shigley does not give; list it in your report as a limitation.
%[text:tableOfContents]{"heading":"Tasks"}
%%
%[text] ## 1. Intermediate-shaft bearing loads
%[text] The bearing load varies with the torque. Shigley Chapter 11 reduces a continuously varying load to the constant load that gives the same rating life: the cubic mean of the load weighted by shaft revolutions. `T_cubic_mean_int` is that reduction of the FTP-75 torque, and the mesh forces are proportional to torque, so work the reactions at `T_cubic_mean_int`. Say in your report why the mean of the equivalent sinusoid would be the wrong basis here.
%[text] Calculate the forces of both meshes at that torque, then take moments about each bearing to obtain the radial reactions $F_{rA}$ and $F_{rB}$ in both planes, from the same free body as the shaft in Student 03: both tangential forces, both radial forces, and both thrust couples. The common sign of the couples is not fixed by this project, which leaves the helix hand and the direction of rotation unspecified, so take the worse sign at each support.
%[text] The locating bearing carries the net thrust, which follows from your Student 03 finding on whether the two thrusts add or oppose. The floating bearing carries none.
% TODO: Load Student01_results.mat, Student02_results.mat and Student03_results.mat, then calculate F_rA, F_aA,
% F_rB, and F_aB from T_cubic_mean_int.
%%
%[text] ## 2. Candidate catalog data
%[text] Choose candidate bearings whose nominal bore matches the journal diameter from Student 03. For each one, tabulate the designation, bore, outside diameter, width, catalog rating $C_{10}$ (the catalog's basic dynamic load rating $\\mathit{C}$), and basic static load rating $C_0$. A larger bore is not a direct fit: revise the journal and repeat the shaft checks.
%[text] $C_{10}$ and $C_0$ describe different things and cannot be substituted for one another. $C_{10}$ is the load that gives one million revolutions of rating life and it is what sets $L_{10}$. $C_0$ is the load the bearing can sustain without rotating before the raceways are permanently indented. In the life-based selection it enters only through the X and Y factors, as the argument of their table, and separately through the static ratio $s_0$ described above.
%[text] Include at least one candidate whose load rating is clearly too low (a lighter series at the same bore) and one that is clearly oversized.
% TODO: Create bearingCandidates.
%%
%[text] ## 3. Equivalent radial load and rating life
%[text] The Shigley equivalent radial load, with the rotation factor $V = 1$ because the inner ring rotates, is:
%[text] $ F_e = X_i V F_r + Y_i F_a $
%[text] For a deep-groove ball bearing $\\mathit{e}$ and $\\mathit{Y}$ are not constants. Interpolate them in the Shigley Chapter 11 table for each candidate. Then compare $F_a/(V F_r)$ against that candidate's own $\\mathit{e}$: at or below it the thrust is small enough to neglect, giving $X=1$ and $Y=0$; above it, $X=0.56$ with the tabulated $\\mathit{Y}$.
%[text] The rating life in millions of revolutions then follows, with $a=3$ for ball bearings:
%[text] $ L_{10}=\\left(\\frac{C_{10}}{F_e}\\right)^{a} $
%[text] Convert that result into vehicle distance so it can be compared against the 150,000 km target. The intermediate shaft turns $N_4/N_3$ times faster than the wheel, so
%[text] $ \\mathrm{rev/km}=\\frac{1000}{2\\pi R_w}\\,\\frac{N_4}{N_3} $
% TODO: Interpolate e and Y for every candidate.
% TODO: Calculate P_A, P_B, L10_A_km, and L10_B_km for every candidate.
%%
%[text] ## 4. Selection
%[text] Take the lightest candidate with a matching nominal bore and $L_{10}$ of at least 150,000 km at each support. The two supports need not receive the same bearing. These two checks fix the bore and the load rating. Then check the mounting. The gear-seat shoulders from Student 03 bound the gear seat inboard of the bearings and are not bearing abutments, so specify the separate bearing shoulder or spacer that locates each bearing, and check the catalog abutment diameter and corner radius of the selected bearing against it.
%[text] State which of the two requirements determined each choice, and what that implies for where mass could be saved.
%[text] Conclude with one table for the report giving, for both supports, the designation, bore, $F_r$, $F_a$, the $\\mathit{e}$ and $\\mathit{Y}$ you interpolated, $F_e$, $L_{10}$ in kilometers, and the catalog reference.
% TODO: Select bearings A and B and create the bearingSelection table.
% TODO: Specify the bearing shoulder or spacer at each support and check the catalog
% abutment diameter and corner radius against it.
%%
%[text] ## 5. Extension: the input-shaft bearings
%[text] If you designed the input shaft in Student 03, select its bearings the same way. It has one mesh and one thrust couple, its locating bearing takes the whole stage-1 thrust, and it turns $\\mathit{G}$ times faster than the wheel. Compare its lives with the intermediate shaft's and explain the difference in terms of load and revolutions.
% TODO (extension): Select the input-shaft bearings.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
