clc;
clear;
clf;

vid = VideoReader("Ishii Lab Project Video 2025.mp4");
skipTime = 60;
vid.CurrentTime = skipTime; % skipping 

%% Constant for blob analysis
fishElem = strel('disk', 10); % TODO: Adjust value 
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
    inpainted = RemoveNet(preimage);
    %% Get fish
    [annotated,bw_inverted,removedDisturb,objCentroid] = extractFish(inpainted,fishElem,hBlobAnalysis,preimage);
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






