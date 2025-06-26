clc; clear;

inputVideo = 'input_video.mp4'; 
videoReader = VideoReader(inputVideo);
frameRate = videoReader.FrameRate;

videoWriter = VideoWriter('fish_mask_binary_output.mp4', 'MPEG-4');
videoWriter.FrameRate = frameRate;
open(videoWriter);

totalFrames = floor(videoReader.Duration * frameRate);
h = waitbar(0, 'read');
frameCount = 0;

while hasFrame(videoReader)
    frame = readFrame(videoReader);

    % CLAHE ENHANCEMENT
    lab = rgb2lab(frame);
    L = lab(:,:,1) / 100;
    L = adapthisteq(L);
    lab(:,:,1) = L * 100;
    enhanced = lab2rgb(lab);
    enhanced = im2uint8(enhanced);

    % Convert to grayscale
    gray = rgb2gray(enhanced);

    % Gamma enhancement to improve contrast
    gamma_corrected = imadjust(gray, [], [], 0.7);  % gamma < 1 

    %Inverted image: fish becomes white, background becomes black
    gray_inverted = imcomplement(gamma_corrected);

    % Binarization, extracting fish outline
    bw = imbinarize(gray_inverted, 'adaptive', 'Sensitivity', 0.5);
    bw = bwareaopen(bw, 150);  % Remove small noise areas
    bw = imclose(bw, strel('disk', 3));  % Connect the broken parts

    % Optional display of debugging effects
    % imshow(bw); title(sprintf('Frame %d', frameCount));

    % Convert to 3-channel image for saving video
    mask3ch = uint8(cat(3, bw, bw, bw) * 255);

    % FRAME READ
    writeVideo(videoWriter, mask3ch);
    frameCount = frameCount + 1;
    waitbar(frameCount / totalFrames, h);
end

close(videoWriter);
close(h);
disp('FINSHED');
