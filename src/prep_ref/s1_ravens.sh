#! /bin/bash


### check : 1056455_2_0

bdir='/cbica/home/erusg/GitHub/gurayerus/NiChart_RAVENS'

ddir='/cbica/home/erusg/comp_space/GitHub/gurayerus/NiChart_RAVENS/data/ref_data_prep/ukbb'

##############################################
# Set paths to data, template, scripts
sdir="$(cd ${bdir}/src && pwd)"
tdir="$(cd ${bdir}/resources/templates/colin27 && pwd)"
indir="$(cd ${ddir}/in && pwd)"

mkdir -pv ${ddir}/out_csf
outdir="$(cd ${ddir}/out_csf && pwd)"

##############################################
## Set template

tImg=${tdir}/colin27_t1_tal_lin_T1_LPS_dlicv.nii.gz

list=${indir}/lists/list_ref_n200.csv

# regtype='default'
regtype='test'

isslurm='yes'
# isslurm='no'

# is_invert='no'
is_invert='yes'

# labels='auto'
labels=${bdir}/resources/dictionaries/list_MUSE_derived_CSF.csv

# Update template if user wants to invert image
if [ "${is_invert}" == 'yes' ]; then
    tImg=${tImg%.nii.gz}_Inv.nii.gz 
fi

for mrid in $( sed 1d $list | cut -d, -f1 ); do
# for mrid in $( sed 1d $list | cut -d, -f1 | head -5 ); do
    echo "Calc RAVENS for $mrid"
    
    t1=${indir}/images/DLICV/${mrid}_T1_DLICV.nii.gz
    t1seg=${indir}/images/DLMUSE/${mrid}_T1_DLMUSE.nii.gz

    outpref="${mrid}_"
    outsub=${outdir}/warp_${regtype}/${mrid}

    if [ -d $outsub ]; then
        echo "Skip $mrid"
    
    else

        # Create out dir for subject
        mkdir -pv $outsub

        # cd to scripts
        cd $sdir
    

        # Run command
        if [ "${isslurm}" == 'no' ]; then
            cmd="./ravens_ants.sh -s $t1 -l ${t1seg} -t ${tImg} -d ${outsub} -p ${outpref} -m ${regtype} -n ${is_invert} -i ${labels}"
            echo "About to run: $cmd"
            $cmd
        else
            logdir=${outsub}/log_slurm
            mkdir -pv $logdir
            cmd="sbatch --output=${logdir}/%x_%j.out --error=${logdir}/%x_%j.err --cpus-per-task=4 --time=08:00:00 --propagate=NONE ./ravens_ants.sh -s $t1 -l ${t1seg} -t ${tImg} -d ${outsub} -p ${outpref} -m ${regtype} -n ${is_invert} -i ${labels}"
            echo "About to run: $cmd"
            $cmd
        fi
    fi

done
