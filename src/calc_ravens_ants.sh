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

# Set number of threads for speed
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=4

# Source ants utils
source ./utils/util_ants.sh

usage() {
  echo "Usage: $0 --source <source_file> --label <labelabel> --target <targetarget> --outdir <output_dir> --prefix <output_prefix> [--mode <string>] [--labels <string>] [--invert <string>] [--factor <int>]"
  echo
  echo "Required:"
  echo "  --source    Source image file (absolute path)"
  echo "  --label     Label image file (absolute path)"
  echo "  --target    Target image file (absolute path)"
  echo "  --outdir    Output folder (absolute path)"
  echo "  --prefix    Output prefix"
  echo
  echo "Optional:"
  echo "  --mode      Registration mode (default: default)"
  echo "  --labels    Labels used for output RAVENS (default: All label values other than 0)"
  echo "  --invert    Invert image intensities (default: no)"
  echo "  --factor    Scaling factor (default: 1000)"
  echo
  exit 1
}

# Default values for optional arguments
mode="default"
labels="auto"
invert="no"
factor=1000

# parse options with getopt
OPTS=$(getopt -o s:l:t:d:p:m:i:n:f: \
              -l source:,label:,target:,outdir:,prefix:,mode:,labels:,invert:,factor:,help \
              -n "$0" -- "$@")

if [ $? != 0 ]; then usage; fi

eval set -- "$OPTS"

while true; do
  case "$1" in
    -s | --source ) source="$2"; shift 2 ;;
    -l | --label )  label="$2"; shift 2 ;;
    -t | --target ) target="$2"; shift 2 ;;
    -d | --outdir ) outdir="$2"; shift 2 ;;
    -p | --prefix ) prefix="$2"; shift 2 ;;
    -m | --mode )   mode="$2"; shift 2 ;;
    -i | --labels ) labels="$2"; shift 2 ;;
    -n | --invert ) invert="$2"; shift 2 ;;
    -f | --factor ) factor="$2"; shift 2 ;;
    --help ) usage ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

# sanity check: required args
if [ -z "$source" ] || [ -z "$label" ] || [ -z "$target" ] || [ -z "$outdir" ] || [ -z "$prefix" ]; then
  echo "Error: missing required arguments."
  usage
fi

echo "Source: $source"
echo "Label: $label"
echo "Target: $target"
echo "Outdir: $outdir"
echo "Prefix: $prefix"
echo "Mode: $mode"
echo "Labels: $labels"
echo "Invert: $invert"
echo "Factor: $factor"

# Create output directory if missing
mkdir -p "$outdir"

# Create a temporary folder inside output dir
tmp_dir=$(mktemp -d "${outdir}/tmp_XXXXXX")
mkdir -p "$tmp_dir"

# Set prefix for outputs
tmp_pref=${tmp_dir}/${prefix}
prefix=${outdir}/${prefix}

# Print parsed arguments (for testing/debugging)
echo "Source image:        $source"
echo "Label image:         $label"
echo "Target image:        $target"
echo "Output directory:    $outdir"
echo "Output prefix:       $prefix"
echo "Registration mode (-m): $mode"
echo "Labels (-i):    $labels"
echo "Invert image intensities (-n): $invert"
echo "Scaling factor (-f): $factor"

# Check that input files exist
for f in "$source" "$target" "$label"; do
  if [ ! -f "$f" ]; then
    echo "Error: Input file does not exist: $f" >&2
    exit 1
  fi
done

# Create a mask image for each label
out_mask_pref=${tmp_pref}Label_
if [ -e ${out_mask_pref}List.csv ]; then
    echo; echo "Label masks exists, skip calculation!"
else
    cmd="python3 utils/util_create_label_masks.py ${label} ${out_mask_pref} --labels ${labels}"
    echo; echo "Running: $cmd"
    $cmd
fi

# Invert image intensities
if [ "${invert}" == 'yes' ]; then
    final_inv=${prefix}Inv.nii.gz
    cmd="python3 utils/util_invert_img.py ${source} ${final_inv}"
    echo; echo "Running: $cmd"
    $cmd
    source=${final_inv}
fi

# Apply ANTs
final_warped=${prefix}Warped.nii.gz
final_warp=${prefix}1Warp.nii.gz
final_invwarp=${prefix}1InverseWarp.nii.gz
final_affine=${prefix}0GenericAffine.mat
if [ -e ${final_warped} ] && [ -e ${final_warp} ] && [ -e ${final_invwarp} ] && [ -e ${final_affine} ]; then
    echo; echo "ANTs results exist, skip ANTs registration!"
else
    # Calculate ANTS registration
    ants_reg ${mode} ${target} ${source} ${tmp_pref}

    # Move final results from tmp
    mv ${tmp_pref}Warped.nii.gz ${final_warped}
    mv ${tmp_pref}1Warp.nii.gz ${final_warp}
    mv ${tmp_pref}1InverseWarp.nii.gz ${final_invwarp}
    mv ${tmp_pref}0GenericAffine.mat ${final_affine}
fi

# Calculate deformation
final_def=${prefix}Def.nii.gz
if [ -e ${final_def} ]; then
    echo; echo "Deformation exists, skip ANTs registration!"
else
    ants_compose ${final_warp} ${final_affine} ${target} ${final_def}
fi

# Create jacobian
final_jac=${prefix}Jacobian.nii.gz
if [ -e ${final_jac} ]; then
    echo; echo "Jacobian exists, skip calculation!"
else
    ants_calc_jacdet ${final_def} ${final_jac}
fi

# Warp label masks
interp='Linear'
for label in $(cat ${out_mask_pref}List.csv); do
    label_in=${out_mask_pref}${label}.nii.gz
    label_out=${out_mask_pref}${label}_warped.nii.gz
    if [ -e ${label_out} ]; then
        echo; echo "Warped label ${label} exists, skip calculation!"
    else
        ants_apply ${label_in} ${final_def} ${target} ${interp} ${label_out}
    fi
done

# Calculate RAVENS
interp='Linear'
for label in $(cat ${out_mask_pref}List.csv); do
    label_in=${out_mask_pref}${label}_warped.nii.gz
    label_out=${prefix}Label_${label}_RAVENS.nii.gz
    if [ -e ${label_out} ]; then
        echo; echo "RAVENS map for label ${label} exists, skip calculation!"
    else
        python3 utils/util_multiply_images.py ${label_in} ${final_jac} ${label_out}
    fi
done

# Warp RAVENS back to subj space
interp='Linear'
for label in $(cat ${out_mask_pref}List.csv); do
    map_in=${prefix}Label_${label}_RAVENS.nii.gz
    map_out=${prefix}Label_${label}_RAVENS_InSubj.nii.gz
    if [ -e ${map_out} ]; then
        echo; echo "RAVENS map in subject space for label ${label} exists, skip calculation!"
    else
        ants_apply_inv ${map_in} ${source} ${final_invwarp} ${final_affine} ${map_out} ${interp}
    fi
done

