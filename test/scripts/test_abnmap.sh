#! /bin/bash

pwd=`pwd`

mrid='subju'

din=${pwd}/../input
dout=${pwd}/../output/testD3

t1=${din}/${mrid}/${mrid}_T1_DLICV.nii.gz
t1seg=${din}/${mrid}/${mrid}_T1_DLMUSE.nii.gz

# regtype='default'
regtype='balanced'
# regtype='test'
regtype='quick'

isslurm='yes'
isslurm='no'

outpref="${mrid}_"

labels='CSF,GM,WM'
# labels='81,82,83,47'
# labels='CSF'

flag_icvcorr='yes'

flag_invert='yes'

flag_keep_temp='no'
flag_keep_temp='yes'

age=48
sex=F

ref='/cbica/home/erusg/GitHub/gurayerus/NiChart_RAVENS/resources/refmodels/ref_ravens_test/stats_npz'
# ref='/cbica/home/erusg/GitHub/gurayerus/NiChart_RAVENS/resources/refmodels/ref_ravens_test/stats_nifti'
ref='/cbica/home/erusg/GitHub/gurayerus/NiChart_RAVENS/resources/refmodels/ref_ravens_default/stats_nifti'

##############################################
# Main 

# Create out dir for subject
mkdir -pv $dout

# cd to scripts
cd ../../src

# Run command
cmd="./nichart_abnmap.sh --in_img $t1 --in_seg ${t1seg} --labels ${labels} --out_dir ${dout} --out_prefix ${outpref} --reg_mode ${regtype} --age $age --sex $sex --icv_mask ${t1seg} --flag_invert ${flag_invert} --flag_keep_temp ${flag_keep_temp} --ref_dir ${ref}"

if [ "${isslurm}" == 'yes' ]; then
    logdir=${dout}/log_slurm
    mkdir -pv $logdir
    cmd="sbatch --output=${logdir}/%x_%j.out --error=${logdir}/%x_%j.err --cpus-per-task=4 --time=08:00:00 --propagate=NONE ${cmd}"
fi

echo "About to run: $cmd"
$cmd
