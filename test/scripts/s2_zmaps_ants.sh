#! /bin/bash

##############################################
# Set paths to data, template, scripts
sdir="$(cd ../../src && pwd)"
indir="$(cd ../output/test && pwd)"

mkdir -pv ../output/zscore
outdir="$(cd ../output/zscore && pwd)"

##############################################
## Set data and template

mrid='subj2'

img_ravens=${indir}/${mrid}/${mrid}_Label_1_RAVENS.nii.gz

outpref="${mrid}_"
outsub=${outdir}/${mrid}

##############################################
# Main 

# Create out dir for subject
mkdir -pv $outsub

# cd to scripts
cd $sdir

img_t1=none
t1=none
t2=none

refdir='/cbica/home/erusg/comp_space/GitHub/gurayerus/NiChart_RAVENS/data/ref_data_prep/ukbb/out/stat_maps'

# Run command
cmd="./calc_abnmap_ants.sh -m $img_ravens -i $img_t1 -t $t1 -t $t2 -r $refdir -o $outsub"
echo "About to run: $cmd"
$cmd
