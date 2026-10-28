classdef InstructorApp < handle
%INSTRUCTORAPP  SimDrive instructor dashboard.
%  app = InstructorApp();
%  app = InstructorApp(OutputRoot=folder) writes exports, the student
%  package and the release ZIP under folder (default: the repository root).
%  Needs MATLAB R2025b+, Simulink and the Signal Processing Toolbox. The
%  EPA FTP-75 schedule is built in (ftp75Schedule.m); another speed trace is optional.

    properties (Constant, Access = private)
        package_name = "SimDrive_Student_Package_v1.0.0"   % as buildStudentPackage.m
        runtime_model = 'SimDrive_LoadCases_RuntimeModel'
    end

    properties (Access = private)

        UIFigure

        % Light theme colors.
        C_fig     = [0.94 0.94 0.94]   % background
        C_panel   = [0.97 0.97 0.97]   % side panels
        C_surface = [0.92 0.92 0.92]   % inset boxes
        C_card    = [1 1 1]            % cards, fields, plot area
        C_hdr     = [0.90 0.90 0.90]   % header and status bar
        C_hair    = [0.80 0.80 0.80]   % separator line, grid
        C_accent  = [0.05 0.30 0.55]   % run button, envelope
        C_amber   = [0.65 0.33 0]      % busy, speed traces
        C_green   = [0 0.42 0.15]      % done
        C_red     = [0.70 0.10 0.10]   % error
        C_tpri    = [0.10 0.10 0.10]   % text
        C_tsec    = [0.35 0.35 0.35]   % dim text
        C_emblue  = [0.05 0.30 0.55]   % torque traces

        ef_mass, ef_Cd, ef_A, ef_Crr
        ef_Tmax, ef_Pmax_kW, ef_nmax_rpm, ef_Tregen
        ef_I_motor
        ax_envelope
        ef_gear_ratio, ef_eta_dt
        ef_wheel_R, dd_tire_profile
        ef_T_ambient
        ef_N1, ef_N2, ef_N3, ef_N4, ef_mn1_mm, ef_mn2_mm, cb_mn2_auto
        ef_psi1_deg, ef_psi2_deg, lbl_gear_msg, lbl_train_flow

        cb_FTP, cb_Hill, cb_Drag
        ef_theta_hill, ef_stop_drag, ef_stop_hill
        ef_ftp_path, dd_ftp_units, btn_browse

        tg_results
        tab_FTP, tab_Hill, tab_Drag, tab_summary, tab_key
        ax_FTP, ax_Hill, ax_Drag
        tbl_design, tbl_key
        btn_run, btn_export, lbl_status

        ax_schematic
        h_case_text
        lbl_Tmean_v, lbl_Talt_v, lbl_bearing_v
        lbl_Tpeak_v, lbl_dist_v, lbl_Tss_v

        anim_timer   = []
        anim_tick    = 0
        anim_period  = 0.10
        anim_running = false
        anim_mode    = 'idle'
        pv3d         = []

        ds_results     = []
        run_parameters = struct()
        run_ok         = false
        T_equiv_period = 120
        output_root
        layout_base_size = [1920 1040]
        text_scale = 1.2   % all text relative to the design sizes in build_ui
        font_scale = 1     % current text scale, set by resize_layout, used by plots drawn later
        layout_items = struct('Handle', {}, 'Position', {}, 'FontSize', {}, 'LineWidth', {})
        layout_ready = false
    end

    methods (Access = public)

        function app = InstructorApp(options)
            arguments
                options.OutputRoot (1,1) string = ""
            end
            app.output_root = options.OutputRoot;
            if strlength(app.output_root) == 0
                app.output_root = string(fileparts(fileparts(mfilename('fullpath'))));
            end
            if ~isfolder(app.output_root)
                [created, message] = mkdir(app.output_root);
                if ~created
                    error('SimDrive:OutputRoot', 'Cannot create output folder: %s', message);
                end
            end
            listing = dir(fullfile(app.output_root, '.'));   % absolute path of OutputRoot
            app.output_root = listing(1).folder;
            SimDriveCore.closeRuntimeModel(app.runtime_model);
            app.build_ui();
            app.UIFigure.Visible = 'on';
            drawnow limitrate;
            app.draw_car_schematic();
            app.refresh_gear_train();
            set(findall(app.UIFigure, '-property', 'FontName'), 'FontName', SimDriveCore.PlotFont);
            app.capture_layout();
            app.UIFigure.SizeChangedFcn = @(~,~) app.resize_layout();
            app.maximize_window();
        end

        function delete(app)
            app.stop_animation(false);
            if ~isempty(app.UIFigure) && isvalid(app.UIFigure)
                delete(app.UIFigure);
            end
        end

    end

    methods (Access = private)   % UI construction and layout

        function build_ui(app)
            app.UIFigure = uifigure( ...
                'Name',     'SimDrive: EV Transmission Design', ...
                'Position', [10 10 1920 1040], ...
                'Visible',  'off', ...
                'Color',    app.C_fig, ...
                'AutoResizeChildren', 'off', ...
                'Resize',   'on');
            % MATLAB draws its own chrome for tab strips, dropdowns, and
            % scrollbars. Only the figure theme reaches those.
            app.UIFigure.Theme = 'light';
            set(app.UIFigure, 'DefaultAxesFontName', SimDriveCore.PlotFont, ...
                'DefaultTextFontName', SimDriveCore.PlotFont);

            hdr = uipanel(app.UIFigure, ...
                'Position',        [0 1006 1920 34], ...
                'BackgroundColor', app.C_hdr, ...
                'BorderType',      'none');
            % Hairline under the header
            uipanel(app.UIFigure, 'Position', [0 1005 1920 1], ...
                'BackgroundColor', app.C_hair, 'BorderType','none');
            uilabel(hdr, ...
                'Text',            'SimDrive: EV Transmission Design', ...
                'Position',        [18 8 520 20], ...
                'FontColor',       app.C_tpri, ...
                'FontSize',        13, ...
                'FontWeight',      'bold', ...
                'BackgroundColor', app.C_hdr);

            app.build_left_panel();

            app.ax_schematic = uiaxes(app.UIFigure, ...
                'Position', [324 520 620 382], ...
                'Color',    app.C_fig, ...
                'XColor',   'none', ...
                'YColor',   'none', ...
                'ZColor',   'none', ...
                'Box',      'off');
            app.ax_schematic.Toolbar.Visible = 'off';
            disableDefaultInteractivity(app.ax_schematic);
            app.build_schematic_overlay();

            app.build_stat_cards();
            app.build_right_panel();
            app.build_results_panel();
            app.reset_results();

            sbar = uipanel(app.UIFigure, ...
                'Position',        [0 0 1920 40], ...
                'BackgroundColor', app.C_hdr, ...
                'BorderType',      'none');
            app.lbl_status = uilabel(sbar, ...
                'Text',            'Ready.', ...
                'Position',        [16 8 1880 24], ...
                'FontColor',       app.C_tsec, ...
                'FontSize',        11, ...
                'BackgroundColor', app.C_hdr);
        end

        function build_left_panel(app)
            pnl = uipanel(app.UIFigure, ...
                'Position',        [12 292 300 702], ...
                'BackgroundColor', app.C_panel, ...
                'BorderType',      'none');

            y = 672;
            dy = 30;    % row spacing
            sg = 34;    % gap between sections (must clear 24px field + title)

            app.mk_title(pnl, 8, y, 260, 'VEHICLE'); y = y - dy;
            app.ef_mass      = app.mk_param(pnl, 8, y, 'Mass [kg]',          1610, [0 Inf], 'off'); app.ef_mass.Tag = 'mass'; y = y - dy;
            app.ef_Cd        = app.mk_param(pnl, 8, y, 'C<sub>d</sub> [-]',            0.23, [0 Inf]); app.ef_Cd.Tag = 'Cd'; y = y - dy;
            app.ef_A         = app.mk_param(pnl, 8, y, 'Frontal area [m<sup>2</sup>]', 2.22, [0 Inf], 'off'); app.ef_A.Tag = 'A'; y = y - dy;
            app.ef_Crr       = app.mk_param(pnl, 8, y, 'C<sub>rr</sub> [-]',      0.01, [0 Inf]); app.ef_Crr.Tag = 'Crr'; y = y - dy;
            app.ef_T_ambient = app.mk_param(pnl, 8, y, 'T<sub>ambient</sub> [°C]',    25, [-40 60]); app.ef_T_ambient.Tag = 'T_ambient'; y = y - sg;

            app.mk_title(pnl, 8, y, 260, 'WHEEL / TIRE'); y = y - dy;
            app.ef_wheel_R = app.mk_param(pnl, 8, y, 'Tire radius R<sub>w</sub> [m]', 0.334, [0 Inf], 'off'); app.ef_wheel_R.Tag = 'wheel_R'; y = y - dy;
            uilabel(pnl, 'Text', 'Tire profile', ...
                'Position', [8 y 105 22], 'FontColor', app.C_tsec, ...
                'FontSize', 10.5, 'BackgroundColor', app.C_panel);
            app.dd_tire_profile = uidropdown(pnl, ...
                'Items',     {'Low profile (35-40%)', 'Standard (45-55%)', 'High profile (60-70%)'}, ...
                'ItemsData', {'low', 'standard', 'high'}, ...
                'Value',     'standard', ...
                'Position',  [118 y 160 24], ...
                'BackgroundColor', app.C_card, 'FontColor', app.C_tpri, 'FontSize', 10);
            y = y - sg;

            app.mk_title(pnl, 8, y, 260, 'MOTOR + DRIVETRAIN'); y = y - dy;
            app.ef_Tmax       = app.mk_param(pnl, 8, y, 'T<sub>max</sub> [N·m]',    350, [0 Inf], 'off'); app.ef_Tmax.Tag = 'Tmax'; y = y - dy;
            app.ef_Pmax_kW    = app.mk_param(pnl, 8, y, 'P<sub>max</sub> [kW]',     210, [0 Inf], 'off'); app.ef_Pmax_kW.Tag = 'Pmax_kW'; y = y - dy;
            app.ef_nmax_rpm   = app.mk_param(pnl, 8, y, 'n<sub>max</sub> [rpm]',   16000, [0 Inf], 'off'); app.ef_nmax_rpm.Tag = 'nmax_rpm'; y = y - dy;
            app.ef_nmax_rpm.ValueDisplayFormat = '%.0f';
            app.ef_Tregen     = app.mk_param(pnl, 8, y, 'T<sub>regen</sub> [N·m]',   150, [0 Inf]); app.ef_Tregen.Tag = 'Tregen'; y = y - dy;
            app.ef_I_motor    = app.mk_param(pnl, 8, y, 'I<sub>motor</sub> [kg·m<sup>2</sup>]',0.05, [0 Inf]); app.ef_I_motor.Tag = 'I_motor'; y = y - dy;
            app.ef_gear_ratio = app.mk_param(pnl, 8, y, 'Gear ratio G (from teeth)', 9.0, [0 Inf], 'off'); y = y - dy;
            app.ef_gear_ratio.Editable = 'off';
            app.ef_eta_dt     = app.mk_param(pnl, 8, y, 'Efficiency &eta;',  0.97, [0 1], 'off'); app.ef_eta_dt.Tag = 'eta_dt'; y = y - sg;

            app.ef_Tmax.ValueChangedFcn       = @(~,~) app.refresh_envelope();
            app.ef_Pmax_kW.ValueChangedFcn    = @(~,~) app.refresh_envelope();
            app.ef_nmax_rpm.ValueChangedFcn   = @(~,~) app.refresh_envelope();
            app.ef_Tregen.ValueChangedFcn     = @(~,~) app.refresh_envelope();
            app.ef_gear_ratio.Tag = 'GearRatio';
            app.ef_wheel_R.ValueChangedFcn    = @(~,~) app.refresh_envelope();

            app.mk_title(pnl, 8, y, 260, 'ENVELOPE PREVIEW');
            ax_h = max(120, y - 22);
            app.ax_envelope = uiaxes(pnl, 'Position', [5 14 290 ax_h]);
            app.ax_envelope.Toolbar.Visible = 'off';
            disableDefaultInteractivity(app.ax_envelope);
        end

        function build_schematic_overlay(app)
            % Title, power-flow line, and the live readouts that sit over the
            % 3D view. set_schematic_case writes into these during a run.
            mk = @(x, y, w, txt, col, sz, wt, align) uilabel(app.UIFigure, ...
                'Text', txt, 'Position', [x y w 20], 'FontColor', col, ...
                'FontSize', sz, 'FontWeight', wt, 'BackgroundColor', 'none', ...
                'HorizontalAlignment', align);

            mk(342, 944, 520, 'Rear-wheel-drive EV powertrain', ...
                app.C_tpri, 13, 'bold', 'left');
            app.lbl_train_flow = mk(342, 924, 600, '', app.C_tsec, 11, 'normal', 'left');
            app.h_case_text = mk(342, 902, 460, '', app.C_accent, 11.5, 'bold', 'left');
        end

        function build_stat_cards(app)
            bg = uipanel(app.UIFigure, ...
                'Position',        [324 292 1032 206], ...
                'BackgroundColor', app.C_fig, ...
                'BorderType',      'none');

            cw = 330; ch = 90; gx = 12; gy = 10;

            % Tag suffix, title (TeX), unit, description.
            defs = { ...
                'T_mean_eq',    'T<sub>mean,eq</sub>',     'N·m', 'FTP-75 Goodman mean';
                'T_alt_eq',     'T<sub>alt,eq</sub>',      'N·m', 'FTP-75 Goodman alternating';
                'T_cubic_mean', 'T<sub>cubic mean</sub>',  'N·m', 'Bearing equivalent load';
                'T_peak',       'T<sub>peak</sub>',        'N·m', 'Drag race peak torque';
                'FTP distance', 'FTP-75 distance', 'km',  'Cycle distance';
                'T_steady',     'T<sub>steady</sub>',      'N·m', 'Hill climb sustained torque';
            };

            for i = 1:6
                col = mod(i-1, 3);
                row = floor((i-1) / 3);
                cx = 4 + col * (cw + gx);
                cy = bg.Position(4) - (row+1) * (ch + gy) + gy;
                card = uipanel(bg, ...
                    'Position',        [cx cy cw ch], ...
                    'BackgroundColor', app.C_card, ...
                    'BorderType',      'none');
                uilabel(card, 'Text', defs{i,2}, 'Interpreter', 'html', ...
                    'Position',        [18 62 cw-26 18], ...
                    'FontColor',       app.C_tsec, ...
                    'FontSize',        11, 'FontWeight', 'bold', ...
                    'BackgroundColor', app.C_card);
                val_lbl = uilabel(card, 'Text', '-', ...
                    'Position',        [18 22 cw-26 36], ...
                    'FontColor',       app.C_tpri, ...
                    'FontSize',        24, 'FontWeight', 'normal', ...
                    'BackgroundColor', app.C_card, 'Tag', ['Stat ' defs{i,1}]);
                uilabel(card, 'Text', [defs{i,3} '   ' defs{i,4}], ...
                    'Position',        [18 6 cw-26 16], ...
                    'FontColor',       app.C_tsec, ...
                    'FontSize',        10, ...
                    'BackgroundColor', app.C_card);
                switch i
                    case 1; app.lbl_Tmean_v   = val_lbl;
                    case 2; app.lbl_Talt_v    = val_lbl;
                    case 3; app.lbl_bearing_v = val_lbl;
                    case 4; app.lbl_Tpeak_v   = val_lbl;
                    case 5; app.lbl_dist_v    = val_lbl;
                    case 6; app.lbl_Tss_v     = val_lbl;
                end
            end
        end

        function build_right_panel(app)
            pnl = uipanel(app.UIFigure, ...
                'Position',        [1368 292 540 702], ...
                'BackgroundColor', app.C_panel, ...
                'BorderType',      'none');

            y  = 668;
            dy = 30;
            sg = 34;
            pw = 520;

            uibutton(pnl, 'push', ...
                'Text', 'Technical Reference', ...
                'Position', [10 y pw 28], ...
                'BackgroundColor', app.C_card, 'FontColor', app.C_tsec, ...
                'FontSize', 11, 'ButtonPushedFcn', @(~,~) app.show_help());
            y = y - dy - sg;

            app.mk_title(pnl, 10, y, pw, 'LOAD CASES'); y = y - dy;

            app.cb_Drag = uicheckbox(pnl, 'Text', 'Drag Race  (peak-load gear and shaft)', ...
                'Value', 1, 'Position', [14 y 260 22], ...
                'FontColor', app.C_tpri, 'FontSize', 11);
            uilabel(pnl, 'Text', 'Stop [s]:', 'Position', [290 y 60 22], ...
                'FontColor', app.C_tsec, 'FontSize', 10, 'BackgroundColor', app.C_panel);
            app.ef_stop_drag = uieditfield(pnl, 'numeric', 'Value', 35, 'Limits', [10 120], ...
                'Position', [354 y 50 24], 'BackgroundColor', app.C_card, ...
                'FontColor', app.C_tpri, 'FontSize', 11);
            y = y - dy;

            app.cb_Hill = uicheckbox(pnl, 'Text', 'Hill Climb  (validation check; shaft life extension)', ...
                'Value', 1, 'Position', [14 y 400 22], ...
                'FontColor', app.C_tpri, 'FontSize', 11);
            y = y - dy;

            uilabel(pnl, 'Text', 'Grade [°]:', 'Position', [30 y 70 22], ...
                'FontColor', app.C_tsec, 'FontSize', 10, 'BackgroundColor', app.C_panel);
            app.ef_theta_hill = uieditfield(pnl, 'numeric', 'Value', 20, 'Limits', [1 45], ...
                'Position', [105 y 52 24], 'BackgroundColor', app.C_card, ...
                'FontColor', app.C_tpri, 'FontSize', 11);
            uilabel(pnl, 'Text', 'Stop [s]:', 'Position', [180 y 60 22], ...
                'FontColor', app.C_tsec, 'FontSize', 10, 'BackgroundColor', app.C_panel);
            app.ef_stop_hill = uieditfield(pnl, 'numeric', 'Value', 60, 'Limits', [5 600], ...
                'Position', [245 y 52 24], 'BackgroundColor', app.C_card, ...
                'FontColor', app.C_tpri, 'FontSize', 11);
            y = y - dy;

            app.cb_FTP = uicheckbox(pnl, 'Text', 'FTP-75  (fatigue and bearing life)', ...
                'Value', 1, 'Position', [14 y 330 22], ...
                'FontColor', app.C_tpri, 'FontSize', 11);
            y = y - sg;

            app.mk_title(pnl, 10, y, pw, 'FTP-75 SPEED TRACE'); y = y - dy;
            % Empty means the built-in EPA FTP-75 schedule; Browse picks another
            % trace, whose speed units are set here or read from its header.
            app.ef_ftp_path = uieditfield(pnl, 'text', 'Value', '', ...
                'Placeholder', 'Built-in EPA FTP-75 (or Browse)', ...
                'Position', [10 y 296 26], 'BackgroundColor', app.C_card, ...
                'FontColor', app.C_tpri, 'FontSize', 10);
            app.dd_ftp_units = uidropdown(pnl, ...
                'Items', {'Units: auto', 'mph', 'km/h'}, 'ItemsData', {'auto', 'mph', 'kph'}, ...
                'Value', 'auto', 'Position', [312 y 92 26], ...
                'Tooltip', 'Speed units of your own trace. Auto reads a header such as speed_kph or mph.', ...
                'BackgroundColor', app.C_card, 'FontColor', app.C_tpri, 'FontSize', 10);
            app.btn_browse = uibutton(pnl, 'push', 'Text', 'Browse', ...
                'Position', [410 y 100 26], 'BackgroundColor', app.C_card, ...
                'FontColor', app.C_tsec, 'FontSize', 10, ...
                'ButtonPushedFcn', @(~,~) app.cb_browse_ftp());
            y = y - sg;

            app.mk_title(pnl, 10, y, pw, 'FTP FATIGUE DESIGN BASIS'); y = y - dy;
            pnl_method = uipanel(pnl, 'Position', [10 y pw 28], ...
                'BackgroundColor', app.C_surface, 'BorderType', 'none');
            uilabel(pnl_method, 'Text', 'Equivalent sinusoid', ...
                'Position', [12 13 240 13], 'FontColor', app.C_tpri, ...
                'FontSize', 11, 'FontWeight', 'bold', ...
                'BackgroundColor', app.C_surface);
            uilabel(pnl_method, 'Text', 'Rainflow count, m = 3', ...
                'Position', [12 2 240 12], 'FontColor', app.C_tsec, ...
                'FontSize', 9, 'BackgroundColor', app.C_surface);
            y = y - 40;

            app.mk_title(pnl, 10, y, pw, 'GEAR TRAIN  (single speed, two stages)'); y = y - dy;
            % One row per stage: pinion teeth, gear teeth, normal module,
            % helix angle. Every change re-validates the train and redraws
            % the drive unit; G is computed from the teeth.
            lbl = @(x, yy, w, txt) uilabel(pnl, 'Text', txt, 'Interpreter', 'html', 'Position', [x yy w 22], ...
                'FontColor', app.C_tsec, 'FontSize', 10, 'BackgroundColor', app.C_panel);
            fld = @(x, yy, v, tagName) uieditfield(pnl, 'numeric', 'Value', v, ...
                'Position', [x yy 44 24], 'BackgroundColor', app.C_card, ...
                'FontColor', app.C_tpri, 'FontSize', 11, 'HorizontalAlignment', 'right', ...
                'Tag', tagName, 'ValueChangedFcn', @(~,~) app.refresh_gear_train());
            lbl(10, y, 60, 'Stage 1');
            lbl(70, y, 28, 'N<sub>1</sub>');  app.ef_N1 = fld(96, y, 20, 'N1');
            lbl(146, y, 28, 'N<sub>2</sub>'); app.ef_N2 = fld(172, y, 60, 'N2');
            lbl(220, y, 48, 'm<sub>n</sub> [mm]'); app.ef_mn1_mm = fld(270, y, 4, 'ModuleStage1');
            lbl(406, y, 48, '&psi; [deg]'); app.ef_psi1_deg = fld(456, y, 25, 'HelixStage1');
            y = y - dy;
            lbl(10, y, 60, 'Stage 2');
            lbl(70, y, 28, 'N<sub>3</sub>');  app.ef_N3 = fld(96, y, 20, 'N3');
            lbl(146, y, 28, 'N<sub>4</sub>'); app.ef_N4 = fld(172, y, 60, 'N4');
            lbl(220, y, 48, 'm<sub>n</sub> [mm]'); app.ef_mn2_mm = fld(270, y, 5, 'ModuleStage2');
            % The key can only pick the module once instructor_answer_key.7z is
            % extracted; until then the instructor types it.
            key_available = isfile(fullfile(fileparts(mfilename('fullpath')), 'solution', 'runAnswerKey.m'));
            key_tip = 'The answer key chooses the smallest stage-2 module that passes the AGMA rating.';
            if ~key_available
                key_tip = 'Answer key locked (instructor_answer_key.7z not extracted): type the stage-2 module.';
            end
            app.cb_mn2_auto = uicheckbox(pnl, 'Text', 'key picks', 'Value', key_available, ...
                'Enable', matlab.lang.OnOffSwitchState(key_available), 'Tooltip', key_tip, ...
                'Position', [320 y 86 22], 'FontColor', app.C_tsec, 'FontSize', 10, ...
                'Tag', 'ModuleStage2Auto', 'ValueChangedFcn', @(~,~) app.refresh_gear_train());
            lbl(406, y, 48, '&psi; [deg]'); app.ef_psi2_deg = fld(456, y, 25, 'HelixStage2');
            y = y - dy + 4;
            app.lbl_gear_msg = uilabel(pnl, 'Text', '', 'Position', [10 y-4 pw 26], ...
                'FontColor', app.C_tsec, 'FontSize', 9.5, 'WordWrap', 'on', ...
                'BackgroundColor', app.C_panel, 'Tag', 'GearTrainMessage');

            app.btn_run = uibutton(pnl, 'push', ...
                'Text', 'Run load cases', ...
                'Position', [10 46 pw 50], ...
                'BackgroundColor', app.C_accent, 'FontColor', [1 1 1], ...
                'FontSize', 13, 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(~,~) app.cb_run());
            app.btn_run.Tag = 'RunLoadCases';

            app.btn_export = uibutton(pnl, 'push', ...
                'Text', 'Export student files', ...
                'Position', [10 6 pw 36], ...
                'BackgroundColor', app.C_card, 'FontColor', app.C_accent, ...
                'FontSize', 12, 'FontWeight', 'bold', 'Enable', 'off', ...
                'ButtonPushedFcn', @(~,~) app.cb_export());
            app.btn_export.Tag = 'ExportStudentFiles';
        end

        function build_results_panel(app)
            app.tg_results = uitabgroup(app.UIFigure, ...
                'Position', [12 52 1896 228]);

            app.tab_FTP     = uitab(app.tg_results, 'Title', 'FTP-75');
            app.tab_Hill    = uitab(app.tg_results, 'Title', 'Hill Climb');
            app.tab_Drag    = uitab(app.tg_results, 'Title', 'Drag Race');
            app.tab_summary = uitab(app.tg_results, 'Title', 'Design Summary');
            app.tab_key     = uitab(app.tg_results, 'Title', 'Answer Key');

            app.tbl_design = uitable(app.tab_summary, ...
                'ColumnName',  {'Case', 'Variable', 'Value', 'Unit', 'Engineering Use'}, ...
                'RowName',     {}, ...
                'ColumnWidth', {150, 290, 150, 90, 1160}, ...
                'FontSize',    11, ...
                'BackgroundColor', [app.C_card; app.C_surface], ...
                'ForegroundColor', app.C_tpri, ...
                'Units',       'normalized', ...
                'Position',    [0.01 0.02 0.98 0.96]);

            app.tbl_key = uitable(app.tab_key, ...
                'ColumnName',  {'Result', 'Value', 'Unit', 'Target', 'Status'}, ...
                'RowName',     {}, ...
                'ColumnWidth', {520, 180, 90, 120, 900}, ...
                'FontSize',    11, ...
                'BackgroundColor', [app.C_card; app.C_surface], ...
                'ForegroundColor', app.C_tpri, ...
                'Units',       'normalized', ...
                'Position',    [0.01 0.02 0.98 0.96], ...
                'Tag',         'AnswerKeyTable');
        end

        function reset_results(app)
            %RESET_RESULTS Blank every result view, so no case shows numbers
            %   from an earlier run.
            for lbl = [app.lbl_Tmean_v, app.lbl_Talt_v, app.lbl_bearing_v, ...
                    app.lbl_Tpeak_v, app.lbl_dist_v, app.lbl_Tss_v]
                lbl.Text = '-';
            end
            app.ax_FTP  = app.placeholder_axes(app.ax_FTP,  app.tab_FTP);
            app.ax_Hill = app.placeholder_axes(app.ax_Hill, app.tab_Hill);
            app.ax_Drag = app.placeholder_axes(app.ax_Drag, app.tab_Drag);
            app.tbl_design.Data = {'-', 'Run the selected load cases first', '-', '-', '-'};
            app.tbl_key.Data = {'Export a complete run to compute the answer key', '-', '-', '-', '-'};
        end

        function ax = placeholder_axes(app, old_ax, tab)
            % A new axes drops the yyaxis rulers and legend of a past plot.
            delete(old_ax);
            ax = uiaxes(tab, 'Units', 'normalized', 'Position', [0.055 0.18 0.890 0.70], ...
                'Color', app.C_card, 'XColor', app.C_tpri, 'YColor', app.C_tpri, ...
                'Box', 'off', 'XTick', [], 'YTick', []);
            ax.Toolbar.Visible = 'off';
            disableDefaultInteractivity(ax);
            text(ax, 0.5, 0.5, 'No results yet', ...
                'Units', 'normalized', ...
                'HorizontalAlignment', 'center', ...
                'FontSize', 13, 'Color', app.C_tpri);
        end

        function draw_car_schematic(app)
            % Cutaway 3D powertrain view; PowertrainView3D owns the geometry
            % and the moving parts.
            detail_axes = uiaxes(app.UIFigure, 'Position', [950 528 390 360], ...
                'Color', app.C_fig, 'Box', 'off');
            detail_axes.Toolbar.Visible = 'off';
            disableDefaultInteractivity(detail_axes);
            app.pv3d = PowertrainView3D(app.ax_schematic, DetailAxes=detail_axes, ...
                Train=buildGearTrain());
        end

        function mk_title(app, parent, x, y, w, txt)
            uilabel(parent, 'Text', txt, ...
                'Position',        [x y w 22], ...
                'FontColor',       app.C_tsec, ...
                'FontWeight',      'bold', ...
                'FontSize',        10.5, ...
                'BackgroundColor', app.C_panel);
        end

        function ef = mk_param(app, parent, x, y, lbl_txt, def_val, limits, lower_inclusive)
            if nargin < 8, lower_inclusive = 'on'; end
            uilabel(parent, 'Text', lbl_txt, 'Interpreter', 'html', ...
                'Position',        [x y 178 22], ...
                'FontColor',       app.C_tsec, ...
                'FontSize',        11, ...
                'BackgroundColor', app.C_panel);
            ef = uieditfield(parent, 'numeric', ...
                'Limits',               limits, ...
                'LowerLimitInclusive',  lower_inclusive, ...
                'Value',                def_val, ...
                'Position',             [x+180 y 80 24], ...
                'BackgroundColor',      app.C_card, ...
                'FontColor',            app.C_tpri, ...
                'FontSize',             12, ...
                'HorizontalAlignment',  'right', ...
                'ValueDisplayFormat',   '%.4g');
        end

        function style_axes(app, ax, font_size)
            % Light text on the card color with a faint grid. Placeholder
            % axes have no ticks, so the tick modes go back to auto.
            set(ax, 'Color', app.C_card, 'GridColor', app.C_hair, 'GridAlpha', 0.9, ...
                'XGrid', 'on', 'YGrid', 'on', 'Box', 'off', 'FontSize', font_size*app.font_scale);
            ax.Title.Color = app.C_tpri;
            for ruler = [ax.XAxis; ax.YAxis(:)]'
                set(ruler, 'Color', app.C_tpri, 'TickValuesMode', 'auto', 'TickLabelsMode', 'auto');
                ruler.Label.Color = app.C_tpri;
            end
        end

        function capture_layout(app)
            % Record the design-size geometry of every pixel-positioned
            % object; resize_layout scales from it, so panels must not
            % auto-resize their children as well.
            app.layout_ready = false;
            set(findall(app.UIFigure, '-property', 'AutoResizeChildren'), ...
                'AutoResizeChildren', 'off');
            h = findall(app.UIFigure);
            items = repmat(struct('Handle', [], 'Position', [], 'FontSize', [], 'LineWidth', []), 1, numel(h));
            keep = false(1, numel(h));

            for k = 1:numel(h)
                obj = h(k);
                if obj == app.UIFigure || ~isvalid(obj) || ~isprop(obj, 'Position')
                    continue;
                end
                % Tabs report a Position but the tab group owns it.
                position_prop = findprop(obj, 'Position');
                if ~strcmp(position_prop.SetAccess, 'public') || numel(obj.Position) ~= 4 || ...
                        (isprop(obj, 'Units') && strcmpi(obj.Units, 'normalized'))
                    continue;
                end

                item.Handle = obj;
                item.Position = obj.Position;
                item.FontSize = [];
                item.LineWidth = [];
                if isprop(obj, 'FontSize')
                    item.FontSize = obj.FontSize;
                end
                if isprop(obj, 'LineWidth')
                    item.LineWidth = obj.LineWidth;
                end
                items(k) = item;
                keep(k) = true;
            end

            app.layout_items = items(keep);
            app.layout_ready = true;
        end

        function maximize_window(app)
            app.UIFigure.WindowState = 'maximized';
            drawnow limitrate;
            app.resize_layout();
        end

        function resize_layout(app)
            if ~app.layout_ready || isempty(app.UIFigure) || ~isvalid(app.UIFigure)
                return;
            end

            fig_pos = app.UIFigure.Position;
            sx = max(0.45, fig_pos(3) / app.layout_base_size(1));
            sy = max(0.45, fig_pos(4) / app.layout_base_size(2));
            sf = app.text_scale * max(0.70, min(1.18, min(sx, sy)));
            app.font_scale = sf;

            for k = 1:numel(app.layout_items)
                item = app.layout_items(k);
                if ~isvalid(item.Handle)
                    continue;
                end
                pos = item.Position;
                item.Handle.Position = [pos(1)*sx, pos(2)*sy, ...
                    max(1, pos(3)*sx), max(1, pos(4)*sy)];
                if ~isempty(item.FontSize)
                    item.Handle.FontSize = max(7, item.FontSize * sf);
                end
                if ~isempty(item.LineWidth)
                    item.Handle.LineWidth = max(0.5, item.LineWidth * min(sx, sy));
                end
            end
            drawnow limitrate;
        end

    end

    methods (Access = private)   % callbacks and export

        function refresh_envelope(app)
            Tmax   = app.ef_Tmax.Value;
            Pmax_W = app.ef_Pmax_kW.Value * 1e3;
            Tregen = app.ef_Tregen.Value;
            G      = app.ef_gear_ratio.Value;
            Rw     = app.ef_wheel_R.Value;

            omega_base = Pmax_W / Tmax;
            omega_max  = app.ef_nmax_rpm.Value * pi/30;
            omega = linspace(0.01, 1.02*omega_max, 400);

            % Same envelope as SimDriveCore: speed limiter tapers the
            % available torque to zero over the last 5 percent.
            taper = min(max((omega_max - omega)/(0.05*omega_max), 0), 1);
            T_avail = min(Tmax, Pmax_W ./ omega) .* taper;

            cla(app.ax_envelope);
            hold(app.ax_envelope, 'on');
            fill(app.ax_envelope, [omega fliplr(omega)], ...
                [T_avail, -Tregen*ones(1,numel(omega))], app.C_accent, ...
                'FaceAlpha', 0.12, 'EdgeColor', 'none');
            plot(app.ax_envelope, omega, T_avail, ...
                'Color', app.C_accent, 'LineWidth', 1.8);
            plot(app.ax_envelope, omega, -Tregen * ones(size(omega)), ...
                'Color', app.C_amber, 'LineWidth', 1.2, 'LineStyle', '--');
            xline(app.ax_envelope, omega_base, ...
                'Color', app.C_tsec, 'LineWidth', 0.8, 'LineStyle', '--');
            hold(app.ax_envelope, 'off');

            v_base_kph = omega_base * (Rw / G) * 3.6;
            app.ax_envelope.XLim = [0 1.02*omega_max];
            app.ax_envelope.YLim = [-Tregen*1.3, Tmax*1.15];
            xlabel(app.ax_envelope, '\omega_m [rad/s]');
            ylabel(app.ax_envelope, 'T [N·m]');
            app.style_axes(app.ax_envelope, 10);
            app.ax_envelope.Title.String = sprintf('v_{base}=%.1f km/h, v_{top}=%.0f km/h', ...
                v_base_kph, omega_max * (Rw / G) * 3.6);
        end

        function cb_browse_ftp(app)
            [fname, fpath] = uigetfile({'*.txt;*.csv', 'Drive cycle files (*.txt, *.csv)'}, ...
                'Select a drive cycle: time [s] and speed (mph or km/h)', pwd);
            if isequal(fname, 0), return; end
            app.ef_ftp_path.Value = fullfile(fpath, fname);
        end

        function cb_run(app)
            [p, err] = app.get_params();
            if ~isempty(err)
                uialert(app.UIFigure, err, 'Input Error', 'Icon', 'error');
                return;
            end

            if ~p.run_FTP && ~p.run_Hill && ~p.run_Drag
                uialert(app.UIFigure, 'Select at least one load case.', 'No Cases Selected');
                return;
            end

            app.btn_run.Enable    = 'off';
            app.btn_export.Enable = 'off';
            app.run_ok            = false;
            app.run_parameters    = struct();
            app.reset_results();
            run_cleanup = onCleanup(@() set(app.btn_run, 'Enable', 'on'));
            app.set_status('Building model...', app.C_amber);

            model_name = app.runtime_model;
            model_cleanup = onCleanup(@() SimDriveCore.closeRuntimeModel(model_name));
            try
                SimDriveCore.createModelEVBlocks(model_name, p.m_vehicle, p.m, p.Cd, p.A, p.rho, p.Crr, ...
                    p.g, p.wheel_R, p.gear_ratio, p.eta_dt, p.Ts_pid, p.dt_sim, p.slewNmPerS);
            catch ME
                uialert(app.UIFigure, ...
                    ['Model build failed: ' ME.message], 'Simulink Error', 'Icon', 'error');
                app.set_status('Model build failed.', app.C_red);
                return;
            end

            drive_data_ftp = [0 0; 1 0];
            stop_ftp = 1;
            if p.run_FTP
                try
                    lastwarn('');
                    [t_ftp, v_ftp_kph] = SimDriveCore.loadFtp75SpeedTrace(p.ftp_file, p.ftp_units);
                    [guess_msg, guess_id] = lastwarn;
                    if strcmp(guess_id, 'SimDriveCore:FtpUnitsGuessed')
                        uialert(app.UIFigure, [guess_msg ' Set the units next to the file name.'], ...
                            'Speed Units Guessed', 'Icon', 'warning');
                    end
                    drive_data_ftp = [t_ftp, v_ftp_kph];
                    stop_ftp = t_ftp(end);
                catch ME
                    uialert(app.UIFigure, ...
                        ['FTP file error: ' ME.message], 'File Error', 'Icon', 'error');
                    app.set_status('FTP file error.', app.C_red);
                    return;
                end
            end

            assignin('base','Tmax',   p.Tmax);
            assignin('base','Tregen', p.Tregen);
            assignin('base','Pmax',   p.Pmax_W);
            assignin('base','omega_max', p.omega_max);
            assignin('base','Ts_pid', p.Ts_pid);
            assignin('base','dt_sim', p.dt_sim);
            assignin('base','Kp', p.Kp); assignin('base','Ki', p.Ki);
            assignin('base','Kd', p.Kd); assignin('base','Nf', p.Nf);
            assignin('base','Topen_cmd',  0);
            assignin('base','CASE_MODE',  0);
            assignin('base','ALLOW_REGEN',0);
            assignin('base','tau_torque', p.tau_fast);
            assignin('base','road_grade_in', 0);
            assignin('base','drive_data', [0 0; 1 0]);

            grade_peak = sin(deg2rad(p.theta_hill_deg));

            cases = struct([]);
            if p.run_FTP
                cases(end+1).name          = 'FTP75';
                cases(end).mode            = 1;
                cases(end).stopTime        = stop_ftp;
                cases(end).tau_torque      = p.tau_smooth;
                cases(end).allow_regen     = 1;
                cases(end).road_grade_in   = 0;
                cases(end).Topen           = 0;
            end
            if p.run_Hill
                cases(end+1).name          = 'HillClimb';
                cases(end).mode            = 0;
                cases(end).stopTime        = p.stop_hill;
                cases(end).tau_torque      = p.tau_fast;
                cases(end).allow_regen     = 0;
                cases(end).road_grade_in   = grade_peak;
                cases(end).Topen           = p.Tmax;
            end
            if p.run_Drag
                cases(end+1).name          = 'DragRace';
                cases(end).mode            = 0;
                cases(end).stopTime        = p.stop_drag;
                cases(end).tau_torque      = p.tau_fast;
                cases(end).allow_regen     = 0;
                cases(end).road_grade_in   = 0;
                cases(end).Topen           = p.Tmax;
            end

            ds = struct('case_name',{},'T_mean_eq',{},'T_alt_eq',{},'T_cubic_mean',{}, ...
                'T_ss_mean',{},'T_peak',{},'ftp_distance_m',{},'rms_err_kph',{}, ...
                'sn_exponent',{},'rf_data',{}, ...
                'Tin_applied',{},'v_sim_kph',{},'T_equiv_sin',{});

            all_ok = true;
            hill_note = '';
            app.stop_animation(false);   % stop idle first
            app.anim_mode = 'running';
            app.start_animation();
            for k = 1:numel(cases)
                app.set_status(sprintf('Running %s  (%d/%d)...', cases(k).name, k, numel(cases)), ...
                    app.C_amber);
                app.set_schematic_case(cases(k).name);
                drawnow;

                assignin('base','CASE_MODE',     cases(k).mode);
                assignin('base','ALLOW_REGEN',   cases(k).allow_regen);
                assignin('base','tau_torque',    cases(k).tau_torque);
                assignin('base','road_grade_in', cases(k).road_grade_in);
                assignin('base','Topen_cmd',     cases(k).Topen);

                if strcmp(cases(k).name, 'FTP75')
                    assignin('base','drive_data', drive_data_ftp);
                end

                set_param(model_name, 'StopTime', num2str(cases(k).stopTime));

                try
                    simout = sim(model_name);
                catch ME
                    uialert(app.UIFigure, ...
                        [cases(k).name ' simulation failed: ' ME.message], ...
                        'Simulation Error', 'Icon', 'error');
                    all_ok = false;
                    break;
                end

                Tin    = simout.Tin_applied;
                v_kph  = simout.v_sim_kph_out;

                ds(k).case_name      = cases(k).name;
                ds(k).sn_exponent    = NaN;   % FTP-75 only, as main.mlx
                ds(k).Tin_applied    = Tin;
                ds(k).v_sim_kph      = v_kph;
                ds(k).omega_m        = simout.omega_m_out;
                ds(k).v_ref_kph      = [];
                ds(k).T_cubic_mean   = SimDriveCore.computeBearingEquivalentTorque(Tin, simout.omega_m_out);

                if strcmp(cases(k).name,'FTP75')
                    v_ref = simout.v_ref_kph_out;
                    ds(k).v_ref_kph = v_ref;
                    e = v_ref.Data(:) - v_kph.Data(:);
                    ds(k).rms_err_kph   = sqrt(mean(e.^2,'omitnan'));

                    v_mps = v_kph.Data(:) / 3.6;
                    ds(k).ftp_distance_m = trapz(v_kph.Time(:), v_mps);

                    tvec = Tin.Time(:);

                    try
                        [T_mean_eq, T_alt_eq, rf_data] = SimDriveCore.computeFatigueLoad( ...
                            Tin, v_kph, 5, p.sn_exponent);
                    catch ME
                        uialert(app.UIFigure, ...
                            ['FTP-75 fatigue extraction failed: ' ME.message], ...
                            'Rainflow Error', 'Icon', 'error');
                        all_ok = false;
                        break;
                    end
                    ds(k).sn_exponent = p.sn_exponent;
                    ds(k).T_mean_eq  = T_mean_eq;
                    ds(k).T_alt_eq   = T_alt_eq;
                    ds(k).rf_data    = rf_data;
                    ds(k).T_ss_mean  = NaN;
                    ds(k).T_peak     = NaN;

                    Teq = T_mean_eq + T_alt_eq * sin(2*pi*tvec / app.T_equiv_period);
                    ds(k).T_equiv_sin = timeseries(Teq, tvec);

                    app.update_plot_FTP(ds(k));

                elseif strcmp(cases(k).name,'HillClimb')
                    T_arr = Tin.Data(:);
                    v_arr = v_kph.Data(:);
                    t_arr = v_kph.Time(:);
                    n_hc  = numel(T_arr);
                    ss_i  = round(0.60*n_hc)+1;
                    ds(k).T_ss_mean      = mean(T_arr(ss_i:end), 'omitnan');
                    v_ss_std = std(v_arr(t_arr >= t_arr(ss_i)), 'omitnan');
                    if v_ss_std > 1.0
                        hill_note = sprintf(['  Hill-climb speed has not settled (std = %.1f km/h); ' ...
                            'increase the hill-climb Stop time.'], v_ss_std);
                        warning('SimDrive:InstructorApp:HillNotSettled', '%s', strtrim(hill_note));
                    end
                    ds(k).T_mean_eq      = NaN;
                    ds(k).T_alt_eq       = NaN;
                    ds(k).T_peak         = NaN;
                    ds(k).ftp_distance_m = NaN;
                    ds(k).rms_err_kph    = NaN;
                    ds(k).rf_data        = [];
                    ds(k).T_equiv_sin    = [];
                    app.plot_torque_speed(app.ax_Hill, ds(k), sprintf( ...
                        'Hill Climb  |  T_{steady}=%.1f N·m  (%.0f°)', ...
                        ds(k).T_ss_mean, p.theta_hill_deg), 'v_{steady}');

                elseif strcmp(cases(k).name,'DragRace')
                    ds(k).T_peak         = max(Tin.Data(:));
                    ds(k).T_mean_eq      = NaN;
                    ds(k).T_alt_eq       = NaN;
                    ds(k).T_ss_mean      = NaN;
                    ds(k).ftp_distance_m = NaN;
                    ds(k).rms_err_kph    = NaN;
                    ds(k).rf_data        = [];
                    ds(k).T_equiv_sin    = [];
                    app.plot_torque_speed(app.ax_Drag, ds(k), sprintf( ...
                        'Drag Race  |  T_{peak}=%.1f N·m', ds(k).T_peak), 'v_{final}');
                end

                drawnow;
            end

            app.ds_results = ds;

            if all_ok
                app.run_parameters = p;
                app.update_summary_table(ds, p);
                app.update_stat_cards(ds);
                app.run_ok            = true;
                app.btn_export.Enable = 'on';
                msg = sprintf('Done: %d cases.', numel(cases));
                if isempty(hill_note)
                    app.set_status(msg, app.C_green);
                else
                    app.set_status([msg hill_note], app.C_amber);
                end
            end

            app.stop_animation(true);
            app.h_case_text.Text = '';
        end

        function cb_export(app)
            if ~app.run_ok || isempty(app.ds_results)
                uialert(app.UIFigure, 'Run the load cases first.', 'Nothing to Export');
                return;
            end

            % Exports go under the output root; the answer key is read from
            % this repository.
            repository_root = fileparts(fileparts(mfilename('fullpath')));
            outdir = fullfile(app.output_root, 'exports_design_ready');
            if ~isfolder(outdir)
                mkdir(outdir);
            end

            app.set_status('Exporting...', app.C_amber);
            drawnow;

            % Export the completed run, even if controls were edited later.
            p = app.run_parameters;
            ds = app.ds_results;

            omega_base = p.Pmax_W / p.Tmax;
            v_base     = omega_base * (p.wheel_R / p.gear_ratio);
            v_top      = p.omega_max * (p.wheel_R / p.gear_ratio);
            grade_peak = sin(deg2rad(p.theta_hill_deg));

            % Resolve the stage-2 module before anything is written, so the
            % summary students receive always prescribes a complete train.
            previous_path = path;
            path_cleanup = onCleanup(@() path(previous_path));
            addpath(fullfile(repository_root, 'instructor', 'solution'));
            % The answer key ships encrypted (instructor_answer_key.7z). Until an
            % instructor extracts it, export works without it: the typed
            % stage-2 module is used and no Answer_Key.md is written.
            key_unlocked = exist('runAnswerKey', 'file') == 2;
            train = p.train;
            if p.m_n2_auto && key_unlocked
                idx_drag = find(strcmp({ds.case_name}, 'DragRace'), 1);
                T_peak_key = p.Tmax;
                if ~isempty(idx_drag), T_peak_key = ds(idx_drag).T_peak; end
                try
                    m_n2_mm = selectStage2Module(p.train_options, T_peak_key, ...
                        omega_base, p.eta_dt, p.wheel_R);
                catch ME
                    app.show_key_failure(ME.message);
                    app.set_status('Export stopped: the answer key cannot rate stage 2.', app.C_red);
                    uialert(app.UIFigure, ME.message, 'Gear Train Infeasible', 'Icon', 'error');
                    return;
                end
                opts = p.train_options;
                opts.m_n2_mm = m_n2_mm;
                args = namedargs2cell(opts);
                train = buildGearTrain(args{:});
            end

            % Per-case .mat files hold the four signals used downstream and
            % ds_single with design values only, matching main.mlx. Controller
            % diagnostics and plot traces stay in the dashboard.
            export_values = arrayfun(@(c) app.design_values_only(c), ds);

            for k = 1:numel(ds)
                S_case = struct( ...
                    'Tin_applied',       ds(k).Tin_applied, ...
                    'omega_m_out',       ds(k).omega_m, ...
                    'v_sim_kph_out',     ds(k).v_sim_kph, ...
                    'T_equiv_sin_out',   ds(k).T_equiv_sin, ...
                    'Tmean_eq',          ds(k).T_mean_eq, ...
                    'Tamp_eq',           ds(k).T_alt_eq, ...
                    'T_equiv_period',    app.T_equiv_period, ...
                    'v_base',            v_base, ...
                    'omega_base',        omega_base, ...
                    'theta_hill_deg',    p.theta_hill_deg, ...
                    'grade_peak',        grade_peak, ...
                    'rms_err_kph',       ds(k).rms_err_kph, ...
                    'ds_single',         export_values(k));
                save(fullfile(outdir, [ds(k).case_name '_Outputs.mat']), '-struct', 'S_case');
                % Same plot as main.mlx writes.
                SimDriveCore.exportCasePlot(outdir, ds(k).case_name, ds(k).Tin_applied, ...
                    ds(k).v_sim_kph, ds(k).T_equiv_sin, 4000, ds(k).rms_err_kph);
            end

            S_sum = struct( ...
                'ds', export_values, 'Tmax', p.Tmax, 'Pmax', p.Pmax_W, 'Tregen', p.Tregen, ...
                'gear_ratio', p.gear_ratio, 'wheel_R', p.wheel_R, 'eta_dt', p.eta_dt, ...
                'v_base', v_base, 'omega_base', omega_base, 'omega_max', p.omega_max, 'v_top', v_top, ...
                'theta_hill_deg', p.theta_hill_deg, 'grade_peak', grade_peak, ...
                'm_vehicle', p.m_vehicle, 'm_eff', p.m, ...
                'I_motor', p.I_motor, 'I_wheel', p.I_wheel, 'delta_m', p.delta_m, ...
                'Cd', p.Cd, 'A_frontal', p.A, 'rho_air', p.rho, ...
                'T_ambient_C', p.T_ambient_C, 'Crr', p.Crr, 'sn_exponent', p.sn_exponent);
            for f = string(fieldnames(train.summary))'
                S_sum.(f) = train.summary.(f);
            end
            save(fullfile(outdir, 'Design_Summary.mat'), '-struct', 'S_sum');
            SimDriveCore.exportOverviewPlot(outdir, string({ds.case_name}), ...
                {ds.Tin_applied}, {ds.v_sim_kph}, p.Tmax, p.Tregen, 4000);

            package_dir = fullfile(app.output_root, 'student_package');
            if numel(ds) == 3 && all(ismember({'FTP75','HillClimb','DragRace'}, {ds.case_name}))
                key_file = fullfile(outdir, 'Answer_Key.md');
                if key_unlocked
                    app.set_status('Computing the answer key...', app.C_amber);
                    try
                        answer_key = runAnswerKey(outdir);
                    catch ME
                        app.show_key_failure(ME.message);
                        app.set_status('Data exported. The answer key failed, so no student package was built.', app.C_red);
                        uialert(app.UIFigure, ME.message, 'Answer Key Failed', 'Icon', 'error');
                        return;
                    end
                    app.show_answer_key(answer_key);
                    writeAnswerKeyReport(answer_key, key_file);
                else
                    app.tbl_key.Data = {'ANSWER KEY LOCKED', '-', '-', '-', ...
                        'Extract instructor_answer_key.7z (see the instructor guide) to compute it.'};
                    key_file = 'locked (instructor_answer_key.7z not extracted)';
                end
                try
                    package_file = buildStudentPackage(DatasetDirectory=outdir, ...
                        PackageDirectory=package_dir, ...
                        OutputFile=fullfile(app.output_root, 'release', app.package_name + ".zip"));
                catch ME
                    app.set_status('Data exported. The package build failed; the existing package is out of date.', app.C_red);
                    uialert(app.UIFigure, ME.message, 'Package Build Failed', 'Icon', 'error');
                    return;
                end
                app.set_status(['Exported. Student package: ' package_dir], app.C_green);
                uialert(app.UIFigure, sprintf('Data: %s\n\nAnswer key: %s\n\nStudent ZIP: %s', ...
                    outdir, key_file, package_file), 'Export Complete', 'Icon', 'info');
            else
                app.set_status('Partial run exported. A student package needs all three cases.', app.C_amber);
                uialert(app.UIFigure, ['Only the selected cases were exported. ' ...
                    'A student package needs all three cases.'], 'Partial Export');
            end
        end

        function values = design_values_only(~, case_data)
            %DESIGN_VALUES_ONLY Keep the design scalars, drop the traces.
            %   Returns the same field set main.mlx writes into ds_single, so
            %   the per-case files carry the same schema from either route.
            %   (main.mlx also adds *_out shaft torques to Design_Summary.ds.)
            names = {'case_name', 'rms_err_kph', 'ftp_distance_m', ...
                'T_cubic_mean', 'T_ss_mean', 'T_peak', 'T_mean_eq', ...
                'T_alt_eq', 'sn_exponent', 'rf_data'};
            values = struct();
            for i = 1:numel(names)
                values.(names{i}) = case_data.(names{i});
            end
            values.case_name = string(values.case_name);   % a string in main.mlx
        end

        function opts = train_options(app)
            %TRAIN_OPTIONS buildGearTrain name-value options from the controls.
            opts = struct('N1', app.ef_N1.Value, 'N2', app.ef_N2.Value, ...
                'N3', app.ef_N3.Value, 'N4', app.ef_N4.Value, ...
                'm_n1_mm', app.ef_mn1_mm.Value, 'm_n2_mm', app.ef_mn2_mm.Value, ...
                'psi1_deg', app.ef_psi1_deg.Value, 'psi2_deg', app.ef_psi2_deg.Value, ...
                'phi_n_deg', 20);
        end

        function refresh_gear_train(app)
            %REFRESH_GEAR_TRAIN Validate the train, show G, redraw the unit.
            args = namedargs2cell(app.train_options());
            [train, problems] = buildGearTrain(args{:});
            if app.cb_mn2_auto.Value
                app.ef_mn2_mm.Enable = 'off';
                % With the key choosing, only its stage-2 rules matter here.
                problems(startsWith(problems, "Stage 2 module")) = [];
            else
                app.ef_mn2_mm.Enable = 'on';
            end
            if isempty(problems)
                app.ef_gear_ratio.Value = train.G;
                app.lbl_gear_msg.Text = sprintf(['G = %.4f (%.4f x %.4f). Normal pressure angle ' ...
                    '20 deg (Shigley Ch. 14 J chart).'], train.G, train.stage(1).ratio, train.stage(2).ratio);
                app.lbl_gear_msg.FontColor = app.C_tsec;
                app.btn_run.Enable = 'on';
                app.lbl_train_flow.Text = sprintf('Motor > stage 1 %d:%d > stage 2 %d:%d > differential', ...
                    train.stage(1).N_pinion, train.stage(1).N_gear, ...
                    train.stage(2).N_pinion, train.stage(2).N_gear);
                if ~isempty(app.pv3d) && isvalid(app.pv3d)
                    % Pause the animation timer while the view is rebuilt,
                    % or a tick can land on graphics being replaced.
                    mode = app.anim_mode;
                    was_running = app.anim_running;
                    app.stop_animation(false);
                    app.pv3d.setTrain(train);
                    app.anim_mode = mode;
                    if was_running
                        app.start_animation();
                    end
                end
                if app.run_ok && isfield(app.run_parameters, 'train') && ...
                        ~isequal(app.run_parameters.train_options, app.train_options())
                    app.set_status(['Gear train changed after the run. Export uses the train ' ...
                        'that was run.'], app.C_amber);
                end
            else
                app.lbl_gear_msg.Text = char(problems(1));
                app.lbl_gear_msg.FontColor = app.C_red;
                app.btn_run.Enable = 'off';
            end
            app.refresh_envelope();
        end

        function show_answer_key(app, answer_key)
            status = repmat({'reference'}, height(answer_key), 1);
            has_target = ~isnan(answer_key.Target);
            status(has_target & answer_key.Pass) = {'PASS'};
            status(has_target & ~answer_key.Pass) = {'FAIL'};
            target = arrayfun(@(t) sprintf('%.4g', t), answer_key.Target, 'UniformOutput', false);
            target(~has_target) = {'-'};
            app.tbl_key.Data = [cellstr(answer_key.Item), ...
                arrayfun(@(v) sprintf('%.5g', v), answer_key.Value, 'UniformOutput', false), ...
                cellstr(answer_key.Unit), target, status];
            app.tg_results.SelectedTab = app.tab_key;
        end

        function show_key_failure(app, message)
            app.tbl_key.Data = {'ANSWER KEY FAILED', '-', '-', '-', char(message)};
            app.tg_results.SelectedTab = app.tab_key;
        end

        function show_help(app)
            msg = sprintf([ ...
                'SimDrive: Instructor Dashboard\n\n', ...
                'WORKFLOW\n', ...
                '1. Set the vehicle, motor and drivetrain parameters.\n', ...
                '2. Pick load cases.\n', ...
                '3. FTP-75 is reduced to one equivalent sinusoid.\n', ...
                '   Students receive its mean and alternating torques.\n\n', ...
                'WHAT EACH CASE GIVES YOU\n', ...
                '  FTP-75:     T_mean_eq, T_alt_eq (Goodman)\n', ...
                '              T_cubic_mean: bearing equivalent load\n', ...
                '              cycle distance (reference)\n', ...
                '  Hill Climb: T_steady (validation check; finite-life extension)\n', ...
                '  Drag Race:  T_peak (gear stress, shaft yield)\n\n', ...
                'GEAR TRAIN\n', ...
                '  Single speed, two stages: N1:N2 then N3:N4.\n', ...
                '  G is computed from the teeth. phi_n is 20 deg\n', ...
                '  (Ch. 14 J chart). A train that breaks a Shigley rule\n', ...
                '  is refused as it is typed, with the rule named.\n', ...
                '  With "key picks" ticked, export sets the smallest\n', ...
                '  stage-2 module that passes the AGMA rating.\n', ...
                '  Export then runs the answer key for\n', ...
                '  the exported train (Answer Key tab and\n', ...
                '  Answer_Key.md); if the key cannot meet a target\n', ...
                '  no student package is built.\n\n', ...
                'EXPORT\n', ...
                '  Simulation data goes to ./exports_design_ready/.\n', ...
                '  That is the instructor working export, at full\n', ...
                '  resolution, and it is not what students receive.\n', ...
                '  A complete three-case export automatically\n', ...
                '  rebuilds ./student_package/ from that run (reduced\n', ...
                '  dataset, templates, project brief, helper, licenses)\n', ...
                '  and zips the same folder into ./release/. Hand out\n', ...
                '  either the folder or the ZIP.\n\n', ...
                'BEARING NOTE\n', ...
                '  Bearings use T_cubic_mean, the revolution-\n', ...
                '  weighted cubic mean of the FTP-75 torque: the\n', ...
                '  Shigley Ch. 11 equivalent load.']);
            uialert(app.UIFigure, msg, 'Help', 'Icon', 'info');
        end

    end

    methods (Access = private)   % results display

        function set_schematic_case(app, case_name)
            col_map = struct('FTP75',     app.C_green, ...
                             'HillClimb', app.C_amber, ...
                             'DragRace',  app.C_red);
            col = app.C_accent;
            if isfield(col_map, case_name)
                col = col_map.(case_name);
            end
            label_map = struct('FTP75',     'FTP-75', ...
                               'HillClimb', 'Hill Climb', ...
                               'DragRace',  'Drag Race');
            lbl = case_name;
            if isfield(label_map, case_name)
                lbl = label_map.(case_name);
            end
            app.h_case_text.Text = ['Running ' lbl];
            app.h_case_text.FontColor = col;
            drawnow limitrate;
        end

        function update_stat_cards(app, ds)
            for k = 1:numel(ds)
                d = ds(k);
                switch d.case_name
                    case 'FTP75'
                        app.lbl_Tmean_v.Text   = sprintf('%.1f', d.T_mean_eq);
                        app.lbl_Talt_v.Text    = sprintf('%.1f', d.T_alt_eq);
                        app.lbl_bearing_v.Text = sprintf('%.1f', d.T_cubic_mean);
                        app.lbl_dist_v.Text    = sprintf('%.2f', d.ftp_distance_m/1e3);
                    case 'HillClimb'
                        app.lbl_Tss_v.Text     = sprintf('%.1f', d.T_ss_mean);
                    case 'DragRace'
                        app.lbl_Tpeak_v.Text   = sprintf('%.1f', d.T_peak);
                end
            end
        end

        function update_plot_FTP(app, d)
            ax = app.ax_FTP;
            cla(ax); hold(ax,'on');

            [t_raw, T_raw] = SimDriveCore.binAverage(d.Tin_applied.Time(:), d.Tin_applied.Data(:), 3000);
            has_equiv = ~isempty(d.T_equiv_sin);
            if has_equiv
                [t_b, T_b] = SimDriveCore.binAverage(d.T_equiv_sin.Time(:), d.T_equiv_sin.Data(:), 3000);
                torque_label = 'T_{eq} sinusoid';
            else
                t_b = t_raw;
                T_b = T_raw;
                torque_label = 'T_{applied}';
            end
            [t_v, v_b] = SimDriveCore.binAverage(d.v_sim_kph.Time(:), d.v_sim_kph.Data(:), 3000);

            yyaxis(ax, 'left');
            h0 = gobjects(0);
            if has_equiv
                h0 = plot(ax, t_raw, T_raw, 'Color', [0.60 0.60 0.60], ...
                    'LineWidth', 1.0, 'LineStyle', '-', 'DisplayName', 'T_{applied}');
            end
            h1 = plot(ax, t_b, T_b, 'Color', app.C_emblue, 'LineWidth', 2.8, ...
                'DisplayName', torque_label);
            ylabel(ax, 'Torque  [N·m]');

            yyaxis(ax, 'right');
            h2 = plot(ax, t_v, v_b, '-', 'Color', app.C_amber, 'LineWidth', 2.2, ...
                'DisplayName', 'v_{sim}');
            h3 = gobjects(0);
            if ~isempty(d.v_ref_kph)
                [t_ref, v_ref] = SimDriveCore.binAverage(d.v_ref_kph.Time(:), d.v_ref_kph.Data(:), 3000);
                h3 = plot(ax, t_ref, v_ref, ':', 'Color', [0.10 0.10 0.10], ...
                    'LineWidth', 2.0, 'DisplayName', 'v_{FTP-75 ref}');
            end
            ylabel(ax, 'Speed  [km/h]');

            hold(ax,'off');
            xlabel(ax, 'Time  [s]');
            title(ax, sprintf('FTP-75 equivalent sinusoid  |  T_{mean}=%.1f, T_{alt}=%.1f N·m  |  RMS error=%.2f km/h', ...
                d.T_mean_eq, d.T_alt_eq, d.rms_err_kph));
            app.style_axes(ax, 11);
            app.style_legend(legend(ax, [h1 h0 h2 h3], 'Location', 'eastoutside', 'FontSize', 10.5*app.font_scale));
            grid(ax, 'on');
        end

        function plot_torque_speed(app, ax, d, title_head, v_label)
            % Hill-climb and drag-race tabs: motor torque and vehicle speed,
            % titled with the final binned speed.
            cla(ax); hold(ax,'on');

            [t_b, T_b] = SimDriveCore.binAverage(d.Tin_applied.Time(:), d.Tin_applied.Data(:), 3000);
            [t_v, v_b] = SimDriveCore.binAverage(d.v_sim_kph.Time(:), d.v_sim_kph.Data(:), 3000);

            yyaxis(ax, 'left');
            h1 = plot(ax, t_b, T_b, 'Color', app.C_emblue, 'LineWidth', 2.8, ...
                'DisplayName', 'Motor torque');
            ylabel(ax, 'Torque  [N·m]');

            yyaxis(ax, 'right');
            h2 = plot(ax, t_v, v_b, '--', 'Color', app.C_amber, 'LineWidth', 2.0, ...
                'DisplayName', 'v_{sim}');
            ylabel(ax, 'Speed  [km/h]');

            hold(ax,'off');
            xlabel(ax, 'Time  [s]');
            title(ax, sprintf('%s  |  %s=%.1f km/h', title_head, v_label, v_b(end)));
            app.style_axes(ax, 11);
            app.style_legend(legend(ax, [h1 h2], 'Location', 'eastoutside', 'FontSize', 10*app.font_scale));
            grid(ax, 'on');
        end

        function style_legend(app, lgd)
            lgd.TextColor = app.C_tpri;
            lgd.Color = app.C_card;
            lgd.EdgeColor = app.C_tsec;
        end

        function update_summary_table(app, ds, p)
            T_ratio = p.gear_ratio * p.eta_dt;
            rows = {};

            T_ratio_int = p.train.stage(1).ratio * sqrt(p.eta_dt);
            rows(end+1,:) = {'PRIMARY','','','','Student design inputs (input shaft = motor side; intermediate = input x i1 x sqrt(eta))'};

            idx_ftp  = find(strcmp({ds.case_name},'FTP75'),1);
            idx_hill = find(strcmp({ds.case_name},'HillClimb'),1);
            idx_drag = find(strcmp({ds.case_name},'DragRace'),1);

            if ~isempty(idx_drag)
                rows(end+1,:) = {'Drag Race','T_peak (input)',  sprintf('%.1f', ds(idx_drag).T_peak),    'N·m','Stage-1 gear stress; input shaft yield (extension)'};
                rows(end+1,:) = {'Drag Race','T_peak (intermediate)', sprintf('%.1f', ds(idx_drag).T_peak*T_ratio_int),'N·m','Stage-2 gear stress + intermediate shaft yield'};
                rows(end+1,:) = {'Drag Race','T_peak (output)', sprintf('%.1f', ds(idx_drag).T_peak*T_ratio),'N·m','Differential carrier reference'};
            end
            if ~isempty(idx_ftp)
                d = ds(idx_ftp);
                rows(end+1,:) = {'FTP-75','T_mean_eq (input)', sprintf('%.1f', d.T_mean_eq),          'N·m','Input shaft Goodman mean (extension)'};
                rows(end+1,:) = {'FTP-75','T_alt_eq (input)',  sprintf('%.1f', d.T_alt_eq),           'N·m','Input shaft Goodman alternating (extension)'};
                rows(end+1,:) = {'FTP-75','T_mean_eq (intermediate)',sprintf('%.1f', d.T_mean_eq*T_ratio_int),'N·m','Intermediate shaft Goodman mean'};
                rows(end+1,:) = {'FTP-75','T_alt_eq (intermediate)', sprintf('%.1f', d.T_alt_eq*T_ratio_int), 'N·m','Intermediate shaft Goodman alternating'};
                rows(end+1,:) = {'FTP-75','T_cubic_mean (input)',  sprintf('%.1f', d.T_cubic_mean),       'N·m','Bearing equivalent load (input)'};
                rows(end+1,:) = {'FTP-75','T_cubic_mean (intermediate)',sprintf('%.1f', d.T_cubic_mean*T_ratio_int),'N·m','Bearing equivalent load (intermediate)'};
                rows(end+1,:) = {'FTP-75','FTP distance',      sprintf('%.3f', d.ftp_distance_m/1000),'km', 'FTP-75 cycle distance (reference)'};
            end
            if ~isempty(idx_hill)
                rows(end+1,:) = {'Hill Climb','T_steady (input)', sprintf('%.1f', ds(idx_hill).T_ss_mean),         'N·m','Validation hand check; finite-life extension'};
                rows(end+1,:) = {'Hill Climb','T_steady (intermediate)',sprintf('%.1f', ds(idx_hill).T_ss_mean*T_ratio_int), 'N·m','Intermediate shaft, finite-life extension'};
            end

            rows(end+1,:) = {'-','-','-','-','-'};

            rows(end+1,:) = {'SUPPORT','','','','Verification + prescribed geometry'};

            rows(end+1,:) = {'Drivetrain','G x eta',   sprintf('%.2f', T_ratio),'-', 'Torque ratio (output/input)'};
            rows(end+1,:) = {'Drivetrain','eta_dt',    sprintf('%.2f', p.eta_dt),'-', 'Drivetrain efficiency'};
            rows(end+1,:) = {'Drivetrain','m_eff',     sprintf('%.0f', p.m),     'kg','Effective mass (incl. rotational)'};
            rows(end+1,:) = {'Drivetrain','R_w',       sprintf('%.4f', p.wheel_R),'m','Tire radius (unloaded)'};
            rows(end+1,:) = {'Drivetrain','rho_air',   sprintf('%.4f', p.rho),   'kg/m³','Air density at T_ambient'};
            if ~isempty(idx_ftp)
                rows(end+1,:) = {'FTP-75','RMS speed error', sprintf('%.2f', ds(idx_ftp).rms_err_kph),'km/h','Tracking quality (<5 OK)'};
            end
            omega_base = p.Pmax_W / p.Tmax;
            v_base_kph = omega_base * (p.wheel_R / p.gear_ratio) * 3.6;
            rows(end+1,:) = {'Config','omega_base',sprintf('%.1f',omega_base),'rad/s','Envelope transition'};
            rows(end+1,:) = {'Config','v_base',    sprintf('%.1f',v_base_kph),'km/h', 'Base vehicle speed'};
            rows(end+1,:) = {'Config','v_top',     sprintf('%.1f',p.omega_max*(p.wheel_R/p.gear_ratio)*3.6),'km/h', 'Top speed at the motor speed limit'};
            stage_rows = cell(6, 5);   % three rows per stage
            for k = 1:2
                st = p.train.stage(k);
                name = sprintf('Stage %d', k);
                stage_rows(3*k-2,:) = {name, 'Pinion / gear teeth', sprintf('%d / %d', st.N_pinion, st.N_gear), '-', sprintf('Ratio %.4f', st.ratio)};
                module_note = 'Normal module';
                if k == 2 && p.m_n2_auto
                    module_note = 'Normal module, trial value: the answer key sets the final one on export';
                end
                stage_rows(3*k-1,:) = {name, 'm_n', sprintf('%.2f', 1000*st.m_n), 'mm', module_note};
                stage_rows(3*k,:) = {name, 'Pitch diameters', sprintf('%.1f / %.1f', 1000*st.d_pinion, 1000*st.d_gear), 'mm', sprintf('Helix %.1f deg, phi_n 20 deg', st.psi_deg)};
            end
            rows = [rows; stage_rows];

            app.tbl_design.Data = rows;
            app.tg_results.SelectedTab = app.tab_summary;
        end

        function set_status(app, msg, clr)
            app.lbl_status.Text = msg;
            app.lbl_status.FontColor = clr;
            drawnow;
        end

    end

    methods (Access = private)   % parameters

        function [p, err] = get_params(app)
            err = '';
            p   = struct();

            p.m_vehicle      = app.ef_mass.Value;
            p.Cd             = app.ef_Cd.Value;
            p.A              = app.ef_A.Value;
            p.Crr            = app.ef_Crr.Value;
            p.Tmax           = app.ef_Tmax.Value;
            p.Pmax_kW        = app.ef_Pmax_kW.Value;
            p.Pmax_W         = p.Pmax_kW * 1e3;
            p.omega_max      = app.ef_nmax_rpm.Value * pi/30;
            p.Tregen         = app.ef_Tregen.Value;
            p.I_motor        = app.ef_I_motor.Value;
            p.eta_dt         = app.ef_eta_dt.Value;
            p.wheel_R        = app.ef_wheel_R.Value;
            p.T_ambient_C    = app.ef_T_ambient.Value;
            p.train_options  = app.train_options();
            p.m_n2_auto      = logical(app.cb_mn2_auto.Value);
            p.theta_hill_deg = app.ef_theta_hill.Value;
            p.stop_drag      = app.ef_stop_drag.Value;
            p.stop_hill      = app.ef_stop_hill.Value;
            p.sn_exponent    = 3;   % fixed course S-N exponent

            try
                SimDriveCore.validateVehicleParameters(p);
            catch ME
                err = ME.message;
                return;
            end

            args = namedargs2cell(p.train_options);
            [p.train, problems] = buildGearTrain(args{:});
            if p.m_n2_auto
                % The key selects the stage-2 module on export, as in refresh_gear_train.
                problems(startsWith(problems, "Stage 2 module")) = [];
            end
            if ~isempty(problems)
                err = char(strjoin(problems, newline));
                return;
            end
            p.gear_ratio = p.train.G;

            % Effective mass: vehicle plus motor rotor and four wheels.
            p.tire_profile = app.dd_tire_profile.Value;
            p.I_wheel = SimDriveCore.wheelInertia(p.wheel_R, p.tire_profile);
            p.delta_m = (p.I_motor * p.gear_ratio^2 + 4 * p.I_wheel) / p.wheel_R^2;
            p.m       = p.m_vehicle + p.delta_m;

            p.g       = 9.81;
            p.rho     = SimDriveCore.airDensity(p.T_ambient_C);

            p.dt_sim      = 0.001;
            p.Ts_pid      = 0.01;
            p.slewNmPerS  = 5000;
            p.tau_fast    = 0.05;
            p.tau_smooth  = 0.12;
            p.Kp = 250; p.Ki = 20; p.Kd = 0; p.Nf = 100;

            p.run_FTP  = app.cb_FTP.Value;
            p.run_Hill = app.cb_Hill.Value;
            p.run_Drag = app.cb_Drag.Value;

            p.ftp_file = strtrim(app.ef_ftp_path.Value);
            p.ftp_units = app.dd_ftp_units.Value;
            if p.run_FTP && strlength(p.ftp_file) > 0 && ~isfile(p.ftp_file)
                err = ['FTP file not found: ' p.ftp_file];
            end
        end

    end

    methods (Access = private)   % animation

        function start_animation(app)
            if isempty(app.UIFigure) || ~isvalid(app.UIFigure) || ...
                    isempty(app.ax_schematic) || ~isvalid(app.ax_schematic)
                app.anim_running = false;
                return;
            end

            app.anim_tick    = 0;
            app.anim_running = true;
            app.delete_timer();
            app.anim_timer = timer( ...
                'ExecutionMode', 'fixedRate', ...
                'BusyMode',      'drop', ...
                'Period',        app.anim_period, ...
                'TimerFcn',      @(~,~) app.anim_step());
            start(app.anim_timer);
        end

        function stop_animation(app, restart_idle)
            app.anim_running = false;
            app.delete_timer();
            app.anim_mode = 'idle';
            if restart_idle
                app.start_animation();
            end
        end

        function delete_timer(app)
            % Detach first: stop() can run a queued tick, and that tick
            % calls back into here.
            t = app.anim_timer;
            app.anim_timer = [];
            if isa(t, 'timer') && isvalid(t)
                stop(t);
                delete(t);
            end
        end

        function anim_step(app)
            if ~app.anim_running || isempty(app.UIFigure) || ~isvalid(app.UIFigure) || ...
                    isempty(app.ax_schematic) || ~isvalid(app.ax_schematic)
                app.stop_animation(false);
                return;
            end

            app.anim_tick = app.anim_tick + 1;
            if ~isempty(app.pv3d) && isvalid(app.pv3d)
                app.pv3d.step(app.anim_tick * app.anim_period, app.anim_mode);
            end
            drawnow limitrate;
        end

    end

end
