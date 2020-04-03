function r = runProjectTests

prj = currentProject;
r = runtests(prj.RootFolder, 'ReportCoverageFor', prj.RootFolder);

end

