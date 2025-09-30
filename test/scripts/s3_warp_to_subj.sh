#! /bin/bash

regtype='test'

##############################################
# Set paths to data, template, scripts
sdir="$(cd ../../src && pwd)"
indir=`cd "../input" && pwd`
wdir=`cd "../out_csf/warp_${regtype}" && pwd`
zdir=`cd "../out_csf/zscore_${regtype}" && pwd`

##############################################
## Set data and template

mrid='1000017_2_0'
mrid='1002338_2_0'

in_img=${zdir}/${mrid}/${mrid}_CSF_RAVENS_zscored.nii.gz
out_img=${zdir}/${mrid}/${mrid}_CSF_RAVENS_zscored_insubj.nii.gz

##############################################
# Main 

# cd to scripts
cd $sdir

t1=${indir}/${mrid}/${mrid}_T1_DLICV.nii.gz
w1=${wdir}/${mrid}/${mrid}_1InverseWarp.nii.gz
w2=${wdir}/${mrid}/${mrid}_0GenericAffine.mat

interp='linear'

# Run command
cmd="./warp_abnmap_to_subj_ants.sh --in_img $in_img --target $t1 --in_warp $w1 --in_affine $w2 --out_img $out_img --interp $interp"
echo "About to run: $cmd"
$cmd
