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
# SCRIPT_DIR="$(dirname "$(realpath "$0")")"
SCRIPT_DIR=$(pwd)
if [ -n "${BASH_SOURCE[0]}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    SCRIPT_DIR="$(pwd)"
fi
echo; echo "Script dir is: ${SCRIPT_DIR}"; echo;

# Define paths relative to the script location
RES_PATH="${SCRIPT_DIR}/../resources"

# echo $0
# echo `realpath $0`
# echo `pwd`
# echo 'Bye ...'
# exit;


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
  echo "  --flag_del_tmp <bool>   Whether to delete temp output (default: false)"
  echo "  --label_dict <path>     ROI dictionary file (default: none)"
  echo "  --ref_dir <path>        Reference directory (default: none)"
  echo "  --reg_mode <str>        Registration mode (default: default)"
  echo "  --reg_backend <str>     Registration backend: ants | fireants (default: ants)"
  echo "  --age <int>             Subject's age (default: none)"
  echo "  --sex <str>             Subject's sex (F or M, default: none)"
  echo "  --icv_mask <int>        Mask to calculate intra-cranial volume (default: none)"
  echo
  echo "Example:"
  echo "  $0 --in_img subj01_T1.nii.gz --in_seg subj01_labels.nii.gz \\"
  echo "     --labels GM,WM --out_dir results --out_prefix subj01_ \\"
  echo "     --template template.nii.gz --ref_dir ./refdata"
  echo "     --reg_mode test --age 55 --sex F --icv_mask subj01_labels.nii.gz"
  echo
  exit 1
}

# ===============================
#   Parse Command-Line Arguments
# ===============================
# Default values
template="${RES_PATH}/templates/colin27/colin27_t1_tal_lin_T1_LPS_dlicv.nii.gz"
label_dict="${RES_PATH}/dictionaries/list_MUSE_derived.csv"
reg_mode='default'
reg_backend='ants'

ref_dir="${RES_PATH}/refmodels/ref_ravens_test/stats_encoded"
ref_dir="${RES_PATH}/refmodels/ref_ravens_test/stats_nifti"

flag_invert='no'
flag_del_tmp='no'
icv_mask='none'

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
    --flag_del_tmp) flag_del_tmp="$2"; shift 2;;
    --flag_icvcorr) flag_icvcorr="$2"; shift 2;;
    --label_dict) label_dict="$2"; shift 2;;
    --ref_dir) ref_dir="$2"; shift 2;;
    --reg_mode) reg_mode="$2"; shift 2;;
    --reg_backend) reg_backend="$2"; shift 2;;
    --age) age="$2"; shift 2;;
    --sex) sex="$2"; shift 2;;
    --icv_mask) icv_mask="$2"; shift 2;;
    -h|--help) usage;;
    *) echo "Unknown option: $1"; usage;;
  esac
done

