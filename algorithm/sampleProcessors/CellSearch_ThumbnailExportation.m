classdef CellSearch_ThumbnailExportation < SampleProcessor
    %CTC_Marker_Characterization SampleProcessor for the Feature Collection use case.
    % Acts on preselected thumbnails, does segmentation (otsu thresholding)
    % an extracts features for every cell. No classification!
        
    properties
    end
    
    methods 
        function this = CellSearch_ThumbnailExportation()
            this.name = 'CellSearch Thumbnail Exportation';
            this.version = '0.1'; 
            this.dataframeProcessor =[];
            this.pipeline = cell(0);
            this.showInList = false;
        end
        
        function run(this,inputSample)
            IO.save_thumbnail(inputSample,[],'prior',false);
        end
        
        
    end
end