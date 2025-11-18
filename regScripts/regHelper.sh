#!/bin/bash -ex

function get4DV1() {

    # fsleyes does not display 5D NIFTI vectors, requires 4D

    dt=$1
    output=$2

    tmpFileBase=`basename ${dt%.nii.gz}`

    tmpOutputRoot=`mktemp /tmp/${tmpFileBase}_XXXX_`

    ImageMath 3 ${tmpOutputRoot}V1.nii.gz TensorToVector $dt 2

    for (( i=0; i<3; i++ )); do
        ImageMath 3 ${tmpOutputRoot}V1${i}.nii.gz ExtractVectorComponent ${tmpOutputRoot}V1.nii.gz $i
    done

    ImageMath 4 ${output} TimeSeriesAssemble 1 0 ${tmpOutputRoot}V10.nii.gz ${tmpOutputRoot}V11.nii.gz \
        ${tmpOutputRoot}V12.nii.gz

    rm ${tmpOutputRoot}V1.nii.gz
    rm ${tmpOutputRoot}V10.nii.gz
    rm ${tmpOutputRoot}V11.nii.gz
    rm ${tmpOutputRoot}V12.nii.gz

}

function get4DV1FromVector() {

    # fsleyes does not display 5D NIFTI vectors, requires 4D

    vectorImage=$1
    output=$2

    tmpFileBase=`basename ${vectorImage%.nii.gz}`
    tmpOutputRoot=`mktemp /tmp/${tmpFileBase}_XXXX_`

    for (( i=0; i<3; i++ )); do
        ImageMath 3 ${tmpOutputRoot}V1${i}.nii.gz ExtractVectorComponent $vectorImage $i
    done

    ImageMath 4 ${output} TimeSeriesAssemble 1 0 ${tmpOutputRoot}V10.nii.gz ${tmpOutputRoot}V11.nii.gz \
        ${tmpOutputRoot}V12.nii.gz

    rm ${tmpOutputRoot}V10.nii.gz
    rm ${tmpOutputRoot}V11.nii.gz
    rm ${tmpOutputRoot}V12.nii.gz
}

function registerFA() {

    fixed=$1
    moving=$2
    outputRoot=$3
    initialTransform=$4

    initialTransformOption=""

    if [[ ! -z "$initialTransform" ]]; then
        initialTransformOption="--initial-moving-transform $initialTransform"
    else
        initialTransformOption="--initial-moving-transform [ $fixed, $moving, 1 ]"
    fi

    outputDir=`dirname $outputRoot`
    if [[ ! -d $outputDir ]]; then
        mkdir -p ${outputDir}
    fi

    antsRegistration \
      --verbose 1 \
      --dimensionality 3 \
      --float 1 \
      --collapse-output-transforms 1 \
      --output [ ${outputRoot},${outputRoot}Warped.nii.gz ] \
      --interpolation Linear \
      --use-histogram-matching 0 \
      --winsorize-image-intensities [ 0.005,0.995 ] \
      $initialTransformOption \
      --transform Rigid[ 0.1 ] \
      --metric MI[ ${fixed},${moving},1,32 ] \
      --convergence [ 50x25x25,1e-6,10 ] \
      --shrink-factors 3x2x1 \
      --smoothing-sigmas 2x1x0vox

}

if [[ $# -eq 0 ]]; then
    echo "
  $0 <moving> <moving DT> <fixed> <outputRoot> [initialTransform]

  The first moving image is the scalar image that is registered to the fixed image.
  The second one is the DT, which will be warped and reoriented.

  It is assumed that the moving DT is named *_DT.nii.gz and that a V1 image (as an ITK vector image) is
  named *_V1_ITK.nii.gz . This enables testing of both DT and vector warping and reorientation.

  Requires ANTs on PATH.

"

    exit 1

fi

moving=$1
movingDT=$2
fixed=$3
outputRoot=$4

initialTransform=""

if [[ $# -gt 4 ]]; then
    initialTransform="$5"
fi

outputDir=`dirname $outputRoot`

if [[ ! -d $outputDir ]]; then
    mkdir -p ${outputDir}
fi

# Derive V1 name from DT name - this is the ITK vector format
movingV1ITK=${movingDT%DT.nii.gz}V1_ITK.nii.gz

registerFA $fixed $moving $outputRoot $initialTransform

# for convenience, copy fixed also
cp $fixed ${outputDir}/fixed.nii.gz

# Now warp tensors and get V1 in FSL vector format
antsApplyTransforms -d 3 -e 2 -r $fixed -t ${outputRoot}0GenericAffine.mat -i $movingDT -o ${outputRoot}DTDeformed.nii.gz \
   --verbose

get4DV1 ${outputRoot}DTDeformed.nii.gz ${outputRoot}V1Deformed.nii.gz

# Output FA
ImageMath 3 ${outputRoot}FADeformed.nii.gz TensorFA ${outputRoot}DTDeformed.nii.gz

# Now warp vectors with proper reorientation
antsApplyTransforms -d 3 -e 1 -r $fixed -t ${outputRoot}0GenericAffine.mat -i $movingV1ITK \
    -o ${outputRoot}V1Deformed_VectorWarped_ITK.nii.gz -n NearestNeighbor --verbose

get4DV1FromVector ${outputRoot}V1Deformed_VectorWarped_ITK.nii.gz ${outputRoot}V1Deformed_VectorWarped.nii.gz