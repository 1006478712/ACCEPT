classdef MCBP < Loader & IcyPluginData
    %MCBP Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name='MCBP'
        hasEdges='false'
        pixelSize=0.64
        channelNames
        channelEdgeRemoval=1;
        sample=Sample();
        tiffHeaders
    end
    
    events

    end
    
    methods
        function this = MCBP(input) %pass either sample or a path to the constructor
            if nargin == 1
                validateattributes(input,{'Sample','char'},{'nonempty'},'','input');
                if isa(input,'Sample')
                    if strcmp(input.type,this.name)
                        this.sample=input;
                    else
                    error('tried to use incorrect sampletype with CellTracks Loader');
                    end
                else
                    this=this.new_sample_path(input);
                end
            end
        end
        
        function new_sample_path(this,samplePath)
            this.sample=Sample();
            this.sample.type = this.name;
            this.sample.loader = @MCBP;
            splitPath = regexp(samplePath, filesep, 'split');
            if isempty(splitPath{end})
                this.sample.id=splitPath{end-1};
            else
                this.sample.id=splitPath{end};
            end
            this.sample.pixelSize = this.pixelSize;
            this.sample.hasEdges = this.hasEdges;
            %this.sample.channelNames = this.channelNames(this.channelRemapping(2,1:this.sample.nrOfChannels));
            this.sample.channelEdgeRemoval = this.channelEdgeRemoval;

            this.preload_tiff_headers(samplePath);
            this.sample.priorLocations = this.prior_locations_in_sample(samplePath);
            %this.processXML();
        end
        
        function dataFrame = load_data_frame(this,frameNr)
        end
        function dataFrame = load_thumb_frame(this,frameNr,option)
        end
        function frameOrder = calculate_frame_nr_order(this)
        end
        function load_scan_info(this,samplePath)
            %find text files to extract metadata
            [txtDir,dirFound]=Loader.find_dir(samplePath,'txt',4);
            if dirFound
                %When files are found check their names
                tempTxtFileNames = dir([txtDir filesep '*.txt']);
                for i=1:numel(tempTxtFileNames)
                    nameArray{i}=tempTxtFileNames(i).name;
                end
                                
                bool=strcmp(nameArray(:),'Parameters.txt')
                %Try and open Parameters.txt
                if bool
                    fid=fopen(strcat(txtDir,filesep,'Parameters.txt'))
                    tline = fgetl(fid);
                    i=1;
                    while ischar(tline)
                        parameters{i}=tline;
                        tline = fgetl(fid);
                        i=i+1;
                    end
                    fclose(fid);
                    filtersUsed=dlmread(strcat(txtDir,filesep,'Used Filters.txt'),'\t');
                    
               end
               keyboard
            else
                %error
            end
            
        end
    end
   
    methods(Access=private)

        
        function preload_tiff_headers(this,samplePath)
            [this.sample.imagePath,bool] = this.find_dir(samplePath,'tif',100);
            if bool
                tempImageFileNames = dir([this.sample.imagePath filesep '*.tif']);
                for i=1:numel(tempImageFileNames)
                 this.sample.imageFileNames{i} = [this.sample.imagePath filesep tempImageFileNames(i).name];  
                end
                %function to fill the dataP.temp.imageinfos variable

                for i=1:numel(this.sample.imageFileNames)
                    this.sample.tiffHeaders{i}=imfinfo(this.sample.imageFileNames{i});
                end

                %Have to add a check for the 2^15 offset.
                %dataP.temp.imagesHaveOffset=false;
                this.sample.imageSize=[this.sample.tiffHeaders{1}(1).Height this.sample.tiffHeaders{1}(1).Width numel(this.sample.tiffHeaders{1})];
                this.sample.nrOfFrames=numel(tempImageFileNames);
                this.sample.nrOfChannels=numel(this.sample.tiffHeaders{1});
            else
                %throw error
            end
        end
        
        function rawImage=read_im_and_scale(this,imageNr,boundingBox)
            % use the previously gathered imageinfo and read all images in a multipage
            % tiff. read only one channel if a channel is specified. Rescale and
            % stretch values and rescale to approx old values if the image is a
            % celltracks tiff: scales IMMC images back to 0..4095 scale. Otherwise a
            % normal tiff is returned.
            if nargin==2
                rawImage = zeros(this.sample.imageSize);
                boundingBox={[1 this.sample.imageSize(1)],[1 this.sample.imageSize(2)]};
            else
                %limit boundingBox to frame
                x = boundingBox{2};
                y = boundingBox{1};
                x = min(x,this.sample.imageSize(2));
                x = max(x,1);
                y = min(y,this.sample.imageSize(1));
                y = max(y,1);
                boundingBox = {y,x};
                sizex = boundingBox{2}(2)-boundingBox{2}(1)+1;
                sizey = boundingBox{1}(2)-boundingBox{1}(1)+1;
                rawImage = zeros(sizey,sizex,this.sample.imageSize(3));
            end
            for i=1:this.sample.nrOfChannels;
                try
                    imagetemp = double(imread(this.sample.imageFileNames{imageNr},i, 'info',this.sample.tiffHeaders{imageNr}));
                catch
                    notify(this,'logMessage',LogMessage(2,['Tiff', this.sample.imageFileNames{imageNr}, 'from channel ' num2str(i) ' is not readable!'])) ;
                    return
                end
                if  this.rescaleTiffs 
                    
                    UnknownTags = this.sample.tiffHeaders{imageNr}(i).UnknownTags;

                    LowValue  =  UnknownTags(2).Value;
                    HighValue =  UnknownTags(3).Value;


                    % scale tiff back to "pseudo 12-bit". More advanced scaling necessary? 
                    imagetemp = LowValue + imagetemp * ((HighValue-LowValue)/max(imagetemp(:)));
                    rawImage(:,:,this.channelRemapping(1,i))=imagetemp(boundingBox{1}(1):boundingBox{1}(2),boundingBox{2}(1):boundingBox{2}(2));
                else
                    if max(imagetemp) > 32767
                        imagetemp = imagetemp - 32768;
                    end
                    rawImage(:,:,this.channelRemapping(1,i))=imagetemp(boundingBox{1}(1):boundingBox{1}(2),boundingBox{2}(1):boundingBox{2}(2));
                end
            end
        end
    end
    methods(Static)
        function bool = can_load_this_folder(path)
            %function that must be present in all loader types to test
            %if the current sample can be loaded by this class. 
            
            [txtDir,dirFound]=Loader.find_dir(path,'txt',4);
            if dirFound
                tempTxtFileNames = dir([txtDir filesep '*.txt']);
                for i=1:numel(tempTxtFileNames)
                    nameArray{i}=tempTxtFileNames(i).name;
                end
                test=strcmp(nameArray(:),'Parameters.txt');
                bool=any(test);
            else
                bool = false;
            end    
        end
    end
end

