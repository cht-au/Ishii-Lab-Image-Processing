clc;
clear;


img = imread('fish.png');
img = imrotate(img, 270);
img = imcrop(img,[0 200 825 1200]);

I2 = rgb2gray(img);
I3 = imadjust(I2);
I4 = im2uint8(I3);
I5 = adapthisteq(I4);
I6 = imsharpen(I5);

%% Net Removal
edges = edge(I6, 'Canny');
strelLength = 11;
se1 = strel('line', strelLength, 90);
se2 = strel('line', strelLength, 0);
se3 = strel('line', strelLength, 45);
se4 = strel('line', strelLength, 135);
netMask = imdilate(edges, se1) | imdilate(edges, se2) | imdilate(edges, se3) | imdilate(edges, se4);
inpainted = regionfill(I6, netMask);

%% Re Adjusted
I7 = imsharpen(inpainted);

bw = imbinarize(I7,"adaptive","Sensitivity",0.80);
bw2 = imbinarize(inpainted,"adaptive","Sensitivity",0.70);
figure(1)
imshowpair(bw,bw2,'montage');

figure(2)
imshowpair(inpainted,I7,'montage');

