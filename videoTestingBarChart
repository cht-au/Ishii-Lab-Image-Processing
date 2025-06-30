clc;
clear;
clf;

avgSpeedsPerFrame = [];
frameTimes = [];
vid = VideoReader("Ishii Lab Project Video 2025.mp4");
skipTime = 60;
vid.CurrentTime = skipTime; % skipping 

%% Constant for blob analysis
fishElem = strel('diamond', 10); % TODO: Adjust value 
hBlobAnalysis = vision.BlobAnalysis('MinimumBlobArea',3500,...
        'MaximumBlobArea',18000); % TODO: Adjust value

% each row: [ID, x,y,vx, vy, frames]
knownFish = []; 
nextFishID = 1;
maxDist = 125;
maxPredictionError = 100; 
savedFish = [];
while vid.CurrentTime < skipTime + 0.75
    frame = readFrame(vid);
    frame = imrotate(frame, 270);
    frame = imcrop(frame,[0 160 824 1422]);
    %% Displaying 
    set(gcf, 'Position', get(0, 'Screensize'));
    figure(1)    
    tiledlayout(1,3);   
    %% Image Pre-Processing 
    preimage = Preprocess(frame);
    enimage = enhanceFishImage(frame);
    inpainted = RemoveNet(preimage);
    %% Get fish
    [annotated,bw_inverted,removedDisturb,objCentroid] = extractFish(inpainted,fishElem,hBlobAnalysis,enimage);
    %% Keeping track of fishes
    updatedFish = []; %[ID, x, y, vx, vy]
    % loop through the seen fish in the current frame
    for i = 1:size(objCentroid, 1)
        currCentroid = objCentroid(i,:); % [x, y]
        matched = false;
        % loop through current known fish
        for j = 1:size(knownFish,1)
            % if the fish is already matched
            if knownFish(j,1) == -1
                continue;
            end
            prevCentroid = knownFish(j,2:3); % current KNOWN fish 
            velocity = knownFish(j,4:5);
            hasVelocity = any(velocity);
            dist = norm(currCentroid - prevCentroid);
    
            if hasVelocity
                predictedPos = prevCentroid + velocity;
                predictedDist = norm(predictedPos - currCentroid);
                if predictedDist < maxPredictionError
                    matched = true;
                end
            elseif dist < maxDist
                matched = true;
            end

            if matched
                % calculate velocity
                vx = currCentroid(1) - prevCentroid(1);
                vy = currCentroid(2) - prevCentroid(2);
                % add the matched fish to the list with new velocities and
                % coordinates
                updatedFish(end+1,:) = [knownFish(j,1), currCentroid, vx, vy,knownFish(j,6)+1];
                % marking the fish invalid
                knownFish(j,1) = -1;
                break;
            end
        end
    
        if ~matched
            updatedFish(end+1,:) = [nextFishID, currCentroid, 0, 0,1];
            nextFishID = nextFishID + 1;
        end
    end
    knownFish = updatedFish;
    [avgSpeedsPerFrame, frameTimes] = trackAverageSpeed(knownFish, vid.CurrentTime, avgSpeedsPerFrame, frameTimes);
    for k = 1:size(knownFish,1)
        speed = norm(knownFish(k,4:5));
        id = knownFish(k,1);
        frames = knownFish(k,6);
        txt = sprintf('%d,%d',id,frames);
        if frames >= 3
            annotated = insertText(annotated, knownFish(k,2:3), txt,FontSize=38,FontColor="red");
            savedFish(end+1,:) = id;
        else
            annotated = insertText(annotated, knownFish(k,2:3), txt,FontSize=38);
        end
        %baseFileName =sprintf('frame_%04d.png',round(vid.CurrentTime * vid.FrameRate));
        %fullFileName = fullfile(cd,'image', baseFileName);  
        %imwrite(annotated, fullFileName);
    end
    %% Displaying
    nexttile
    imshow(bw_inverted);
    nexttile
    imshow(removedDisturb);
    nexttile
    imshow(annotated)
