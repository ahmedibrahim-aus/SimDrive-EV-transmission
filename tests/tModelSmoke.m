classdef tModelSmoke < matlab.unittest.TestCase
    %TMODELSMOKE  Build the Simulink EV model and run a short simulation.
    %   Verifies the programmatic model builds, simulates, and produces
    %   physically sane outputs (finite, torque within the +/-Tmax envelope,
    %   speed non-negative). Requires Simulink.

    properties
        RepoRoot
        ModelName = 'EV_SmokeTest_Model';
    end

    methods (TestClassSetup)
        function setupPath(tc)
            tc.RepoRoot = fileparts(fileparts(mfilename('fullpath')));
            instDir = fullfile(tc.RepoRoot, 'instructor');
            addpath(instDir);
            tc.addTeardown(@() rmpath(instDir));
        end
    end

    methods (Test, TestTags = {'Integration'})

        function dragRaceShortSimIsSane(tc)
            mn = tc.ModelName;
            tc.addTeardown(@() SimDriveCore.closeRuntimeModel(mn));

            % Runtime parameters the model blocks reference from the base workspace.
            Tmax = 350; Tregen = 150; Pmax = 210e3;
            assignin('base', 'Tmax', Tmax);
            assignin('base', 'Tregen', Tregen);
            assignin('base', 'Pmax', Pmax);
            assignin('base', 'omega_max', 16000*pi/30);
            assignin('base', 'Kp', 250); assignin('base', 'Ki', 20);
            assignin('base', 'Kd', 0);   assignin('base', 'Nf', 100);
            assignin('base', 'Ts_pid', 0.01); assignin('base', 'dt_sim', 0.001);
            assignin('base', 'tau_torque', 0.05);
            assignin('base', 'CASE_MODE', 0);        % open-loop full torque
            assignin('base', 'ALLOW_REGEN', 0);
            assignin('base', 'Topen_cmd', Tmax);
            assignin('base', 'road_grade_in', 0.0);  % flat
            assignin('base', 'drive_data', [0 0; 1 0]);

            % Build the model (mVeh, mEff, Cd, area, rho, Crr, g, Rw, G, eta, TsPid, dtSim, slew).
            SimDriveCore.createModelEVBlocks(mn, 1610, 1705, 0.23, 2.22, 1.18, ...
                0.01, 9.81, 0.334, 9.0, 0.97, 0.01, 0.001, 5000);
            tc.verifyTrue(bdIsLoaded(mn), 'model should be loaded after build');
            % Efficiency divides the regen force, multiplies the drive force.
            drive = str2num(get_param(mn + "/Vehicle Dynamics/T_to_F_drive", 'Gain')); %#ok<ST2NM>
            regen = str2num(get_param(mn + "/Vehicle Dynamics/T_to_F_regen", 'Gain')); %#ok<ST2NM>
            tc.verifyEqual(drive, 0.97*9.0/0.334, 'RelTol', 1e-9);
            tc.verifyEqual(regen, 9.0/(0.97*0.334), 'RelTol', 1e-9);

            set_param(mn, 'StopTime', '3');
            simout = sim(mn);

            T = simout.Tin_applied.Data(:);
            v = simout.v_sim_kph_out.Data(:);

            tc.verifyTrue(all(isfinite(T)), 'applied torque must be finite');
            tc.verifyTrue(all(isfinite(v)), 'speed must be finite');
            tc.verifyLessThanOrEqual(max(abs(T)), Tmax + 1e-6, 'torque within +/-Tmax envelope');
            tc.verifyGreaterThanOrEqual(min(v), -1e-6, 'speed saturates non-negative');
            tc.verifyGreaterThan(v(end), 0, 'car should accelerate under full drag torque');
        end

        function hillClimbSettlesOnTheMotorEnvelope(tc)
            % The hill-climb hand check solves the steady state against the
            % whole motor envelope: torque limit, power limit and the speed
            % limiter taper. 5 deg settles on the taper, 20 deg on the power
            % limit; both must match the simulation once settled.
            mn = tc.ModelName;
            tc.addTeardown(@() SimDriveCore.closeRuntimeModel(mn));
            Tmax = 350; Pmax = 210e3; wmax = 16000*pi/30; G = 9; Rw = 0.334; eta = 0.97;
            m = 1610; Crr = 0.01; rho = 1.18; Cd = 0.23; A = 2.22; g = 9.81;
            assignin('base', 'Tmax', Tmax); assignin('base', 'Tregen', 150);
            assignin('base', 'Pmax', Pmax); assignin('base', 'omega_max', wmax);
            assignin('base', 'Kp', 250); assignin('base', 'Ki', 20);
            assignin('base', 'Kd', 0);   assignin('base', 'Nf', 100);
            assignin('base', 'Ts_pid', 0.01); assignin('base', 'dt_sim', 0.001);
            assignin('base', 'tau_torque', 0.05);
            assignin('base', 'CASE_MODE', 0); assignin('base', 'ALLOW_REGEN', 0);
            assignin('base', 'Topen_cmd', Tmax); assignin('base', 'drive_data', [0 0; 1 0]);
            SimDriveCore.createModelEVBlocks(mn, m, 1705, Cd, A, rho, Crr, g, Rw, G, eta, ...
                0.01, 0.001, 5000);
            set_param(mn, 'StopTime', '60');
            T_avail = @(w) min(Tmax, Pmax./max(w, eps)) .* min(max((wmax - w)./(0.05*wmax), 0), 1);
            for theta = [5 20]
                assignin('base', 'road_grade_in', sind(theta));
                simout = sim(mn);
                T = simout.Tin_applied.Data(:);
                T_sim = mean(T(round(0.6*numel(T))+1:end));
                road = @(v) m*g*sind(theta) + Crr*m*g + 0.5*rho*Cd*A*v.^2;
                v = fzero(@(v) eta*G*T_avail(G*v/Rw)/Rw - road(v), [0 wmax*Rw/G]);
                tc.verifyEqual(T_sim, T_avail(G*v/Rw), 'RelTol', 0.02, ...
                    sprintf('Hill climb at %d deg does not settle on the motor envelope.', theta));
            end
        end

        function ftpTorqueIsPhysicallyPlausible(tc)
            % Guards the three v3 model bugs: the envelope limiter wired as a
            % relay (Saturation Dynamic ports up/u/lo crossed), the inverted
            % regen switch, and the speed integrator winding below zero at
            % stops. Each produced full-torque chatter or launches that the
            % FTP-75 schedule never asks for.
            mn = tc.ModelName;
            tc.addTeardown(@() SimDriveCore.closeRuntimeModel(mn));
            [t, vKph] = SimDriveCore.loadFtp75SpeedTrace();   % built-in EPA FTP-75
            Tmax = 350; Tregen = 150; Pmax = 210e3;
            mVeh = 1610; mEff = 1705; Rw = 0.334; G = 9; eta = 0.97; rho = 1.18;
            assignin('base', 'Tmax', Tmax); assignin('base', 'Tregen', Tregen);
            assignin('base', 'Pmax', Pmax);
            assignin('base', 'omega_max', 16000*pi/30);
            assignin('base', 'Kp', 250); assignin('base', 'Ki', 20);
            assignin('base', 'Kd', 0);   assignin('base', 'Nf', 100);
            assignin('base', 'Ts_pid', 0.01); assignin('base', 'dt_sim', 0.001);
            assignin('base', 'tau_torque', 0.12);
            assignin('base', 'CASE_MODE', 1); assignin('base', 'ALLOW_REGEN', 1);
            assignin('base', 'Topen_cmd', 0); assignin('base', 'road_grade_in', 0.0);
            assignin('base', 'drive_data', [t vKph]);
            SimDriveCore.createModelEVBlocks(mn, mVeh, mEff, 0.23, 2.22, rho, ...
                0.01, 9.81, Rw, G, eta, 0.01, 0.001, 5000);
            set_param(mn, 'StopTime', num2str(t(end)));
            simout = sim(mn);

            T = simout.Tin_applied.Data(:);
            Tcmd = simout.T_cmd_pre_env_out.Data(:);
            Tavail = simout.T_avail_out.Data(:);
            v = simout.v_sim_kph_out.Data(:);
            vref = simout.v_ref_kph_out.Data(:);

            % Torque the schedule itself requires, with 30 percent headroom.
            aRefMax = max(diff(vKph/3.6)./diff(t));
            vMax = max(vKph)/3.6;
            demand = (mEff*aRefMax + 0.01*mVeh*9.81 + 0.5*rho*0.23*2.22*vMax^2)*Rw/(G*eta);
            tc.verifyLessThan(max(T), 1.3*demand, ...
                sprintf('FTP peak torque %.0f N·m exceeds what the cycle demands (%.0f N·m).', max(T), demand));
            tc.verifyEqual(T, min(max(Tcmd, -Tregen), Tavail), 'AbsTol', 1e-9, ...
                'Applied torque must be the command clipped to the envelope.');
            tc.verifyLessThan(min(T), -20, 'The car must regen-brake on the FTP decelerations.');
            tc.verifyLessThan(sqrt(mean((vref - v).^2)), 1.5, 'FTP tracking RMS error too large.');
        end

    end
end
