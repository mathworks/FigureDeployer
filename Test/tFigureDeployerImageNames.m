classdef tFigureDeployerImageNames < matlab.unittest.TestCase
% Tests the figure deployer image names

    methods (Test)
        
        function shouldAcceptImageNameWithExtension(testCase)
            DF = FigureDeployer(ImageName='testImage.gif', ImageType='gif');
            
            import matlab.unittest.constraints.StringComparator
            import matlab.unittest.constraints.IsEqualTo
            testCase.verifyThat(DF.ImageName, IsEqualTo("testImage.gif", 'Using', StringComparator));
                        
        end
        
        function shouldUseTempnameWithExtension(testCase)
            DF = FigureDeployer(ImageType='svg');
            
            import matlab.unittest.constraints.EndsWithSubstring
            import matlab.unittest.constraints.StartsWithSubstring
            testCase.verifyThat(DF.ImageName, EndsWithSubstring(".svg"));
            testCase.verifyThat(DF.ImageName, StartsWithSubstring(tempdir));
            
        end
        
        function shouldAcceptFullFileImageName(testCase)
            import matlab.unittest.constraints.StringComparator
            import matlab.unittest.constraints.IsEqualTo
            
            fname = tempname + "12.jpg";
            DF = FigureDeployer(ImageName=fname);
            testCase.verifyThat(DF.ImageName, IsEqualTo(fname, 'Using', StringComparator));
            
        end    

        function testSetImageName(testCase)
            DF = FigureDeployer(ImageName='testImage.gif', ImageType='gif');
            DF.ImageName = 'bobbysue.jpg';
            testCase.verifyMatches(DF.ImageName, "bobbysue.jpg")

        end
               
    end
 
end
% Copyright 2020 The MathWorks, Inc.