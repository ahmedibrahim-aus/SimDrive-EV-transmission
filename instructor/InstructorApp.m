classdef InstructorApp < handle
%INSTRUCTORAPP  GUI for the EV gearbox instructor workflow.
%  app = InstructorApp();
%  Needs MATLAB R2025a+, Simulink and the Signal Processing Toolbox. The
%  EPA FTP-75 schedule is built in (ftp75Schedule.m); another speed trace is optional.

    properties (Constant, Access = private)
        package_name = "EV_Gearbox_Student_Package_v4.0.0"   % as tools/buildStudentPackage.m
    end

    properties (Access = private)

        UIFigure

        % Surfaces are separated by tone, not by borders: each step up the
        % stack is a lighter neutral. Color is reserved for state and for the
        % single accent, so the numbers stay the brightest thing on screen.
        C_fig    = [0.102 0.102 0.110]   % canvas
        C_panel  = [0.129 0.129 0.137]   % sidebar and panels
        C_surface= [0.149 0.149 0.157]   % elevated surface
        C_card   = [0.173 0.173 0.180]   % card and input fill
        C_hdr    = [0.078 0.078 0.086]   % chrome bars
        C_hair   = [0.235 0.235 0.247]   % hairline separator
        C_accent = [0.039 0.518 1.000]   % accent, one only
        C_amber  = [1.000 0.624 0.039]   % warning / gearbox
        C_green  = [0.188 0.820 0.345]   % pass
        C_red    = [1.000 0.271 0.227]   % fail
        C_tpri   = [0.949 0.949 0.969]   % label
        C_tsec   = [0.596 0.596 0.616]   % secondary label
        C_emblue = [0.392 0.824 1.000]   % motor component

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
        ef_sn_exp, pnl_sn

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
    end

    properties (Access = private)
        ds_results  = []
        run_parameters = struct()
        run_ok      = false
        T_equiv_period = 120
        output_root
        layout_base_size = [1920 1040]
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
            listing = dir(app.output_root);   % resolves relative paths and ..
            app.output_root = listing(1).folder;
            app.reset_project_state();
            app.build_ui();
            app.UIFigure.Visible = 'on';
            drawnow limitrate;
            app.draw_car_schematic();
            app.refresh_gear_train();
            app.capture_layout();
            app.UIFigure.SizeChangedFcn = @(~,~) app.resize_layout();
            app.maximize_window();
            app.anim_mode = 'idle';
            app.anim_running = false;
        end

        function delete(app)
            app.stop_animation(false);
            if ~isempty(app.UIFigure) && isvalid(app.UIFigure)
                delete(app.UIFigure);
            end
        end

    end

    methods (Access = private)

        function reset_project_state(~)
            modelName = 'EV_Gearbox_LoadCases_RuntimeModel';

            if bdIsLoaded(modelName)
                close_system(modelName, 0);
            end
        end

    end

    methods (Access = private)

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
            app.UIFigure.Theme = 'dark';

            hdr = uipanel(app.UIFigure, ...
                'Position',        [0 1006 1920 34], ...
                'BackgroundColor', app.C_hdr, ...
                'BorderType',      'none');
            % Accent line at bottom of header
            uipanel(app.UIFigure, 'Position', [0 1005 1920 1], ...
                'BackgroundColor', app.C_hair, 'BorderType','none');
            uilabel(hdr, ...
                'Text',            'SimDrive: EV Transmission Design', ...
                'Position',        [18 8 520 20], ...
                'FontColor',       app.C_tpri, ...
                'FontSize',        13.5, ...
                'FontWeight',      'bold', ...
                'BackgroundColor', app.C_hdr);
            uilabel(hdr, ...
                'Text',            'Configure | Run | Review | Export student-ready data', ...
                'Position',        [540 7 640 20], ...
                'FontColor',       app.C_tsec, ...
                'FontSize',        10, ...
                'BackgroundColor', app.C_hdr);
            uilabel(hdr, ...
                'Text',            'MATLAB + Simulink', ...
                'Position',        [1740 7 160 20], ...
                'FontColor',       app.C_tsec, ...
                'FontSize',        10, ...
                'HorizontalAlignment', 'right', ...
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

            sbar = uipanel(app.UIFigure, ...
                'Position',        [0 0 1920 40], ...
                'BackgroundColor', app.C_hdr, ...
                'BorderType',      'none');
            app.lbl_status = uilabel(sbar, ...
                'Text',            'Ready. Configure parameters and select load cases.', ...
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
            app.ef_mass      = app.mk_param(pnl, 8, y, 'Mass  [kg]',         1610); y = y - dy;
            app.ef_Cd        = app.mk_param(pnl, 8, y, 'Cd  [-]',            0.23); y = y - dy;
            app.ef_A         = app.mk_param(pnl, 8, y, 'Frontal area  [m²]', 2.22); y = y - dy;
            app.ef_Crr       = app.mk_param(pnl, 8, y, 'Crr  [-]',          0.01); y = y - dy;
            app.ef_T_ambient = app.mk_param(pnl, 8, y, 'T_ambient  [°C]',     25); y = y - sg;

            app.mk_title(pnl, 8, y, 260, 'WHEEL / TIRE'); y = y - dy;
            app.ef_wheel_R = app.mk_param(pnl, 8, y, 'Tire radius R_w [m]', 0.334); y = y - dy;
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
            app.ef_Tmax       = app.mk_param(pnl, 8, y, 'T_max  [N·m]',     350); y = y - dy;
            app.ef_Pmax_kW    = app.mk_param(pnl, 8, y, 'P_max  [kW]',      210); y = y - dy;
            app.ef_nmax_rpm   = app.mk_param(pnl, 8, y, 'n_max  [rpm]',   16000); y = y - dy;
            app.ef_nmax_rpm.ValueDisplayFormat = '%.0f';
            app.ef_Tregen     = app.mk_param(pnl, 8, y, 'T_regen  [N·m]',   150); y = y - dy;
            app.ef_I_motor    = app.mk_param(pnl, 8, y, 'I_motor  [kg·m²]',0.05); y = y - dy;
            app.ef_gear_ratio = app.mk_param(pnl, 8, y, 'Gear ratio  G (from teeth)', 9.0); y = y - dy;
            app.ef_gear_ratio.Editable = 'off';
            app.ef_eta_dt     = app.mk_param(pnl, 8, y, 'Efficiency  η',   0.97); y = y - sg;

            app.ef_Tmax.ValueChangedFcn       = @(~,~) app.refresh_envelope();
            app.ef_Pmax_kW.ValueChangedFcn    = @(~,~) app.refresh_envelope();
            app.ef_nmax_rpm.ValueChangedFcn   = @(~,~) app.refresh_envelope();
            app.ef_Tregen.ValueChangedFcn     = @(~,~) app.refresh_envelope();
            app.ef_gear_ratio.Tag = 'GearRatio';
            app.ef_wheel_R.ValueChangedFcn    = @(~,~) app.refresh_envelope();

            app.mk_title(pnl, 8, y, 260, 'ENVELOPE PREVIEW');
            ax_h = max(120, y - 22);
            app.ax_envelope = uiaxes(pnl, 'Position', [5 14 290 ax_h]);
            app.style_dark_axes(app.ax_envelope, '\omega_m  [rad/s]', 'T  [N·m]');
            app.ax_envelope.Title.String  = '';
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

            mk(342, 944, 520, 'REAR-WHEEL-DRIVE EV POWERTRAIN', ...
                app.C_tpri, 13, 'bold', 'left');
            app.lbl_train_flow = mk(342, 924, 600, '', app.C_tsec, 11, 'normal', 'left');

            app.h_case_text   = mk(342, 902, 460, '', app.C_accent, 11.5, 'bold', 'left');
        end

        function build_stat_cards(app)
            bg = uipanel(app.UIFigure, ...
                'Position',        [324 292 1032 206], ...
                'BackgroundColor', app.C_fig, ...
                'BorderType',      'none');

            cw = 330; ch = 90; gx = 12; gy = 10;

            defs = { ...
                'T_mean_eq',    '-', 'N·m',  'FTP Goodman mean',        app.C_emblue;
                'T_alt_eq',     '-', 'N·m',  'FTP Goodman alternating', app.C_amber;
                'T_cubic_mean', '-', 'N·m',  'Bearing load, Eq. (11-17)', app.C_green;
                'T_peak',       '-', 'N·m',  'Drag peak torque',        app.C_red;
                'FTP distance', '-', 'km',   'FTP cycle distance',      app.C_green;
                'T_steady',     '-', 'N·m',  'Hill sustained torque',   app.C_amber;
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
                uilabel(card, 'Text', defs{i,1}, ...
                    'Position',        [18 62 cw-26 18], ...
                    'FontColor',       app.C_tsec, ...
                    'FontSize',        10.5, 'FontWeight', 'bold', ...
                    'BackgroundColor', app.C_card);
                val_lbl = uilabel(card, 'Text', defs{i,2}, ...
                    'Position',        [18 22 cw-26 36], ...
                    'FontColor',       app.C_tpri, ...
                    'FontSize',        30, 'FontWeight', 'normal', ...
                    'BackgroundColor', app.C_card);
                uilabel(card, 'Text', [defs{i,3} '   ' defs{i,4}], ...
                    'Position',        [18 6 cw-26 16], ...
                    'FontColor',       app.C_tsec, ...
                    'FontSize',        9.5, ...
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

            y  = 676;
            dy = 30;
            sg = 34;
            pw = 520;

            % The caption needs more clearance than a normal row: the step
            % strip below it is 26 px tall and was covering its descenders.
            app.mk_title(pnl, 10, y, pw, 'INSTRUCTOR FLOW'); y = y - dy - 12;
            step_txt = {'1  Configure', '2  Run', '3  Review', '4  Export'};
            step_col = {app.C_emblue, app.C_green, app.C_accent, app.C_amber};
            step_w = (pw - 18) / 4;
            for i = 1:4
                sx = 10 + (i-1) * (step_w + 6);
                sp = uipanel(pnl, ...
                    'Position',        [sx y step_w 26], ...
                    'BackgroundColor', app.C_surface, ...
                    'BorderType',      'none');
                uipanel(sp, ...
                    'Position',        [0 0 3 26], ...
                    'BackgroundColor', step_col{i}, ...
                    'BorderType',      'none');
                uilabel(sp, ...
                    'Text',            step_txt{i}, ...
                    'Position',        [8 2 step_w-10 22], ...
                    'FontColor',       app.C_tpri, ...
                    'FontSize',        9.5, ...
                    'FontWeight',      'bold', ...
                    'BackgroundColor', app.C_surface);
            end
            y = y - dy - 10;

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
                'Value', 1, 'Position', [14 y 260 22], ...
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
            uilabel(pnl_method, 'Text', 'Approach A: equivalent sinusoid', ...
                'Position', [12 13 240 13], 'FontColor', app.C_tpri, ...
                'FontSize', 11, 'FontWeight', 'bold', ...
                'BackgroundColor', app.C_surface);
            uilabel(pnl_method, 'Text', 'Single course-approved reduction', ...
                'Position', [12 2 240 12], 'FontColor', app.C_tsec, ...
                'FontSize', 9, 'BackgroundColor', app.C_surface);
            y = y - 40;

            app.pnl_sn = uipanel(pnl, 'Position', [10 y pw 28], ...
                'BackgroundColor', app.C_panel, 'BorderType', 'none', 'Visible', 'on');
            uilabel(app.pnl_sn, 'Text', 'S-N exponent m:', ...
                'Position', [0 2 130 22], 'FontColor', app.C_tsec, ...
                'FontSize', 10, 'BackgroundColor', app.C_panel);
            app.ef_sn_exp = uieditfield(app.pnl_sn, 'numeric', ...
                'Value', 3, 'Limits', [1 20], 'Position', [135 2 60 24], ...
                'Editable', 'off', 'BackgroundColor', app.C_card, ...
                'FontColor', app.C_tpri, 'FontSize', 11);
            uilabel(app.pnl_sn, 'Text', '(fixed course value)', ...
                'Position', [205 2 120 22], 'FontColor', app.C_tsec, ...
                'FontSize', 9, 'BackgroundColor', app.C_panel);
            y = y - sg;

            app.mk_title(pnl, 10, y, pw, 'GEAR TRAIN  (single speed, two stages)'); y = y - dy;
            % One row per stage: pinion teeth, gear teeth, normal module,
            % helix angle. Every change re-validates the train and redraws
            % the drive unit; G is computed from the teeth, never typed.
            lbl = @(x, yy, w, txt) uilabel(pnl, 'Text', txt, 'Position', [x yy w 22], ...
                'FontColor', app.C_tsec, 'FontSize', 10, 'BackgroundColor', app.C_panel);
            fld = @(x, yy, v, tagName) uieditfield(pnl, 'numeric', 'Value', v, ...
                'Position', [x yy 44 24], 'BackgroundColor', app.C_card, ...
                'FontColor', app.C_tpri, 'FontSize', 11, 'HorizontalAlignment', 'right', ...
                'Tag', tagName, 'ValueChangedFcn', @(~,~) app.refresh_gear_train());
            lbl(10, y, 60, 'Stage 1');
            lbl(70, y, 28, 'N1');  app.ef_N1 = fld(96, y, 20, 'N1');
            lbl(146, y, 28, 'N2'); app.ef_N2 = fld(172, y, 60, 'N2');
            lbl(224, y, 44, 'm_n mm'); app.ef_mn1_mm = fld(270, y, 4, 'ModuleStage1');
            lbl(410, y, 44, 'ψ deg'); app.ef_psi1_deg = fld(456, y, 20, 'HelixStage1');
            y = y - dy;
            lbl(10, y, 60, 'Stage 2');
            lbl(70, y, 28, 'N3');  app.ef_N3 = fld(96, y, 20, 'N3');
            lbl(146, y, 28, 'N4'); app.ef_N4 = fld(172, y, 60, 'N4');
            lbl(224, y, 44, 'm_n mm'); app.ef_mn2_mm = fld(270, y, 6, 'ModuleStage2');
            % The key can only pick the module once instructor_answer_key.7z is
            % extracted; until then the instructor types it.
            keyAvailable = isfile(fullfile(fileparts(mfilename('fullpath')), 'solution', 'runAnswerKey.m'));
            keyTip = 'The answer key chooses the smallest stage-2 module that passes the AGMA rating.';
            if ~keyAvailable
                keyTip = 'Answer key locked (instructor_answer_key.7z not extracted): type the stage-2 module.';
            end
            app.cb_mn2_auto = uicheckbox(pnl, 'Text', 'key picks', 'Value', keyAvailable, ...
                'Enable', matlab.lang.OnOffSwitchState(keyAvailable), 'Tooltip', keyTip, ...
                'Position', [320 y 86 22], 'FontColor', app.C_tsec, 'FontSize', 10, ...
                'Tag', 'ModuleStage2Auto', 'ValueChangedFcn', @(~,~) app.refresh_gear_train());
            lbl(410, y, 44, 'ψ deg'); app.ef_psi2_deg = fld(456, y, 20, 'HelixStage2');
            y = y - dy + 4;
            app.lbl_gear_msg = uilabel(pnl, 'Text', '', 'Position', [10 y-4 pw 26], ...
                'FontColor', app.C_tsec, 'FontSize', 9.5, 'WordWrap', 'on', ...
                'BackgroundColor', app.C_panel, 'Tag', 'GearTrainMessage');

            app.btn_run = uibutton(pnl, 'push', ...
                'Text', char(9654) + "  Run load cases", ...
                'Position', [10 46 pw 50], ...
                'BackgroundColor', app.C_accent, 'FontColor', [1 1 1], ...
                'FontSize', 15, 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(~,~) app.cb_run());
            app.btn_run.Tag = 'RunLoadCases';

            app.btn_export = uibutton(pnl, 'push', ...
                'Text', 'Export student files', ...
                'Position', [10 6 pw 36], ...
                'BackgroundColor', app.C_card, 'FontColor', app.C_accent, ...
                'FontSize', 12.5, 'FontWeight', 'bold', 'Enable', 'off', ...
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

            app.ax_FTP  = uiaxes(app.tab_FTP,  'Units','normalized','Position',[0.055 0.18 0.890 0.70]);
            app.ax_Hill = uiaxes(app.tab_Hill, 'Units','normalized','Position',[0.055 0.18 0.890 0.70]);
            app.ax_Drag = uiaxes(app.tab_Drag, 'Units','normalized','Position',[0.055 0.18 0.890 0.70]);

            for ax = [app.ax_FTP, app.ax_Hill, app.ax_Drag]
                ax.Color = app.C_card;
                ax.XColor = app.C_tpri;
                ax.YColor = app.C_tpri;
                ax.Box = 'off';
                ax.Toolbar.Visible = 'off';
                disableDefaultInteractivity(ax);
                text(ax, 0.5, 0.5, 'Run the selected load cases to populate results', ...
                    'Units', 'normalized', ...
                    'HorizontalAlignment', 'center', ...
                    'FontSize', 13, 'Color', app.C_tpri);
                ax.XTick = []; ax.YTick = [];
            end

            app.tbl_design = uitable(app.tab_summary, ...
                'ColumnName',  {'Case', 'Variable', 'Value', 'Unit', 'Engineering Use'}, ...
                'RowName',     {}, ...
                'ColumnWidth', {150, 290, 150, 90, 1160}, ...
                'FontSize',    11, ...
                'BackgroundColor', [app.C_card; app.C_surface], ...
                'ForegroundColor', app.C_tpri, ...
                'Units',       'normalized', ...
                'Position',    [0.01 0.02 0.98 0.96]);
            app.tbl_design.Data = {'-', 'Run the selected load cases first', '-', '-', '-'};

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
            app.tbl_key.Data = {'Export a complete run to compute the answer key', '-', '-', '-', '-'};
        end

        function draw_car_schematic(app)
            % Cutaway 3D powertrain view; PowertrainView3D owns the geometry
            % and the moving parts.
            detailAxes = uiaxes(app.UIFigure, 'Position', [950 528 390 360], ...
                'Color', app.C_fig, 'Box', 'off');
            detailAxes.Toolbar.Visible = 'off';
            disableDefaultInteractivity(detailAxes);
            app.pv3d = PowertrainView3D(app.ax_schematic, DetailAxes=detailAxes, ...
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

        function ef = mk_param(app, parent, x, y, lbl_txt, def_val)
            uilabel(parent, 'Text', lbl_txt, ...
                'Position',        [x y 178 22], ...
                'FontColor',       app.C_tsec, ...
                'FontSize',        11, ...
                'BackgroundColor', app.C_panel);
            ef = uieditfield(parent, 'numeric', ...
                'Value',                def_val, ...
                'Position',             [x+180 y 80 24], ...
                'BackgroundColor',      app.C_card, ...
                'FontColor',            app.C_tpri, ...
                'FontSize',             12, ...
                'HorizontalAlignment',  'right', ...
                'ValueDisplayFormat',   '%.4g');
        end

        function style_dark_axes(app, ax, xlbl, ylbl)
            ax.Color      = app.C_card;
            ax.XColor     = app.C_tpri;
            ax.YColor     = app.C_tpri;
            ax.GridColor  = app.C_hair;
            ax.GridAlpha  = 0.9;
            ax.XGrid      = 'on';
            ax.YGrid      = 'on';
            ax.Box        = 'off';
            ax.XLabel.String = xlbl;  ax.XLabel.Color = app.C_tpri;
            ax.YLabel.String = ylbl;  ax.YLabel.Color = app.C_tpri;
            ax.Title.Color   = app.C_tpri;
            ax.FontSize      = 10.5;
        end

        function style_result_axes(app, ax)
            ax.Color      = app.C_card;
            ax.XColor     = app.C_tpri;
            ax.YColor     = app.C_tpri;
            ax.GridColor  = app.C_hair;
            ax.GridAlpha  = 0.9;
            ax.XGrid      = 'on';
            ax.YGrid      = 'on';
            ax.Box        = 'off';
            ax.LineWidth  = 1.1;
            ax.FontSize   = 12;
            ax.FontWeight = 'bold';
            ax.XLabel.Color = app.C_tpri;
            ax.YLabel.Color = app.C_tpri;
            ax.Title.Color  = app.C_tpri;
            ax.XLabel.FontSize = 12;
            ax.YLabel.FontSize = 12;
            ax.Title.FontSize  = 12.5;
            ax.Title.FontWeight = 'bold';
            ax.XTickMode = 'auto';
            ax.XTickLabelMode = 'auto';
            try
                ax.XAxis.Color = app.C_tpri;
                ax.XAxis.FontSize = 12;
            catch
            end
            for ruler = ax.YAxis(:)'
                ruler.Color = app.C_tpri;
                ruler.Label.Color = app.C_tpri;
                ruler.Label.FontSize = 12;
            end
            try
                yyaxis(ax, 'left');
                ax.YTickMode = 'auto';
                ax.YTickLabelMode = 'auto';
                yyaxis(ax, 'right');
                ax.YTickMode = 'auto';
                ax.YTickLabelMode = 'auto';
            catch
            end
        end

        function capture_layout(app)
            app.layout_ready = false;
            h = findall(app.UIFigure);
            % This existing layout has one owner: resize_layout. Prevent
            % nested panels from also moving their children during resizing.
            containers = findall(app.UIFigure, '-property', 'AutoResizeChildren');
            set(containers, 'AutoResizeChildren', 'off');
            items = struct('Handle', {}, 'Position', {}, 'FontSize', {}, 'LineWidth', {});

            for k = 1:numel(h)
                obj = h(k);
                if obj == app.UIFigure || ~isvalid(obj) || ~isprop(obj, 'Position')
                    continue;
                end
                units = "";
                if isprop(obj, 'Units')
                    try
                        units = string(obj.Units);
                    catch
                        units = "";
                    end
                end
                if strcmpi(units, "normalized")
                    continue;
                end

                try
                    pos = obj.Position;
                catch
                    continue;
                end
                if ~isnumeric(pos) || numel(pos) ~= 4 || any(~isfinite(pos))
                    continue;
                end

                item.Handle = obj;
                item.Position = pos;
                item.FontSize = [];
                item.LineWidth = [];
                if isprop(obj, 'FontSize')
                    try
                        if isnumeric(obj.FontSize) && isfinite(obj.FontSize)
                            item.FontSize = obj.FontSize;
                        end
                    catch
                    end
                end
                if isprop(obj, 'LineWidth')
                    try
                        if isnumeric(obj.LineWidth) && isfinite(obj.LineWidth)
                            item.LineWidth = obj.LineWidth;
                        end
                    catch
                    end
                end
                items(end+1) = item; %#ok<AGROW>
            end

            app.layout_items = items;
            app.layout_ready = true;
        end

        function maximize_window(app)
            try
                app.UIFigure.WindowState = 'maximized';
            catch
                screenSize = get(groot, 'ScreenSize');
                app.UIFigure.Position = [1 41 screenSize(3) max(720, screenSize(4)-80)];
            end
            drawnow limitrate;
            app.resize_layout();
        end

        function resize_layout(app)
            if ~app.layout_ready || isempty(app.UIFigure) || ~isvalid(app.UIFigure)
                return;
            end

            figPos = app.UIFigure.Position;
            sx = max(0.45, figPos(3) / app.layout_base_size(1));
            sy = max(0.45, figPos(4) / app.layout_base_size(2));
            sf = max(0.70, min(1.18, min(sx, sy)));

            for k = 1:numel(app.layout_items)
                item = app.layout_items(k);
                if isempty(item.Handle) || ~isvalid(item.Handle)
                    continue;
                end
                pos = item.Position;
                try
                    item.Handle.Position = [pos(1)*sx, pos(2)*sy, ...
                        max(1, pos(3)*sx), max(1, pos(4)*sy)];
                catch
                end
                if ~isempty(item.FontSize) && isprop(item.Handle, 'FontSize')
                    try
                        item.Handle.FontSize = max(7, item.FontSize * sf);
                    catch
                    end
                end
                if ~isempty(item.LineWidth) && isprop(item.Handle, 'LineWidth')
                    try
                        item.Handle.LineWidth = max(0.5, item.LineWidth * min(sx, sy));
                    catch
                    end
                end
            end
            drawnow limitrate;
        end

    end

    methods (Access = private)

        function refresh_envelope(app)
            try
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
                hAvail = plot(app.ax_envelope, omega, T_avail, ...
                    'Color', app.C_accent, 'LineWidth', 1.8);
                hRegen = plot(app.ax_envelope, omega, -Tregen * ones(size(omega)), ...
                    'Color', app.C_amber, 'LineWidth', 1.2, 'LineStyle', '--');
                hBase = xline(app.ax_envelope, omega_base, ...
                    'Color', app.C_tsec, 'LineWidth', 0.8, 'LineStyle', '--');
                hold(app.ax_envelope, 'off');

                v_base_kph = omega_base * (Rw / G) * 3.6;
                app.ax_envelope.XLim = [0 1.02*omega_max];
                app.ax_envelope.YLim = [-Tregen*1.3, Tmax*1.15];
                legend(app.ax_envelope, [hAvail hRegen hBase], {'T_{avail}', '-T_{regen}', '\omega_{base}'}, ...
                    'Location', 'northeast', 'FontSize', 8, ...
                    'TextColor', app.C_tpri, 'Color', app.C_card);
                app.style_dark_axes(app.ax_envelope, '\omega_m [rad/s]', 'T [N·m]');
                app.ax_envelope.Title.String = sprintf('v_{base}=%.1f km/h, v_{top}=%.0f km/h', ...
                    v_base_kph, omega_max * (Rw / G) * 3.6);
            catch ME
                warning('InstructorApp:refresh_envelope', '%s', ME.message);
            end
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
            cleanup = onCleanup(@() set(app.btn_run, 'Enable', 'on'));
            app.set_status('Building model...', app.C_amber);

            modelName = 'EV_Gearbox_LoadCases_RuntimeModel';
            modelCleanup = onCleanup(@() app.close_runtime_model(modelName));
            try
                app.create_model_EV_blocks(modelName, p.m_vehicle, p.m, p.Cd, p.A, p.rho, p.Crr, ...
                    p.g, p.wheel_R, p.gear_ratio, p.eta_dt, p.Ts_pid, p.dt_sim, p.slewNmPerS);
            catch ME
                uialert(app.UIFigure, ...
                    ['Model build failed: ' ME.message], 'Simulink Error', 'Icon', 'error');
                app.btn_run.Enable = 'on';
                app.set_status('Model build failed. Check the Command Window.', app.C_red);
                return;
            end

            drive_data_ftp = [0 0; 1 0];
            stop_ftp = 1;
            if p.run_FTP
                try
                    lastwarn('');
                    [t_ftp, v_ftp_kph] = app.load_ftp75(p.ftp_file, p.ftp_units);
                    [guessMsg, guessId] = lastwarn;
                    if strcmp(guessId, 'SimDriveCore:FtpUnitsGuessed')
                        uialert(app.UIFigure, [guessMsg ' Set the units next to the file name.'], ...
                            'Speed Units Guessed', 'Icon', 'warning');
                    end
                    drive_data_ftp = [t_ftp, v_ftp_kph];
                    stop_ftp = t_ftp(end);
                catch ME
                    uialert(app.UIFigure, ...
                        ['FTP file error: ' ME.message], 'File Error', 'Icon', 'error');
                    app.btn_run.Enable = 'on';
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
            grade_peak = min(max(grade_peak, 0), 0.95);

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
                'fatigue_method',{},'sn_exponent',{},'rf_data',{}, ...
                'Tin_applied',{},'v_sim_kph',{},'T_equiv_sin',{});

            all_ok = true;
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

                set_param(modelName, 'StopTime', num2str(cases(k).stopTime));

                try
                    simout = sim(modelName);
                catch ME
                    uialert(app.UIFigure, ...
                        [cases(k).name ' simulation failed: ' ME.message], ...
                        'Simulation Error', 'Icon', 'error');
                    all_ok = false;
                    break;
                end

                Tin    = simout.Tin_applied;
                v_kph  = simout.v_sim_kph_out;

                ds(k).case_name          = cases(k).name;
                ds(k).fatigue_method     = p.fatigue_method;
                ds(k).sn_exponent        = p.sn_exponent;
                ds(k).Tin_applied        = Tin;
                ds(k).v_sim_kph          = v_kph;
                ds(k).omega_m            = simout.omega_m_out;
                ds(k).T_cmd_pre_env      = simout.T_cmd_pre_env_out;
                ds(k).T_avail            = simout.T_avail_out;
                ds(k).v_ref_kph          = [];
                ds(k).T_cubic_mean       = app.compute_bearing_equivalent_torque(Tin, simout.omega_m_out);

                if strcmp(cases(k).name,'FTP75')
                    v_ref = simout.v_ref_kph_out;
                    ds(k).v_ref_kph = v_ref;
                    e = v_ref.Data(:) - v_kph.Data(:);
                    ds(k).rms_err_kph   = sqrt(mean(e.^2,'omitnan'));

                    v_mps = v_kph.Data(:) / 3.6;
                    ds(k).ftp_distance_m = trapz(v_kph.Time(:), v_mps);

                    tvec = Tin.Time(:);

                    try
                        [T_mean_eq, T_alt_eq, rf_data] = app.compute_fatigue_load( ...
                            Tin, v_kph, 5, p.fatigue_method, p.sn_exponent);
                    catch ME
                        uialert(app.UIFigure, ...
                            ['FTP-75 fatigue extraction failed: ' ME.message], ...
                            'Rainflow Error', 'Icon', 'error');
                        all_ok = false;
                        break;
                    end
                    ds(k).T_mean_eq  = T_mean_eq;
                    ds(k).T_alt_eq   = T_alt_eq;
                    ds(k).rf_data    = rf_data;
                    ds(k).T_ss_mean  = NaN;
                    ds(k).T_peak     = NaN;

                    Teq = T_mean_eq + T_alt_eq * sin(2*pi*tvec / app.T_equiv_period);
                    ds(k).T_equiv_sin = timeseries(Teq, tvec);

                    app.update_plot_FTP(ds(k), p);

                elseif strcmp(cases(k).name,'HillClimb')
                    T_arr = Tin.Data(:);
                    v_arr = v_kph.Data(:);
                    t_arr = v_kph.Time(:);
                    n_hc  = numel(T_arr);
                    ss_i  = round(0.60*n_hc)+1;
                    ds(k).T_ss_mean     = mean(T_arr(ss_i:end), 'omitnan');
                    v_ss_std = std(v_arr(t_arr >= t_arr(ss_i)), 'omitnan');
                    if v_ss_std > 1.0
                        warning('InstructorApp:HillNotSettled', 'Hill-climb speed has not settled (std = %.1f km/h); increase the hill-climb Stop time.', v_ss_std);
                    end
                    ds(k).T_mean_eq     = NaN;
                    ds(k).T_alt_eq      = NaN;
                    ds(k).T_peak        = NaN;
                    ds(k).ftp_distance_m= NaN;
                    ds(k).rms_err_kph   = NaN;
                    ds(k).rf_data       = [];
                    ds(k).T_equiv_sin   = [];
                    app.update_plot_Hill(ds(k), p);

                elseif strcmp(cases(k).name,'DragRace')
                    [T_pk, ~] = max(Tin.Data(:));
                    ds(k).T_peak        = T_pk;
                    ds(k).T_mean_eq     = NaN;
                    ds(k).T_alt_eq      = NaN;
                    ds(k).T_ss_mean     = NaN;
                    ds(k).ftp_distance_m= NaN;
                    ds(k).rms_err_kph   = NaN;
                    ds(k).rf_data       = [];
                    ds(k).T_equiv_sin   = [];
                    app.update_plot_Drag(ds(k), p);
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
                app.set_status(sprintf('Simulation complete. Review Design Summary, then export student files.  %d case(s) ready.', numel(cases)), app.C_green);
            end

            app.stop_animation(true);
            app.clear_schematic_overlay();
            app.btn_run.Enable = 'on';
        end

        function cb_export(app)
            if ~app.run_ok || isempty(app.ds_results)
                uialert(app.UIFigure, 'Run the load cases first.', 'Nothing to Export');
                return;
            end

            % Shared handoff folder at the repo root (one level up from instructor/).
            repositoryRoot = fileparts(fileparts(mfilename('fullpath')));
            outdir = fullfile(app.output_root, 'exports_design_ready');
            if ~exist(outdir, 'dir')
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
            previousPath = path;
            pathCleanup = onCleanup(@() path(previousPath));
            addpath(fullfile(repositoryRoot, 'instructor', 'solution'));
            % The answer key ships encrypted (instructor_answer_key.7z). Until an
            % instructor extracts it, export works without it: the typed
            % stage-2 module is used and no Answer_Key.md is written.
            keyUnlocked = exist('runAnswerKey', 'file') == 2;
            train = p.train;
            if p.m_n2_auto && keyUnlocked
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

            % Pack per-case .mat files via -struct to avoid lint warnings.
            % Only the four signals anything downstream reads are stored. The
            % controller diagnostics (T_cmd_pre_env, T_avail, v_ref_kph) stay in
            % the GUI's own results; at 1 ms over the 1874 s cycle they were
            % nearly half the size of the FTP-75 export and nothing used them.
            % ds_single carries design values only, matching what main.mlx
            % writes. The GUI keeps the traces on its own case structs for
            % plotting; exporting them inside ds_single as well would store
            % every signal twice and put a 1 ms trace inside Design_Summary.
            exportValues = arrayfun(@(c) app.design_values_only(c), ds);

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
                    'ds_single',         exportValues(k));
                save(fullfile(outdir, [ds(k).case_name '_Outputs.mat']), '-struct', 'S_case');
                app.export_case_png(outdir, ds(k), p);
            end

            switch p.tire_profile
                case 'low',      rim_ratio = 0.74;
                case 'standard', rim_ratio = 0.68;
                case 'high',     rim_ratio = 0.62;
                otherwise,       rim_ratio = 0.68;
            end
            I_wheel = 0.5 * 20 * (1 + rim_ratio^2) * p.wheel_R^2;

            S_sum = struct( ...
                'ds', exportValues, 'Tmax', p.Tmax, 'Pmax', p.Pmax_W, 'Tregen', p.Tregen, ...
                'gear_ratio', p.gear_ratio, 'wheel_R', p.wheel_R, 'eta_dt', p.eta_dt, ...
                'v_base', v_base, 'omega_base', omega_base, 'omega_max', p.omega_max, 'v_top', v_top, ...
                'theta_hill_deg', p.theta_hill_deg, 'grade_peak', grade_peak, ...
                'm_vehicle', p.m_vehicle, 'm_eff', p.m, ...
                'I_motor', p.I_motor, 'I_wheel', I_wheel, 'delta_m', p.delta_m, ...
                'Cd', p.Cd, 'A_frontal', p.A, 'rho_air', p.rho, ...
                'T_ambient_C', p.T_ambient_C, 'Crr', p.Crr, ...
                'FATIGUE_METHOD', p.fatigue_method, 'sn_exponent', p.sn_exponent);
            for f = string(fieldnames(train.summary))'
                S_sum.(f) = train.summary.(f);
            end
            save(fullfile(outdir, 'Design_Summary.mat'), '-struct', 'S_sum');
            app.export_overview_png(outdir, ds, p);

            packageDir = app.student_package_dir();
            if numel(ds) == 3 && all(ismember({'FTP75','HillClimb','DragRace'}, {ds.case_name}))
                keyFile = fullfile(outdir, 'Answer_Key.md');
                if keyUnlocked
                    app.set_status('Computing the answer key for this gear train...', app.C_amber);
                    try
                        answerKey = runAnswerKey(outdir);
                    catch ME
                        app.show_key_failure(ME.message);
                        app.set_status('Data exported; answer key failed, so no student package was built.', app.C_red);
                        uialert(app.UIFigure, ME.message, 'Answer Key Failed', 'Icon', 'error');
                        return;
                    end
                    app.show_answer_key(answerKey);
                    writeAnswerKeyReport(answerKey, keyFile);
                else
                    app.tbl_key.Data = {'ANSWER KEY LOCKED', '-', '-', '-', ...
                        'Extract instructor_answer_key.7z (see the instructor guide) to compute it.'};
                    keyFile = 'locked (instructor_answer_key.7z not extracted)';
                end
                addpath(fullfile(repositoryRoot, 'tools'));
                try
                    packageFile = buildStudentPackage(DatasetDirectory=outdir, ...
                        PackageDirectory=packageDir, ...
                        OutputFile=fullfile(app.output_root, 'release', app.package_name + ".zip"));
                catch ME
                    app.set_status('Data exported; package build failed. Do not distribute the old package.', app.C_red);
                    uialert(app.UIFigure, ME.message, 'Package Build Failed', 'Icon', 'error');
                    return;
                end
                if isfile(keyFile)
                    app.set_status(['Export, answer key and fresh package complete: ' packageDir], app.C_green);
                else
                    app.set_status(['Export and fresh package complete (answer key locked): ' packageDir], app.C_green);
                end
                uialert(app.UIFigure, sprintf(['Completed-run data: %s\n\nAnswer key: %s\n\n' ...
                    'Fresh student ZIP: %s'], outdir, keyFile, packageFile), ...
                    'Export Complete', 'Icon', 'success');
            else
                app.set_status('Partial run exported. Run all three cases to create a fresh student package.', app.C_amber);
                uialert(app.UIFigure, ['Only the selected cases were exported. No new student package was built. ' ...
                    'Run all three cases before distributing a package.'], 'Partial Export');
            end
        end

        function values = design_values_only(~, caseData)
            %DESIGN_VALUES_ONLY Keep the design scalars, drop the traces.
            %   Returns the same field set main.mlx writes into ds_single, so
            %   the per-case files carry the same schema from either route.
            %   (main.mlx also adds *_out shaft torques to Design_Summary.ds.)
            names = {'case_name', 'rms_err_kph', 'ftp_distance_m', ...
                'T_cubic_mean', 'T_ss_mean', 'T_peak', 'T_mean_eq', ...
                'T_alt_eq', 'fatigue_method', 'sn_exponent', 'rf_data'};
            values = struct();
            for i = 1:numel(names)
                if isfield(caseData, names{i})
                    values.(names{i}) = caseData.(names{i});
                else
                    values.(names{i}) = [];
                end
            end
        end

        function packageDir = student_package_dir(app)
            %STUDENT_PACKAGE_DIR Absolute path of the student hand-out folder.
            packageDir = fullfile(app.output_root, 'student_package');
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
                app.lbl_gear_msg.Text = sprintf(['G = %.4f (%.4f x %.4f).  phi_n locked at ' ...
                    '20 deg, Shigley Fig. 14-7.'], train.G, train.stage(1).ratio, train.stage(2).ratio);
                app.lbl_gear_msg.FontColor = app.C_tsec;
                app.btn_run.Enable = 'on';
                app.lbl_train_flow.Text = sprintf(['battery  %s  motor  %s  stage 1  %d:%d  %s  ' ...
                    'stage 2  %d:%d  %s  differential'], char(8594), char(8594), ...
                    train.stage(1).N_pinion, train.stage(1).N_gear, char(8594), ...
                    train.stage(2).N_pinion, train.stage(2).N_gear, char(8594));
                if ~isempty(app.pv3d) && isvalid(app.pv3d)
                    % Pause the animation timer while the view is rebuilt,
                    % or a tick can land on graphics being replaced.
                    mode = app.anim_mode;
                    wasRunning = app.anim_running;
                    app.stop_animation(false);
                    app.pv3d.setTrain(train);
                    app.anim_mode = mode;
                    if wasRunning
                        app.start_animation();
                    end
                end
                if app.run_ok && isfield(app.run_parameters, 'train') && ...
                        ~isequal(app.run_parameters.train_options, app.train_options())
                    app.set_status(['Gear train edited after the run. Export uses the train ' ...
                        'that was run; run again to export the new one.'], app.C_amber);
                end
            else
                app.lbl_gear_msg.Text = char(problems(1));
                app.lbl_gear_msg.FontColor = app.C_red;
                app.btn_run.Enable = 'off';
            end
            app.refresh_envelope();
        end

        function show_answer_key(app, answerKey)
            status = repmat({'reference'}, height(answerKey), 1);
            hasTarget = ~isnan(answerKey.Target);
            status(hasTarget & answerKey.Pass) = {'PASS'};
            status(hasTarget & ~answerKey.Pass) = {'FAIL'};
            target = arrayfun(@(t) sprintf('%.4g', t), answerKey.Target, 'UniformOutput', false);
            target(~hasTarget) = {'-'};
            app.tbl_key.Data = [cellstr(answerKey.Item), ...
                arrayfun(@(v) sprintf('%.5g', v), answerKey.Value, 'UniformOutput', false), ...
                cellstr(answerKey.Unit), target, status];
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
                '3. Approach A converts FTP-75 into one equivalent sinusoid.\n', ...
                '   Students receive its mean and alternating torques.\n\n', ...
                'WHAT EACH CASE GIVES YOU\n', ...
                '  FTP-75:     T_mean_eq, T_alt_eq (Goodman)\n', ...
                '              T_cubic_mean: bearing load (Eq. 11-17)\n', ...
                '              cycle distance (reference)\n', ...
                '  Hill Climb: T_steady (validation check; finite-life extension)\n', ...
                '  Drag Race:  T_peak (gear stress, shaft yield)\n\n', ...
                'GEAR TRAIN\n', ...
                '  Single speed, two stages: N1:N2 then N3:N4.\n', ...
                '  G is computed from the teeth. phi_n is 20 deg\n', ...
                '  (Fig. 14-7). A train that breaks a Shigley rule\n', ...
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
                '  Shigley Eq. (11-17) equivalent load.']);
            uialert(app.UIFigure, msg, 'Help', 'Icon', 'info');
        end

    end

    methods (Access = private)

        function set_schematic_case(app, case_name)
            col_map = struct('FTP75', app.C_green, ...
                             'HillClimb', app.C_amber, ...
                             'DragRace',  app.C_red);
            col = app.C_accent;
            if isfield(col_map, case_name)
                col = col_map.(case_name);
            end
            label_map = struct('FTP75', 'FTP-75', ...
                               'HillClimb', 'Hill Climb', ...
                               'DragRace',  'Drag Race');
            lbl = case_name;
            if isfield(label_map, case_name)
                lbl = label_map.(case_name);
            end
            app.h_case_text.Text = [char(9654) '  ' lbl '  -  Running…'];
            app.h_case_text.FontColor = col;
            drawnow limitrate;
        end

        function clear_schematic_overlay(app)
            app.h_case_text.Text   = '';
        end

        function update_stat_cards(app, ds)
            for k = 1:numel(ds)
                d = ds(k);
                switch d.case_name
                    case 'FTP75'
                        if isfield(d,'T_mean_eq')   && isfinite(d.T_mean_eq)
                            app.lbl_Tmean_v.Text   = sprintf('%.1f', d.T_mean_eq);
                        end
                        if isfield(d,'T_alt_eq')    && isfinite(d.T_alt_eq)
                            app.lbl_Talt_v.Text    = sprintf('%.1f', d.T_alt_eq);
                        end
                        if isfield(d,'T_cubic_mean')&& isfinite(d.T_cubic_mean)
                            app.lbl_bearing_v.Text = sprintf('%.1f', d.T_cubic_mean);
                        end
                        if isfield(d,'ftp_distance_m') && isfinite(d.ftp_distance_m)
                            app.lbl_dist_v.Text    = sprintf('%.2f', d.ftp_distance_m/1e3);
                        end
                    case 'HillClimb'
                        if isfield(d,'T_ss_mean') && isfinite(d.T_ss_mean)
                            app.lbl_Tss_v.Text = sprintf('%.1f', d.T_ss_mean);
                        end
                    case 'DragRace'
                        if isfield(d,'T_peak') && isfinite(d.T_peak)
                            app.lbl_Tpeak_v.Text = sprintf('%.1f', d.T_peak);
                        end
                end
            end
        end

    end

    methods (Access = private)  % plotting

        function update_plot_FTP(app, d, ~)
            ax = app.ax_FTP;
            cla(ax); hold(ax,'on');

            [t_raw, T_raw] = app.bin_average(d.Tin_applied.Time(:), d.Tin_applied.Data(:), 3000);
            has_equiv = isfield(d, 'T_equiv_sin') && ~isempty(d.T_equiv_sin);
            if has_equiv
                [t_b, T_b] = app.bin_average(d.T_equiv_sin.Time(:), d.T_equiv_sin.Data(:), 3000);
                torque_label = 'T_{eq} sinusoid';
            else
                t_b = t_raw;
                T_b = T_raw;
                torque_label = 'T_{applied}';
            end
            [t_v, v_b] = app.bin_average(d.v_sim_kph.Time(:), d.v_sim_kph.Data(:), 3000);
            t_ref = [];
            v_ref = [];
            if isfield(d, 'v_ref_kph') && ~isempty(d.v_ref_kph)
                [t_ref, v_ref] = app.bin_average(d.v_ref_kph.Time(:), d.v_ref_kph.Data(:), 3000);
            end

            yyaxis(ax, 'left');
            if has_equiv
                h0 = plot(ax, t_raw, T_raw, 'Color', [0.55 0.62 0.70], ...
                    'LineWidth', 1.0, 'LineStyle', '-', 'DisplayName', 'T_{applied}');
            else
                h0 = gobjects(0);
            end
            h1 = plot(ax, t_b, T_b, 'Color', app.C_emblue, 'LineWidth', 2.8, ...
                'DisplayName', torque_label);
            ylabel(ax, 'Torque  [N·m]');

            yyaxis(ax, 'right');
            h2 = plot(ax, t_v, v_b, '-', 'Color', app.C_amber, 'LineWidth', 2.2, ...
                'DisplayName', 'v_{sim}');
            if ~isempty(t_ref)
                h3 = plot(ax, t_ref, v_ref, ':', 'Color', [0.92 0.94 0.96], ...
                    'LineWidth', 2.0, 'DisplayName', 'v_{FTP-75 ref}');
            else
                h3 = gobjects(0);
            end
            ylabel(ax, 'Speed  [km/h]');

            hold(ax,'off');
            xlabel(ax, 'Time  [s]');
            title(ax, sprintf('FTP-75 / Approach A  |  T_{mean}=%.1f, T_{alt}=%.1f N·m  |  RMS error=%.2f km/h', ...
                d.T_mean_eq, d.T_alt_eq, d.rms_err_kph));
            app.style_result_axes(ax);
            if isempty(h0) && isempty(h3)
                lgd = legend(ax, [h1 h2], {torque_label, 'v_{sim}'}, ...
                    'Location', 'best', 'FontSize', 10.5);
            elseif isempty(h3)
                lgd = legend(ax, [h1 h0 h2], {torque_label, 'T_{applied}', 'v_{sim}'}, ...
                    'Location', 'best', 'FontSize', 10.5);
            elseif isempty(h0)
                lgd = legend(ax, [h1 h2 h3], {torque_label, 'v_{sim}', 'v_{FTP-75 ref}'}, ...
                    'Location', 'best', 'FontSize', 10.5);
            else
                lgd = legend(ax, [h1 h0 h2 h3], {torque_label, 'T_{applied}', 'v_{sim}', 'v_{FTP-75 ref}'}, ...
                    'Location', 'best', 'FontSize', 10.5);
            end
            lgd.TextColor = app.C_tpri;
            lgd.Color = app.C_card;
            lgd.EdgeColor = app.C_tsec;
            grid(ax, 'on');
        end

        function update_plot_Hill(app, d, p)
            ax = app.ax_Hill;
            cla(ax); hold(ax,'on');

            [t_b, T_b] = app.bin_average(d.Tin_applied.Time(:), d.Tin_applied.Data(:), 3000);
            [t_v, v_b] = app.bin_average(d.v_sim_kph.Time(:), d.v_sim_kph.Data(:), 3000);

            yyaxis(ax, 'left');
            h1 = plot(ax, t_b, T_b, 'Color', app.C_emblue, 'LineWidth',2.8, ...
                'DisplayName','T_{applied}');
            ylabel(ax, 'Torque  [N·m]');

            yyaxis(ax, 'right');
            h2 = plot(ax, t_v, v_b, '--', 'Color', app.C_amber, 'LineWidth',2.0, ...
                'DisplayName','v_{sim}');
            ylabel(ax, 'Speed  [km/h]');

            hold(ax,'off');
            xlabel(ax,'Time  [s]');
            title(ax, sprintf('Hill Climb  |  T_{steady}=%.1f N·m  (%.0f°)  |  v_{steady}=%.1f km/h', ...
                d.T_ss_mean, p.theta_hill_deg, v_b(end)));
            app.style_result_axes(ax);
            lgd = legend(ax, [h1 h2], {'T_{applied}', 'v_{sim}'}, 'Location','best','FontSize',10);
            lgd.TextColor = app.C_tpri;
            lgd.Color = app.C_card;
            lgd.EdgeColor = app.C_tsec;
            grid(ax,'on');
        end

        function update_plot_Drag(app, d, ~)
            ax = app.ax_Drag;
            cla(ax); hold(ax,'on');

            [t_b, T_b] = app.bin_average(d.Tin_applied.Time(:), d.Tin_applied.Data(:), 3000);
            [t_v, v_b] = app.bin_average(d.v_sim_kph.Time(:), d.v_sim_kph.Data(:), 3000);

            yyaxis(ax, 'left');
            h1 = plot(ax, t_b, T_b, 'Color', app.C_emblue, 'LineWidth',2.8, ...
                'DisplayName','T_{applied}');
            ylabel(ax,'Torque  [N·m]');

            yyaxis(ax,'right');
            h2 = plot(ax, t_v, v_b, '--', 'Color', app.C_amber, 'LineWidth',2.0, ...
                'DisplayName','v_{sim}');
            ylabel(ax,'Speed  [km/h]');

            hold(ax,'off');
            xlabel(ax,'Time  [s]');
            title(ax, sprintf('Drag Race  |  T_{peak}=%.1f N·m  |  v_{final}=%.1f km/h', ...
                d.T_peak, v_b(end)));
            app.style_result_axes(ax);
            lgd = legend(ax,[h1 h2],{'T_{applied}','v_{sim}'},'Location','best','FontSize',10);
            lgd.TextColor = app.C_tpri;
            lgd.Color = app.C_card;
            lgd.EdgeColor = app.C_tsec;
            grid(ax,'on');
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
                m_str = sprintf('[%s]', d.fatigue_method);
                rows(end+1,:) = {'FTP-75','T_mean_eq (input)', sprintf('%.1f', d.T_mean_eq),          'N·m',['Input shaft Goodman mean (extension) ' m_str]};
                rows(end+1,:) = {'FTP-75','T_alt_eq (input)',  sprintf('%.1f', d.T_alt_eq),           'N·m',['Input shaft Goodman alternating (extension) ' m_str]};
                rows(end+1,:) = {'FTP-75','T_mean_eq (intermediate)',sprintf('%.1f', d.T_mean_eq*T_ratio_int),'N·m','Intermediate shaft Goodman mean'};
                rows(end+1,:) = {'FTP-75','T_alt_eq (intermediate)', sprintf('%.1f', d.T_alt_eq*T_ratio_int), 'N·m','Intermediate shaft Goodman alternating'};
                rows(end+1,:) = {'FTP-75','T_cubic_mean (input)',  sprintf('%.1f', d.T_cubic_mean),       'N·m','Bearing equivalent load, Eq. (11-17) (input)'};
                rows(end+1,:) = {'FTP-75','T_cubic_mean (intermediate)',sprintf('%.1f', d.T_cubic_mean*T_ratio_int),'N·m','Bearing equivalent load, Eq. (11-17) (intermediate)'};
                rows(end+1,:) = {'FTP-75','FTP distance',      sprintf('%.3f', d.ftp_distance_m/1000),'km', 'FTP-75 cycle distance (reference)'};
            end
            if ~isempty(idx_hill)
                rows(end+1,:) = {'Hill Climb','T_steady (input)', sprintf('%.1f', ds(idx_hill).T_ss_mean),         'N·m','Validation hand check; finite-life extension'};
                rows(end+1,:) = {'Hill Climb','T_steady (intermediate)',sprintf('%.1f', ds(idx_hill).T_ss_mean*T_ratio_int), 'N·m','Intermediate shaft, finite-life extension'};
            end

            rows(end+1,:) = {'-','-','-','-','-'};

            rows(end+1,:) = {'SUPPORT','','','','Verification + prescribed geometry'};

            rows(end+1,:) = {'Drivetrain','G × eta',   sprintf('%.2f', T_ratio),'-', 'Torque ratio (output/input)'};
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
            for k = 1:2
                st = p.train.stage(k);
                name = sprintf('Stage %d', k);
                rows(end+1,:) = {name, 'Pinion / gear teeth', sprintf('%d / %d', st.N_pinion, st.N_gear), '-', sprintf('Ratio %.4f', st.ratio)}; %#ok<AGROW>
                moduleNote = 'Normal module';
                if k == 2 && p.m_n2_auto
                    moduleNote = 'Normal module, trial value: the answer key sets the final one on export';
                end
                rows(end+1,:) = {name, 'm_n', sprintf('%.2f', 1000*st.m_n), 'mm', moduleNote}; %#ok<AGROW>
                rows(end+1,:) = {name, 'Pitch diameters', sprintf('%.1f / %.1f', 1000*st.d_pinion, 1000*st.d_gear), 'mm', sprintf('Helix %.1f deg, phi_n 20 deg', st.psi_deg)}; %#ok<AGROW>
            end

            app.tbl_design.Data = rows;
            app.tg_results.SelectedTab = app.tab_summary;
        end

        function export_case_png(~, outdir, d, ~)
            % The command line draws the same plot, so students get one
            % format whichever route produced their dataset.
            equiv = [];
            if isfield(d, 'T_equiv_sin')
                equiv = d.T_equiv_sin;
            end
            SimDriveCore.exportCasePlot(outdir, d.case_name, d.Tin_applied, ...
                d.v_sim_kph, equiv, 4000, d.rms_err_kph);
        end

        function export_overview_png(~, outdir, ds, p)
            % Same figure as main.mlx writes, through SimDriveCore.
            SimDriveCore.exportOverviewPlot(outdir, string({ds.case_name}), ...
                {ds.Tin_applied}, {ds.v_sim_kph}, p.Tmax, p.Tregen, 4000);
        end

        function set_status(app, msg, clr)
            app.lbl_status.Text = msg;
            if nargin > 2
                app.lbl_status.FontColor = clr;
            end
            drawnow;
        end

    end

    methods (Access = private)

        function [p, err] = get_params(app)
            err = '';
            p   = struct();

            try
                p.m_vehicle   = app.ef_mass.Value;
                p.Cd          = app.ef_Cd.Value;
                p.A           = app.ef_A.Value;
                p.Crr         = app.ef_Crr.Value;
                p.Tmax        = app.ef_Tmax.Value;
                p.Pmax_kW     = app.ef_Pmax_kW.Value;
                p.Pmax_W      = p.Pmax_kW * 1e3;
                p.omega_max   = app.ef_nmax_rpm.Value * pi/30;
                p.Tregen      = app.ef_Tregen.Value;
                p.I_motor     = app.ef_I_motor.Value;
                p.eta_dt      = app.ef_eta_dt.Value;
                p.wheel_R     = app.ef_wheel_R.Value;
                p.T_ambient_C = app.ef_T_ambient.Value;
                p.train_options = app.train_options();
                p.m_n2_auto   = logical(app.cb_mn2_auto.Value);
                p.theta_hill_deg = app.ef_theta_hill.Value;
                p.stop_drag   = app.ef_stop_drag.Value;
                p.stop_hill   = app.ef_stop_hill.Value;
                p.sn_exponent = app.ef_sn_exp.Value;
            catch ME
                err = ['Parameter read error: ' ME.message];
                return;
            end

            args = namedargs2cell(p.train_options);
            [p.train, problems] = buildGearTrain(args{:});
            if ~isempty(problems)
                err = char(strjoin(problems, newline));
                return;
            end
            p.gear_ratio = p.train.G;

            % Effective mass from R_w and tire profile
            p.tire_profile = app.dd_tire_profile.Value;
            switch p.tire_profile
                case 'low',      rim_ratio = 0.74;
                case 'standard', rim_ratio = 0.68;
                case 'high',     rim_ratio = 0.62;
                otherwise,       rim_ratio = 0.68;
            end
            m_whl     = 20;   % typical assembly mass [kg]
            I_wh      = 0.5 * m_whl * (1 + rim_ratio^2) * p.wheel_R^2;
            p.delta_m = (p.I_motor * p.gear_ratio^2 + 4 * I_wh) / p.wheel_R^2;
            p.m       = p.m_vehicle + p.delta_m;

            p.g       = 9.81;
            p_atm     = 101325;
            RH        = 0.50;
            R_d       = 287.058;
            R_v       = 461.495;
            T_K       = p.T_ambient_C + 273.15;
            p_sat     = 610.78 * exp(17.27 * p.T_ambient_C / (p.T_ambient_C + 237.3));
            p_v       = RH * p_sat;
            p.rho     = (p_atm - p_v) / (R_d * T_K) + p_v / (R_v * T_K);

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
            p.fatigue_method = 'approach-a-equivalent-sinusoid';
            if p.m <= 0,       err = 'Vehicle mass must be positive.'; return; end
            if p.Tmax <= 0,    err = 'T_max must be positive.';         return; end
            if p.Pmax_W <= 0,  err = 'P_max must be positive.';         return; end
            if p.omega_max <= p.Pmax_W/p.Tmax, err = 'n_max must be above the motor base speed.'; return; end
            if p.wheel_R <= 0, err = 'Wheel radius must be positive.';  return; end
            if p.run_FTP && strlength(p.ftp_file) > 0 && ~isfile(p.ftp_file)
                err = ['FTP file not found: ' p.ftp_file]; return;
            end
            if p.run_FTP && ~(exist('rainflow', 'file') || exist('rainflow', 'builtin'))
                err = ['rainflow() is required for FTP-75 fatigue load extraction. ' ...
                    'Install the Signal Processing Toolbox before running the FTP-75 case.']; return;
            end
        end

    end

    methods (Access = private)  % sim helper wrappers

        function close_runtime_model(~, modelName)
            SimDriveCore.closeRuntimeModel(modelName);
        end

        function [t_s, v_kph] = load_ftp75(~, fname, units)
            [t_s, v_kph] = SimDriveCore.loadFtp75SpeedTrace(fname, units);
        end

        function [T_mean_eq, T_alt_eq, rf_data] = compute_fatigue_load(~, T_ts, v_kph_ts, vmin_kph, method, m_sn)
            [T_mean_eq, T_alt_eq, rf_data] = SimDriveCore.computeFatigueLoad( ...
                T_ts, v_kph_ts, vmin_kph, method, m_sn);
        end

        function T_eq = compute_bearing_equivalent_torque(~, T_ts, omega_ts)
            T_eq = SimDriveCore.computeBearingEquivalentTorque(T_ts, omega_ts);
        end

        function [t_out, y_out] = bin_average(~, t_in, y_in, maxPts)
            [t_out, y_out] = SimDriveCore.binAverage(t_in, y_in, maxPts);
        end

        function create_model_EV_blocks(~, modelName, m_veh, m_eff, Cd, A, rho, Crr, g, Rw, G, eta, Ts_pid, dt_sim, slewNmPerS)
            SimDriveCore.createModelEVBlocks(modelName, m_veh, m_eff, Cd, A, rho, Crr, ...
                g, Rw, G, eta, Ts_pid, dt_sim, slewNmPerS);
        end

    end

    methods (Access = private)

        function start_animation(app)
            if isempty(app.UIFigure) || ~isvalid(app.UIFigure) || ...
                    isempty(app.ax_schematic) || ~isvalid(app.ax_schematic)
                app.anim_running = false;
                return;
            end

            app.anim_tick    = 0;
            app.anim_running = true;

            if ~isempty(app.anim_timer) && isa(app.anim_timer, 'timer')
                try
                    stop(app.anim_timer);
                catch
                end
                delete(app.anim_timer);
            end

            app.anim_timer = timer( ...
                'ExecutionMode', 'fixedRate', ...
                'BusyMode',      'drop', ...
                'Period',        app.anim_period, ...
                'TimerFcn',      @(~,~) app.anim_step());
            start(app.anim_timer);
        end

        function stop_animation(app, restartIdle)
            if nargin < 2
                restartIdle = true;
            end

            app.anim_running = false;

            if ~isempty(app.anim_timer) && isa(app.anim_timer, 'timer')
                try stop(app.anim_timer); catch; end
                delete(app.anim_timer);
            end
            app.anim_timer = [];

            app.anim_mode = 'idle';
            if restartIdle
                app.start_animation();
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
