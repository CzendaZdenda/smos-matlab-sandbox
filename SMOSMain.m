function SMOSMain()
% Testing
% CSVDir = [pwd '\testData\CSV\'];

clear all;

addpath('libs');

% get data provider
dProvider = SMOSDataProvider;

% if we do not have csv files, we can create it from .dbl
% (see SMOSDataProvider class, setCSVDir).
% dProvider.setDBLDir('path/where/DBL/files/are/stored');
% dProvider.setCSVDir('path/where/CSV/files/will/be/stored');

dProvider.setDBLDir([pwd '\data\smos\']);
dProvider.setCSVDir([pwd '\data\csv\']);
%dProvider.CreateCSVFromDBLFiles();

% load SMOSPoints from .csv files
% and keep them in dProvider.Points (see dProvider.Points.keys)
dProvider.UpdatePoints();

%if we want generate .png graphs for all points
% dProvider.GenerateGraphs();

% get point number 16512
%point = dProvider.Points(16512);

% set day
% datestr(day)
%day = 734151;

% plot graph by particular day with vertical and horizontal
% polarizations in dependence of incedence angle
%point.PlotVAndHPolarizationsByDateNumber(day);

end