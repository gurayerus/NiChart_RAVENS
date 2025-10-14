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
  echo "  --dtype      Reference data type (npz or nifti)"
  echo "  --ref_list   List of reference data"
  echo "  --params     Parameters for encoding (only necessary for npz ref data)"
  echo "  --out_img    Output image filename"
  echo
  echo "Example:"
  echo "  $0 --in_img subj01_encoded.npz --age 62.5 --sex F --dtype npz --ref_list ./ref_stats/list_CSF.csv --params ./ref_stats/params.json --out_img subj01_abnmap.npz"
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
    --label) label="$2"; shift; shift ;;
    --dtype) dtype="$2"; shift; shift ;;
    --ref_list) ref_list="$2"; shift; shift ;;
    --params) params="$2"; shift; shift ;;
    --out_img) out_img="$2"; shift; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

# -------------------------
# Check required arguments
# -------------------------
if [[ -z "$in_img" || -z "$age" || -z "$sex" || -z "$dtype" || -z "$ref_list" || -z "$out_img" ]]; then
  echo "Error: Missing required argument."
  usage
fi

if [ "$dtype" == 'npz' ] && [ -z "$params" ]; then
  echo "Error: Missing required argument (params)."
  usage
fi

out_dir=$(dirname "$out_img")
mkdir -pv "$out_dir"

if [ "$dtype" == 'npz' ]; then

    # ---------------------------
    # Encode input ravens
    mkdir -pv "${out_dir}/encoded"
    out_encoded=${out_dir}/encoded/ravens_encoded.npz
    if [ -e ${out_encoded} ]; then
        echo; echo "Encoded img exists, skip calculation!"
    else
        cmd="python3 utils/util_encode_ravens.py ${in_img} ${params} ${out_encoded}"
        echo; echo "Running: $cmd"
        $cmd
    fi

    # ---------------------------
    # Apply z-score
    out_zscore=${out_dir}/encoded/ravens_zscore.npz
    if [ -e ${out_zscore} ]; then
        echo; echo "Zscore img exists, skip calculation!"
    else
        cmd="python3 utils/util_zscore_ravens.py --inmap ${out_encoded} --age $age --sex $sex --ref_list ${ref_list} --out_file ${out_zscore}"
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

else
    # ---------------------------
    # Apply z-score
    if [ -e ${out_img} ]; then
        echo; echo "Zscore img exists, skip calculation!"
    else
        cmd="python3 utils/util_zscore_ravens.py --inmap ${in_img} --age $age --sex $sex --ref_list ${ref_list} --out_file ${out_img}"
        echo; echo "Running: $cmd"
        $cmd
    fi
fi

