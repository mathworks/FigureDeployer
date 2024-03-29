classdef (Sealed) FigureDeployer < handle & matlab.mixin.SetGetExactNames
% Deploys figure to image or byte stream
    
    properties
        Figure {mustBeFigureOrPlaceholder} = get(groot, 'CurrentFigure') % Figure handle
        Height(1, 1) {mustBeNumeric, mustBePositive, mustBeInteger} = 450 % Height in pixels of raster image
        ImageType(1, 1) string {mustBeMember(ImageType, {'png', 'jpg', 'svg', 'gif'})} = "png" % Image Type 
        Width(1, 1) {mustBeNumeric, mustBePositive, mustBeInteger} = 600 % Width in pixels of raster image
        Resolution(1, 1) {mustBeNumeric, mustBePositive, mustBeInteger} = 150 % Width in pixels of raster image
        OutputType(1, 1) string {mustBeMember(OutputType, {'uint8', 'base64'})} = "uint8" % Stream output type for getStream
    end

    properties (Dependent)
        ImageName(1, 1) string % Image name
    end
    
    properties (Access = protected)
        ProvidedImageName(1, 1) string = missing
    end
    
    methods
        
        function obj = FigureDeployer(opts)
        % fd = FigureDeployer('Name', value, ...);
        %
        % Name-Value Pairs:
        %
        %   -Figure: Figure to deploy.  Figure, default is get(groot, 'CurrentFigure').
        %
        %   -Height: Height in pixels.  Scalar, default is 450.
        %
        %   -ImageName: Name of file to write to.
        %               String scalar name of file to write to.  
        %   
        %   -ImageType: Image type.  String scalar must be one the following:
        %               {['png'], 'jpg', 'gif', 'svg'}
        %   
        %   -Width: Width in pixels.  Scalar, default is 600.
        %   
        %   -Resolution: Pixels/per inch.  Scalar, default is 150.
        %
        %   -OutputType: Output type of non-SVG image stream.  Either
        %                {['uint8'], "base64"}        
        %                SVG is always a character vector.
        %

            arguments                
                opts.?FigureDeployer
                opts.Figure = get(groot, 'CurrentFigure'); % Figure is separate so calculated at runtime v. class load time
            end            
            
            % Unpack arguments to properties
            set(obj, opts)
            if isfield(opts, 'ImageName')
                % Image name is provided, store it.
                obj.ProvidedImageName = opts.ImageName;            
            end
            
        end
        
        function [imdata, imname] = getImage(obj)
        % Get image data and image name from figure deployer
        % 
        % Usage:
        %
        %   [imdata, imname] = getImage(obj);
        % 
        % Outputs:
        %
        %   -imdata: Image data of the type specified by the ImageType
        %
        %   -imname: Image file name.
        %        
        
            checkFigure(obj);
        
            if obj.Figure.NumberTitle == "on"
                imdata = getFigureImage(obj);
            
            else
                imdata = getUIFigureImage(obj);

            end
            imname = obj.ImageName;
            
        end
 
        function stream = getStream(obj)
        % Get byte or char stream output
        %
        % Usage:
        %   
        %   stream = getStream(fd, 'Name', value)
        %        
        % Outputs:
        % 
        %   stream: Byte stream of image.
        %           Class OutputType for raster image types.
        %           Char for SVG.
        %        
             
              checkFigure(obj);
              
              % Streams always use tempnames
              oldname = obj.ImageName;
              namerestorer = onCleanup(@()set(obj, 'ImageName', oldname));
              obj.ImageName = tempname+"."+obj.ImageType;

              if obj.ImageType == "svg"
                  % SVG stream is equivalent to the data.
                  [stream, imname] = getImage(obj);
                  deleter = onCleanup(@()delete(imname));
                  
              else
                  % Everything else, generate the image, then read it
                  [~, imname] = getImage(obj);
                  deleter = onCleanup(@()delete(imname));
                  fid = fopen(imname, 'r');
                  stream = fread(fid, inf, 'uint8=>uint8');                  
                  fclose(fid);

                  if obj.OutputType == "base64"
                      stream = matlab.net.base64encode(stream);
                  end
                  
              end
              
        end
                   
        function imname = get.ImageName(obj)
        % Returns image name handling the file extension.        
            if ismissing(obj.ProvidedImageName)
                % Nothing provided, give a tempname
                obj.ProvidedImageName = string(tempname);
            end
            
            % Handle path and extension.
            [impath, name, ext] = fileparts(obj.ProvidedImageName);
            pname = fullfile(impath, name);
            
            % Add extension if there isn't one
            if ~strlength(ext)
                ext = "." + obj.ImageType;
            end
            
            % Build image name
            imname = pname + ext;
        
        end
        
        function set.ImageName(obj, newimagename)            
            obj.ProvidedImageName = newimagename;

        end

    end
    
    methods (Access = protected)

        function checkFigure(obj)
            if isempty(obj.Figure) || ~isvalid(obj.Figure)
                ME = MException('FigureDeployer:InvalidFigure', 'Figure is empty or deleted');
                throwAsCaller(ME);                
            end
            
        end

        function imdata = getFigureImage(obj)
            origPosition = obj.Figure.Position;
            origUnits = obj.Figure.Units;            
            origPP = obj.Figure.PaperPosition;
            resetFigure = @()set(obj.Figure, 'Units', origUnits, 'Position', origPosition, 'PaperPosition', origPP);
            resetter = onCleanup(resetFigure);
            
            % Driver info and resolution
            driver = '-d' + string(obj.ImageType);
            driver = replace(driver, 'jpg', 'jpeg'); % JPG driver includes e            
            
            % Set to accurate size
            obj.Figure.Units = 'pixels';
            obj.Figure.Position(3:4) = [obj.Width obj.Height];

            % Print image
            if driver == "-dgif"
                % Use getframe and imwrite
                f = getframe(obj.Figure);
                [ind, map] = rgb2ind(f.cdata, 256);
                ind = imresize(ind, [obj.Height, obj.Width]);
                imwrite(ind, map, obj.ImageName);
            
            else
                % Use print
                obj.Figure.PaperPosition = [0 0 obj.Width./obj.Resolution obj.Height./obj.Resolution];
                print(obj.Figure, obj.ImageName, char(driver), char("-r" + obj.Resolution))

            end
            
            if driver == "-dsvg"
                % SVG, the output is text.                
                fid = fopen(obj.ImageName, 'r');
                closer = onCleanup(@()fclose(fid));
                imdata = fread(fid, inf, 'char=>char');

            else
                % Raster, use imread
                [imdata, map] = imread(obj.ImageName);

            end
            
            % Handle GIF storage to return rgb data of the correct size
            if driver == "-dgif"
                imdata = im2uint8(ind2rgb(imdata, map));

            end
        
        end

        function imdata = getUIFigureImage(obj)
            assert(~matches(obj.ImageType, "svg"), 'FigureDeployer:NoUIFigureSVG', ...
                'UIFigures are not supported for SVG deployment')

            origPosition = obj.Figure.Position;
            origUnits = obj.Figure.Units;            
            resetFigure = @()set(obj.Figure, 'Units', origUnits, 'Position', origPosition);
            resetter = onCleanup(resetFigure);
            
            % Get close with setting, then correct it after
            obj.Figure.Units = 'pixels';
            obj.Figure.Position = [0 0 obj.Width obj.Height];
            exportgraphics(obj.Figure, obj.ImageName, Resolution=obj.Resolution)
            [imdata, map] = imread(obj.ImageName);
            imdata = imresize(imdata, [obj.Height obj.Width]);
            if isempty(map)
                imwrite(imdata, obj.ImageName)
                if obj.ImageType == "jpg"
                    % Need to reread JPG because it is not lossless.
                    imdata = imread(obj.ImageName);

                end

            else
                % gif is special and needs map written separately
                imwrite(imdata, map, obj.ImageName)
                imdata = im2uint8(ind2rgb(imdata, map));

            end

        end

    end    
    
end

function mustBeFigureOrPlaceholder(fig)
% Validate that the figure is a Figure or GraphicsPlaceholder
    validateattributes(fig, {'matlab.ui.Figure', 'matlab.graphics.GraphicsPlaceholder'}, {}, mfilename, 'Figure')
    
end
% Copyright 2020 The MathWorks, Inc.