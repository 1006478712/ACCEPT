function handle = gui_main(base)

% global gui

tasks = [];

% Update chooseButton for tasks via available sampleProcessors
gui.tasks_raw = base.availableSampleProcessors;
% convert sampleProcessor m-file names to readable Strings
if ~isempty(gui.tasks_raw)
    tasks = strrep(strrep(gui.tasks_raw,'_',' '),'.m','');
end
% select DEFAULT sampleProcessor number (in alphabetical order) for visualization
defaultSampleProcessorNumber = 2;

uni_logo = imread('logoUT.png'); [uni_logo_x, uni_logo_y, ~] = size(uni_logo); uni_logo_rel = uni_logo_x / uni_logo_y;
cancerid_logo = imread('logoCancerID.png'); [cancerid_logo_x, cancerid_logo_y, ~] = size(cancerid_logo); cancerid_logo_rel = cancerid_logo_x / cancerid_logo_y;
% subtitle = imread('title2.tif'); [subtitle_x, subtitle_y, ~] = size(subtitle); subtitle_rel = subtitle_x / subtitle_y;

%Menu
gui.screensize = get( 0, 'Screensize' );
gui.rel_screen = (0.5*gui.screensize(3))/(0.75*gui.screensize(4));


%window
posx = 0.25; posy = 0.15; width = 0.5; height = 0.75; gui.rel = width/height;

% gui.fig_main = figure('Units','normalized','Position',[posx posy width height],'Name','ACCEPT - Automated CTC Classification Enumeration and PhenoTyping','MenuBar','none',...
%     'NumberTitle','off','Color', [1 1 1],'ResizeFcn',@doResizeFcn,'Visible','off');
gui.fig_main = figure('Units','normalized','Position',[posx posy width height],'Name','ACCEPT - Automated CTC Classification Enumeration and PhenoTyping','MenuBar','none',...
    'NumberTitle','off','Color', [1 1 1],'Resize','off','Visible','off');

gui.process_button = uicontrol(gui.fig_main,'Style','pushbutton','String','Process','Units','normalized','Position',[0.22 0.1 0.22 0.05],'FontUnits','normalized', 'FontSize',0.5,'Callback', {@process,base}); 
gui.visualize_button = uicontrol(gui.fig_main,'Style','pushbutton','String','Visualize','Units','normalized','Position',[0.56 0.1 0.22 0.05],'FontUnits','normalized', 'FontSize',0.5,'Callback', {@visualize,base});

% gui.titel = uicontrol(gui.fig_main,'Style','text', 'String','ACCEPT','Units','normalized','Position',[0.41 0.83 0.18 0.04],'FontUnits','normalized', 'FontSize',1,'BackgroundColor',[1 1 1],'ForegroundColor',[0.729 0.161 0.208]);
gui.title_axes = axes('Units','normalized','Position',[0.5 0.83 0.18 0.04]); axis off;
gui.titel = text('Position',[0 0],'String','\color[rgb]{0.729,0.161,0.208} ACCEPT','Units','normalized','FontUnits','normalized', 'FontSize',1,'verticalAlignment','base','horizontalAlignment','center','FontWeight','bold');

gui.subtitle_axes = axes('Units','normalized','Position',[0.5 0.77 0.85 0.03]);axis off;
gui.subtitel = text('Position',[0 0],'String','\color[rgb]{0.729,0.161,0.208}A\color[rgb]{0,0,0}utom\color[rgb]{0,0,0}ated \color[rgb]{0.729,0.161,0.208}C\color[rgb]{0,0,0}TC \color[rgb]{0.729,0.161,0.208}C\color[rgb]{0,0,0}lassification \color[rgb]{0.729,0.161,0.208}E\color[rgb]{0,0,0}numeration and \color[rgb]{0.729,0.161,0.208}P\color[rgb]{0,0,0}heno\color[rgb]{0.729,0.161,0.208}T\color[rgb]{0,0,0}yping',...
    'Units','normalized','FontUnits','normalized', 'FontSize',1,'verticalAlignment','base','horizontalAlignment','center','FontWeight','bold');


