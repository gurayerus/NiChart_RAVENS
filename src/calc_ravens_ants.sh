#!/usr/bin/bash
#
# ==========================================================
# Script: calc_ravens_ants.sh
# Purpose: Compute tissue density maps (RAVENS maps) using ANTs
# Author: Guray Erus
# Date: 2025-08-25
# ==========================================================
#
# Description:
#   This script calculates RAVENS maps by warping a in_img image 
#   into template space using ANTs and applying the corresponding 
#   transformations to segmentation masks. The tissue density maps 
#   reflect local volumetric changes across subjects.
#
# Requirements:
#   - ANTs (>=2.0)
#   - bash
#
# Usage:
#   See usage
#
# ==========================================================

# Set number of threads for speed
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=4

usage() {
  echo "Usage: $0 --in_img <in_img_file> --in_seg <in_seg_img> --labels <string> --template <template> --out_dir <output_dir> --out_prefix <output_prefix> [--reg_mode <string>]  [--flag_invert <string>] [--label_dict <string>] [--flag_del_warps <string>]"
  echo
  echo "Required:"
  echo "  --in_img   Source image file (absolute path)"
  echo "  --in_seg     Label image file (absolute path)"
  echo "  --labels     Labels used for output RAVENS (default: All in_seg values other than 0)"
  echo "  --template   Target image file (absolute path)"
  echo "  --out_dir     Output folder (absolute path)"
  echo "  --out_prefix Output prefix"
  echo
  echo "Optional:"
  echo "  --reg_mode   Registration reg_mode (default: default)"
  echo "  --flag_invert Invert image intensities (default: no)"
  echo "  --label_dict Label dictionary to convert labels to indices (default: None)"
  echo "  --icv_mask   Mask for calculating ICV for correction (default: None)"
  echo "  --flag_del_warps  Flag to delete warps (default: no)"
  echo
  exit 1
}

# Default values for optional arguments
reg_mode='default'
label_dict='none'
icv_mask='none'
flag_invert='no'
flag_del_warps='no'

# parse options with getopt
OPTS=$(getopt -o "" -l in_img:,in_seg:,labels:,template:,out_dir:,out_prefix:,reg_mode:,label_dict:,icv_mask:,flag_invert:,flag_del_warps:,help -n "$0" -- "$@")

if [ $? != 0 ]; then usage; fi

eval set -- "$OPTS"

while true; do
  case "$1" in
    --in_img ) in_img="$2"; shift 2 ;;
    --in_seg )  in_seg="$2"; shift 2 ;;
    --labels ) labels="$2"; shift 2 ;;
    --template ) template="$2"; shift 2 ;;
    --out_dir ) out_dir="$2"; shift 2 ;;
    --out_prefix ) prefix="$2"; shift 2 ;;
    --reg_mode )   reg_mode="$2"; shift 2 ;;
    --label_dict ) label_dict="$2"; shift 2 ;;
    --icv_mask ) icv_mask="$2"; shift 2 ;;
    --flag_invert ) flag_invert="$2"; shift 2 ;;
    --flag_del_warps ) flag_del_warps="$2"; shift 2 ;;
    --help ) usage ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

# sanity check: required args
if [[ -z "$in_img" || -z "$in_seg" || -z "$labels" || -z "$template" || -z "$out_dir" || -z "$prefix" ]]; then
  echo "Error: missing required arguments."
  usage
fi

# Print parsed arguments (for testing/debugging)
echo "Source image:        $in_img"
echo "Label image:         $in_seg"
echo "Labels:              $labels"
echo "Template image:      $template"
echo "Output directory:    $out_dir"
echo "Output prefix:       $prefix"
echo "Registration mode :  $reg_mode"
echo "Label dictionary:    $label_dict"
echo "Invert image intensities: $flag_invert"
echo "Delete warps: $flag_del_warps"
echo "ICV mask:             $icv_mask"

# Create output directory if missing
mkdir -p "$out_dir"

# Check that input files exist
for f in "$in_img" "$template" "$in_seg"; do
  if [ ! -f "$f" ]; then
    echo "Error: Input file does not exist: $f" >&2
    exit 1
  fi
done

# Create a folder with init images
init_dir="${out_dir}/init"
mkdir -p "$init_dir"
if [ ! -e ${init_dir}/${prefix}T1.nii.gz ]; then
    ln -s $in_img ${init_dir}/${prefix}T1.nii.gz
