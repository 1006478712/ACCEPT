function GuiSampleHandle = gui_sample(base,currentSample)

% Main figure: create and set properies (relative size, color)
screensize = get(0,'Screensize');
GuiSampleHandle.fig_main = figure('Units','characters','Position',[64 8 220 65],'Name','ACCEPT - Automated CTC Classification Enumeration and PhenoTyping','MenuBar','none',...
    'NumberTitle','off','Color',[1 1 1],'Resize','off');

%% Set maximum intensity
if strcmp(currentSample.dataTypeOriginalImage,'uint8')
    maxi = 255;
elseif strcmp(currentSample.dataTypeOriginalImage,'uint12')
    maxi = 4095;
else
%     maxi = 65535;
%     Set maxi to 4095 until uint12 is implemented
    maxi = 4095;
end

%handle empty thumbs
usedThumbs = find(ismember(linspace(1,size(currentSample.results.thumbnail_images,2),size(currentSample.results.thumbnail_images,2)),currentSample.results.features{:,1}));
nrUsedThumbs = size(usedThumbs,2);

%replace NaN values with zeros
sampleFeatures = currentSample.results.features;
sampleFeatures_noNaN = sampleFeatures{:,:};
sampleFeatures_noNaN(isnan(sampleFeatures_noNaN)) = 0;
sampleFeatures{:,:} = sampleFeatures_noNaN;
%handle selections
GuiSampleHandle.selectedFrames = false(nrUsedThumbs,1);
GuiSampleHandle.selectedCells = false(size(sampleFeatures,1),1);
rgbTriple = repmat([0 0 1],[size(sampleFeatures,1),1]);
%% Main title
GuiSampleHandle.title_axes = axes('Units','characters','Position',[110 61.8 39.6 2.6]); axis off;
GuiSampleHandle.title = text('Position',[0 0],'String','\color[rgb]{0.729,0.161,0.208} Sample Visualizer','FontUnits','normalized','FontSize',0.8,'verticalAlignment','base','horizontalAlignment','center');


%% Main panels
% create panel for overview (top-left)
GuiSampleHandle.uiPanelOverview = uipanel('Parent',GuiSampleHandle.fig_main,...
                                     'Units','characters','Position',[5.1 45.6 151.6 15.5],...
                                     'Title','Overview','TitlePosition','CenterTop',...
                                     'FontUnits','normalized','FontSize',0.1,...
                                     'BackgroundColor',[1 1 1]);

% create panel for thumbnail gallery (bottom-left)
GuiSampleHandle.uiPanelGallery = uipanel('Parent',GuiSampleHandle.fig_main,...
                                    'Units','characters','Position',[5.1 1.3 151.6 42.8],...
                                     'Title','Cell Gallery','TitlePosition','CenterTop',...
                                     'FontUnits','normalized','FontSize',0.033,...
                                     'BackgroundColor',[1 1 1]);

% create panel for scatter plots (right)
GuiSampleHandle.uiPanelScatter = uipanel('Parent',GuiSampleHandle.fig_main,...
                                    'Units','characters','Position',[160.8 1.3 53.9 59.7],...
                                     'Title','Marker Characterization','TitlePosition','CenterTop',...
                                     'FontUnits','normalized','FontSize',0.023,...
                                     'BackgroundColor',[1 1 1]);

                                 
%% Fill uiPanelOverview
% create table with sample properties as overview
propnames = properties(currentSample);
selectedProps = [1,2,5,6,10]; % properties of data sample to be visualized
propnames = propnames(selectedProps); % row titles
dat = cell(numel(propnames),1);
entry = cell(numel(propnames),1);
rnames = {'Sample ID','Type','Nr of Frames', 'Nr of Channels', 'Pixel Size','Nr of Scored Events'};
for i = 1:numel(propnames)
   dat{i} = eval(['currentSample.',propnames{i}]);
   entry{i} = [rnames{i}, ': ',num2str(dat{i})];
end

% dat{6} = size(currentSample.results.thumbnails,1);
dat{6} = size(currentSample.results.features,1);
entry{6} = [rnames{6}, ': ',num2str(dat{6})];

GuiSampleHandle.uiPanelTable = uipanel('Parent',GuiSampleHandle.uiPanelOverview,...
                                     'Units','characters','Position',[1.5 1.4 37.9 12],...
                                     'Title','Sample Information','TitlePosition','CenterTop',...
                                     'BackgroundColor',[1 1 1]);
                                      
GuiSampleHandle.tableDetails = uicontrol('Style','text','Parent',GuiSampleHandle.uiPanelTable,...
                                  'Units','characters','Position',[0.2 .5 37.5 9],...
                                  'String',entry,'FontUnits','normalized', 'FontSize',0.11,'BackgroundColor',[1 1 1],'HorizontalAlignment','left','FontName','FixedWidth');

tabPosition = get(GuiSampleHandle.uiPanelTable,'Position');


if ~isempty(currentSample.overviewImage) 
    % % create overview image per channel
     GuiSampleHandle.axesOverview = axes('Parent',GuiSampleHandle.uiPanelOverview,...
                                    'Units','characters','Position',[tabPosition(1)+tabPosition(3)+1.5 1 151.6-(tabPosition(1)+tabPosition(3)+3) 12.7]);
    %                            
     defCh = 2; % default channel for overview when starting the sample visualizer

     blank=zeros(size(currentSample.overviewImage(:,:,defCh)));
     GuiSampleHandle.imageOverview = imshow(blank,'parent',GuiSampleHandle.axesOverview,'InitialMagnification','fit');
     colormap(GuiSampleHandle.axesOverview,parula(4096));
     high=prctile(reshape(currentSample.overviewImage(:,:,defCh),[1,size(currentSample.overviewImage,1)*size(currentSample.overviewImage,2)]),99);
     plotImInAxis(currentSample.overviewImage(:,:,defCh).*(4095/high),[],GuiSampleHandle.axesOverview,GuiSampleHandle.imageOverview);


    % % create choose button to switch color channel
     GuiSampleHandle.popupChannel = uicontrol('Style','popup','String',currentSample.channelNames,...
                                         'Units','characters','Position',[88 40 17.6 8.7],...
                                         'FontUnits','normalized','FontSize',0.12,...
                                         'Value',defCh,...
                                         'Callback',{@popupChannel_callback});
