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
  echo "Usage: $0 --source <source_file> --label <labelabel> --target <targetarget> --outdir <output_dir> --prefix <output_prefix> [--mode <string>]  [--invert <string>] [--labels <string>] [--labeldict <string>]"
  echo
  echo "Required:"
  echo "  --source    Source image file (absolute path)"
  echo "  --label     Label image file (absolute path)"
  echo "  --target    Target image file (absolute path)"
  echo "  --outdir    Output folder (absolute path)"
  echo "  --prefix    Output prefix"
  echo "  --mode      Registration mode (default: default)"
  echo "  --invert    Invert image intensities (default: no)"
  echo
  echo "Optional:"
  echo "  --labels    Labels used for output RAVENS (default: All label values other than 0)"
  echo "  --labeldict Label dictionary to convert labels to indices (default: None)"
  echo
  exit 1
}

# Default values for optional arguments
labels="none"
labeldict="none"

# parse options with getopt
OPTS=$(getopt -o "" -l source:,label:,target:,outdir:,prefix:,mode:,invert:,labels:,labeldict:,help \
              -n "$0" -- "$@")

if [ $? != 0 ]; then usage; fi

eval set -- "$OPTS"

while true; do
  case "$1" in
    --source ) source="$2"; shift 2 ;;
    --label )  label="$2"; shift 2 ;;
    --target ) target="$2"; shift 2 ;;
    --outdir ) outdir="$2"; shift 2 ;;
    --prefix ) prefix="$2"; shift 2 ;;
    --mode )   mode="$2"; shift 2 ;;
    --labels ) labels="$2"; shift 2 ;;
    --labeldict ) labeldict="$2"; shift 2 ;;
    --invert ) invert="$2"; shift 2 ;;
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

# Print parsed arguments (for testing/debugging)
echo "Source image:        $source"
echo "Label image:         $label"
echo "Target image:        $target"
echo "Output directory:    $outdir"
echo "Output prefix:       $prefix"
echo "Registration mode : $mode"
echo "Labels:    $labels"
echo "Label dictionary:    $labeldict"
echo "Invert image intensities: $invert"

# Create output directory if missing
mkdir -p "$outdir"

# Check that input files exist
for f in "$source" "$target" "$label"; do
  if [ ! -f "$f" ]; then
    echo "Error: Input file does not exist: $f" >&2
    exit 1
  fi
done

# Create a folder with init images
init_dir="${outdir}/init"
mkdir -p "$init_dir"
if [ ! -e ${init_dir}/${prefix}T1.nii.gz ]; then
    ln -s $source ${init_dir}/${prefix}T1.nii.gz
fi
if [ ! -e ${init_dir}/${prefix}Labels.nii.gz ]; then
    ln -s $label ${init_dir}/${prefix}Labels.nii.gz
fi
if [ ! -e ${init_dir}/Template.nii.gz ]; then
    ln -s $target ${init_dir}/Template.nii.gz
fi

# Create a mask image for each label
label_dir="${outdir}/labels"
mkdir -p "$label_dir"
if [ -e ${label_dir}/${prefix}Label_List.csv ]; then
    echo; echo "Label masks exists, skip calculation!"
else
    cmd="python3 utils/util_create_label_masks.py ${label} ${label_dir}/${prefix}Label_"
    if [ ${labels} != 'none' ]; then
        cmd="${cmd} --labels ${labels}"
    fi
    if [ ${labeldict} != 'none' ]; then
        cmd="${cmd} --labeldict ${labeldict}"
    fi
    echo; echo "Running: $cmd"
    $cmd
fi

# Invert image intensities
if [ "${invert}" == 'yes' ]; then
    final_inv=${init_dir}/${prefix}Inv.nii.gz
    cmd="python3 utils/util_invert_img.py ${source} ${final_inv}"
    echo; echo "Running: $cmd"
    $cmd
    source=${final_inv}
fi

# Apply ANTs
warp_dir="${outdir}/warps"
mkdir -p "$warp_dir"
final_warped=${warp_dir}/${prefix}Warped.nii.gz
final_warp=${warp_dir}/${prefix}1Warp.nii.gz
final_invwarp=${warp_dir}/${prefix}1InverseWarp.nii.gz
final_affine=${warp_dir}/${prefix}0GenericAffine.mat
if [ -e ${final_warped} ] && [ -e ${final_warp} ] && [ -e ${final_invwarp} ] && [ -e ${final_affine} ]; then
    echo; echo "ANTs results exist, skip ANTs registration!"
else
    ants_reg ${mode} ${target} ${source} ${warp_dir}/${prefix}
fi

# Calculate deformation
final_def=${warp_dir}/${prefix}Def.nii.gz
if [ -e ${final_def} ]; then
    echo; echo "Deformation exists, skip ANTs registration!"
else
    ants_compose ${final_warp} ${final_affine} ${target} ${final_def}
fi

# Create jacobian
final_jac=${warp_dir}/${prefix}Jacobian.nii.gz
if [ -e ${final_jac} ]; then
    echo; echo "Jacobian exists, skip calculation!"
else
    ants_calc_jacdet ${final_def} ${final_jac}
fi

# Warp label masks
interp='Linear'
for label in $(cat ${label_dir}/${prefix}Label_List.csv); do
    label_in=${label_dir}/${prefix}Label_${label}.nii.gz
    label_out=${label_dir}/${prefix}Label_${label}_warped.nii.gz
    if [ -e ${label_out} ]; then
        echo; echo "Warped label ${label} exists, skip calculation!"
    else
        ants_apply ${label_in} ${final_def} ${target} ${interp} ${label_out}
    fi
done

# Calculate RAVENS
interp='Linear'
for label in $(cat ${label_dir}/${prefix}Label_List.csv); do
    label_in=${label_dir}/${prefix}Label_${label}_warped.nii.gz
    label_out=${outdir}/${prefix}Label_${label}_RAVENS.nii.gz
    if [ -e ${label_out} ]; then
        echo; echo "RAVENS map for label ${label} exists, skip calculation!"
    else
        python3 utils/util_multiply_images.py ${label_in} ${final_jac} ${label_out}
    fi
done

# Warp RAVENS back to subj space
interp='Linear'
for label in $(cat ${label_dir}/${prefix}Label_List.csv); do
    label_in=${outdir}/${prefix}Label_${label}_RAVENS.nii.gz
    label_out=${outdir}/${prefix}Label_${label}_RAVENS_InSubj.nii.gz
    if [ -e ${label_out} ]; then
        echo; echo "RAVENS map in subject space for label ${label} exists, skip calculation!"
    else
        ants_apply_inv ${label_in} ${source} ${final_invwarp} ${final_affine} ${label_out} ${interp}
    fi
done

