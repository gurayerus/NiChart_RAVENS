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
t1="/input/${mrid}_T1.nii.gz"
t1seg="/input/${mrid}_T1_DLMUSE.nii.gz"

## Reference files
template='/app/resources/templates/colin27/colin27_t1_tal_lin_T1_LPS_dlicv.nii.gz'
label_dict='/app/resources/dictionaries/list_MUSE_derived.csv'
ref='/app/resources/refmodels/ref_csf_ravens_quick/stats_npz'

## Create out dir for subject
mkdir -pv ${output_dir}

## Read Age and Sex values from demog file
age=$( sed 1d ${input_dir}/list_demog.csv | cut -d, -f2 )
sex=$( sed 1d ${input_dir}/list_demog.csv | cut -d, -f3 )

## Docker command
DOCKER_CMD="docker run -it --rm \
    --name ravens \
    --mount type=bind,source=${app_dir},target=/app \
    --mount type=bind,source=${input_dir},target=/input,readonly=true \
    --mount type=bind,source=${output_dir},target=/output,readonly=false \
    cbica/nichart_ravens:initialdemo \
        --in_img ${t1} \
        --in_seg ${t1seg} \
        --labels CSF \
        --out_dir /output \
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
echo "$DOCKER_CMD"
echo "------------------------------"

eval "$DOCKER_CMD"
