#!/usr/bin/env bash

# -------------------------
# Usage function
# -------------------------
usage() {
  echo "Usage: $0 --in_img <file> --age <float> --sex <M/F> --icv <float> --ref_dir <dir> --out_img <file>"
  echo
  echo "Arguments:"
  echo "  --in_img     Input image file (NIfTI, encoded npz, etc.)"
  echo "  --age        Subject age (float)"
  echo "  --sex        Subject sex (M or F)"
  echo "  --icv        Intracranial volume (float)"
  echo "  --ref_dir    Reference directory with stats"
  echo "  --out_img    Output image filename"
  echo
  echo "Example:"
  echo "  $0 --in_img subj01_encoded.npz --age 62.5 --sex F --icv 1450 --ref_dir ./ref_stats --out_img subj01_abnmap.npz"
  exit 1
}

# -------------------------
# Parse arguments
# -------------------------
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --in_img) in_img="$2"; shift; shift ;;
    --age) age="$2"; shift; shift ;;
    --sex) sex="$2"; shift; shift ;;
    --icv) icv="$2"; shift; shift ;;
    --ref_dir) ref_dir="$2"; shift; shift ;;
    --out_img) out_img="$2"; shift; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

# -------------------------
# Check required arguments
# -------------------------
if [[ -z "$in_img" || -z "$age" || -z "$sex" || -z "$icv" || -z "$ref_dir" || -z "$out_img" ]]; then
  echo "Error: Missing required argument."
  usage
fi

params=${ref_dir}/params.json

out_dir=$(dirname "$out_img")
mkdir -p "$out_dir"

# ---------------------------
# Encode input ravens
out_encoded=${out_dir}/ravens_encoded.npz
if [ -e ${out_encoded} ]; then
    echo; echo "Encoded img exists, skip calculation!"
else
    cmd="python3 utils/util_encode_ravens.py ${in_img} ${params} ${out_encoded}"
    echo; echo "Running: $cmd"
    $cmd
fi

# ---------------------------
# Apply z-score
out_zscore=${out_dir}/ravens_zscore.npz
if [ -e ${out_zscore} ]; then
    echo; echo "Zscore img exists, skip calculation!"
else
    cmd="python3 utils/util_zscore_ravens.py --inmap ${out_encoded} --age $age --sex $sex --ref_dir ${ref_dir} --out_file ${out_zscore}"
    echo; echo "Running: $cmd"
    $cmd
fi

# ---------------------------
# Decode z-score map
if [ -e ${out_img} ]; then
    echo; echo "Decoded img exists, skip calculation!"
else
    cmd="python3 utils/util_decode_ravens.py ${out_zscore} ${params} ${out_img} --in_field zmap"
    echo; echo "Running: $cmd"
    $cmd
fi
