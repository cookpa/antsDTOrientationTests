#!/bin/bash

for series in axis ortho pitch roll yaw; do

  tmpDir=ants/${series}/tmp

  mkdir -p $tmpDir

  ImageMath 3 ants/${series}/${series}_DT.nii.gz FSLTensorToITK fsl/${series}/${series}_tensor.nii.gz
  ImageMath 3 ants/${series}/${series}_FA.nii.gz TensorFA ants/${series}/${series}_DT.nii.gz
  ImageMath 3 ants/${series}/${series}_MD.nii.gz TensorMeanDiffusion ants/${series}/${series}_DT.nii.gz
  ImageMath 3 ants/${series}/${series}_RGB.nii.gz TensorColor ants/${series}/${series}_DT.nii.gz

  # fsleyes requires vectors to be 4D
  ImageMath 3 ${tmpDir}/${series}_V1.nii.gz TensorToVector ants/${series}/${series}_DT.nii.gz 2

  for (( i=0; i < 3; i++ )); do
    ImageMath 3 ${tmpDir}/${series}_V1_${i}.nii.gz ExtractVectorComponent ${tmpDir}/${series}_V1.nii.gz $i
  done

  ImageMath 4 ants/${series}/${series}_V1.nii.gz TimeSeriesAssemble 1 0 ${tmpDir}/${series}_V1_0.nii.gz ${tmpDir}/${series}_V1_1.nii.gz ${tmpDir}/${series}_V1_2.nii.gz

  rm ${tmpDir}/*
  rmdir ${tmpDir}

done
