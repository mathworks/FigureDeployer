classdef (Sealed) FigureDeployer < handle
% Deploys figure to image or byte stream
    
    properties
        Figure {mustBeFigureOrPlaceholder} = get(groot, 'CurrentFigure') % Figure handle
        Height(1, 1) {mustBeNumeric, mustBePositive, mustBeInteger} = 450 % Height in pixels of image
        ImageName(1, 1) string = "" % Image file name
        ImageType(1, 1) string {mustBeMember(ImageType, {'png', 'jpg', 'bmp', 'svg', 'gif'})} = "png" % Image Type 
        Width(1, 1) {mustBeNumeric, mustBePositive, mustBeInteger} = 600 % Width in pixels of image
        Resolution(1, 1) {mustBeNumeric, mustBePositive, mustBeInteger} = 150 % Width in pixels of image
    end
    
    properties (Access = protected)
        ProvidedImageName(1, 1) string = missing
    end
    
    methods
        
        function obj = FigureDeployer(opts)
        % fd = FigureDeployer('Name', value, ...);
        %
        % Name/Value Pairs:
        %
        %   -Figure: Figure to deploy.  Figure, default is get(groot, 'CurrentFigure').
        %
        %   -Height: Height in pixels.  Scalar, default is 450.
        %
        %   -ImageName: Name of file to write to.
        %               String scalar name of file to write to.  
        %   
        %   -ImageType: Image type.  String scalar must be one the following:
        %               {['png'], 'bmp', 'jpg', 'gif', 'svg'}
        %   
        %   -Width: Width in pixels.  Scalar, default is 600.
        %   
        %   -Resolution: Pixels/per inch.  Scalar, default is 150.
        %
            arguments                
                opts.?FigureDeployer
                opts.Figure = get(groot, 'CurrentFigure'); % Figure is separate so calculated at runtime v. class load time
            end            
            
            % Unpack arguments to properties
            fn = fieldnames(opts);
            for ii = 1:numel(fn)
                obj.(fn{ii}) = opts.(fn{ii});
            end
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
        
            % Be nice, set things back to original state.
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
        
            % Pass back ImageName
            imname = obj.ImageName;
            
        end
 
        function stream = getStream(obj, opts)
        % Get byte or char stream output
        %
        % Usage:
        %   
        %   stream = getStream(fd, 'Name', value)
        %                 
        % Inputs Name-valeue Pairs:
        %
        %   -OutputType': Bytestream type for raster formats.
        %                 Either 'uint8' or 'base64'.  
        %        
        % Outputs:
        % 
        %   -Stream: Byte stream of image.
        %            Class OutputType for raster image types.
        %            Char for SVG.
        %        
              arguments
                  obj
                  opts.OutputType(1, 1) string {mustBeMember(opts.OutputType, {'uint8', 'base64'})} = "uint8"
              end              
              checkFigure(obj);
              
              if obj.ImageType == "svg"
                  % SVG stream is equivalent to the data.
                  [stream, imname] = getImage(obj);
                  deleter = onCleanup(@()delete(imname));
                  
              else
                  % Everything else, use figToImStream
                  stream = figToImStream('figHandle', obj.Figure, ...
                      'imageFormat', obj.ImageType, 'outputType', 'uint8');
                  
                  if opts.OutputType == "base64"
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
        
    end
    
    methods (Access = protected)

        function checkFigure(obj)
            if isempty(obj.Figure) || ~isvalid(obj.Figure)
                ME = MException('FigureDeployer:InvalidFigure', 'Figure is empty or deleted');
                throwAsCaller(ME);                
            end
            
        end
        
    end    
    
end

function mustBeFigureOrPlaceholder(fig)
% Validate that the figure is a Figure or GraphicsPlaceholder
    validateattributes(fig, {'matlab.ui.Figure', 'matlab.graphics.GraphicsPlaceholder'}, {}, mfilename, 'Figure')
    
end
% Copyright 2020 The MathWorks, Inc.