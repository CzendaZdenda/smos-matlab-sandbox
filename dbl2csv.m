function [status, csvFile] = dbl2csv(inputFile, outputCSVFileName, smosExtractorFullPath)
%dbl2csv(inputFile, outputCSVFileName, smosExtractorFullPath)
%   Convert SMOS .dbl file to .csv formate file using SmosDataExtractor by Zhenya
%
%   [status, csvFile] = dbl2csv(inputFile, outputCSVFileName, smosExtractorFullPath)
%
%   inputDBLFileName                    - 
%   outputCSVFileName(optional)         -
%       [get from inputDBLFileName]
%   smosExtractorFullPath (optional)    - path to SmosDataExtractor.exe,
%       [default - SmosDataExtractor\SmosDataExtractor.exe]

% check input arguments
% http://www.heckler.com.br/blog/2012/02/13/matlab-function-with-a-number-of-optional-arguments/

addpath(pwd);

isZip = 0;

CSV_EXTENSION = '.csv';
ZIP_EXTENSION = '.zip';
DBL_EXTENSION = '.dbl';

if nargin >= 1 || nargin <=3
    [inputFolder, inputFileName, inputExtension] = fileparts(inputFile);
    inputFolder = [inputFolder '\'];
    outputFolder = inputFolder;
    % TODO> check input folder
    if ~isequal(exist(inputFile,'file'),2)
        error('Bad input arguments. File not found!');
    end
end

if nargin == 1
    outputCSVFileName = [inputFolder inputFileName CSV_EXTENSION];
end

if nargin == 1 || nargin == 2
    if isequal(exist('SmosDataExtractor\SmosDataExtractor.exe','file'),2)
        smosExtractorFullPath = [pwd '\SmosDataExtractor\SmosDataExtractor.exe'];
        smosExtractorDir = [pwd '\SmosDataExtractor\'];
	else
        error('Smos data extractor is not found!');     
    end
end

if nargin == 2
    [outputFolder, ~, ~] = fileparts(outputCSVFileName);
    outputFolder = [outputFolder '\'];
end

if nargin == 3
    if isequal(exist(smosExtractorFullPath, 'var'),1)
        [smosExtractorDir, ~, ~] = fileparts(smosExtractorFullPath);
        % ok
	elseif isequal(exist('SmosDataExtractor\SmosDataExtractor.exe','file'),2)
        smosExtractorFullPath = [pwd '\SmosDataExtractor\SmosDataExtractor.exe'];
        smosExtractorDir = [pwd '\SmosDataExtractor\'];
    else
        error('Smos data extractor is not found!'); 
    end    
end

if (nargin<1 || 3 < nargin)
    error('Check input variables!'); 
end

% save current folder
currentFolder = pwd;

% move to SmosDataExtractor folder
cd(smosExtractorDir);

% if is zip
if isequal(lower(inputExtension),ZIP_EXTENSION)
    display(['Extracting file ' inputFileName ZIP_EXTENSION ' ...']);
    unzipFiles = unzip(inputFile,inputFolder);
    display(['Extracting file ' inputFileName ZIP_EXTENSION ' completed.']);
    isZip = 1;
    inputDBLFile = getFileFromArrayByExtension(unzipFiles, DBL_EXTENSION);
elseif isequal(lower(inputExtension),DBL_EXTENSION)
    inputDBLFile = inputFile;
else
    error('Not supported input file!');
end

command = [ smosExtractorFullPath ' ' inputDBLFile ' ' outputCSVFileName];

[status,~] = system(command);
csvFile = outputCSVFileName;

% TODO> add result to log


% check status
if ~status
    display(['Converting file ' inputFileName DBL_EXTENSION ' completed.']);
end

% clean
if isZip
    for fileIdx=1:length(unzipFiles)
        delete(unzipFiles{fileIdx})
    end
end

cd(currentFolder);

end