#!/usr/bin/bash
#
# ==========================================================
# Script: nichart_abnmap.sh
# Purpose: Compute voxelwise abnormality maps
# Author: Guray Erus
# Date: 2025-08-25
# ==========================================================
#
# Description:
#   This script calculates z-scored RAVENS maps that indicate
#   voxelwise tissue abnormalities
#
# Requirements:
#   - ANTs (>=2.0)
#   - bash
#
# Usage:
#   See usage
#
# ==========================================================

set -e

# Set number of threads for ANTs
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=4

# Get absolute path to the folder containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define paths relative to the script location
RES_PATH="${SCRIPT_DIR}/../resources"

# ===============================
#   Usage and Help
# ===============================
usage() {
  echo
  echo "Usage: $0 --in_img <path> --in_seg <path> --labels <string> --out_dir <path> --out_prefix <string>"
  echo
  echo "Optional arguments:"
  echo "  --template <path>       Template image file (default: none)"
  echo "  --flag_invert <bool>    Whether to invert intensities (default: false)"
  echo "  --roi_dict <path>       ROI dictionary file (default: none)"
  echo "  --ref_dir <path>        Reference directory (default: none)"
  echo "  --reg_mode <str>        Registration mode (default: default)"
  echo
  echo "Example:"
  echo "  $0 --in_img subj01_T1.nii.gz --in_seg subj01_labels.nii.gz \\"
  echo "     --labels GM,WM --out_dir results --out_prefix subj01_ \\"
  echo "     --template template.nii.gz --ref_dir ./refdata"
  echo "     --reg_mode test"
  echo
  exit 1
}

# ===============================
#   Parse Command-Line Arguments
# ===============================
# Default values
template="${RES_PATH}/templates/colin27/colin27_t1_tal_lin_T1_LPS_dlicv.nii.gz"
roi_dict="${RES_PATH}/dictionaries/list_MUSE_derived.csv"
ref_dir="${RES_PATH}/refmodels/ref_csf_ravens_test"
reg_mode='default'

# Parse long options
while [[ $# -gt 0 ]]; do
  case "$1" in
    --in_img) in_img="$2"; shift 2;;
    --in_seg) in_seg="$2"; shift 2;;
    --labels) labels="$2"; shift 2;;
    --out_dir) out_dir="$2"; shift 2;;
    --out_prefix) out_prefix="$2"; shift 2;;
    --template) template="$2"; shift 2;;
    --flag_invert) flag_invert="$2"; shift 2;;
    --roi_dict) roi_dict="$2"; shift 2;;
    --ref_dir) ref_dir="$2"; shift 2;;
    --reg_mode) reg_mode="$2"; shift 2;;
    -h|--help) usage;;
    *) echo "Unknown option: $1"; usage;;
  esac
done

# ===============================
#   Validate Required Inputs
# ===============================
if [[ -z "$in_img" || -z "$in_seg" || -z "$labels" || -z "$out_dir" || -z "$out_prefix" ]]; then
  echo "Error: Missing one or more required arguments."
  usage
fi

# ===============================
#   Check input files
# ===============================
if [ ! -f "$in_img" ]; then
    echo "Error: Input img does not exist: $in_img" >&2
    exit 1
fi
if [ ! -f "$in_seg" ]; then
    echo "Error: Input segmentation mask does not exist: $in_seg" >&2
    exit 1
fi

# ===============================
#   Prepare Output Directory
# ===============================
mkdir -p "$out_dir"

# ===============================
#   Run nichart_abnmap
# ===============================
echo "Running nichart_abnmap with the following parameters:"
echo "  in_img      = $in_img"
echo "  in_seg   = $in_seg"
echo "  labels        = $labels"
echo "  out_dir     = $out_dir"
echo "  out_prefix  = $out_prefix"
echo "  template    = $template"
echo "  flag_invert = $flag_invert"
echo "  roi_dict    = $roi_dict"
echo "  ref_dir     = $ref_dir"
echo "  reg_mode     = $reg_mode"
echo

# Create a folder with init images
init_dir="${out_dir}/init"
mkdir -p ${init_dir}

if [ ! -e ${init_dir}/${out_prefix}T1.nii.gz ]; then
    ln -sv $in_img ${init_dir}/${out_prefix}T1.nii.gz
fi
if [ ! -e ${init_dir}/${out_prefix}Labels.nii.gz ]; then
    ln -sv $in_seg ${init_dir}/${out_prefix}Labels.nii.gz
fi
if [ ! -e ${init_dir}/Template.nii.gz ]; then
    ln -sv $template ${init_dir}/Template.nii.gz
fi

# Create a mask image for each label
label_dir="${out_dir}/labels"
mkdir -p "$label_dir"
if [ -e ${label_dir}/${out_prefix}Label_List.csv ]; then
    echo; echo "Label masks exists, skip calculation!"
else
    cmd="python3 utils/util_create_label_masks.py ${in_seg} ${labels} ${label_dir}/${out_prefix}Label_"
    if [ ${roi_dict} != 'none' ]; then
        cmd="${cmd} --labeldict ${roi_dict}"
    fi
    echo; echo "Running: $cmd"
    $cmd
fi

# Invert image intensities
if [ "${invert}" == 'yes' ]; then
    final_inv=${init_dir}/${out_prefix}Inv.nii.gz
    cmd="python3 utils/util_invert_img.py ${in_img} ${final_inv}"
    echo; echo "Running: $cmd"
    $cmd
    in_img=${final_inv}
