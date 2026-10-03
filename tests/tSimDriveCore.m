classdef tSimDriveCore < matlab.unittest.TestCase
    %TSIMDRIVECORE  Unit tests for the SimDriveCore static math helpers.
    %   Fast tests (no Simulink) covering FTP-75 loading, plot binning, the
    %   bearing cubic-mean torque, and Approach A fatigue-load reduction.

    properties
        RepoRoot
    end

    methods (TestClassSetup)
        function setupPath(tc)
            tc.RepoRoot = fileparts(fileparts(mfilename('fullpath')));
            instDir = fullfile(tc.RepoRoot, 'instructor');
            addpath(instDir);
            tc.addTeardown(@() rmpath(instDir));
        end
    end

    methods (Test, TestTags = {'Unit'})

        function loadFtpReturnsMonotonicKph(tc)
            % No file: the built-in EPA FTP-75 schedule.
            [t, v] = SimDriveCore.loadFtp75SpeedTrace();
            tc.verifyGreaterThan(numel(t), 100);
            tc.verifySize(v, size(t));
            tc.verifyTrue(all(diff(t) > 0), 'time must be strictly increasing');
            tc.verifyGreaterThanOrEqual(min(v), 0, 'speed must be non-negative');
            tc.verifyLessThan(max(v), 200, 'km/h should be < 200 for FTP-75');
            tc.verifyGreaterThan(max(v), 75, 'the built-in mph schedule must be returned in km/h');
            tc.verifyEqual(max(v), 56.7*1.609344, 'AbsTol', 1e-9);
        end

        function userTraceUnitsAreExplicitOrWarned(tc)
            % A user trace in km/h that never exceeds 75 must not be taken
            % for mph when the units are given, and a guess must be flagged.
            file = [tempname '.txt'];
            tc.addTeardown(@() delete(file));
            writematrix([(0:20)' 60*ones(21, 1)], file);
            [~, v] = SimDriveCore.loadFtp75SpeedTrace(file, "kph");
            tc.verifyEqual(max(v), 60, 'AbsTol', 1e-12);
            [~, v] = SimDriveCore.loadFtp75SpeedTrace(file, "mph");
            tc.verifyEqual(max(v), 60*1.609344, 'AbsTol', 1e-9);
            tc.verifyWarning(@() SimDriveCore.loadFtp75SpeedTrace(file), ...
                'SimDriveCore:FtpUnitsGuessed');
        end

        function userTraceHeaderSetsUnits(tc)
            % A header naming the units decides them without a guess.
            file = [tempname '.csv'];
            tc.addTeardown(@() delete(file));
            writelines(["time_s,speed_kph"; compose("%d,50", (0:20)')], file);
            v = tc.verifyWarningFree(@() speedOf(file));
            tc.verifyEqual(max(v), 50, 'AbsTol', 1e-12);
            writelines(["time_s,speed_kmph"; compose("%d,50", (0:20)')], file);
            tc.verifyEqual(max(speedOf(file)), 50, 'AbsTol', 1e-12);
            writelines(["t [s], v [mph]"; compose("%d,50", (0:20)')], file);
            tc.verifyEqual(max(speedOf(file)), 50*1.609344, 'AbsTol', 1e-9);
        end

        function userTraceIsValidated(tc)
            file = [tempname '.txt'];
            tc.addTeardown(@() delete(file));
            writematrix([(5:25)' 30*ones(21, 1)], file);
            tc.verifyError(@() SimDriveCore.loadFtp75SpeedTrace(file, "kph"), ...
                'SimDriveCore:FtpTimeStart');
            writematrix([(0:20)' [30*ones(20, 1); -1]], file);
            tc.verifyError(@() SimDriveCore.loadFtp75SpeedTrace(file, "kph"), ...
                'SimDriveCore:FtpNegativeSpeed');
            writematrix([(0:5)' zeros(6, 1)], file);
            tc.verifyError(@() SimDriveCore.loadFtp75SpeedTrace(file, "kph"), ...
                'SimDriveCore:FtpFileShape');
        end

        function binAverageReducesAndStaysBounded(tc)
            t = linspace(0, 10, 5000)';  y = sin(t);
            [to, yo] = SimDriveCore.binAverage(t, y, 200);
            tc.verifyLessThanOrEqual(numel(to), 201, 'should downsample to <= maxPoints');
            tc.verifyGreaterThan(numel(to), 10);
            tc.verifyGreaterThanOrEqual(min(yo), -1.01);
            tc.verifyLessThanOrEqual(max(yo),  1.01);
        end

        function binAveragePreservesConstant(tc)
            t = linspace(0, 10, 1000)';  y = 5 * ones(size(t));
            [~, yo] = SimDriveCore.binAverage(t, y, 100);
            tc.verifyEqual(yo, 5 * ones(size(yo)), 'AbsTol', 1e-9);
        end

        function bearingTorqueConstantEqualsLevel(tc)
            % Constant |T| and constant omega -> cubic mean equals T.
            t  = (0:0.01:10)';
            T  = timeseries(100 * ones(size(t)), t);
            om = timeseries( 50 * ones(size(t)), t);
            tc.verifyEqual(SimDriveCore.computeBearingEquivalentTorque(T, om), 100, 'RelTol', 1e-6);
        end

        function bearingTorqueZeroOmegaIsZero(tc)
            t  = (0:0.1:5)';
            T  = timeseries(80 * ones(size(t)), t);
            om = timeseries(zeros(size(t)), t);
            tc.verifyEqual(SimDriveCore.computeBearingEquivalentTorque(T, om), 0);
        end

        function fatigueRecoversSinusoid(tc)
            % A clean sinusoid mean+amp*sin should rainflow-reduce to (mean, amp).
            t  = (0:0.01:200)';
            mn = 120; amp = 60;
            T  = timeseries(mn + amp * sin(2*pi*t/20), t);
            v  = timeseries(50 * ones(size(t)), t);   % moving (> 5 km/h)
            [Tm, Ta, approachData] = SimDriveCore.computeFatigueLoad( ...
                T, v, 5, "approach-a-equivalent-sinusoid", 3);
            tc.verifyEqual(Tm, mn,  'AbsTol', 5,    'equivalent mean torque');
            tc.verifyEqual(Ta, amp, 'RelTol', 0.15, 'equivalent alternating torque');
            tc.verifyEqual(approachData.method_used, ...
                "approach-a-equivalent-sinusoid");
            tc.verifyFalse(approachData.legacy_method_alias_used);
        end

        function smallRippleDoesNotDiluteTheReduction(tc)
            % Controller ripple (here 0.2 N·m at 7 Hz, far below 2 percent of
            % the range) must be gated out, not counted as extra cycles that
            % drag the per-cycle averages down.
            t  = (0:0.01:200)';
            v  = timeseries(50 * ones(size(t)), t);
            clean = 120 + 60 * sin(2*pi*t/20);
            [Tm0, Ta0] = SimDriveCore.computeFatigueLoad(timeseries(clean, t), v, 5);
            [Tm1, Ta1, data] = SimDriveCore.computeFatigueLoad( ...
                timeseries(clean + 0.2*sin(2*pi*7*t), t), v, 5);
            tc.verifyEqual(Ta1, Ta0, 'RelTol', 0.02, 'ripple must not dilute T_alt_eq');
            tc.verifyEqual(Tm1, Tm0, 'AbsTol', 0.5);
            tc.verifyEqual(data.range_gate, 0.02*(max(clean) - min(clean)), 'RelTol', 0.01);
        end

        function fatigueErrorsWhenStationary(tc)
            t = (0:0.01:200)';
            T = timeseries(100 + 10 * sin(t), t);
            v = timeseries(zeros(size(t)), t);        % never moving
            tc.verifyError(@() SimDriveCore.computeFatigueLoad( ...
                T, v, 5, "approach-a-equivalent-sinusoid", 3), ...
                'SimDriveCore:InsufficientFatigueSamples');
        end

        function fatigueRejectsAlternativeMethod(tc)
            t = (0:0.01:20)';
            torque = timeseries(100 + 10*sin(t), t);
            speed = timeseries(50*ones(size(t)), t);

            tc.verifyError(@() SimDriveCore.computeFatigueLoad( ...
                torque, speed, 5, "alternative-b", 3), ...
                'SimDriveCore:ApproachARequired');
        end

        function legacyRainflowNameMapsToApproachA(tc)
            t = (0:0.01:200)';
            torque = timeseries(120 + 60*sin(2*pi*t/20), t);
            speed = timeseries(50*ones(size(t)), t);

            [~, ~, approachData] = SimDriveCore.computeFatigueLoad( ...
                torque, speed, 5, "rainflow", 3);

            tc.verifyEqual(approachData.method_used, ...
                "approach-a-equivalent-sinusoid");
            tc.verifyTrue(approachData.legacy_method_alias_used);
        end

    end
end

function v = speedOf(file)
    [~, v] = SimDriveCore.loadFtp75SpeedTrace(file);
end
