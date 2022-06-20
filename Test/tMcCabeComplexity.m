classdef tMcCabeComplexity < matlab.unittest.TestCase
% Qualifies low McCabe complexity of MATLAB code files in current project
%
% This unit test inspects all of the MATLAB code files in the current
% project and checks their McCabe complexity.  If any exceed the
% MaximumComplexity their names are reported and the test fails.

    properties (TestParameter)
        MaximumComplexity = struct('Ten', 10);
    end

    methods (TestClassSetup)
        function assumeProjectLoaded(testCase)
            testCase.assumeNotEmpty(matlab.project.currentProject, 'No project loaded');
        end
    end
    
    methods (Test)
                
        function shouldHaveLowComplexity(testCase, MaximumComplexity)
            % Get project files
            cp = currentProject;            
            projectfiles = [cp.Files(:).Path];
            codefiles = projectfiles(endsWith(projectfiles, [".m" ".mlx" ".mlapp"]));
            
            % Get cyclomatic complexity
            [cyc, ~] = checkcode(codefiles, '-cyc');
            
            % Loop over files checking complexity on each.
            for ii = 1:numel(codefiles)
                cycii = cyc{ii};
                for jj = 1:numel(cycii)
                    % Extract cyc
                    cycjj = regexp(string(cycii(jj).message), "is (\d*)\.", 'tokens'); % Get all digits at end of message.
                    if ~isempty(cycjj)  
                        % Other messages will sometimes appear as well that
                        % don't contain -cyc info.  Skip them.
                        cycjj = double(cycjj{1}); % Extract from cell, convert to couble
                        
                        % Fail test if >= MaximumComplexity;
                        testCase.verifyLessThan(cycjj, MaximumComplexity, sprintf('McCabe Complexity of %i\nIn: %s', cycjj, codefiles(ii)));
                    
                    end
                    
                end
                
            end
            
        end       
           
    end
 
end

% Copyright 2020 The MathWorks, Inc.