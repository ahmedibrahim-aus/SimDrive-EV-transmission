classdef tValidationZeroTo100 < matlab.unittest.TestCase
    %TVALIDATIONZEROTO100 Checks the standalone 0-100 km/h validation script.

    methods (Test, TestTags = {'Integration'})
        function zeroTo100ScriptRuns(testCase)
            repoRoot = fileparts(fileparts(mfilename('fullpath')));
            testCase.applyFixture(matlab.unittest.fixtures.CurrentFolderFixture( ...
                fullfile(repoRoot, 'validation')));

            % Run it here rather than in the base workspace, so a caller's
            % variables survive the test.
            result = tValidationZeroTo100.runScript();

            testCase.verifyGreaterThan(result.Time_s, 5.0);
            testCase.verifyLessThan(result.Time_s, 6.5);
            testCase.verifyEqual(height(result.Summary), 1);
        end
    end

    methods (Static, Access = private)
        function result = runScript()
            makePlots = false; %#ok<NASGU> read by run_zero_to_100.m
            evalc("run('run_zero_to_100.m')");
            result.Time_s = zeroTo100Time_s;
            result.Summary = validationSummary;
        end
    end
end