end
disp(unique(savedFish))
plotAverageSpeedPerFrame(frameTimes, avgSpeedsPerFrame);

function I8 = Preprocess(img)
    I3 = rgb2gray(img);
    I4 = imadjust(I3);
    I5 = im2uint8(I4);
    I6 = adapthisteq(I5);
    I7 = imsharpen(I6);
    I8 = medfilt2(I7);

end

function inpainted = RemoveNet(img)
    edges = edge(img, 'Canny');
    strelLength = 11;
    se1 = strel('line', strelLength, 90);
    se2 = strel('line', strelLength, 0);
    se3 = strel('line', strelLength, 45);
    se4 = strel('line', strelLength, 135);
    netMask = imdilate(edges, se1) | imdilate(edges, se2) | imdilate(edges, se3) | imdilate(edges, se4);
    inpainted = regionfill(img, netMask);
end

function [annotated,bw_inverted,Ibwopen,objCentroid] = extractFish(inpainted,fishElem,hBlobAnalysis,originalPic)
    image = inpainted;
    %image = imsharpen(inpainted); % TODO: might be unnesscary
    % Thresholding
    bw = imbinarize(image,"adaptive","Sensitivity",0.7);
    bw_inverted = ~bw;
    % Remove disturbances
    Ibwopen = imopen(bw_inverted,fishElem);
    % Blob Analysis
    [objArea, objCentroid, bboxOut] = step(hBlobAnalysis,Ibwopen);
    % Annotate
    annotated = insertShape(originalPic,'rectangle',bboxOut,'Linewidth',4);
end

function I_out = enhanceFishImage(I)
    % enhanceFishImage Enhances underwater or low-contrast images
    % Input: I - an RGB image
    % Output: I_out - enhanced RGB image

    % Ensure double precision in [0,1]
    I = im2double(I);

    % White balance 
    avg = mean(reshape(I, [], 3), 1);
    gray = mean(avg);
    I(:,:,1) = I(:,:,1) * (gray / avg(1));  
    I(:,:,2) = I(:,:,2) * (gray / avg(2));  
    I(:,:,3) = I(:,:,3) * (gray / avg(3));  
    I = min(I, 1);  

    % Contrast enhancement
    for c = 1:3
        I(:,:,c) = adapthisteq(I(:,:,c), 'ClipLimit', 0.007);
    end

    % Gamma correction
    I = I .^ 0.8;

    % Reduce haze and sharpen
    I = imreducehaze(I, 'Amount', 0.05);
    I = imsharpen(I, 'Radius', 1, 'Amount', 0.8);

    % Convert to LAB and enhance luminance
    I_lab = rgb2lab(I);
    L = I_lab(:,:,1) / 100;
    L = adapthisteq(L, 'ClipLimit', 0.005);
    I_lab(:,:,1) = L * 100;
    I_out = lab2rgb(I_lab);

    % Clip just in case
    I_out = max(min(I_out, 1), 0);
end

function [avgSpeedsPerFrame, frameTimes] = trackAverageSpeed(knownFish, frameTime, avgSpeedsPerFrame, frameTimes)
    speeds = vecnorm(knownFish(:,4:5), 2, 2);  % Compute speed for each fish (vector norm of vx, vy)
    if ~isempty(speeds)
        avgSpeed = mean(speeds);
    else
        avgSpeed = 0;  % No fish found in this frame
    end
    avgSpeedsPerFrame(end+1) = avgSpeed;
    frameTimes(end+1) = frameTime;
end

function plotAverageSpeedPerFrame(times, avgSpeeds)
    figure;
    bar(times, avgSpeeds); 
    xlabel('Video Time (s)');
    ylabel('Average Speed');
    title('Average Fish Speed Per Frame');
    grid on;
end
