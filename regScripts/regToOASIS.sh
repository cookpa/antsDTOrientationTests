#!/bin/bash

binDir=`dirname $0`

if [[ $# -eq 0 ]]; then
    echo " 
  $0 <moving series> 

  Run this from the directory above scripts/ . Output is to reg/ .

  Uses ANTs with ANTSPATH=${ANTSPATH}

"
    exit 1

fi

movingSeries=$1

movingFA="nativeDT/ants/${movingSeries}/${movingSeries}_FA.nii.gz"
movingDT="nativeDT/ants/${movingSeries}/${movingSeries}_DT.nii.gz"

fixedT1="OASIS/T_template0_BrainCerebellum_3mm.nii.gz"

if [[ !(-f $fixedT1 && -f $movingFA) ]] ; then
    echo " Missing input images "
    exit 1
fi


outputRoot="reg/${movingSeries}ToOASIS/${movingSeries}ToOASIS_"

regScripts/regHelper.sh $movingFA $movingDT $fixedT1 $outputRoot
