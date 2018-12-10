#!/bin/bash

if [[ $# -eq 0 ]]; then
    echo " 
  $0 <moving> <fixed> 

  Run this from the directory above scripts/. Output is to regWithRotation/

  Uses ANTs with ANTSPATH=${ANTSPATH}

"

    exit 1

fi

movingSeries=$1
fixedSeries=$2

movingFA="nativeDT/ants/${movingSeries}/${movingSeries}_FA.nii.gz"
movingDT="nativeDT/ants/${movingSeries}/${movingSeries}_DT.nii.gz"

fixedFA="targetImagesWithRotation/${fixedSeries}_FA_rotated.nii.gz"


if [[ !(-f $fixedFA && -f $movingFA) ]] ; then
    echo " Cannot find images corresponding to $movingSeries / $fixedSeries "
    exit 1
fi

fixedFirstLetterUpper=`echo ${fixedSeries:0:1} | tr '[:lower:]' '[:upper:]'`

fixedSeriesTitleCase="${fixedFirstLetterUpper}${fixedSeries:1}"

outputRoot="regWithRotation/${movingSeries}To${fixedSeriesTitleCase}Rotated/${movingSeries}To${fixedSeriesTitleCase}Rotated_"

initialTransform=${outputRoot}init.mat

# Run quick antsAI because the rotation can be large
${ANTSPATH}antsAI -d 3 -m Mattes[ $fixedFA , $movingFA , 32 , Regular, 0.125 ] -t Rigid[0.2] -s [25, 0.14] -c [8] -o $initialTransform -v 1

regScripts/regHelper.sh $movingFA $movingDT $fixedFA $outputRoot $initialTransform
