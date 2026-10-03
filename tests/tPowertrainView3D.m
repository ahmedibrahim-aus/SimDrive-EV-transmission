classdef tPowertrainView3D < matlab.unittest.TestCase
    %TPOWERTRAINVIEW3D Checks for the cutaway 3D view of the two-stage drive unit.

    properties
        Figure
        View
    end

    methods (TestClassSetup)
        function addInstructorToPath(testCase)
            repoRoot = fileparts(fileparts(mfilename('fullpath')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(repoRoot, 'instructor')));
        end
    end

    methods (TestMethodSetup)
        function buildView(testCase)
            testCase.Figure = figure('Visible', 'off');
            testCase.addTeardown(@() close(testCase.Figure));
            testCase.View = PowertrainView3D(axes(testCase.Figure));
        end
    end

    methods (Test, TestTags = {'Unit'})

        function shaftsTurnAtTheirStageRatios(testCase)
            % The visible reductions must be the design reductions: the
            % intermediate shaft turns i2 times the output gear and the input
            % pinion turns G times it.
            t = 0.02;   % small enough that no angle wraps past pi
            testCase.View.step(t, 'running');
            train = testCase.View.Train;
            gear = yRotation(testCase, 'GearTform');
            intermediate = yRotation(testCase, 'IntermediateTform');
            pinion = yRotation(testCase, 'PinionTform');

            testCase.verifyEqual(train.G, 9, 'The course train is 20:60 x 20:60 = 9.', ...
                AbsTol=1e-12);
            testCase.verifyEqual(abs(intermediate/gear), train.stage(2).ratio, RelTol=1e-9);
            testCase.verifyEqual(abs(pinion/gear), train.G, RelTol=1e-9);
            testCase.verifyLessThan(intermediate*gear, 0, ...
                'Stage-2 meshing shafts must turn in opposite directions.');
            testCase.verifyLessThan(pinion*intermediate, 0, ...
                'Stage-1 meshing shafts must turn in opposite directions.');
        end

        function rotorStaysLockedToThePinion(testCase)
            testCase.View.step(0.02, 'running');
            testCase.verifyEqual(yRotation(testCase, 'RotorTform'), ...
                yRotation(testCase, 'PinionTform'), 'RelTol', 1e-9, ...
                'The motor rotor shares the input shaft with the pinion.');
        end

        function idleTurnsSlowerThanRunning(testCase)
            testCase.View.step(0.02, 'idle');
            idleAngle = abs(yRotation(testCase, 'GearTform'));
            testCase.View.step(0.02, 'running');
            runAngle = abs(yRotation(testCase, 'GearTform'));
            testCase.verifyLessThan(idleAngle, runAngle);
        end

        function outputGearClearsTheRoadAtTrueScale(testCase)
            % The view draws the gears at true scale from the train, so the
            % train's output gear tip circle, centered on the axle, is what
            % must stay above the road. This checks the train it draws.
            axleHeightMm = 334;
            s2 = testCase.View.Train.stage(2);
            tipRadiusMm = 1000*(s2.d_gear/2 + s2.m_n);
            testCase.verifyLessThan(tipRadiusMm, axleHeightMm, ...
                'Drawn output gear must clear the road surface.');
        end

        function setTrainRedrawsForANewTrain(testCase)
            train = buildGearTrain(N1=24, N2=66, m_n2_mm=8);
            testCase.View.setTrain(train);
            testCase.verifyEqual(testCase.View.Train.summary, train.summary);
            testCase.View.step(0.02, 'running');
            testCase.verifyEqual(abs(yRotation(testCase, 'PinionTform') / ...
                yRotation(testCase, 'GearTform')), train.G, RelTol=1e-9);
        end

        function enlargedDriveUnitStaysSynchronized(testCase)
            detailAxes = axes(testCase.Figure);
            view = PowertrainView3D(testCase.View.Axes, DetailAxes=detailAxes);
            testCase.verifyNumElements(view.DetailTforms, 4);
            view.step(0.05, 'running');
            originals = [view.PinionTform view.GearTform view.RotorTform view.IntermediateTform];
            for k = 1:4
                testCase.verifyEqual(view.DetailTforms(k).Matrix, originals(k).Matrix);
            end
            view.step(0.15, 'idle');
            for k = 1:4
                testCase.verifyEqual(view.DetailTforms(k).Matrix, originals(k).Matrix);
            end
        end

    end

    methods (Access = private)
        function angle = yRotation(testCase, tformName)
            m = testCase.View.(tformName).Matrix; %#ok<*PROPLC>
            angle = atan2(m(1,3), m(1,1));
        end
    end
end
