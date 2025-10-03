#!/usr/bin/env python3
import os
import argparse
import json
import random
import nibabel as nib
import numpy as np
from scipy.ndimage import zoom
from pathlib import Path
import pandas as pd


def encode_map(in_file, params, out_file, out_field='imgvec'):
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
    
    # Save
    print(f"Encoded data saved to {out_file}")

def main():
    parser = argparse.ArgumentParser(description="Encode input file")
    parser.add_argument("in_file", help="Input file")
    parser.add_argument("params", help="params.json")
    parser.add_argument("out_file", help="Output file")
    parser.add_argument("--out_field", default='imgvec', help="Field name for target data")

    args = parser.parse_args()

    # Read params
    with open(args.params, "r") as f:
        params = json.load(f)        

    # Encode images
    encode_map(args.in_file, params, args.out_file, args.out_field)

if __name__ == "__main__":
    main()
