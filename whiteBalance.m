clear all 
clc
% Read and normalize the image
I = im2double(imread('fishSample.png'));
I=imrotate(I,-90);

% White balance (gray world)
avg = mean(reshape(I, [], 3), 1);
gray = mean(avg);
I(:,:,1) = I(:,:,1) * (gray / avg(1));  % Red channel
I(:,:,2) = I(:,:,2) * (gray / avg(2));  % Green channel
I(:,:,3) = I(:,:,3) * (gray / avg(3));  % Blue channel
I = min(I, 1);  % Clip values

% Contrast enhancement using histogram equalization
for c = 1:3
    I(:,:,c)=adapthisteq(I(:,:,c),'ClipLimit',0.005);
end

% Gamma correction (brighten)
I = I .^0.8;

% Slight sharpening
%I = imsharpen(I,'Radius',1,'Amount', 0.8);

% Display original and enhanced side by side
imshowpair(imrotate(imread('fishSample.png'),-90), I, 'montage');
 title('Original (Left) vs Enhanced (Right)');

I_gray = rgb2gray(I);
I4 = imadjust(I_gray);
I5 = im2uint8(I4);
I6 = adapthisteq(I5);
I7 = imsharpen(I6);
I8 = medfilt2(I7);


imshow(I_gray);
title('Enhanced Grayscale Image');
