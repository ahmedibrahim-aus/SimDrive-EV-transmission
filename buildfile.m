function plan = buildfile
%BUILDFILE Define repeatable checks for the GitHub teaching release.

    import matlab.buildtool.Task
    import matlab.buildtool.tasks.CodeIssuesTask
    import matlab.buildtool.tasks.TestTask

    plan = buildplan;
    coverageFiles = [
        "instructor/SimDriveCore.m"
        "instructor/InstructorApp.m"
        "instructor/PowertrainView3D.m"
        "instructor/generateLoadCases.m"
        "instructor/buildGearTrain.m"
        "instructor/solution/computeShoulderNotchFactors.m"
        "instructor/solution/computeHelicalJ.m"
        "instructor/solution/rateHelicalStage.m"
        "instructor/solution/selectStage2Module.m"
        "instructor/solution/simplySupportedMoment.m"
        "instructor/solution/bearingCatalogue.m"
        "instructor/solution/runAnswerKey.m"
        "instructor/solution/writeAnswerKeyReport.m"
        "instructor/solution/courseTargets.m"
        "tools/buildStudentPackage.m"];
    codeFiles = [coverageFiles
        "instructor/solution/Solution_00_Run_All.m"
        "instructor/solution/Solution_01_Load_Inputs.m"
        "instructor/solution/Solution_02_Gear_Design.m"
        "instructor/solution/Solution_03_Shaft_Design.m"
        "instructor/solution/Solution_04_Bearing_Selection.m"];
    % The answer-key files ship encrypted in instructor_answer_key.7z; check
    % only the ones that have been extracted.
    coverageFiles = coverageFiles(isfile(coverageFiles));
    codeFiles = codeFiles(isfile(codeFiles));

    plan("check") = CodeIssuesTask(codeFiles, ...
        WarningThreshold=0, ...
        Results="artifacts/code-issues.sarif", ...
        Description="Run MATLAB Code Analyzer with zero-warning gate");

    plan("testFast") = TestTask("tests", ...
        Tag="Unit", ...
        SourceFiles=coverageFiles, ...
        TestResults=["artifacts/fast-tests.xml" "artifacts/fast-tests.html"], ...
        CodeCoverageResults="artifacts/fast-coverage.xml", ...
        Description="Run fast unit and teaching-package tests");

    plan("testFull") = TestTask("tests", ...
        SourceFiles=coverageFiles, ...
        TestResults=["artifacts/full-tests.xml" "artifacts/full-tests.html"], ...
        CodeCoverageResults="artifacts/full-coverage.xml", ...
        Description="Run complete simulation and answer-key validation");

    plan("release") = Task( ...
        Description="Run every release gate", ...
        Dependencies=["check" "testFull"]);

    plan.DefaultTasks = ["check" "testFast"];
end
