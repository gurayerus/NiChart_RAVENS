#! /bin/bash

##############################################
# Set paths to data, template, scripts
sdir="$(cd ../../src && pwd)"
tdir="$(cd ../../resources/templates/colin27 && pwd)"
indir="$(cd ../input && pwd)"

mkdir -pv ../out_csf
outdir="$(cd ../out_csf && pwd)"

##############################################
## Set data and template

tImg=${tdir}/colin27_t1_tal_lin_T1_LPS_dlicv.nii.gz

mrid='1000017_2_0'
mrid='1002338_2_0'

t1=${indir}/${mrid}/${mrid}_T1_DLICV.nii.gz
t1seg=${indir}/${mrid}/${mrid}_T1_DLMUSE.nii.gz

# regtype='default'
regtype='test'

isslurm='yes'
# isslurm='no'

outpref="${mrid}_"
outsub=${outdir}/warp_${regtype}/${mrid}

# is_invert='no'
is_invert='yes'

# labels='auto'
labels='/cbica/home/erusg/GitHub/gurayerus/NiChart_RAVENS/resources/dictionaries/list_MUSE_derived_CSF.csv'

##############################################
# Main 

# Update template if user wants to invert image
if [ "${is_invert}" == 'yes' ]; then
   tImg=${tImg%.nii.gz}_Inv.nii.gz 
fi

# Create out dir for subject
mkdir -pv $outsub

# cd to scripts
cd $sdir

# Run command
if [ "${isslurm}" == 'no' ]; then
    cmd="./calc_ravens_ants.sh -s $t1 -l ${t1seg} -t ${tImg} -d ${outsub} -p ${outpref} -m ${regtype} -n ${is_invert} -i ${labels}"
    echo "About to run: $cmd"
    $cmd
else
    logdir=${outsub}/log_slurm
    mkdir -pv $logdir
    cmd="sbatch --output=${logdir}/%x_%j.out --error=${logdir}/%x_%j.err --cpus-per-task=4 --time=08:00:00 --propagate=NONE ./calc_ravens_ants.sh -s $t1 -l ${t1seg} -t ${tImg} -d ${outsub} -p ${outpref} -m ${regtype} -n ${is_invert} -i ${labels}"
    echo "About to run: $cmd"
    $cmd
fi
