function [Success_out, Msr, algP] = FindAndMeasureObjects(input_cartridge,dataP, algP)
% Function to find actc and wbc in a cartridge
tic
disp(['starting on ' input_cartridge] )
%% variable initialization

Success_out = 'Cartridge ok';
algP.thresh = zeros(dataP.numFrames,1);
Msr = [];

%% Find images in input path
% determine in which directory the tiff files are located.

[dataP, Success_out] = get_image_filenames(dataP, input_cartridge);

if strcmp(Success_out, 'No Tiff dir found') || strcmp(Success_out, 'More than one dir found')
   return 
end

dataP = get_image_info(dataP);
% determine image size
sizeX = dataP.temp.imageinfos{1}(1).Width;
sizeY = dataP.temp.imageinfos{1}(1).Height;
toc
tic
disp('image info gathered')
%% Detect cartridge edge
if dataP.removeEdges == true
    % Get scan area: exclude border of cartridge
    [MaskEdgesCartridge, BorderCheckSuccess]= get_Scan_Area(dataP, algP);

    if strcmp(BorderCheckSuccess, 'error reading FITC image in function GetScanArea')
        Success_out = BorderCheckSuccess;
        return
    elseif strcmp(BorderCheckSuccess, 'Number of images in directory not normal!')
        Success_out = BorderCheckSuccess;
        return
    elseif strcmp(BorderCheckSuccess, 'Tiff from channel 2 is not readable!')
        Success_out = BorderCheckSuccess;
        return
    elseif strcmp(BorderCheckSuccess, 'Using Template border mask')
        Success_out = 'Used template border area';
    end
else
    MaskEdgesCartridge = ones(sizeX, sizeY, TiffCount);
end
toc
tic
disp('get scan area done')
%% Determine threshold if segmentation method is thresholding
if strcmp(func2str(algP.segMeth),'thresholding')
    [Error_Tiff, algP.thresh(1),algP.thresh(2),algP.thresh(3),algP.thresh(4)] = algP.threshMeth(MaskEdgesCartridge, dataP, algP); % wie laesst sich das besser loesen, ohne das man die 4 einsetzt??
    
    if ~(isempty(Error_Tiff))
        Success_out = Error_Tiff;
        return
    end
end
toc
tic
disp('bighist done start measuring')
%% process each tiff - prepare images for segmentation (read in/scale back/apply mask/...) 
for ii = 1:numel(dataP.temp.imageFileNames)
    [scaled_image ErrorTiff] = readImAndScale(dataP,ii);
    if strcmp(ErrorTiff, 'Tiff is not an IMMC tiff!')
        Error_out = ErrorTiff;
        MaskAreaToScan_out = [];
        return
    elseif strcmp(ErrorTiff, ['Tiff from channel ' num2str(dataP.channelEdgeremoval) ' is not readable!'])
        Error_out =  ErrorTiff;
        MaskAreaToScan_out = [];
        return
    end    
    % resample border image, create dummy image for transferring mask
    if dataP.removeEdges == true
        MaskEdge = squeeze(MaskEdgesCartridge(:,:,ii)); 
        MaskEdge = repmat(imresize(MaskEdge, [sizeY sizeX]),1,1,dataP.numFrames);
    end

    % create image without edges if removeEdges is activated
    image_to_seg=zeros(sizeY,sizeX,dataP.numFrames,'uint16');
    if dataP.removeEdges == true
        image_to_seg(MaskEdge) = scaled_image(MaskEdge);
    else
        image_to_seg = scaled_image;
    end
    
%     icy_im3show(image_to_seg)
    
%% segmentation step       
    seg_image = algP.segMeth(image_to_seg, dataP, algP);
%     icy_im3show(seg_image);

%% feature/measurement extraction

    % extract image number for use in measurement ID
    % CELLSEARCH SPECIFIC!! Find a more general way!!
    ending = strfind(dataP.temp.imageFileNames{ii}, '.tif');
    image_number = dataP.temp.imageFileNames{ii}(ending-3:ending-1);
    
    % measure features for each single cell
    New_msr = measurements(seg_image, image_to_seg, image_number, dataP, algP);

    if ii ==1
        Msr = New_msr;
    elseif max(max(seg_image)) > 0
        Msr = [Msr, New_msr];     
    end
    
%% save results of segmentation if wanted    
    if dataP.saveSeg == true
        param = strcat('segMethod=',func2str(algP.segMethod));
        resPath = fullfile(dataP.output_folder, param, input_cartridge, 'segmentation_results');
        if ~exist(resPath, 'dir')
            mkdir(resPath);
        end

        [dir,file,extension]=fileparts(dataP.temp.imageFileNames{ii});
        imwrite(seg_image(:,:,1), [resPath filesep file extension]);
        for ch = 2:dataP.numFrames
            imwrite(seg_image(:,:,ch), [resPath filesep file extension], 'writemode', 'append');
        end
    end
    
end
toc