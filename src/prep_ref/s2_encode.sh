#! /bin/bash

bdir='/cbica/home/erusg/GitHub/gurayerus/NiChart_RAVENS'
ddir='/cbica/home/erusg/comp_space/GitHub/gurayerus/NiChart_RAVENS/data/ref_data_prep/ukbb'

regtype='default'
# regtype='test'

##############################################
# Set paths to data, template, scripts
sdir="$(cd ${bdir}/src && pwd)"
indir="$(cd ${ddir}/out_csf/warp_${regtype} && pwd)"

mkdir -pv ${ddir}/out_csf/encoded_${regtype}
outdir="$(cd ${ddir}/out_csf/encoded_${regtype} && pwd)"

##############################################
## Set data and template

# cd to scripts
cd $sdir

cmd="python ./utils/util_refdata_encode.py ${indir} ${outdir} --suffix _Label_CSF_RAVENS.nii.gz --n_samples 50"
echo "About to run: $cmd"
$cmd
