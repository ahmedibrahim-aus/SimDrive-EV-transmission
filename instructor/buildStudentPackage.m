function packageFile = buildStudentPackage(options)
%BUILDSTUDENTPACKAGE Build the student hand-out folder and its archive.
%   packageFile = BUILDSTUDENTPACKAGE() reads the instructor export in
%   exports_design_ready/, reduces each load case to the single torque curve
%   students need, refreshes student_package/ with that dataset plus the
%   templates, documents, project brief, notch helper and licenses, and then
%   writes a ZIP of the same folder to release/. The hand-out folder and the
%   ZIP always hold identical files.
%
%   packageFile = BUILDSTUDENTPACKAGE(DatasetDirectory=folder,
%   PackageDirectory=folder, OutputFile=file) overrides the instructor
%   export folder, the hand-out folder, and the archive path. The instructor
%   solution is never included.

    arguments
        options.DatasetDirectory (1,1) string = ""
        options.PackageDirectory (1,1) string = ""
        options.OutputFile (1,1) string = ""
    end

    instructorDirectory = fileparts(mfilename('fullpath'));
    repositoryRoot = string(fileparts(instructorDirectory));
    packageName = "SimDrive_Student_Package_v1.0.0";
    sourcePackageDirectory = fullfile(repositoryRoot, "student_package");

    datasetDirectory = valueOrDefault(options.DatasetDirectory, ...
        fullfile(repositoryRoot, "exports_design_ready"));
    packageDirectory = valueOrDefault(options.PackageDirectory, ...
        sourcePackageDirectory);
    packageFile = valueOrDefault(options.OutputFile, ...
        fullfile(repositoryRoot, "release", packageName + ".zip"));
    datasetDirectory = canonicalPath(datasetDirectory);
    packageDirectory = canonicalPath(packageDirectory);
    packageFile = canonicalPath(packageFile);
    validateDestinations(repositoryRoot, datasetDirectory, packageDirectory, packageFile);

    if ~isfolder(datasetDirectory)
        error("SimDrive:StudentPackage:MissingDataset", ...
            "Dataset folder not found: %s. Generate the instructor load cases first.", ...
            datasetDirectory);
    end

    stagingRoot = string(tempname);
    packageRoot = fullfile(stagingRoot, packageName);
    mkdir(packageRoot);
    cleanup = onCleanup(@() removeStagingFolder(stagingRoot));

    % Every file below is tracked in the repository. The dataset is the only
    % generated content, and it is reduced from the instructor export.
    copySourceFiles(fullfile(repositoryRoot, "student"), packageRoot, [
        "Student_01_Load_Inputs.m"
        "Student_02_Gear_Design.m"
        "Student_03_Shaft_Design.m"
        "Student_04_Bearing_Selection.m"
        "ASSIGNMENT_BRIEF.md"
        "DESIGN_REPORT_TEMPLATE.md"
        "DATA_DICTIONARY.md"]);
    copySourceFiles(repositoryRoot, packageRoot, ["LICENSE"; "LICENSE-docs"]);

    % Students call the notch helper in Student 03, so it ships with them even
    % though the canonical copy sits beside the answer key.
    copySourceFiles(fullfile(repositoryRoot, "instructor", "solution"), ...
        packageRoot, "computeShoulderNotchFactors.m");

    % The hand-out README and the Word brief are authored in student_package/
    % and are carried through every rebuild.
    copySourceFiles(sourcePackageDirectory, packageRoot, [
        "README.md"
        "SimDrive_Project_Brief.docx"]);

    writeStudentDataset(datasetDirectory, fullfile(packageRoot, "exports_design_ready"));

    % Build the archive before touching either published output. No previous
    % files are reused: both outputs come entirely from this staging folder.
    stagedArchive = fullfile(stagingRoot, packageName + ".zip");
    zip(stagedArchive, packageRoot);
    refreshPackageDirectory(packageRoot, packageDirectory);

    outputDirectory = fileparts(packageFile);
    if strlength(outputDirectory) > 0 && ~isfolder(outputDirectory)
        mkdir(outputDirectory);
    end
    movefile(stagedArchive, packageFile, 'f');

    shipped = dir(fullfile(packageDirectory, '**', '*'));
    shipped = shipped(~[shipped.isdir]);
    fprintf('Student package built from %s\n', datasetDirectory);
    fprintf('  %d files in %s\n', numel(shipped), packageDirectory);
    fprintf('  ZIP: %s\n', packageFile);
    fprintf('  No instructor solution files are included.\n');
