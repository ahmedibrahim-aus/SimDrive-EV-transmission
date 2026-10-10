classdef PowertrainView3D < handle
    %POWERTRAINVIEW3D Cutaway 3D view of the EV powertrain for the dashboard.
    %   view = POWERTRAINVIEW3D(ax) builds a translucent passenger-car body
    %   with the rear drive unit visible inside it: a motor and a separate
    %   single-speed, two-stage transmission. The input pinion drives the
    %   stage-1 gear on the intermediate shaft, the stage-2 pinion on the same
    %   shaft drives the output gear, and the output gear carries the
    %   differential on the rear axle. STEP advances the idle or running
    %   animation: the wheels and all three shafts turn at their true
    %   relative rates, so both reductions are visible on screen.
    %
    %   POWERTRAINVIEW3D(ax, Train=train) draws a buildGearTrain train; the
    %   default is the course train. Gears are drawn to true scale.
    %   SETTRAIN(view, train) redraws for a new train.
    %   POWERTRAINVIEW3D(ax, DetailAxes=detailAx) adds an enlarged drive-unit
    %   view with synchronized animation. Both axes are owned by the caller.
    %
    %   See also INSTRUCTORAPP, BUILDGEARTRAIN.

    properties (SetAccess = private)
        Axes
        Train
        % Exposed so the moving parts can be inspected and tested.
        WheelTforms = gobjects(1,4)
        PinionTform = gobjects(1)          % stage-1 pinion, input shaft
        IntermediateTform = gobjects(1)    % stage-1 gear and stage-2 pinion
        GearTform   = gobjects(1)          % stage-2 gear, output shaft
        RotorTform  = gobjects(1)
        DetailTforms = gobjects(0)
    end

    properties (Access = private)
        DetailAxes = []
        WheelCenters = zeros(4,3)
        PinionCenter = zeros(1,3)
        IntermediateCenter = zeros(1,3)
        GearCenter   = zeros(1,3)
        RotorCenter  = zeros(1,3)
        FlowDots     = gobjects(1)
        FlowPath     = zeros(0,3)
        FlowLength   = 0
    end

    methods
        function view = PowertrainView3D(ax, options)
            arguments
                ax (1,1) matlab.graphics.axis.Axes
                options.DetailAxes = []
                options.Train (1,1) struct = buildGearTrain()
            end
            view.Axes = ax;
            view.DetailAxes = options.DetailAxes;
            view.Train = options.Train;
            view.build(options.DetailAxes);
        end

        function setTrain(view, train)
            %SETTRAIN Redraw the drive unit for another gear train.
            if isequal(train.summary, view.Train.summary); return; end
            view.Train = train;
            view.build(view.DetailAxes);
        end

        function step(view, t, mode)
            %STEP Advance the animation. MODE is "idle" or "running".
            if ~isvalid(view.Axes); return; end
            running = strcmp(mode, 'running');

            % Wheel rate sets everything else: the intermediate shaft turns
            % i2 times faster than the wheel and the input shaft G times.
            % Meshing shafts turn in opposite directions.
            omegaWheel = 4.5 * running + 0.35 * ~running;
            omegaInt   = omegaWheel * view.Train.stage(2).ratio;
            omegaIn    = omegaWheel * view.Train.G;

            for k = 1:numel(view.WheelTforms)
                spin(view.WheelTforms(k), view.WheelCenters(k,:), -omegaWheel*t);
            end
            spin(view.GearTform,         view.GearCenter,         -omegaWheel*t);
            spin(view.IntermediateTform, view.IntermediateCenter,  omegaInt*t);
            spin(view.PinionTform,       view.PinionCenter,       -omegaIn*t);
            spin(view.RotorTform,        view.RotorCenter,        -omegaIn*t);
            if numel(view.DetailTforms) == 4 && all(isgraphics(view.DetailTforms))
                view.DetailTforms(1).Matrix = view.PinionTform.Matrix;
                view.DetailTforms(2).Matrix = view.GearTform.Matrix;
                view.DetailTforms(3).Matrix = view.RotorTform.Matrix;
                view.DetailTforms(4).Matrix = view.IntermediateTform.Matrix;
            end

            if isgraphics(view.FlowDots)
                if running
                    n = 8;
                    s = mod((0:n-1)/n + t/1.9, 1) * view.FlowLength;
                    p = interp1(cumulative(view.FlowPath), view.FlowPath, s);
                    set(view.FlowDots, 'XData', p(:,1), 'YData', p(:,2), ...
                        'ZData', p(:,3), 'Visible', 'on');
                else
                    view.FlowDots.Visible = 'off';
                end
            end
        end
    end

    methods (Access = private)
        function build(view, detailAxes)
            ax = view.Axes;
            cla(ax, 'reset');
            ax.Toolbar.Visible = 'off';   % 'reset' brings the axes toolbar back
            hold(ax, 'on');
            axis(ax, 'off');
            axis(ax, 'vis3d');
            daspect(ax, [1 1 1]);
            ax.Color = 'none';
            ax.Clipping = 'off';

            cCage  = [0.66 0.75 0.84];
            cGlass = [0.40 0.51 0.63];
            cMotor = [0.24 0.78 0.96];
            cAmber = [0.98 0.69 0.32];
            cSteel = [0.80 0.84 0.90];
            cBatt  = [0.20 0.58 0.60];

            unitMm = 438.7;                 % model units per mm of a 4.7 m car
            zGround = 0.38;
            zFloor  = 0.76;   % rocker line, so the pack and drive unit sit inside
            bodyWidth = 4.21;
            xNose = 0.80; xTail = 11.30;
            xFront = 2.60; xRear = 9.14; zAxle = 1.12;
            wheelR = 0.74; wheelT = 0.26; halfTrack = 1.52;
            archR = 0.86;

            % Gear train at true scale. Face width is drawn at ten normal
            % modules, a typical proportion; the key sets the real one.
            st = view.Train.stage;
            r1 = 1000*st(1).d_pinion/2/unitMm;   r2 = 1000*st(1).d_gear/2/unitMm;
            r3 = 1000*st(2).d_pinion/2/unitMm;   r4 = 1000*st(2).d_gear/2/unitMm;
            mod1 = 1000*st(1).m_t/unitMm;        mod2 = 1000*st(2).m_t/unitMm;
            face1 = 10*1000*st(1).m_n/unitMm;    face2 = 10*1000*st(2).m_n/unitMm;
            psi1 = st(1).psi;                    psi2 = st(2).psi;

            % Body is two lofts: the lower body up to the belt line (nose,
            % hood shoulder, door belt, trunk deck) and the greenhouse on top
            % of it (A-pillar, roof, fastback glass). x,z pairs, scene units.
            % Both profiles close onto the sill at the ends, so the loft ends
            % in a rounded nose and tail with no separate bumper face.
            beltPts = [0.80 0.92; 0.81 1.18; 0.84 1.38; 0.96 1.62; 1.25 1.84; ...
                       1.70 1.97; 2.30 2.08; 3.00 2.19; 3.70 2.30; 4.20 2.38; ...
                       5.00 2.44; 6.50 2.49; 8.00 2.51; 9.20 2.50; 9.80 2.47; ...
                       10.40 2.40; 10.85 2.31; 11.10 2.18; 11.20 2.02; ...
                       11.26 1.75; 11.29 1.35; 11.30 1.02];
            roofPts = [4.15 2.38; 4.50 2.62; 4.90 2.92; 5.30 3.18; 5.70 3.40; ...
                       6.10 3.52; 6.50 3.56; 6.90 3.55; 7.30 3.48; 7.70 3.33; ...
                       8.10 3.13; 8.50 2.90; 8.85 2.68; 9.10 2.50];
            % plan half-width factor: flat flanks, bumper corners pulled in
            planPts = [0.80 0.06; 0.81 0.22; 0.84 0.42; 0.90 0.60; 1.05 0.73; ...
                       1.35 0.86; 1.80 0.94; 2.60 0.99; 3.20 1.00; 9.40 1.00; ...
                       10.20 0.98; 10.60 0.94; 10.90 0.86; 11.10 0.74; ...
                       11.20 0.60; 11.26 0.42; 11.29 0.22; 11.30 0.06];
            beltOf = @(x) pchipOf(beltPts, x);
            roofOf = @(x) pchipOf(roofPts, x);
            planOf = @(x) pchipOf(planPts, x);
            % bumper undersides lift clear of the sill (approach and departure)
            sillOf = @(x) zFloor + 0.12*max(0, (1.60 - x)/0.80).^2 ...
                + 0.22*max(0, (x - 10.50)/0.80).^2;
            bodySide  = @(x, z) lowerSide(x, z, bodyWidth, zFloor, beltOf, planOf);
            glassSide = @(x, z) upperSide(x, z, bodyWidth, beltOf, roofOf, planOf);

            % ---- road ----
            [rx, ry] = meshgrid([-7 19], [-7 7]);
            surf(ax, rx, ry, zGround*ones(2), 'FaceColor', [0.102 0.107 0.119], ...
                'EdgeColor', 'none', 'FaceLighting', 'none');
            circle = linspace(0, 2*pi, 72);
            for k = linspace(1, 0.30, 7)
                patch(ax, 6.05 + 4.55*k*cos(circle), 1.72*k*sin(circle), ...
                    (zGround+0.0015)*ones(size(circle)), [0.035 0.038 0.045], ...
                    'EdgeColor', 'none', 'FaceAlpha', 0.115, 'FaceLighting', 'none');
            end

            % ---- lower body, wheel openings cut into the sections ----
            % Sections start at the arch instead of the sill inside each
            % opening. Doubled x stations at the arch ends give the vertical
            % edge of the opening its own column instead of a slanted quad.
            xArch = [xFront xRear] + archR*[-1 -1 1 1]' + 1e-4*[-1 1 -1 1]';
            xr = sort([linspace(xNose, xTail, 140), xArch(:)', ...
                xNose + [0.01 0.02 0.04 0.07], xTail - [0.01 0.02 0.04 0.07]]);
            zLo = @(x) archLine(x, [xFront xRear], zAxle, archR, sillOf(x));
            [xs, ys, zs] = loft(xr, zLo, beltOf, bodySide, 64);
            skin = {'EdgeColor', 'none', 'SpecularStrength', 0.9, ...
                'SpecularExponent', 22, 'DiffuseStrength', 0.30, ...
                'AmbientStrength', 0.26, 'BackFaceLighting', 'lit'};
            surf(ax, xs, ys, zs, 'FaceColor', cGlass, 'FaceAlpha', 0.12, skin{:});

            % ---- greenhouse loft on the belt line ----
            xg = linspace(roofPts(1,1), roofPts(end,1), 80);
            [xs, ys, zs] = loft(xg, @(x) beltOf(x) - 0.04, roofOf, glassSide, 48);
            % Denser than the lower body: the far wheels would otherwise show
            % through the cabin as bright rings. The drive unit sits below the
            % belt and is unaffected.
            surf(ax, xs, ys, zs, 'FaceColor', cGlass*0.92, 'FaceAlpha', 0.19, skin{:});

            % ---- feature lines: belt, sill, arch lips, roof rail ----
            % Lines sit on the shoulder of each section, just under the edge
            % rounding, so they trace the true skin width.
            lineOn = @(x, y, z, a, w) plot3(ax, x, y, z, 'Color', [cCage a], 'LineWidth', w);
            % One shoulder loop: down one flank, across the deck end, back
            % along the other flank, across the hood end. It stops where the
            % profiles round down so the loft ends carry no outline.
            xb = linspace(xNose + 0.12, xTail - 0.12, 200);
            zb = beltOf(xb) - 0.05;
            yb = bodySide(xb, zb);
            lineOn([xb fliplr(xb) xb(1)], [yb -fliplr(yb) yb(1)], ...
                [zb fliplr(zb) zb(1)], 0.32, 0.8);
            xsill = linspace(xNose + 0.30, xTail - 0.30, 200);
            zsill = sillOf(xsill);
            ysill = bodySide(xsill, zsill);
            ysill(min(abs(xsill - xFront), abs(xsill - xRear)) < archR) = NaN;
            arc = linspace(0, pi, 60);
            % Roof rail per side: A-pillar, rail and C-pillar in one polyline.
            % The far side (+y from the camera) is drawn fainter.
            zr = beltOf(xg) - 0.04 + 0.93*(roofOf(xg) - beltOf(xg) + 0.04);
            yr = glassSide(xg, zr);
            railAlpha = [0.55 0.22];
            for sgn = [-1 1]
                lineOn(xsill, sgn*ysill, zsill, 0.30, 0.8);
                for xw = [xFront xRear]
                    ax_ = [xw+archR, xw + archR*cos(arc), xw-archR];
                    az_ = [zFloor, zAxle + archR*sin(arc), zFloor];
                    lineOn(ax_, sgn*bodySide(ax_, az_), az_, 0.48, 1.0);
                end
                lineOn(xg, sgn*yr, zr, railAlpha(1 + (sgn > 0)), 1.1);
            end

            % ---- glazing laid on the greenhouse skin ----
            % Side glass is one band from A-pillar to C-pillar, sampled on the
            % greenhouse surface; the B-pillar is a dark strip inside it.
            % Windshield and backlight lie on the roof lid.
            cPane = [0.40 0.56 0.74];
            xd = linspace(4.42, 8.72, 40);
            zC = beltOf(8.72) + 0.05 + (roofOf(8.05) - 0.08 - beltOf(8.72) - 0.05) ...
                * (8.72 - xd)/(8.72 - 8.05);
            zlo = beltOf(xd) + 0.05;
            zhi = max(min(roofOf(xd) - 0.08, zC), zlo);
            sd = linspace(0, 1, 8)';
            zd = zlo + sd.*(zhi - zlo);
            xd = repmat(xd, numel(sd), 1);
            yd = glassSide(xd, zd) * 1.002;
            for sgn = [-1 1]
                surf(ax, xd, sgn*yd, zd, 'FaceColor', cPane, 'FaceAlpha', 0.24, ...
                    'EdgeColor', 'none', 'FaceLighting', 'none');
                zp = [beltOf(6.30) + 0.05, roofOf(6.30) - 0.08];
                patch(ax, [6.30 6.40 6.40 6.30], sgn*glassSide([6.30 6.40 6.40 6.30], ...
                    zp([1 1 2 2]))*1.004, zp([1 1 2 2]), [0.06 0.07 0.09], ...
                    'EdgeColor', 'none', 'FaceAlpha', 0.92, 'FaceLighting', 'none');
            end
            for xw = {[4.32 5.62], [7.45 9.06]}
                xt = linspace(xw{1}(1), xw{1}(2), 30);
                zt = roofOf(xt);
                yt = 0.96 * glassSide(xt, beltOf(xt) - 0.04 + 0.90*(zt - beltOf(xt) + 0.04));
                surf(ax, [xt; xt], [-yt; yt], [zt; zt] + 0.006, 'FaceColor', cPane, ...
                    'FaceAlpha', 0.20, 'EdgeColor', 'none', 'FaceLighting', 'none');
            end

            % ---- wheels on their own transforms so they can turn ----
            k = 0;
            for xw = [xFront xRear]
                for yw = [-halfTrack halfTrack]
                    k = k + 1;
                    xw_ = xw; yw_ = yw;
                    view.WheelTforms(k) = groupDraw(ax, ...
                        @(p) drawWheel(p, xw_, yw_, zAxle, wheelR, wheelT));
                    view.WheelCenters(k,:) = [xw yw zAxle];
                end
            end

            drawBox(ax, [3.20 7.10], [-1.40 1.40], [0.74 1.06], cBatt, 0.10, ...
                [0.36 0.80 0.82], 0.28);

            % ---- rear drive unit ----
            % A motor and a separate transmission on the rear axle, which is
            % the rear-wheel-drive EV layout. The transmission is single speed with two
            % stages on three parallel shafts in one plane: the motor drives
            % the input shaft through a coupling at the housing wall, the input
            % pinion drives the stage-1 gear on the intermediate shaft, the
            % stage-2 pinion on that shaft drives the output gear, and the
            % output gear carries the differential on the axle, the arrangement
            % of many production EV drive units.
            unitStart = numel(ax.Children);
            gx = xRear; gz = zAxle;
            u = [cos(deg2rad(152)) sin(deg2rad(152))];
            ic = [gx gz] + (r3 + r4)*u;                 % intermediate axis
            pc = ic + (r1 + r2)*u;                      % input axis, in line
            ix = ic(1); iz = ic(2); pxc = pc(1); pzc = pc(2);

            % Axial stations follow the answer-key layout: stage-2 mesh on the
            % axle center plane, stage-1 mesh toward the motor, 50 mm from each
            % gear face to its bearing and 20 mm between the two gears. Spans
            % are drawn at 1.6 times true length so the six supports and four
            % gear faces stay distinct from the pinned camera.
            k = 1.6/unitMm;
            y2 = 0;
            y1 = y2 - (face1/2 + face2/2 + 20*k);
            yIntA = y1 - face1/2 - 50*k;   yIntB = y2 + face2/2 + 50*k;
            yInA  = y1 - face1/2 - 50*k;   yInB  = y1 + face1/2 + 80*k;
            yOutA = y2 - face2/2 - 50*k;   yOutB = y2 + face2/2 + 50*k;
            yWall = [min([yIntA yInA yOutA]) - 0.03, max([yIntB yInB yOutB]) + 0.03];
            % Put the separate motor on the visible side of the housing.
            % A short exposed coupling makes the two assemblies legible.
            motorY = [-1.26, yWall(1) - 0.30];
            motorR = 0.25;
            yCoup = mean([motorY(2) yWall(1)]) + [-0.07 0.07];
            rIn  = 0.5*35/unitMm;  rInt = 0.5*50/unitMm;  rOut = 0.5*65/unitMm;

            % Transmission housing around all three shafts and six bearings.
            xs = [pxc - r1, pxc + r1, ix - r2, ix + r2, gx - r4, gx + r4];
            zs = [pzc - r1, pzc + r1, iz - r2, iz + r2, gz - r4, gz + r4];
            drawBox(ax, [min(xs) - 0.09, max(xs) + 0.09], yWall, ...
                [min(zs) - 0.09, max(zs) + 0.09], cAmber, 0.07, cAmber, 0.65);

            % Output gear on the axle; opposite hand to the stage-2 pinion.
            view.GearCenter = [gx 0 gz];
            view.GearTform = regroup(ax, collect(ax, @(p) drawGear(p, gx, gz, ...
                r4, st(2).N_gear, mod2, face2, -psi2, y2 - face2/2, cSteel)));
            view.GearTform.Tag = 'DriveGear';

            % Intermediate shaft: stage-1 gear and stage-2 pinion, same hand,
            % turning together on one shaft.
            view.IntermediateCenter = [ix 0 iz];
            view.IntermediateTform = regroup(ax, [ ...
                collect(ax, @(p) drawGear(p, ix, iz, r2, st(1).N_gear, mod1, face1, ...
                    psi1, y1 - face1/2, cSteel*0.94)); ...
                collect(ax, @(p) drawGear(p, ix, iz, r3, st(2).N_pinion, mod2, face2, ...
                    psi2, y2 - face2/2, min(cAmber*1.15, 1)))]);
            view.IntermediateTform.Tag = 'IntermediateGears';

            % Input pinion; opposite hand to the stage-1 gear.
            view.PinionCenter = [pxc 0 pzc];
            view.PinionTform = regroup(ax, collect(ax, @(p) drawGear(p, pxc, pzc, ...
                r1, st(1).N_pinion, mod1, face1, -psi1, y1 - face1/2, ...
                min(cMotor*1.25, 1))));
            view.PinionTform.Tag = 'DrivePinion';

            % motor outside the housing, coaxial with the input shaft
            drawMotorShell(ax, pxc, pzc, motorY, motorR, cMotor);
            view.RotorCenter = [pxc 0 pzc];
            view.RotorTform = regroup(ax, collect(ax, @(p) drawMotorRotor(p, ...
                pxc, pzc, motorY, motorR, cMotor)));
            view.RotorTform.Tag = 'DriveRotor';

            % input shaft: pinion between bearings A and B, coupling to the motor
            drawTube(ax, pxc, pzc, [yCoup(2), yInB+0.045], rIn, cSteel, 1.0);
            drawTube(ax, pxc, pzc, [motorY(2), yCoup(1)], rIn, cSteel, 1.0);
            drawCoupling(ax, pxc, pzc, yCoup, rIn, cSteel);
            drawBearing(ax, pxc, pzc, yInA, rIn, 0.042);
            drawBearing(ax, pxc, pzc, yInB, rIn, 0.042);
            drawRing(ax, pxc, pzc, yWall(1), rIn*2.6, 0.030, cAmber*0.85);

            % intermediate shaft, wholly inside the housing
            drawTube(ax, ix, iz, [yIntA - 0.03, yIntB + 0.03], rInt, cSteel, 1.0);
            drawBearing(ax, ix, iz, yIntA, rInt, 0.046);
            drawBearing(ax, ix, iz, yIntB, rInt, 0.046);

            % output: gear on the differential carrier, half-shafts to the wheels
            drawTube(ax, gx, gz, [-1.42 1.42], rOut, cSteel, 1.0);
            drawRing(ax, gx, gz, y2, rOut*2.1, 0.22, cSteel*0.82);
            drawBearing(ax, gx, gz, yOutA, rOut, 0.052);
            drawBearing(ax, gx, gz, yOutB, rOut, 0.052);
            for yw = yWall
                drawRing(ax, gx, gz, yw, rOut*2.4, 0.032, cAmber*0.85);
            end

            unitObjects = ax.Children(1:numel(ax.Children)-unitStart);
            if ~isempty(detailAxes) && isgraphics(detailAxes, 'axes')
                view.buildDetail(detailAxes, unitObjects, pxc, pzc, gx, gz, cMotor, cAmber);
            else
                tag(ax, 'ELECTRIC MOTOR', pxc, mean(motorY), pzc + motorR, -0.8, 0.8, cMotor);
                tag(ax, 'TWO-STAGE GEARBOX', gx, 0, gz + r4, 0.6, 1.0, cAmber);
            end

            % ---- power-flow particles: battery -> motor -> mesh -> wheel ----
            view.FlowPath = [5.30 0 0.92; 6.80 -0.65 0.94; pxc mean(motorY) pzc; ...
                             pxc y1 pzc; ix y1 iz; ix y2 iz; gx y2 gz; gx -halfTrack gz];
            view.FlowLength = max(cumulative(view.FlowPath));
            view.FlowDots = line(ax, nan(1,8), nan(1,8), nan(1,8), ...
                'LineStyle', 'none', 'Marker', 'o', 'MarkerSize', 5, ...
                'MarkerFaceColor', [0.30 0.78 1.00], 'MarkerEdgeColor', 'none', ...
                'Visible', 'off');

            % ---- camera and light ----
            % Pin the limits before the camera. With automatic limits the road
            % plane sets a cube as wide as itself, and an automatic camera then
            % backs off to contain that cube, shrinking the car to a speck.
            ax.XLim = [-0.6 12.6];
            ax.YLim = [-4.6 4.6];
            ax.ZLim = [0.0 5.2];
            % Elevated and behind the rear axle. Both drive units are visible
            % from here. A level view does not work: the gear is coaxial with a
            % road wheel of larger radius, so from abeam the wheel covers it.
            campos(ax, [20 -19 12]);
            camtarget(ax, [6.0 0 1.45]);
            camup(ax, [0 0 1]);
            camva(ax, 18.5);
            camproj(ax, 'orthographic');
            ax.CameraPositionMode = 'manual';
            ax.CameraTargetMode = 'manual';
            ax.CameraViewAngleMode = 'manual';
            ax.CameraUpVectorMode = 'manual';
            camlight(ax, 'headlight');
            keyLight = light(ax);
            keyLight.Position = [2 -18 16];
            keyLight.Color = [0.85 0.90 1.00];
            fillLight = light(ax);
            fillLight.Position = [20 12 7];
            fillLight.Color = [0.26 0.34 0.48];
            material(ax, 'dull');
            lighting(ax, 'gouraud');
            hold(ax, 'off');
        end

        function buildDetail(view, ax, objects, pxc, pzc, gx, gz, cMotor, cAmber)
            % Same geometry and transforms, enlarged without the vehicle skin.
            cla(ax, 'reset');
            ax.Toolbar.Visible = 'off';
            hold(ax, 'on');
            copyobj(objects, ax);
            view.DetailTforms = [findobj(ax, 'Tag', 'DrivePinion'), ...
                findobj(ax, 'Tag', 'DriveGear'), findobj(ax, 'Tag', 'DriveRotor'), ...
                findobj(ax, 'Tag', 'IntermediateGears')];
            axis(ax, 'off');
            daspect(ax, [1 1 1]);
            ax.Color = 'none';
            ax.Clipping = 'off';
            ax.XLim = [pxc-0.4 gx+0.65];
            ax.YLim = [-1.55 1.55];
            ax.ZLim = [gz-0.6 max(pzc+0.5, gz+0.8)];
            camproj(ax, 'orthographic');
            % From the far side: the stage-2 pinion sits behind the larger
            % stage-1 gear on the same shaft and is hidden from the motor side.
            campos(ax, [gx+2 7 gz+3]);
            camtarget(ax, [(pxc+gx)/2 -0.15 gz+0.10]);
            camup(ax, [0 0 1]);
            camva(ax, 24);
            camlight(ax, 'headlight');
            light(ax, 'Position', [pxc-3 4 pzc+5], 'Color', [0.58 0.73 0.94]);
            lighting(ax, 'gouraud');
            text(ax, 0.04, 0.96, 'ELECTRIC MOTOR', 'Units', 'normalized', ...
                'Color', cMotor, 'FontSize', 11, 'FontWeight', 'bold', ...
                'FontName', 'Segoe UI', 'VerticalAlignment', 'top');
            text(ax, 0.04, 0.88, 'SINGLE-SPEED, TWO-STAGE GEARBOX', 'Units', 'normalized', ...
                'Color', cAmber, 'FontSize', 11, 'FontWeight', 'bold', ...
                'FontName', 'Segoe UI', 'VerticalAlignment', 'top');
            st = view.Train.stage;
            text(ax, 0.04, 0.10, sprintf('%d:%d  x  %d:%d  |  %.2f:1 fixed reduction', ...
                st(1).N_pinion, st(1).N_gear, st(2).N_pinion, st(2).N_gear, view.Train.G), ...
                'Units', 'normalized', ...
                'Color', [0.76 0.81 0.88], 'FontSize', 10, 'FontName', 'Segoe UI');
            text(ax, 0.04, 0.03, 'Gears to scale, spans x1.6 / enlarged', 'Units', 'normalized', ...
                'Color', [0.49 0.56 0.65], 'FontSize', 9, 'FontName', 'Segoe UI');
            hold(ax, 'off');
        end
    end