end

                                
%% Fill uiPanelGallery
gui_sample_color = [1 1 1];


% create column names for gallery
columnTextSize = 0.68;
                       
% create panel for thumbnails next to slider                          
GuiSampleHandle.uiPanelThumbsOuter = uipanel('Parent',GuiSampleHandle.uiPanelGallery,...
                                        'Units','characters','Position',[0 0 147 39.3],...
                                        'BackgroundColor',gui_sample_color);
                                   
% create slider for gallery
GuiSampleHandle.slider = uicontrol('Style','Slider','Parent',GuiSampleHandle.uiPanelGallery,...
                              'Units','characters','Position',[147.3 0 3 39.3],...
                              'Callback',{@slider_callback});
                                    
% compute relative dimension of the thumbnail grid
nbrAvailableRows = 5;
nbrColorChannels = currentSample.nrOfChannels; 
nbrImages        = nbrAvailableRows * (nbrColorChannels+1);
maxNumCols       = 7; % design decision, % maxNumCols = 1 (overlay) + nbrChannels                            
cols  = min(maxNumCols,nbrColorChannels+1);
rows  = nbrAvailableRows;
space = (144.1 - cols *15.1)/(2*cols);
for i = 1:cols
    if i == 1
        GuiSampleHandle.textCol(i) = uicontrol('Style','text','Parent',GuiSampleHandle.uiPanelGallery,...
                                    'Units','characters','Position',[space 39.2 15.1 1.7],...
                                    'String','Overlay','HorizontalAlignment','center',...
                                    'FontUnits', 'normalized','FontSize',columnTextSize,...
                                    'BackgroundColor',gui_sample_color);
    else
        GuiSampleHandle.textCol(i) = uicontrol('Style','text','Parent',GuiSampleHandle.uiPanelGallery,...
                                    'Units','characters','Position',[(2*(i-1)+1)*space+(i-1)*15.1 39.2 15.1 1.7],...
                                    'String',currentSample.channelNames{i-1},'HorizontalAlignment','center',...
                                    'FontUnits', 'normalized','FontSize',columnTextSize,...
                                    'BackgroundColor',gui_sample_color);
    end
end

% pitch (box for axis) height and width
rPitch  = 38.52/rows;
cPitch  = 144.1/cols;
% axis height and width
axHeight = 35.4/rows;
axWidth = 132.3/cols;

%-----
hAxes   = zeros(nbrImages,1);
hImages = zeros(nbrImages,1);
% define common properties and values for all axes
axesProp = {'dataaspectratio' ,...
            'Parent',...
            'PlotBoxAspectRatio', ...
            'xgrid' ,...
            'ygrid'};
axesVal = {[1,1,1] , ...
           GuiSampleHandle.uiPanelThumbsOuter,...
           [1 1 1]...
           'on',...
           'on'};
% define color pam and include color for contour
map = colormap(parula(maxi+1));
% add color for contour
map(end+1,:) = [1,0,0];

for i=1:rows
    % specify row location for all columns
    y = 39.3-i*rPitch;
    % plot overlay image in first column
    x = 0;
    ind = (i-1)*(cols) + 1; % 5,10,15... index for first column element
    hAxes(ind) = axes(axesProp,axesVal,'Units','characters','Position',[x y axWidth axHeight]);
    hImages(ind)= imshow([],'parent',hAxes(ind),'InitialMagnification','fit');
    set(hImages(ind),'ButtonDownFcn',{@openSpecificImage,i});
    % plot image for each color channel in column 2 till nbrChannels
    for ch = 1:cols-1
        x = (ch)*cPitch;
        ind = ((i-1)*cols + ch +1); % 1-4,6-9,... index for four color channels
        hAxes(ind) = axes(axesProp,axesVal,'Units','characters','Position',[x y axWidth axHeight]);
        hImages(ind)= imshow([],'parent',hAxes(ind),'InitialMagnification','fit');
        set(hImages(ind),'ButtonDownFcn',{@openSpecificImage,i});
        colormap(hAxes(ind),map);
    end
end
% check if slider is needed     
if  nrUsedThumbs>5
    set(GuiSampleHandle.slider,'Max',-3,'Min',-nrUsedThumbs+2,...
        'Value',-3,'SliderStep', [1, 1] / (nrUsedThumbs - 5));
else
    set(GuiSampleHandle.slider,'enable','off');
end

% go through all thumbnails (resp. dataframes)
plot_thumbnails(3);


%% Fill uiPanelScatter

marker_size = 30;
% create data for scatter plot at the top
GuiSampleHandle.axesTop = axes('Parent',GuiSampleHandle.uiPanelScatter,'Units','characters','Position',[9.2 42 40.4 13.4]); %[left bottom width height]
topFeatureIndex1 = 9; topFeatureIndex2 = 17;
gca; GuiSampleHandle.axesScatterTop = scatter(sampleFeatures.(topFeatureIndex1+1),...    % +1 because first column in feature table is index (thumbNumber)
                                      sampleFeatures.(topFeatureIndex2+1),marker_size,'filled','CData',rgbTriple);
xlim([0,max(ceil(1.1*max(sampleFeatures.(topFeatureIndex1+1))),1)]); ylim([0,max(ceil(1.1*max(sampleFeatures.(topFeatureIndex2+1))),1)]);
% GuiSampleHandle.pointsTop=get(GuiSampleHandle.axesScatterTop,'Children');
% for i=1:numel(GuiSampleHandle.pointsTop)
% set(GuiSampleHandle.pointsTop(i),'HitTest','on','ButtonDownFcn',@(handle,event,pointNr)click_point(handle,event,i));
% end
% % add callback to single scatter points
% %points=get(GuiSampleHandle.axesScatterTop,'Children');
% %set(points,'HitTest','on','ButtonDownFcn',{@clickScatterPoint});
                                  
