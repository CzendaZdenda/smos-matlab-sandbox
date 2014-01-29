function [outputFile] = getFileFromArrayByExtension(files, extension)
    % getFileFromArrayByExtension(files, extension)
    %   files : Array
    %   extension : String
    
    if nargin ~=2
        error('getFileFromArrayByExtension(files, extension): Not enough input arguments.');
    end
    
    outputFile = 0;

    for fileIdx=1:length(files)
        [tFolder, tFile, tExtension] = fileparts(files{fileIdx});
        
        if isequal(lower(tExtension), lower(extension));
            outputFile = files{fileIdx};
            break
        end
    end
    
end