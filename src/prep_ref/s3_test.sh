#! /bin/bash

pwd=`pwd`

sdir='/cbica/home/erusg/GitHub/gurayerus/NiChart_RAVENS/src'

pdir='/cbica/home/erusg/comp_space/GitHub/gurayerus/NiChart_RAVENS/data/ref_data_prep/ukbb/cluster'

din=${pdir}/zscores/in
list=${din}/list_test.csv

# regtype='test'
# regtype='quick'
regtype='default'

# ref=${pdir}/csf_ravens_${regtype}/stats_nifti
ref=${pdir}/csf_ravens_${regtype}/stats_npz
dout=${pdir}/zscores/out_${regtype}

isslurm='yes'
# isslurm='no'

outpref="${mrid}_"

labels='CSF'

flag_invert='yes'

flag_del_tmp='no'


##############################################
# Main 

# Create out dir for subject
mkdir -pv $dout

# cd to scripts
cd $sdir


for ll in `sed 1d $list`; do

    mrid=`echo $ll | cut -d, -f1`
    age=`echo $ll | cut -d, -f2`
    sex=`echo $ll | cut -d, -f3`

    t1=${din}/${mrid}_T1.nii.gz
    t1seg=${din}/${mrid}_T1_DLMUSE.nii.gz

    dsub=${dout}/${mrid}
    mkdir -pv $dsub


    # Run command
    cmd="./nichart_abnmap.sh --in_img $t1 --in_seg ${t1seg} --labels ${labels} --out_dir ${dsub} --out_prefix ${mrid}_ --reg_mode ${regtype} --age $age --sex $sex --icv_mask ${t1seg} --flag_invert ${flag_invert} --flag_del_tmp ${flag_del_tmp} --ref_dir ${ref}"

    if [ "${isslurm}" == 'yes' ]; then
        logdir=${dsub}/log_slurm
        mkdir -pv $logdir
        cmd="sbatch --output=${logdir}/%x_%j.out --error=${logdir}/%x_%j.err --cpus-per-task=4 --time=08:00:00 --propagate=NONE ${cmd}"
    fi

    echo "About to run: $cmd"
    $cmd
    
#     read -p ee

done