% initialize cell counter (scatter elements) in title
set(GuiSampleHandle.uiPanelScatter,'Title',...
    [get(GuiSampleHandle.uiPanelScatter,'Title'),' ',num2str(0),'/',num2str(size(sampleFeatures,1))]);

set(gca,'TickDir','out');
feature_names = cell(size(sampleFeatures.Properties.VariableNames));
feature_names(2:end) = strrep(strrep(strrep(strrep(sampleFeatures.Properties.VariableNames(2:end),'_',' '),'ch 1',currentSample.channelNames(1)),'ch 2',currentSample.channelNames(2)),'ch 3',currentSample.channelNames(3));
if size(currentSample.channelNames,2) > 3
    feature_names(2:end) = strrep(feature_names(2:end),'ch 4',currentSample.channelNames(4));
end
if size(currentSample.channelNames,2) > 4
    feature_names(2:end) = strrep(feature_names(2:end),'ch 5',currentSample.channelNames(5));
end

% create choose button to switch feature index1 (x-axis)
GuiSampleHandle.popupFeatureSelectTopIndex1 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter,'Style','popup','Units','characters',...
            'String',feature_names(2:end),...
            'Position',[21 39.4 32.3 0.9],...
            'FontUnits', 'normalized',...
            'FontSize',1,...
            'Value',topFeatureIndex1,...
            'Callback',{@popupFeatureTopIndex1_Callback});
% create choose button to switch feature index2 (y-axis)
GuiSampleHandle.popupFeatureSelectTopIndex2 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter,'Style','popup','Units','characters',...
            'String',feature_names(2:end),...
            'Position',[-0.5 56.9 32.3 0.9],...
            'FontUnits', 'normalized',...
            'FontSize',1,...
            'Value',topFeatureIndex2,...
            'Callback',{@popupFeatureTopIndex2_Callback});
        % Create push button
GuiSampleHandle.gateScatter1 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter, 'Style', 'pushbutton', 'Units','characters','FontUnits', 'normalized',...
            'FontSize',0.4,'String', 'Gate','Position', [13.74 38.5 8.1 1.8],'Callback', @(handle,event,plotnr)gate_scatter(handle,event,1)); 
GuiSampleHandle.clearScatter = uicontrol('Parent',GuiSampleHandle.uiPanelScatter, 'Style', 'pushbutton', 'Units','characters','FontUnits', 'normalized',...
            'FontSize',0.4,'String', 'Clear Selection','Position', [36.1 56 16.2 1.8],'Callback', @clear_selection); 
GuiSampleHandle.selectSingleScatter1 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter, 'Style', 'pushbutton', 'Units','characters','FontUnits', 'normalized',...
            'FontSize',0.4,'String', 'Select Event','Position', [0.5 38.5 13.5 1.8],'Callback', @(handle,event,plotnr)select_event(handle,event,1));         


%----
% create data for scatter plot in the middle
GuiSampleHandle.axesMiddle = axes('Parent',GuiSampleHandle.uiPanelScatter,'Units','characters','Position',[9.2 22.8 40.4 13.4]); %[left bottom width height]
middleFeatureIndex1 = 9; middleFeatureIndex2 = 17;
gca; GuiSampleHandle.axesScatterMiddle = scatter(sampleFeatures.(middleFeatureIndex1+1),...    % +1 because first column in feature table is index (thumbNumber)
                                         sampleFeatures.(middleFeatureIndex2+1),marker_size,'filled','CData',rgbTriple);
xlim([0,max(ceil(1.1*max(sampleFeatures.(middleFeatureIndex1+1))),1)]); ylim([0,max(ceil(1.1*max(sampleFeatures.(middleFeatureIndex2+1))),1)]);
set(gca,'TickDir','out');
% create choose button to switch feature index1 (x-axis)
GuiSampleHandle.popupFeatureSelectMiddleIndex1 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter,'Style','popup','Units','characters',...
            'String',feature_names(2:end),...
            'Position',[21 20.1 32.3 0.9],...
            'FontUnits', 'normalized',...
            'FontSize',1,...
            'Value',middleFeatureIndex1,...
            'Callback',{@popupFeatureMiddleIndex1_Callback});
% create choose button to switch feature index2 (y-axis)
GuiSampleHandle.popupFeatureSelectMiddleIndex2 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter,'Style','popup','Units','characters',...
            'String',feature_names(2:end),...
            'Position',[-0.5 37.7 32.3 0.9],...
            'FontUnits', 'normalized',...
            'FontSize',1,...
            'Value',middleFeatureIndex2,...
            'Callback',{@popupFeatureMiddleIndex2_Callback});
% create push button
GuiSampleHandle.gateScatter2 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter, 'Style', 'pushbutton', 'Units','characters','FontUnits', 'normalized',...
            'FontSize',0.4,'String', 'Gate','Position', [13.74 19.2 8.1 1.8],'Callback', @(handle,event,plotnr)gate_scatter(handle,event,2)); 
GuiSampleHandle.selectSingleScatter2 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter, 'Style', 'pushbutton', 'Units','characters','FontUnits', 'normalized',...
            'FontSize',0.4,'String', 'Select Event','Position', [0.5 19.2 13.5 1.8],'Callback', @(handle,event,plotnr)select_event(handle,event,2));         

