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

mrid='1000017_2_0'
# mrid='1002338_2_0'

# is_invert='no'
is_invert='yes'

tImg=${tdir}/colin27_t1_tal_lin_T1_LPS_dlicv_Inv.nii.gz

t1=${indir}/${mrid}/${mrid}_T1_DLICV.nii.gz
t1seg=${indir}/${mrid}/${mrid}_T1_DLMUSE.nii.gz

regtype='default'
regtype='test'

isslurm='yes'
# isslurm='no'

outpref="${mrid}_"
outsub=${outdir}/warp_${regtype}/${mrid}

labels='CSF'
labeldict='/cbica/home/erusg/GitHub/gurayerus/NiChart_RAVENS/resources/dictionaries/list_MUSE_derived_CSF.csv'

##############################################
# Main 

# Create out dir for subject
mkdir -pv $outsub

# cd to scripts
cd $sdir

# Run command
cmd="./calc_ravens_ants.sh --source $t1 --label ${t1seg} --target ${tImg} --outdir ${outsub} --prefix ${outpref} --mode ${regtype} --invert ${is_invert} --labels ${labels} --labeldict ${labeldict}"

if [ "${isslurm}" == 'yes' ]; then
    logdir=${outsub}/log_slurm
    mkdir -pv $logdir
    cmd="sbatch --output=${logdir}/%x_%j.out --error=${logdir}/%x_%j.err --cpus-per-task=4 --time=08:00:00 --propagate=NONE ${cmd}"
fi

echo "About to run: $cmd"
$cmd