fi
if [ ! -e ${init_dir}/${prefix}Labels.nii.gz ]; then
    ln -s $in_seg ${init_dir}/${prefix}Labels.nii.gz
fi
if [ ! -e ${init_dir}/Template.nii.gz ]; then
    ln -s $template ${init_dir}/Template.nii.gz
fi

# Create a mask image for each label
label_dir="${out_dir}/labels"
mkdir -p "$label_dir"
if [ -e ${label_dir}/${prefix}Label_List.csv ]; then
    echo; echo "Label masks exists, skip calculation!"
else
    cmd="python3 utils/util_create_label_masks.py ${in_seg} ${labels} ${label_dir}/${prefix}Label_"
    if [ ${label_dict} != 'none' ]; then
        cmd="${cmd} --label_dict ${label_dict}"
    fi
    echo; echo "Running: $cmd"
    $cmd
fi

# Invert image intensities
if [ "${flag_invert}" == 'yes' ]; then
    final_inv=${init_dir}/${prefix}Inv.nii.gz
    cmd="python3 utils/util_invert_img.py ${in_img} ${final_inv}"
    echo; echo "Running: $cmd"
    $cmd
    in_img=${final_inv}
fi

# Source ants utils
source ./utils/util_ants.sh

# Apply ANTs
warp_dir="${out_dir}/warps"
mkdir -p "$warp_dir"
final_warped=${warp_dir}/${prefix}Warped.nii.gz
final_warp=${warp_dir}/${prefix}1Warp.nii.gz
final_invwarp=${warp_dir}/${prefix}1InverseWarp.nii.gz
final_affine=${warp_dir}/${prefix}0GenericAffine.mat
if [ -e ${final_warped} ] && [ -e ${final_warp} ] && [ -e ${final_invwarp} ] && [ -e ${final_affine} ]; then
    echo; echo "ANTs results exist, skip ANTs registration!"
else
    ants_reg ${reg_mode} ${template} ${in_img} ${warp_dir}/${prefix}
fi

# Move warped image to out folder
mv ${final_warped} ${out_dir}

# Calculate deformation
final_def=${warp_dir}/${prefix}Def.nii.gz
if [ -e ${final_def} ]; then
    echo; echo "Deformation exists, skip ANTs registration!"
else
    ants_compose ${final_warp} ${final_affine} ${template} ${final_def}
fi

# Create jacobian
final_jac=${warp_dir}/${prefix}Jacobian.nii.gz
if [ -e ${final_jac} ]; then
    echo; echo "Jacobian exists, skip calculation!"
else
    ants_calc_jacdet ${final_def} ${final_jac}
fi

# Warp in_seg masks
interp='Linear'
for label in $(cat ${label_dir}/${prefix}Label_List.csv); do
    img_in=${label_dir}/${prefix}Label_${label}.nii.gz
    img_out=${label_dir}/${prefix}Label_${label}_warped.nii.gz
    if [ -e ${img_out} ]; then
        echo; echo "Warped label ${label} exists, skip calculation!"
    else
        ants_apply ${img_in} ${final_def} ${template} ${interp} ${img_out}
    fi
done

# Calculate RAVENS
echo; echo "Calculate RAVENS"
interp='Linear'
for label in $(cat ${label_dir}/${prefix}Label_List.csv); do
    img_in=${label_dir}/${prefix}Label_${label}_warped.nii.gz
    img_out=${out_dir}/${prefix}Label_${label}_RAVENS.nii.gz
    if [ -e ${img_out} ]; then
        echo; echo "RAVENS map for label ${label} exists, skip calculation!"
    else
        python3 utils/util_multiply_images.py ${img_in} ${final_jac} ${img_out}
    fi
done

# Correct ICV
echo; echo "Correct ICV"
if [ ${icv_mask} != 'none' ]; then
    for label in $(cat ${label_dir}/${prefix}Label_List.csv); do
        img_in=${out_dir}/${prefix}Label_${label}_RAVENS.nii.gz
        img_out=${out_dir}/${prefix}Label_${label}_RAVENS_ICVNorm.nii.gz
        if [ -e ${img_out} ]; then
            echo; echo "ICV corrected RAVENS map for label ${label} exists, skip calculation!"
        else
            python3 utils/util_corr_icv.py ${img_in} ${icv_mask} ${img_out}
        fi
    done
fi


echo ${flag_del_warps}

if [ "${flag_del_warps}" == 'yes' ]; then
    echo; echo "Delete Warps"
    rm -rf ${warp_dir}
    echo "Removed folder: ${warp_dir}"
fi
