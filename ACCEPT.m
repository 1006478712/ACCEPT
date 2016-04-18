function uiHandle=ACCEPT(varargin)
    %% Automated CTC Classification Enumeration and PhenoTyping algorithm
    % main function to run the image analysis algorithm for the detection of
    % circulating tumor cells. If given input arguments it will run in batch
    % mode. The function accepts the following input arguments:
    % .....
    % Developed for the European CANCER-ID project by Leonie Zeune, Guus
    % van Dalum, Christoph Brune and Leon Terstappen. 


    %% Clear command window, close all figures and clear global struct used to
    % pass information between functions. 
    clc;
    close all
%     clear actc
    %% Add subdirectories to path
    file = which('ACCEPT.m');
    installDir = fileparts(file);
    addpath(genpath_exclude(installDir));
    
    %% Check the number of arguments in and launch the appropriate script.
    base = Base();
    parser = gen_input_parser(base);
    parse(parser,varargin{:});
    if parser.Results.noGui==false
        uiHandle = gui_main2(base);
    end
end

%% Helper functions
function p = genpath_exclude(d)
    % extension of the genpath function of matlab, inspired by the
    % genpath_exclude.m written by jhopkin posted on matlab central.  We use
    % a regexp to also exclude .git directories from our path.
    
    files = dir(d);
	if isempty(files)
	  return
	end

	% Add d to the path even if it is empty.
	p = [d pathsep];

	% set logical vector for subdirectory entries in d
	isdir = logical(cat(1,files.isdir));
	%
	% Recursively descend through directories which are neither
	% private nor "class" directories.
	%
	dirs = files(isdir); % select only directory entries from the current listing

	for i=1:length(dirs)
		dirname = dirs(i).name;
		%NOTE: regexp ignores '.', '..', '@.*', and 'private' directories by default. 
		if ~any(regexp(dirname,'^\.$|^\.\.$|^\@*|^\+*|^\.git|^private$|','start'))
		  p = [p genpath_exclude(fullfile(d,dirname))]; % recursive calling of this function.
		end
	end
end

function parser = gen_input_parser(base)
    parser=inputParser;
    parser.FunctionName='batchmode input parser';
    parser.addOptional('noGui',false,@(x)islogical(x));
    %Additional options can be added here
    %parser.addOptional('sampleProcessor',@(a) any(validatestring(a,base.availableSampleProcessors)));
    %Optional: io atributes, defaults set to io defaults.
    %parser.addOptional('inputFolder','',@(x) isdir(x));
    %parser.addOptional('outputFolder','',@(x) isdir(x));
    %parser.addOptional('overwriteResults',this.io.overwriteResults,@(x)islogical(x))
end