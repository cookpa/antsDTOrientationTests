# antsDTOrientationTests

Data and code to test DT warping and reorientation in ANTs


## Raw data

A single subject scanned on a Siemens Prisma, with varying image orientations.
The data is from 

  https://www.nitrc.org/plugins/mwiki/index.php/dcm2nii:MainPage#Diffusion_Tensor_Imaging 

Please see the license file in rawData/license.txt if you want to use or
redistribute this data.

## NIFTI data

The data was converted with dcm2niix, then renamed by series (axis, ortho,
pitch, roll, yaw).

In other words, under nii/ we have:

axis:
axis.bval  axis.bvec  axis.json  axis.nii.gz

ortho:
ortho.bval  ortho.bvec  ortho.json  ortho.nii.gz

pitch:
pitch.bval  pitch.bvec  pitch.json  pitch.nii.gz

roll:
roll.bval  roll.bvec  roll.json  roll.nii.gz

yaw:
yaw.bval  yaw.bvec  yaw.json  yaw.nii.gz

The data is in the same physical space, but the acquisition planes vary.


## DT fit

The DT is computed with FSL (dtifit). It is then converted into ANTs format. No
reorientation is applied at this stage, the components are just re-ordered into
a NIFTI standard (lower triangular) file compatible with ITK I/O.

The scripts to do this are in nativeDT/, and can be run from that directory.


## Registration experiments

The registration is rigid, but we test both the application of the affine matrix
and the same matrix encoded in a warp field, as these are handled separately in
the ReorientTensorImage executable.

Alignment of principal directions is assessed by extracting the primary
eigenvector of the tensor with ImageMath after registration / reorientation. 

I have used fsleyes to visualize results.

Example:

```
# Set ANTSPATH to a version you want to test before running this
#
# Run the script from the directory above regScripts/ so it can
# find the data
#
regScripts/reg.sh ortho roll
```

The experiments test different aspects of the code,


### `reg/`

This aligns the FA images to each other, and to the OASIS T1 template. The
rotation in physical space is very small, but getting the headers wrong can lead
to large errors. 

These tests mostly check that antsApplyTransforms is correctly reading and
writing the deformed images. 

For the OASIS registrations, the rigid alignment is only roughly correct, so it
may be easier to view the warped FA image as the base layer rather than the T1. 

### `regWithRotation`

Fixed images here are rotated with respect to the original FA images. They are
designed to test the reorientation that occurs when the fixed and moving images
are not aligned in physical space.

The fixed images for these experiments are in targetImagesWithRotation/.

To aid visual inspection, the rotations are quite large, so antsAI is called
before antsRegistrationSyNQuick.sh. 


## Registration output

fixed.nii.gz - the fixed image

movingToFixed_Warped.nii.gz - deformed moving FA image

movingToFixed_DTDeformed.nii.gz - DT resampled into fixed space, but NOT
                                  reoriented.

movingToFixed_DTReorientedMat.nii.gz - DT reoriented using the affine .mat file

movingToFixed_DTReorientedWarp.nii.gz - DT reoriented using the warp field.
                                        Should be very similar to the matrix
                                        version unless there is a bug. 

The principal directions from each of these tensors is stored as a 4D vector,
which FSL recognizes as a DT eigenvector. Eg,

  movingToFixed_V1ReorientedMat.nii.gz

ANTs writes these in NIFTI format, which is 5D with intent code
NIFTI_INTENT_VECTOR. If you want this format, run

 ImageMath 3 V1.nii.gz TensorToVector DT.nii.gz 2



## Testing different ANTs versions 

To re-run the experiments with different ANTs versions, move 
  
  reg/
  regWithRotation/

then set ANTSPATH and and re-run the experiments.


