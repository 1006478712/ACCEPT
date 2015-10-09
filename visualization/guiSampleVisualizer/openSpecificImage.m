function openSpecificImage(handles)
    type = get(gcf,'SelectionType');
    switch type
        case 'open' % double-click
            im = get( gcbo,'cdata' );
            % if you have "imtool" it's nicer to open the image in it...
%             imtool(im, [min(im(:)) max(im(:))] );
            figure; imagesc(im); colorbar; colormap(gray); axis equal; axis off;
        case 'normal'   
            %left mouse button action
            %get(gcbo)
            set(gcbo,'Selected','on');
        case 'extend'
            % shift & left mouse button action
        case 'alt'
            % alt & left mouse button action
    end
end