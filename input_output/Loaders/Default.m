classdef Default < Loader
    %DEFAULT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name='Default'
        channelNames='Unknown' 
        channelEdgeRemoval=1;
        hasEdges='false'
        pixelSize=1
        sample
    end
    
    methods
        function new_sample_path(this,samplePath)
        
        end
        
        function dataFrame = load_data_frame(this,frameNr)
        
        end
        function dataFrame = load_thumb_frame(this,frameNr,option)
        end
        function frameOrder = calculate_frame_nr_order(this)    
        end
    end
    
end

