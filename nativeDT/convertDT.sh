#!/bin/bash

export ANTSPATH=/Users/pcook/bin/ants/bin/

for series in axis ortho pitch roll yaw; do 

  tmpDir=ants/${series}/tmp

  mkdir -p $tmpDir

  ${ANTSPATH}ImageMath 3 ${tmpDir}/${series}_dtUpper.nii.gz 4DTensorTo3DTensor fsl/${series}/${series}_tensor.nii.gz

  comps=(xx xy xz yy yz zz)

  for (( i=0; i < 6; i++ )); do
    ${ANTSPATH}ImageMath 3 ${tmpDir}/${series}_comp_d${comps[$i]}.nii.gz TensorToVectorComponent ${tmpDir}/${series}_dtUpper.nii.gz $((i+3))
  done

  ${ANTSPATH}ImageMath 3 ants/${series}/${series}_DT.nii.gz ComponentTo3DTensor ${tmpDir}/${series}_comp_d .nii.gz

  ${ANTSPATH}ImageMath 3 ants/${series}/${series}_FA.nii.gz TensorFA ants/${series}/${series}_DT.nii.gz
  ${ANTSPATH}ImageMath 3 ants/${series}/${series}_MD.nii.gz TensorMeanDiffusion ants/${series}/${series}_DT.nii.gz
  ${ANTSPATH}ImageMath 3 ants/${series}/${series}_RGB.nii.gz TensorColor ants/${series}/${series}_DT.nii.gz

  # fslview does not display NIFTI vectors correctly, requires 4D
  ${ANTSPATH}ImageMath 3 ${tmpDir}/${series}_V1.nii.gz TensorToVector ants/${series}/${series}_DT.nii.gz 2

  for (( i=0; i < 3; i++ )); do
    ${ANTSPATH}ImageMath 3 ${tmpDir}/${series}_V1_${i}.nii.gz ExtractVectorComponent ${tmpDir}/${series}_V1.nii.gz $i
  done

  ${ANTSPATH}ImageMath 4 ants/${series}/${series}_V1.nii.gz  TimeSeriesAssemble 1 0 ${tmpDir}/${series}_V1_0.nii.gz ${tmpDir}/${series}_V1_1.nii.gz ${tmpDir}/${series}_V1_2.nii.gz

  rm ${tmpDir}/*
  rmdir ${tmpDir}

done
