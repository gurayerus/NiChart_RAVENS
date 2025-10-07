#! /bin/bash

# NiChart_RAVENS package project folder
pkg_dir='/cbica/home/erusg/GitHub/gurayerus/NiChart_RAVENS'
src_dir=${pkg_dir}/src

#-------------------------------
# --- Usage ---
usage() {
  echo "Usage: $0 <config_file>"
  echo "Example $0 ref_csf_ravens_test/config/config_stats.sh"  
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

# #-------------------------------
# # --- Encode data ---
echo "Encoding scans ..."
for roi in $( echo $labels | sed 's/,/ /g' ); do
    list_ravens=${ravens_dir}/list_${roi}.csv
    encode_suff="_${roi}_encoded.npz"
    cmd="python ./utils/util_refdata_encode.py ${list_ravens} ${encode_dir} ${encode_suff} --n_samples ${nsamples}"
    echo "About to run: $cmd"
    $cmd
done

#-------------------------------
# --- Make list of encoded  ---
echo "Making list of encoded scans ..."
for roi in $( echo $labels | sed 's/,/ /g' ); do
    list_encoded=${encode_dir}/list_${roi}.csv
    
    if [ ! -e $list_encoded ]; then
        echo MRID,FileName > $list_encoded
        for mrid in $(sed 1d $list | cut -d, -f1 ); do
            fname=${encode_dir}/${mrid}${encode_suff}
            if [ -e ${fname} ]; then
                echo $mrid,${fname}
            fi >> $list_encoded
        done
    fi
done

# #-------------------------------
# # --- Calculate stats (encoded) ---
stats_dir=${out_dir}/stats_encoded
echo "Creating stat maps ..."
for roi in $( echo $labels | sed 's/,/ /g' ); do
    list_stats=${stats_dir}/list_${roi}.csv
    list_encoded=${encode_dir}/list_${roi}.csv
    if [ ! -e ${list_stats} ]; then
        cmd="python ./utils/util_refdata_get_stats.py $roi $list $list_encoded ${stats_dir} --agediff $agediff --agestep $agestep --corr_icv"
        echo "About to run: $cmd"
        $cmd
    fi
done

# #-------------------------------
# # --- Calculate stats (nifti) ---
stats_dir=${out_dir}/stats_nifti
echo "Creating stat maps ..."
for roi in $( echo $labels | sed 's/,/ /g' ); do
    list_stats=${stats_dir}/list_${roi}.csv
    list_ravens=${ravens_dir}/list_${roi}.csv
    if [ ! -e ${list_stats} ]; then
        cmd="python ./utils/util_refdata_get_stats.py $roi $list $list_ravens ${stats_dir} --agediff $agediff --agestep $agestep --corr_icv"
        echo "About to run: $cmd"
        $cmd
    fi
done

