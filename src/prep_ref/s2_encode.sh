#! /bin/bash

bdir='/cbica/home/erusg/GitHub/gurayerus/NiChart_RAVENS'
ddir='/cbica/home/erusg/comp_space/GitHub/gurayerus/NiChart_RAVENS/data/ref_data_prep/ukbb'

##############################################
# Set paths to data, template, scripts
sdir="$(cd ${bdir}/src && pwd)"
indir="$(cd ${ddir}/out_csf/warp_test && pwd)"

mkdir -pv ${ddir}/out_csf/encoded
outdir="$(cd ${ddir}/out_csf/encoded && pwd)"

##############################################
## Set data and template

# cd to scripts
cd $sdir

cmd="python ./utils/util_refdata_encode.py ${indir} ${outdir} --suffix _Label_CSF_RAVENS.nii.gz --n_samples 50"
echo "About to run: $cmd"
$cmd
