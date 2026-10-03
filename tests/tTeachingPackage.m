classdef tTeachingPackage < matlab.unittest.TestCase
    %TTEACHINGPACKAGE Student-only archive and documentation checks.

    properties
        RepoRoot
    end

    methods (TestClassSetup)
        function setupPath(testCase)
            testCase.RepoRoot = fileparts(fileparts(mfilename('fullpath')));
            toolsDirectory = fullfile(testCase.RepoRoot, 'tools');
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(toolsDirectory));
        end
    end

    methods (Test, TestTags = {'Unit'})
        function packageContainsStudentFilesOnly(testCase)
            built = testCase.buildPackage();

            testCase.verifyTrue(any(contains(built.Entries, ...
                'Student_03_Shaft_Design.m')));
            testCase.verifyTrue(any(contains(built.Entries, ...
                'ASSIGNMENT_BRIEF.md')));
            testCase.verifyTrue(any(contains(built.Entries, ...
                'EV_Gearbox_Project_Brief.docx')));
            testCase.verifyFalse(any(contains(built.Entries, ...
                'instructor/solution', IgnoreCase=true)));
            testCase.verifyFalse(any(endsWith(built.Entries, '.mlx')));
        end

        function packagedFtpCaseCarriesTheTorqueCurve(testCase)
            built = testCase.buildPackage();
            ftpFile = built.Entries(endsWith(built.Entries, 'FTP75_Outputs.mat'));
            testCase.assertNumElements(ftpFile, 1);

            packaged = load(ftpFile);
            testCase.verifyTrue(isfield(packaged, 'torque_Nm'), ...
                'FTP75_Outputs.mat has no torque_Nm curve');
            testCase.verifyTrue(isfield(packaged, 'torque_note'));
            testCase.verifyTrue(isfield(packaged, 'ds_single'));
            testCase.verifyLessThanOrEqual(numel(packaged.torque_Nm.Time), 2000);
            testCase.verifyEqual(packaged.ds_single.T_mean_eq, 9.15);
            % The note quotes the curve's own mean (the stub curve is 1, 2, 3).
            testCase.verifyTrue(contains(packaged.torque_note, "is 2.0 N·m"), packaged.torque_note);
        end

        function packagedSummaryOmitsInstructorFields(testCase)
            built = testCase.buildPackage();
            summaryFile = built.Entries(endsWith(built.Entries, 'Design_Summary.mat'));
            testCase.assertNumElements(summaryFile, 1);
            packaged = load(summaryFile);
            testCase.verifyEqual(string(fieldnames(packaged)), "gear_ratio");
        end

        function handOutFolderMatchesTheArchive(testCase)
            % The folder and the ZIP are the same hand-out, so a student who
            % gets one cannot be working from different files than a student
            % who gets the other.
            built = testCase.buildPackage();
            archived = sort(extractAfter(built.Entries, built.ArchiveRoot));

            folderContents = dir(fullfile(built.PackageDirectory, '**', '*'));
            folderContents = folderContents(~[folderContents.isdir]);
            stored = strings(numel(folderContents), 1);
            for k = 1:numel(folderContents)
                stored(k) = extractAfter(fullfile(folderContents(k).folder, ...
                    folderContents(k).name), built.PackageDirectory + filesep);
            end

            testCase.verifyEqual(archived(:), sort(stored));
        end

        function equationMapContainsAllFiveShigleyFigures(testCase)
            equationMap = fileread(fullfile(testCase.RepoRoot, ...
                'docs', 'SHIGLEY_EQUATION_MAP.md'));

            testCase.verifyTrue(all(contains(string(equationMap), ...
                ["A-15-7" "A-15-8" "A-15-9" "6-26" "6-27"])));
        end

        function rebuildingUsesOnlyFreshDataset(testCase)
            built = testCase.buildPackage();
            source = load(fullfile(built.DatasetDirectory, 'FTP75_Outputs.mat'));
            source.ds_single.T_mean_eq = 175;
            save(fullfile(built.DatasetDirectory, 'FTP75_Outputs.mat'), '-struct', 'source');
            summary = load(fullfile(built.DatasetDirectory, 'Design_Summary.mat'));
            summary.ds(1) = source.ds_single;
            save(fullfile(built.DatasetDirectory, 'Design_Summary.mat'), '-struct', 'summary');
            buildStudentPackage(DatasetDirectory=built.DatasetDirectory, ...
                PackageDirectory=built.PackageDirectory, OutputFile=built.PackageFile);
            unzip(built.PackageFile, built.UnzipDirectory);
            folderCase = load(fullfile(built.PackageDirectory, 'exports_design_ready', 'FTP75_Outputs.mat'));
            zippedCase = load(fullfile(built.ArchiveRoot, 'exports_design_ready', 'FTP75_Outputs.mat'));
            testCase.verifyEqual(folderCase.ds_single.T_mean_eq, 175, AbsTol=1e-12);
            testCase.verifyEqual(zippedCase.ds_single, folderCase.ds_single);
        end

        function rejectsSourceAndDatasetDestinations(testCase)
            built = testCase.buildPackage();
            testCase.verifyError(@() buildStudentPackage(PackageDirectory=testCase.RepoRoot), ...
                'EVGearbox:StudentPackage:UnsafeDestination');
            testCase.verifyError(@() buildStudentPackage(DatasetDirectory=built.DatasetDirectory, ...
                PackageDirectory=built.DatasetDirectory, OutputFile=built.PackageFile), ...
                'EVGearbox:StudentPackage:UnsafeDestination');
        end

        function preservesUnrelatedFiles(testCase)
            built = testCase.buildPackage();
            noteFile = fullfile(built.PackageDirectory, 'my-notes.mat');
            important = 42;
            save(noteFile, 'important');
            testCase.verifyError(@() buildStudentPackage(DatasetDirectory=built.DatasetDirectory, ...
                PackageDirectory=built.PackageDirectory, OutputFile=built.PackageFile), ...
                'EVGearbox:StudentPackage:UnrelatedContent');
            preserved = load(noteFile);
            testCase.verifyEqual(preserved.important, 42, AbsTol=1e-12);
        end

        function rejectsPartialRunDespiteOldCaseFiles(testCase)
            built = testCase.buildPackage();
            summary = load(fullfile(built.DatasetDirectory, 'Design_Summary.mat'));
            summary.ds = summary.ds(3);
            save(fullfile(built.DatasetDirectory, 'Design_Summary.mat'), '-struct', 'summary');
            testCase.verifyError(@() buildStudentPackage(DatasetDirectory=built.DatasetDirectory, ...
                PackageDirectory=built.PackageDirectory, OutputFile=built.PackageFile), ...
                'EVGearbox:StudentPackage:IncompleteRun');
        end

        function rejectsMixedRunScalars(testCase)
            built = testCase.buildPackage();
            source = load(fullfile(built.DatasetDirectory, 'FTP75_Outputs.mat'));
            source.ds_single.T_mean_eq = 1;
            save(fullfile(built.DatasetDirectory, 'FTP75_Outputs.mat'), '-struct', 'source');
            testCase.verifyError(@() buildStudentPackage(DatasetDirectory=built.DatasetDirectory, ...
                PackageDirectory=built.PackageDirectory, OutputFile=built.PackageFile), ...
                'EVGearbox:StudentPackage:InconsistentRun');
        end

        function acceptsDerivedSummaryFields(testCase)
            built = testCase.buildPackage();
            summary = load(fullfile(built.DatasetDirectory, 'Design_Summary.mat'));
            summary.ds(1).T_mean_eq_out = 9.15 * 9 * 0.97;
            save(fullfile(built.DatasetDirectory, 'Design_Summary.mat'), '-struct', 'summary');
            testCase.verifyWarningFree(@() buildStudentPackage(DatasetDirectory=built.DatasetDirectory, ...
                PackageDirectory=built.PackageDirectory, OutputFile=built.PackageFile));
        end
    end

    methods (Access = private)
        function built = buildPackage(testCase)
            temporaryRoot = string(tempname);
            mkdir(temporaryRoot);
            testCase.addTeardown(@() rmdir(temporaryRoot, 's'));

            datasetDirectory = fullfile(temporaryRoot, 'exports_design_ready');
            testCase.writeStubInstructorExport(datasetDirectory);
            built.DatasetDirectory = datasetDirectory;

            built.PackageDirectory = fullfile(temporaryRoot, 'student_package');
            packageFile = fullfile(temporaryRoot, 'student-package.zip');
            built.PackageFile = packageFile;
            buildStudentPackage(DatasetDirectory=datasetDirectory, ...
                PackageDirectory=built.PackageDirectory, ...
                OutputFile=packageFile);

            unzipDirectory = fullfile(temporaryRoot, 'unzipped');
            built.UnzipDirectory = unzipDirectory;
            built.Entries = string(unzip(packageFile, unzipDirectory));
            built.ArchiveRoot = fullfile(unzipDirectory, ...
                "EV_Gearbox_Student_Package_v4.0.0") + filesep;
        end

        function writeStubInstructorExport(~, datasetDirectory)
            % A miniature stand-in for exports_design_ready: same variable
            % names and shapes as the real export, three samples per case.
            mkdir(datasetDirectory);
            time = (0:2)';
            designValues = struct('case_name', "FTP75", 'T_mean_eq', 9.15, ...
                'T_alt_eq', 46.27, 'T_cubic_mean', 44.05, 'T_peak', 350);

            stub.T_equiv_sin_out = timeseries([1; 2; 3], time);
            stub.Tin_applied = timeseries([4; 5; 6], time);
            ds = repmat(designValues, 1, 3);
            names = ["FTP75" "HillClimb" "DragRace"];
            for k = 1:3
                caseFile = names(k) + "_Outputs.mat";
                ds(k).case_name = names(k);
                stub.ds_single = ds(k);
                save(fullfile(datasetDirectory, caseFile), '-struct', 'stub');
            end

            gear_ratio = 9;
            save(fullfile(datasetDirectory, 'Design_Summary.mat'), 'gear_ratio', 'ds');

            for plotName = ["FTP75_Plot.png" "HillClimb_Plot.png" ...
                    "DragRace_Plot.png" "Overview_AllCases.png"]
                imwrite(zeros(2, 2, 'uint8'), fullfile(datasetDirectory, plotName));
            end
        end
    end
end
