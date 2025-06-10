# antsDTOrientationTests

Data and code to test DT warping and reorientation in ANTs.


## Raw data

A single subject scanned on a Siemens Prisma, with varying image orientations.
The data is from

  https://www.nitrc.org/plugins/mwiki/index.php/dcm2nii:MainPage#Diffusion_Tensor_Imaging

Please see the license file in rawData/license.txt if you want to use or
redistribute this data.

The OASIS template is derived from the original by Nick Tustison, at

  https://figshare.com/articles/ANTs_ANTsR_Brain_Templates/915436

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

Brain masks were created with FSL's `bet`.


## DT fit

The DT is computed with FSL (dtifit). It is then converted into ANTs format. No
reorientation is applied at this stage, the components are just re-ordered into
a NIFTI standard (lower triangular) file compatible with ITK I/O.

The scripts to do this are in nativeDT/, and can be run from that directory.


## Registration experiments

The registration is rigid. Deformable registration will be tested in a separate
repository.

Alignment of principal directions is assessed by extracting the primary
eigenvector of the tensor with ImageMath after registration / reorientation.

I have used fsleyes to visualize results. Note that FSL requires radiological orientation
for bvecs, regardless of whether or not the image index space is radiological. If
`fslorient -getorient` reports NEUROLOGICAL, fsleyes will automatically flip the tensor
vectors for display. You can toggle this in fsleyes settings.

ANTs attempts to handle this automatically by flipping the coordinate system of the
tensors from NEUROLOGICAL images upon import and export. Inside ANTs, we require that the
tensors match the index space of the image, such that they can be rebased to physical space by
applying the header direction matrix.

The test data here is all RADIOLIGICAL, so this should not be an issue.

Example:

```
regScripts/reg.sh ortho roll
```

Or to run all registrations:

```
./runAll.sh
```


## Output directories

### `reg/`

This aligns the FA images to each other, and to the OASIS T1 template. The
rotation in physical space is very small, but getting the headers wrong can lead
to large errors.

These tests mostly check that antsApplyTransforms is correctly reading and
writing the deformed images.

For the OASIS registrations, the rigid alignment is only roughly correct, so it
may be easier to view the warped FA image as the base layer rather than the T1.


### `regWithRotation/`

Fixed images here are rotated with respect to the original FA images. They are
designed to test the reorientation that occurs when the fixed and moving images
are not aligned in physical space.

The fixed images for these experiments are in targetImagesWithRotation/.

To aid visual inspection, the rotations are quite large, so antsAI is called
before antsRegistrationSyNQuick.sh.


## Registration output

fixed.nii.gz - the fixed image

movingToFixed_DTDeformed.nii.gz - DT resampled and reoriented into the fixed space.

movingToFixed_FADeformed.nii.gz - FA from movingToFixed_DTDeformed.nii.gz

The principal directions from each of these tensors is stored as a 4D vector,
which FSL recognizes as a DT eigenvector. Eg,

  movingToFixed_V1Deformed.nii.gz

ANTs normally writes these in NIFTI format, which is 5D with intent code
NIFTI_INTENT_VECTOR. If you want this format, run

  ImageMath 3 V1.nii.gz TensorToVector DT.nii.gz 2