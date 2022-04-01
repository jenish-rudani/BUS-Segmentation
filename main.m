close all; clear all; path(pathdef); clc; warning off;
addpath(genpath('./library'));
run('.\library\vlfeat-0.9.21\toolbox\vl_setup');

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
[inputGTNameList, inputGTDirectoryPath, ~] = uigetfile('./data/GT/*.png', 'Select Corresponding Ground Truth Images', 'MultiSelect', 'on');

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
    gtName = inputGTNameList{i};
  catch exception
    imageName = inputImageNameList;
    gtName = inputGTNameList;
  end
  
  fprintf('\n\n---------------------------------------------------------------\n');
  disp(['Processing File #' num2str(i) ' ("' imageName '")' ' of selected #' num2str(numberOfImages)]);

  imgData = im2double(imread([inputImageDirectoryPath imageName]));
  gtData = im2double(imread([inputGTDirectoryPath gtName]));
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

  normalizedImageData = customNormalization(preprocessedImageData);
  normalizedImageData = double(normalizedImageData >= 0.8);

  clearBorderImageData = imclearborder(normalizedImageData);
  reconstructedImage = imfill(clearBorderImageData, 'holes');

  figure;
  subplot(2, 2, 1); imshow(preprocessedImageData); title('\fontsize{6} \color{gray} {Filtered Image from previous stage}')
  subplot(2, 2, 2); imshow(normalizedImageData); title("\fontsize{6} \color{gray} {Normalized Image}")
  subplot(2, 2, 3); imshow(clearBorderImageData); title("\fontsize{6} \color{gray} {Bordere Cleared}");
  subplot(2, 2, 4); imshow(reconstructedImage); title("\fontsize{6} \color{gray} {Reconstructed Image}")
  saveas(gcf, [outputPath tempImageNameDir{1} '_Output' '/Segmentation_Plot.png']);
  
  ratio = 0.01;
  kernelsize = 5;
  maxdist = 5;
  qsSegmentedImage = vl_quickseg(reconstructedImage, ratio, kernelsize, maxdist);

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%% Postprocessing %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  normalizedSegmentedImage = customNormalization(qsSegmentedImage); %Thresholding using some scalar value after unit normalization
  normalizedSegmentedImage = double(normalizedSegmentedImage >= 0.8);
  
  figure;
  subplot(2, 1, 1); imshow(qsSegmentedImage); title('\fontsize{6} \color{gray} {Quick Shift Segmented Image}')
  subplot(2, 1, 2); imshow(normalizedSegmentedImage); title("\fontsize{6} \color{gray} {Segmented Image after Normalization and Threshold (0.8)}")
  saveas(gcf, [outputPath tempImageNameDir{1} '_Output' '/PostProcessing_Plot.png']);
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%% Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  ssm = imgData .* normalizedSegmentedImage;
  ssm = ssm + ~normalizedSegmentedImage;
  
  gtLesion = imgData .* gtData;
  gtLesion = gtLesion + ~gtData;

  figure;
  subplot(2, 1, 1); imshow(ssm); title("\fontsize{6} \color{gray} {Segmented Lesion Produced by Algorithm}")
  subplot(2, 1, 2); imshow(gtLesion); title('\fontsize{6} \color{gray} {Segmeted Lesion using Provided GT}')
  saveas(gcf, [outputPath tempImageNameDir{1} '_Output' '/Result_Comparison_Plot.png']);
end
