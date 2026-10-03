function results = run_all_tests()
%RUN_ALL_TESTS  Run the full SimDrive test suite (all tests in this folder).
%   results = RUN_ALL_TESTS() runs every test class in tests/ and prints a
%   one-line summary. Returns the matlab.unittest.TestResult array.
%
%   Example:
%       cd tests
%       run_all_tests

    here = fileparts(mfilename('fullpath'));
    results = runtests(here);
    fprintf('\n%d passed, %d failed, %d incomplete of %d  (%.1f s total)\n', ...
        nnz([results.Passed]), nnz([results.Failed]), nnz([results.Incomplete]), ...
        numel(results), sum([results.Duration]));
end
