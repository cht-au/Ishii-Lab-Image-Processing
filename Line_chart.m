clc; clear;

inputVideo = 'fish_mask_binary_output.mp4';  
videoReader = VideoReader(inputVideo);
frameRate = videoReader.FrameRate;
totalFrames = floor(videoReader.Duration * frameRate);

area_list = zeros(totalFrames, 1);
count_list = zeros(totalFrames, 1);

h = waitbar(0, ' Counting fish activity per frame...');
frameCount = 0;

while hasFrame(videoReader)
    frame = readFrame(videoReader);
    bw = im2bw(frame, 0.5);  % Convert the video frame back to a binary image (255 to 1)

    % Area Statistics
    area_list(frameCount+1) = sum(bw(:));  % Total number of white pixels (fish area）

    % Quantity Statistics
    labeled = bwlabel(bw);
    count_list(frameCount+1) = max(labeled(:));  % Number of connected regions

    frameCount = frameCount + 1;
    waitbar(frameCount / totalFrames, h);
end

close(h);

T = table((1:frameCount)', area_list(1:frameCount), count_list(1:frameCount), ...
    'VariableNames', {'Frame', 'WhitePixelArea', 'FishCount'});
writetable(T, 'fish_activity_stats.csv');

% Read statistics results
T = readtable('fish_activity_stats.csv');

figure('Name','Fish activity and quantity statistics','NumberTitle','off','Color','w');

% Sub-image 1: White area (fish activity)
subplot(2,1,1);
plot(T.Frame, T.WhitePixelArea, '-o', 'Color', [0.2 0.6 1.0], 'LineWidth', 1.5);
title(' Fish activity (white pixel area)', 'FontSize', 14);
xlabel('Frame number'); ylabel('Number of white pixels');
grid on;

% Sub-graph 2: Number of connected regions (fish population estimation)
subplot(2,1,2);
plot(T.Frame, T.FishCount, '-s', 'Color', [1.0 0.4 0.4], 'LineWidth', 1.5);
title('Fish population estimation (number of connected regions)', 'FontSize', 14);
xlabel('Frame number'); ylabel('Number of fish');
grid on;
%smoothize the fig
T = readtable('fish_activity_stats.csv');

windowSize = 10;

smooth_area = movmean(T.WhitePixelArea, windowSize);
smooth_count = movmean(T.FishCount, windowSize);

figure('Name',' Fish trend (moving average)','Color','w');

subplot(2,1,1);
plot(T.Frame, smooth_area, '-','LineWidth',2,'Color',[0.1 0.5 1]);
title('Fish activity (moving average)'); ylabel('White pixel area'); grid on;

subplot(2,1,2);
plot(T.Frame, smooth_count, '-','LineWidth',2,'Color',[1 0.4 0.4]);
title('Fish population estimates (moving average)'); xlabel('Frame number'); ylabel('number'); grid on;

saveas(gcf, 'fish_activity_plot.png');