function outputDirectory = generateLoadCases()
%GENERATELOADCASES Run the load cases and write the complete two-stage export.
%   outputDirectory = GENERATELOADCASES() runs main.mlx, selects the stage-2
%   module with the answer key (selectStage2Module), or uses the default
%   5 mm module while the key is still encrypted, and writes the full
%   two-stage gear train into Design_Summary.mat. Use this entry point for
%   command-line runs.

    instructorDirectory = fileparts(mfilename('fullpath'));
    repositoryRoot = fileparts(instructorDirectory);
    outputDirectory = fullfile(repositoryRoot, "exports_design_ready");

    previousDirectory = pwd;
    directoryCleanup = onCleanup(@() cd(previousDirectory));
    cd(instructorDirectory);
    evalin('base', 'run(''main.mlx'')');
    % main.mlx leaves its model-cleanup guard in the base workspace so its
    % figures/results remain available interactively. Dispose it while the
    % instructor folder (and SimDriveCore) is still resolvable.
    evalin('base', 'clear modelCleanup');

    summaryFile = fullfile(outputDirectory, "Design_Summary.mat");
    if ~isfile(summaryFile)
        error("SimDrive:GenerateLoadCases:MissingSummary", ...
            "The load-case run did not create %s.", summaryFile);
    end
    summary = load(summaryFile);

    % Two-stage gear train: the default course train with the stage-2
    % module the answer key selects, exactly as the dashboard export does.
    solutionDirectory = fullfile(instructorDirectory, "solution");
    addpath(solutionDirectory);
    pathCleanup = onCleanup(@() rmpath(solutionDirectory));
    dragIndex = find(string({summary.ds.case_name}) == "DragRace", 1);
    trainOptions = struct('N1', 20, 'N2', 60, 'N3', 20, 'N4', 60, 'm_n1_mm', 4, ...
        'm_n2_mm', NaN, 'psi1_deg', 25, 'psi2_deg', 25, 'phi_n_deg', 20);
    if exist("selectStage2Module", "file") == 2
        trainOptions.m_n2_mm = selectStage2Module(trainOptions, summary.ds(dragIndex).T_peak, ...
            summary.Pmax/summary.Tmax, summary.eta_dt, summary.wheel_R);
    else
        % Answer key still encrypted (instructor_answer_key.7z): use the
        % default stage-2 module instead of the key's selection.
        trainOptions.m_n2_mm = 5;
    end
    args = namedargs2cell(trainOptions);
    train = buildGearTrain(args{:});
    for f = string(fieldnames(train.summary))'
        summary.(f) = train.summary.(f);
    end
    save(summaryFile, '-struct', 'summary');

    fprintf("Export complete: %s\n", outputDirectory);
end
