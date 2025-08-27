#!/usr/bin/bash
#
# ==========================================================
# Script: calc_abnmap_ants.sh
# Purpose: Calculate abnormality map and warp it to subject space using ANTs
# Author: Guray Erus
# Date: 2025-08-25
# ==========================================================
#
# Description:
#   This script uses input RAVENS maps  and a set of reference maps to calculate a statistical map
#   It warps the final map to subject space
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
# Calculate a statistical map and warp it from atlas space to subject space
# using ANTs' antsApplyTransforms.
#
# Example:
#   ./calc_abnmap_ants.sh -m atlas_map.nii.gz -i subj_T1.nii.gz \
#                     -t warp.nii.gz -t affine.mat \
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
    echo "  -m   Statistical map in atlas space"
    echo "  -i   Subject T1 image in subject space"
    echo "  -t   Transform(s) from atlas->subject (can be given multiple times, in order)"
    echo "  -o   Output statistical map in subject space"
    echo
    echo "Optional arguments:"
    echo "  -n   Interpolation method (default: Linear, use NearestNeighbor for labels)"
    echo "  -h   Show this help"
    exit 1
}

while getopts "m:i:t:o:n:h" opt; do
  case $opt in
    m) in_map=$OPTARG ;;
    i) in_img=$OPTARG ;;
    t) transforms+=("$OPTARG") ;;
    o) out_map=$OPTARG ;;
    n) interp=$OPTARG ;;
    h) usage ;;
    *) usage ;;
  esac
done

# ---------------------------
# Check required args
# ---------------------------
if [ -z "${in_map:-}" ] || [ -z "${in_img:-}" ] || [ ${#transforms[@]} -eq 0 ] || [ -z "${out_map:-}" ]; then
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
     -o "${out_map}")

# Append transforms (order matters!)
for t in "${transforms[@]}"; do
    cmd+=(-t "$t")
done

# ---------------------------
# Run
# ---------------------------
echo "Running: ${cmd[*]}"
"${cmd[@]}"
