% read data
T = readtable('fish_activity_stats.csv');

frameRate = 15;  
window_sec = 15;
window_size = window_sec * frameRate;

total_frames = height(T);
num_windows = floor(total_frames / window_size);

% begin
avg_area = zeros(num_windows, 1);
avg_count = zeros(num_windows, 1);
labels = strings(num_windows, 1);

% average
for i = 1:num_windows
    idx_start = (i-1)*window_size + 1;
    idx_end = i*window_size;
    
    segment = T(idx_start:idx_end, :);
    avg_area(i) = mean(segment.WhitePixelArea);
    avg_count(i) = mean(segment.FishCount);
    labels(i) = sprintf('%.0f~%.0fs', (i-1)*window_sec, i*window_sec);
end

% fig
figure('Name',' Segment-wise average fish school behavior analysis','Color','w');

% activityy fig
subplot(2,1,1);
bar(avg_area, 'FaceColor', [0.2 0.6 1]);
title('Average fish activity every 15 seconds');
ylabel('White pixel area');
set(gca, 'XTick', 1:num_windows, 'XTickLabel', labels, 'XTickLabelRotation', 45);
grid on;

% number of fish fig
subplot(2,1,2);
bar(avg_count, 'FaceColor', [1 0.4 0.4]);
title('Average number of fish per 15 seconds');
ylabel('Number of connected regions (fish population estimate）');
set(gca, 'XTick', 1:num_windows, 'XTickLabel', labels, 'XTickLabelRotation', 45);
xlabel('Time period (seconds)');
grid on;
saveas(gcf, 'fish_segment_analysis.png');  