%% This file is part of ACCEPT, 
% A program for the automated classification, enumeration and 
% phenotyping of Circulating Tumor Cells.
% Copyright (C) 2016 Leonie Zeune, Guus van Dalum, Christoph Brune
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
%% 
classdef ExtractFeatures < DataframeProcessorObject
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        nrObjects = [];
    end
    
    methods
        function returnFrame = run(this,inputFrame)
            if isa(inputFrame,'Dataframe')
                returnFrame = inputFrame;
                returnFrame.features = table();
                this.nrObjects = max(inputFrame.labelImage(:));

                if this.nrObjects > 0
                    for ch = 1:inputFrame.nrChannels
                        imTemp = inputFrame.rawImage(:,:,ch);
                        MsrTemp = regionprops(inputFrame.labelImage(:,:,ch), imTemp - median(imTemp(inputFrame.labelImage(:,:,ch) == 0)),...
                                'MaxIntensity', 'PixelValues', 'MeanIntensity', 'Area', 'Perimeter', 'Eccentricity');

                        %fill structure so tables can be concatenated.
                        MsrTemp=fillStruct(this, MsrTemp);

                        StandardDeviation = arrayfun(@(x) std2(x.PixelValues)/x.MeanIntensity, MsrTemp);
                        Mass = arrayfun(@(x) sum(x.PixelValues), MsrTemp);
                        P2A = arrayfun(@(x) x.Perimeter^2/(4*pi*x.Area), MsrTemp);
                        Size = arrayfun(@(x) x.Area *(inputFrame.pixelSize)^2 , MsrTemp);
                        MsrTemp=rmfield(MsrTemp,{'PixelValues','Area'});

                        names = strcat('ch_',num2str(ch),'_',fieldnames(MsrTemp));
                        tmpTable = struct2table(MsrTemp);
                        tmpTable.Properties.VariableNames = names;
                        tmpStandardDeviation = array2table(StandardDeviation,'VariableNames',{strcat('ch_',num2str(ch),'_StandardDeviation')});
                        tmpMass = array2table(Mass,'VariableNames',{strcat('ch_',num2str(ch),'_Mass')});
                        tmpP2A = array2table(P2A,'VariableNames',{strcat('ch_',num2str(ch),'_P2A')});
                        tmpSize = array2table(Size,'VariableNames',{strcat('ch_',num2str(ch),'_Size')});
                        returnFrame.features = [returnFrame.features tmpTable tmpSize tmpStandardDeviation tmpMass tmpP2A];
                    end
                              
                    %% VERY TIME CONSUMING DUE TO COMPLEXITY (not needed?)
%                     for ch_one = 1:inputFrame.nrChannels
%                         for ch_two = 1:ch_one
%                             tmpTbl = table();
%                             for i = 1:this.nrObjects
%                                 tmpImg = returnFrame.labelImage == i;
%                                 tmpTbl = [tmpTbl; array2table(sum(sum(tmpImg(:,:,ch_one) & tmpImg(:,:,ch_two))),...
%                                     'VariableNames',{strcat('Overlay_ch_',num2str(ch_one),'_ch_',num2str(ch_two))})]; 
%                             end
%                             returnFrame.features = [returnFrame.features tmpTbl];
%                         end
%                     end
                    %% smaller variant
                    for ch_two = 1:inputFrame.nrChannels
                        if ch_two ~= 2
                            tmpTbl = table();
                            for i = 1:this.nrObjects
                                tmpImg = returnFrame.labelImage == i;
                                tmpTbl = [tmpTbl; array2table(sum(sum(tmpImg(:,:,2) & tmpImg(:,:,ch_two)))/sum(sum(tmpImg(:,:,2))),...
                                    'VariableNames',{strcat('ch_', num2str(2),'_Overlay_ch_',num2str(ch_two))})]; 
                            end
                            returnFrame.features = [returnFrame.features tmpTbl];
                        end
                    end
                end
            elseif isa(inputFrame,'double')
                if mod(size(inputFrame,3),2) ~= 0
                    error('Feature Extraction not possible. Number of image frames and segmented frames is not the same!')
                end
                rawImage = inputFrame(:,:,1:size(inputFrame,3)/2);
                segImage = inputFrame(:,:,size(inputFrame,3)/2+1:end);
                
                if ~isempty(find(segImage(segImage ~= 1),1))
                    error('Feature Extraction not possible. Segmented Image is not binary.')
                end
                
                % transform to labeled image
                sumImage = sum(segImage,3); 
                labels = repmat(bwlabel(sumImage,4),1,1,size(segImage,3));
                labelImage = labels.*segImage;
            
                returnFrame = table();
                this.nrObjects = max(labelImage(:));

                if this.nrObjects > 0
                    for ch = 1:size(segImage,3)
                        imTemp = rawImage(:,:,ch);
                        MsrTemp = regionprops(labelImage(:,:,ch), imTemp - median(imTemp(labelImage(:,:,ch) == 0)),...
                                'MaxIntensity', 'PixelValues', 'MeanIntensity', 'Area', 'Perimeter', 'Eccentricity');

                        %fill structure so tables can be concatenated.
                        MsrTemp=fillStruct(this, MsrTemp);

                        StandardDeviation = arrayfun(@(x) std2(x.PixelValues), MsrTemp);
                        Mass = arrayfun(@(x) sum(x.PixelValues), MsrTemp);
                        P2A = arrayfun(@(x) x.Perimeter^2/(4*pi*x.Area), MsrTemp);

                        MsrTemp=rmfield(MsrTemp,'PixelValues');

                        names = strcat('ch_',num2str(ch),'_',fieldnames(MsrTemp));
                        tmpTable = struct2table(MsrTemp);
                        tmpTable.Properties.VariableNames = names;
                        tmpStandardDeviation = array2table(StandardDeviation,'VariableNames',{strcat('ch_',num2str(ch),'_StandardDeviation')});
                        tmpMass = array2table(Mass,'VariableNames',{strcat('ch_',num2str(ch),'_Mass')});
                        tmpP2A = array2table(P2A,'VariableNames',{strcat('ch_',num2str(ch),'_P2A')});
                        returnFrame = [returnFrame tmpTable tmpStandardDeviation tmpMass tmpP2A];
                    end
                end
            else
                error('Extract Features can only be used on dataframes or double images combined with a binary segmentation for each channel.');
            end
        end

        function MsrTemp=fillStruct(this, MsrTemp)
            numObjects = this.nrObjects;
            numMsr=numel(MsrTemp);

            if numMsr ~= numObjects
                if numMsr == 0;
                    MsrTemp(1:numObjects,1)=struct('Area',0,'Eccentricity', 0 ,'Perimeter',0,...
                        'PixelValues',[],'MeanIntensity',NaN ,'MaxIntensity',NaN );
                else
                    MsrTemp(numMsr+1:numObjects,1)=struct('Area',0 ,'Eccentricity', 0,...
                        'Perimeter',0, 'PixelValues',[],'MeanIntensity',NaN ,'MaxIntensity',NaN );
                end
            end
            idx=arrayfun(@(x) isempty(x.MaxIntensity),MsrTemp);
            MsrTemp(idx)=struct('Area',0 ,'Eccentricity',0,'Perimeter',0,...
            'PixelValues',[],'MeanIntensity',NaN ,'MaxIntensity',NaN );
        end
       
        
    end
end
