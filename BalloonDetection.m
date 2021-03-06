function [ mean_x, mean_y ] = BalloonDetection( im, x, y, rotation, index  )
%BalloonDetection Detects round shaped balloons in an image frame

%   Detailed explanation goes here
global tracker;
h = fspecial('gaussian',[5,5],5);
mean_x = 0;
mean_y = 0;
colors = [];
im_hsv = rgb2hsv(im);
im_s = im_hsv(:,:,2);
im_s = imfilter(im_s,h);
[centers, ~] = imfindcircles(im_s,[20,50],'ObjectPolarity','bright', 'Method', 'TwoStage', 'Sensitivity', 0.55);
[r, c, ~] = size(im);

if ~isempty(centers)
    [rows, ~] = size(centers);
    temp_centers1 = (centers(:,1) - c/2);
    temp_centers2 = (r/2 - centers(:,2));
    centers_world_x = temp_centers1 .* cos(rotation(index)) - temp_centers2 .* sin(rotation(index)) + ones(rows,1) * x(index); % convert to world frame
    centers_world_y = temp_centers1 .* sin(rotation(index)) + temp_centers2 .* cos(rotation(index)) + ones(rows,1) * y(index);
    centers_world = cat(2,centers_world_x, centers_world_y);

    if(isempty(tracker)) % Tracker is not empty, go through and try to assign
        tracker = centers_world;
        colors(1,:) = get_roi(im, centers + [20,0], 2);
        tracker = cat(2, tracker, colors.*255);
    else
            % Tracker is not empty (after the first iteration)
            temp_colors = get_roi(im, centers, 10);
            temp = cat(1, tracker, cat(2, centers_world, temp_colors.*255)); % concatenate
            est_dist = squareform(pdist(temp)); % calculate distance matrix
            inf_diag =  diag(inf* ones(length(est_dist),1)); % Assign inf to diagonal
            est_dist = est_dist + inf_diag;
            sc = size(centers_world,1);      st = size(tracker,1);
            est_dist = est_dist(end-sc+1:end, 1:end-sc);
            
            for F = 1 : size(est_dist,1)
                low_value = min(est_dist(F,:));
                [~, low_index] = find(est_dist == low_value);
                if low_value < 300 % This is an already tracked balloon
                    %mean_x = cat(1, mean_x, (centers_world(F,1) -  tracker(low_index,1)));
                    %mean_y = cat(1, mean_y, (centers_world(F,2) -  tracker(low_index,2)));
                    mean_x  = (centers_world(F,1) -  tracker(low_index,1));
                    mean_y  = (centers_world(F,2) -  tracker(low_index,2));
                    tracker(low_index,1:2) = (centers_world(F,:));
                else
                    tracker = cat(1, tracker, temp(F+st,:));
                    % Getting colors
                    cc_temp =  im(round(centers(1,2)), round(centers(1,1)),:);
                    cc = cc_temp(1,1:3);
                    colors = cat(1, colors, cc);
                    colors = cat(1, colors, get_roi(im, centers(F,:),10));
                end
            end

            
    end
end

