#! /bin/bash

regtype='test'
# regtype='default'

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

roi='CSF'

outpref="${mrid}_"
outsub=${outdir}/${mrid}

##############################################
# Main 

img_ravens=${wdir}/${mrid}/${mrid}_Label_${roi}_RAVENS.nii.gz

# Create out dir for subject
mkdir -pv $outsub

# cd to scripts
cd $sdir

dtype='npz'
reflist="/cbica/home/erusg/comp_space/GitHub/gurayerus/NiChart_RAVENS/data/ref_data_prep/ukbb/out/ref_csf_ravens_${regtype}/stats_encoded/list_${roi}.csv"
params="/cbica/home/erusg/comp_space/GitHub/gurayerus/NiChart_RAVENS/data/ref_data_prep/ukbb/out/ref_csf_ravens_${regtype}/stats_encoded/params.json"
outimg=${outsub}/${mrid}_${roi}_encoded_RAVENS_zscored.nii.gz


# dtype='nifti'
# reflist="/cbica/home/erusg/comp_space/GitHub/gurayerus/NiChart_RAVENS/data/ref_data_prep/ukbb/out/ref_csf_ravens_${regtype}/stats_nifti/list_${roi}.csv"
# outimg=${outsub}/${mrid}_${roi}_RAVENS_zscored.nii.gz


list=${indir}/${mrid}/list.csv
age=`tail -1 $list | cut -d, -f2`
sex=`tail -1 $list | cut -d, -f3`
icv=`tail -1 $list | cut -d, -f4`

if [ ! -e $outimg ]; then

    # Run command
    cmd="./calc_abnmap.sh --in_img $img_ravens --age $age --sex $sex --icv $icv --ref_list $reflist --dtype $dtype --out_img $outimg"

    if [ ${dtype} == 'npz' ]; then
        cmd="${cmd} --params $params"
    fi

    echo "About to run: $cmd"
    $cmd

fi
