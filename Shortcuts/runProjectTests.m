function r = runProjectTests

prj = currentProject;
r = runtests(prj.RootFolder, 'ReportCoverageFor', prj.RootFolder);

end
% Copyright 2020 The MathWorks, Inc.