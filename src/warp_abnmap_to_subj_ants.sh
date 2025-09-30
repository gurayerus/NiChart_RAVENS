#!/usr/bin/bash
#
# ==========================================================
# Script: warp_abnmap_to_subj_ants.sh
# Purpose: Warp maps to subj space using ants
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
  echo "Usage: $0 --in_img <input_image> --target <target_image> --in_warp <warp_field> --in_affine <affine_transform> --out_img <output_image> [--interp <method>]"
  echo
  echo "Required arguments:"
  echo "  --in_img     Path to input image"
  echo "  --target     Path to target image (reference)"
  echo "  --in_warp    Path to nonlinear warp field"
  echo "  --in_affine  Path to affine transform"
  echo "  --out_img    Path for output warped image"
  echo
  echo "Optional arguments:"
  echo "  --interp     Interpolation method: linear, nearest, cubic, sinc (default: linear)"
  exit 1
}

# Default values
interp="linear"

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --in_img) in_img="$2"; shift 2;;
    --target) target="$2"; shift 2;;
    --in_warp) in_warp="$2"; shift 2;;
    --in_affine) in_affine="$2"; shift 2;;
    --out_img) out_img="$2"; shift 2;;
    --interp) interp="$2"; shift 2;;
    -h|--help) usage;;
    *) echo "Unknown option: $1"; usage;;
  esac
done

# Check required args
if [[ -z "$in_img" || -z "$target" || -z "$in_warp" || -z "$in_affine" || -z "$out_img" ]]; then
  echo "Error: Missing required arguments."
  usage
fi

# Ensure output directory exists
out_dir=$(dirname "$out_img")
mkdir -p "$out_dir"

# ---- Example warp command (replace with actual ANTs/FSL/etc.) ----
echo "Warping image..."
echo " Input image:     $in_img"
echo " Target image:    $target"
echo " Warp field:      $in_warp"
echo " Affine:          $in_affine"
echo " Output image:    $out_img"
echo " Interpolation:   $interp"

ants_apply_inv ${in_img} ${target} ${in_warp} ${in_affine} ${out_img} ${interp}

