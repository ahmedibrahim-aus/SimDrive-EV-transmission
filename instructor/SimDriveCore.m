classdef SimDriveCore
%SIMDRIVECORE Shared simulation utilities for SimDrive.
%   Static helper methods used by the command-line script, instructor app,
%   and Live Editor teaching material.

    properties (Constant, Access = private)
        % Exported plots: report style, black and gray on white.
        TorqueColor = [0 0 0]
        SpeedColor  = [0.45 0.45 0.45]
    end

    properties (Constant)
        % Exported plots and the dashboard share one typeface.
        PlotFont = "Times New Roman"
    end

    methods (Static)

        function closeRuntimeModel(modelName)
            % Close an unsaved model built by createModelEVBlocks. Any other
            % model with the same name stays open.
            if bdIsLoaded(modelName) && isempty(get_param(modelName, "FileName")) && ...
                    get_param(modelName, "Tag") == "SimDriveRuntime"
                close_system(modelName, 0);
            end
        end

        function validateVehicleParameters(p)
            % Validate vehicle and motor inputs before calculating derived quantities.
            positive = [p.m_vehicle p.A p.Tmax p.Pmax_W p.omega_max p.wheel_R];
            nonnegative = [p.Cd p.Crr p.Tregen p.I_motor];
            if ~all(isfinite([positive nonnegative])) || ~all(positive > 0) || ~all(nonnegative >= 0)
                error('SimDriveCore:InvalidVehicleParameters', ...
                    ['Vehicle mass, frontal area, motor torque, power and speed, and wheel radius must be positive and finite. ' ...
                    'Drag, rolling resistance, regen torque and rotor inertia must be nonnegative and finite.']);
            end
            if ~(p.eta_dt > 0 && p.eta_dt <= 1)
                error('SimDriveCore:InvalidEfficiency', ...
                    'Drivetrain efficiency must be greater than zero and at most 1.');
            end
            if ~(p.T_ambient_C >= -40 && p.T_ambient_C <= 60)
                error('SimDriveCore:InvalidAmbientTemperature', ...
                    'Ambient temperature must be between -40 and 60 deg C (the supported model range).');
            end
            if p.omega_max <= p.Pmax_W/p.Tmax
                error('SimDriveCore:InvalidMotorSpeed', ...
                    'n_max must be above the motor base speed.');
            end
        end

        function rho = airDensity(T_ambient_C)
            % Moist air at 101325 Pa and 50 percent relative humidity; the
            % vapor pressure follows the Tetens formula.
            p_atm = 101325;
            RH    = 0.50;
            R_d   = 287.058;
            R_v   = 461.495;
            T_K   = T_ambient_C + 273.15;
            p_sat = 610.78 * exp(17.27 * T_ambient_C / (T_ambient_C + 237.3));
            p_v   = RH * p_sat;
            rho   = (p_atm - p_v) / (R_d * T_K) + p_v / (R_v * T_K);
        end

        function I_wheel = wheelInertia(wheel_R, tire_profile)
            % One wheel and tire assembly (20 kg) as a thick ring from the rim
            % to the tire radius: I = 0.5*m*(1 + (r_rim/R_w)^2)*R_w^2. A low
            % profile tire sits on a large rim, a high profile one on a small rim.
            switch tire_profile
                case "low",      rim_ratio = 0.74;   % e.g. 255/35R20
                case "standard", rim_ratio = 0.68;   % e.g. 235/45R18
                case "high",     rim_ratio = 0.62;   % e.g. 205/65R16
                otherwise
                    error("SimDrive:UnknownTireProfile", ...
                        "tire_profile must be ""low"", ""standard"" or ""high"", not ""%s"".", tire_profile);
            end
            m_whl = 20;
            I_wheel = 0.5 * m_whl * (1 + rim_ratio^2) * wheel_R^2;
        end

        function [tSeconds, vKph] = loadFtp75SpeedTrace(fileName, units)
            %LOADFTP75SPEEDTRACE Drive-cycle speed trace in s and km/h.
            %   With no file (or an empty one) the built-in EPA FTP-75
            %   schedule is used. A file must hold time [s] and speed in two
            %   columns, starting at time zero, with no negative speeds.
            %   UNITS is "mph", "kph" or "auto" (the default). With "auto" a
            %   header naming the units (mph, kph, km/h or kmh) decides;
            %   without one, a trace that never exceeds 75 is taken as mph
            %   and a SimDriveCore:FtpUnitsGuessed warning says so.
            arguments
                fileName (1,1) string = ""
                units (1,1) string {mustBeMember(units, ["auto" "mph" "kph"])} = "auto"
            end
            if strlength(fileName) == 0
                [t, v] = ftp75Schedule();
                units = "mph";
            else
                data = readmatrix(fileName, "FileType", "text");
                if size(data, 2) < 2 || size(data, 1) < 10
                    error("SimDriveCore:FtpFileShape", ...
                        "Drive-cycle file %s must have at least 2 columns and 10 rows.", fileName);
                end
                t = data(:, 1);
                v = data(:, 2);
                if units == "auto"
                    header = lower(string(readlines(fileName, "EmptyLineRule", "skip")));
                    header = header(find(~startsWith(strtrim(header), digitsPattern | "-" | "."), 1));
                    if ~isempty(header) && contains(header, ["kph" "kmph" "km/h" "kmh"])
                        units = "kph";
                    elseif ~isempty(header) && contains(header, "mph")
                        units = "mph";
                    end
                end
            end

            isValid = isfinite(t) & isfinite(v);
            t = t(isValid);
            v = v(isValid);

            [t, uniqueIdx] = unique(t, "stable");
            v = v(uniqueIdx);
            if numel(t) < 2
                error("SimDriveCore:FtpFiniteSamples", ...
                    "Drive-cycle data must contain at least two distinct finite time/speed samples.");
            end
            if any(diff(t) <= 0)
                error("SimDriveCore:FtpTimeNotIncreasing", ...
                    "Drive-cycle time must increase strictly (after removing repeated times).");
            end
            if t(1) ~= 0
                error("SimDriveCore:FtpTimeStart", ...
                    "Drive-cycle time must start at 0 s; this file starts at %g s.", t(1));
            end
            if any(v < 0)
                error("SimDriveCore:FtpNegativeSpeed", ...
                    "Drive-cycle speed must not be negative (minimum %g).", min(v));
            end

            if units == "auto"
                if max(v) < 75
                    units = "mph";
                else
                    units = "kph";
                end
                warning("SimDriveCore:FtpUnitsGuessed", ...
                    "Speed units of %s not given; treated as %s (maximum %.1f). Pass the units to be sure.", ...
                    fileName, units, max(v));
            end
            if units == "mph"
                vKph = v * 1.609344;
            else
                vKph = v;
            end

            tSeconds = t(:);
            vKph = vKph(:);
        end

        function [tOut, yOut] = binAverage(tIn, yIn, maxPoints)
            tIn = tIn(:);
            yIn = yIn(:);

            isValid = isfinite(tIn) & isfinite(yIn);
            t = tIn(isValid);
            y = yIn(isValid);

            if numel(t) < 10
                tOut = t;
                yOut = y;
                return;
            end

            if t(end) <= t(1)
                tOut = t(1);
                yOut = mean(y, "omitnan");
                return;
            end

            numBins = max(50, min(maxPoints, 20000));
            edges = linspace(t(1), t(end), numBins + 1);
            bin = discretize(t, edges);
            centers = 0.5 * (edges(1:end-1) + edges(2:end));

            yMean = accumarray( ...
                bin(~isnan(bin)), ...
                y(~isnan(bin)), ...
                [numBins 1], ...
                @(x) mean(x, "omitnan"), ...
                NaN);

            keep = isfinite(yMean);
            tOut = centers(keep);
            yOut = yMean(keep);
        end

        function [meanTorque, altTorque, cycleData] = computeFatigueLoad(torqueTs, speedKphTs, minMovingKph, snExponent)
            %COMPUTEFATIGUELOAD Reduce FTP-75 torque to one equivalent sinusoid.
            %   Rainflow cycle counting and a damage-equivalent amplitude give
            %   one mean and one alternating torque for the Shigley sinusoidal
            %   fatigue exercise. SNEXPONENT defaults to 3.
            if nargin < 4
                snExponent = 3;
            end

            if ~(exist("rainflow", "file") || exist("rainflow", "builtin"))
                error("SimDriveCore:RainflowUnavailable", ...
                    "rainflow() is required for fatigue load extraction. Install the Signal Processing Toolbox.");
            end

            torque = torqueTs.Data(:);
            torqueTime = torqueTs.Time(:);
            speed = interp1(speedKphTs.Time(:), speedKphTs.Data(:), torqueTime, "linear", "extrap");

            isMoving = (speed > minMovingKph) & isfinite(torque) & isfinite(speed) & isfinite(torqueTime);
            movingTorque = torque(isMoving);
            movingTime = torqueTime(isMoving);

            if numel(movingTorque) < 50
                error("SimDriveCore:InsufficientFatigueSamples", ...
                    "Rainflow fatigue extraction needs at least 50 finite moving torque samples.");
            end

            rf = rainflow(movingTorque, movingTime);
            if isempty(rf)
                error("SimDriveCore:RainflowEmpty", ...
                    "rainflow() did not return valid cycle data for the moving FTP-75 torque history.");
            end

            % Range gate: cycles smaller than 2 percent of the full torque
            % range are speed-controller ripple, not driving events. Left in,
            % they are most of the count and dilute the per-cycle averages
            % below, although they add almost no damage.
            rangeGate = 0.02 * (max(movingTorque) - min(movingTorque));
            keep = rf(:, 2) >= rangeGate;
            rf = rf(keep, :);

            nCycles = rf(:, 1);
            altCycles = rf(:, 2) / 2;
            meanCycles = rf(:, 3);
            totalCycles = sum(nCycles);   % positive: the largest cycle spans the full range

            altTorque = (sum(nCycles .* altCycles.^snExponent) / totalCycles)^(1/snExponent);
            meanTorque = sum(nCycles .* meanCycles) / totalCycles;

            cycleData.n_cycles = nCycles;
            cycleData.T_mean_cyc = meanCycles;
            cycleData.T_alt_cyc = altCycles;
            cycleData.N_total = totalCycles;
            cycleData.range_gate = rangeGate;
            cycleData.m_sn = snExponent;
        end

        function equivalentTorque = computeBearingEquivalentTorque(torqueTs, omegaTs)
            torqueTime = torqueTs.Time(:);
            torque = abs(torqueTs.Data(:));
            omega = interp1(omegaTs.Time(:), abs(omegaTs.Data(:)), torqueTime, "linear", "extrap");

            isValid = isfinite(torqueTime) & isfinite(torque) & isfinite(omega);
            t = torqueTime(isValid);
            torque = torque(isValid);
            omega = omega(isValid);

            if numel(t) < 2
                equivalentTorque = 0;
                return;
            end

            revolutionWeight = trapz(t, omega);
            if revolutionWeight <= 0
                equivalentTorque = 0;
                return;
            end

            equivalentTorque = (trapz(t, (torque.^3) .* omega) / revolutionWeight)^(1/3);
        end

        function exportCasePlot(outdir, caseName, torqueApplied, speedSimKph, torqueEquivSin, maxPlotPoints, ftpRmsErrKph)
            caseName = string(caseName);
            isFtp = (caseName == "FTP75");

            if isFtp && ~isempty(torqueEquivSin)
                torqueTs = torqueEquivSin;
                torqueLabel = "Equivalent sinusoid (120 s period)";
            else
                torqueTs = torqueApplied;
                torqueLabel = "Motor torque";
            end

            titleName = caseName;
            if caseName == "FTP75"
                titleName = "FTP-75 city cycle";
            elseif caseName == "HillClimb"
                titleName = "Hill climb";
            elseif caseName == "DragRace"
                titleName = "Full-throttle launch (drag race)";
            end

            [torqueTime, torquePlot] = SimDriveCore.binAverage( ...
                torqueTs.Time(:), torqueTs.Data(:), maxPlotPoints);
            [speedTime, speedPlot] = SimDriveCore.binAverage( ...
                speedSimKph.Time(:), speedSimKph.Data(:), maxPlotPoints);

            % Hidden from gcf/gca; every call names its axes.
            fig = figure("Visible", "off", "Color", "white", "Position", [50 50 900 420], ...
                "HandleVisibility", "off");
            ax = axes(fig);
            SimDriveCore.styleReportAxes(ax);

            yyaxis(ax, "left");
            h1 = plot(ax, torqueTime, torquePlot, ...
                "Color", SimDriveCore.TorqueColor, "LineWidth", 1.1);
            ylabel(ax, "Motor torque (N·m)");
            % Headroom above a torque plateau.
            ylim(ax, [min(0, 1.15*min(torquePlot)), 1.15*max(max(torquePlot), eps)]);

            yyaxis(ax, "right");
            h2 = plot(ax, speedTime, speedPlot, ...
                "--", "Color", SimDriveCore.SpeedColor, "LineWidth", 1.0);
            ylabel(ax, "Vehicle speed (km/h)");
            ax.YAxis(1).Color = "k";
            ax.YAxis(2).Color = "k";

            xlabel(ax, "Time (s)");
            if isFtp && isfinite(ftpRmsErrKph)
                title(ax, sprintf("%s (speed tracking RMS error %.2f km/h)", titleName, ftpRmsErrKph));
            else
                title(ax, titleName);
            end
            legend(ax, [h1 h2], {char(torqueLabel), "Vehicle speed"}, ...
                "Location", "southoutside", "Orientation", "horizontal", ...
                "FontName", SimDriveCore.PlotFont, "FontSize", 10);

            exportgraphics(fig, fullfile(outdir, caseName + "_Plot.png"), ...
                "Resolution", 200, "Padding", 12)
            close(fig);
        end

        function exportOverviewPlot(outdir, caseNames, torqueSeries, speedSeries, Tmax, Tregen, maxPlotPoints)
            %EXPORTOVERVIEWPLOT Overview_AllCases.png: motor torque and speed of every case.
            %   CASENAMES is a string array; TORQUESERIES and SPEEDSERIES are
            %   cell arrays of timeseries (applied motor torque, vehicle speed
            %   in km/h). The dashboard and main.mlx both call this, so the
            %   two routes write the same figure.
            titles = dictionary(["FTP75" "HillClimb" "DragRace"], ...
                ["FTP-75 city cycle" "Hill climb" "Full-throttle launch (drag race)"]);
            n = numel(caseNames);
            fig = figure("Visible", "off", "Color", "white", "Position", [50 50 900 760*n/3], ...
                "HandleVisibility", "off");
            figureCleanup = onCleanup(@() close(fig));
            for k = 1:n
                [tT, T] = SimDriveCore.binAverage(torqueSeries{k}.Time(:), torqueSeries{k}.Data(:), maxPlotPoints);
                [tV, v] = SimDriveCore.binAverage(speedSeries{k}.Time(:), speedSeries{k}.Data(:), maxPlotPoints);
                ax = subplot(n, 1, k, "Parent", fig);
                SimDriveCore.styleReportAxes(ax);
                yyaxis(ax, "left");
                hT = plot(ax, tT, T, "Color", SimDriveCore.TorqueColor, "LineWidth", 1.0);
                hold(ax, "on");
                % The limits are named in the legend, not on the lines.
                hMax = yline(ax, Tmax, "-.", "Color", [0.55 0.55 0.55], "LineWidth", 0.8);
                hReg = yline(ax, -Tregen, ":", "Color", [0.55 0.55 0.55], "LineWidth", 0.8);
                hold(ax, "off");
                ylim(ax, [-1.25*Tregen, 1.2*Tmax]);
                ylabel(ax, "Torque (N·m)");
                yyaxis(ax, "right");
                hV = plot(ax, tV, v, "--", "Color", SimDriveCore.SpeedColor, "LineWidth", 0.9);
                ylabel(ax, "Speed (km/h)");
                ax.YAxis(1).Color = "k";
                ax.YAxis(2).Color = "k";
                name = string(caseNames(k));
                if isKey(titles, name), name = titles(name); end
                title(ax, sprintf("(%c) %s", 'a' + k - 1, name), "FontWeight", "normal");
                ax.TitleHorizontalAlignment = "left";
                if k == 1
                    legend(ax, [hT hV hMax hReg], ["Motor torque", "Vehicle speed", ...
                        "Torque limit T_{max}", "Regen limit -T_{regen}"], ...
                        "Location", "northoutside", "Orientation", "horizontal", ...
                        "FontName", SimDriveCore.PlotFont, "FontSize", 10);
                end
                xlabel(ax, "Time (s)");   % each case has its own time scale
            end
            exportgraphics(fig, fullfile(outdir, "Overview_AllCases.png"), "Resolution", 200);
        end

        function createModelEVBlocks(modelName, mVeh, mEff, Cd, area, rho, Crr, g, Rw, gearRatio, eta, TsPid, dtSim, slewNmPerS)
            % Callers check the vehicle inputs with validateVehicleParameters.
            modelName = string(modelName);
            if ~isvarname(modelName)
                error("SimDriveCore:InvalidModelName", "Use a valid model name without a path or extension.");
            end
            SimDriveCore.closeRuntimeModel(modelName);   % unsaved copy from an earlier run
            if bdIsLoaded(modelName) || exist(modelName + ".slx", "file") || ...
                    exist(modelName + ".mdl", "file")
                error("SimDriveCore:ModelNameConflict", ...
                    "Model %s is already loaded or saved. Choose another runtime name.", modelName);
            end

            new_system(modelName);
            set_param(modelName, "Tag", "SimDriveRuntime");

            set_param(modelName, "SolverType", "Fixed-step", "Solver", "ode3", ...
                "FixedStep", num2str(dtSim));

            add_block("simulink/Sources/From Workspace", modelName + "/Drive Cycle Input", ...
                "Position", [20, 80, 140, 110]);
            set_param(modelName + "/Drive Cycle Input", "VariableName", "drive_data", "Interpolate", "on");

            add_block("simulink/Math Operations/Gain", modelName + "/kmh_to_ms", ...
                "Gain", "1000/3600", "Position", [170, 83, 240, 107]);
            add_block("simulink/Math Operations/Sum", modelName + "/Error Sum", ...
                "Inputs", "+-", "Position", [270, 85, 300, 115]);
            add_block("simulink/Continuous/PID Controller", modelName + "/PID Controller", ...
                "LimitOutput", "on", ...
                "UpperSaturationLimit", "Tmax", ...
                "LowerSaturationLimit", "-Tregen", ...
                "AntiWindupMode", "clamping", ...
                "Position", [330, 80, 430, 120]);
            set_param(modelName + "/PID Controller", "TimeDomain", "Discrete-time", ...
                "SampleTime", num2str(TsPid));
            set_param(modelName + "/PID Controller", "P", "Kp", "I", "Ki", "D", "Kd", "N", "Nf");

            add_block("simulink/Sources/Constant", modelName + "/Topen_const", ...
                "Value", "Topen_cmd", "Position", [330, 150, 430, 180]);
            add_block("simulink/Sources/Constant", modelName + "/CASE_MODE", ...
                "Value", "CASE_MODE", "Position", [430, 25, 540, 55]);
            add_block("simulink/Signal Routing/Switch", modelName + "/ModeSwitch", ...
                "Criteria", "u2 ~= 0", "Threshold", "0.5", "Position", [560, 95, 610, 155]);
            add_block("simulink/Continuous/Transfer Fcn", modelName + "/Torque Actuator", ...
                "Numerator", "[1]", "Denominator", "[tau_torque 1]", "Position", [650, 105, 740, 135]);
            add_block("simulink/Discontinuities/Rate Limiter", modelName + "/Torque Rate Limiter", ...
                "RisingSlewLimit", num2str(+slewNmPerS), ...
                "FallingSlewLimit", num2str(-slewNmPerS), ...
                "Position", [780, 105, 910, 135]);

            add_block("simulink/Ports & Subsystems/Subsystem", modelName + "/Vehicle Dynamics", ...
                "Position", [1180, 80, 1420, 180]);
            sub = modelName + "/Vehicle Dynamics";
            delete_block(sub + "/In1");
            delete_block(sub + "/Out1");
            add_block("simulink/Ports & Subsystems/In1", sub + "/Tin_in", ...
                "Position", [30, 50, 60, 65]);
            add_block("simulink/Ports & Subsystems/Out1", sub + "/v_out_mps", ...
                "Position", [880, 95, 920, 110]);
            % Drivetrain loss sits on the output side when driving and on the
            % motor side when regenerating: F = eta*G*T/Rw for T >= 0 and
            % F = G*T/(eta*Rw) for T < 0.
            add_block("simulink/Math Operations/Gain", sub + "/T_to_F_drive", ...
                "Gain", sprintf("%g*%g/%g", eta, gearRatio, Rw), "Position", [100, 15, 170, 45]);
            add_block("simulink/Math Operations/Gain", sub + "/T_to_F_regen", ...
                "Gain", sprintf("%g/(%g*%g)", gearRatio, eta, Rw), "Position", [100, 95, 170, 125]);
            add_block("simulink/Signal Routing/Switch", sub + "/T_to_F", ...
                "Criteria", "u2 >= Threshold", "Threshold", "0", "Position", [200, 45, 240, 95]);
            add_block("simulink/Math Operations/Sum", sub + "/NetF", ...
                "Inputs", "+---", "Position", [260, 80, 290, 110]);
            add_block("simulink/Math Operations/Gain", sub + "/1_m", ...
                "Gain", sprintf("1/%g", mEff), "Position", [320, 83, 360, 107]);
            % Speed cannot go negative: braking torque on a stopped car does
            % not drive it backwards. Limiting the integrator itself (rather
            % than only its output) stops the state winding below zero at
            % every stop, which otherwise forces a full-torque launch.
            add_block("simulink/Continuous/Integrator", sub + "/Int_v_raw", ...
                "LimitOutput", "on", "LowerSaturationLimit", "0", ...
                "UpperSaturationLimit", "inf", ...
                "Position", [400, 83, 430, 107]);
            add_block("simulink/Sources/Constant", sub + "/F_roll", ...
                "Value", sprintf("%g*%g*%g", Crr, mVeh, g), "Position", [100, 125, 170, 155]);
            add_block("simulink/Math Operations/Product", sub + "/vabs", ...
                "Inputs", "**", "Position", [220, 200, 250, 225]);
            add_block("simulink/Math Operations/Gain", sub + "/AeroCoeff", ...
                "Gain", sprintf("%g", 0.5*rho*Cd*area), "Position", [280, 200, 360, 225]);
            add_block("simulink/Sources/Constant", sub + "/road_grade_in", ...
                "Value", "road_grade_in", "Position", [100, 165, 170, 195]);
            add_block("simulink/Math Operations/Gain", sub + "/F_grade", ...
                "Gain", sprintf("%g*%g", mVeh, g), "Position", [560, 180, 640, 210]);

            add_line(sub, "Tin_in/1", "T_to_F_drive/1");
            add_line(sub, "Tin_in/1", "T_to_F_regen/1");
            add_line(sub, "Tin_in/1", "T_to_F/2");
            add_line(sub, "T_to_F_drive/1", "T_to_F/1");
            add_line(sub, "T_to_F_regen/1", "T_to_F/3");
            add_line(sub, "T_to_F/1", "NetF/1");
            add_line(sub, "F_roll/1", "NetF/2");
            add_line(sub, "AeroCoeff/1", "NetF/3");
            add_line(sub, "F_grade/1", "NetF/4");
            add_line(sub, "NetF/1", "1_m/1");
            add_line(sub, "1_m/1", "Int_v_raw/1");
            add_line(sub, "Int_v_raw/1", "v_out_mps/1");
            add_line(sub, "Int_v_raw/1", "vabs/1");   % v >= 0, so v*v is the drag term v*|v|
            add_line(sub, "Int_v_raw/1", "vabs/2");
            add_line(sub, "vabs/1", "AeroCoeff/1");
            add_line(sub, "road_grade_in/1", "F_grade/1");

            add_block("simulink/Math Operations/Gain", modelName + "/v_to_omega_m", ...
                "Gain", sprintf("%g/%g", gearRatio, Rw), "Position", [940, 170, 1030, 200]);
            add_block("simulink/Math Operations/Abs", modelName + "/Abs_omega", ...
                "Position", [1060, 170, 1090, 200]);
            add_block("simulink/Sources/Constant", modelName + "/omega_eps", ...
                "Value", "1e-3", "Position", [1060, 215, 1090, 245]);
            add_block("simulink/Math Operations/MinMax", modelName + "/Max_omega_eps", ...
                "Function", "max", "Inputs", "2", "Position", [1120, 175, 1170, 205]);
            add_block("simulink/Sources/Constant", modelName + "/Pmax_const", ...
                "Value", "Pmax", "Position", [1060, 120, 1120, 145]);
            add_block("simulink/Math Operations/Divide", modelName + "/P_over_omega", ...
                "Position", [1200, 155, 1250, 205]);
            add_block("simulink/Sources/Constant", modelName + "/Tmax_const", ...
                "Value", "Tmax", "Position", [1200, 110, 1250, 135]);
            add_block("simulink/Math Operations/MinMax", modelName + "/Min_Tavail", ...
                "Function", "min", "Inputs", "2", "Position", [1280, 150, 1330, 200]);
            % Motor speed limit: the available torque tapers linearly to zero
            % over the last 5 percent below omega_max, as a motor controller's
            % speed limiter does; a hard cut-off would chatter.
            add_block("simulink/Sources/Constant", modelName + "/omega_max_const", ...
                "Value", "omega_max", "Position", [1120, 250, 1170, 275]);
            add_block("simulink/Math Operations/Sum", modelName + "/omega_headroom", ...
                "Inputs", "+-", "Position", [1200, 225, 1230, 255]);
            add_block("simulink/Math Operations/Gain", modelName + "/taper_gain", ...
                "Gain", "1/(0.05*omega_max)", "Position", [1250, 225, 1290, 255]);
            add_block("simulink/Discontinuities/Saturation", modelName + "/taper_sat", ...
                "LowerLimit", "0", "UpperLimit", "1", "Position", [1300, 225, 1330, 255]);
            add_block("simulink/Math Operations/Product", modelName + "/T_avail_limited", ...
                "Position", [1340, 160, 1360, 200]);
            add_block("simulink/Sources/Constant", modelName + "/ALLOW_REGEN", ...
                "Value", "ALLOW_REGEN", "Position", [980, 25, 1110, 55]);
            add_block("simulink/Sources/Constant", modelName + "/Tmin_no_regen", ...
                "Value", "0", "Position", [1200, 25, 1250, 55]);
            add_block("simulink/Sources/Constant", modelName + "/Tmin_regen", ...
                "Value", "-Tregen", "Position", [1200, 65, 1250, 95]);
            add_block("simulink/Signal Routing/Switch", modelName + "/Tmin_switch", ...
                "Criteria", "u2 ~= 0", "Threshold", "0.5", "Position", [1280, 35, 1330, 95]);
            add_block("simulink/Discontinuities/Saturation Dynamic", modelName + "/Sat_Dynamic", ...
                "Position", [1360, 95, 1420, 155]);
            add_block("simulink/Math Operations/Gain", modelName + "/ms_to_kph", ...
                "Gain", "3.6", "Position", [1460, 80, 1510, 110]);
            add_block("simulink/Math Operations/Gain", modelName + "/vref_ms_to_kph", ...
                "Gain", "3.6", "Position", [245, 15, 295, 45]);

            add_block("simulink/Sinks/To Workspace", modelName + "/Tin_applied", ...
                "VariableName", "Tin_applied", "SaveFormat", "Timeseries", "Position", [1450, 20, 1570, 50]);
            add_block("simulink/Sinks/To Workspace", modelName + "/v_sim_kph_out", ...
                "VariableName", "v_sim_kph_out", "SaveFormat", "Timeseries", "Position", [1540, 80, 1660, 110]);
            add_block("simulink/Sinks/To Workspace", modelName + "/v_ref_kph_out", ...
                "VariableName", "v_ref_kph_out", "SaveFormat", "Timeseries", "Position", [310, 10, 430, 40]);
            add_block("simulink/Sinks/To Workspace", modelName + "/omega_m_out", ...
                "VariableName", "omega_m_out", "SaveFormat", "Timeseries", "Position", [1450, 120, 1570, 150]);
            add_block("simulink/Sinks/To Workspace", modelName + "/T_avail_out", ...
                "VariableName", "T_avail_out", "SaveFormat", "Timeseries", "Position", [1450, 160, 1570, 190]);
            add_block("simulink/Sinks/To Workspace", modelName + "/T_cmd_pre_env_out", ...
                "VariableName", "T_cmd_pre_env_out", "SaveFormat", "Timeseries", "Position", [1450, 200, 1570, 230]);

            ph = @(blockName) get_param(modelName + "/" + blockName, "PortHandles");
            add_line(modelName, ph("Drive Cycle Input").Outport(1), ph("kmh_to_ms").Inport(1));
            add_line(modelName, ph("kmh_to_ms").Outport(1), ph("Error Sum").Inport(1));
            add_line(modelName, ph("Vehicle Dynamics").Outport(1), ph("Error Sum").Inport(2));
            add_line(modelName, ph("Error Sum").Outport(1), ph("PID Controller").Inport(1));
            add_line(modelName, ph("PID Controller").Outport(1), ph("ModeSwitch").Inport(1));
            add_line(modelName, ph("CASE_MODE").Outport(1), ph("ModeSwitch").Inport(2));
            add_line(modelName, ph("Topen_const").Outport(1), ph("ModeSwitch").Inport(3));
            add_line(modelName, ph("ModeSwitch").Outport(1), ph("Torque Actuator").Inport(1));
            add_line(modelName, ph("Torque Actuator").Outport(1), ph("Torque Rate Limiter").Inport(1));
            add_line(modelName, ph("Vehicle Dynamics").Outport(1), ph("v_to_omega_m").Inport(1));
            add_line(modelName, ph("v_to_omega_m").Outport(1), ph("Abs_omega").Inport(1));
            add_line(modelName, ph("Abs_omega").Outport(1), ph("Max_omega_eps").Inport(1));
            add_line(modelName, ph("omega_eps").Outport(1), ph("Max_omega_eps").Inport(2));
            add_line(modelName, ph("Pmax_const").Outport(1), ph("P_over_omega").Inport(1));
            add_line(modelName, ph("Max_omega_eps").Outport(1), ph("P_over_omega").Inport(2));
            add_line(modelName, ph("Tmax_const").Outport(1), ph("Min_Tavail").Inport(1));
            add_line(modelName, ph("P_over_omega").Outport(1), ph("Min_Tavail").Inport(2));
            % The switch passes input 1 when ALLOW_REGEN ~= 0, so that input is
            % the regen floor -Tregen; input 3 is the no-regen floor of zero.
            add_line(modelName, ph("Tmin_regen").Outport(1), ph("Tmin_switch").Inport(1));
            add_line(modelName, ph("ALLOW_REGEN").Outport(1), ph("Tmin_switch").Inport(2));
            add_line(modelName, ph("Tmin_no_regen").Outport(1), ph("Tmin_switch").Inport(3));
            add_line(modelName, ph("omega_max_const").Outport(1), ph("omega_headroom").Inport(1));
            add_line(modelName, ph("Abs_omega").Outport(1), ph("omega_headroom").Inport(2));
            add_line(modelName, ph("omega_headroom").Outport(1), ph("taper_gain").Inport(1));
            add_line(modelName, ph("taper_gain").Outport(1), ph("taper_sat").Inport(1));
            add_line(modelName, ph("Min_Tavail").Outport(1), ph("T_avail_limited").Inport(1));
            add_line(modelName, ph("taper_sat").Outport(1), ph("T_avail_limited").Inport(2));
            % Saturation Dynamic ports are (1) up, (2) u, (3) lo: the available
            % torque is the ceiling, the command is the signal, the regen
            % floor is the lower limit.
            add_line(modelName, ph("T_avail_limited").Outport(1), ph("Sat_Dynamic").Inport(1));
            add_line(modelName, ph("Torque Rate Limiter").Outport(1), ph("Sat_Dynamic").Inport(2));
            add_line(modelName, ph("Tmin_switch").Outport(1), ph("Sat_Dynamic").Inport(3));
            add_line(modelName, ph("Sat_Dynamic").Outport(1), ph("Vehicle Dynamics").Inport(1));
            add_line(modelName, ph("Sat_Dynamic").Outport(1), ph("Tin_applied").Inport(1));
            add_line(modelName, ph("Torque Rate Limiter").Outport(1), ph("T_cmd_pre_env_out").Inport(1));
            add_line(modelName, ph("T_avail_limited").Outport(1), ph("T_avail_out").Inport(1));
            add_line(modelName, ph("v_to_omega_m").Outport(1), ph("omega_m_out").Inport(1));
            add_line(modelName, ph("Vehicle Dynamics").Outport(1), ph("ms_to_kph").Inport(1));
            add_line(modelName, ph("ms_to_kph").Outport(1), ph("v_sim_kph_out").Inport(1));
            add_line(modelName, ph("kmh_to_ms").Outport(1), ph("vref_ms_to_kph").Inport(1));
            add_line(modelName, ph("vref_ms_to_kph").Outport(1), ph("v_ref_kph_out").Inport(1));
        end

    end

    methods (Static, Access = private)
        function styleReportAxes(ax)
            % Plain report look: serif text, black frame, light grid.
            set(ax, "FontName", SimDriveCore.PlotFont, "FontSize", 11, ...
                "Box", "on", "LineWidth", 0.75, "XColor", "k", "TickDir", "in", ...
                "GridColor", [0.8 0.8 0.8], "GridAlpha", 0.6);
            grid(ax, "on");
            ax.Title.FontWeight = "normal";
        end

    end
end
