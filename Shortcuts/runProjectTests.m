function r = runProjectTests

prj = currentProject;
r = runtests(prj.RootFolder, 'ReportCoverageFor', 'FigureDeployer.m');

end

