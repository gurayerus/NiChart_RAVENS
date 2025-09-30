#! /bin/bash

regtype='test'

##############################################
# Set paths to data, template, scripts
sdir="$(cd ../../src && pwd)"
indir=`cd "../input" && pwd`
wdir=`cd "../out_csf/warp_${regtype}" && pwd`

mkdir -pv ../out_csf/zscore_${regtype}
outdir="$(cd ../out_csf/zscore_${regtype} && pwd)"

##############################################
## Set data and template

mrid='1000017_2_0'
mrid='1002338_2_0'

img_ravens=${wdir}/${mrid}/${mrid}_Label_CSF_RAVENS.nii.gz

outpref="${mrid}_"
outsub=${outdir}/${mrid}

outimg=${outsub}/${mrid}_CSF_RAVENS_zscored.nii.gz

##############################################
# Main 

# Create out dir for subject
mkdir -pv $outsub

# cd to scripts
cd $sdir

refdir='/cbica/home/erusg/comp_space/GitHub/gurayerus/NiChart_RAVENS/data/ref_data_prep/ukbb/out_csf/stat_maps'

list=${indir}/${mrid}/list.csv
age=`tail -1 $list | cut -d, -f2`
sex=`tail -1 $list | cut -d, -f3`
icv=`tail -1 $list | cut -d, -f4`

# Run command
cmd="./calc_abnmap.sh --in_img $img_ravens --age $age --sex $sex --icv $icv --ref_dir $refdir --out_img $outimg"
echo "About to run: $cmd"
$cmd
