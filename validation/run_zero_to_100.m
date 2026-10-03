%% 0-100 km/h Acceleration Validation
% Edit the car numbers in this section. The script reports only the
% full-throttle 0-100 km/h time, plus plots for inspection.

if ~exist("makePlots", "var")
    makePlots = true;
end
clc;

%% Student-editable car inputs

car.Name = "Representative rear-wheel-drive passenger EV course baseline";
car.VehicleMass_kg = 1610;
car.RotationalMassAllowance_kg = 94.8006;
car.WheelRadius_m = 0.334;
car.GearRatio = 9.0;
car.DrivetrainEfficiency = 0.97;
car.MotorMaxTorque_Nm = 350;
car.MotorMaxPower_kW = 210;
car.DragCoefficient = 0.23;
car.FrontalArea_m2 = 2.22;
car.RollingResistance = 0.010;
car.AirDensity_kgpm3 = 1.1769;
car.RoadGrade_deg = 0;

targetSpeed_kph = 100;
dt_s = 0.001;
maxTime_s = 30;

%% Run validation

[time_s, speed_kph, motorTorque_Nm, motorPower_kW, zeroTo100Time_s] = ...
    simulateZeroTo100(car, targetSpeed_kph, dt_s, maxTime_s);

fprintf("\n0-100 km/h validation: %s\n", car.Name);
fprintf("  Effective mass = %.1f kg\n", car.VehicleMass_kg + car.RotationalMassAllowance_kg);
if isnan(zeroTo100Time_s)
    fprintf("  0-100 km/h time: not reached within %.1f s\n", maxTime_s);
else
    fprintf("  0-100 km/h time = %.2f s\n", zeroTo100Time_s);
end

validationSummary = table(car.Name, zeroTo100Time_s, ...
    speed_kph(end), max(motorPower_kW), max(motorTorque_Nm), ...
    'VariableNames', {'Vehicle','ZeroTo100_s','FinalSpeed_kph','PeakMotorPower_kW','PeakMotorTorque_Nm'});
disp(validationSummary)

if makePlots
    figure("Name", "0-100 km/h validation");
    tiledlayout(3, 1);

    nexttile;
    plot(time_s, speed_kph, "LineWidth", 1.5);
    hold on;
    yline(targetSpeed_kph, "--", "100 km/h");
    hold off;
    grid on;
    xlabel("Time [s]");
    ylabel("Speed [km/h]");

    nexttile;
    plot(time_s, motorTorque_Nm, "LineWidth", 1.5);
    grid on;
    xlabel("Time [s]");
    ylabel("Motor torque [N·m]");

    nexttile;
    plot(time_s, motorPower_kW, "LineWidth", 1.5);
    grid on;
    xlabel("Time [s]");
    ylabel("Motor power [kW]");
end

function [time_s, speed_kph, motorTorque_Nm, motorPower_kW, zeroTo100Time_s] = ...
        simulateZeroTo100(car, targetSpeed_kph, dt_s, maxTime_s)

    validateCarInputs(car, targetSpeed_kph, dt_s, maxTime_s);

    g = 9.81;
    targetSpeed_mps = targetSpeed_kph / 3.6;
    motorMaxPower_W = car.MotorMaxPower_kW * 1000;
    effectiveMass_kg = car.VehicleMass_kg + car.RotationalMassAllowance_kg;
    roadGrade = deg2rad(car.RoadGrade_deg);

    numSteps = floor(maxTime_s/dt_s) + 1;
    time_s = (0:numSteps-1)' * dt_s;
    speed_mps = zeros(numSteps, 1);
    motorTorque_Nm = zeros(numSteps, 1);
    motorPower_kW = zeros(numSteps, 1);

    omegaBase_radps = motorMaxPower_W / car.MotorMaxTorque_Nm;

    for k = 1:numSteps-1
        omegaMotor_radps = speed_mps(k) / car.WheelRadius_m * car.GearRatio;
        if omegaMotor_radps <= omegaBase_radps
            torqueAvailable_Nm = car.MotorMaxTorque_Nm;
        else
            torqueAvailable_Nm = motorMaxPower_W / max(omegaMotor_radps, eps);
        end

        tractiveForce_N = torqueAvailable_Nm * car.GearRatio * ...
            car.DrivetrainEfficiency / car.WheelRadius_m;
        aerodynamicDrag_N = 0.5 * car.AirDensity_kgpm3 * car.DragCoefficient * ...
            car.FrontalArea_m2 * speed_mps(k)^2;
        % Road loads act on the true vehicle weight; only the acceleration sees
        % the effective mass (vehicle + reflected rotational inertia).
        rollingResistance_N = car.VehicleMass_kg * g * car.RollingResistance * cos(roadGrade);
        gradeResistance_N = car.VehicleMass_kg * g * sin(roadGrade);
        netForce_N = tractiveForce_N - aerodynamicDrag_N - rollingResistance_N - gradeResistance_N;
        acceleration_mps2 = netForce_N / effectiveMass_kg;

        speed_mps(k+1) = max(0, speed_mps(k) + acceleration_mps2 * dt_s);
        motorTorque_Nm(k) = torqueAvailable_Nm;
        motorPower_kW(k) = torqueAvailable_Nm * omegaMotor_radps / 1000;
    end

    motorTorque_Nm(end) = motorTorque_Nm(end-1);
    motorPower_kW(end) = motorPower_kW(end-1);
    speed_kph = speed_mps * 3.6;

    zeroTo100Time_s = NaN;
    crossingIndex = find(speed_mps >= targetSpeed_mps, 1, "first");
    if ~isempty(crossingIndex) && crossingIndex > 1
        t0 = time_s(crossingIndex - 1);
        t1 = time_s(crossingIndex);
        v0 = speed_mps(crossingIndex - 1);
        v1 = speed_mps(crossingIndex);
        zeroTo100Time_s = t0 + (targetSpeed_mps - v0) * (t1 - t0) / (v1 - v0);
    end
end

function validateCarInputs(car, targetSpeed_kph, dt_s, maxTime_s)
    requiredFields = ["VehicleMass_kg", "RotationalMassAllowance_kg", "WheelRadius_m", ...
        "GearRatio", "DrivetrainEfficiency", "MotorMaxTorque_Nm", "MotorMaxPower_kW", ...
        "DragCoefficient", "FrontalArea_m2", "RollingResistance", "AirDensity_kgpm3", ...
        "RoadGrade_deg"];

    for fieldName = requiredFields
        if ~isfield(car, fieldName)
            error("EVGearbox:Validation:MissingCarInput", "Missing car.%s.", fieldName);
        end
    end

    positiveValues = [car.VehicleMass_kg, car.WheelRadius_m, car.GearRatio, ...
        car.DrivetrainEfficiency, car.MotorMaxTorque_Nm, car.MotorMaxPower_kW, ...
        car.FrontalArea_m2, car.AirDensity_kgpm3, targetSpeed_kph, dt_s, maxTime_s];
    if any(~isfinite(positiveValues)) || any(positiveValues <= 0)
        error("EVGearbox:Validation:InvalidCarInput", ...
            "Mass, wheel radius, gear ratio, efficiency, motor limits, area, air density, target speed, dt, and max time must be positive finite values.");
    end

    nonnegativeValues = [car.RotationalMassAllowance_kg, car.DragCoefficient, car.RollingResistance];
    if any(~isfinite(nonnegativeValues)) || any(nonnegativeValues < 0)
        error("EVGearbox:Validation:InvalidCarInput", ...
            "Rotational mass allowance, drag coefficient, and rolling resistance must be nonnegative finite values.");
    end
end