end

function value = canonicalPath(value)
    % Absolute path with relative parts and .. resolved through the deepest
    % existing folder; a tail that does not exist yet is appended as written.
    value = char(value);
    tail = '';
    while ~isfolder(value) && ~isfile(value)
        [parent, name, ext] = fileparts(value);
        if isempty(parent), parent = pwd; end
        if strcmp(parent, value), break; end
        tail = fullfile([name ext], tail);
        value = parent;
    end
    listing = dir(value);
    if isfile(value)
        value = fullfile(listing(1).folder, listing(1).name);
    elseif ~isempty(listing)
        value = listing(1).folder;
    end
    value = string(fullfile(value, tail));
end

function tf = withinPath(child, parent)
    if ispc
        child = lower(child);
        parent = lower(parent);
    end
    tf = child == parent || startsWith(child, parent + filesep);
end

function validateDestinations(repositoryRoot, dataset, destination, archive)
    repositoryRoot = canonicalPath(repositoryRoot);
    defaultPackage = canonicalPath(fullfile(repositoryRoot, 'student_package'));
    releaseDirectory = canonicalPath(fullfile(repositoryRoot, 'release'));
    if withinPath(repositoryRoot, destination) || ...
            (withinPath(destination, repositoryRoot) && destination ~= defaultPackage) || ...
            withinPath(dataset, destination) || withinPath(destination, dataset) || ...
            isfile(destination)
        error('SimDrive:StudentPackage:UnsafeDestination', ...
            'PackageDirectory must be the hand-out folder or a separate output folder, not a source or data folder, or a folder that contains one.');
    end
    [~, ~, extension] = fileparts(archive);
    if ~strcmpi(extension, '.zip') || isfolder(archive) || ...
            withinPath(archive, destination) || withinPath(archive, dataset) || ...
            (withinPath(archive, repositoryRoot) && ~withinPath(archive, releaseDirectory))
        error('SimDrive:StudentPackage:UnsafeArchive', ...
            'OutputFile must be a ZIP outside source/data/hand-out folders (use release/ inside the repository).');
    end
end

function value = valueOrDefault(given, fallback)
    if strlength(given) == 0
        value = fallback;
    else
        value = given;
    end
end

function copySourceFiles(sourceDirectory, targetDirectory, fileNames)
    for fileName = reshape(string(fileNames), 1, [])
        sourceFile = fullfile(sourceDirectory, fileName);
        if ~isfile(sourceFile)
            error("SimDrive:StudentPackage:MissingSource", ...
                "Required student file is missing: %s", sourceFile);
        end
        copyfile(sourceFile, targetDirectory);
    end
end