%----
% create scatter plot at the bottom
GuiSampleHandle.axesBottom = axes('Parent',GuiSampleHandle.uiPanelScatter,'Units','characters','Position',[9.2 3.5 40.4 13.4]); %[left bottom width height]
bottomFeatureIndex1 = 9; bottomFeatureIndex2 = 17;
gca; GuiSampleHandle.axesScatterBottom = scatter(sampleFeatures.(bottomFeatureIndex1+1),...    % +1 because first column in feature table is index (thumbNumber)
                                         sampleFeatures.(bottomFeatureIndex2+1),marker_size,'filled','CData',rgbTriple);
xlim([0,max(ceil(1.1*max(sampleFeatures.(bottomFeatureIndex1+1))),1)]); ylim([0,max(ceil(1.1*max(sampleFeatures.(bottomFeatureIndex2+1))),1)]);
set(gca,'TickDir','out');
% create choose button to switch feature index1 (x-axis)
GuiSampleHandle.popupFeatureSelectBottomIndex1 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter,'Style','popup','Units','characters',...
            'String',feature_names(2:end),...
            'Position',[21 0.9 32.3 0.9],...
            'FontUnits', 'normalized',...
            'FontSize',1,...
            'Value',bottomFeatureIndex1,...
            'Callback',{@popupFeatureBottomIndex1_Callback});
% create choose button to switch feature index2 (y-axis)
GuiSampleHandle.popupFeatureSelectBottomIndex2 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter,'Style','popup','Units','characters',...
            'String',feature_names(2:end),...
            'Position',[-0.5 18.4 32.3 0.9],...
            'FontUnits', 'normalized',...
            'FontSize',1,...
            'Value',bottomFeatureIndex2,...
            'Callback',{@popupFeatureBottomIndex2_Callback});
% create push button
GuiSampleHandle.gateScatter3 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter, 'Style', 'pushbutton', 'Units','characters','FontUnits', 'normalized',...
            'FontSize',0.4, 'String', 'Gate','Position', [13.74 0.0 8.1 1.8],'Callback', @(handle,event,plotnr)gate_scatter(handle,event,3)); 
GuiSampleHandle.selectSingleScatter3 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter, 'Style', 'pushbutton', 'Units','characters','FontUnits', 'normalized',...
            'FontSize',0.4,'String', 'Select Event','Position', [0.5 0.0 13.5 1.8],'Callback', @(handle,event,plotnr)select_event(handle,event,3));         
        

%% Create export/load buttons----
% export gates as manual classification
GuiSampleHandle.export_button = uicontrol('Style', 'pushbutton', 'Units','characters','String', 'Export Selection','FontUnits', 'normalized',...
            'FontSize',.5,'Position', [5.1 61.2 27.5 2.6],'Callback', {@export_gates}); 
% load gates as manual classification
GuiSampleHandle.export_button = uicontrol('Style', 'pushbutton', 'Units','characters','String', 'Load Selection','FontUnits', 'normalized',...
            'FontSize',.5,'Position', [33 61.2 26.4 2.6],'Callback', {@load_gates}); 
        
% export thumbnails
GuiSampleHandle.export_button = uicontrol('Style', 'pushbutton', 'Units','characters','String', 'Export Thumbnails','FontUnits', 'normalized',...
            'FontSize',.5,'Position', [181.7 61.2 33 2.6],'Callback', {@export_thumbs}); 
                                
%% Callback and helper functions

% --- Executes on selection in popupChannel.
function popupChannel_callback(hObject,~,~)
    selectedChannel = get(hObject,'Value');
    high=prctile(reshape(currentSample.overviewImage(:,:,selectedChannel),[1,size(currentSample.overviewImage,1)*size(currentSample.overviewImage,2)]),99);
    plotImInAxis(currentSample.overviewImage(:,:,selectedChannel).*(4095/high),[],GuiSampleHandle.axesOverview,GuiSampleHandle.imageOverview);
end

% --- Executes on selection in topFeatureIndex1 (x-axis)
function popupFeatureTopIndex1_Callback(hObject,~,~)
    selectedFeature = get(hObject,'Value');
    set(GuiSampleHandle.axesScatterTop,'XData',sampleFeatures.(selectedFeature+1)); % +1 because first column in feature table is index (thumbNumber)
    xlim(GuiSampleHandle.axesTop,[0,max(ceil(1.1*max(sampleFeatures.(selectedFeature+1))),1)]);
end

% --- Executes on selection in topFeatureIndex2 (y-axis)
function popupFeatureTopIndex2_Callback(hObject,~,~)
    selectedFeature = get(hObject,'Value');
    set(GuiSampleHandle.axesScatterTop,'YData',sampleFeatures.(selectedFeature+1)); % +1 because first column in feature table is index (thumbNumber)
    ylim(GuiSampleHandle.axesTop,[0,max(ceil(1.1*max(sampleFeatures.(selectedFeature+1))),1)]);
end

% --- Executes on selection in middleFeatureIndex1 (x-axis)
function popupFeatureMiddleIndex1_Callback(hObject,~,~)
    selectedFeature = get(hObject,'Value');
    set(GuiSampleHandle.axesScatterMiddle,'XData',sampleFeatures.(selectedFeature+1)); % +1 because first column in feature table is index (thumbNumber)
    xlim(GuiSampleHandle.axesMiddle,[0,max(ceil(1.1*max(sampleFeatures.(selectedFeature+1))),1)]);
end

% --- Executes on selection in middleFeatureIndex2 (y-axis)
function popupFeatureMiddleIndex2_Callback(hObject,~,~)
    selectedFeature = get(hObject,'Value');
    set(GuiSampleHandle.axesScatterMiddle,'YData',sampleFeatures.(selectedFeature+1)); % +1 because first column in feature table is index (thumbNumber)
    ylim(GuiSampleHandle.axesMiddle,[0,max(ceil(1.1*max(sampleFeatures.(selectedFeature+1))),1)]);
end

