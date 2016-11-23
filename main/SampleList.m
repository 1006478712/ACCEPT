classdef SampleList < handle
    %SAMPLELIST keeps track if availablee samples are processed or not. 
    
    properties
        sampleProcessorId='empty';
        inputPath = '';
        resultPath = '';
        toBeProcessed = [];
        overwriteResults = false;
        loaderTypesAvailable={CellTracks(),MCBP(),ThumbnailLoader(),Default()}; % beware of the order, the first loader type that can load a dir will be used.
    end 
    
    properties(SetAccess={?IO})
        sampleNames = {};
        isProcessed = [];   
    end
    
    properties(Access={?IO})
        loaderToBeUsed = {}
    end
        
    events
        logMessage
        updated
    end
    
    methods
        function this=SampleList(procId,inputP,resultP)
            if nargin==3
                this.sampleProcessorId = procId;
                this.inputPath = inputP;
                this.resultPath = resultP;
                this.updated_sample_processor()
            end
        end
        
        function outputStr=save_path(this)
            outputStr = [this.resultPath,filesep,this.sampleProcessorId,filesep];
        end
            
        function set.sampleProcessorId(this,value)
            this.sampleProcessorId = value;
            this.updated_sample_processor();
            notify(this,'updated');
        end
        
        function set.inputPath(this,value)
            this.inputPath = value;
            this.updated_input_path();
            notify(this,'updated')
        end
        
        function set.resultPath(this,value)
            this.resultPath = value;
            IO.check_save_path(this.save_path());
            this.updated_result_path();
            notify(this,'updated')
        end
        
        function set.overwriteResults(this,value)
            this.overwriteResults = value;
            this.updated_result_path();
            notify(this,'updated')
        end
        
        function populate_available_input_types(this)
            % populate available inputs 
            % Function not used atm /g
            temp = what('Loaders');
            flist = temp.m;

            for i=1:numel(flist)
               [~,filename,filetext]=fileparts(flist{i}); % get just the filename
               if exist(filename, 'class') && ismember('loader', superclasses(filename))
                 this.loaderTypesAvailable{end+1} = filename();
               end
             end
        end
        
        function updated_sample_processor(this)
            if all([~isempty(this.resultPath),...
                    ~isempty(this.inputPath),...
                    ~strcmp(this.sampleProcessorId,'empty'),...
                    isempty(this.sampleNames)]);
                this.updated_input_path();
            end
            if and(~isempty(this.inputPath),~isempty(this.resultPath))
                this.processed_samples()
            end
        end
                
        function updated_result_path(this)
            if all([~isempty(this.inputPath),...
                    ~isempty(this.resultPath),...
                    ~strcmp(this.sampleProcessorId,'empty'),...
                    isempty(this.sampleNames)]);
                this.updated_input_path();
            end
            if and(~isempty(this.resultPath),...
                    ~strcmp(this.sampleProcessorId,'empty'));
                    this.processed_samples()
             end
        end
        
        function updated_input_path(this)
            [this.sampleNames,this.loaderToBeUsed]=IO.available_samples(this);
            if and(~isempty(this.resultPath),...
                ~strcmp(this.sampleProcessorId,'empty'));
                this.processed_samples()   
            end
        end
        
        function processed_samples(this)
            this.isProcessed=false(1,numel(this.sampleNames));
            this.toBeProcessed=true(1,numel(this.sampleNames));
            %Check in results dir if any samples are already processed.
            try load([this.save_path() filesep 'processed.mat'],'samplesProcessed')
            catch 
                %appears to be no list (?) so lets create an empty sampleProccesed variable
                samplesProcessed={};
            end
            [~,index]=intersect(this.sampleNames,samplesProcessed);
            if this.overwriteResults==false
                this.toBeProcessed(index)=false;
                this.isProcessed(index)=true;
            end
        end
        
        function update_sample_list(this)
                this.processed_samples();
        end
    end
end

