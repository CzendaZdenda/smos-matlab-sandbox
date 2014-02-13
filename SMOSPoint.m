classdef SMOSPoint < handle
    %SMOSPoint Class to keep information about point from SMOS satelite
    %   and data about brightness temperature by date
    %   TODO>Detailed explanation goes here
    
    properties
        id = '';
        lat = '';
        lon = '';
        values = containers.Map('KeyType','double','ValueType','any');
        source = ''; % like 'db' or 'cvs'
    end
    
    methods 
        % constructor
        function Point = SMOSPoint(data)
            if nargin ==1
                if isequal(class(data),'dataset')
                    % TODO somehow create Point.values from that
                else
                    display('Unsupported input data. Empty SMOSPoint were created');
                end
            else
                Point.values = containers.Map('KeyType','double','ValueType','any');
            end
        end
        
        function addRow(SMOSPoint, dateNumber, row)
            % addRow(dateNumber, row)
            %   
            
            if SMOSPoint.values.isKey(dateNumber)
                data = SMOSPoint.values(dateNumber);
                data = [data;row];
                SMOSPoint.values(dateNumber) = data;
            else
                SMOSPoint.values(dateNumber) = row;
            end
        end
        
        function [IncidenceAgles, BrightnesTemperaturesReal] = GetDataByPolarizationAndDateNumber(SMOSPoint, polarization, dateNumber)
            % GetDataByPolarizationAndDateNumber(polarization, dateNumber)
            %   Get data (IncidenceAgle, BrightnesTemperatureReal) for specific polarization and date.
            
            IncidenceAgles = [];
            BrightnesTemperaturesReal = [];
            
            if ~SMOSPoint.values.isKey(dateNumber)
                display('No data available for this day. Try another one.');                
            else
                dataPerDay = SMOSPoint.values(dateNumber);
                
                IncidenceAgles = zeros(70,1);
                BrightnesTemperaturesReal = zeros(70,1);
                
                cnt = 0;
                
                % get just data for needed polarization
                for rowIdx=1:size(dataPerDay,1)
                    if isequal(dataPerDay(rowIdx, const.SMOSPoint_POLARIZATION_COL),polarization)
                        cnt = cnt + 1;
                        IncidenceAgles(cnt) = dataPerDay(rowIdx,const.SMOSPoint_INCIDENCE_ANGLE_COL);
                        BrightnesTemperaturesReal(cnt) = dataPerDay(rowIdx,const.SMOSPoint_BTReal_COL);
                    end
                end
                
                IncidenceAgles = IncidenceAgles(1:cnt);
                BrightnesTemperaturesReal = BrightnesTemperaturesReal(1:cnt);
            end
            
        end
        
        function Figure = PlotVAndHPolarizationsByDateNumber(point, dateNumber, visible)
            % PlotVAndHPolarizationsByDateNumber(dateNumber)
            %   Plot graph by particular day with vertical and horizontal
            %   polarizations in dependence of incedence angle.
            
            if nargin==2 || ~isequal(class(visible),'double')
                visible = 1;
            end
            
            % sort data first <- probably it's not necessary 
            point.SortDataByColumnAndDate(const.SMOSPoint_INCIDENCE_ANGLE_COL, dateNumber);
            
            % polarization = '0' -> check it
            [H_IA,H_BTr] = point.GetDataByPolarizationAndDateNumber(const.H_POLARIZATION, dateNumber);
            
            % polarization = '1' -> check it
            [V_IA,V_BTr] = point.GetDataByPolarizationAndDateNumber(const.V_POLARIZATION, dateNumber);
            
            % if want to see the graph, just uncomment it
            if isequal(visible,0)
                set(gcf,'Visible','off');
            end
            
            %figure
            plot(V_IA,V_BTr,'-rx');
            hold on;
            plot(H_IA,H_BTr,'-bx');
            title( { 'Independence of brightness temperature on incidence angle'; datestr(dateNumber); ['(' num2str(point.id) ')'] } );
            legend('H POLARIZATION', 'V POLARIZATION');
            ylabel({'bightness temperature - real';'[K]'});
            xlabel({'incidence angle'; '[deg]'});
            hold off;
            
            Figure = gcf;
        end
        
        function Status = SortDataByColumnAndDate(point, columnIdx, dateNumber)
           % SortDataByColumnAndDate(columnIndx, dateNumber)
           %    Sort data in point.values(dateNumber) by particular column
           %    (see libs/const.m).
           
           if ~point.values.isKey(dateNumber)
               Status = 0;
               display( sprintf( ['No data for date ' datestr(dateNumber) '.'] ) );
               return
           end
           
           point.values(dateNumber) = sortrows(point.values(dateNumber),columnIdx);
           
        end
        
        function Status = GenerateGraphs(point, outputFolder, visible)
            startTime = cputime;
            
            addpath('libs');
            
            if nargin ~= 4
                visible = const.VISIBLE_OFF;
            end
            
            if nargin==1 || ~isequal(exist(outputFolder, 'dir'),7)
            	outputFolder = [pwd '\data\png\'];
            end
            
            dayNumbers = point.values.keys;
            
            % TODO testing with 'parfor'
            for dayIdx=1:point.values.Count
               dayNumber = dayNumbers{dayIdx};
               
               point.PlotVAndHPolarizationsByDateNumber(dayNumber,visible);
               saveas(gcf,[ outputFolder num2str(point.id) '_' num2str(dayNumber) '.png'], 'png');
               if isequal(visible,const.VISIBLE_OFF)
                close(gcf);
               end
            end
            
            display(sprintf(['Processing time: ' num2str(cputime-startTime) 's.']));
            
            Status = 1;
        end
        
        function BT = GetBTByIAByDateByPolarization(point, incidenceAngle, dateNumber, polarization)
            point.SortDataByColumnAndDate(const.SMOSPoint_INCIDENCE_ANGLE_COL, dateNumber);
            [IA,BTr] = point.GetDataByPolarizationAndDateNumber(polarization, dateNumber);
            
            if isequal(size(IA,1),0)
                BT = '';
                return
            end
            
            [~, i, ~] = unique(IA);
            IA = IA(i);
            BTr = BTr(i);

            BT = interp1(IA, BTr, incidenceAngle);
        end
        
        function Figure = GetTimeSerieGraphByIAFromTO(point, incidenceAngle, dayFrom, dayTo, polarization)
            % GetTimeSerieGraphByIAFromTO(incidenceAngle, dayFrom, dayTo)
            %
            %   example:
            %      point.GetTimeSerieGraphByIAFromTO(40, '2010-01-13', '2010-01-17',0)
            
            dayFromNumber = datenum(dayFrom,'yyyy-mm-dd');
            dayToNumber = datenum(dayTo,'yyyy-mm-dd');

            cnt = 0;
            for day=dayFromNumber:dayToNumber
                cnt = cnt+1;
                % TODO check if we get something
                BT = point.GetBTByIAByDateByPolarization(incidenceAngle, day, polarization);
                if isequal(class(BT), 'double')
                    yBT(cnt) = BT;
                    xDateNumber(cnt) = day;
                end
            end

                        
            figure
            plot(xDateNumber,yBT,'-rx');
            datetick('x','dd-mmm-yy');
            %set(gca,'XTick',xDateNumber,'XTickLabel', datestr(xDateNumber,'yyyy-mm-dd'));
            hold on;
            title( { 'Brightness temperature by incidence angle in time'; ['(' num2str(point.id) ')'] ; [dayFrom '-' dayTo] } );
            ylabel({'bightness temperature - real';'[K]'});
            xlabel('date');
            hold off;
            
            Figure = gcf;
        end
    end

end