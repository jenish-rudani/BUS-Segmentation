close all; clear all; path(pathdef); clc; warning off;
addpath(genpath('./library'));
run('C:\Users\jruda\Documents\MATLAB\vlfeat-0.9.21\toolbox\vl_setup');

%% Define Variables and Clear Results Directory
method = 'Guassian_Normalized_Cut';
outputPath = './Results/';

if exist(outputPath, 'dir')
  fprintf('\n\n')
  disp("Deleting All Old Output Images from 'Results' Directory")
  rmdir(outputPath, 's');
end

mkdir(outputPath);

%% Get Input Image Files
[inputImageNameList, inputImageDirectoryPath, ~] = uigetfile('./data/input/*.png', 'Select Input BUS Images', 'MultiSelect', 'on');

if isa(inputImageNameList, 'cell')
  numberOfImages = numel(inputImageNameList); %Returns the number of elements from Input Array
else
  numberOfImages = 1;
end

for i = 1:numberOfImages
  try
    tempImageNameDir = split(inputImageNameList{i}, ".");
  catch exception
    tempImageNameDir = split(inputImageNameList, ".");
  end
  mkdir([outputPath tempImageNameDir{1} '_Output'])
end

%% Algorithm

for i = 1:numberOfImages
  try
    imageName = inputImageNameList{i};
  catch exception
    imageName = inputImageNameList;
  end
  
  fprintf('\n\n---------------------------------------------------------------\n');
  disp(['Processing File #' num2str(i) ' ("' imageName '")' ' of selected #' num2str(numberOfImages)]);
  imgData = im2double(imread([inputImageDirectoryPath imageName]));
  [numberOfRows, numberOfColumns, ~] = size(imgData);

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%% Image Pre-processing %%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  %! Contrast Enhancement and Gaussian filtering of Image.
  lowHigh = stretchlim(imgData);
  fprintf('\tContrast Streching Limits: [ Low: %0.2f High: %0.2f]\n', stretchlim(imgData));
  increasedContrastImgData = imadjust(imgData);
  inversedImageData = imcomplement(increasedContrastImgData); % Inverse Contrast Streched Input Image
  preprocessedImageData = imgaussfilt(inversedImageData); % Removing Speckle Noise using Gaussian Smoothing Filter

  figure;
  subplot(2, 2, 1); imshow(imgData); title('\fontsize{6} \color{gray} {Input BUS Image}')
  subplot(2, 2, 2); imshow(increasedContrastImgData); title("\fontsize{6} \color{gray} {Contrast Streched Image (lowIn = " + num2str(lowHigh(1)) + ") (highIn = " + num2str(lowHigh(2)) + ")}")
  subplot(2, 2, 3); imshow(inversedImageData); title("\fontsize{6} \color{gray} {Inversed Higher Contrast Image}");
  subplot(2, 2, 4); imshow(preprocessedImageData); title("\fontsize{6} \color{gray} {Filtered Image (Gaussian Low-Pass Filter Fitlers Speckle)}")
  tempImageNameDir = split(imageName, ".");
  saveas(gcf, [outputPath tempImageNameDir{1} '_Output' '/Preprocessing_Plot.png']);
  fprintf('\tCompleted Pre Processing: ( "%s" )\n---------------------------------------------------------------\n\n', imageName);

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%% Image Segmentation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  normalizedImageData = normalization(preprocessedImageData);
  normalizedImageData = double(normalizedImageData >= 0.8);

  clearBorderImageData = imclearborder(normalizedImageData);
  reconstructedImage = imfill(clearBorderImageData, 'holes');

  figure;
  subplot(2, 2, 1); imshow(preprocessedImageData); title('\fontsize{6} \color{gray} {Filtered Image from previous stage}')
  subplot(2, 2, 2); imshow(normalizedImageData); title("\fontsize{6} \color{gray} {Normalized Image}")
  subplot(2, 2, 3); imshow(clearBorderImageData); title("\fontsize{6} \color{gray} {Bordere Cleared}");
  subplot(2, 2, 4); imshow(reconstructedImage); title("\fontsize{6} \color{gray} {Reconstructed Image}")
  saveas(gcf, [outputPath tempImageNameDir{1} '_Output' '/Segmentation_Plot.png']);
  
  ratio = 0.8;
  kernelsize = 5;
  maxdist = 20;
  qsSegmentedImage = vl_quickseg(reconstructedImage, ratio, kernelsize, maxdist);

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%% Postprocessing %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  %-Convert segemented (gray-scale) image into binary image by one-point
  %-thresholding using some scalar value after unit normalization
  normalizedSegmentedImage = normalization(qsSegmentedImage);
  normalizedSegmentedImage = double(normalizedSegmentedImage >= 0.8);

  %-Remove boundary regions
  suppressedSegmentedImage = imclearborder(normalizedSegmentedImage);

  %-Select region with largest area
  stat = regionprops(suppressedSegmentedImage , 'Area', 'PixelIdxList');
  [~, indMax] = max([stat.Area]);
  normalizedSegmentedImage2 = false(size(suppressedSegmentedImage ));

  if (~isempty(indMax))
    normalizedSegmentedImage2(stat(indMax).PixelIdxList) = 1;
  end
  
  figure;
  subplot(2, 2, 1); imshow(qsSegmentedImage); title('\fontsize{6} \color{gray} {Quick Shift Segmented Image}')
  subplot(2, 2, 2); imshow(normalizedSegmentedImage); title("\fontsize{6} \color{gray} {Segmented Image after Normalization and Threshold (0.8)}")
  subplot(2, 2, 3); imshow(suppressedSegmentedImage); title("\fontsize{6} \color{gray} {Suppressed Border Image (8-Connectivity)}");
  subplot(2, 2, 4); imshow(normalizedSegmentedImage2); title("\fontsize{6} \color{gray} {Output Segment}")
end
