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
%javaclasspath('postgresql-9.3-1100.jdbc3.jar');
javaclasspath('postgresql-9.2-1002.jdbc4.jar');

%setDBConnection(dbname, username, password, driver, databaseurl)
dProvider.setDBConnection('smos', 'postgres', 'papa99', 'org.postgresql.Driver', 'jdbc:postgresql://localhost:5432/smos');

%% Better to update database
% add geometry data to db
%dProvider.UpdateDBGeometryTable();

% load SMOSPoints from .csv files and save in database
%dProvider.UpdateDBRecordTable();

%% Get point from database
% points will be stored within dProvider.Points as instances of SMOSPoint
% class (see dProvider.Points.keys)
% get point number 16512
%point1 = dProvider.GetPointDB(16512)
% get the nearest pixel to given coordintes
%point2 = dProvider.GetPointDB(-147, 68);

%% Get matrix with incidence angles in first column and brightness
% temperature in second. 
% [P_IA, P_BT] = GetIABT(dProvider, pointId, dateNum, polarization)

% get the index of point which the nearest to given coordinates
%pointId = dProvider.GetNearestPointID(-147, 68);

%[H_IA, H_BT] = dProvider.GetIABT(pointId, datenum('2012-11-28','yyyy-mm-dd'), const.H_POLARIZATION);
%[V_IA, V_BT] = dProvider.GetIABT(pointId, datenum('2012-11-28','yyyy-mm-dd'), const.V_POLARIZATION);

% first find the closest timestamp '2012-11-28 05:40:44'
% than get data just from this timestamp
% if you you are not interested in time, use dProvider.GetIABT
%[H_IA, H_BT] = dProvider.GetIABTTimeStamp(pointId, '2012-11-28 05:40:44', const.H_POLARIZATION);
%[V_IA, V_BT] = dProvider.GetIABTTimeStamp(pointId, '2012-11-28 05:40:44', const.V_POLARIZATION);

%%


dateFrom = datenum('2012-11-28','yyyy-mm-dd');
dateTo = datenum('2012-12-06','yyyy-mm-dd');

pointId = 31357;

for date=dateFrom:dateTo

    % tady si najdu datestamps pro kazde dny
    sql = ['select observ_date from smos_records'...
        ' where grid_point_id = ' num2str(pointId) ...
        ' and date_trunc(''day'', observ_date) = ''' datestr(date, 'yyyy-mm-dd') ''''...
        ' group by observ_date '...
        ' order by observ_date'];

    timestamps = fetch(dProvider.conn, sql);
    
    for timestampIdx = 1:size(timestamps,1)
        timestamp = timestamps.observ_date{timestampIdx};
        [H_IA, H_BT] = dProvider.GetIABTTimeStamp(pointId, timestamp, const.H_POLARIZATION);
        [V_IA, V_BT] = dProvider.GetIABTTimeStamp(pointId, timestamp, const.V_POLARIZATION);

        plot(H_IA,H_BT,'blue',V_IA,V_BT,'red');
        
        title( { 'Independence of brightness temperature on incidence angle'; timestamp; ['(' num2str(pointId) ')'] } );
        legend('H POLARIZATION', 'V POLARIZATION');
        ylabel({'bightness temperature - real';'[K]'});
        xlabel({'incidence angle'; '[deg]'});
        
        timeStr = strrep(strrep(strrep(strrep(timestamp, '-',''),' ','T'),':',''),'.0','');
        
        saveas(gcf,[pwd '\data\png\' num2str(pointId) '_' timeStr '_VVHHPolarization.png'], 'png');
    end

end
return


%% Plot time series

% set intputs
pointId = 31357;
%pointId = dProvider.GetNearestPointID(-147, 68);
IA = 40;
From = '2012-11-28';
To  = '2012-12-16';
Time = '15:00:00';

%{
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% get data using time %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
[DATEsH, BTsH] = dProvider.GetTimeSeriesData(pointId, const.H_POLARIZATION, IA, From, To, Time);
[DATEsV, BTsV] = dProvider.GetTimeSeriesData(pointId, const.V_POLARIZATION, IA, From, To, Time);

%{
display('H polarization:');
for idx=1:size(DATEsH,1)
    display( [datestr(DATEsH(idx), 'yyyy-mm-dd HH:MM:SS') ' -> ' num2str(BTsH(idx)) ]);
end

display('V polarization:');
for idx=1:size(DATEsV,1)
    display( [datestr(DATEsV(idx), 'yyyy-mm-dd HH:MM:SS') ' -> ' num2str(BTsV(idx)) ]);
end
%}

%figure
plot(DATEsH,BTsH, 'oblue');
hold on;
plot(DATEsV,BTsV, 'xred');
hold off;

title( { 'Brightness temperature by incidence angle in time'; ['(' num2str(pointId) ')'] ; [From ' - ' To] ; ['Time: ' Time]  } );
ylabel({'bightness temperature - real';'[K]'});
xlabel('date');

datetick('x', 'dd-mmm-yy', 'keepticks');

cursorMode = datacursormode;
set(cursorMode,'UpdateFcn',@TooltipFunc);

FromString2 = strrep(From,'-','');
ToString2 = strrep(To,'-','');
TimeString2 = strrep(Time,':','');

%saveas(gcf,[pwd '\data\png\' num2str(pointId) '_' IA '_' FromString2 '_' ToString2 '_T' TimeString2 'TimeSerie.png'], 'png');
%}

%{
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% get data don't care about time %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[DATEsH, BTsH] = dProvider.GetTimeSeriesData(pointId, const.H_POLARIZATION, IA, From, To);
[DATEsV, BTsV] = dProvider.GetTimeSeriesData(pointId, const.V_POLARIZATION, IA, From, To);

%figure
plot(DATEsH,BTsH, 'oblue');
hold on;
plot(DATEsV,BTsV, 'xred');
hold off;

%{
display('H polarization:');
for idx=1:size(DATEsH,1)
    display( [datestr(DATEsH(idx), 'yyyy-mm-dd HH:MM:SS') ' -> ' num2str(BTsH(idx)) ]);
end

display('V polarization:');
for idx=1:size(DATEsV,1)
    display( [datestr(DATEsV(idx), 'yyyy-mm-dd HH:MM:SS') ' -> ' num2str(BTsV(idx)) ]);
end
%}

title( { 'Brightness temperature by incidence angle in time'; ['(' num2str(pointId) ')'] ; [From ' - ' To] } );
ylabel({'bightness temperature - real';'[K]'});
xlabel('date');

datetick('x', 'dd-mmm-yy', 'keepticks');

cursorMode = datacursormode;
set(cursorMode,'UpdateFcn',@TooltipFunc);

FromString2 = strrep(From,'-','');
ToString2 = strrep(To,'-','');

saveas(gcf,[pwd '\data\png\' num2str(pointId) '_' IA '_' FromString2 '_' ToString2 '_TimeSerie.png'], 'png');

%}

% or 
%M = dProvider.GetVVHHPolarization(datenum('2010-01-13','yyyy-mm-dd'),-155.593, 71.166);
% where M = [H_AI, H_BT, V_AI, V_BT]

%% Some graphs
%point2.GetTimeSerieGraphByIAFromTO(40, '2010-01-13', '2010-01-18',1);
% or
%dProvider.PlotTimeSerie(pointId, 1, IA, From, To);

% plot graph by particular day with vertical and horizontal polarizations
% in dependence of incedence angle
%point1.PlotVAndHPolarizationsByDateNumber(datenum('2010-01-13','yyyy-mm-dd'));


end