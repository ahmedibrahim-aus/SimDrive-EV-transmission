classdef tInstructorWorkflow < matlab.uitest.TestCase
    %TINSTRUCTORWORKFLOW Dashboard callbacks, Run/Export gestures and hand-out checks.
    properties
        App
        Figure
        OutputRoot
        RepoRoot
    end

    methods (TestClassSetup)
        function needsDisplay(testCase)
            % Gestures and exportapp need a display; a headless Linux runner
            % without one (no Xvfb) skips these tests instead of failing.
            testCase.assumeFalse(isunix && ~ismac && isempty(getenv('DISPLAY')), ...
                'The dashboard tests need a display (use Xvfb on headless Linux).');
        end
    end

    methods (TestMethodSetup)
        function launch(testCase)
            testCase.RepoRoot = fileparts(fileparts(mfilename('fullpath')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(testCase.RepoRoot, 'instructor')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(testCase.RepoRoot, 'tools')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(testCase.RepoRoot, 'tests', 'helpers')));
            folder = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            testCase.OutputRoot = folder.Folder;
            testCase.applyFixture(matlab.unittest.fixtures.CurrentFolderFixture(testCase.OutputRoot));
            testCase.App = InstructorApp(OutputRoot=string(testCase.OutputRoot));
            testCase.addTeardown(@() delete(testCase.App));
            testCase.Figure = findall(groot, 'Type', 'figure', ...
                'Name', 'SimDrive: EV Transmission Design');
            testCase.assertNumElements(testCase.Figure, 1);
            drawnow;
            resizeFigureAndWait(testCase.Figure, [1366 768]);
        end
    end

    methods (Test, TestTags = {'Integration', 'GUI'})
        function editedControlsCannotChangeCompletedRunExport(testCase)
            runButton = findobj(testCase.Figure, 'Tag', 'RunLoadCases');
            exportButton = findobj(testCase.Figure, 'Tag', 'ExportStudentFiles');
            ratio = findobj(testCase.Figure, 'Tag', 'GearRatio');
            n4 = findobj(testCase.Figure, 'Tag', 'N4');
            testCase.press(runButton);
            testCase.assertEqual(exportButton.Enable, matlab.lang.OnOffSwitchState.on);
            testCase.verifyPlotContrast();
            fprintf('GUI E2E: all three simulations complete; editing the stage-2 gear.\n');
            % Set the public control and dispatch its change callback. This
            % avoids browser typing timeouts in non-desktop MATLAB runners.
            n4.Value = 66;
            n4.ValueChangedFcn(n4, []);
            testCase.verifyEqual(ratio.Value, 9.9, 'G is computed from the tooth counts.', ...
                AbsTol=1e-12);
            testCase.press(exportButton);
            drawnow;

            summary = load(fullfile(testCase.OutputRoot, 'exports_design_ready', 'Design_Summary.mat'));
            testCase.verifyEqual(summary.gear_ratio, 9, 'Export must use the train that was run, not the edited controls.', ...
                AbsTol=1e-12);
            testCase.verifyEqual([summary.N1 summary.N2 summary.N3 summary.N4], [20 60 20 60]);
            testCase.verifyEqual(summary.i1*summary.i2, summary.gear_ratio, AbsTol=1e-12);
            testCase.verifyEqual(summary.d2/summary.d1, 3, AbsTol=1e-12);
            testCase.verifyFalse(isfield(summary, 'N_g'), 'No single-stage fields remain.');
            testCase.verifyTrue(ismember(1000*summary.m_n2, [1 1.25 1.5 2 2.5 3 4 5 6 8 10 12 16 20]), ...
                'The key sets a preferred stage-2 module.');
            keyFile = fullfile(testCase.OutputRoot, 'exports_design_ready', 'Answer_Key.md');
            keyTable = findobj(testCase.Figure, 'Tag', 'AnswerKeyTable');
            if isfile(fullfile(testCase.RepoRoot, 'instructor', 'solution', 'runAnswerKey.m'))
                testCase.verifyTrue(isfile(keyFile), 'Export must write the answer key.');
                testCase.verifyFalse(any(strcmp(keyTable.Data(:,5), 'FAIL')), 'Answer key misses a target.');
                testCase.verifyGreaterThan(size(keyTable.Data, 1), 20);
            else
                testCase.verifyFalse(isfile(keyFile), 'A locked key must not write Answer_Key.md.');
                testCase.verifyEqual(keyTable.Data{1,1}, 'ANSWER KEY LOCKED');
            end
            testCase.verifyNumElements(summary.ds, 3);
            ftp = load(fullfile(testCase.OutputRoot, 'exports_design_ready', 'FTP75_Outputs.mat'));
            idx = strcmp({summary.ds.case_name}, 'FTP75');
            testCase.verifyEqual(ftp.ds_single, summary.ds(idx));
            testCase.verifyGreaterThan(ftp.ds_single.T_mean_eq, 7.5);
            testCase.verifyLessThan(ftp.ds_single.T_mean_eq, 10);
            testCase.verifyGreaterThan(ftp.ds_single.T_alt_eq, 45);
            testCase.verifyLessThan(ftp.ds_single.T_alt_eq, 50);
            testCase.verifyTrue(all(isfinite(ftp.Tin_applied.Data(:))));
            testCase.verifyTrue(isfile(fullfile(testCase.OutputRoot, 'exports_design_ready', 'Overview_AllCases.png')));
            archive = fullfile(testCase.OutputRoot, 'release', 'EV_Gearbox_Student_Package_v4.0.0.zip');
            testCase.assertTrue(isfile(archive), 'GUI must build a fresh ZIP from this run.');
            unpacked = fullfile(testCase.OutputRoot, 'unpacked');
            unzip(archive, unpacked);
            handout = fullfile(unpacked, 'EV_Gearbox_Student_Package_v4.0.0');
            packagedSummary = load(fullfile(handout, 'exports_design_ready', 'Design_Summary.mat'));
            packagedFtp = load(fullfile(handout, 'exports_design_ready', 'FTP75_Outputs.mat'));
            % Students get the documented vehicle and train data only; the
            % per-case summary ds (with output-shaft torques) stays behind.
            testCase.verifyFalse(isfield(packagedSummary, 'ds'));
            for f = string(fieldnames(packagedSummary))'
                testCase.verifyEqual(packagedSummary.(f), summary.(f));
            end
            testCase.verifyTrue(all(isfield(packagedSummary, {'gear_ratio', 'omega_max', 'v_top', 'theta_hill_deg'})));
            testCase.verifyEqual(packagedFtp.ds_single, ftp.ds_single);
            testCase.verifyLessThanOrEqual(numel(packagedFtp.torque_Nm.Time), 2000);
            testCase.verifyFalse(isfolder(fullfile(handout, 'instructor')));
            testCase.verifyPackagedCases(handout, summary);
            fprintf('GUI E2E: all three exported cases and ZIP contents verified.\n');
            testCase.dismissDialog('uialert', testCase.Figure);

            % Then run only Drag Race. Old case files must not be packaged.
            ftpBox = findobj(testCase.Figure, 'Type', 'uicheckbox', 'Text', 'FTP-75  (fatigue and bearing life)');
            hillBox = findobj(testCase.Figure, 'Type', 'uicheckbox', 'Text', 'Hill Climb  (validation check; shaft life extension)');
            ftpBox.Value = false;
            hillBox.Value = false;
            testCase.press(runButton);
            testCase.press(exportButton);
            partial = load(fullfile(testCase.OutputRoot, 'exports_design_ready', 'Design_Summary.mat'));
            testCase.verifyNumElements(partial.ds, 1);
            testCase.verifyEqual(partial.gear_ratio, 9.9, AbsTol=1e-12);
            testCase.verifyEqual(partial.N4, 66);
            testCase.verifyError(@() buildStudentPackage( ...
                DatasetDirectory=string(fullfile(testCase.OutputRoot, 'exports_design_ready')), ...
                PackageDirectory=string(fullfile(testCase.OutputRoot, 'student_package')), ...
                OutputFile=string(archive)), 'EVGearbox:StudentPackage:IncompleteRun');
            testCase.dismissDialog('uialert', testCase.Figure);
        end

        function invalidGearTrainBlocksTheRun(testCase)
            runButton = findobj(testCase.Figure, 'Tag', 'RunLoadCases');
            message = findobj(testCase.Figure, 'Tag', 'GearTrainMessage');
            n3 = findobj(testCase.Figure, 'Tag', 'N3');
            n3.Value = 10;               % below the printed Fig. 14-7 domain
            n3.ValueChangedFcn(n3, []);
            testCase.verifyEqual(runButton.Enable, matlab.lang.OnOffSwitchState.off);
            testCase.verifyTrue(contains(message.Text, "20 to 500 teeth"), message.Text);
            n3.Value = 20;
            n3.ValueChangedFcn(n3, []);
            testCase.verifyEqual(runButton.Enable, matlab.lang.OnOffSwitchState.on);

            auto = findobj(testCase.Figure, 'Tag', 'ModuleStage2Auto');
            module2 = findobj(testCase.Figure, 'Tag', 'ModuleStage2');
            auto.Value = false;
            auto.ValueChangedFcn(auto, []);
            module2.Value = 4.5;         % not a Table 13-2 preferred module
            module2.ValueChangedFcn(module2, []);
            testCase.verifyEqual(runButton.Enable, matlab.lang.OnOffSwitchState.off);
            testCase.verifyTrue(contains(message.Text, "Table 13-2"), message.Text);
        end

        function resizingDoesNotDoubleScaleNestedControls(testCase)
            resizeFigureAndWait(testCase.Figure, [1920 1040]);
            label = findobj(testCase.Figure, 'Type', 'uilabel', 'Text', 'T_mean_eq');
            testCase.verifyEqual(label.Position, [18 62 304 18], AbsTol=1.1);
            original = label.Position;
            resizeFigureAndWait(testCase.Figure, [1366 768]);
            testCase.verifyEqual(label.Position, original .* [1366/1920 768/1040 1366/1920 768/1040], AbsTol=1.1);
            testCase.verifyGreaterThanOrEqual(label.Position(2), 0);
            testCase.verifyLessThanOrEqual(label.Position(2)+label.Position(4), label.Parent.Position(4));
            artifacts = fullfile(testCase.RepoRoot, 'artifacts');   % made by buildtool; not on a fresh clone
            if ~isfolder(artifacts), mkdir(artifacts); end
            exportapp(testCase.Figure, fullfile(testCase.RepoRoot, 'artifacts', 'dashboard-fixed-1366.png'));
            laptopImage = imfinfo(fullfile(testCase.RepoRoot, 'artifacts', 'dashboard-fixed-1366.png'));
            testCase.verifyEqual([laptopImage.Width laptopImage.Height], [1366 768]);
            resizeFigureAndWait(testCase.Figure, [1920 1040]);
            testCase.verifyEqual(label.Position, original, AbsTol=1.1);
            exportapp(testCase.Figure, fullfile(testCase.RepoRoot, 'artifacts', 'dashboard-fixed-1920.png'));
            desktopImage = imfinfo(fullfile(testCase.RepoRoot, 'artifacts', 'dashboard-fixed-1920.png'));
            testCase.verifyEqual([desktopImage.Width desktopImage.Height], [1920 1040]);
        end
    end

    methods (Access = private)
        function verifyPackagedCases(testCase, handout, summary)
            for name = ["FTP75" "HillClimb" "DragRace"]
                fileName = name + "_Outputs.mat";
                exported = load(fullfile(testCase.OutputRoot, 'exports_design_ready', fileName));
                packaged = load(fullfile(handout, 'exports_design_ready', fileName));
                folderCase = load(fullfile(testCase.OutputRoot, 'student_package', 'exports_design_ready', fileName));
                expected = summary.ds(string({summary.ds.case_name}) == name);
                testCase.verifyEqual(exported.ds_single, expected);
                testCase.verifyEqual(packaged.ds_single, expected);
                testCase.verifyEqual(folderCase.ds_single, expected);
                trace = exported.Tin_applied;
                if name == "FTP75"
                    trace = exported.T_equiv_sin_out;
                end
                keep = round(linspace(1, numel(trace.Time), min(2000, numel(trace.Time))));
                testCase.verifyEqual(packaged.torque_Nm.Data, trace.Data(keep), AbsTol=1e-10);
                testCase.verifyEqual(packaged.torque_Nm.Time, trace.Time(keep), AbsTol=1e-10);
                testCase.verifyEqual(folderCase.torque_Nm.Data, packaged.torque_Nm.Data, AbsTol=1e-10);
                testCase.verifyTrue(all(isfinite(exported.Tin_applied.Data(:))));
                testCase.verifyGreaterThanOrEqual(min(exported.v_sim_kph_out.Data(:)), -1e-8);
                testCase.verifyLessThanOrEqual(max(exported.Tin_applied.Data(:)), summary.Tmax + 1e-6);
                png = imread(fullfile(handout, 'exports_design_ready', name + '_Plot.png'));
                testCase.verifyGreaterThan(numel(png), 1000);
                % Printed charts must keep dark text on a white background.
                testCase.verifyEqual(png(1, 1, 1:3), uint8(reshape([255 255 255], 1, 1, 3)));
                lowerMargin = png(end-35:end, :, 1:3);
                testCase.verifyGreaterThan(nnz(all(lowerMargin < 100, 3)), 10, ...
                    'Exported time-axis text must not be pale on white.');
            end
        end

        function verifyPlotContrast(testCase)
            axesList = findall(testCase.Figure, 'Type', 'axes');
            labeledCount = 0;
            for ax = axesList(:)'
                if isempty(ax.XLabel.String), continue; end
                labeledCount = labeledCount + 1;
                testCase.verifyGreaterThanOrEqual( ...
                    testCase.contrast(ax.XLabel.Color, ax.Color), 4.5);
                testCase.verifyGreaterThanOrEqual( ...
                    testCase.contrast(ax.Title.Color, ax.Color), 4.5);
                for ruler = ax.YAxis(:)'
                    testCase.verifyGreaterThanOrEqual( ...
                        testCase.contrast(ruler.Color, ax.Color), 4.5);
                    testCase.verifyGreaterThanOrEqual( ...
                        testCase.contrast(ruler.Label.Color, ax.Color), 4.5);
                end
                testCase.verifyGreaterThanOrEqual( ...
                    testCase.contrast(ax.Legend.TextColor, ax.Legend.Color), 4.5);
            end
            testCase.verifyEqual(labeledCount, 4, ...
                'Check the motor envelope and all three result plots.');
        end

        function ratio = contrast(~, foreground, background)
            rgb = [foreground; background];
            linear = rgb / 12.92;
            nonlinear = rgb > 0.04045;
            linear(nonlinear) = ((rgb(nonlinear) + 0.055) / 1.055).^2.4;
            luminance = linear * [0.2126; 0.7152; 0.0722];
            ratio = (max(luminance) + 0.05) / (min(luminance) + 0.05);
        end

    end
end
