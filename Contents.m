% SimDrive: EV Transmission Design
% Version 4.0.0 (2026)
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
%   MATLAB R2025a or newer; the instructor notebooks are Live Scripts (.mlx).
%   Simulink                    - programmatic longitudinal vehicle model.
%   Signal Processing Toolbox   - rainflow() fatigue load extraction.
%   Tested on R2025b and R2026b on Windows, and on R2025b on Linux in CI;
%   R2025a has not been tested.
%
% Quick start (instructor):
%   >> cd instructor
%   >> Start_Here          % preflight check, then launch the dashboard
%
% Repository layout:
%   instructor/   - Instructor tools and teaching notebooks
%     Start_Here.mlx                     - Launcher: preflight + GUI/CLI
%     main.mlx                           - Load-case generator (Live Script)
%     generateLoadCases.m                - Command-line entry point
%     check_dependencies.mlx             - Environment checker
%     InstructorApp.m                    - GUI dashboard class
%     SimDriveCore.m                     - Shared simulation backend
%     ftp75Schedule.m                    - Built-in EPA FTP-75 drive cycle
%     SimDrive_EV_Gearbox_Workflow.mlx   - High-level teaching notebook
%     SimDrive_01_Setup_Validation.mlx   - Setup and dependencies
%     SimDrive_02_Load_Case_Generator.mlx- Load-case workflow
%     SimDrive_03_Simulink_Backend.mlx   - Simulink backend
%     SimDrive_04_Instructor_App_Flow.mlx- GUI architecture
%     SimDrive_05_Student_Transmission_Design.mlx - Student design overview
%
%   instructor/solution/  - Worked answer key, not for students
%     Solution_00..04 *.m                - Reference solution, encrypted in instructor_answer_key.7z
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
%                       tools/buildStudentPackage.m: project brief, the four
%                       templates, the three student documents, the notch
%                       helper, both licenses, and the reduced dataset in
%                       exports_design_ready/ beside the templates
%
%   docs/         - Instructor guide, course scope, equations, and models
%   tools/        - Student hand-out builder
%   validation/   - Standalone 0-100 km/h vehicle validation script
%   exports_design_ready/  - Instructor working export, full resolution
%   release/      - Generated student ZIP
%
% License:
%   Software: BSD-3-Clause (see LICENSE)
%   Course materials: CC BY-SA 4.0 (see LICENSE-docs)
