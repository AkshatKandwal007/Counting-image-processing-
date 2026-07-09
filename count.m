% Stone Counter - Aggressive Separation for Tightly Packed Stones
% Optimized for high-density stone images

img = imread('/MATLAB Drive/Counting/stones.png');
figure; imshow(img); title('Original Image');

% Convert to grayscale
gray = rgb2gray(img);
figure; imshow(gray); title('Grayscale Image');

% Apply stronger smoothing to reduce stone texture
blurred = imgaussfilt(gray, 3);
figure; imshow(blurred); title('Smoothed Image (Higher Blur)');

% Enhance contrast using adaptive histogram equalization
enhanced = adapthisteq(blurred);
figure; imshow(enhanced); title('Contrast Enhanced');

% Use adaptive thresholding instead of global threshold
% This handles varying lighting across the image better
bw = imbinarize(enhanced, 'adaptive', 'ForegroundPolarity', 'dark', 'Sensitivity', 0.35);
figure; imshow(bw); title('Adaptive Binary - Stones in White');

% Clean up
bw = imfill(bw, 'holes');
bw = bwareaopen(bw, 600);  % Lower threshold to catch smaller stones
figure; imshow(bw); title('Cleaned Binary Image');

% CRITICAL: More aggressive erosion to separate touching stones
% This is the key to detecting individual stones instead of clumps
bw_eroded = imerode(bw, strel('disk', 4));  % Stronger erosion
figure; imshow(bw_eroded); title('Aggressively Eroded - Separates Stones');

% Distance transform on the ORIGINAL cleaned binary (not eroded)
D = bwdist(~bw);
figure; imshow(D, []); title('Distance Transform');

% Use the eroded image to find seed points (stone centers)
% This prevents over-segmentation
D = -D;
D(~bw_eroded) = Inf;  % Only look at eroded regions for centers
D2 = imimposemin(D, bw_eroded);
figure; imshow(D2, []); title('Imposed Minima from Eroded Stones');

% Apply watershed on original binary using eroded seeds
Ld = watershed(D2);
bw_final = bw;
bw_final(Ld == 0) = 0;  % Mark boundaries
figure; imshow(bw_final); title('Watershed Applied');

% Remove very small fragments
bw_final = bwareaopen(bw_final, 400);
figure; imshow(bw_final); title('Final Segmentation');

% Count stones
[labeled, numStones] = bwlabel(bw_final);

fprintf('\n');
fprintf('═══════════════════════════════════════════\n');
fprintf('   TOTAL STONES DETECTED: %d\n', numStones);
fprintf('═══════════════════════════════════════════\n\n');

% Visualize boundaries
boundaries = bwboundaries(bw_final);
figure; imshow(img); hold on;
for k = 1:length(boundaries)
    boundary = boundaries{k};
    plot(boundary(:,2), boundary(:,1), 'r', 'LineWidth', 1.5);
end
hold off; 
title(sprintf('Detected Boundaries - %d Stones', numStones));

% Color-coded visualization
figure; imshow(label2rgb(labeled, 'jet', 'k', 'shuffle')); 
title(sprintf('Color-Coded Detection - %d Stones', numStones));

% Numbered stones
stats = regionprops(bw_final, 'Centroid', 'Area', 'Perimeter');
figure; imshow(img); hold on;
displayCount = min(150, numStones);
for i = 1:displayCount
    centroid = stats(i).Centroid;
    text(centroid(1), centroid(2), num2str(i), ...
        'Color', 'yellow', 'FontSize', 7, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center', 'BackgroundColor', [0 0 0 0.6]);
end
hold off; 
title(sprintf('Numbered Stones (Showing %d of %d)', displayCount, numStones));

% Statistics
areas = [stats.Area];
fprintf('Stone Measurements:\n');
fprintf('  Average area: %.1f px²\n', mean(areas));
fprintf('  Std deviation: %.1f px²\n', std(areas));
fprintf('  Largest: %.1f px²\n', max(areas));
fprintf('  Smallest: %.1f px²\n', min(areas));

fprintf('\n═══════════════════════════════════════════\n');
fprintf('TUNING TIPS:\n');
fprintf('═══════════════════════════════════════════\n');
fprintf('If detecting too FEW stones:\n');
fprintf('  → Line 27: Increase erosion disk size (try 5 or 6)\n');
fprintf('  → Line 21: Lower min size (try 400)\n\n');
fprintf('If detecting too MANY (over-segmentation):\n');
fprintf('  → Line 27: Decrease erosion (try 3)\n');
fprintf('  → Line 21: Increase min size (try 800)\n');
fprintf('═══════════════════════════════════════════\n');
