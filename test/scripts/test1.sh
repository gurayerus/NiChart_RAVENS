#! /bin/bash

pwd=`pwd`

din=${pwd}/../input
dout=${pwd}/../out_test1

mrid='1000017_2_0'
# mrid='1002338_2_0'

t1=${din}/${mrid}/${mrid}_T1_DLICV.nii.gz
t1seg=${din}/${mrid}/${mrid}_T1_DLMUSE.nii.gz

regtype='default'
regtype='test'

isslurm='yes'
# isslurm='no'

outpref="${mrid}_"

labels='CSF,GM,WM'
labels='81,82,83,47'
labels='CSF'

##############################################
# Main 

# Create out dir for subject
mkdir -pv $dout

# cd to scripts
cd ../../src

# Run command
cmd="./nichart_abnmap.sh --in_img $t1 --in_seg ${t1seg} --labels ${labels} --out_dir ${dout} --out_prefix ${outpref} --reg_mode test"

# if [ "${isslurm}" == 'yes' ]; then
#     logdir=${outsub}/log_slurm
#     mkdir -pv $logdir
#     cmd="sbatch --output=${logdir}/%x_%j.out --error=${logdir}/%x_%j.err --cpus-per-task=4 --time=08:00:00 --propagate=NONE ${cmd}"
# fi

echo "About to run: $cmd"
$cmd
