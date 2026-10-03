classdef tRequiredFiles < matlab.unittest.TestCase
    %TREQUIREDFILES  Structural checks: the released file layout is intact.

    properties
        RepoRoot
    end

    methods (TestClassSetup)
        function setupRoot(tc)
            tc.RepoRoot = fileparts(fileparts(mfilename('fullpath')));
        end
    end

    methods (Test, TestTags = {'Unit'})

        function instructorFilesExist(tc)
            req = [
                "instructor/InstructorApp.m"
                "instructor/PowertrainView3D.m"
                "instructor/SimDriveCore.m"
                "instructor/generateLoadCases.m"
                "instructor/ftp75Schedule.m"
                "instructor/main.mlx"
                "instructor/check_dependencies.mlx"
                "instructor/Start_Here.mlx"
                "instructor/SimDrive_EV_Gearbox_Workflow.mlx"
                "instructor/SimDrive_01_Setup_Validation.mlx"
                "instructor/SimDrive_02_Load_Case_Generator.mlx"
                "instructor/SimDrive_03_Simulink_Backend.mlx"
                "instructor/SimDrive_04_Instructor_App_Flow.mlx"
                "instructor/SimDrive_05_Student_Transmission_Design.mlx"];
            for f = req'
                tc.verifyTrue(isfile(fullfile(tc.RepoRoot, f)), "missing: " + f);
            end
        end

        function studentTemplatesExist(tc)
            % v2.0 plain-text Live Code templates are the GitHub source of truth.
            req = [
                "student/Student_01_Load_Inputs.m"
                "student/Student_02_Gear_Design.m"
                "student/Student_03_Shaft_Design.m"
                "student/Student_04_Bearing_Selection.m"];
            for f = req'
                tc.verifyTrue(isfile(fullfile(tc.RepoRoot, f)), "missing: " + f);
            end
        end

        function solutionFilesExist(tc)
            % The notch helper is public (students receive it). The answer
            % key ships encrypted; either the archive or its extracted files
            % must be present.
            tc.verifyTrue(isfile(fullfile(tc.RepoRoot, "instructor/solution/computeShoulderNotchFactors.m")));
            archive = isfile(fullfile(tc.RepoRoot, "instructor_answer_key.7z"));
            extracted = isfile(fullfile(tc.RepoRoot, "instructor/solution/Solution_00_Run_All.m"));
            tc.verifyTrue(archive || extracted, ...
                "Neither instructor_answer_key.7z nor the extracted answer key is present.");
        end

        function docsAndRootFilesExist(tc)
            req = [
                "docs/MathematicalModels.md"
                "docs/QUICKSTART.md"
                "docs/INSTRUCTOR_GUIDE.md"
                "docs/APPROACH_A.md"
                "docs/SHIGLEY_EQUATION_MAP.md"
                "docs/ASSESSMENT_RUBRIC.md"
                "student/ASSIGNMENT_BRIEF.md"
                "student/DESIGN_REPORT_TEMPLATE.md"
                "student/DATA_DICTIONARY.md"
                "tools/buildStudentPackage.m"
                "validation/README.md"
                "validation/run_zero_to_100.m"
                "README.md"
                "Contents.m"
                "CITATION.cff"
                "LICENSE"];
            for f = req'
                tc.verifyTrue(isfile(fullfile(tc.RepoRoot, f)), "missing: " + f);
            end
        end

        function dependencyCheckReportsNoFailures(tc)
            % check_dependencies is the documented first step, so a clean
            % checkout has to come through it with nothing flagged.
            tc.applyFixture(matlab.unittest.fixtures.CurrentFolderFixture( ...
                fullfile(tc.RepoRoot, 'instructor')));
            report = evalc("run('check_dependencies.mlx')");
            tc.verifyFalse(contains(report, '[FAIL]'), report);
            tc.verifyFalse(contains(report, '[WARN]'), report);
            tc.verifyTrue(contains(report, 'ALL CHECKS PASSED'), report);
        end

        function exactlyFourPlainTextTemplatesExist(tc)
            d = dir(fullfile(tc.RepoRoot, 'student', 'Student_*.m'));
            tc.verifyNumElements(d, 4, ...
                'student/ should contain exactly four v2.0 Live Code templates');
        end

    end
end
