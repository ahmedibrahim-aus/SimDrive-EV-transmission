function ok = validate_release()
%VALIDATE_RELEASE  One-shot pre-release check for the SimDrive module.
%   ok = VALIDATE_RELEASE() puts the instructor folder on the path and runs the
%   full test suite (file layout, core math, and a short Simulink smoke run),
%   then prints a release-readiness verdict. Returns true if all tests pass.
%
%   Run this before tagging a release or submitting to File Exchange.

    root = fileparts(fileparts(mfilename('fullpath')));   % tests/ -> repo root
    instDir = fullfile(root, 'instructor');
    addpath(instDir);
    cleanup = onCleanup(@() rmpath(instDir));

    fprintf('================ SimDrive release validation ================\n');
    fprintf('  repo: %s\n\n', root);

    results = runtests(fullfile(root, 'tests'));

    nPass = nnz([results.Passed]);
    nFail = nnz([results.Failed]);
    nInc  = nnz([results.Incomplete]);
    fprintf('\n------------------------------------------------------------\n');
    fprintf('  %d passed, %d failed, %d incomplete of %d  (%.1f s)\n', ...
        nPass, nFail, nInc, numel(results), sum([results.Duration]));

    ok = (nFail == 0) && (nInc == 0);
    if ok
        fprintf('  RELEASE VALIDATION: PASS\n');
    else
        fprintf('  RELEASE VALIDATION: REVIEW FAILURES ABOVE\n');
    end
    fprintf('============================================================\n');
end
