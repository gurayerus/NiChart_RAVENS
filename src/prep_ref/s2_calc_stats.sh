#! /bin/bash

# NiChart_RAVENS package project folder
pkg_dir='/cbica/home/erusg/GitHub/gurayerus/NiChart_RAVENS'
src_dir=${pkg_dir}/src

#-------------------------------
# --- Usage ---
usage() {
  echo "Usage: $0 <config_file>"
  echo "Example $0 /cbica/home/erusg/comp_space/GitHub/gurayerus/NiChart_RAVENS/data/ref_data_prep/ukbb/out/ref_csf_ravens_test/config/config_stats.sh"  
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

list=${conf_dir}/${list_demog}

# cd to scripts
echo "cd to $src_dir"
cd $src_dir

ravens_dir=${out_dir}/ravens
encode_dir=${out_dir}/encoded

#-------------------------------
# --- Make list of ravens  ---
for roi in $( echo $labels ); do
    mkdir -pv ${encode_dir}/${roi}
    list_ravens=${encode_dir}/${roi}/list_${roi}.csv
    
    if [ ! -e $list_ravens ]; then
        echo MRID,FileName > $list_ravens
        for mrid in $(sed 1d $list | cut -d, -f1 ); do
            fname=${ravens_dir}/${mrid}/${mrid}_Label_${roi}_RAVENS.nii.gz
            if [ -e ${fname} ]; then
                echo $mrid,${fname}
            fi >> $list_ravens
        done
    fi
done

# 
# #-------------------------------
# # --- Encode data ---
for roi in $( echo $labels ); do
    list_ravens=${encode_dir}/${roi}/list_${roi}.csv

    cmd="python ./utils/util_refdata_encode.py ${list_ravens} ${encode_dir}/${roi} --n_samples 50"
    echo "About to run: $cmd"
    $cmd

done

# 
# if [ ! -d ${encode_dir}/list_stats.csv ]; then
#     cmd="python ./utils/util_refdata_get_stats.py $list $ddir $odir --agediff $agediff --agestep $agestep --corr_icv"
#     echo "About to run: $cmd"
#     $cmd
# fi