end

% ===================== local helpers =====================

function tform = groupDraw(ax, drawFcn)
    %GROUPDRAW Run DRAWFCN on AX, then reparent whatever it made to a transform.
    %   surf/patch/plot3 only accept an axes as the leading parent argument,
    %   so the objects are created first and moved afterwards. New children
    %   are prepended, so the leading N handles are the ones just created.
    before = numel(ax.Children);
    drawFcn(ax);
    created = ax.Children(1:(numel(ax.Children) - before));
    tform = hgtransform(ax);
    set(created, 'Parent', tform);
end

function spin(tform, center, angle)
    if ~isgraphics(tform); return; end
    tform.Matrix = makehgtform('translate', center, 'yrotate', angle, ...
        'translate', -center);
end

function d = cumulative(path)
    d = [0; cumsum(vecnorm(diff(path), 2, 2))];
end

function v = pchipOf(pts, x)
    v = interp1(pts(:,1), pts(:,2), min(max(x, pts(1,1)), pts(end,1)), 'pchip');
end

function y = lowerSide(x, z, width, zFloor, beltOf, planOf)
    % Half-width of the lower body at (x,z): rounded rectangle section,
    % sill tucked in under the shoulder, plan taper at the bumpers.
    t = min(max((z - zFloor)./(beltOf(x) - zFloor), 0), 1);
    y = (width/2) * planOf(x) .* (1 - 0.07*(1-t)) ...
        .* (1 - t.^30).^0.10 .* (1 - (1-t).^10).^0.08;
