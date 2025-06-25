clc;
clear;

%% Image Preprocessing
I = imread('fish.png');
I2 = imrotate(I, 270);
I2 = imcrop(I2,[0 138.5 824 1422]);
% Original cropping
% I2 = imcrop(I,[100 100 1400 1500]);
I3 = rgb2gray(I2);
I4 = imadjust(I3);
I5 = im2uint8(I4);
I6 = adapthisteq(I5);
I7 = imsharpen(I6);
I8 = medfilt2(I7);
edges = edge(I8, 'Canny');

%% Net Removal
strelLength = 11;
se1 = strel('line', strelLength, 90);
se2 = strel('line', strelLength, 0);
se3 = strel('line', strelLength, 45);
se4 = strel('line', strelLength, 135);
netMask = imdilate(edges, se1) | imdilate(edges, se2) | imdilate(edges, se3) | imdilate(edges, se4);
inpainted = regionfill(I2, netMask); 

imshow(inpainted)
% %% Thresholding
% sharpIn = imsharpen(inpainted); % TODO: Might be better to enhace image further
% % or remove it if it is better
% bw = imbinarize(sharpIn,"adaptive","Sensitivity",0.70); 
% bw_inverted = ~bw;
% imshow(bw_inverted)

% %% Remove disturbances
% fishElem = strel('diamond', 10);
% Ibwopen = imopen(bw_inverted,fishElem);
% %% Blob Analysis
% hBlobAnalysis = vision.BlobAnalysis('MinimumBlobArea',4000,...
%     'MaximumBlobArea',10000);
% [objArea, objCentroid, bboxOut] = step(hBlobAnalysis,Ibwopen);
% %% Annotate
% Ishape = insertShape(I2,'rectangle',bboxOut,'Linewidth',4);
% imshow(Ishape)