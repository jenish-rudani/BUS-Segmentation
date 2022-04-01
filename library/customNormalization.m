function NormalizedImageData = customNormalization(inputImageData)
  %normalization - Description
  %
  % Syntax: NormalizedImageData = normalization(inputImageData)
  %
  % This funtion performs normalization: ( I - min(I) ) / ( max(I) )

  tempVar = inputImageData - min(inputImageData(:));
  NormalizedImageData = tempVar / (max(inputImageData(:)) - min(inputImageData(:)));

end
