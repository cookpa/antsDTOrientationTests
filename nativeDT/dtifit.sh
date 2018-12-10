#!/bin/bash

for series in axis ortho pitch roll yaw; do 

  mkdir fsl/$series

  dtifit -k ../nii/${series}/${series}.nii.gz -o fsl/${series}/${series} -m ../nii/${series}/${series}_mean_b0_brain_mask.nii.gz -r ../nii/${series}/${series}.bvec -b ../nii/${series}/${series}.bval --save_tensor

done
