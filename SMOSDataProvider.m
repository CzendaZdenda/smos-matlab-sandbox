classdef SMOSDataProvider < handle
 % SMOSDataProvider
 %  USAGE:
 %      TODO
 
 properties
    Points = containers.Map('KeyType','double','ValueType','any');
    %DBLDir = [pwd '\testData\SMOS\'];
    %CSVDir = [pwd '\testData\CSV\'];
    DBLDir = [pwd '\data\smos\'];
    CSVDir = [pwd '\data\csv\'];
    
    SQLFilesDir = [pwd '\data\sql\'];
    conn = '';
    % TODO create method SetDBConection(...)
    databasename = 'smos';
    username = 'smos';
    password = '';
    driver = 'org.postgresql.Driver';
    databaseurl = 'jdbc:postgresql://localhost:5432/smos';
    
    tableName = 'smos_bt_point';
    
    dbColumns = {'grid_point_id', 'observ_date', 'polarization', 'bt_value_real', 'bt_value_imag', ...
                'pixel_radiometric_accuracy', 'incidence_angle', 'azimuth_angle', 'faraday_rotation_angle', ...
                'geometric_rotation_angle', 'footprint_axis1', 'footprint_axis2', 'origin'};
            
    sqlTemplate = [ 'INSERT INTO table_name (grid_point_id, observ_date, polarization, bt_value_real, bt_value_imag, ' ...
        'pixel_radiometric_accuracy, incidence_angle, azimuth_angle, faraday_rotation_angle, ' ...
        'geometric_rotation_angle, footprint_axis1, footprint_axis2, origin) ' ...
        'VALUES( DB_Grid_Point_ID, ''DB_Observ_date'', DB_Polarization, DB_BT_Real_COL, DB_BT_Imag_COL, ' ...
        'DB_Pixel_radiometric_accuracy, DB_Incidence_angle, DB_Azimuth_angle, DB_Faraday_rotation_angle, ' ...
        'DB_Geometric_rotation_angle, DB_Footprint_axis1, DB_Footprint_axis2, ''DB_Origin'');' ];
    
    % TODO check if process all files is needed
    %   check num of rows in file and num of records in db
    
    logFileName = '';
 end

 methods
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
         %status = fclose(fileId);
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
        
    function point = GetPointById(dProvider, ID, LAT, LON)
        % GetPointById(id, latitude, longitude)
        %   get point, if does not exist, create new
        
        if dProvider.Points.isKey(ID)
            point = dProvider.Points(ID);
        else
            % save it to Points?
            point = SMOSPoint;
            point.id = ID;
            point.lat = LAT;
            point.lon = LON;
            dProvider.Points(ID) = point;
            %display(['Point ' num2str(point.id) ' created.' ]);
        end
    end
        
	function CreateCSVFromDBLFiles(dataProvider)
        % CreateCSVFromDBLFiles()
        %   process .DBL files and convert them to .csv files
        
        % get files from 
        ZIPFiles = dir( [dataProvider.DBLDir 'SM_REPR*.zip'] );
        DBLFiles = dir( [dataProvider.DBLDir 'SM_REPR*.DBL'] );
        
        % TODO> check every status and file
        % TODO> do it with 'AllFiles' together
        for fileIdx=1:length(ZIPFiles)
            [tFolder, tFileName, tExt] = fileparts( [dataProvider.DBLDir ZIPFiles(fileIdx).name] );
            inputFileName = [dataProvider.DBLDir tFileName tExt];
            outputFileName = [dataProvider.CSVDir tFileName '.csv'];
            dbl2csv( inputFileName, outputFileName);
        end
        
        for fileIdx=1:length(DBLFiles)
            [tFolder, tFileName, tExt] = fileparts( [dataProvider.DBLDir DBLFiles(fileIdx).name] );
            inputFileName = [dataProvider.DBLDir tFileName tExt];
            outputFileName = [dataProvider.CSVDir tFileName '.csv'];
            dbl2csv( inputFileName, outputFileName);
        end
        
        AllFiles = dir( [dataProvider.DBLDir 'SM_REPR*']);
        
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
     
	function UpdatePoints(dataProvider, BEAMMode)
        % UpdatePoints()
        %   read .csv files from CSV storage (dataProvider.CSVDir) and process them
        startTime = cputime;
        
        addpath('libs');
         
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
            
            startSMOSNameIdx = strfind(csvFileName,'SM_REPR_MIR');
            startSMOSDateIdx = startSMOSNameIdx+length('SM_REPR_MIR_SCLF1C_');
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
    
    function Status = UpdateDB(dProvider)
        startTime = cputime;
        dProvider.writeDBLog('Start udating db.');
        addpath('libs');
        
        CSVFiles = dir( [dProvider.CSVDir '*.csv']);
        
        try
        	ping(dProvider.conn);
        catch err
            % create connection
            dProvider.conn = database(dProvider.databasename,dProvider.username,dProvider.password,dProvider.driver,dProvider.databaseurl);
            ping(dProvider.conn);

            % log
            dProvider.writeDBLog(err.message);
        end
        
        dProvider.writeDBLog('Processing .csv files.');
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
            data=cell(size(csv,1),size(dProvider.dbColumns,2));
            
            startSMOSNameIdx = strfind(csvFileName,'SM_REPR_MIR');
            startSMOSDateIdx = startSMOSNameIdx+length('SM_REPR_MIR_SCLF1C_');
            endSMOSDateIdx = startSMOSDateIdx + length('20100113T051300')-1;
            
            % convert date string into datenumber
            SMOSDate = datenum(csvFileName(startSMOSDateIdx:endSMOSDateIdx),'yyyymmdd');
            SMOSDateSQL = datestr(SMOSDate,'yyyy-mm-dd');

            %   create .sql file where inserts will be kept
            if ~isequal(exist(dProvider.SQLFilesDir,'dir'),7)
                % maybe check status [SUCCESS,MESSAGE,MESSAGEID] = mkdir(NEWDIR)
                mkdir(dProvider.SQLFilesDir);
            end
            
            %{
            SQLFileName = strrep(csvFileName,'.csv','');
            fileId = fopen([dProvider.SQLFilesDir SQLFileName], 'w');
            %}
            
            
            for rowIdx=1:size(csv,1)
                recordCnt = recordCnt + 1;
                if isequal(mod(recordCnt,10000),0)
                    display(sprintf(['Number of already processed records: ' num2str(recordCnt)]));
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
                %{
                sql = strrep(dProvider.sqlTemplate,'table_name',dProvider.tableName);
                sql = strrep(sql, 'DB_Grid_Point_ID', num2str(csv(rowIdx, const.CSV_ID_COL)));
                sql = strrep(sql, 'DB_Observ_date', SMOSDateSQL);
                sql = strrep(sql, 'DB_Polarization', num2str(csv(rowIdx, const.CSV_POLARIZATION_COL)));
                sql = strrep(sql, 'DB_BT_Real_COL', num2str(csv(rowIdx, const.CSV_BTReal_COL)));
                sql = strrep(sql, 'DB_BT_Imag_COL', num2str(csv(rowIdx, const.CSV_BTImaginary_COL)));
                sql = strrep(sql, 'DB_Pixel_radiometric_accuracy', num2str(csv(rowIdx, const.CSV_PIXEL_RADIOMETRIC_ACCURACY_COL)));
                sql = strrep(sql, 'DB_Incidence_angle', num2str(csv(rowIdx, const.CSV_INCIDENCE_ANGLE_COL)));
                sql = strrep(sql, 'DB_Azimuth_angle', num2str(csv(rowIdx, const.CSV_AZIMUTH_ANGLE_COL)));
                sql = strrep(sql, 'DB_Faraday_rotation_angle', num2str(csv(rowIdx, const.CSV_FARADAY_ROTATION_ANGLE_COL)));
                sql = strrep(sql, 'DB_Geometric_rotation_angle', num2str(csv(rowIdx, const.CSV_GEOMETRIC_ROTATION_ANGLE_COL)));
                % sql = strrep(sql, 'DB_Snapshot_id_of_pixel', num2str(csv(rowIdx, const.CSV_)));
                sql = strrep(sql, 'DB_Footprint_axis1', num2str(csv(rowIdx, const.CSV_FOOTPRINT_Axis1_COL)));
                sql = strrep(sql, 'DB_Footprint_axis2', num2str(csv(rowIdx, const.CSV_FOOTPRINT_Axis2_COL)));
                sql = strrep(sql, 'DB_Origin', csvFileName);
                
                % ulozim do souboru
                fprintf(fileId, sql);
                %}
                
                
            end
            
            % insert points into db
            dProvider.writeDBLog(['Inserting ' csvFileName ' file into db.']);
            insert(dProvider.conn,dProvider.tableName, dProvider.dbColumns, data);

            msg = ['Processing ' csvFileName ' file finished in ' num2str(cputime-startTimeOneFile) 'sec.'];
            dProvider.writeDBLog(msg);
            display(msg);
        end
        
        display(sprintf(['Processing time: ' num2str(cputime-startTime) 'sec.']));
        
        
        close(dProvider.conn);
        Status = 1;
    end
    
    function Status = GetSMOSPointDB()
        % get point from db
            
        Status = 1;
    end
 end
 
end