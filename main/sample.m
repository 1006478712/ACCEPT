classdef sample < handle
    %sample class contains sample specific information
    %It also contains results for the entire sample. Sample wide results
    %are not directly writable but require the use of class methods. 
    
    
    %Raw image dimensions:[x-axis,y-axis,fluophore]
    %the channel order should be discussed, as a starting point the
    %following convention is used:
    %The first channel = exclusion marker
    %second channel = DNA marker
    %third channel = inclusion marker
    %additional channels = extra markers
    
    
    properties (SetAccess=private)
        name='Empty' %the sample name or identifier.
        type='Default'; % this can be replaced with a specific data type such as CellSearch. 
        hasEdges = false; % do we need to removeEdges using this datatype (for example CellSearch )

        % We will have to discuss our naming convention. I think we should keep
        % track of both the flouphore and its target, but it gets confusing \G.
        channelNames={'CD45','DNA','CK','Empty'};
        numChannels = 4;
        pixelSize=1;
        channelEdgeRemoval=4;
        nrOfFrames=0;
        measurements=table();
        classificationResults=table();
        dataTypeOriginalImage='uint16';
    end
    
    events
        saveResults
        logMessage
    end
    

    methods
        function self=sample(name,type,pixelSize,hasEdges,channelNames,channelEdgeRemoval,nrOfFrames)
            if nargin==7
                self.name=name;
                self.type=type;
                self.pixelSize=pixelSize;
                self.hasEdges=hasEdges;
                self.channelNames=channelNames;
                self.numChannels=numel(channelNames);
                self.channelEdgeRemoval=channelEdgeRemoval;
                self.nrOfFrames=nrOfFrames;
            end
            notify(self,'logMessage',logmessage(4,['New sample: ',self.name, ' is constructed.']));
                     
        end
        function add_measurements(self,frameNr,measurements)
            self.measurements=[self.measurements; measurements];
        end
        function add_classification_results(self,frameNr,classificationResults)
            self.classificationResults=[self.classificationResults; classificationResults];
        end
        function save_results(self)
        notify(self,'saveResults');
        end
    end
end
