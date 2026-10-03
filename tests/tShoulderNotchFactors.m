classdef tShoulderNotchFactors < matlab.unittest.TestCase
    %TSHOULDERNOTCHFACTORS Tests for shoulder notch factor lookup helper.

    methods (TestClassSetup)
        function addSolutionPath(testCase)
            repoRoot = fileparts(fileparts(mfilename('fullpath')));
            solutionDir = fullfile(repoRoot, 'instructor', 'solution');
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(solutionDir));
        end
    end

    methods (Test, TestTags = {'Unit'})
        function nominalShoulderReturnsFactors(testCase)
            % Read off Shigley 11e Figs. A-15-7, A-15-8 and A-15-9 at the
            % sharpest shoulder the digitized grids carry.
            factors = computeShoulderNotchFactors(1.05, 0.025, 669, 40);

            testCase.verifyEqual(factors.Kt_axial, 2.11, AbsTol=0.05);
            testCase.verifyEqual(factors.Kt_bending, 2.14, AbsTol=0.05);
            testCase.verifyEqual(factors.Kts, 1.52, AbsTol=0.05);
            testCase.verifyGreaterThan(factors.q, 0.70);
            testCase.verifyGreaterThan(factors.qs, factors.q);
            testCase.verifyLessThan(factors.Kf_axial, factors.Kt_axial);
            testCase.verifyLessThan(factors.Kf_bending, factors.Kt_bending);
            testCase.verifyLessThan(factors.Kfs, factors.Kts);
            testCase.verifyEqual(factors.Kfs, ...
                1 + factors.qs*(factors.Kts - 1), AbsTol=1e-12);
            testCase.verifyEqual(factors.Kt, factors.Kt_bending);
            testCase.verifyEqual(factors.Kf, factors.Kf_bending);
            testCase.verifyTrue(contains(factors.ChartSource, "Shigley 11e"));
        end

        function vectorInputsInterpolateMonotonically(testCase)
            factors = computeShoulderNotchFactors([1.05; 1.10], [0.025; 0.025], 669, 40);

            testCase.verifyEqual(height(factors), 2);
            testCase.verifyTrue(all(ismember(["Kt_axial","Kt_bending","Kf_axial","Kf_bending","qs"], ...
                string(factors.Properties.VariableNames))));
            testCase.verifyGreaterThan(factors.Kt_axial(2), factors.Kt_axial(1));
            testCase.verifyGreaterThan(factors.Kt_bending(2), factors.Kt_bending(1));
            testCase.verifyGreaterThan(factors.Kts(2), factors.Kts(1));
        end

        function impossibleFilletErrors(testCase)
            testCase.verifyError(@() computeShoulderNotchFactors(1.05, 0.04, 669, 40), ...
                'EVGearbox:ShoulderNotch:InvalidGeometry');
        end

        function outsideDigitizedRangeErrors(testCase)
            testCase.verifyError(@() computeShoulderNotchFactors(1.50, 0.11, 669, 40), ...
                'EVGearbox:ShoulderNotch:OutsideChartRange');
            testCase.verifyError(@() computeShoulderNotchFactors(1.50, 0.020, 669, 40), ...
                'EVGearbox:ShoulderNotch:OutsideChartRange');
        end

        function outsideEq635StrengthRangeErrors(testCase)
            % The helper keeps to the 415 to 1400 MPa that Figs. 6-26 and 6-27
            % plot; above about 1700 MPa the cubic fits return q > 1.
            testCase.verifyError(@() computeShoulderNotchFactors(1.10, 0.025, 1800, 40), ...
                'EVGearbox:ShoulderNotch:OutsideStrengthRange');
            testCase.verifyError(@() computeShoulderNotchFactors(1.10, 0.025, 300, 40), ...
                'EVGearbox:ShoulderNotch:OutsideStrengthRange');
        end

        function exactlyFilledShoulderIsAccepted(testCase)
            % r/d = (D/d - 1)/2 is a geometrically exact shoulder and must
            % not be rejected by floating-point round-off.
            factors = computeShoulderNotchFactors(1.20, 0.100, 669, 40);

            testCase.verifyEqual(height(factors), 1);
            testCase.verifyGreaterThan(factors.Kt_bending, 1);
        end
    end
end