% --- Executes on selection in bottomFeatureIndex1 (x-axis)
function popupFeatureBottomIndex1_Callback(hObject,~,~)
    selectedFeature = get(hObject,'Value');
    set(GuiSampleHandle.axesScatterBottom,'XData',sampleFeatures.(selectedFeature+1)); % +1 because first column in feature table is index (thumbNumber)
    xlim(GuiSampleHandle.axesBottom,[0,max(ceil(1.1*max(sampleFeatures.(selectedFeature+1))),1)]);
end

% --- Executes on selection in bottomFeatureIndex2 (y-axis)
function popupFeatureBottomIndex2_Callback(hObject,~,~)
    selectedFeature = get(hObject,'Value');
    set(GuiSampleHandle.axesScatterBottom,'YData',sampleFeatures.(selectedFeature+1)); % +1 because first column in feature table is index (thumbNumber)
    ylim(GuiSampleHandle.axesBottom,[0,max(ceil(1.1*max(sampleFeatures.(selectedFeature+1))),1)]);
end

% --- Executes on slider movement.
function slider_callback(hObject,~)
    val = round(get(hObject,'Value'));
    plot_thumbnails(-val);
end

% --- Plot thumbnails around index i
function plot_thumbnails(val)
    %numberOfThumbs=size(currentSample.priorLocations,1);
    numberOfThumbs = nrUsedThumbs;
    thumbIndex=[val-2:1:val+2];
    thumbIndex(thumbIndex<1)=[];
    thumbIndex(thumbIndex>numberOfThumbs)=[];
    if ~isempty(thumbIndex)
        for j=1:numel(thumbIndex)
            thumbInd=thumbIndex(j);
            % obtain dataFrame from io
%             dataFrame = base.io.load_thumbnail_frame(currentSample,thumbInd,'prior');
%             dataFrame = base.io.load_thumbnail_frame(currentSample,thumbInd);
%             rawImage = currentSample.results.thumbnail_images{thumbInd};
%             segmentedImage = currentSample.results.segmentation{thumbInd};
            rawImage = currentSample.results.thumbnail_images{usedThumbs(thumbInd)};
            segmentedImage = currentSample.results.segmentation{usedThumbs(thumbInd)};
            k = (j-1)*cols + 1; % k indicates indices 1,6,11,...
            % plot overlay image in first column
%             plotImInAxis(dataFrame.rawImage,[],hAxes(k),hImages(k));
            plotImInAxis(rawImage,[],hAxes(k),hImages(k));
            
            % update visual selection dependent on selectedFrames array
            if GuiSampleHandle.selectedFrames(thumbInd) == 1
%                 set(hImages(k),'Selected','on');
                set(hAxes(k),'XTick',[]);
                set(hAxes(k),'yTick',[]);
                set(hAxes(k),'XColor',[1.0 0.5 0]);
                set(hAxes(k),'YColor',[1.0 0.5 0]);
                set(hAxes(k),'LineWidth',3);
                set(hAxes(k),'Visible','on');
            else
%                 set(hImages(k),'Selected','off');
                set(hAxes(k),'Visible','off');
            end
            % plot image for each color channel in column 2 till nbrChannels
            for chan = 1:cols-1
                l = ((j-1)*cols + chan + 1);
%                 plotImInAxis(dataFrame.rawImage(:,:,chan),segmentedImage(:,:,chan),hAxes(l),hImages(l));
                plotImInAxis(rawImage(:,:,chan),segmentedImage(:,:,chan),hAxes(l),hImages(l));
            end
        end
    end
end

% --- Helper function used in thumbnail gallery to plot thumbnails in axes
function plotImInAxis(im,segm,hAx,hIm)
    if size(im,3) > 1
        % create overlay image here
        %plot_image(hAx,im,255,'fullscale_rgb');
        overlay(:,:,1) = im(:,:,2)/maxi; overlay(:,:,3) = im(:,:,2)/maxi; overlay(:,:,2) = im(:,:,3)/maxi;
        %can we define Callback function somewhere else??
%         imagesc(overlay,{'ButtonDownFcn'},{'openSpecificImage'},'parent',hAx);
        %imshow(overlay,'parent',hAx,'InitialMagnification','fit'); 
        set(hIm,'CData',overlay);
    else
        %plot_image(hAx,im,255,'fullscale',{'ButtonDownFcn'},{'openSpecificImage(base)'});
%         imagesc(im/maxi,'ButtonDownFcn',{'openSpecificImage'},'parent',hAx);
        %can we define Callback function somewhere else??
        %imshow(im/maxi,'parent',hAx,'InitialMagnification','fit');

        if ~isempty(segm)
            cont = bwperim(segm,4);
            im(im>maxi)= maxi;
            im(cont) = (maxi+1);
        end
        set(hIm,'CData',im/(maxi+1));
    end
    axis(hAx,'image');
end

% --- Helper function used in thumbnail gallery to react on user clicks
function openSpecificImage(~,~,row)
    type = get(gcf,'SelectionType');
    switch type
        case 'open' % double-click
%             im = get(gcbo,'cdata');
%             figure; imagesc(im,[0,max(max(im(im<1)))]); axis equal; axis off;
        case 'normal' %left mouse button action
            if size(get(gcbo,'cdata'),3) > 1 % only allow selection for first overlay column elements
                if strcmp(get( get(gcbo,'Parent'),'Visible'),'off')
%                     set(gcbo,'Selected','on');
                    surroundingAx = get(gcbo,'Parent');
                    set(surroundingAx,'XTick',[]);
                    set(surroundingAx,'YTick',[]);
                    set(surroundingAx,'XColor',[1.0 0.5 0]);
                    set(surroundingAx,'YColor',[1.0 0.5 0]);
                    set(surroundingAx,'LineWidth',3);
                    set(surroundingAx,'Visible','on');
                    pos = max(1,-round(get(GuiSampleHandle.slider,'Value'))-3+row);
                    updateScatterPlots(pos,1);
                else
