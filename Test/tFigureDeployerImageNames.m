classdef tFigureDeployerImageNames < matlab.unittest.TestCase
% Tests the figure deployer image names

    properties (TestParameter)
        RasterImageTypes = {'bmp', 'png', 'jpg', 'gif'}
    end
    
    methods (Test)
        
        function shouldAcceptImageNameWithExtension(testCase)
            DF = FigureDeployer('ImageName', 'testImage.bmp', 'ImageType', 'bmp');
            
            import matlab.unittest.constraints.StringComparator
            import matlab.unittest.constraints.IsEqualTo
            testCase.verifyThat(DF.ImageName, IsEqualTo("testImage.bmp", 'Using', StringComparator));
                        
        end
        
        function shouldUseTempnameWithExtension(testCase)
            DF = FigureDeployer('ImageType', 'bmp');
            
            import matlab.unittest.constraints.EndsWithSubstring
            import matlab.unittest.constraints.StartsWithSubstring
            testCase.verifyThat(DF.ImageName, EndsWithSubstring(".bmp"));
            testCase.verifyThat(DF.ImageName, StartsWithSubstring(tempdir));
            
        end
        
        function shouldAcceptFullFileImageName(testCase)
            import matlab.unittest.constraints.StringComparator
            import matlab.unittest.constraints.IsEqualTo
            
            fname = tempname + "12.jpg";
            DF = FigureDeployer('ImageName', fname);
            testCase.verifyThat(DF.ImageName, IsEqualTo(fname, 'Using', StringComparator));
            
        end          
               
    end
 
end