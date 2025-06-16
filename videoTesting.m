clc;
clear;

vid = VideoReader("Ishii Lab Project Video 2025.mp4");
vid.CurrentTime = 60; % skipping 
fishElem = strel('disk', 9); % TODO: Adjust value 
hBlobAnalysis = vision.BlobAnalysis('MinimumBlobArea',3500,...
        'MaximumBlobArea',60000);

while hasFrame(vid)
    frame = readFrame(vid);
    frame = imrotate(frame, 270);
    frame = imcrop(frame,[0 200 825 1200]);
    %% Displaying 
    set(gcf, 'Position', get(0, 'Screensize'));
    figure(1)    
    tiledlayout(1,4,"TileSpacing","none");   
    %% Image Pre-Processing 
    preimage = Preprocess(frame);
    inpainted = RemoveNet(preimage);
    %% Get fish
    [annotated,bw_inverted,removedDisturb] = extractFish(inpainted,fishElem,hBlobAnalysis,preimage);
    %% Displaying

    nexttile
    imshow(annotated);

     nexttile
    imshow(bw_inverted);

    nexttile
    imshow(removedDisturb);
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

function result = Preprocess(img)
    %Original cropping
    I2 = imcrop(img,[100 100 1400 1500]);
    %Modified cropping + rotated
    %I2 = imcrop(imrotate(I, 270),[0 200 825 1200]);
    I3 = rgb2gray(I2);
    I4 = imadjust(I3);
    I5 = im2uint8(I4);
    I6 = adapthisteq(I5);
    result = imsharpen(I6);
end

function [annotated,bw_inverted,Ibwopen] = extractFish(inpainted,fishElem,hBlobAnalysis,originalPic)
    image = inpainted;
    %image = imsharpen(inpainted); % TODO: might be unnesscary
    % Thresholding
    bw = imbinarize(image,"adaptive","Sensitivity",0.65);
    bw_inverted = ~bw;
    % Remove disturbances
    Ibwopen = imopen(bw_inverted,fishElem);
    % Blob Analysis
    [objArea, objCentroid, bboxOut] = step(hBlobAnalysis,Ibwopen);
    % Annotate
    annotated = insertShape(originalPic,'rectangle',bboxOut,'Linewidth',4);
end






