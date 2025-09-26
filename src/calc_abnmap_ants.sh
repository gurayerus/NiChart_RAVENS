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
    echo "Usage: $0 -m <in_map> -i <in_img> -t <transform> [-t <transform> ...] -r <ref_dir> -o <out_dir>"
    echo
    echo "Required arguments:"
    echo "  -m   Statistical map in atlas space"
    echo "  -i   Subject T1 image in subject space"
    echo "  -t   Transform(s) from atlas->subject (can be given multiple times, in order)"
    echo "  -r   Ref dir"
    echo "  -o   Output dir"
    echo
    echo "Optional arguments:"
    echo "  -h   Show this help"
    exit 1
}

while getopts "m:i:t:r:o:h" opt; do
  case $opt in
    m) in_map=$OPTARG ;;
    i) in_img=$OPTARG ;;
    t) transforms+=("$OPTARG") ;;
    r) ref_dir=$OPTARG ;;
    o) out_dir=$OPTARG ;;
    h) usage ;;
    *) usage ;;
  esac
done

# ---------------------------
# Check required args
# ---------------------------
if [ -z "${in_map:-}" ] || [ -z "${in_img:-}" ] || [ ${#transforms[@]} -eq 0 ] || [ -z "${ref_dir:-}" ] || [ -z "${out_dir:-}" ]; then
    echo "Error: Missing required argument(s)."
    usage
fi

mkdir -pv ${out_dir}

params=${ref_dir}/params.json

# ---------------------------
# Encode input ravens
out_encoded=${out_dir}/ravens_encoded.npz
if [ -e ${out_encoded} ]; then
    echo; echo "Encoded img exists, skip calculation!"
else
    cmd="python3 utils/util_encode_ravens.py ${in_map} ${params} ${out_encoded}"
    echo; echo "Running: $cmd"
    $cmd
fi

# ---------------------------
# Apply z-score
out_zscore=${out_dir}/ravens_zscore.npz
age=62
sex=F
if [ -e ${out_zscore} ]; then
    echo; echo "Zscore img exists, skip calculation!"
else
    cmd="python3 utils/util_zscore_ravens.py --inmap ${out_encoded} --age $age --sex $sex --ref_dir ${ref_dir} --out_file ${out_zscore}"
    echo; echo "Running: $cmd"
    $cmd
fi

# ---------------------------
# Decode z-score map
out_decoded=${out_dir}/ravens_zscore_decoded.nii.gz
if [ -e ${out_decoded} ]; then
    echo; echo "Decoded img exists, skip calculation!"
else
    cmd="python3 utils/util_decode_ravens.py ${out_zscore} ${params} ${out_decoded} --in_field zmap"
    echo; echo "Running: $cmd"
    $cmd
fi

# # ---------------------------
# # Warp z-score map to subj space
# interp='Linear'
# map_in=${out_pref}Label_${label}_RAVENS.nii.gz
# map_out=${out_pref}Label_${label}_RAVENS_InSubj.nii.gz
# if [ -e ${map_out} ]; then
#     echo; echo "RAVENS map in subject space for label ${label} exists, skip calculation!"
# else
#     ants_apply_inv ${map_in} ${s_file} ${final_invwarp} ${final_affine} ${map_out} ${interp}
# fi