gui.task = uicontrol(gui.fig_main,'Style','text', 'String','Choose a task:','Units','normalized','Position',[0.22 0.7 0.15 0.02],'FontUnits','normalized', 'FontSize',1,'BackgroundColor',[1 1 1]);
gui.task_list = uicontrol('Style', 'popup','String', tasks,'Units','normalized','Position', [0.39 0.703 0.39 0.019],'Callback', {@choosetask,base}, 'FontUnits','normalized', 'FontSize',1);  
set(gui.task_list,'Value',defaultSampleProcessorNumber);
% create sampleProcessor object for - per default - selected sampleProcessor 
currentSampleProcessorName = strrep(gui.tasks_raw{get(gui.task_list,'Value')},'.m','');
eval(['base.sampleProcessor = ',currentSampleProcessorName,'();']);
base.sampleList.sampleProcessorId=base.sampleProcessor.id();

gui.input_path_frame = uipanel('Parent',gui.fig_main, 'Units','normalized','Position',[0.22 0.597 0.359 0.038]);
gui.input_path = uicontrol(gui.fig_main,'Style','text', 'String','','Units','normalized','Position',[0.223 0.608 0.353 0.016],'FontUnits','normalized', 'FontSize',1);
gui.input_path_button = uicontrol(gui.fig_main,'Style','pushbutton','String','Select input folder','Units','normalized','Position',[0.58 0.597 0.2 0.038],'FontUnits','normalized', 'FontSize',0.5,'Callback', {@input_path,base});

gui.results_path_frame = uipanel('Parent',gui.fig_main, 'Units','normalized','Position',[0.22 0.537 0.359 0.038]);
gui.results_path = uicontrol(gui.fig_main,'Style','text', 'String','','Units','normalized','Position',[0.223 0.548 0.353 0.016],'FontUnits','normalized', 'FontSize',1);
gui.results_path_button = uicontrol(gui.fig_main,'Style','pushbutton','String','Select results folder','Units','normalized','Position',[0.58 0.537 0.2 0.038],'FontUnits','normalized', 'FontSize',0.5,'Callback', {@results_path,base});

gui.uni_logo_axes = axes('Units','normalized','Position',[0.57 0.025 0.4 0.4*uni_logo_rel*gui.rel_screen]);
gui.uni_logo = imagesc(uni_logo);  axis off;

gui.cancerid_logo_axes = axes('Units','normalized','Position',[0.66 0.83 0.3 0.3*cancerid_logo_rel*gui.rel_screen]); 
gui.cancerid_logo = imagesc(cancerid_logo); axis off;

% gui.subtitle_axes = axes('Units','normalized','Position',[0.13 0.77 0.74 0.74*subtitle_rel*rel]);
% gui.subtitle = imagesc(subtitle);  axis off;

gui.table_frame = uipanel('Parent',gui.fig_main, 'Units','normalized','Position',[0.34 0.1805 0.32 0.326], 'BackgroundColor', [1 1 1]);
gui.table = uitable('Parent', gui.table_frame, 'Data', [],'ColumnName', {'Sample name','Processed'},'ColumnFormat', {'char','logical'},'ColumnEditable', false,'RowName',[],'Units','normalized',...
    'Position', [0 0 1 1],'ColumnWidth',{0.32*0.59*0.5*gui.screensize(3) 0.32*0.39*0.5*gui.screensize(3)}, 'FontUnits','normalized', 'FontSize',0.05,'CellSelectionCallback',@(src,evnt)set(src,'UserData',evnt.Indices));

handle = gui.fig_main;
set(gui.fig_main,'Visible','on');
update_list(base);



