#! /bin/bash

trap "stty sane; echo; exit" INT

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
    icv_mask=$( echo $ll | cut -d, -f4 )

    if [[ -z ${t1_img} || -z ${label_img} || -z ${icv_mask} ]]; then
        echo "Empty file name in list, skip $mrid"
        continue
    fi

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
        if [ ${flag_icvcorr} == 'yes' ]; then
            fout=${out_sub}/${out_pref}Label_${nn}_RAVENS_ICVNorm.nii.gz
        else
            fout=${out_sub}/${out_pref}Label_${nn}_RAVENS.nii.gz
        fi
        if [ ! -e $fout ]; then
            flagout='0'
        fi
    done
    if [ ${flagout} == '1' ]; then
        echo "Output exists, skip: $mrid"
        continue;
    fi

    # Run command for each subject
    cmd="./calc_ravens_ants.sh --in_img ${t1_img} --icv_mask ${icv_mask} --in_seg ${label_img} --labels ${labels} --template ${templ_img} --out_dir ${out_sub} --out_prefix ${out_pref} --reg_mode ${regtype} --flag_invert ${flag_invert} --flag_del_warps ${flag_del_warps} --flag_del_tmp ${flag_del_tmp}"
    if [ ! -z ${label_dict} ]; then
        cmd="${cmd} --label_dict ${label_dict}"
    fi

    if [ "${flag_slurm}" == 'yes' ]; then
        logdir=${out_sub}/log_slurm
        mkdir -pv $logdir
        cmd="sbatch --output=${logdir}/%x_%j.out --error=${logdir}/%x_%j.err --cpus-per-task=4 --time=08:00:00 --propagate=NONE ${cmd}"
    fi
    echo "About to run: $cmd"
    $cmd
    
    read -p ee

done