end

function y = upperSide(x, z, width, beltOf, roofOf, planOf)
    % Half-width of the greenhouse at (x,z): narrower than the body at the
    % belt, tumblehome up to a rounded roof edge, tapering toward the tail.
    zb = beltOf(x) - 0.04;
    t = min(max((z - zb)./max(roofOf(x) - zb, 1e-3), 0), 1);
    y = (width/2) * planOf(x) .* (1 - 0.10*max(0, (x - 7.0)/2.1)) ...
        .* (0.92 - 0.07*t) .* (1 - t.^16).^0.15;
end

function z = archLine(x, xWheels, zAxle, archR, zFloor)
    % Lowest z of the skin at station x: the sill, or the arch over a wheel.
    z = zFloor;
    for c = xWheels
        d = x - c;
        if abs(d) < archR, z = zAxle + sqrt(archR^2 - d^2); end
    end
end

function [xs, ys, zs] = loft(xr, zLo, zHi, sideFcn, nv)
    % Sweep an open U section along x. nv even: up one flank, over, down.
    half = nv/2;
    xs = repmat(xr, nv, 1); ys = zeros(nv, numel(xr)); zs = ys;
    for i = 1:numel(xr)
        z = linspace(zLo(xr(i)), max(zHi(xr(i)), zLo(xr(i)) + 1e-3), half)';
        y = sideFcn(xr(i), z);
        ys(:,i) = [y; flipud(-y)];
        zs(:,i) = [z; flipud(z)];
    end