%                     set(gcbo,'Selected','off');
                    surroundingAx = get(gcbo,'Parent');
                    set(surroundingAx,'Visible','off');
                    pos = max(-round(get(GuiSampleHandle.slider,'Value'))-3+row,1);
                    updateScatterPlots(pos,0);
                end
            end
        case 'extend' % shift & left mouse button action
            if size(get(gcbo,'cdata'),3) > 1 % only allow selection for first overlay column elements
                pos = max(1,-round(get(GuiSampleHandle.slider,'Value'))-3+row);
                posToDelete = sampleFeatures.ThumbNr == pos;
                sampleFeatures(posToDelete,:) = [];
                rgbTriple(posToDelete,:) = [];
                GuiSampleHandle.selectedFrames(pos) = [];
                GuiSampleHandle.selectedCells(posToDelete) = [];
                usedThumbs(pos) = [];
                plot_thumbnails(pos);
                
                axes(GuiSampleHandle.axesTop)
                GuiSampleHandle.axesScatterTop = scatter(sampleFeatures.(topFeatureIndex1+1),...    % +1 because first column in feature table is index (thumbNumber)
                                                      sampleFeatures.(topFeatureIndex2+1),marker_size,'filled','CData',rgbTriple);
                xlim([0,max(ceil(1.1*max(sampleFeatures.(topFeatureIndex1+1))),1)]); ylim([0,max(ceil(1.1*max(sampleFeatures.(topFeatureIndex2+1))),1)]);
                
                axes(GuiSampleHandle.axesMiddle) 
                GuiSampleHandle.axesScatterMiddle = scatter(sampleFeatures.(middleFeatureIndex1+1),...    % +1 because first column in feature table is index (thumbNumber)
                                                         sampleFeatures.(middleFeatureIndex2+1),marker_size,'filled','CData',rgbTriple);
                xlim([0,max(ceil(1.1*max(sampleFeatures.(middleFeatureIndex1+1))),1)]); ylim([0,max(ceil(1.1*max(sampleFeatures.(middleFeatureIndex2+1))),1)]);
                
                axes(GuiSampleHandle.axesBottom)
                GuiSampleHandle.axesScatterBottom = scatter(sampleFeatures.(bottomFeatureIndex1+1),...    % +1 because first column in feature table is index (thumbNumber)
                                         sampleFeatures.(bottomFeatureIndex2+1),marker_size,'filled','CData',rgbTriple);
                xlim([0,max(ceil(1.1*max(sampleFeatures.(bottomFeatureIndex1+1))),1)]); ylim([0,max(ceil(1.1*max(sampleFeatures.(bottomFeatureIndex2+1))),1)]);
                set(GuiSampleHandle.uiPanelScatter,'Title',['Marker Characterization '...
                                        num2str(sum(GuiSampleHandle.selectedCells)) '/' num2str(size(sampleFeatures,1))]);
            end
        case 'alt' % right mouse button action
            im = get(gcbo,'cdata');
            figure; imagesc(im,[0,max(max(im(im<1)))]); axis equal; axis off;
    end
end

% --- Helper function to update scatter plots
function updateScatterPlots(pos,booleanOnOff)
    GuiSampleHandle.selectedFrames(pos) = booleanOnOff;
    GuiSampleHandle.selectedCells(sampleFeatures.ThumbNr == usedThumbs(pos)) = booleanOnOff;
    rgbTriple(GuiSampleHandle.selectedCells,1) = 1;
    rgbTriple(GuiSampleHandle.selectedCells,2) = 0.5;
    rgbTriple(GuiSampleHandle.selectedCells,3) = 0;
    rgbTriple(~GuiSampleHandle.selectedCells,1) = 0;
    rgbTriple(~GuiSampleHandle.selectedCells,2) = 0;
    rgbTriple(~GuiSampleHandle.selectedCells,3) = 1;
    % update all scatter plots with new manual clustering
    set(GuiSampleHandle.axesScatterTop,'CData',rgbTriple);
    set(GuiSampleHandle.axesScatterMiddle,'CData',rgbTriple);
    set(GuiSampleHandle.axesScatterBottom,'CData',rgbTriple);
    % update title for scatter panel showing clustering summary
    set(GuiSampleHandle.uiPanelScatter,'Title',['Marker Characterization '...
        num2str(sum(GuiSampleHandle.selectedCells)) '/' num2str(size(sampleFeatures,1))]);
end


function gate_scatter(handle,~,plotnr)
    color = get(handle,'backg');
    set(handle,'backgroundcolor',[1 .5 .5])
    drawnow;
    if plotnr == 1
        h = impoly(GuiSampleHandle.axesTop);
        xtest = get(GuiSampleHandle.axesScatterTop,'XData');
        ytest = get(GuiSampleHandle.axesScatterTop,'YData');
    elseif plotnr == 2
        h = impoly(GuiSampleHandle.axesMiddle);
        xtest = get(GuiSampleHandle.axesScatterMiddle,'XData');
        ytest = get(GuiSampleHandle.axesScatterMiddle,'YData');
    else
        h = impoly(GuiSampleHandle.axesBottom);
        xtest = get(GuiSampleHandle.axesScatterBottom,'XData');
        ytest = get(GuiSampleHandle.axesScatterBottom,'YData');
    end
         
    pos = getPosition(h);
    [in,~] = inpolygon(xtest,ytest,pos(:,1),pos(:,2));
    GuiSampleHandle.selectedCells(in) = 1;
    GuiSampleHandle.selectedFrames(ismember(usedThumbs,sampleFeatures.ThumbNr(in))) = 1; 
    rgbTriple(GuiSampleHandle.selectedCells,1) = 1;
    rgbTriple(GuiSampleHandle.selectedCells,2) = 0.5;
    rgbTriple(GuiSampleHandle.selectedCells,3) = 0;
    rgbTriple(~GuiSampleHandle.selectedCells,1) = 0;
    rgbTriple(~GuiSampleHandle.selectedCells,2) = 0;
    rgbTriple(~GuiSampleHandle.selectedCells,3) = 1;
    % update all scatter plots with new manual clustering
    set(GuiSampleHandle.axesScatterTop,'CData',rgbTriple);
    set(GuiSampleHandle.axesScatterMiddle,'CData',rgbTriple);
    set(GuiSampleHandle.axesScatterBottom,'CData',rgbTriple);
    delete(h);
    set(GuiSampleHandle.uiPanelScatter,'Title',['Marker Characterization '...
        num2str(sum(GuiSampleHandle.selectedCells)) '/' num2str(size(sampleFeatures,1))]);
    % update view to selected thumbnail closest to current view
    val = round(get(GuiSampleHandle.slider, 'Value'));
    [~, index] = min(abs((-find(GuiSampleHandle.selectedFrames))-val));
    selectedFrames = find(GuiSampleHandle.selectedFrames);
    closestValue = selectedFrames(index(1)); 
    plot_thumbnails(closestValue);
    set(GuiSampleHandle.slider, 'Value',-closestValue);
    set(handle,'backg',color)
