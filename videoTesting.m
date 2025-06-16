clc;
clear;


vid = VideoReader("Ishii Lab Project Video 2025.mp4");
vid.CurrentTime = 60; % skipping 
while hasFrame(vid)
    frame = readFrame(vid);
    %% Image Pre-Processing 
    I = frame;
    I2 = imcrop(imrotate(I, 270),[0 200 800 1100]);
    I2 = imreducehaze(I2);
    %I2 = imcrop(I,[100 100 1400 1500]);
    I3 = rgb2gray(I2);
    I4 = imadjust(I3);
    I5 = im2uint8(I4);
    I6 = adapthisteq(I5);
    I7 = imsharpen(I6);
    %% Net Removal
    edges = edge(I7, 'Canny');
    strelLength = 11;
    se1 = strel('line', strelLength, 90);
    se2 = strel('line', strelLength, 0);
    se3 = strel('line', strelLength, 45);
    se4 = strel('line', strelLength, 135);
    netMask = imdilate(edges, se1) | imdilate(edges, se2) | imdilate(edges, se3) | imdilate(edges, se4);
    inpainted = regionfill(I7, netMask);
    %% Readjustment
    %inpainted = imadjust(inpainted);
    inpainted = imsharpen(inpainted); % might be unnesscary
    %% Thresholding
    bw = imbinarize(inpainted,"adaptive","Sensitivity",0.80);
    bw_inverted = ~bw;
    %% Remove disturbances - 
    fishElem = strel('diamond', 4); % TODO: Adjust value 
    Ibwopen = imopen(bw_inverted,fishElem);
    %% Blob Analysis
    hBlobAnalysis = vision.BlobAnalysis('MinimumBlobArea',4300,...
        'MaximumBlobArea',60000); % TODO: Adjust value
    [objArea, objCentroid, bboxOut] = step(hBlobAnalysis,Ibwopen);
    %% Annotate
    Ishape = insertShape(I7,'rectangle',bboxOut,'Linewidth',4);
    %% Display
    set(gcf, 'Position', get(0, 'Screensize'));

    figure(1)    
    tiledlayout(2,2,"TileSpacing","none");
    
    nexttile;
    imshow(Ishape);
    title('Annotated Frame');

    
    nexttile;
    imshow(bw_inverted);
    title('After Thresholding');
    

    nexttile;
    imshow(inpainted);
    title('Net Removal');
    

end