end

function drawGear(parent, cx, cz, rPitch, nTeeth, module, faceW, psi, y0, col)
    half = pi/(2*nTeeth);
    rTip  = rPitch + module;
    rRoot = rPitch - 1.25*module;
    offs = [-2*half+0.16*half, -1.28*half, -half, -0.55*half, ...
             0.55*half, half, 1.28*half, 2*half-0.16*half];
    radii = [rRoot rRoot rPitch rTip rTip rPitch rRoot rRoot];
    % Walk every flank of one tooth before advancing to the next tooth.
    ang = reshape(((2*pi*(0:nTeeth-1)/nTeeth)' + offs).', 1, []);
    rad = repmat(radii, 1, nTeeth);
    ang(end+1) = ang(1) + 2*pi;
    rad(end+1) = rad(1);

    nz = 11;
    yv = linspace(y0, y0+faceW, nz);
    twist = (yv - y0)*tan(psi)/rPitch;          % helix across the face
    x = zeros(numel(ang), nz); y = x; z = x;
    for j = 1:nz
        x(:,j) = cx + rad(:).*cos(ang(:) + twist(j));
        z(:,j) = cz + rad(:).*sin(ang(:) + twist(j));
        y(:,j) = yv(j);
    end
    surf(parent, x, y, z, 'FaceColor', col, 'EdgeColor', 'none', ...
        'SpecularStrength', 0.75, 'SpecularExponent', 12, ...
        'DiffuseStrength', 0.85, 'AmbientStrength', 0.26);

    % Solid web, built as a triangle fan from the gear center. A single patch
    % face holding the whole tooth outline does not fill: at 180 teeth that is
    % 1441 vertices and MATLAB's polygon triangulation fails.
    nOut = numel(ang);
    fan = [ones(nOut-1,1), (2:nOut)', (3:nOut+1)'];
    fan(end,3) = 2;
    for j = [1 nz]
        verts = [cx, yv(j), cz; x(:,j), y(:,j), z(:,j)];
        patch(parent, 'Vertices', verts, 'Faces', fan, ...
            'FaceColor', col*0.92, 'EdgeColor', 'none', ...
            'SpecularStrength', 0.35, 'AmbientStrength', 0.30);
        if nTeeth > 40
            % Recessed web and turned hub distinguish the wheel from a disc.
            circle = linspace(0, 2*pi, 120);
            side = sign(j - nz/2);
            yFace = yv(j) + side*0.002;
            patch(parent, cx+0.77*rPitch*cos(circle), ...
                yFace*ones(size(circle)), cz+0.77*rPitch*sin(circle), ...
                col*0.53, 'EdgeColor', col*0.80, 'LineWidth', 0.8, ...
                'SpecularStrength', 0.6, 'AmbientStrength', 0.4);
            patch(parent, cx+0.27*rPitch*cos(circle), ...
                (yFace+side*0.002)*ones(size(circle)), cz+0.27*rPitch*sin(circle), ...
                col, 'EdgeColor', 'none', 'SpecularStrength', 0.8);
        end
    end
end

function drawTube(parent, cx, cz, yRange, r, col, alpha)
    circle = linspace(0, 2*pi, 48)';
    surf(parent, cx + r*cos(circle)*[1 1], ones(numel(circle),1)*yRange, ...
        cz + r*sin(circle)*[1 1], 'FaceColor', col, 'EdgeColor', 'none', ...
        'FaceAlpha', alpha, 'SpecularStrength', 0.9, 'SpecularExponent', 16, ...
        'AmbientStrength', 0.28);
end

function drawRing(parent, cx, cz, y, r, w, col)
    drawTube(parent, cx, cz, [y-w/2 y+w/2], r, col, 0.96);
end

function drawBearing(parent, cx, cz, y, rShaft, w)
    % Rolling bearing at a shaft support: inner race standing proud of the
    % outer race on both sides, with the ball row showing as a dark band.
    drawTube(parent, cx, cz, y + [-1 1]*w*0.66, rShaft*1.45, [0.72 0.76 0.82], 1.0);
    drawTube(parent, cx, cz, y + [-1 1]*w/2, rShaft*2.10, [0.60 0.65 0.73], 1.0);
    drawRing(parent, cx, cz, y, rShaft*2.16, w*0.30, [0.19 0.21 0.25]);
end

function drawCoupling(parent, cx, cz, yRange, rShaft, col)
    % Bolted flange pair between the motor shaft and the input shaft.
    ym = mean(yRange);
    drawTube(parent, cx, cz, yRange, rShaft*1.20, col*0.90, 1.0);
    for yf = ym + [-0.017 0.017]
        drawRing(parent, cx, cz, yf, rShaft*3.80, 0.028, col*0.72);
    end
    drawRing(parent, cx, cz, ym, rShaft*3.86, 0.008, [0.19 0.21 0.25]);
end

function drawMotorShell(ax, cx, cz, yRange, r, col)
    drawTube(ax, cx, cz, yRange, r, col*0.72, 0.56);
    % End bells and cooling ribs.
    for y = linspace(yRange(1)+0.04, yRange(2)-0.04, 8)
        drawRing(ax, cx, cz, y, r*1.035, 0.012, col*0.72);
    end
    circle = linspace(0, 2*pi, 60);
    for j = 1:2
        patch(ax, cx + r*cos(circle), yRange(j)*ones(size(circle)), ...
            cz + r*sin(circle), col*0.42, 'EdgeColor', col, 'EdgeAlpha', 0.85, ...
            'LineWidth', 1.1, 'FaceAlpha', 0.65, 'FaceLighting', 'none');
    end
end

function drawMotorRotor(ax, cx, cz, yRange, r, col)
    % Rotor and its bars turn with the input shaft.
    drawTube(ax, cx, cz, [yRange(1)+0.03 yRange(2)-0.03], r*0.30, ...
        [0.74 0.78 0.84], 0.85);
    for a = linspace(0, 2*pi, 13)
        plot3(ax, cx + [r r]*0.62*cos(a), yRange, ...
            cz + [r r]*0.62*sin(a), 'Color', [col 0.55], 'LineWidth', 1.2);
    end
end

function drawWheel(parent, cx, cy, cz, r, t)
    tire = [0.10 0.105 0.115];
    rim  = [0.52 0.57 0.64];
    circle = linspace(0, 2*pi, 64)';
    surf(parent, cx + r*cos(circle)*[1 1], ones(numel(circle),1)*[cy-t/2 cy+t/2], ...
        cz + r*sin(circle)*[1 1], 'FaceColor', tire, 'EdgeColor', 'none', ...
        'DiffuseStrength', 0.7, 'AmbientStrength', 0.20);
    for yf = [cy-t/2 cy+t/2]
        patch(parent, cx + r*cos(circle), yf*ones(size(circle)), ...
            cz + r*sin(circle), tire*1.3, 'EdgeColor', [0.22 0.24 0.27], ...
            'LineWidth', 0.7, 'AmbientStrength', 0.24);
    end
    yf = cy + sign(cy)*(t/2 + 0.004);
    patch(parent, cx + 0.68*r*cos(circle), yf*ones(size(circle)), ...
        cz + 0.68*r*sin(circle), rim*0.42, 'EdgeColor', rim, ...
        'LineWidth', 1.1, 'AmbientStrength', 0.35);
    % Five spokes.
    for a = (0:4)*2*pi/5 + pi/7
        plot3(parent, cx + [0.30 0.66]*r*cos(a), [yf yf] + sign(cy)*0.002, ...
            cz + [0.30 0.66]*r*sin(a), 'Color', [min(rim*1.25,1) 0.85], 'LineWidth', 4.0);
    end
    patch(parent, cx + 0.20*r*cos(circle), (yf + sign(cy)*0.004)*ones(size(circle)), ...
        cz + 0.20*r*sin(circle), rim*0.75, 'EdgeColor', 'none');
end

function drawBox(ax, xr, yr, zr, faceCol, faceAlpha, edgeCol, edgeAlpha)
    v = [xr([1 2 2 1 1 2 2 1])', yr([1 1 2 2 1 1 2 2])', zr([1 1 1 1 2 2 2 2])'];
    f = [1 2 3 4; 5 6 7 8; 1 2 6 5; 2 3 7 6; 3 4 8 7; 4 1 5 8];
    patch(ax, 'Vertices', v, 'Faces', f, 'FaceColor', faceCol, ...
        'FaceAlpha', faceAlpha, 'EdgeColor', edgeCol, 'EdgeAlpha', edgeAlpha, ...
        'LineWidth', 1.1, 'FaceLighting', 'none');
end

function tag(ax, txt, x, y, z, dx, dz, col)
%TAG Component callout: a dot on the part, a leader, and the label.
    plot3(ax, [x x+dx], [y y], [z z+dz], 'Color', [col 0.55], 'LineWidth', 0.8);
    plot3(ax, x, y, z, 'o', 'MarkerSize', 3.5, ...
        'MarkerFaceColor', col, 'MarkerEdgeColor', 'none');
    if dx < 0, align = 'right'; else, align = 'left'; end
    text(ax, x+dx, y, z+dz, ['  ' txt '  '], 'Color', col, ...
        'FontSize', 9.5, 'FontWeight', 'bold', 'FontName', 'Segoe UI', ...
        'HorizontalAlignment', align, 'VerticalAlignment', 'middle');
end

function created = collect(ax, drawFcn)
%COLLECT Run DRAWFCN on AX and return the handles it created.
    before = numel(ax.Children);
    drawFcn(ax);
    created = ax.Children(1:(numel(ax.Children) - before));
end

function tform = regroup(ax, handles)
%REGROUP Move already-drawn handles under a fresh transform.
    tform = hgtransform(ax);
    if ~isempty(handles), set(handles, 'Parent', tform); end
end
