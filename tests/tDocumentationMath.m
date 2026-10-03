classdef tDocumentationMath < matlab.unittest.TestCase
    % Guard the GitHub math block boundaries in the two model references.
    properties (TestParameter)
        Document = {'APPROACH_A.md', 'MathematicalModels.md'}
    end
    methods (Test, TestTags = {'Unit'})
        function displayMathHasPortableBoundaries(testCase, Document)
            root = fileparts(fileparts(mfilename('fullpath')));
            source = fileread(fullfile(root, 'docs', Document));
            source = strrep(source, sprintf('\r\n'), newline);
            testCase.verifyFalse(contains(source, '\['));
            testCase.verifyFalse(contains(source, '\]'));
            delimiters = regexp(source, '(?m)^ *\$\$[ \t]*$', 'match');
            blocks = regexp(source, '(?<=\n\n) *\$\$\n[^$]+\n *\$\$(?=\n\n)', 'match');
            testCase.verifyNotEmpty(blocks);
            testCase.verifyEqual(numel(delimiters), 2 * numel(blocks));
        end
    end
end
