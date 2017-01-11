%where in a cartridige are the scored events:
%first open a processed sample
%then display the opened 
[file,dir]=uigetfile('*.mat','Please select a ACCEPT cartridge result');
load(fullfile(dir,file));

locations=[];

for i=1:size(currentSample.priorLocations,1)
    locations(i,:)=IO.calculate_overview_location(currentSample,i);
end
figure
imshow(currentSample.overviewImage(:,:,2),parula(4000))
hold
scatter(locations(:,2),locations(:,1),'red')
hold off
