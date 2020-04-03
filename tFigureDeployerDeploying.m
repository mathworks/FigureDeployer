classdef tFigureDeployerDeploying < matlab.unittest.TestCase
% Tests the figure deployer with a figure

    properties
        TempFilename
        Figure
    end
    
    properties (TestParameter)
        RasterImageTypes = {'bmp', 'png', 'jpg', 'gif'} % Different raster image types
        StreamOutputTypes = {'uint8', 'int8'} % Different byte stream data types
    end
    
    methods (TestMethodSetup)

        function makeFigure(testCase)
            testCase.Figure = figure;
            testCase.addTeardown(@()delete(testCase.Figure));
            plot(sin(1:100))
            xlabel('X')
            ylabel('Hello World','FontAngle','italic')
            patch([0 10 10 0],[0 0 1 1],'b','FaceAlpha',0.3)     
            
        end
        
    end
 
    methods (Test)

        function shouldRespectWidthHeight(testCase, RasterImageTypes)
            DF = FigureDeployer('Figure', testCase.Figure, 'ImageType', RasterImageTypes);
            DF.Width = 300;
            DF.Height = 500;
            [imdata, imname] = getImage(DF);                        
            testCase.addTeardown(@()delete(imname));
            testCase.verifySize(imdata, [500 300 3]);            
            
        end
       
        function shouldConstructWithDefaults(testCase)
            DF = FigureDeployer;
            testCase.verifySameHandle(DF.Figure, testCase.Figure);            
            testCase.verifyMatches(DF.ImageType, 'png');
            testCase.verifyEqual(DF.Width, 600);
            testCase.verifyEqual(DF.Height, 450);
            testCase.verifyEqual(DF.Resolution, 150);
            
        end
             
        function shouldConstructWithInputs(testCase)
            other_figure = figure;
            closer = onCleanup(@()close(other_figure));
            DF = FigureDeployer('Figure', testCase.Figure, 'Width', 200, 'Height', 200, ...
                    'ImageName', 'testImage', 'ImageType', 'svg', 'Resolution', 300);
            testCase.verifySameHandle(DF.Figure, testCase.Figure);
            testCase.verifyEqual(DF.Width, 200);
            testCase.verifyEqual(DF.Height, 200);
            testCase.verifyMatches(DF.ImageName, 'testImage.svg');
            testCase.verifyMatches(DF.ImageType, 'svg');
            testCase.verifyEqual(DF.Resolution, 300);
            
        end
                    
        function shouldGenerateRasterImageFile(testCase, RasterImageTypes)
            DF = FigureDeployer('Figure', testCase.Figure, ...
                'ImageType', RasterImageTypes, 'ImageName', 'testImage');
            [imdata, imname] = getImage(DF);
            testCase.addTeardown(@()delete(imname));
            testCase.assertMatches(imname, ['testImage.' RasterImageTypes]);
            [Ifile, map] = imread(imname);
            
            % Indexed images
            if ~isempty(map)
                Ifile = im2uint8(ind2rgb(Ifile, map));
            end
            
            % Qualify
            testCase.verifyClass(Ifile, 'uint8');
            testCase.verifyEqual(imdata, Ifile);

        end
               
        function shouldGenerateSVGFile(testCase)
            DF = FigureDeployer('ImageType', 'svg');
            [imdata, imname] = getImage(DF);
            testCase.addTeardown(@()delete(imname));
            testCase.verifyClass(imdata, 'char');
            
            fid = fopen(imname, 'r');
            testCase.addTeardown(@()fclose(fid));
            imfiledata = fread(fid, inf, 'char=>char');
            
            import matlab.unittest.constraints.IsEqualTo
            import matlab.unittest.constraints.StringComparator            
            testCase.verifyThat(imfiledata, IsEqualTo(imdata, 'Using', StringComparator));            
            
        end
        
        function shouldGenerateByteStreamOutput(testCase, RasterImageTypes, StreamOutputTypes)
            DF = FigureDeployer('Figure', testCase.Figure, 'ImageType', RasterImageTypes);
            im = getStream(DF, 'OutputType', StreamOutputTypes);                       
            
            import matlab.unittest.constraints.IsFile
            testCase.verifyClass(im, StreamOutputTypes);
            testCase.verifyThat(DF.ImageName, ~IsFile)

        end
                     
        function shouldDefaultToUint8Bytes(testCase)
            DF = FigureDeployer('Figure', testCase.Figure);
            im = getStream(DF);                       
            testCase.verifyClass(im, 'uint8');
            
        end        
        
        function shouldGenerateSVGStreamOutput(testCase)
            DF = FigureDeployer('Figure', testCase.Figure, 'ImageType', 'svg');
            im = getStream(DF);                       
            
            import matlab.unittest.constraints.IsFile
            testCase.verifyClass(im, 'char');         
            testCase.verifyThat(DF.ImageName, ~IsFile)
            
        end        
                
    end
 
end