function process(handle,~,base)
%     global gui
    display('Process samples...')
    color = get(handle,'backg');
    set(handle,'backgroundcolor',[1 .5 .5],'string','Process samples...');
    drawnow;
    selectedCellsInTable = get(gui.table,'UserData');
    if size(selectedCellsInTable,1) == 0
        msgbox('No sample selected')
    else
        if and(~isempty(base.sampleList.inputPath),~isempty(base.sampleList.resultPath))
            % update the current sampleList: selected samples should be processed
            base.sampleList.toBeProcessed(selectedCellsInTable(:,1)) = 1;
            base.run();
        else
            msgbox('no dirs selected');
        end
    end
    set(handle,'backg',color,'String','Process');
    update_list(base);
   
end

function visualize(handle,~,base)
%     global gui
    display('Visualize samples...')
    color = get(handle,'backg');
    set(handle,'backgroundcolor',[1 .5 .5],'string','Starting GUI')
    drawnow;
    selectedCellsInTable = get(gui.table,'UserData');
    if size(selectedCellsInTable,1) == 0
        msgbox('No sample selected')
    elseif size(selectedCellsInTable,1) == 1
        if and(~isempty(base.sampleList.inputPath),~isempty(base.sampleList.resultPath))
        % load selected sample
        currentSample = base.io.load_sample(base.sampleList,selectedCellsInTable(1));
        % run sampleVisGui with loaded sample
        gui_sample(base,currentSample);
        else
            msgbox('no dirs selected')
        end
    else
        msgbox('Too many samples selected for visualization');
    end
    set(handle,'backg',color,'String','Visualize')
end

function input_path(~,~,base)
%     global gui
    inputPath = uigetdir(pwd,'Please select an input folder.');
    if inputPath ~= 0
        set(gui.input_path,'String',inputPath);
        base.sampleList.inputPath=inputPath;
        update_list(base);
    end
end

function results_path(~,~,base)
%     global gui
    resultPath = uigetdir(pwd,'Please select a results folder.');
    if resultPath ~= 0
        test=strfind(resultPath,get(gui.input_path,'String'));
        if isempty(test)
            set(gui.results_path,'String',resultPath);
        else
            msgbox('The results folder cannot be located inside of the image folder')
        end
        base.sampleList.resultPath=resultPath;
        update_list(base);
    end
end

function choosetask(source,~,base)
%     global gui
    val = get(source,'Value');        
    set(gui.task_list,'Value',val);
    % create sampleProcessor object for selected sampleProcessor 
    currentSampleProcessorName = strrep(gui.tasks_raw{val},'.m','');
    eval(['base.sampleProcessor = ',currentSampleProcessorName,'();']);
    base.sampleList.sampleProcessorId=base.sampleProcessor.id();
    update_list(base);
end

function update_list(base)
%     global gui
    % update inputPath if none is selected. 
    if or(isempty(base.sampleList.inputPath),isempty(base.sampleList.resultPath))
        dat{1,1}='Please select an';
        dat{2,1}='input and output folder.';        
    else
        sl = base.sampleList;
        base.io.update_sample_list(sl);
        nbrSamples = size(sl.sampleNames,2);
        nbrAttributes = 2;
        dat = cell(nbrSamples,nbrAttributes);
        for r=1:nbrSamples
            dat{r,1} = sl.sampleNames{1,r};
            dat{r,2} = sl.isProcessed(1,r);
        end   
    end
    set(gui.table,'data', dat);
end

function doResizeFcn(varargin)
% global gui
% x = get(gui.fig_main,'Position')
% % set(gui.task, 'String','bla');
% if x(3)/gui.rel<= 1
%     set(gui.fig_main,'Position',[x(1) x(2) x(3) x(3)/gui.rel]);
% else
%     set(gui.fig_main,'Position',[x(1) 0 gui.rel 1]);
% end
% x_new = get(gui.fig_main,'Position')
% % set(gui.table, 'ColumnWidth',{0.32*0.59*x(3)*gui.screensize(3) 0.32*0.39*x(3)*gui.screensize(3)});

end
end