# Check type of reference data (nifti or npz--compressed)
ref_type=${ref_dir##*_}

# ===============================
#   Validate Required Inputs
# ===============================
if [[ -z "$in_img" || -z "$in_seg" || -z "$labels" || -z "$out_dir" || -z "$out_prefix" ]]; then
  echo "Error: Missing one or more required arguments."
  usage
fi

# Invert template
if [[ "$flag_invert" == "yes" ]]; then
    if [[ "$template" != *_Inv.nii.gz ]]; then
        template="${template%.nii.gz}_Inv.nii.gz"
        echo "Warning: Template name should end with _Inv.nii.gz; renaming template"
    fi
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
if [ ! -f "$template" ]; then
    echo "Error: Template image does not exist: $template" >&2
    exit 1
fi

flag_icvcorr='no'
if [ ! -z ${icv_mask} ]; then
    flag_icvcorr='yes'
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
echo "  in_seg      = $in_seg"
echo "  labels      = $labels"
echo "  template    = $template"
echo "  out_dir     = $out_dir"
echo "  out_prefix  = $out_prefix"
echo "  flag_invert = $flag_invert"
echo "  label_dict  = $label_dict"
echo "  ref_dir     = $ref_dir"
echo "  reg_mode    = $reg_mode"
echo "  reg_backend = $reg_backend"
echo "  age         = $age"
echo "  sex         = $sex"
echo "  flag_icvcorr = $flag_icvcorr"
echo "  icv_mask    = $icv_mask"
echo "  flag_del_tmp = $flag_del_tmp"

echo

#-------------------------------
# --- Calculate RAVENS ---
cmd="./calc_ravens_ants.sh --in_img ${in_img} --in_seg ${in_seg} --labels ${labels} --template ${template} --out_dir ${out_dir} --out_prefix ${out_prefix} --reg_mode ${reg_mode} --reg_backend ${reg_backend} --flag_invert ${flag_invert}"
if [ ! -z ${label_dict} ]; then
    cmd="${cmd} --label_dict ${label_dict}"
fi
if [ ${flag_icvcorr} == 'yes' ]; then
    cmd="${cmd} --icv_mask ${icv_mask}"
fi
echo "About to run: $cmd"
$cmd

#-----------------------------------
# --- Calculate abnormality maps ---
if [[ -z age || -z sex ]]; then
    echo "Age and Sex info not provided, skip calculation of abnormality map"
    exit;
fi

if [ ${flag_icvcorr} == 'yes' ]; then
    suff="_RAVENS_ICVNorm"
else
    suff="_RAVENS"
fi

for label in $(echo $labels | sed 's/,/ /g'); do

    echo; echo "Calculating abnormality map for: ${roi}"

    ref_list="${ref_dir}/list_${label}.csv"
    ref_params="${ref_dir}/params.json"

    in_tmp=${out_dir}/${out_prefix}Label_${label}${suff}.nii.gz
    out_tmp=${out_dir}/${out_prefix}Label_${label}${suff}_zScored.nii.gz

    cmd="./calc_zscore_ravens.sh --in_img ${in_tmp} --age ${age} --sex ${sex} --label ${label} --dtype ${ref_type} --ref_list ${ref_list} --params ${ref_params} --out_img ${out_tmp}"
    echo "About to run: $cmd"
    $cmd

done

# Source ants utils (used for ANTs backend)
source ./utils/util_ants.sh

for label in $(echo $labels | sed 's/,/ /g'); do
    interp='Linear'

    echo; echo "Warping abnormality map to subject: ${label}"

    in_tmp=${out_dir}/${out_prefix}Label_${label}${suff}_zScored.nii.gz
    out_tmp=${out_dir}/${out_prefix}Label_${label}${suff}_zScored_inSubj.nii.gz

    if [ -e ${out_tmp} ]; then
        echo; echo "RAVENS map in subject space for label ${label} exists, skip calculation!"
        continue
    fi

    if [ "${reg_backend}" == "ants" ]; then
        def_invwarp=${out_dir}/warps/${out_prefix}1InverseWarp.nii.gz
        def_affine=${out_dir}/warps/${out_prefix}0GenericAffine.mat
        cmd="ants_apply_inv ${in_tmp} ${in_img} ${def_invwarp} ${def_affine} ${out_tmp} ${interp}"
    else
        # FireANTs backend: use inverse deformation field written by util_fireants.py
        def_invwarp=${out_dir}/warps/${out_prefix}InvDef.nii.gz
        cmd="antsApplyTransforms -d 3 -i ${in_tmp} -r ${in_img} -n ${interp} -o ${out_tmp} -t ${def_invwarp}"
    fi

    echo; echo "Running: $cmd"
    $cmd

done

if [ "${flag_del_tmp}" == 'yes' ]; then
    echo; echo "Deleting temporary folders ..."

    rm -rf ${out_dir}/warps
    echo; echo "Removed temp folder: ${out_dir}/warps"
    
    rm -rf ${out_dir}/init
    echo; echo "Removed temp folder: ${out_dir}/init"
    
    rm -rf ${out_dir}/labels
    echo; echo "Removed temp folder: ${out_dir}/labels"

    rm -rf ${out_dir}/encoded
    echo; echo "Removed temp folder: ${out_dir}/encoded"

fi

