#! /bin/bash

pwd=`pwd`

mrid='subju'

din=${pwd}/../input
dout=${pwd}/../output/test

t1=${din}/${mrid}/${mrid}_T1_DLICV.nii.gz
t1seg=${din}/${mrid}/${mrid}_T1_DLMUSE.nii.gz

# regtype='default'
regtype='test'

# isslurm='yes'
isslurm='no'

outpref="${mrid}_"

# labels='CSF,GM,WM'
# labels='81,82,83,47'
labels='CSF'

age=48
sex=F

##############################################
# Main 

# Create out dir for subject
mkdir -pv $dout

# cd to scripts
cd ../../src

# Run command
cmd="./nichart_abnmap.sh --in_img $t1 --in_seg ${t1seg} --labels ${labels} --out_dir ${dout} --out_prefix ${outpref} --reg_mode test --age $age --sex $sex --icv_mask ${t1seg}"


# if [ "${isslurm}" == 'yes' ]; then
#     logdir=${outsub}/log_slurm
#     mkdir -pv $logdir
#     cmd="sbatch --output=${logdir}/%x_%j.out --error=${logdir}/%x_%j.err --cpus-per-task=4 --time=08:00:00 --propagate=NONE ${cmd}"
# fi

echo "About to run: $cmd"
$cmd
