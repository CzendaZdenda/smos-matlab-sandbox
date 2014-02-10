function SMOSMain()
% Testing
% CSVDir = [pwd '\testData\CSV\'];

clear all;

% because of constant defined in libs/const.m
addpath('libs'); 

% get data provider
dProvider = SMOSDataProvider;

%% if we do not have csv files, we can create it from .dbl
% (see SMOSDataProvider class, setCSVDir).
%dProvider.setDBLDir([pwd '\data\smos\']);
%dProvider.setCSVDir([pwd '\data\csv\']);
%dProvider.CreateCSVFromDBLFiles();

%% Set database
%setDBConnection(dbname, username, password, driver, databaseurl)
dProvider.setDBConnection('smos', 'smos', 'smospasswd', 'org.postgresql.Driver', 'jdbc:postgresql://localhost:5432/smos')
dProvider.tablePointsName = 'points_test';
dProvider.tableRecordName = 'smos_test_csv_import';

%% Better to update database
% add geometry data to db
dProvider.UpdateDBGeometryTable();

% load SMOSPoints from .csv files and save in database
dProvider.UpdateDBRecordTable();

%% Get point from database
% points will be stored within dProvider.Points as instances of SMOSPoint
% class (see dProvider.Points.keys)
% get point number 16512
point1 = dProvider.GetPointDB(16512)
% get the nearest pixel to given coordintes
point2 = dProvider.GetPointDB(-147, 68);

%% Get matrix with incidence angles in first column and brightness
% temperature in second. 
% [P_IA, P_BT] = GetIABT(dProvider, pointId, dateNum, polarization)

% get the index of point which the nearest to given coordinates
pointId = dProvider.GetNearestPointID(-147, 68);

[H_IA, H_BT] = dProvider.GetIABT(pointId, datenum('2010-01-13','yyyy-mm-dd'), const.H_POLARIZATION);
[V_IA, V_BT] = dProvider.GetIABT(pointId, datenum('2010-01-13','yyyy-mm-dd'), const.V_POLARIZATION);

% or 
M = dProvider.GetVVHHPolarization(datenum('2010-01-13','yyyy-mm-dd'),-155.593, 71.166);
% where M = [H_AI, H_BT, V_AI, V_BT]

% plot graph by particular day with vertical and horizontal polarizations
% in dependence of incedence angle
%point1.PlotVAndHPolarizationsByDateNumber(datenum('2010-01-13','yyyy-mm-dd'));


end