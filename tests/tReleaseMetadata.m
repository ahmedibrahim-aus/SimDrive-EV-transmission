classdef tReleaseMetadata < matlab.unittest.TestCase
    %TRELEASEMETADATA GitHub release/version consistency checks.

    properties
        RepoRoot
    end

    methods (TestClassSetup)
        function setupRoot(testCase)
            testCase.RepoRoot = fileparts(fileparts(mfilename('fullpath')));
        end
    end

    methods (Test, TestTags = {'Unit'})
        function versionIsConsistentAcrossReleaseFiles(testCase)
            releaseVersion = '4.0.0';
            contentsText = fileread(fullfile(testCase.RepoRoot, 'Contents.m'));
            citationText = fileread(fullfile(testCase.RepoRoot, 'CITATION.cff'));
            changeText = fileread(fullfile(testCase.RepoRoot, 'CHANGELOG.md'));
            builderText = fileread(fullfile(testCase.RepoRoot, 'tools', ...
                'buildStudentPackage.m'));
            appText = fileread(fullfile(testCase.RepoRoot, 'instructor', 'InstructorApp.m'));
            expectedFile = fullfile(testCase.RepoRoot, 'docs', 'EXPECTED_RESULTS.md');

            testCase.verifyTrue(contains(contentsText, ['Version ' releaseVersion]));
            testCase.verifyTrue(contains(citationText, ['version: "' releaseVersion '"']));
            testCase.verifyTrue(contains(changeText, ['## [' releaseVersion ']']));
            testCase.verifyTrue(contains(builderText, ['_v' releaseVersion '"']));
            testCase.verifyTrue(contains(appText, ['_v' releaseVersion '"']));
            if isfile(expectedFile)   % encrypted until extracted
                testCase.verifyTrue(contains(fileread(expectedFile), ['v' releaseVersion]));
            end
        end

        function publicTextHasNoDeveloperAbsolutePath(testCase)
            offendingFiles = testCase.findDeveloperPaths();
            testCase.verifyEmpty(offendingFiles, ...
                'Public text/code contains a developer-specific absolute path.');
        end

        function readmeLinksInstructorReleaseMaterial(testCase)
            readmeText = fileread(fullfile(testCase.RepoRoot, 'README.md'));
            testCase.verifyTrue(contains(readmeText, 'docs/QUICKSTART.md'));
            testCase.verifyTrue(contains(readmeText, 'buildStudentPackage'));
            testCase.verifyTrue(contains(readmeText, 'generateLoadCases'));
        end
    end

    methods (Access = private)
        function offendingFiles = findDeveloperPaths(testCase)
            extensions = ["*.m" "*.md" "*.cff" "*.yml"];
            % Any local absolute path: a drive letter followed by a folder,
            % or a Unix home folder. Web addresses (https://) do not match.
            localPath = '(?<![A-Za-z])[A-Za-z]:[\\/][A-Za-z_~]|(?<![A-Za-z:])/(Users|home)/[A-Za-z]';
            offendingFiles = strings(0, 1);
            for extension = extensions
                files = dir(fullfile(testCase.RepoRoot, "**", extension));
                files = files(~contains({files.folder}, filesep + "artifacts"));
                for file = files'
                    filePath = fullfile(file.folder, file.name);
                    if ~isempty(regexp(fileread(filePath), localPath, 'once'))
                        offendingFiles(end+1, 1) = string(filePath); %#ok<AGROW>
                    end
                end
            end
        end
    end
end
