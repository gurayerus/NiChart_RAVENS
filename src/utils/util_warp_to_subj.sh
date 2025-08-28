#!/usr/bin/bash +x
#
# ==========================================================
# Script: util_warp_to_subj.sh
# Purpose: Warp map to subject space using ANTs
# Author: Guray Erus
# Date: 2025-08-25
# ==========================================================
#
# Description:
#   This script warps a map to subject space
#
# Requirements:
#   - ANTs (>=2.0)
#   - bash
#
# Usage:
#   See usage
#
# ==========================================================

#!/usr/bin/env bash
#
# Warp a map from atlas space to subject space
# using ANTs' antsApplyTransforms.
#
# Example:
#   ./util_warp_to_subj.sh -m atlas_map.nii.gz -i subj_T1.nii.gz \
#                     -w warp.nii.gz -t affine.mat \
#                     -o subj_map.nii.gz -n Linear
#

set -euo pipefail

# ---------------------------
# Default values
# ---------------------------
interp="Linear"   # default interpolation
transforms=()     # list of transforms

# ---------------------------
# Parse options
# ---------------------------
usage() {
    echo "Usage: $0 -m <in_map> -i <in_img> -t <transform> [-t <transform> ...] -o <out_map> [-n <interp>]"
    echo
    echo "Required arguments:"
    echo "  -m   Input map (e.g. statistical map) in atlas space"
    echo "  -i   Subject T1 image in subject space"
    echo "  -w   Inverse of the def. from subject->atlas"
    echo "  -t   Affine transform from subject->atlas (will be inverted when applied)"
    echo "  -o   Output map (statistical map in subject space)"
    echo
    echo "Optional arguments:"
    echo "  -n   Interpolation method (default: Linear, use NearestNeighbor for labels)"
    echo "  -h   Show this help"
    exit 1
}

while getopts "m:i:w:t:o:n:h" opt; do
  case $opt in
    m) in_map=$OPTARG ;;
    i) in_img=$OPTARG ;;
    w) in_warp=$OPTARG ;;
    t) in_affine=$OPTARG ;;
    o) out_map=$OPTARG ;;
    n) interp=$OPTARG ;;
    h) usage ;;
    *) usage ;;
  esac
done

# ---------------------------
# Check required args
# ---------------------------
if [ -z "${in_map:-}" ] || [ -z "${in_img:-}" ] || [ -z "${in_warp:-}" ] || [ -z "${in_affine:-}" ]; then
    echo "Error: Missing required argument(s)."
    usage
fi

# ---------------------------
# Build antsApplyTransforms command
# ---------------------------
cmd=(antsApplyTransforms -d 3
     -i "${in_map}"
     -r "${in_img}"
     -n "${interp}"
     -o "${out_map}"
     -t "[${in_affine},1]"
     -t "${in_warp}"     
    )

# ---------------------------
# Run
# ---------------------------
echo "Running: ${cmd[*]}"
"${cmd[@]}"
