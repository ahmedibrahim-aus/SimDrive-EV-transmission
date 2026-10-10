% SimDrive: EV Transmission Design
% Version 1.0.0 (2026)
%
% Ahmed Hanafy Ibrahim, Assistant Professor (ahmedibrahim@aus.edu)
% Mahmoud Al Herbawi and Malek Zahir, senior undergraduate students
% Financial support: MathWorks Teaching Support Award
%
% Generates motor torque/speed histories from a Simulink EV model
% (FTP-75, Hill Climb, Drag Race) for student gearbox design projects
% (AGMA gear rating, Shigley shaft design, Shigley bearing life with SKF
% catalog data).
%
% Requirements:
%   MATLAB R2025b or newer; the instructor notes are Live Scripts (.mlx).
%   Simulink                    - programmatic longitudinal vehicle model.
%   Signal Processing Toolbox   - rainflow() fatigue load extraction.
%   Tested on R2025b and R2026b on Windows.
%
% Quick start (instructor):
%   >> cd instructor
%   >> Start_Here          % preflight check, then launch the dashboard
%
% Repository layout:
%   instructor/   - Dashboard, simulation and instructor Live Scripts
%     Start_Here.mlx                     - Launcher: preflight + GUI/CLI
%     main.mlx                           - Load-case generator (Live Script)
%     generateLoadCases.m                - Command-line entry point
%     check_dependencies.mlx             - Environment checker
%     InstructorApp.m                    - GUI dashboard class
%     SimDriveCore.m                     - Shared simulation backend
%     ftp75Schedule.m                    - Built-in EPA FTP-75 drive cycle
%     buildGearTrain.m                   - Two-stage gear train geometry and checks
%     buildStudentPackage.m              - Builds the student hand-out and ZIP
%     PowertrainView3D.m                 - 3D drive-unit view in the dashboard
%     SimDrive_Workflow.mlx                - Overview of the whole workflow
%     SimDrive_01_Setup_Validation.mlx     - Setup and dependencies
%     SimDrive_02_Load_Case_Generator.mlx  - Load-case workflow
%     SimDrive_03_Simulink_Backend.mlx     - Simulink backend
%     SimDrive_04_Instructor_App_Flow.mlx  - GUI architecture
%     SimDrive_05_Student_Transmission_Design.mlx
%                                        - Notes on the student design flow
%
%   instructor/solution/  - Worked answer key, not for students
%     Solution_00 to Solution_04         - Reference solution (in instructor_answer_key.7z)
%     computeShoulderNotchFactors.m      - Shaft shoulder Kt_axial/Kt_bending/Kts/Kf/Kfs helper
%     courseTargets.m                    - Course targets: safety factors, design life, Q_v speed
%
%   student/      - Comment-scaffolded plain-text Live Code templates
%     Student_01_Load_Inputs.m           - Load instructor exports
%     Student_02_Gear_Design.m           - Shigley/AGMA gear stress
%     Student_03_Shaft_Design.m          - Stepped shaft, fatigue + yield
%     Student_04_Bearing_Selection.m     - Shigley L10 bearing life
%
%   student_package/  - The hand-out students receive, built by
%                       instructor/buildStudentPackage.m: project brief, the four
%                       templates, the three student documents, the notch
%                       helper, both licenses, and the reduced dataset in
%                       exports_design_ready/ beside the templates
%
%   docs/         - Instructor guide, course scope, equations, and models
%   instructor_answer_key.7z - Encrypted answer key (password on request)
%   validation/   - Standalone 0-100 km/h vehicle validation script
%   exports_design_ready/  - Instructor working export (generated, not in the repository)
%   release/      - Student ZIP (generated, not in the repository)
%
% License:
%   Software: BSD-3-Clause (see LICENSE)
%   Course materials: CC BY-SA 4.0 (see LICENSE-docs)
