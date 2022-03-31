close all; clear all; path(pathdef); clc; warning off;
addpath(genpath('./library'));

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
numberOfImages = numel(inputImageNameList); %Returns the number of elements from Input Array

for i = 1:numberOfImages
  tempImageNameDir = split(inputImageNameList{i}, ".");
  mkdir([outputPath tempImageNameDir{1} '_Output'])
end

%% Algorithm

for i = 1:numberOfImages
  imageName = inputImageNameList{i};
  fprintf('\n\n---------------------------------------------------------------\n');
  disp(['Processing File #' num2str(i) ' ("' imageName '")' ' of selected #' num2str(numel(inputImageNameList))]);
  imgData = im2double(imread([inputImageDirectoryPath imageName]));
  [numberOfRows, numberOfColumns, ~] = size(imgData);

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%% Image Pre-processing %%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % Contrast Enhancement Image Intensity values | Saturating the upper 1% and the lower 1%.
  lowHigh = stretchlim(imgData);
  fprintf('\tContrast Streching Limits: [ Low: %0.2f High: %0.2f]\n', stretchlim(imgData));
  increasedContrastImgData = imadjust(imgData);
  inversedImageData = imcomplement(increasedContrastImgData); %Inverse Contrast Streched Input Image

  %%% Removing Speckle Noise using Gaussian Smoothing Filter
  preprocessedImageData = imgaussfilt(inversedImageData); %Gaussian Low Pass Filter

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

end
