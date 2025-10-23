#! /bin/bash

## Test subject
mrid='subj1'

## Set registration mode
regmode='quick'         # Default mode (~10 minutes)
regmode='test'          # For a quick test (~1 minutes)

## Mounting path for the container app
app_dir=$(realpath ../..)
input_dir="${app_dir}/test/input/${mrid}"
output_dir="${app_dir}/test/output/${mrid}"

## Input files
t1="${input_dir}/${mrid}_T1.nii.gz"
t1seg="${input_dir}/${mrid}_T1_DLMUSE.nii.gz"

## Reference files
template="${app_dir}/resources/templates/colin27/colin27_t1_tal_lin_T1_LPS_dlicv.nii.gz"
label_dict="${app_dir}/resources/dictionaries/list_MUSE_derived.csv"
ref="${app_dir}/resources/refmodels/ref_csf_ravens_quick/stats_npz"

## Create out dir for subject
mkdir -pv ${output_dir}

## Read Age and Sex values from demog file
age=$( sed 1d ${input_dir}/list_demog.csv | cut -d, -f2 )
sex=$( sed 1d ${input_dir}/list_demog.csv | cut -d, -f3 )

## Go to scripts
cd ${app_dir}/scripts

## Run abn map creation
CMD="nichart_abnmap.sh \
        --in_img ${t1} \
        --in_seg ${t1seg} \
        --labels CSF \
        --out_dir ${output_dir} \
        --out_prefix ${mrid}_ \
        --reg_mode ${regmode} \
        --age ${age} \
        --sex ${sex} \
        --icv_mask ${t1seg} \
        --flag_invert yes \
        --flag_del_tmp yes \
        --ref_dir ${ref} \
        --template ${template} \
        --label_dict ${label_dict}"

echo "--- COMMAND TO BE EXECUTED ---"
echo "$CMD"
echo "------------------------------"

eval "$CMD"