fi

# Apply ANTs
source ./utils/util_ants.sh

warp_dir="${out_dir}/warps"
mkdir -p "$warp_dir"
final_warped=${warp_dir}/${out_prefix}Warped.nii.gz
final_warp=${warp_dir}/${out_prefix}1Warp.nii.gz
final_invwarp=${warp_dir}/${out_prefix}1InverseWarp.nii.gz
final_affine=${warp_dir}/${out_prefix}0GenericAffine.mat
if [ -e ${final_warped} ] && [ -e ${final_warp} ] && [ -e ${final_invwarp} ] && [ -e ${final_affine} ]; then
    echo; echo "ANTs results exist, skip ANTs registration!"
else
    ants_reg ${reg_mode} ${template} ${in_img} ${warp_dir}/${out_prefix}
fi

# Calculate deformation
final_def=${warp_dir}/${out_prefix}Def.nii.gz
if [ -e ${final_def} ]; then
    echo; echo "Deformation exists, skip ANTs registration!"
else
    ants_compose ${final_warp} ${final_affine} ${template} ${final_def}
fi

# Create jacobian
final_jac=${warp_dir}/${out_prefix}Jacobian.nii.gz
if [ -e ${final_jac} ]; then
    echo; echo "Jacobian exists, skip calculation!"
else
    ants_calc_jacdet ${final_def} ${final_jac}
fi

# Warp label masks
interp='Linear'
for label in $(cat ${label_dir}/${out_prefix}Label_List.csv); do
    label_in=${label_dir}/${out_prefix}Label_${label}.nii.gz
    label_out=${label_dir}/${out_prefix}Label_${label}_warped.nii.gz
    if [ -e ${label_out} ]; then
        echo; echo "Warped label ${label} exists, skip calculation!"
    else
        ants_apply ${label_in} ${final_def} ${template} ${interp} ${label_out}
    fi
done

# Calculate RAVENS
interp='Linear'
for label in $(cat ${label_dir}/${out_prefix}Label_List.csv); do
    label_in=${label_dir}/${out_prefix}Label_${label}_warped.nii.gz
    label_out=${out_dir}/${out_prefix}Label_${label}_RAVENS.nii.gz
    if [ -e ${label_out} ]; then
        echo; echo "RAVENS map for label ${label} exists, skip calculation!"
    else
        python3 utils/util_multiply_images.py ${label_in} ${final_jac} ${label_out}
    fi
done

# # Warp RAVENS back to subj space
# interp='Linear'
# for label in $(cat ${label_dir}/${out_prefix}Label_List.csv); do
#     label_in=${out_dir}/${out_prefix}Label_${label}_RAVENS.nii.gz
#     label_out=${out_dir}/${out_prefix}Label_${label}_RAVENS_InSubj.nii.gz
#     if [ -e ${label_out} ]; then
#         echo; echo "RAVENS map in subject space for label ${label} exists, skip calculation!"
#     else
#         ants_apply_inv ${label_in} ${in_img} ${final_invwarp} ${final_affine} ${label_out} ${interp}
#     fi
# done

roi='CSF'
age='55'
sex='F'

ref_type='npz'
ref_list=${ref_dir}/stats_encoded/list_${roi}.csv
ref_params="${ref_dir}/stats_encoded/params.json"

in_ravens=${out_dir}/${out_prefix}Label_${label}_RAVENS.nii.gz

if [ "$ref_type" == 'npz' ]; then

    # ---------------------------
    # Encode input ravens
    encoded_dir="${out_dir}/encoded"
    mkdir -pv $encoded_dir
    out_encoded=${encoded_dir}/ravens_encoded.npz
    if [ -e ${out_encoded} ]; then
        echo; echo "Encoded img exists, skip calculation!"
    else
        cmd="python3 utils/util_encode_ravens.py ${in_ravens} ${ref_params} ${out_encoded}"
        echo; echo "Running: $cmd"
        $cmd
    fi

    # ---------------------------
    # Apply z-score
    out_zscore=${out_dir}/${out_prefix}ABNMAP_${roi}.npz
    if [ -e ${out_zscore} ]; then
        echo; echo "Zscore img exists, skip calculation!"
    else
        cmd="python3 utils/util_zscore_ravens.py --inmap ${out_encoded} --age $age --sex $sex --ref_list ${ref_list} --out_file ${out_zscore}"
        echo; echo "Running: $cmd"
        $cmd
    fi

    # ---------------------------
    # Decode z-score map
    out_img=${out_dir}/${out_prefix}ABNMAP_${roi}.nii.gz
    if [ -e ${out_img} ]; then
        echo; echo "Decoded img exists, skip calculation!"
    else
        cmd="python3 utils/util_decode_ravens.py ${out_zscore} ${ref_params} ${out_img} --in_field zmap"
        echo; echo "Running: $cmd"
        $cmd
    fi

else
    # ---------------------------
    # Apply z-score
    out_zscore=${out_dir}/ravens_zscore.nii.gz
    if [ -e ${out_zscore} ]; then
        echo; echo "Zscore img exists, skip calculation!"
    else
        cmd="python3 utils/util_zscore_ravens.py --inmap ${in_img} --age $age --sex $sex --ref_list ${ref_list} --out_file ${out_zscore}"
        echo; echo "Running: $cmd"
        $cmd
    fi
fi

