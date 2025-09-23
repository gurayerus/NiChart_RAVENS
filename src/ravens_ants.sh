#!/usr/bin/bash
#
# ==========================================================
# Script: ravens_ants.sh
# Purpose: Compute tissue density maps (RAVENS maps) using ANTs
# Author: Guray Erus
# Date: 2025-08-25
# ==========================================================
#
# Description:
#   This script calculates RAVENS maps by warping a source image 
#   into target space using ANTs and applying the corresponding 
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

# Default values for optional arguments
m_val="minimal"
n_val="no"
f_val=1000

# Usage message
usage() {
  echo "Usage: $0 -s <source_file> -l <label_file> -t <target_file> -d <output_dir> -p <output_prefix> [-m <string>] [-i <string>] [-n <string>] [-f <int>]"
  echo
  echo "Required:"
  echo "  -s   Source image file (absolute path)"
  echo "  -l   Label image file (absolute path)"
  echo "  -t   Target image file (absolute path)"
  echo "  -d   Output folder (absolute path)"
  echo "  -p   Output prefix"
  echo
  echo "Optional:"
  echo "  -m   Registration mode (default: default)"
  echo "  -i   Labels used for output RAVENS (default: All label values other than 0)"
  echo "  -n   Invert image intensities (default: no)"
  echo "  -f   Scaling factor (default: 1000)"

  echo "Example:"
  echo "ravens_ants.sh -s subj01_T1.nii.gz -l subj01_labels.nii.gz\\"
  echo " -t template.nii.gz -d ravens_out -r subj01_"

  echo "Notes:"
  echo " - All input files should be in NIfTI format (.nii or .nii.gz)."
  echo " - The script creates a temporary working directory in the output folder."
  exit 1
}

# Set number of threads for speed
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=4

# Source ants utils
source ./utils/util_ants.sh

##############################################
# Parse options
while getopts ":s:l:t:d:p:m:i:n:f:" opt; do
  case ${opt} in
    s ) s_file=$OPTARG ;;
    l ) l_file=$OPTARG ;;
    t ) t_file=$OPTARG ;;
    d ) out_dir=$OPTARG ;;
    p ) out_pref=$OPTARG ;;
    m ) m_val=$OPTARG ;;
    i ) i_val=$OPTARG ;;
    n ) n_val=$OPTARG ;;
    f ) f_val=$OPTARG ;;
    \? ) echo "Invalid option: -$OPTARG" >&2; usage ;;
    : ) echo "Option -$OPTARG requires an argument." >&2; usage ;;
  esac
done

# Check for required arguments
if [ -z "$s_file" ] || [ -z "$l_file" ] || [ -z "$t_file" ] || [ -z "$out_dir" ] || [ -z "$out_pref" ]; then
  echo "Error: Missing required arguments." >&2
  usage
fi

# Create output directory if missing
mkdir -p "$out_dir"

# Create a temporary folder inside output dir
tmp_dir=$(mktemp -d "${out_dir}/tmp_XXXXXX")
mkdir -p "$tmp_dir"

# Set prefix for outputs
tmp_pref=${tmp_dir}/${out_pref}
out_pref=${out_dir}/${out_pref}

i_val=1

# Print parsed arguments (for testing/debugging)
echo "Source image:        $s_file"
echo "Label image:         $l_file"
echo "Target image:        $t_file"
echo "Output directory:    $out_dir"
echo "Output prefix:       $out_pref"
echo "Registration mode (-m): $m_val"
echo "Intensities (-i):    $i_val"
echo "Invert image intensities (-n): $n_val"
echo "Scaling factor (-f): $f_val"

# Check that input files exist
for f in "$s_file" "$t_file" "$l_file"; do
  if [ ! -f "$f" ]; then
    echo "Error: Input file does not exist: $f" >&2
    exit 1
  fi
done

# Invert image intensities
if [ "${n_val}" == 'yes' ]; then
    final_inv=${out_pref}Inv.nii.gz
    cmd="python3 utils/util_invert_img.py ${s_file} ${final_inv}"
    echo; echo "Running: $cmd"
    $cmd
    s_file=${final_inv}
fi

# Apply ANTs
final_warped=${out_pref}Warped.nii.gz
final_warp=${out_pref}1Warp.nii.gz
final_invwarp=${out_pref}1InverseWarp.nii.gz
final_affine=${out_pref}0GenericAffine.mat
if [ -e ${final_warped} ] && [ -e ${final_warp} ] && [ -e ${final_invwarp} ] && [ -e ${final_affine} ]; then
    echo; echo "ANTs results exist, skip ANTs registration!"
else
    # Calculate ANTS registration
    ants_reg ${m_val} ${t_file} ${s_file} ${tmp_pref}

    # Move final results from tmp
    mv ${tmp_pref}Warped.nii.gz ${final_warped}
    mv ${tmp_pref}1Warp.nii.gz ${final_warp}
    mv ${tmp_pref}1InverseWarp.nii.gz ${final_invwarp}
    mv ${tmp_pref}0GenericAffine.mat ${final_affine}
fi

# Calculate deformation
final_def=${out_pref}Def.nii.gz
if [ -e ${final_def} ]; then
    echo; echo "Deformation exists, skip ANTs registration!"
else
    ants_compose ${final_warp} ${final_affine} ${t_file} ${final_def}
fi

# Create jacobian
final_jac=${out_pref}Jacobian.nii.gz
if [ -e ${final_jac} ]; then
    echo; echo "Jacobian exists, skip calculation!"
else
    ants_calc_jacdet ${final_def} ${final_jac}
fi

# Create a mask image for each label
out_mask_pref=${tmp_pref}Label_
if [ -e ${out_mask_pref}List.csv ]; then
    echo; echo "Label masks exists, skip calculation!"
else
    cmd="python3 utils/util_create_label_masks.py ${l_file} ${out_mask_pref}"
    echo; echo "Running: $cmd"
    $cmd
fi

# Warp label masks
interp='Linear'
for label in $(cat ${out_mask_pref}List.csv); do
    label_in=${out_mask_pref}${label}.nii.gz
    label_out=${out_mask_pref}${label}_warped.nii.gz
    if [ -e ${label_out} ]; then
        echo; echo "Warped label ${label} exists, skip calculation!"
    else
        ants_apply ${label_in} ${final_def} ${t_file} ${interp} ${label_out}
    fi
done

# Calculate RAVENS
interp='Linear'
for label in $(cat ${out_mask_pref}List.csv); do
    label_in=${out_mask_pref}${label}_warped.nii.gz
    label_out=${out_pref}Label_${label}_RAVENS.nii.gz
    if [ -e ${label_out} ]; then
        echo; echo "RAVENS map for label ${label} exists, skip calculation!"
    else
        python3 utils/util_multiply_images.py ${label_in} ${final_jac} ${label_out}
    fi
done

# Warp RAVENS back to subj space
interp='Linear'
for label in $(cat ${out_mask_pref}List.csv); do
    map_in=${out_pref}Label_${label}_RAVENS.nii.gz
    map_out=${out_pref}Label_${label}_RAVENS_InSubj.nii.gz
    if [ -e ${map_out} ]; then
        echo; echo "RAVENS map in subject space for label ${label} exists, skip calculation!"
    else
        ants_apply_inv ${map_in} ${s_file} ${final_invwarp} ${final_affine} ${map_out} ${interp}

#         cmd="utils/util_warp_to_subj.sh -m ${map_in} -i ${s_file} -w ${final_invwarp} -t ${final_affine} -o ${map_out}"
#         echo; echo "Running: $cmd"
#         $cmd
    fi
done

