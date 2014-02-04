function insert_wkt(connect,tableName,fieldNames,data)
%INSERT Export MATLAB cell array data into database table.
%   INSERT(CONNECT,TABLENAME,FIELDNAMES,DATA). 
%
%   !!!! Modify to fit WKT format of input data - see <wkt>!!!
%
%   CONNECT is a database connection handle structure, FIELDNAMES
%   is a string array of database column names, TABLENAME is the 
%   database table, DATA is a MATLAB cell array.    For improved 
%   write performance and support for additional data types, use the
%   function FASTINSERT.
%
%
%   Example:
%
%
%   The following INSERT command inserts the contents of
%   the cell array in to the database table yearlySales
%   for the columns defined in the cell array colNames.
%
% 
%   insert(conn,'yearlySales',colNames,monthlyTotals);
%
%   where 
%
%   The cell array colNames contains the value:
%
%   colNames = {'salesTotal'};
%
%   monthlyTotals is a cell array containing the data to be
%   inserted into the database table yearlySales
%   
%   insert(conn,'yearlySales',colNames,monthlyTotals);
%
%
%   See also FASTINSERT, UPDATE, MSSQLSERVERBULKINSERT, MYSQLBULKINSERT, ORACLEBULKINSERT.	

%   Copyright 1984-2010 The MathWorks, Inc.
%   $Revision: 1.24.4.14 $	$Date: 2010/12/22 16:21:56 $%

% Check for valid connection

if isa(connect.Handle,'double')
   
   error(message('database:database:invalidConnection')) 
   
end

% Create start of the SQL insert statement
% First get number of columns in the cell array 

%Get dimensions of data
switch class(data)
    
  case {'cell','double','logical'}
    [numberOfRows,cols] = size(data);	%data dimensions
    
  case 'struct'
    sflds = fieldnames(data);
    fchk = setxor(sflds,fieldNames);
    if ~isempty(fchk)
      error(message('database:database:writeMismatch'))
    end
    numberOfRows = size(data.(sflds{1}),1);
    cols = length(sflds);

  case 'dataset'
    dSummary = summary(data);
    sflds = {dSummary.Variables.Name};
    fchk = setxor(sflds,fieldNames);
    if ~isempty(fchk)
      error(message('database:database:writeMismatch'))
    end
    numberOfRows = size(data.(sflds{1}),1);
    cols = length(sflds);
    
  otherwise
    error(message('database:database:invalidWriteDataType'))
   
end

% Case 1 all fields are being written to in the target database table.
insertField = '';

% Create the field name string for the INSERT statement .. this defines the
% fields in the database table that will be receive data.

for i=1:cols,
  if ( i == cols),
    insertField = [ insertField fieldNames{i} ]; %#ok
  else
    insertField = [ insertField fieldNames{i} ',' ];  %#ok
  end	
end

% Create the head of the SQL statement
startOfString = [ 'INSERT INTO '  tableName ' (' insertField ') ' 'VALUES ( ' ];

% Get NULL string and number preferences 
prefs = setdbprefs;
nsw = prefs.NullStringWrite;
nnw = str2double(prefs.NullNumberWrite);

% Add the data for all the columns in the cell array.
for i = 1:numberOfRows,  
  
  dataString ='';
  
  for j = 1:cols,
    
    switch class(data)
        
      case {'cell','double','uint8','uint16','uint32','uint64','int8','int16','int32','int64','single'}

        try   %Index as cell array, or matrix, if not cell array
          tmp = data{i,j}; 
        catch
          tmp = data(i,j); 
        end    
        
      case {'struct','dataset'}
          
        try
          tmp = data.(sflds{j}){i};
        catch exception %#ok
          tmp = data.(sflds{j})(i,:);
        end
        
    end  
    
    if isnumeric(tmp) || isa(tmp,'logical') %Test for data type.
      
      % Substitute NULL value for NullNumberWrite value
      if (isempty(tmp) && isempty(nnw)) || (~isempty(nnw) && ~isempty(tmp) && tmp == nnw) || (isnan(tmp) && isnan(nnw)) 
        tmpstr = 'NULL';
      else
        tmpstr = sprintf('%0.17g',tmp);
      end
      
      % Numeric data.
      if (j == cols), % Last column in the cell array.
        
        % The final comma in the field string is not required. 
        dataString = [ dataString tmpstr ];
        
      else	   
        dataString = [ dataString tmpstr ',' ];
        
      end
      
    else
      
      % Character/String data.
           
      % Substitute NULL value for NullStringWrite value
      if (isempty(tmp) && isempty(nsw)) || strcmp(tmp,nsw)
        tmpstr = 'NULL';
      else
        tmpstr = ['''' tmp ''''];
      end
        
      if (j == cols), % Last column in the cell array.

        % The final comma in the field string is not required. 
        
        dataString= [ dataString tmpstr];
        
      else	   
        
        dataString= [ dataString tmpstr ','];
        
      end
      
    end
    
  end % End of cols loop
  
  writeString = [startOfString dataString ' )'];
  writeString = strrep(writeString, '<wkt>''', '');
  writeString = strrep(writeString, '''<wkt>', '');
  
  % Now insert the data into the database.
  cursTemp=exec(connect,writeString);
  
  if isa(cursTemp.Cursor,'com.mathworks.toolbox.database.sqlExec'),
    
    % Close the cursor.
    close(cursTemp);
  else
    % Stop the insertion process there is a problem 
    % with the SQL statement.  
    
    error(message('database:database:cursorError', cursTemp.Message));
    
  end
end  % End of numberOfRows loop
