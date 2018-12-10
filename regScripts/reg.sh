#!/bin/bash

if [[ $# -eq 0 ]]; then
    echo " 
  $0 <moving> <fixed> 

  Run this from the directory above scripts/. Output is to reg/

  Uses ANTs with ANTSPATH=${ANTSPATH}

"

    exit 1

fi

movingSeries=$1
fixedSeries=$2

movingFA="nativeDT/ants/${movingSeries}/${movingSeries}_FA.nii.gz"
movingDT="nativeDT/ants/${movingSeries}/${movingSeries}_DT.nii.gz"

fixedFA="nativeDT/ants/${fixedSeries}/${fixedSeries}_FA.nii.gz"

if [[ !(-f $fixedFA && -f $movingFA) ]] ; then
    echo " Cannot find images corresponding to $movingSeries / $fixedSeries "
    exit 1
fi

fixedFirstLetterUpper=`echo ${fixedSeries:0:1} | tr '[:lower:]' '[:upper:]'`

fixedSeriesTitleCase="${fixedFirstLetterUpper}${fixedSeries:1}"

outputRoot="reg/${movingSeries}To${fixedSeriesTitleCase}/${movingSeries}To${fixedSeriesTitleCase}_"

regScripts/regHelper.sh $movingFA $movingDT $fixedFA $outputRoot
