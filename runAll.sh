#!/bin/bash

# Register FA images to each other
for fixed in axis ortho pitch roll yaw; do
  for moving in axis ortho pitch roll yaw; do
    if [[ ! $fixed == $moving ]]; then
      regScripts/reg.sh $moving $fixed
    fi
  done
done

# Register FA to OASIS T1 template
for moving in axis ortho pitch roll yaw; do
 regScripts/regToOASIS.sh $moving
done

# Register each image to rotated fixed images
# so there is some actual rotation in physical space
#
for rotated in pitch roll yaw orthoRoll orthoPitch orthoYaw; do
  for moving in axis ortho pitch roll yaw; do
    regScripts/regWithRotation.sh $moving $rotated
  done
done