end

function clear_selection(~,~)
    GuiSampleHandle.selectedCells = false(size(GuiSampleHandle.selectedCells));
    GuiSampleHandle.selectedFrames = false(size(GuiSampleHandle.selectedFrames));
    rgbTriple(~GuiSampleHandle.selectedCells,1) = 0;
    rgbTriple(~GuiSampleHandle.selectedCells,2) = 0;
    rgbTriple(~GuiSampleHandle.selectedCells,3) = 1;
    set(GuiSampleHandle.axesScatterTop,'CData',rgbTriple);
    set(GuiSampleHandle.axesScatterMiddle,'CData',rgbTriple);
    set(GuiSampleHandle.axesScatterBottom,'CData',rgbTriple);
    set(GuiSampleHandle.uiPanelScatter,'Title',['Marker Characterization '...
    num2str(sum(GuiSampleHandle.selectedCells)) '/' num2str(size(sampleFeatures,1))]);
    val = round(get(GuiSampleHandle.slider, 'Value'));
    plot_thumbnails(-val);
end

function select_event(handle,~,plotnr)
    color = get(handle,'backg');
    set(handle,'backgroundcolor',[1 .5 .5])
    drawnow;
    if plotnr == 1
        h = impoint(GuiSampleHandle.axesTop);
        xtest = get(GuiSampleHandle.axesScatterTop,'XData');
        ytest = get(GuiSampleHandle.axesScatterTop,'YData');
    elseif plotnr == 2
        h = impoint(GuiSampleHandle.axesMiddle);
        xtest = get(GuiSampleHandle.axesScatterMiddle,'XData');
        ytest = get(GuiSampleHandle.axesScatterMiddle,'YData');
    else
        h = impoint(GuiSampleHandle.axesBottom);
        xtest = get(GuiSampleHandle.axesScatterBottom,'XData');
        ytest = get(GuiSampleHandle.axesScatterBottom,'YData');
    end
    pos = getPosition(h);
%     pos_extended = [0.95*pos(1), 0.95*pos(2); 0.95*pos(1), 1.05*pos(2); 1.05*pos(1), 1.05*pos(2); 1.05*pos(1), 0.95*pos(2)];
    pos_extended = [pos(1)-50, pos(2)-50; pos(1)-50, pos(2)+50; pos(1)+50, pos(2)+50; pos(1)+50, pos(2)-50];
    [in,~] = inpolygon(xtest,ytest,pos_extended(:,1),pos_extended(:,2));
    sum(in)
    if sum(in) > 1
        indices = find(in);
        [~,index] = min((xtest(in) - pos(1)).^2 + (ytest(in) - pos(2)).^2);
        in(indices(indices ~= indices(index))) = 0;
    end
    if GuiSampleHandle.selectedCells(in) == 0
        GuiSampleHandle.selectedCells(in) = 1;
        GuiSampleHandle.selectedFrames(ismember(usedThumbs,sampleFeatures.ThumbNr(in))) = 1; 
        rgbTriple(GuiSampleHandle.selectedCells,1) = 1;
        rgbTriple(GuiSampleHandle.selectedCells,2) = 0.5;
        rgbTriple(GuiSampleHandle.selectedCells,3) = 0;
        rgbTriple(~GuiSampleHandle.selectedCells,1) = 0;
        rgbTriple(~GuiSampleHandle.selectedCells,2) = 0;
        rgbTriple(~GuiSampleHandle.selectedCells,3) = 1;
        % update all scatter plots with new manual clustering
        set(GuiSampleHandle.axesScatterTop,'CData',rgbTriple);
        set(GuiSampleHandle.axesScatterMiddle,'CData',rgbTriple);
        set(GuiSampleHandle.axesScatterBottom,'CData',rgbTriple);
        delete(h);
        set(GuiSampleHandle.uiPanelScatter,'Title',['Marker Characterization '...
            num2str(sum(GuiSampleHandle.selectedCells)) '/' num2str(size(sampleFeatures,1))]);
        % update view to selected thumbnail
        plot_thumbnails(find(usedThumbs == sampleFeatures.ThumbNr(in)));
        set(GuiSampleHandle.slider, 'Value',-sampleFeatures.ThumbNr(in));
    else
        GuiSampleHandle.selectedCells(in) = 0;
        if ~isempty(GuiSampleHandle.selectedCells(in)) && isempty(find(sampleFeatures.ThumbNr(GuiSampleHandle.selectedCells) == sampleFeatures.ThumbNr(in), 1))
            GuiSampleHandle.selectedFrames(ismember(usedThumbs,sampleFeatures.ThumbNr(in))) = 0; 
        end
        rgbTriple(GuiSampleHandle.selectedCells,1) = 1;
        rgbTriple(GuiSampleHandle.selectedCells,2) = 0.5;
        rgbTriple(GuiSampleHandle.selectedCells,3) = 0;
        rgbTriple(~GuiSampleHandle.selectedCells,1) = 0;
        rgbTriple(~GuiSampleHandle.selectedCells,2) = 0;
        rgbTriple(~GuiSampleHandle.selectedCells,3) = 1;
        % update all scatter plots with new manual clustering
        set(GuiSampleHandle.axesScatterTop,'CData',rgbTriple);
        set(GuiSampleHandle.axesScatterMiddle,'CData',rgbTriple);
        set(GuiSampleHandle.axesScatterBottom,'CData',rgbTriple);
        delete(h);
        set(GuiSampleHandle.uiPanelScatter,'Title',['Marker Characterization '...
            num2str(sum(GuiSampleHandle.selectedCells)) '/' num2str(size(sampleFeatures,1))]);
        % update currentview
        val = round(get(GuiSampleHandle.slider, 'Value'));
        plot_thumbnails(-val);
    end
    set(handle,'backg',color)
