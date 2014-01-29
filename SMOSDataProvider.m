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
    
    % TODO check if process all files is needed
    lastModification = 0;
 end

 methods
	
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
            display(['Point ' num2str(point.id) ' created.' ]);
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
     
	function UpdatePoints(dataProvider)
        % UpdatePoints()
        %   read .csv files from CSV storage (dataProvider.CSVDir) and process them
        
        addpath('libs');
         
        CSVFiles = dir( [dataProvider.CSVDir '*.csv']);

        for csvIdx=1:length(CSVFiles)
            csvFileName = CSVFiles(csvIdx).name;
            
            display(['File ' csvFileName ' is processing...']);
            
            csvFileFullName = [dataProvider.CSVDir csvFileName];
            csv = dlmread(csvFileFullName,';',1,0);
            
            startSMOSNameIdx = strfind(csvFileName,'SM_REPR_MIR');
            startSMOSDateIdx = startSMOSNameIdx+length('SM_REPR_MIR_SCLF1C_');
            endSMOSDateIdx = startSMOSDateIdx + length('20100113T051300')-1;
            
            % convert date string into datenumber
            SMOSDateNumber = datenum(csvFileName(startSMOSDateIdx:endSMOSDateIdx),'yyyymmdd');
            
            for rowIdx=1:size(csv,1)
                tId = csv(rowIdx,const.CSV_ID_COL);
                tLat = csv(rowIdx,const.CSV_LAT_COL);
                tLon = csv(rowIdx,const.CSV_LON_COL);
                
                if ~isequal(exist('lastSMOSPoint','var'),1)
                    lastSMOSPoint = SMOSPoint();
                end
                
                if ~isequal(lastSMOSPoint.id, tId);
                    lastSMOSPoint = dataProvider.GetPointById(tId, tLat, tLon);
                end
                
                row = csv(rowIdx,const.CSV_ID_COL+1:end);
                lastSMOSPoint.addRow(SMOSDateNumber,row);
            end
            display(sprintf(['Processing file ' csvFileName ' completed.\n']));
        end
        
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
 end
 
end