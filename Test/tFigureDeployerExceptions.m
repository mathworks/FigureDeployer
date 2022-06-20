classdef tFigureDeployerExceptions < matlab.unittest.TestCase
% Tests figure deployer exceptions

    methods (Test)
        
        function shouldErrorWithBadProperties(testCase)
            testCase.verifyError(@()FigureDeployer(Height=-10), 'MATLAB:validators:mustBePositive')
            testCase.verifyError(@()FigureDeployer(Height=[10 30]), 'MATLAB:validation:IncompatibleSize')
            testCase.verifyError(@()FigureDeployer(Height=3.14), 'MATLAB:validators:mustBeInteger')
            testCase.verifyError(@()FigureDeployer(Height='S'), 'MATLAB:validators:mustBeNumeric')
            testCase.verifyError(@()FigureDeployer(Width=-10), 'MATLAB:validators:mustBePositive')
            testCase.verifyError(@()FigureDeployer(Width=[10 30]), 'MATLAB:validation:IncompatibleSize')
            testCase.verifyError(@()FigureDeployer(Width=3.14), 'MATLAB:validators:mustBeInteger')
            testCase.verifyError(@()FigureDeployer(Width='S'), 'MATLAB:validators:mustBeNumeric')
            testCase.verifyError(@()FigureDeployer(ImageType=-10), 'MATLAB:validators:mustBeMember')
            testCase.verifyError(@()FigureDeployer(ImageType='Sean'), 'MATLAB:validators:mustBeMember')
            testCase.verifyError(@()FigureDeployer(ImageName=['Hello'; 'World']), 'MATLAB:validation:IncompatibleSize')
            testCase.verifyError(@()FigureDeployer(Resolution='H'), 'MATLAB:validators:mustBeNumeric')
            testCase.verifyError(@()FigureDeployer(Resolution=pi), 'MATLAB:validators:mustBeInteger')
            testCase.verifyError(@()FigureDeployer(Resolution=-100), 'MATLAB:validators:mustBePositive')
            testCase.verifyError(@()FigureDeployer(OutputType=pi), 'MATLAB:validators:mustBeMember')
            testCase.verifyError(@()FigureDeployer(OutputType=['Hello'; 'World']), 'MATLAB:validation:IncompatibleSize')
        
        end
           
        function shouldErrorForEmptyFigure(testCase)
            DF = FigureDeployer(Figure=matlab.ui.Figure.empty);
            testCase.verifyError(@()getImage(DF), 'FigureDeployer:InvalidFigure')
            testCase.verifyError(@()getStream(DF), 'FigureDeployer:InvalidFigure')   
        
        end
        
        function shouldErrorForDeletedFigure(testCase)
            fig = figure;
            DF = FigureDeployer(Figure=fig);
            delete(fig);
            testCase.verifyError(@()getImage(DF),'FigureDeployer:InvalidFigure')
            testCase.verifyError(@()getStream(DF), 'FigureDeployer:InvalidFigure')                                  
        
        end
                
    end
 
end
% Copyright 2020 The MathWorks, Inc.