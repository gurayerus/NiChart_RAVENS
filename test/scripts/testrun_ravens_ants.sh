#! /bin/bash

##############################################
# Set paths to data, template, scripts
sdir="$(cd ../../src && pwd)"
tdir="$(cd ../../resources/templates/colin27 && pwd)"
indir="$(cd ../input && pwd)"

mkdir -pv ../output
outdir="$(cd ../output && pwd)"

##############################################
## Set data and template

# tImg=${tdir}/colin27_t1_tal_lin_T1_LPS_dlicv_reshaped.nii.gz
tImg=${tdir}/colin27_t1_tal_lin_T1_LPS_dlicv.nii.gz

mrid='subj1'
mrid='subj2'

# t1=${indir}/${mrid}/${mrid}_T1_LPS_dlicv_reshaped.nii.gz
# t1seg=${indir}/${mrid}/${mrid}_T1_LPS_dlicv_seg_reshaped.nii.gz
t1=${indir}/${mrid}/${mrid}_T1_LPS_dlicv.nii.gz
t1seg=${indir}/${mrid}/${mrid}_T1_LPS_dlicv_seg.nii.gz

# regtype='high'
regtype='test'
# regtype='balanced'
regtype='high'

isslurm='yes'
#isslurm='no'

outpref="${mrid}_"
outsub=${outdir}/${regtype}/${mrid}

##############################################
# Main 

# Create out dir for subject
mkdir -pv $outsub

# cd to scripts
cd $sdir

# Run command
if [ "${isslurm}" == 'no' ]; then
    cmd="./ravens_ants.sh -s $t1 -l ${t1seg} -t ${tImg} -d ${outsub} -r ${outpref} -p ${regtype}"
    echo "About to run: $cmd"
    $cmd
else
    logdir=${outsub}/log_slurm
    mkdir -pv $logdir
    cmd="sbatch --output=${logdir}/%x_%j.out --error=${logdir}/%x_%j.err ./ravens_ants.sh -s $t1 -l ${t1seg} -t ${tImg} -d ${outsub} -r ${outpref} -p ${regtype}"
    echo "About to run: $cmd"
    $cmd
fi
