classdef SMOSDataProvider < handle
 % SMOSDataProvider
 %  USAGE:
 %      TODO
 
 properties
    Points = containers.Map('KeyType','double','ValueType','any');

    DBLDir = [pwd '\data\smos\'];
    CSVDir = [pwd '\data\csv\'];
    
    SQLFilesDir = [pwd '\data\sql\'];
    conn = '';

    databasename = 'smos';
    username = 'smos';
    password = '';
    driver = 'org.postgresql.Driver';
    databaseurl = 'jdbc:postgresql://localhost:5432/smos';
    
    tableRecordName = 'smos_records';
    tablePointsName = 'points';
    
    dbRecordColumns = {'grid_point_id', 'observ_date', 'polarization', 'bt_real', 'bt_imag', ...
                'pixel_radiometric_accuracy', 'incidence_angle', 'azimuth_angle', 'faraday_rotation_angle', ...
                'geometric_rotation_angle', 'footprint_axis1', 'footprint_axis2', 'origin'};
    dbPointsColumns = {'smos_point', 'smos_id'};
    
    % TODO check if process all files is needed
    %   check num of rows in file and num of records in db
    
    logFileName = '';
 end

 methods
     %destructor
     function delete(dProvider)
         % what else should I close?
         if isequal(class(dProvider.conn),'database') 
            close(dProvider.conn);
         end
     end
         
     %constructor
     function dProvider = SMOSDataProvider()
         addpath('libs');
         setdbprefs('DataReturnFormat','dataset');
         
         dProvider.databasename = 'smos';
         dProvider.username = 'smos';
         dProvider.password = 'smospasswd';
         dProvider.driver = 'org.postgresql.Driver';
         dProvider.databaseurl = 'jdbc:postgresql://localhost:5432/smos';
     end
     
     function Status = setDBConnection(dProvider, dbname, username, password, driver, databaseurl)
         dProvider.databasename = dbname;
         dProvider.username = username;
         dProvider.password = password;
         dProvider.driver = driver;
         dProvider.databaseurl = databaseurl;
         
         dProvider.conn = database(dProvider.databasename, dProvider.username, dProvider.password, dProvider.driver, dProvider.databaseurl);
         
         try
             ping(dProvider.conn);
             Status = const.OK;
         catch err
             dProvider.writeLog(err.message);
             Status = const.NOT_OK;
         end
     end
         
     function writeDBLog(dProvider, msg)
         dProvider.writeLog('db',msg);
     end

     % TODO put this function into some base class
     function writeLog(dProvider, type, msg)
         if ~isequal(exist(dProvider.logFileName, 'file'), 2)
             dProvider.logFileName = ['log\' datestr(now,'yyyymmdd') '_' type '.txt'];
         end
         
         fileId = fopen(dProvider.logFileName, 'a');
         fprintf(fileId, [datestr(now,'HH:MM:SS') '> ' msg '\n']);
         fclose(fileId);
     end
     
	 function Status = CheckDBConnection(dProvider)
         try
             ping(dProvider.conn);
         catch err
             % create connection
             dProvider.conn = database(dProvider.databasename,dProvider.username,dProvider.password,dProvider.driver,dProvider.databaseurl);
             ping(dProvider.conn);
             dProvider.writeDBLog('DB connection established.');

             % log
             dProvider.writeDBLog(err.message);
         end
        
        Status = const.OK;
     end
     function setDBLDir(dProvider, path)
        % setDBLDir(path)
        %   set path, where .dbl files are stored
        
     	dProvider.DBLDir = path;
     end
     
	 function setCSVDir(dProvider, path)
        % setCSVDir(path)
        %   set path, where .csv files are stored
     	
        dProvider.CSVDir = path;
     end
     
     function Status = TryToCreateNewSMOSPoint(dProvider, tId, tLat, tLon)
        % TryToCreateNewSMOSPoint(tId, tLat, tLon)
        %   if smos point with this id does not exist in the db, create it
        
        dProvider.CheckDBConnection();
        sql = ['SELECT count(*) from ' dProvider.tablePointsName ' WHERE smos_id = ' num2str(tId)];
        
        result = fetch(dProvider.conn, sql);
               
        if isequal(result.count,0)
            data = { ['<wkt>ST_GeomFromText(''POINT(' num2str(tLon) ' ' num2str(tLat) ')'',4326)<wkt>'], tId};
            insert_wkt(dProvider.conn, dProvider.tablePointsName, dProvider.dbPointsColumns, data);
            
            dProvider.writeDBLog(['Points no. ' num2str(tId) ' was created.']);
        end
        
        Status = 1;
     end
     % deprecated
     function point = GetPointById(dProvider, ID, LAT, LON)
        % deprecated
        % GetPointById(id, latitude, longitude)
        %   get point, if does not exist, create new
        
        if dProvider.Points.isKey(ID)
            point = dProvider.Points(ID);
        else
            % save it to Points?
            point = SMOSPoint();
            point.id = ID;
            point.lat = LAT;
            point.lon = LON;
            dProvider.Points(ID) = point;
            dProvider.writeDBLog(['Point ' num2str(point.id) ' created.' ]);
        end
     end
     
     % change/improve file names -> SM_OPER....
     function CreateCSVFromDBLFiles(dataProvider)
        % CreateCSVFromDBLFiles()
        %   process .DBL files and convert them to .csv files
        
        % get files from 
        ZIPFiles = dir( [dataProvider.DBLDir 'SM_*.zip'] );
        DBLFiles = dir( [dataProvider.DBLDir 'SM_*.DBL'] );
        
        % TODO> check every status and file
        % TODO> do it with 'AllFiles' together
        for fileIdx=1:length(ZIPFiles)
            [~, tFileName, tExt] = fileparts( [dataProvider.DBLDir ZIPFiles(fileIdx).name] );
            inputFileName = [dataProvider.DBLDir tFileName tExt];
            outputFileName = [dataProvider.CSVDir tFileName '.csv'];
            dbl2csv( inputFileName, outputFileName);
        end
        
        for fileIdx=1:length(DBLFiles)
            [~, tFileName, tExt] = fileparts( [dataProvider.DBLDir DBLFiles(fileIdx).name] );
            inputFileName = [dataProvider.DBLDir tFileName tExt];
            outputFileName = [dataProvider.CSVDir tFileName '.csv'];
            dbl2csv( inputFileName, outputFileName);
        end
        
        AllFiles = dir( [dataProvider.DBLDir 'SM_*']);
        
        for fileIdx=1:length(AllFiles)
            item = AllFiles(fileIdx);
            if item.isdir
                DBLFolder = item.name;
                [tFolder, tFileName, tExt] = fileparts( [dataProvider.DBLDir DBLFolder '\' item.name '.DBL'] );
                inputFileName = [tFolder '\' tFileName tExt];
                outputFileName = [dataProvider.CSVDir tFileName '.csv'];
                dbl2csv(inputFileName, outputFileName);
            end
        end
        
     end
    
     % deprecated
	 function UpdatePoints(dataProvider, BEAMMode)
        % UpdatePoints()
        %   read .csv files from CSV storage (dataProvider.CSVDir) and process them
        startTime = cputime;
        
        %addpath('libs');
         
        CSVFiles = dir( [dataProvider.CSVDir '*.csv']);

        if nargin==1 || ~isequal(class(BEAMMode),'double')
            BEAMMode = 0;
        end
        
        for csvIdx=1:length(CSVFiles)
            csvFileName = CSVFiles(csvIdx).name;
            
            display(['File ' csvFileName ' is processing...']);
            
            csvFileFullName = [dataProvider.CSVDir csvFileName];
            
            if BEAMMode
                csv = dlmread(csvFileFullName,';',2,0);
            else
                csv = dlmread(csvFileFullName,';',1,0);
            end
            
            startSMOSNameIdx = strfind(csvFileName,'SM_');
            startSMOSDateIdx = startSMOSNameIdx+length('SM_REPR_MIR_SCLF1C_'); % or 'SM_OPER_MIR_SCLF1C_' doesn't metter
            endSMOSDateIdx = startSMOSDateIdx + length('20100113T051300')-1;
            
            % convert date string into datenumber
            SMOSDateNumber = datenum(csvFileName(startSMOSDateIdx:endSMOSDateIdx),'yyyymmdd');
            
            for rowIdx=1:size(csv,1)
                if BEAMMode
                    % TODO> kostyl
                    tId = csv(rowIdx,const.BEAM_Grid_Point_ID);
                    tLat = csv(rowIdx,const.BEAM_Latitude);
                    tLon = csv(rowIdx,const.CSV_LON_COL);
                else
                    tId = csv(rowIdx,const.CSV_ID_COL);
                    tLat = csv(rowIdx,const.CSV_LAT_COL);
                    tLon = csv(rowIdx,const.CSV_LON_COL);
                end
                
                if ~isequal(exist('lastSMOSPoint','var'),1)
                    lastSMOSPoint = SMOSPoint();
                end
                
                if ~isequal(lastSMOSPoint.id, tId);
                    lastSMOSPoint = dataProvider.GetPointById(tId, tLat, tLon);
                end
                
                if BEAMMode
                	row(1) = csv(rowIdx,const.BEAM_Latitude);
                    row(2) = csv(rowIdx,const.BEAM_Longitude);
                    row(3) = csv(rowIdx,const.BEAM_BT_Value_Real);
                    row(4) = csv(rowIdx,const.BEAM_BT_Value_Imag);
                    row(5) = mod(csv(rowIdx,const.BEAM_Flags),4);
                    row(6) = csv(rowIdx,const.BEAM_Incidence_Angle);
                    row(7) = csv(rowIdx,const.BEAM_Azimuth_Angle);
                    row(8) = csv(rowIdx,const.BEAM_Faraday_Rotation_Angle);
                    row(9) = csv(rowIdx,const.BEAM_Geometric_Rotation_Angle);
                    row(10) = csv(rowIdx,const.BEAM_Footprint_Axis1);
                    row(11) = csv(rowIdx,const.BEAM_Footprint_Axis2);
                    row(12) = csv(rowIdx,const.BEAM_Pixel_Radiometric_Accuracy);
                else
                    row = csv(rowIdx,const.CSV_LAT_COL:end);
                end
                
                lastSMOSPoint.addRow(SMOSDateNumber,row);
            end
            display(sprintf(['Processing file ' csvFileName ' completed.\n']));
        end
        
        display(sprintf(['Processing time: ' num2str(cputime-startTime) 's.']));
     end
    
     function Status = GenerateGraphs(dProvider)
        addpath('libs');
        cntPoints = dProvider.Points.Count;
        pointNumbers = dProvider.Points.keys; % as a cell
        
        for pointIdx=1:cntPoints
            point = dProvider.Points(pointNumbers{pointIdx});
            
            cntDays = point.values.Count;
            dayNumbers = point.values.keys;
            
            for dayIdx=1:cntDays
               dayNumber = dayNumbers{dayIdx};
               
               point.PlotVAndHPolarizationsByDateNumber(dayNumber,const.VISIBLE_OFF);
               saveas(gcf,[pwd '\data\png\' num2str(point.id) '_' num2str(dayNumber) '.png'], 'png');
               close(gcf);
            end
            
        end
        
        Status = 1;
     end
     
     % in testing
     function Status = UpdateDBGeometryTable(dProvider)
         % UpdateDBGeometryTable()
         %      To update table dProvider.tablePointsName in smos database
         %      using .csv files in dProvider.CSVDir.
         
         % just for testing
         dProvider.tablePointsName = 'points_test';

         if isequal(dProvider.CheckDBConnection(),const.NOT_OK)
             dProvider.writeDBLog('Can not connect to database.');
             Status = const.NOT_OK;
             return
         end
         
         dProvider.writeDBLog('Start udating geometry of points in db.');
         CSVFiles = dir( [dProvider.CSVDir '*.csv']);
         for csvIdx=1:length(CSVFiles)
            % record counter
            recordCnt = 0;
            
            csvFileName = CSVFiles(csvIdx).name;
            
            csvFileFullName = [dProvider.CSVDir csvFileName];
            csv = dlmread(csvFileFullName,';',1,0);
            
            lastSMOSPointID = 0;
            
            for rowIdx=1:size(csv,1)
                recordCnt = recordCnt + 1;
                
                tId = csv(rowIdx,const.CSV_ID_COL);
                tLat = csv(rowIdx,const.CSV_LAT_COL);
                tLon = csv(rowIdx,const.CSV_LON_COL);
                
                if ~isequal(lastSMOSPointID, tId);
                    lastSMOSPointID = tId;
                    dProvider.TryToCreateNewSMOSPoint(tId, tLat, tLon);
                end
            end
         end       
         Status = 1;
         dProvider.writeDBLog('Updating geometry of points in db finished.');
     end
     
     function Status = UpdateDBRecordTable(dProvider)
         % UpdateDB()
         %      To update table with records in database using .csv files
         %      generated by SmosDataExtractor.exe and Postgresql command
         %      COPY <TABLE_NAME> FROM '<PATH>\<FILE>' CSV HEADER DELIMITER ';';
         %      So just put some .csv files into dProvider.CSVFiles folder.
        
         % just for testing
         dProvider.tableRecordName = 'smos_test_csv_import';
         
         % we need to be root
         dProvider.username = 'postgres';
         dProvider.password = 'papa99';
         dProvider.conn = database(dProvider.databasename,dProvider.username,dProvider.password,dProvider.driver,dProvider.databaseurl);

         dProvider.writeDBLog('Start udating records in db.');
        
         CSVFiles = dir( [dProvider.CSVDir '*.csv']);
        
         if isequal(dProvider.CheckDBConnection(),const.NOT_OK)
             dProvider.writeDBLog('Can not connect to database.');
             Status = const.NOT_OK;
             return
         end
        
         for csvIdx=1:length(CSVFiles)
             csvFileName = CSVFiles(csvIdx).name;
             csvFileFullName = [dProvider.CSVDir csvFileName];
             sqlCopy = ['COPY ' dProvider.tableRecordName ' FROM ''' csvFileFullName ''' CSV HEADER DELIMITER '';''' ];
             
             try
                fetch(dProvider.conn, sqlCopy)
             catch err
                if isequal(err.identifier, 'database:fetch:execError')
                    % it's ok, just propably no return value
                else
                    % smth we did not expect 
                    display(err.getReport());
                    return
                end
             end
             
         end
         
         dProvider.writeDBLog('Updating records in db finished.');
         Status = 1;
     end
     % deprecated
     function Status = UpdateDB(dProvider)
        startTime = cputime;
        dProvider.writeDBLog('Start udating db.');
        addpath('libs');
        
        CSVFiles = dir( [dProvider.CSVDir '*.csv']);
        
        if isequal(dProvider.CheckDBConnection(),const.NOT_OK)
           dProvider.writeDBLog('Can not connect to database.');
           Status = const.NOT_OK;
           return
        end
        
        dProvider.writeDBLog('Processing .csv files.');
        
        %%% TODO> check the parallel computing possibilities of MATLAB 
        %matlabpool
        %parfor csvIdx=1:length(CSVFiles)
        for csvIdx=1:length(CSVFiles)
            startTimeOneFile = cputime;
            
            % record counter
            recordCnt = 0;
            
            csvFileName = CSVFiles(csvIdx).name;
            
            msg = ['File ' csvFileName ' is processing...'];
            display(msg);
            dProvider.writeDBLog(msg);
            
            csvFileFullName = [dProvider.CSVDir csvFileName];
            csv = dlmread(csvFileFullName,';',1,0);
            
            % preallocation dimension of data
            data=cell(size(csv,1),size(dProvider.dbRecordColumns,2));
            
            startSMOSNameIdx = strfind(csvFileName,'SM_');
            startSMOSDateIdx = startSMOSNameIdx+length('SM_REPR_MIR_SCLF1C_');
            endSMOSDateIdx = startSMOSDateIdx + length('20100113T051300')-1;
            
            % convert date string into datenumber
            SMOSDate = datenum(csvFileName(startSMOSDateIdx:endSMOSDateIdx),'yyyymmdd');
            SMOSDateSQL = datestr(SMOSDate,'yyyy-mm-dd');
            
            lastSMOSPointID = 0;
            
            for rowIdx=1:size(csv,1)
                recordCnt = recordCnt + 1;
                
                tId = csv(rowIdx,const.CSV_ID_COL);
                tLat = csv(rowIdx,const.CSV_LAT_COL);
                tLon = csv(rowIdx,const.CSV_LON_COL);

                if ~isequal(lastSMOSPointID, tId);
                    lastSMOSPointID = tId;
                    dProvider.TryToCreateNewSMOSPoint(tId, tLat, tLon);
                end

                data(recordCnt,:) = {num2str(csv(rowIdx, const.CSV_ID_COL)) ...
                    SMOSDateSQL ...
                    num2str(csv(rowIdx, const.CSV_POLARIZATION_COL)) ...
                    num2str(csv(rowIdx, const.CSV_BTReal_COL)) ...
                    num2str(csv(rowIdx, const.CSV_BTImaginary_COL)) ...
                    num2str(csv(rowIdx, const.CSV_PIXEL_RADIOMETRIC_ACCURACY_COL)) ...
                    num2str(csv(rowIdx, const.CSV_INCIDENCE_ANGLE_COL)) ...
                    num2str(csv(rowIdx, const.CSV_AZIMUTH_ANGLE_COL)) ...
                    num2str(csv(rowIdx, const.CSV_FARADAY_ROTATION_ANGLE_COL)) ...
                    num2str(csv(rowIdx, const.CSV_GEOMETRIC_ROTATION_ANGLE_COL)) ...
                    num2str(csv(rowIdx, const.CSV_FOOTPRINT_Axis1_COL)) ...
                    num2str(csv(rowIdx, const.CSV_FOOTPRINT_Axis2_COL)) ...
                    csvFileName};
                
                if isequal(mod(recordCnt,10000),0)
                    display(sprintf(['Number of already processed records: ' num2str(recordCnt)]));
                end
            end
            
            % insert points into db
            dProvider.writeDBLog([num2str(recordCnt) ' rows have been read from .csv file.']);
            dProvider.writeDBLog('Inserting these records into db.');

            insert(dProvider.conn, dProvider.tableRecordName, dProvider.dbRecordColumns, data);
            
            %get size of db after this insert
            s = fetch(dProvider.conn, ['SELECT pg_size_pretty(pg_total_relation_size(''' dProvider.tableRecordName '''))']);
            dProvider.writeDBLog(['Db size: ' s.pg_size_pretty{1} '.']);
            
            msg = ['Processing ' csvFileName ' file finished in ' num2str(cputime-startTimeOneFile) 'sec.'];
            dProvider.writeDBLog(msg);
            display(sprintf(msg));
        end
        
        display(sprintf(['Processing time: ' num2str(cputime-startTime) 'sec.']));
        
        
        close(dProvider.conn);
        Status = 1;
     end
     
     % deprecated
     function point = GetSMOSPointDB(dProvider, id)
        % GetSMOSPointDB(pointId)
        %   get data for specific point from db
        
        %   but first check whether the point already exist
        %startTime = cputime;
        
        point = dProvider.GetPointById(id, 0, 0);
        
        if isequal(point.values.Count,0)
            
            if isequal(dProvider.CheckDBConnection(),const.NOT_OK)
               dProvider.writeDBLog('Can not connect to database.');
               return
            end
            %display(sprintf(['Processing time: ' num2str(cputime-startTime) 's.']));
            sql = ['SELECT * FROM ' dProvider.tableRecordName ' WHERE grid_point_id = ' num2str(id)];
            result = fetch(dProvider.conn, sql);
            %display(sprintf(['Processing time: ' num2str(cputime-startTime) 's.']));
            
            % create Point
            point = SMOSPoint();
            point.id = id;

            nRecords = size(result,1);

            for recordIdx=1:nRecords
                tmp = [ 0 0 result.bt_real(recordIdx) result.bt_imag(recordIdx) result.polarization(recordIdx) result.incidence_angle(recordIdx) ...
                    result.azimuth_angle(recordIdx) result.faraday_rotation_angle(recordIdx) result.geometric_rotation_angle(recordIdx) ...
                    result.footprint_axis1(recordIdx) result.footprint_axis2(recordIdx) result.pixel_radiometric_accuracy(recordIdx)];
  
                dateNumber = datenum(result.observ_date{recordIdx},'yyyy-mm-dd');
                
                point.addRow(dateNumber,tmp);
            end

            point.source = 'db';
            dProvider.Points(point.id) = point;
        end
        display(sprintf(['Processing time: ' num2str(cputime-startTime) 's.']));
    end % EndOfGetSMOSPointDB
    
     function PlotTimeSerie(dProvider, pointID, polarization, IA, From, To)
        % PlotTimeSerie(pointID, polarization, IA, From, To)
        %   
        %   example: 
        %       dProvider.PlotTimeSerie(16513, 1, 40, '2010-01-13','2010-01-18')
        
       startTime = cputime;
       display(sprintf(['Processing time: ' num2str(cputime-startTime) 's.']));
       if isequal(dProvider.CheckDBConnection(),const.NOT_OK)
               dProvider.writeDBLog('Can not connect to database.');
               return
       end
       
       display(sprintf(['Processing time: ' num2str(cputime-startTime) 's.']));
        
       sql = ['SELECT getTimeSerieData(' num2str(IA) ', i, ' num2str(polarization) ... 
           ', ' num2str(pointID) ') as bt, i as dateString FROM (SELECT observ_date FROM smos_records WHERE grid_point_id = ' ...
           num2str(pointID) ' AND polarization = ' num2str(polarization) ' AND observ_date BETWEEN ''' From ''' AND ''' ...
           To ''' GROUP BY observ_date ORDER BY observ_date) g(i)'];
       
       timeSerieData = fetch(dProvider.conn, sql);
       
       if isequal(size(timeSerieData,1),0)
          display(sprintf(['No data available for point no. ' num2str(pointID) ' in this period.']));
          return
       end
       
       display(sprintf(['Processing time: ' num2str(cputime-startTime) 's.']));
       
       xDateNum = datenum(timeSerieData.datestring, 'yyyy-mm-dd');
       
       figure
       plot(xDateNum, timeSerieData.bt, '-rx');
       datatick('x', 'dd-mmm-yy')
       hold on;
       title( { 'Brightness temperature by incidence angle in time'; ['(' num2str(pointID) ')'] ; [From '-' To] } );
       ylabel({'bightness temperature - real';'[K]'});
       xlabel('date');
       hold off;
       
       display(sprintf(['Processing time: ' num2str(cputime-startTime) 's.']));

     end
    
     function pointId = GetNearestPointID(dProvider, lat, lon)
        % SMOSPointId = GetNearestPointID(lat, lon)
        %   Get id of point according to given coordinates.
        
        if isequal(dProvider.CheckDBConnection(),const.NOT_OK)
        	dProvider.writeDBLog('Can not connect to database.');
            return
        end
        
        if nargin ==3 && isnumeric(lat) && isnumeric(lon) 
            sql = ['select nearestpoint(' num2str(lat) ',' num2str(lon) ')'];            
            result = fetch(dProvider.conn, sql);
            if size(result,1)~=0
                pointId = result.nearestpoint;
            else
                pointId = 0;
            end
        else
            display(sprintf('Bad inputs when calling SMOSDataProvider.GetNearestPointID(lat, lon).'));
            help SMOSDataProvider.GetNearestPointID
            pointId = 0;
        end
	 end
    
     function point = GetPointDB(dProvider, arg1, arg2)
        %  SMOSPoint = GetPointDB(lat, lon)
        %    To obtain the closest point to given coordinates.
        %  SMOSPoint = GetPointDB(grid_point_id)
        %    To obtain the point with that id.
        
        if isequal(dProvider.CheckDBConnection(),const.NOT_OK)
        	dProvider.writeDBLog('Can not connect to database.');
            return
        end

        if nargin == 2 && isnumeric(arg1)
        	% get by id
        	id = arg1;  
        elseif nargin ==3 && isnumeric(arg1) && isnumeric(arg2)
        	% get by coordinates
        	id = dProvider.GetNearestPointID(arg1, arg2);
            if id ==0
                display(sprintf('Bad inputs when calling SMOSDataProvider.GetPointDB(lat, lon).'));
                help SMOSDataProvider.GetPointDB
                return
            end
        else
            % smth is wrong
            display(sprintf('Bad inputs.\n'));
            help SMOSDataProvider.GetPointDB
            return
        end
       
        point = dProvider.GetPointById(id, 0, 0);
        
        if ~isequal(point.values.Count,0)
            return
        end
        
        % create Point
        point = SMOSPoint();
        point.id = id;

        oldPreferences = setdbprefs;
        
        % get days
        sqlGetDays = [ 'SELECT DISTINCT on (observ_date) observ_date FROM ' dProvider.tableRecordName ' WHERE grid_point_id = ' num2str(id)];
        
        resultDates = fetch(dProvider.conn, sqlGetDays);
        
        nDates = size(resultDates,1);
        
        if nDates == 0
            display(sprintf('No available data for this point.'));
            return
        end
        
        setdbprefs('DataReturnFormat','numeric');
        
        for dateIdx=1:nDates
            date = resultDates.observ_date{dateIdx};
            dateNum = datenum(date, 'yyyy-mm-dd');
            
            % TODO> after final design of table change the querry
            sqlDataByDate = [ 'SELECT 0,0, bt_real, bt_imag, polarization, incidence_angle, '...
                              'azimuth_angle, faraday_rotation_angle, geometric_rotation_angle, '...
                              'footprint_axis1, footprint_axis2, pixel_radiometric_accuracy '...
                              'FROM ' dProvider.tableRecordName ' WHERE grid_point_id = ' num2str(id) ...
                              ' AND observ_date = ''' date ''' ORDER BY incidence_angle' ];
            
            resultData = fetch(dProvider.conn, sqlDataByDate);
            
            point.values(dateNum) = resultData;
        end
        
        setdbprefs(oldPreferences);
        dProvider.Points(point.id) = point;        
     end

     function HAI_HBT_VAI_VBT = GetVVHHPolarization(dProvider, date, lat, lon)
         % HAI_HBT_VAI_VBT = GetVVHHPolarization(DATE, LAT, LON)
         %      Where DATE is string in 'yyyy-mm-dd' formate, LAT and LON
         %      are coordinates of the pixel. 
         %      Where HAI_HBT_VAI_VBT = [H_AI, H_BT, V_AI, V_BT]
        
         if nargin ~= 4 && ~ischar(date) && ~isnumerci(lat) && ~isnumerci(lon)
            display(sprintf('Bad inputs when calling SMOSDataProvider.GetVVHHPolarization(date,lat, lon).'));
            help SMOSDataProvider.GetVVHHPolarization
         end
         
         if isequal(dProvider.CheckDBConnection(),const.NOT_OK)
        	dProvider.writeDBLog('Can not connect to database.');
            return
         end
        
         id = dProvider.GetNearestPointID(lat, lon);
         
         if id == 0
            display(sprintf('Bad coordinates or empty database.'));
            return
         end
         
         [H_IA, H_BT] = dProvider.GetIABT(id, date, const.H_POLARIZATION);
         [V_IA, V_BT] = dProvider.GetIABT(id, date, const.V_POLARIZATION);
         
         minRows = min(size(H_IA,1), size(V_IA,1));
         HAI_HBT_VAI_VBT = [H_IA(1:minRows, :) H_BT(1:minRows, :) V_IA(1:minRows, :) V_BT(1:minRows, :)];
     end
       
     
     function [P_IA, P_BT] = GetIABT(dProvider, pointId, dateNum, polarization)
         % [P_IA, P_BT] = GetIABT(POINT_ID, DATE_NUM, POLARIZATION)
         %      Get matrix of Nx2 dimension, where N is number of rows for
         %      pixel with smos id POINT_ID on date DATE_NUM and
         %      for polarization POLARIZATION. Where DATE_NUM is integer
         %      that represents date in Matlab (see datestring, datenum)
         %      and POLARIZATION is integer from 0 to 4.
         
         if nargin == 4
             
         else
             
         end
         
         if isequal(dProvider.CheckDBConnection(),const.NOT_OK)
        	dProvider.writeDBLog('Can not connect to database.');
            return
         end 
                 
         sql = ['select incidence_angle, bt_real from ' dProvider.tableRecordName ...
            ' smos_records where grid_point_id = ' num2str(pointId) ' and observ_date = ''' ...
            datestr(dateNum, 'yyyy-mm-dd') ''' and polarization = ' num2str(polarization) ...
            ' order by incidence_angle'];
        
        oldPreferences = setdbprefs;
        setdbprefs('DataReturnFormat','numeric');
        
        result = fetch(dProvider.conn, sql);

        P_IA = result(:,1);
        P_BT = result(:,2);
        
        setdbprefs(oldPreferences);
     end
 end
 
end