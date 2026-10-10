function [train, problems] = buildGearTrain(options)
%BUILDGEARTRAIN Geometry of the two-stage helical reduction.
%   train = BUILDGEARTRAIN() returns the default course gear train: stage 1
%   20:60 at m_n = 4 mm, stage 2 20:60 at m_n = 6 mm, both helical at
%   psi = 20 deg and phi_n = 20 deg, G = 9.
%
%   [train, problems] = BUILDGEARTRAIN(Name=Value) builds any other train.
%   PROBLEMS is a string array of every reason the train cannot be rated by
%   the Shigley procedure the course uses; it is empty for a valid train.
%   With one output, an invalid train raises an error instead.
%
%   Stage 1 is the primary reduction (motor pinion N1 -> intermediate gear
%   N2). Stage 2 is the final drive (intermediate pinion N3 -> output gear
%   N4, which carries the differential). All three shafts lie in one plane,
%   so the stage-1 and stage-2 meshes sit on opposite sides of the
%   intermediate shaft.
%
%   Validity rules, each traced to Shigley 11e:
%     * phi_n = 20 deg only: the Shigley Ch. 14 helical J' chart is drawn
%       for 20 deg.
%     * Normal module on the Shigley Ch. 13 list of preferred modules.
%     * Pinion teeth at or above the helical interference minimum,
%       Shigley Ch. 13 interference relation, full depth (k = 1), for its actual mate.
%     * Tooth counts from 20 to 500 and helix angles from 5 to 35 deg, the
%       printed domain of the Ch. 14 J charts that the key reads J from.

    arguments
        options.N1 (1,1) double = 20
        options.N2 (1,1) double = 60
        options.N3 (1,1) double = 20
        options.N4 (1,1) double = 60
        options.m_n1_mm (1,1) double = 4
        options.m_n2_mm (1,1) double = 6
        options.psi1_deg (1,1) double = 20
        options.psi2_deg (1,1) double = 20
        options.phi_n_deg (1,1) double = 20
    end

    problems = strings(0, 1);
    teeth = [options.N1 options.N2 options.N3 options.N4];
    if any(teeth ~= round(teeth)) || any(teeth < 1)
        problems(end+1) = "Tooth counts must be positive whole numbers.";
    end
    if options.phi_n_deg ~= 20
        problems(end+1) = "Normal pressure angle is locked at 20 deg: the Shigley Ch. 14 J chart covers 20 deg only.";
    end

    preferred = preferredModulesMm();
    stageModules = [options.m_n1_mm options.m_n2_mm];
    for s = 1:2
        if ~any(abs(preferred - stageModules(s)) < 1e-9)
            problems(end+1) = sprintf( ...
                "Stage %d module %.4g mm is not a Shigley Ch. 13 preferred module (%s mm).", ...
                s, stageModules(s), strjoin(string(preferred), ", ")); %#ok<AGROW>
        end
    end

    stageTeeth = [options.N1 options.N2; options.N3 options.N4];
    stagePsi = [options.psi1_deg options.psi2_deg];
    phi_n = deg2rad(options.phi_n_deg);
    stage = struct([]);
    for s = 1:2
        Np = stageTeeth(s,1);  Ng = stageTeeth(s,2);
        psi = deg2rad(stagePsi(s));
        m_n = stageModules(s)/1000;
        m_t = m_n/cos(psi);
        phi_t = atan(tan(phi_n)/cos(psi));
        stage(s).N_pinion = Np;
        stage(s).N_gear = Ng;
        stage(s).ratio = Ng/Np;
        stage(s).m_n = m_n;
        stage(s).m_t = m_t;
        stage(s).psi_deg = stagePsi(s);
        stage(s).psi = psi;
        stage(s).phi_n_deg = options.phi_n_deg;
        stage(s).phi_n = phi_n;
        stage(s).phi_t = phi_t;
        stage(s).phi_t_deg = rad2deg(phi_t);
        stage(s).d_pinion = Np*m_t;
        stage(s).d_gear = Ng*m_t;
        stage(s).center_distance = 0.5*(Np + Ng)*m_t;

        if Ng < Np
            problems(end+1) = sprintf("Stage %d is a step-up: the gear (%d) must have more teeth than the pinion (%d).", s, Ng, Np); %#ok<AGROW>
        end
        if stagePsi(s) < 5 || stagePsi(s) > 35
            problems(end+1) = sprintf("Stage %d helix angle %g deg is outside the Shigley Ch. 14 J charts, which print 5 to 35 deg.", s, stagePsi(s)); %#ok<AGROW>
        end
        if any([Np Ng] < 20 | [Np Ng] > 500)
            problems(end+1) = sprintf("Stage %d tooth counts must lie within the Shigley Ch. 14 J charts, which print 20 to 500 teeth.", s); %#ok<AGROW>
        end
        % Shigley Ch. 13: smallest helical pinion that meshes with a gear
        % of ratio m = Ng/Np without interference, full-depth teeth (k = 1).
        mG = Ng/max(Np, 1);
        s2 = sin(phi_t)^2;
        Nmin = 2*cos(psi)/((1 + 2*mG)*s2) * (mG + sqrt(mG^2 + (1 + 2*mG)*s2));
        stage(s).N_pinion_min = Nmin;
        if Np < Nmin
            problems(end+1) = sprintf( ...
                "Stage %d pinion has %d teeth; Shigley Ch. 13 needs at least %d to mesh with %d teeth at psi = %g deg without interference.", ...
                s, Np, ceil(Nmin), Ng, stagePsi(s)); %#ok<AGROW>
        end
    end

    train.stage = stage;
    train.G = stage(1).ratio * stage(2).ratio;
    train.phi_n_deg = options.phi_n_deg;
    train.mesh_layout = "in-line";   % all three shaft axes in one plane
    train.helix_hands = "same hand on both intermediate-shaft gears";   % Shigley Ch. 13, minimum thrust

    % Flat fields exactly as Design_Summary.mat stores them (lengths in m).
    train.summary = struct( ...
        'gear_ratio', train.G, 'i1', stage(1).ratio, 'i2', stage(2).ratio, ...
        'N1', stage(1).N_pinion, 'N2', stage(1).N_gear, ...
        'N3', stage(2).N_pinion, 'N4', stage(2).N_gear, ...
        'm_n1', stage(1).m_n, 'm_n2', stage(2).m_n, ...
        'm_t1', stage(1).m_t, 'm_t2', stage(2).m_t, ...
        'phi_n_deg', options.phi_n_deg, ...
        'phi_t1_deg', stage(1).phi_t_deg, 'phi_t2_deg', stage(2).phi_t_deg, ...
        'psi1_deg', stage(1).psi_deg, 'psi2_deg', stage(2).psi_deg, ...
        'd1', stage(1).d_pinion, 'd2', stage(1).d_gear, ...
        'd3', stage(2).d_pinion, 'd4', stage(2).d_gear);

    if nargout < 2 && ~isempty(problems)
        error("SimDrive:GearTrain:Invalid", "%s", strjoin(problems, newline));
    end
end

function m = preferredModulesMm()
    % Shigley 11e Ch. 13 preferred modules (first choice).
    m = [1 1.25 1.5 2 2.5 3 4 5 6 8 10 12 16 20 25 32 40 50];
end
