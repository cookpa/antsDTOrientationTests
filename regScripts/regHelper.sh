#!/bin/bash

function get4DV1() {

    # fslview does not display 5D NIFTI vectors correctly, requires 4D
    
    dt=$1
    output=$2
    
    tmpFileRoot=`basename ${dt%.nii.gz}`
    
    ${ANTSPATH}ImageMath 3 /tmp/${tmpFileRoot}V1.nii.gz TensorToVector $dt 2
    
    for (( i=0; i<3; i++ )); do
        ${ANTSPATH}ImageMath 3 /tmp/${tmpFileRoot}V1${i}.nii.gz ExtractVectorComponent /tmp/${tmpFileRoot}V1.nii.gz $i
    done
    
    ${ANTSPATH}ImageMath 4 ${output} TimeSeriesAssemble 1 0 /tmp/${tmpFileRoot}V10.nii.gz /tmp/${tmpFileRoot}V11.nii.gz /tmp/${tmpFileRoot}V12.nii.gz 
    
}

if [[ $# -eq 0 ]]; then
    echo " 
  $0 <moving> <moving DT> <fixed> <outputRoot> [initialTransform]

  The first moving image is the scalar image that is registered to the fixed image.
  The second one is the DT, which will be warped and reoriented.

  Uses ANTs with ANTSPATH=${ANTSPATH}

"

    exit 1

fi

moving=$1
movingDT=$2
fixed=$3
outputRoot=$4

initialTransformOpt=""

if [[ $# -gt 4 ]]; then
    initialTransform="-i $5"
fi

outputDir=`dirname $outputRoot`

if [[ ! -d $outputDir ]]; then
    mkdir -p ${outputDir}
fi



${ANTSPATH}antsRegistrationSyNQuick.sh -p f -f $fixed -m $moving -t r -o $outputRoot $initialTransformOpt

# for convenience, copy fixed also
cp $fixed ${outputDir}/fixed.nii.gz

# Now warp tensors and get V1 in FSL vector format
${ANTSPATH}antsApplyTransforms -d 3 -e 2 -r $fixed -t ${outputRoot}0GenericAffine.mat -i $movingDT -o ${outputRoot}DTDeformed.nii.gz

get4DV1 ${outputRoot}DTDeformed.nii.gz ${outputRoot}V1Deformed.nii.gz

${ANTSPATH}ReorientTensorImage 3 ${outputRoot}DTDeformed.nii.gz ${outputRoot}DTReorientedMat.nii.gz ${outputRoot}0GenericAffine.mat

get4DV1 ${outputRoot}DTReorientedMat.nii.gz ${outputRoot}V1ReorientedMat.nii.gz

# Get a warp field 
${ANTSPATH}antsApplyTransforms -d 3 -r $fixed -t ${outputRoot}0GenericAffine.mat -i $moving -o [${outputRoot}0Warp.nii.gz, 1]

${ANTSPATH}ReorientTensorImage 3 ${outputRoot}DTDeformed.nii.gz ${outputRoot}DTReorientedWarp.nii.gz ${outputRoot}0Warp.nii.gz

get4DV1 ${outputRoot}DTReorientedWarp.nii.gz ${outputRoot}V1ReorientedWarp.nii.gz
