#!/usr/bin/env python3
import os
import argparse
import json
import random
import nibabel as nib
import numpy as np
from scipy.ndimage import zoom
from pathlib import Path

def decode_map(in_file, params, out_file, in_field='imgvec', scale_vals=True):
    """
    Decode an encoded uint16 NIfTI image to the original image space.

    Args:
        in_file (str): Path to encoded NIfTI (uint16)
        params (dict): Dictionary with keys:
            'bbox_min', 'bbox_max', 'vmin', 'vmax'
        out_file (str): Path to save the decoded NIfTI
        downsample (int or tuple): Downsampling factor used during encoding
    """
    
    # Load vector
    enc_data = np.load(in_file)[in_field]
    enc_data = enc_data.reshape(params["bbox_ds_size"])
    
    if scale_vals:
        # Convert back to float using vmin/vmax
        vmin = params["vmin"]
        vmax = params["vmax"]
        data_float = enc_data.astype(np.float32) / 65535 * (vmax - vmin) + vmin
    else:
        data_float = enc_data.astype(np.float32)

    # Upsample back to original bounding box size
    bbox_min = np.array(params["bbox_min"])
    bbox_max = np.array(params["bbox_max"])
    bbox_size = params["bbox_size"]

    zoom_factors = [s/o for s, o in zip(bbox_size, np.array(data_float.shape))]
    data_upsampled = zoom(data_float, zoom_factors, order=1)
    #data_upsampled = zoom(data_float, zoom_factors, order=0)

    # Place the upsampled crop into full original image
    full_data = np.zeros(params['img_shape'], dtype=np.float32)
    full_data[bbox_min[0]:bbox_max[0], 
              bbox_min[1]:bbox_max[1], 
              bbox_min[2]:bbox_max[2]] = data_upsampled

    # Save decoded image
    out_img = nib.Nifti1Image(full_data, np.array(params["affine"]))
    nib.save(out_img, out_file)
    print(f"Decoded image saved to {out_file}")

def main():
    parser = argparse.ArgumentParser(description="Decode input file")
    parser.add_argument("in_file", help="Input file")
    parser.add_argument("params", help="params.json")
    parser.add_argument("out_file", help="Output file")
    parser.add_argument("--in_field", default='imgvec', help="Input field")
    parser.add_argument("--scale_vals", action='store_true', help="Input field")

    args = parser.parse_args()

    # Read params
    with open(args.params, "r") as f:
        params = json.load(f)        

    # Encode images
    decode_map(args.in_file, params, args.out_file, args.in_field, args.scale_vals)

if __name__ == "__main__":
    main()