function writeStudentDataset(sourceDirectory, targetDirectory)
%WRITESTUDENTDATASET Reduce the instructor export to the student dataset.
%   Each case keeps its ds_single scalars untouched and gains one binned
%   torque curve with a note saying what that curve is. For FTP-75 the curve
%   is the equivalent sinusoid, not the raw tracked torque.

    maximumPoints = 2000;
    % The FTP-75 note quotes the curve's own arithmetic mean, computed below
    % from the data, so it stays right for any vehicle or gear train.
    ftpNote = @(curveMean) sprintf(['Equivalent sinusoidal torque for the ' ...
        'FTP-75 city cycle: the single fatigue cycle the drive cycle is ' ...
        'reduced to. This is the curve the Goodman fatigue calculation uses, ' ...
        'not the raw tracked motor torque. Period 120 s, centered on T_mean_eq ' ...
        'with amplitude T_alt_eq. The cycle is not a whole number of periods, ' ...
        'so the arithmetic mean of this curve is %.1f N·m rather than exactly ' ...
        'T_mean_eq; take the centerline from the half-range, not from mean().'], ...
        curveMean);
    caseSpecification = {
        "FTP75_Outputs.mat",     "T_equiv_sin_out", ftpNote
        "HillClimb_Outputs.mat", "Tin_applied",     'Motor torque applied during the sustained hill climb.'
        "DragRace_Outputs.mat",  "Tin_applied",     'Motor torque applied during full-throttle acceleration.'};

    mkdir(targetDirectory);
    summary = load(fullfile(sourceDirectory, 'Design_Summary.mat'));
    requiredCases = ["FTP75" "HillClimb" "DragRace"];
    if ~isfield(summary, 'ds') || numel(summary.ds) ~= 3 || ...
            ~all(ismember(requiredCases, string({summary.ds.case_name})))
        error('SimDrive:StudentPackage:IncompleteRun', ...
            'A fresh student package requires all three cases in the latest Design_Summary.');
    end
    % Students receive only the documented vehicle and gear-train data
    % (DATA_DICTIONARY.md). The per-case summary ds is left out: it carries
    % derived output-shaft torques that would answer part of Student 01.
    studentFields = ["gear_ratio" "i1" "i2" "eta_dt" "wheel_R" "N1" "N2" "N3" "N4" ...
        "m_n1" "m_n2" "m_t1" "m_t2" "phi_n_deg" "phi_t1_deg" "phi_t2_deg" ...
        "psi1_deg" "psi2_deg" "d1" "d2" "d3" "d4" "Tmax" "Pmax" "omega_base" ...
        "v_base" "omega_max" "v_top" "m_vehicle" "Crr" "Cd" "A_frontal" ...
        "rho_air" "theta_hill_deg"];
    studentSummary = rmfield(summary, setdiff(fieldnames(summary), studentFields));
    save(fullfile(targetDirectory, 'Design_Summary.mat'), '-struct', 'studentSummary');

    for k = 1:size(caseSpecification, 1)
        caseFile = caseSpecification{k, 1};
        sourceFile = fullfile(sourceDirectory, caseFile);
        if ~isfile(sourceFile)
            error("SimDrive:StudentPackage:MissingCase", ...
                "Instructor export is missing %s.", sourceFile);
        end
        exported = load(sourceFile);
        expected = summary.ds(string({summary.ds.case_name}) == requiredCases(k));
        if isfield(exported, 'ds_single')
            % CLI summaries may also contain derived output-shaft torques.
            % Compare every case field; retain those legitimate summary extras.
            expected = rmfield(expected, setdiff(fieldnames(expected), fieldnames(exported.ds_single)));
        end
        if ~isfield(exported, 'ds_single') || ~isequaln(exported.ds_single, expected)
            error('SimDrive:StudentPackage:InconsistentRun', ...
                '%s does not match the latest Design_Summary. Export all cases from one completed run.', caseFile);
        end
        curveName = caseSpecification{k, 2};
        if ~isfield(exported, curveName) || ~isfield(exported, "ds_single")
            error("SimDrive:StudentPackage:UnexpectedExport", ...
                "%s does not contain %s and ds_single.", sourceFile, curveName);
        end
        curve = exported.(curveName);
        sampleCount = numel(curve.Time);
        keep = round(linspace(1, sampleCount, min(maximumPoints, sampleCount)));

        studentCase.torque_Nm = timeseries(curve.Data(keep), curve.Time(keep), ...
            'Name', 'torque_Nm');
        note = caseSpecification{k, 3};
        if isa(note, 'function_handle')
            note = note(mean(curve.Data));
        end
        studentCase.torque_note = note;
        studentCase.ds_single = exported.ds_single;
        save(fullfile(targetDirectory, caseFile), '-struct', 'studentCase', '-v7');
        clear studentCase
    end

    copySourceFiles(sourceDirectory, targetDirectory, [
        "FTP75_Plot.png"
        "HillClimb_Plot.png"
        "DragRace_Plot.png"
        "Overview_AllCases.png"]);
end

function refreshPackageDirectory(packageRoot, packageDirectory)
%REFRESHPACKAGEDIRECTORY Make the hand-out folder match the staged package.
% Refuse unrelated content and overwrite only named generated files. Never
% recursively remove a caller-selected directory, even the default hand-out.
    if isfolder(packageDirectory)
        existing = dir(fullfile(packageDirectory, '**', '*'));
        existing = existing(~ismember({existing.name}, {'.','..'}));
        for k = 1:numel(existing)
            target = string(fullfile(existing(k).folder, existing(k).name));
            relative = extractAfter(target, packageDirectory + filesep);
            staged = fullfile(packageRoot, relative);
            if ~withinPath(canonicalPath(target), packageDirectory) || ...
                    (~isfile(staged) && ~isfolder(staged))
                error('SimDrive:StudentPackage:UnrelatedContent', ...
                    'student_package/ contains a file the builder did not create: %s', target);
            end
        end
    end
    copyfile(packageRoot, packageDirectory);
end

function removeStagingFolder(stagingRoot)
    if isfolder(stagingRoot)
        rmdir(stagingRoot, 's');
    end
end
