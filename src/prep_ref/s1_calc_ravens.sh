#! /bin/bash

# NiChart_RAVENS package project folder
pkg_dir='/cbica/home/erusg/GitHub/gurayerus/NiChart_RAVENS'
src_dir=${pkg_dir}/src

#-------------------------------
# --- Usage ---
usage() {
  echo "Usage: $0 <config_file>"
  echo "Example $0 ref_csf_ravens_test/config/config_ravens.sh"
  exit 1
}

#-------------------------------
# --- Check input ---
if [ $# -ne 1 ]; then
  usage
fi

config_file=$1

if [ ! -f "$config_file" ]; then
  echo "Error: Config file '$config_file' not found!"
  exit 1
fi

#-------------------------------
# --- Load config ---
source "$config_file"

conf_dir=$(dirname "$(realpath "$config_file")")
out_dir=$(dirname `dirname "$(realpath "$config_file")"`)

echo "Running job at $out_dir"

list=${conf_dir}/${list_images}

templ_img=${pkg_dir}/${templ_img}
if [ ! -z ${label_dict} ]; then
    label_dict=${pkg_dir}/${label_dict}
fi

# cd to scripts
echo "cd to $src_dir"
cd $src_dir

#-------------------------------
# --- Run RAVENS Map calculation ---
# for ll in $( sed 1d $list | head -2); do
for ll in $( sed 1d $list); do
    mrid=$( echo $ll | cut -d, -f1 )
    t1_img=$( echo $ll | cut -d, -f2 )
    label_img=$( echo $ll | cut -d, -f3 )

    echo "Calc RAVENS for $mrid"
    
    out_pref="${mrid}_"
    out_sub=${out_dir}/ravens/${mrid}

    # Check input / output
    if [ ! -e ${t1_img} ]; then
        echo "Missing T1 img, skip: ${t1_img}"
        continue
    fi
    if [ ! -e ${label_img} ]; then
        echo "Missing label img, skip: $label_img"
        continue
    fi
    
    # Create out dir for subject
    mkdir -pv $out_sub
    
    # Check output
    flagout='1'
    for nn in $( echo $labels | sed 's/,/ /g'); do
        fout=${out_sub}/${out_pref}Label_${nn}_RAVENS.nii.gz
        if [ ! -e $fout ]; then
            flagout='0'
        fi
    done
    if [ ${flagout} == '1' ]; then
        echo "Output exists, skip: $mrid"
        continue;
    fi

    # Run command for each subject
    cmd="./calc_ravens_ants.sh --source ${t1_img} --label ${label_img} --target ${templ_img} --outdir ${out_sub} --prefix ${out_pref} --mode ${regtype} --invert ${flag_invert}"
    if [ ! -z ${labels} ]; then
        cmd="${cmd} --labels ${labels}"
    fi
    if [ ! -z ${label_dict} ]; then
        cmd="${cmd} --labeldict ${label_dict}"
    fi

    if [ "${flag_slurm}" == 'yes' ]; then
        logdir=${out_sub}/log_slurm
        mkdir -pv $logdir
        cmd="sbatch --output=${logdir}/%x_%j.out --error=${logdir}/%x_%j.err --cpus-per-task=4 --time=08:00:00 --propagate=NONE ${cmd}"
    fi
    echo "About to run: $cmd"
    $cmd
    
# #     read -p ee

done

#-------------------------------
# --- Make list of ravens  ---
for roi in $( echo $labels | sed 's/,/ /g' ); do
    list_ravens=${out_dir}/ravens/list_${roi}.csv
    
    if [ ! -e $list_ravens ]; then
        echo MRID,FileName > $list_ravens
        for mrid in $(sed 1d $list | cut -d, -f1 ); do
            fname=${out_dir}/ravens/${mrid}/${mrid}_Label_${roi}_RAVENS.nii.gz
            if [ -e ${fname} ]; then
                echo $mrid,${fname}
            fi >> $list_ravens
        done
    fi
done

