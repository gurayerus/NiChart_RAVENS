#! /bin/bash

bdir='/cbica/home/erusg/GitHub/gurayerus/NiChart_RAVENS'
ddir='/cbica/home/erusg/comp_space/GitHub/gurayerus/NiChart_RAVENS/data/ref_data_prep/ukbb'

regtype='default'
# regtype='test'

##############################################
# Set paths to data, template, scripts
sdir="$(cd ${bdir}/src && pwd)"
indir="$(cd ${ddir}/in && pwd)"
outdir="$(cd ${ddir}/out_csf && pwd)"

##############################################

ddir=${outdir}/encoded_${regtype}
list=${indir}/lists/list_ref_n200.csv

cd $sdir

suff='_encoded.npz'

odir=${outdir}/stat_maps2_${regtype}
osuff=out_map

agediff=4
agestep=4
ddir=${outdir}/encoded_${regtype}

if [ ! -d ${odir}/list_stats.csv ]; then
    cmd="python ./utils/util_refdata_get_stats.py $list $ddir $odir --agediff $agediff --agestep $agestep --corr_icv"
    echo "About to run: $cmd"
    $cmd
fi