end

function export_gates(handle,~)
    color = get(handle,'backg');
    set(handle,'backgroundcolor',[1 .5 .5])
    drawnow;
    set(0,'defaultUicontrolFontSize', 14)
    exist = true;
    name = inputdlg({''},...
        'Please enter a name for your manual selection.', [1,75],{''},'on');
    classes = currentSample.results.classification.Properties.VariableNames;
    while exist 
        [exist,loc] = ismember(name,classes);
        if exist
            choice = questdlg('There exists a classification with this name. Do you want to overwrite it?', ...
                                    'Error', 'Yes','No','No');
            switch choice
                case 'Yes'
                    currentSample.results.classification(:,loc) = [];
                    exist = false;
                case 'No'
                    name = inputdlg({''},...
                        'Please enter a new name for your manual selection.', [1,75],{''},'on');            
            end
        end
    end
    if ~isempty(name)
        currentSample.results.classification = [currentSample.results.classification array2table(GuiSampleHandle.selectedCells,'VariableNames',{name{1}})];
        base.io.save_sample(currentSample);
        base.io.save_results_as_xls(currentSample)
    end
    set(0,'defaultUicontrolFontSize', 12)
    set(handle,'backg',color)
end

function load_gates(handle,~)
    color = get(handle,'backg');
    set(handle,'backgroundcolor',[1 .5 .5])
    drawnow;
    classes = currentSample.results.classification.Properties.VariableNames;
    if isempty(classes)
        msgbox('No prior selection avaliable.')
    elseif size(classes,2)==1
        GuiSampleHandle.selectedCells = false(size(GuiSampleHandle.selectedCells));
        GuiSampleHandle.selectedFrames = false(size(GuiSampleHandle.selectedFrames));
        GuiSampleHandle.selectedCells = currentSample.results.classification{:,1};
        GuiSampleHandle.selectedFrames(ismember(usedThumbs,sampleFeatures.ThumbNr(GuiSampleHandle.selectedCells))) = 1; 
        rgbTriple(GuiSampleHandle.selectedCells,1) = 1;
        rgbTriple(GuiSampleHandle.selectedCells,2) = 0.5;
        rgbTriple(GuiSampleHandle.selectedCells,3) = 0;
        rgbTriple(~GuiSampleHandle.selectedCells,1) = 0;
        rgbTriple(~GuiSampleHandle.selectedCells,2) = 0;
        rgbTriple(~GuiSampleHandle.selectedCells,3) = 1;
        set(GuiSampleHandle.axesScatterTop,'CData',rgbTriple);
        set(GuiSampleHandle.axesScatterMiddle,'CData',rgbTriple);
        set(GuiSampleHandle.axesScatterBottom,'CData',rgbTriple);
        set(GuiSampleHandle.uiPanelScatter,'Title',['Marker Characterization '...
        num2str(sum(GuiSampleHandle.selectedCells)) '/' num2str(size(sampleFeatures,1))]);
        val = round(get(GuiSampleHandle.slider, 'Value'));
        plot_thumbnails(-val);      
    else
        [s,v] = listdlg('PromptString',[{'There are multiple prior selections available. Please select one:'} {''}],...
                'SelectionMode','single',...
                'ListString',classes,'ListSize',[250,150]);
        if v == 1
            GuiSampleHandle.selectedCells = false(size(GuiSampleHandle.selectedCells));
            GuiSampleHandle.selectedFrames = false(size(GuiSampleHandle.selectedFrames));
            GuiSampleHandle.selectedCells = currentSample.results.classification{:,s};
            GuiSampleHandle.selectedFrames(ismember(usedThumbs,sampleFeatures.ThumbNr(GuiSampleHandle.selectedCells))) = 1; 
            rgbTriple(GuiSampleHandle.selectedCells,1) = 1;
            rgbTriple(GuiSampleHandle.selectedCells,2) = 0.5;
            rgbTriple(GuiSampleHandle.selectedCells,3) = 0;
            rgbTriple(~GuiSampleHandle.selectedCells,1) = 0;
            rgbTriple(~GuiSampleHandle.selectedCells,2) = 0;
            rgbTriple(~GuiSampleHandle.selectedCells,3) = 1;
            set(GuiSampleHandle.axesScatterTop,'CData',rgbTriple);
            set(GuiSampleHandle.axesScatterMiddle,'CData',rgbTriple);
            set(GuiSampleHandle.axesScatterBottom,'CData',rgbTriple);
            set(GuiSampleHandle.uiPanelScatter,'Title',['Marker Characterization '...
            num2str(sum(GuiSampleHandle.selectedCells)) '/' num2str(size(sampleFeatures,1))]);
            val = round(get(GuiSampleHandle.slider, 'Value'));
            plot_thumbnails(-val); 
        end
    end
    set(handle,'backg',color)
end

function export_thumbs(handle,~)
    color = get(handle,'backg');
    set(handle,'backgroundcolor',[1 .5 .5])
    drawnow;
    base.io.save_thumbnail(currentSample)
    set(handle,'backg',color)
end
end