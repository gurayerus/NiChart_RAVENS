#!/usr/bin/env python3
import os
import argparse
import json
import random
import nibabel as nib
import numpy as np
from scipy.ndimage import zoom
from pathlib import Path


def encode_map(in_file, params, out_file, out_field = 'imgvec'):
    """
    Encode a NIfTI image using provided parameters:
      - Crop to bounding box from params
      - Quantize values to uint16 using vmin/vmax
      - Downsample by the given factor
      - Save as a new NIfTI file

    Args:
        in_file (str): Input data file
        params (dict): Dictionary with keys:
            'bbox_min', 'bbox_max', 'vmin', 'vmax'
        out_file (str): Output NIfTI file path
        out_field (str): Field name        
    """    
    img = nib.load(in_file)
    data = img.get_fdata()
    #affine = img.affine

    # Crop using bounding box
    minc = np.array(params["bbox_min"])
    maxc = np.array(params["bbox_max"])
    cropped = data[minc[0]:maxc[0], minc[1]:maxc[1], minc[2]:maxc[2]]

    downsample = params["downsample"]

    # Downsample
    if isinstance(downsample, int):
        zoom_factors = [1/downsample] * 3
    else:
        zoom_factors = [1/f for f in downsample]
    cropped_ds = zoom(cropped, zoom_factors, order=1)  # linear interpolation

    # Quantize to uint16
    vmin = params["vmin"]
    vmax = params["vmax"]
    clipped = np.clip(cropped_ds, vmin, vmax)
    scaled = np.round((clipped - vmin) / (vmax - vmin) * 65535).astype(np.uint16)

    # Save
    imgvec = scaled.flatten()
    np.savez_compressed(out_file, **{out_field: imgvec})
    
    print(f"Encoded data saved to {out_file}")

def detect_params(files, out_file, downsample = 2, n_samples=50):
    """
    Detect parameters from a random subset of nifti files in indir.
    Saves params.json in outdir.
    """
    # Random subset
    sampled_files = random.sample(files, min(n_samples, len(files)))
    print(f"Sampling {len(sampled_files)} files for parameter detection")

    bboxes = []
    vmins = []
    vmaxs = []

    for f in sampled_files:
        print(f'File name is: {f}')
        img = nib.load(f)
        data = img.get_fdata()

        mask = data > 0
        if not np.any(mask):
            continue

        coords = np.array(np.where(mask))
        minc, maxc = coords.min(axis=1), coords.max(axis=1) + 1
        bboxes.append((minc, maxc))
        vmins.append(data[mask].min())
        vmaxs.append(data[mask].max())

    # Compute overall bbox (min of mins, max of maxs)
    all_mins = np.min([b[0] for b in bboxes], axis=0).tolist()
    all_maxs = np.max([b[1] for b in bboxes], axis=0).tolist()

    all_size = np.zeros(3).tolist()
    ds_size = np.zeros(3).tolist()

    # Ensure even size for each axis
    print(all_mins)
    print(all_maxs)
    for i in range(3):
        size = all_maxs[i] - all_mins[i]
        if size % 2 != 0:
            # Try to extend maxc by 1, but not beyond image size
            if all_maxs[i] < data.shape[i] - 1:
                all_maxs[i] = int(all_maxs[i] + 1)
            else:
                all_maxs[i] = int(all_maxs[i] - 1)
        else:
            all_maxs[i] = int(all_maxs[i])

        all_size[i] = all_maxs[i] - all_mins[i]
        ds_size[i] = round(all_size[i] / downsample)

    print(all_mins)
    print(all_maxs)

    # Global min/max
    global_vmin = float(np.min(vmins))
    global_vmax = float(np.max(vmaxs))

    params = {
        "img_shape": data.shape,
        "bbox_min": all_mins,
        "bbox_max": all_maxs,
        "bbox_size": all_size,
        "bbox_ds_size": ds_size,
        "vmin": global_vmin,
        "vmax": global_vmax,
        "downsample": downsample,
        "affine": img.affine.tolist()
    }
    
    print(params)
    print('---')

    with open(out_file, "w") as f:
        json.dump(params, f, indent=2)

    print(f"Saved encoding parameters to {out_file}")
    return params

def main():
    parser = argparse.ArgumentParser(description="Encode maps in input folder")
    parser.add_argument("indir", help="Input directory containing nifti files")
    parser.add_argument("outdir", help="Output directory for params.json")
    parser.add_argument("--suffix", default=".nii.gz", help="File suffix (default: .nii.gz)")
    parser.add_argument("--n_samples", type=int, default=10, help="Number of files to sample")
    parser.add_argument("--downsample", type=int, default=2, help="Downsample factor (default=2)")

    args = parser.parse_args()

    indir = Path(args.indir)
    outdir = Path(args.outdir)

    # make outdir if needed
    os.makedirs(outdir, exist_ok=True)

    # Collect files recursively
    files = list(indir.rglob(f"*{args.suffix}"))
    if not files:
        raise FileNotFoundError(f"No files with suffix '{suffix}' found in {indir}")

    # Get ids
    fnames = [os.path.basename(f) for f in files]
    ids = [str(f).replace(args.suffix, '') for f in fnames]

    # Detect parameters
    params_file = os.path.join(args.outdir, "params.json")
    if not os.path.exists(params_file):
        params = detect_params(files, params_file, args.downsample, args.n_samples)
    else:
        # Open and load into a dictionary
        print(f"{params_file} already exists, reading params from file.")
        with open(params_file, "r") as f:
            params = json.load(f)        

    # Encode images
    for i, fname in enumerate(files):
        fout = os.path.join(outdir, ids[i] + '_encoded')
        if not os.path.exists(fout):
            print(f'Encoding: {fout}')
            encode_map(fname, params, fout)

if __name__ == "__main__":
    main()
