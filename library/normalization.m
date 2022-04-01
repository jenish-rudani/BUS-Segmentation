function NormalizedImageData = normalization(inputImageData)
  %normalization - Description
  %
  % Syntax: NormalizedImageData = normalization(inputImageData)
  %
  % This funtion performs normalization: ( I - min(I) ) / ( max(I) )

  tempVar = inputImageData - min(inputImageData(:));
  NormalizedImageData = tempVar / max(tempVar(:));

end
