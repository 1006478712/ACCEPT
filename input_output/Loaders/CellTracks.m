classdef CellTracks < Loader
    %CELLSEARCH Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        loaderType='CellTracks'
        hasEdges=true;
        rescaleTiffs=true;
        pixelSize=0.64;
        tiffHeaders;
        channelNames={'DNA','Marker1','CK','CD45','Marker2','Marker3'};
        channelRemapping=[2,4,3,1,5,6;4,1,3,2,5,6];
        channelEdgeRemoval=2;
        xmlData;
        sample=Sample();
    end
    
    methods
        function this = CellTracks(input) %pass either a sample or a path to the constructor
            if nargin == 1
                validateattributes(input,{'Sample','char'},{'nonempty'},'','input');
                if isa(input,'Sample')
                    if strcmp(input.type,'CellTracks')
                        this.sample=input;
                    end
                    error('tried to use incorrect sampletype with CellTracks Loader');
                else
                    this=this.new_sample_path(samplePath);
                end
            end
            keyboard
        end
        
        function this=new_sample_path(this,samplePath)
            this.sample.imagePath = this.find_dir(samplePath,'tif',100);
            this.sample.priorPath = this.find_dir(samplePath,'xml',1);
            splitPath=regexp(samplePath, filesep, 'split');
            if isempty(splitPath{end})
                this.sample.sampleId=splitPath{end-1};
            else
                this.sample.sampleId=splitPath{end};
            end
            this.preload_tiff_headers(imagePath);
            this.processXML();
            this.sample.pixelSize=this.pixelSize;
            this.sample.hasEdges=this.hasEdges;
            this.sample.channelNames=this.channelNames(this.channelRemapping(2,1:this.sample.nrOfChannels));
            this.sample.channelEdgeRemoval=this.channelEdgeRemoval;
            this.priorLocations=this.prior_locations_in_sample;
        end
   
        function dataFrame=load_data_frame(this,frameNr)
            if isempty(this.sample)
                this.load_sample();
            end
            dataFrame=Dataframe(this.sample,frameNr,...
            this.does_frame_have_edge(frameNr),...
            this.read_im_and_scale(frameNr));
            addlistener(dataFrame,'loadNeigbouringFrames',@this.load_neigbouring_frames);
        end
         
    end
    methods(Access=private)
        function Dir_out = find_dir(this,Dir_in,fileExtension,numberOfFiles)
            % function to verify in which directory the tiff files are located. There
            % are a few combinations present in the immc databases:
            % immc38: dirs with e.g. .1.2 have a dir "processed" in cartridge dir, dirs
            % without "." too "171651.1.2\processed\"
            % immc26: dirs with name of cartridge, nothing else: "172182\mic06122006e7\"
            % imcc26: dirs with e.g. .1.2: "173765.1.1\173765.1.1\processed\"
           

            CurrentDir = Dir_in;

            % count iterations, if more than 10, return with error.
            it = 0;

            % if nothing is found, return error -1
            Dir_out = 'No dir found';

            while it < 10
                it = it + 1;
                if numel(dir([CurrentDir filesep '*.' fileExtension])) >= numberOfFiles
                    Dir_out = CurrentDir;
                    break
                else
                    FilesDirs = dir(CurrentDir);
                    if size(FilesDirs,1)> 2
                        DirCount = 0;
                        for ii = 1:size(FilesDirs,1)
                            if FilesDirs(ii).isdir && ~strcmp(FilesDirs(ii).name, '.') && ~strcmp(FilesDirs(ii).name, '..') && ~strcmp(FilesDirs(ii).name, '.DS_Store')
                                DirCount = DirCount + 1;
                                NewDir = FilesDirs(ii).name;
                            end
                        end
                        if DirCount == 1
                            CurrentDir = [CurrentDir filesep NewDir];
                        elseif DirCount == 0
                            break
                        else
                            % if more than 1 directory is found, end search with error
                            Dir_out = 'More than one dir found';
                            break
                        end
                    end
                end
            end
        end
        
        function preload_tiff_headers(this)
            tempImageFileNames = dir([this.sample.imagePath filesep '*.tif']);
            for i=1:numel(tempImageFileNames)
             imageFileNames{i} = [this.sample.imagePath filesep tempImageFileNames(i).name];  
            end
            %function to fill the dataP.temp.imageinfos variable

            for i=1:numel(imageFileNames)
                this.sample.tiffHeaders{i}=imfinfo(imageFileNames{i});
            end

            %Have to add a check for the 2^15 offset.
            %dataP.temp.imagesHaveOffset=false;
            this.sample.imageSize=[this.tiffHeaders{1}(1).Height this.tiffHeaders{1}(1).Width numel(this.tiffHeaders{1})];
            this.sample.nrOfFrames=numel(this.imageFileNames);
            this.sample.nrOfChannels=numel(this.tiffHeaders{1});
        end
        
        function rawImage=read_im_and_scale(this,imageNr)
            % use the previously gathered imageinfo and read all images in a multipage
            % tiff. read only one channel if a channel is specified. Rescale and
            % stretch values and rescale to approx old values if the image is a
            % celltracks tiff: scales IMMC images back to 0..4095 scale. Otherwise a
            % normal tiff is returned.
            rawImage = zeros(this.imageSize);
            for i=1:this.nrOfChannels;
                try
                    imagetemp = double(imread(this.imageFileNames{imageNr},i, 'info',this.tiffHeaders{imageNr}));
                catch
                    notify(this,'logMessage',logmessage(2,['Tiff from channel ' num2str(ch) ' is not readable!'])) ;
                    return
                end
                if  this.rescaleTiffs 
                    
                    UnknownTags = this.tiffHeaders{imageNr}(i).UnknownTags;

                    LowValue  =  UnknownTags(2).Value;
                    HighValue =  UnknownTags(3).Value;


                    % scale tiff back to "pseudo 12-bit". More advanced scaling necessary? 
                    rawImage(:,:,this.channelRemapping(1,i)) = LowValue + imagetemp * ((HighValue-LowValue)/max(imagetemp(:)));
                else
                    if max(imagetemp) > 32767
                        imagetemp = imagetemp - 32768;
                    end
                    rawImage(:,:,this.channelRemapping(1,i))=imagetemp;
                end

                            
            end
        end

        function hasEdge=does_frame_have_edge(this,frameNr)
            row = ceil(frameNr/this.sample.columns) - 1;
            switch row
                case {0,this.xmlData.rows} 
                    hasEdge=true;
                otherwise
                    col=frameNr-row*this.sample.columns;
                    if col==this.sample.columns
                        hasEdge=true;
                    elseif col==1
                        hasEdge=true;
                    else
                        hasEdge=false;
                    end 
            end
        end
        
        function locations=prior_locations_in_sample(this)
            index=find(this.xmlData.score==1);
            if isempty(index)
                locations=[];
            else
                for i=1:numel(index)
                    locations(i,:)=this.event_to_pixels_and_frame(index(i));
                end
            end
        end           
        
        function load_neighbouring_frames(this,sourceFrame,~)
            % to be implemented
            neigbouring_frames=this.calculate_neighbouring_frames(sourceFrame.frameNr);
        
        end
        
        function neigbouring_frames=calculate_neigbouring_frames(this,frameNr)
            % to be implemented
            neigbouring_frames=[1,2,3];
        end
        
        function processXML(this)
            % Process XML file if available
            % determine in which directory the xml file is located.
            NoXML=0;
            this.xmlData = [];
            
            % find directory where xml file is located in
            if isempty(this.priorPath)
                NoXML=1;
            else
                XMLFile = dir([this.priorPath filesep '*.xml']);
            end
                
            % Load & process XML file
            if NoXML == 0
                this.xmlData=xml2struct([this.priorPath filesep XMLFile.name]);
                this.xmlData.num_events = [];
                this.xmlData.CellSearchIds = [];
                this.xmlData.locations = [];
                this.xmlData.score=[];
                this.xmlData.frameNr=[];
                this.xmlData.camYSize=1384
                this.xmlData.camXSize=1036;
                if isfield(this.xmlData,'archive')
                    this.xmlData.num_events = size(this.xmlData.archive{2}.events.record,2);
                    this.xmlData.CellSearchIds = zeros(this.xmlData.num_events,1);
                    this.xmlData.locations = zeros(this.xmlData.num_events,4);
                    this.xmlData.score=zeros(this.xmlData.num_events,1);
                    this.xmlData.frameNr=zeros(this.xmlData.num_events,1);
                    for i=1:this.xmlData.num_events
                        this.xmlData.CellSearchIds(i)=str2num(this.xmlData.archive{2}.events.record{i}.eventnum.Text); %#ok<*ST2NM>
                        this.xmlData.score(i)=str2num(this.xmlData.archive{2}.events.record{i}.numselected.Text);                    
                        this.xmlData.frameNr(i)=str2num(this.xmlData.archive{2}.events.record{i}.framenum.Text);
                        tempstr=this.xmlData.archive{2}.events.record{i}.location.Text;
                        start=strfind(tempstr,'(');
                        finish=strfind(tempstr,')');
                        to=str2num(tempstr(start(1)+1:finish(1)-1));
                        from=str2num(tempstr(start(2)+1:finish(2)-1));
                        this.xmlData.locations(i,:)=[from,to];
                    end
                    this.xmlData.columns=str2num(this.xmlData.archive{2}.runs.record.numcols.Text);
                    this.xmlData.rows=str2num(this.xmlData.archive{2}.runs.record.numrows.Text);
                    this.xmlData.camYSize=str2num(this.xmlData.archive{2}.runs.record.camysize.Text);
                    this.xmlData.camXSize=str2num(this.xmlData.archive{2}.runs.record.camxsize.Text);
           
                    
                elseif isfield(this.xmlData, 'export')
                    this.xmlData.num_events = size(this.xmlData.export{2}.events.record,2);
                    this.xmlData.CellSearchIds = zeros(this.xmlData.num_events,1);
                    this.xmlData.locations = zeros(this.xmlData.num_events,4);
                    this.xmlData.score=zeros(this.xmlData.num_events,1);
                    this.xmlData.frameNr=zeros(this.xmlData.num_events,1);
                    for i=1:this.xmlData.num_events
                        this.xmlData.CellSearchIds(i)=str2num(this.xmlData.export{2}.events.record{i}.eventnum.Text);
                        this.xmlData.score(i)=str2num(this.xmlData.export{2}.events.record{i}.numselected.Text);                    
                        this.xmlData.frameNr(i)=str2num(this.xmlData.export{2}.events.record{i}.framenum.Text);
                        tempstr=this.xmlData.export{2}.events.record{i}.location.Text;
                        start=strfind(tempstr,'(');
                        finish=strfind(tempstr,')');
                        to=str2num(tempstr(start(1)+1:finish(1)-1));
                        from=str2num(tempstr(start(2)+1:finish(2)-1));
                        this.xmlData.locations(i,:)=[from,to];
                    end
                    this.xmlData.columns=str2num(this.xmlData.export{2}.runs.record.numcols.Text);
                    this.xmlData.rows=str2num(this.xmlData.export{2}.runs.record.numrows.Text);
                    this.xmlData.camYSize=str2num(this.xmlData.export{2}.runs.record.camysize.Text);
                    this.xmlData.camXSize=str2num(this.xmlData.export{2}.runs.record.camxsize.Text);
                else
                    notify(this,'logMessage',logmessage(2,['unable to read xml']));
                    %setting row and colums based on nrOfImages
                    switch this.nrOfFrames
                        case 210 % 6*35 images
                            this.sample.columns=35;
                            this.sample.rows=6;
                        case 180 % 5*36 images
                            this.sample.columns=36;
                            this.sample.rows=5;
                        case 175 % 5*35 images
                            this.sample.columns=35;
                            this.sample.rows=5;
                        case 170 % 5*34 images
                            this.sample.columns=34;
                            this.sample.rows=5;
                        case 144 % 4*36 images
                            this.sample.columns=36;
                            this.sample.rows=4;
                        case 140 % 4*35 images
                            this.sample.columns=35;
                            this.sample.rows=4;
                    end
                    return
                end
            end
        end
        
        function [coordinates]=pixels_to_coordinates(this,pixelCoordinates, imgNr)
            row = ceil(imgNr/this.sample.columns) - 1;
            cols = this.sample.columns;
            switch row
                case {1,3,5} 
                    col=(cols-(imgNr-rowthis.sample.columns));
                    coordinates(1)=pixelCoordinates(1)+this.sample.camXSize*col;
                    coordinates(2)=pixelCoordinates(2)+this.sample.camYSize*row;  
                otherwise
                    col=imgNr-1-row*cols;
                    coordinates(1)=pixelCoordinates(1)+this.sample.camXSize*col;
                    coordinates(2)=pixelCoordinates(2)+this.sample.camYSize*row; 
            end
        end

        function [locations]=event_to_pixels_and_frame(this,eventNr)
            frameNr=this.sample.frameNr(eventNr);
            row = ceil(frameNr/this.sample.columns) - 1;
            cols = this.sample.columns;
            switch row
                case {1,3,5} 
                    col=(cols-(frameNr-row*this.sample.columns));
                otherwise
                    col=frameNr-1-row*this.sample.columns;
            end
            xTopLeft=this.xmlData.locations(eventNr,1)-this.sample.camXSize*col;
            yTopLeft=this.xmlData.locations(eventNr,2)-this.xmlData.camYSize*row;
            xBottomRight=this.xmlData.locations(eventNr,3)-this.xmlData.camXSize*col;
            yBottomRight=this.xmlData.locations(eventNr,4)-this.xmlData.camYSize*row;
            locations=table(frameNr,xTopLeft,yTopLeft,xBottomRight,yBottomRight);
        end
        
    end
        
    methods(Static)
        function bool = can_load_this_folder(path)
            %function that must be present in all loader types to test
            %if the current sample can be loaded by this class. 
            bool=true;
%                         %check if image is CellTracks image
%             try tags=dataP.temp.imageinfos{1}(1).UnknownTags;
%                 for i=1:numel(tags)
%                     if tags(i).ID==754
%                         dataP.temp.imagesAreFromCT=true;
%                     end
%                 end
%             catch dataP.temp.imagesAreFromCT=false;
%             end
        end
 
    end
end

