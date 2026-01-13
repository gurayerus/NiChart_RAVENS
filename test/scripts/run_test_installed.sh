#! /bin/bash

## Test subject
mrid='subj1'

## Set registration mode (profile)
regmode='quick'         # Default mode (~10 minutes)
regmode='test'          # For a quick test (~1 minutes)
regmode='quick2'

## Registration backend: ants (default) or fireants
reg_backend='fireants'

# Allow overriding backend via first CLI argument, e.g.:
#   ./run_test_installed.sh fireants
if [ $# -ge 1 ]; then
    reg_backend="$1"
fi

## Mounting path for the container app
app_dir=$(realpath ../..)
input_dir="${app_dir}/test/input/${mrid}"
output_dir="${app_dir}/test/output/${mrid}"
output_dir="${app_dir}/test/output_fireants/${mrid}"

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
cd ${app_dir}/src

#########
# 
# /cbica/home/erusg/GitHub/Others/fireants/cli/fireantsRegistration --output firetest --device cuda:0  --initial-moving-transform [Template.nii.gz,subj1_T1_ICV_Inv.nii.gz,2] --transform Rigid[0.03] --metric MI[Template.nii.gz,subj1_T1_ICV_Inv.nii.gz,gaussian,16] --convergence [100x50x25x10,1e-6,10] --shrink-factors 8x4x2x1 --transform Affine[0.03] --metric CC[Template.nii.gz,subj1_T1_ICV_Inv.nii.gz,5] --convergence [100x50x25x10,1e-4,10] --shrink-factors 8x4x2x1 --transform SyN[0.2] --metric MSE[Template.nii.gz,subj1_T1_ICV_Inv.nii.gz] --convergence [100x70x50x20,1e-4,10] --shrink-factors 8x4x2x1 --verbose
# 
#########


## Run abn map creation
CMD="./nichart_abnmap.sh \
        --in_img ${t1} \
        --in_seg ${t1seg} \
        --labels CSF \
        --out_dir ${output_dir} \
        --out_prefix ${mrid}_ \
        --reg_mode ${regmode} \
        --reg_backend ${reg_backend} \
        --age ${age} \
        --sex ${sex} \
        --icv_mask ${t1seg} \
        --flag_invert yes \
        --flag_del_tmp no \
        --ref_dir ${ref} \
        --template ${template} \
        --label_dict ${label_dict}"

echo "--- COMMAND TO BE EXECUTED ---"
echo "$CMD"
echo "------------------------------"

eval "$CMD"
