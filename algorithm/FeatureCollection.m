classdef FeatureCollection < SampleProcessorObject
    %FEATURECOLLECTION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
       dataProcessor = DataframeProcessor();
       use_thumbs = 0;
       priorLocations = [];
    end
    
    methods
        function this = FeatureCollection(inputDataframeProcessor,varargin)
            this.dataProcessor = inputDataframeProcessor;
            if nargin > 1
                this.use_thumbs = varargin{1};
            end
            
            if nargin > 2
                this.priorLocations = varargin{2};
            end
        end
        
        function returnSample = run(this, inputSample)
            returnSample = inputSample;
            
            if this.use_thumbs == 0
                for i = 1:inputSample.nrOfFrames
                    i
                    dataFrame = IO.load_data_frame(inputSample,i);
                    this.dataProcessor.run(dataFrame);
                    objectsfoundearlier = size(inputSample.results.features,1);
                    objectsfound = size(dataFrame.features,1);
                    IO.save_data_frame_segmentation(inputSample,dataFrame);
                    if objectsfound > 0
                        thumbNr = array2table(linspace(objectsfoundearlier+1,objectsfoundearlier+size(dataFrame.features,1),...
                            size(dataFrame.features,1))','VariableNames',{'ThumbNr'});
                        
                        dataFrame.features = [thumbNr dataFrame.features]; %maybe change like below?!
                        inputSample.results.features=vertcat(inputSample.results.features, dataFrame.features);
                        bb = struct2cell(regionprops(dataFrame.labelImage,'BoundingBox'));
                        yBottomLeft = cellfun(@(x) min(max(floor(x(2)) - round(0.2*x(5)),1),size(dataFrame.rawImage,1)),bb);
                        xBottomLeft = cellfun(@(x) min(max(floor(x(1)) - round(0.2*x(4)),1),size(dataFrame.rawImage,2)),bb);
                        yTopRight = cellfun(@(x) min(floor(x(2)) + round(1.2*x(5)),size(dataFrame.rawImage,1)),bb);
                        yTopRight = max(yTopRight,yBottomLeft+2);
                        xTopRight = cellfun(@(x) min(floor(x(1)) + round(1.2*x(4)),size(dataFrame.rawImage,2)),bb);
                        xTopRight = max(xTopRight,xBottomLeft+2);
                        ind1 = find(xTopRight>size(dataFrame.rawImage,2));
                        ind2 = find(yTopRight>size(dataFrame.rawImage,1));
                        if ~isempty(ind1)|| ~isempty(ind2)
                            ind = [ind1, ind2];
                            xBottomLeft(ind) = [];
                            yBottomLeft(ind) = [];
                            xTopRight(ind) = [];
                            yTopRight(ind) = [];
                        end                      
                        returnSample.results.thumbnails = vertcat(returnSample.results.thumbnails, table(dataFrame.frameNr * ones(size(xBottomLeft,2),1),xBottomLeft',...
                            yBottomLeft',xTopRight',yTopRight','VariableNames',{'frameNr' 'xBottomLeft' 'yBottomLeft' 'xTopRight' 'yTopRight'}));
                        thumbnail_images = cell(1,size(dataFrame.features,1));
                        segmentation = cell(1,size(dataFrame.features,1));
                        for n = 1:size(xBottomLeft,2)
                            thumbnail_images{n} = dataFrame.rawImage(yBottomLeft(n):yTopRight(n),...
                                xBottomLeft(n):xTopRight(n),:);
                            segmentation{n} = dataFrame.segmentedImage(yBottomLeft(n):yTopRight(n),...
                                xBottomLeft(n):xTopRight(n),:);
                        end
                        returnSample.results.thumbnail_images = horzcat(returnSample.results.thumbnail_images, thumbnail_images);
                        returnSample.results.segmentation = horzcat(returnSample.results.segmentation, segmentation);
                    end
                end
            
            elseif this.use_thumbs == 1 && isempty(this.priorLocations)

                if strcmp(inputSample.type,'ThumbnailLoader')
                    nPriorLoc = inputSample.nrOfFrames
                else 
                    nPriorLoc = size(inputSample.priorLocations,1)
                end
                thumbFramesProcessed = cell(nPriorLoc,1);
                featureTables = cell(nPriorLoc,1);
        
                % parallelized
                
%                 parfor i = 1:nPriorLoc
%                     if strcmp(inputSample.type,'ThumbnailLoader')
%                         thumbFrame = this.io.load_data_frame(inputSample,i);
%                     else
%                         thumbFrame = this.io.load_thumbnail_frame(inputSample,i,'prior'); 
%                     end
%                     this.dataProcessor.run(thumbFrame);
%                     % for the parallel version we need an explicit update
%                     % of the i-th dataFrame called thumbFrames{i}
%                     thumbFramesProcessed{i} = thumbFrame;
%                     objectsfound = size(thumbFrame.features,1);
%                     if objectsfound > 0
%                         thumbNr = array2table(i*ones(objectsfound,1),'VariableNames',{'ThumbNr'});
%                         featureTables{i} = [thumbNr thumbFrame.features];
%                     end
%                 end
                if strcmp(inputSample.type,'ThumbnailLoader')
                    for i = 1:nPriorLoc
                        thumbFrame = IO.load_data_frame(inputSample,i);                
                        this.dataProcessor.run(thumbFrame);
                        % for the parallel version we need an explicit update
                        % of the i-th dataFrame called thumbFrames{i}
                        thumbFramesProcessed{i} = thumbFrame;
                        objectsfound = size(thumbFrame.features,1);
                        if objectsfound > 0
                            thumbNr = array2table(i*ones(objectsfound,1),'VariableNames',{'ThumbNr'});
                            featureTables{i} = [thumbNr thumbFrame.features];
                        end
                    end         
                else
                   parfor i = 1:nPriorLoc
                        thumbFrame = IO.load_thumbnail_frame(inputSample,i,'prior');                 
                        this.dataProcessor.run(thumbFrame);
                        % for the parallel version we need an explicit update
                        % of the i-th dataFrame called thumbFrames{i}
                        thumbFramesProcessed{i} = thumbFrame;
                        objectsfound = size(thumbFrame.features,1);
                        if objectsfound > 0
                            thumbNr = array2table(i*ones(objectsfound,1),'VariableNames',{'ThumbNr'});
                            featureTables{i} = [thumbNr thumbFrame.features];
                        end
                    end 
                        
                end
              
                for k = 1:nPriorLoc
                    % add extracted features to current sample result
                    if ~strcmp(inputSample.type,'ThumbnailLoader')
                        returnSample.results.thumbnails = vertcat(returnSample.results.thumbnails, returnSample.priorLocations(k,:));
                    end
                    returnSample.results.features = vertcat(returnSample.results.features,featureTables{k});
                    returnSample.results.segmentation = horzcat(returnSample.results.segmentation, thumbFramesProcessed{k}.segmentedImage);
                    returnSample.results.thumbnail_images = horzcat(returnSample.results.thumbnail_images, thumbFramesProcessed{k}.rawImage);
                end
                
            %------------------
            elseif this.use_thumbs == 1 && ~isempty(this.priorLocations)
                %still needs to be adapted to parfor
                size(this.priorLocations,1)
                for i = 1:size(this.priorLocations,1)
                    i
                    thumbFrame = IO.load_thumbnail_frame(inputSample,i,this.priorLocations); 
                    this.dataProcessor.run(thumbFrame);
%                     thumbsfoundearlier = size(returnSample.results.thumbnails,1);
                    objectsfound = size(thumbFrame.features,1);
                    if objectsfound > 0
%                         thumbNr = array2table((thumbsfoundearlier+1)*ones(objectsfound,1),'VariableNames',{'ThumbNr'});
                        thumbNr = array2table(i*(ones(size(objectsfound,1),1)),'VariableNames',{'ThumbNr'});
                        thumbFrame.features = [thumbNr thumbFrame.features];
                        returnSample.results.features=vertcat(returnSample.results.features, thumbFrame.features);
                    end
                    returnSample.results.thumbnails=vertcat(returnSample.results.thumbnails, this.priorLocations(i,:));
                    returnSample.results.segmentation = horzcat(returnSample.results.segmentation, thumbFrame.segmentedImage);
                    %delete later!?
                    returnSample.results.thumbnail_images = horzcat(returnSample.results.thumbnail_images, thumbFrame.rawImage);
                end
            end
        end
        
    end
    
end

